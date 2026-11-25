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

  IntroHandoff? _introHandoff;

  /// Left by the intro globe (onboarding / launch) as it hands over to
  /// home: where the user's location was on screen and how large the map
  /// was there. The home map starts from exactly that view and then glides
  /// to its own framing, so the cross-fade shows no jump.
  void setIntroHandoff(IntroHandoff handoff) => _introHandoff = handoff;

  /// The pending hand-over, if it is recent (null otherwise).
  IntroHandoff? get introHandoff {
    final h = _introHandoff;
    if (h == null) return null;
    if (DateTime.now().difference(h.at) > const Duration(seconds: 4)) {
      _introHandoff = null;
      return null;
    }
    return h;
  }

  void clearIntroHandoff() => _introHandoff = null;
}

/// See [SharedGlobeController.setIntroHandoff].
class IntroHandoff {
  IntroHandoff({
    required this.latitude,
    required this.longitude,
    required this.globalPoint,
    required this.pixelsPerRadian,
  }) : at = DateTime.now();

  /// The user's location.
  final double latitude;
  final double longitude;

  /// Where it was on screen (global logical pixels).
  final Offset globalPoint;

  /// Local map scale there: on-screen pixels per radian of arc.
  final double pixelsPerRadian;

  final DateTime at;
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

  @override
  State<SharedGlobeLayer> createState() => _SharedGlobeLayerState();
}

class _SharedGlobeLayerState extends State<SharedGlobeLayer>
    with SingleTickerProviderStateMixin {
  /// Size of the globe behind secondary screens and how high its top edge
  /// sits (fraction of the height), as in the intro / reference.
  static const double _backgroundZoom = 3.35;
  static const double _backgroundHorizon = 0.72;

  /// Size when handing over to the home map (about the map's scale).
  static const double _homeZoom = 4.0;

  final SharedGlobeController _shared = SharedGlobeController.instance;
  final GlobeCamera _camera = GlobeCamera();
  late final Ticker _ticker;
  Duration? _last;
  WorldMapData? _data;
  Size _size = Size.zero;

  /// Vertical shift of the globe (pixels) and how "home" the pose is.
  double _dy = 0;
  bool _placed = false;

  /// Visibility: Home draws its own map/globe, so once the zoom-in has
  /// handed over this layer fades out and stops painting (no duplicate
  /// globe rendering under the home screen).
  double _opacity = 1;

  @override
  void initState() {
    super.initState();
    _camera
      ..latitude = _shared.latitude
      ..longitude = _shared.longitude
      ..zoom = _shared.onHome ? _homeZoom : _backgroundZoom;
    _opacity = _shared.onHome ? 0 : 1;
    _ticker = createTicker(_tick);
    _shared.addListener(_onSharedChanged);
    WorldMapData.load().then((data) {
      if (!mounted) return;
      setState(() => _data = data);
      _wake();
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    _shared.removeListener(_onSharedChanged);
    _ticker.dispose();
    _camera.dispose();
    super.dispose();
  }

  void _onSharedChanged() {
    // Pick up the rotation other globes left behind, then move.
    if (!_ticker.isActive) {
      _camera
        ..latitude = _shared.latitude
        ..longitude = _shared.longitude;
    }
    _wake();
  }

  void _wake() {
    if (!_ticker.isActive && mounted) {
      _last = null;
      _ticker.start();
    }
  }

  double _targetDy() {
    if (_size.isEmpty) return 0;
    if (_shared.onHome) return 0;
    // GlobePainter centres the globe at 45% of the height.
    final r = math.min(_size.width * 0.39, _size.height * 0.36) *
        _backgroundZoom;
    return _size.height * (_backgroundHorizon - 0.45) + r;
  }

  void _tick(Duration elapsed) {
    final last = _last;
    _last = elapsed;
    if (last == null || _size.isEmpty) return;
    final dt = ((elapsed - last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    // Critically-damped-like follow (~0.25 s time constant): smooth, no
    // overshoot, and it starts from the current state when re-targeted.
    final k = 1 - math.exp(-dt * 4.0);

    final home = _shared.onHome;
    final targetZoom = home ? _homeZoom : _backgroundZoom;
    final targetDy = _targetDy();
    final focus = home ? _shared.homeFocus : null;

    _camera.zoom += (targetZoom - _camera.zoom) * k;
    _dy += (targetDy - _dy) * k;
    // Fade out on Home only once the zoom-in is mostly done; fade back in
    // straight away when leaving.
    final targetOpacity =
        home ? ((_camera.zoom - _homeZoom).abs() < 0.25 ? 0.0 : 1.0) : 1.0;
    _opacity += (targetOpacity - _opacity) * (1 - math.exp(-dt * 6.0));
    if ((_opacity - targetOpacity).abs() < 0.01) _opacity = targetOpacity;
    var rotating = false;
    if (focus != null) {
      final dLon = angleDelta(_camera.longitude, focus.longitude);
      final dLat = focus.latitude.clamp(-60.0, 70.0) - _camera.latitude;
      _camera.longitude = wrapLongitude(_camera.longitude + dLon * k);
      _camera.latitude += dLat * k;
      rotating = dLon.abs() > 0.05 || dLat.abs() > 0.05;
    } else if (!home) {
      // Background: tilt gently so the northern hemisphere shows along the
      // visible curve.
      final dLat = 12 - _camera.latitude;
      _camera.latitude += dLat * k;
      rotating = dLat.abs() > 0.05;
    }
    _shared.syncRotation(_camera.latitude, _camera.longitude);
    _camera.notify();
    if (mounted) setState(() {});

    final settled = (_camera.zoom - targetZoom).abs() < 0.002 &&
        (_dy - targetDy).abs() < 0.5 &&
        _opacity == targetOpacity &&
        !rotating;
    if (settled) {
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
          if (!_placed && !size.isEmpty) {
            _placed = true;
            _dy = _targetDy();
          }
          WidgetsBinding.instance.addPostFrameCallback((_) => _wake());
        }
        if (data == null || _opacity <= 0) return const SizedBox.expand();
        return Opacity(
          opacity: _opacity.clamp(0.0, 1.0),
          child: Transform.translate(
          offset: Offset(0, _dy),
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
