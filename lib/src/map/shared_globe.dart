import 'dart:math' as math;

import 'package:belnet_mobile/src/map/globe_painter.dart';
import 'package:belnet_mobile/src/map/globe_projection.dart';
import 'package:belnet_mobile/src/map/world_map_data.dart';
import 'package:belnet_mobile/src/map/world_map_painters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Shared state of "the" BelNet globe.
///
/// Every place that draws the globe (launch intro / onboarding, the home
/// connecting globe, the background globe behind the other tabs) reads and
/// writes its rotation here, so moving between screens continues the same
/// rotation instead of starting a new globe.
class SharedGlobeController extends ChangeNotifier {
  SharedGlobeController._();

  static final SharedGlobeController instance = SharedGlobeController._();

  /// Point currently facing the viewer.
  double latitude = 15;
  double longitude = 40;

  /// Where the home screen is centred (the user's country when unprotected,
  /// the exit country when protected). The background globe turns here when
  /// it hands over to the home map.
  LatLon? homeFocus;

  bool _onHome = true;

  /// The home tab is showing (the background globe then sits behind the
  /// home map, centred on [homeFocus]).
  bool get onHome => _onHome;

  void setOnHome(bool value) {
    if (_onHome == value) return;
    _onHome = value;
    notifyListeners();
  }

  /// Called every frame by whichever globe is animating on screen.
  void syncRotation(double lat, double lon) {
    latitude = lat;
    longitude = lon;
  }

  void setHomeFocus(LatLon? focus) {
    homeFocus = focus;
  }

  /// Published by the home map: where the user's location sits on screen
  /// in home's resting view, and how large the map is there. The intro
  /// globe (onboarding / launch) zooms into exactly this view before home
  /// appears, so the hand-over is a still cross-fade with no jump.
  final ValueNotifier<HomeAnchor?> homeAnchor = ValueNotifier(null);
}

/// See [SharedGlobeController.homeAnchor].
@immutable
class HomeAnchor {
  const HomeAnchor({
    required this.latitude,
    required this.longitude,
    required this.globalPoint,
    required this.pixelsPerRadian,
  });

  /// The point home is centred on.
  final double latitude;
  final double longitude;

  /// The user's location on screen (global logical pixels).
  final Offset globalPoint;

  /// Local map scale there: on-screen pixels per radian of arc.
  final double pixelsPerRadian;

  @override
  bool operator ==(Object other) =>
      other is HomeAnchor &&
      (other.latitude - latitude).abs() < 0.01 &&
      (other.longitude - longitude).abs() < 0.01 &&
      (other.globalPoint - globalPoint).distance < 0.5 &&
      (other.pixelsPerRadian - pixelsPerRadian).abs() < 0.5;

  @override
  int get hashCode => Object.hash(
      globalPoint.dx.round(), globalPoint.dy.round(), pixelsPerRadian.round());
}

/// The globe behind every tab (design: Settings and other screens).
///
/// * On a secondary tab it rests large and low, with only its upper curve
///   visible above the bottom bar.
/// * Going to Home it rises and zooms into the home focus (the map then
///   fades in over it); leaving Home it zooms out and sinks back.
///
/// It eases towards its target from wherever it is, so interrupted or rapid
/// navigation never snaps, and it keeps the shared rotation. It stops
/// rendering once it has settled.
class SharedGlobeLayer extends StatefulWidget {
  const SharedGlobeLayer({super.key, required this.dark});

  final bool dark;

  /// Length of the move between Home and the other tabs. The tab bar
  /// starts fading Home in only once this is done (see MainBottomNavbar).
  static const double moveSeconds = 0.54;

  @override
  State<SharedGlobeLayer> createState() => _SharedGlobeLayerState();
}

class _SharedGlobeLayerState extends State<SharedGlobeLayer>
    with SingleTickerProviderStateMixin {
  /// Size of the globe behind secondary screens and how high its top edge
  /// sits (fraction of the height), as in the intro / reference.
  static const double _backgroundZoom = 3.35;
  static const double _backgroundHorizon = 0.72;

  /// Fallback size at Home when the home map has not reported its view.
  static const double _homeZoom = 4.0;


  /// At Home: wait this long after arriving (Home has faded in on top),
  /// then fade this layer out over [_fadeSeconds] and stop drawing it.
  static const double _hideDelay = 0.45;
  static const double _fadeSeconds = 0.3;

  final SharedGlobeController _shared = SharedGlobeController.instance;
  final GlobeCamera _camera = GlobeCamera();
  late final Ticker _ticker;
  Duration? _last;
  WorldMapData? _data;
  Size _size = Size.zero;
  bool _placed = false;

  /// Shift of the globe from its default place (centre at 45% height).
  Offset _offset = Offset.zero;

  /// Pose the current move started from, and its progress (1 = arrived).
  bool _home = true;
  double _t = 1;
  double _fromZoom = _backgroundZoom;
  Offset _fromOffset = Offset.zero;
  double _fromLat = 0;
  double _fromLon = 0;
  double _sinceArrival = 0;

  /// Visibility: Home draws its own map, so once Home is showing on top
  /// this layer fades out and stops painting (no duplicate rendering).
  double _opacity = 1;

  @override
  void initState() {
    super.initState();
    _home = _shared.onHome;
    _camera
      ..latitude = _shared.latitude
      ..longitude = _shared.longitude
      ..zoom = _home ? _homeZoom : _backgroundZoom;
    _opacity = _home ? 0 : 1;
    _ticker = createTicker(_tick);
    _shared.addListener(_onSharedChanged);
    _shared.homeAnchor.addListener(_wake);
    WorldMapData.load().then((data) {
      if (!mounted) return;
      setState(() => _data = data);
      _wake();
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    _shared.removeListener(_onSharedChanged);
    _shared.homeAnchor.removeListener(_wake);
    _ticker.dispose();
    _camera.dispose();
    super.dispose();
  }

  void _onSharedChanged() {
    if (_shared.onHome == _home) return;
    if (!_ticker.isActive) {
      // Pick up the rotation other globes left behind.
      _camera
        ..latitude = _shared.latitude
        ..longitude = _shared.longitude;
    }
    if (!_shared.onHome && _opacity <= 0.01 && !_size.isEmpty) {
      // Leaving Home while hidden: start from exactly what the home map
      // shows (it may have changed since we arrived), so the cross-fade
      // reveals the same view.
      final h = _homePose();
      _camera
        ..zoom = h.zoom
        ..latitude = h.lat ?? _camera.latitude
        ..longitude = h.lon ?? _camera.longitude;
      _offset = h.offset;
    }
    _home = _shared.onHome;
    _fromZoom = _camera.zoom;
    _fromOffset = _offset;
    _fromLat = _camera.latitude;
    _fromLon = _camera.longitude;
    _t = 0;
    _sinceArrival = 0;
    if (!_home) _opacity = 1; // Home fades out on top of us
    _wake();
  }

  void _wake() {
    if (!_ticker.isActive && mounted) {
      _last = null;
      _ticker.start();
    }
  }

  double get _base => math.min(_size.width * 0.39, _size.height * 0.36);

  /// Home's resting view: the focus point at the place and scale the home
  /// map shows it (SharedGlobeController.homeAnchor).
  ({double zoom, Offset offset, double? lat, double? lon}) _homePose() {
    final anchor = _shared.homeAnchor.value;
    final focus = anchor != null
        ? (latitude: anchor.latitude, longitude: anchor.longitude)
        : _shared.homeFocus;
    final box = context.findRenderObject() as RenderBox?;
    if (anchor == null || box == null || !box.hasSize) {
      return (
        zoom: _homeZoom,
        offset: Offset.zero,
        lat: focus?.latitude.clamp(-60.0, 70.0),
        lon: focus?.longitude,
      );
    }
    final local = box.globalToLocal(anchor.globalPoint);
    final center = Offset(_size.width / 2, _size.height * 0.45);
    return (
      zoom: anchor.pixelsPerRadian / math.max(_base, 1.0),
      offset: local - center,
      lat: anchor.latitude,
      lon: anchor.longitude,
    );
  }

  ({double zoom, Offset offset, double? lat, double? lon}) _backgroundPose() {
    final r = _base * _backgroundZoom;
    return (
      zoom: _backgroundZoom,
      // Top edge at [_backgroundHorizon] of the height.
      offset: Offset(0, _size.height * (_backgroundHorizon - 0.45) + r),
      // Tilt so the northern hemisphere shows along the visible curve.
      lat: 12,
      lon: null,
    );
  }

  void _tick(Duration elapsed) {
    final last = _last;
    _last = elapsed;
    if (last == null || _size.isEmpty) return;
    final dt = ((elapsed - last).inMicroseconds / 1e6).clamp(0.0, 0.1);

    // One eased move (in and out) from where we were to the target pose;
    // the target is re-read every frame, a new move starts from wherever
    // the globe is.
    final pose = _home ? _homePose() : _backgroundPose();
    _t = math.min(1.0, _t + dt / SharedGlobeLayer.moveSeconds);
    final e = Curves.easeInOutCubic.transform(_t);
    _camera.zoom = _fromZoom + (pose.zoom - _fromZoom) * e;
    _offset = Offset.lerp(_fromOffset, pose.offset, e)!;
    final lat = pose.lat;
    if (lat != null) _camera.latitude = _fromLat + (lat - _fromLat) * e;
    final lon = pose.lon;
    if (lon != null) {
      _camera.longitude =
          wrapLongitude(_fromLon + angleDelta(_fromLon, lon) * e);
    }

    var targetOpacity = 1.0;
    if (_home && _t >= 1) {
      _sinceArrival += dt;
      if (_sinceArrival > _hideDelay) {
        targetOpacity = 0;
        _opacity = math.max(0.0, _opacity - dt / _fadeSeconds);
      }
    }

    _shared.syncRotation(_camera.latitude, _camera.longitude);
    _camera.notify();
    if (mounted) setState(() {});

    if (_t >= 1 && _opacity == targetOpacity) {
      // Nothing moves: stop rendering (saves battery / GPU behind the
      // blurred panels of the settings screens).
      _ticker.stop();
      _last = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final palette = VpnMapPalette.of(widget.dark);
    return IgnorePointer(
      child: LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size != _size) {
          _size = size;
          if (!_placed && !size.isEmpty && !_home) {
            _placed = true;
            _offset = _backgroundPose().offset;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) => _wake());
        }
        if (data == null || _opacity <= 0) return const SizedBox.expand();
        return Opacity(
          opacity: _opacity.clamp(0.0, 1.0),
          child: Transform.translate(
          offset: _offset,
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: GlobePainter(
                geometry: GlobeGeometry.of(data),
                camera: _camera,
                palette: palette,
                highlight: null,
                highlightColor: palette.originHighlight,
                highlightBorder: palette.originHighlightBorder,
                origin: null,
                showOrigin: false,
                exit: null,
                exitActive: false,
                hops: const [],
                otherNodes: const [],
                routeArcs: const [],
                routeMode: GlobeRouteMode.none,
                showSpinArrow: false,
              ),
            ),
          ),
          ),
        );
      }),
    );
  }
}


/// A still globe for full-screen pages outside the tabs (No internet,
/// About): same look and resting pose as the globe behind the tabs, with
/// only its upper curve showing. It is painted once (no ticker).
class BackdropGlobe extends StatefulWidget {
  const BackdropGlobe({super.key, required this.dark, this.horizon = 0.66});

  final bool dark;

  /// Fraction of the height where the globe's top edge sits.
  final double horizon;

  @override
  State<BackdropGlobe> createState() => _BackdropGlobeState();
}

class _BackdropGlobeState extends State<BackdropGlobe> {
  static const double _zoom = 3.35;

  final GlobeCamera _camera = GlobeCamera();
  WorldMapData? _data;

  @override
  void initState() {
    super.initState();
    // Same side of the world as the globe behind the tabs.
    _camera
      ..latitude = 12
      ..longitude = SharedGlobeController.instance.longitude
      ..zoom = _zoom;
    WorldMapData.load().then((data) {
      if (mounted) setState(() => _data = data);
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const SizedBox.expand();
    final palette = VpnMapPalette.of(widget.dark);
    return IgnorePointer(
      child: LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        // GlobePainter centres the globe at 45% of the height.
        final r = math.min(size.width * 0.39, size.height * 0.36) * _zoom;
        final dy = size.height * (widget.horizon - 0.45) + r;
        return ClipRect(
          child: Transform.translate(
            offset: Offset(0, dy),
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: GlobePainter(
                  geometry: GlobeGeometry.of(data),
                  camera: _camera,
                  palette: palette,
                  highlight: null,
                  highlightColor: palette.originHighlight,
                  highlightBorder: palette.originHighlightBorder,
                  origin: null,
                  showOrigin: false,
                  exit: null,
                  exitActive: false,
                  hops: const [],
                  otherNodes: const [],
                  routeArcs: const [],
                  routeMode: GlobeRouteMode.none,
                  showSpinArrow: false,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
