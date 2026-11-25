import 'dart:math' as math;

import 'package:belnet_mobile/src/map/geo_location.dart';
import 'package:belnet_mobile/src/map/globe_painter.dart';
import 'package:belnet_mobile/src/map/globe_projection.dart';
import 'package:belnet_mobile/src/map/map_projection.dart';
import 'package:belnet_mobile/src/map/route_snapshot.dart';
import 'package:belnet_mobile/src/map/shared_globe.dart';
import 'package:belnet_mobile/src/map/vpn_home_style.dart';
import 'package:belnet_mobile/src/map/vpn_map_provider.dart';
import 'package:belnet_mobile/src/map/world_map_data.dart';
import 'package:belnet_mobile/src/map/world_map_painters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

enum _MarkerKind { origin, exit }

/// The home-screen map.
///
/// * Disconnected: a flat map zoomed to the user's own country (real public
///   IP location), red marker, "UNPROTECTED".
/// * Connecting: the map zooms out into a rotating globe. While the daemon
///   looks for a route the globe spins ("FINDING ROUTE"); as soon as it is
///   building a path the REAL masternode hops of that path are shown and
///   the route is traced through them ("HOPPING NODES"); once a path to the
///   exit is established the globe turns to the exit country ("ROUTE
///   FOUND").
/// * Connected: the globe zooms back into the flat map, centred on the
///   exit country, green marker, "PROTECTED".
///
/// Reads everything from [VpnMapProvider]; it never changes connection
/// state itself.
class VpnWorldMap extends StatefulWidget {
  const VpnWorldMap({
    super.key,
    required this.darkTheme,
    this.bottomInset = 0,
    this.overlay,
    this.showStatus = true,
    this.compact = false,
  });

  final bool darkTheme;

  /// Space covered at the bottom of the map (status block); auto-focus
  /// keeps markers above it.
  final double bottomInset;

  /// Extra widgets drawn on top of the map.
  final List<Widget>? overlay;

  /// Show the status block (bottom-left).
  final bool showStatus;

  /// The panel below is expanded: the map is small, so the status block
  /// and the zoom controls are hidden (as in the design).
  final bool compact;

  @override
  State<VpnWorldMap> createState() => _VpnWorldMapState();
}

class _VpnWorldMapState extends State<VpnWorldMap>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const double _maxScale = 8.0;

  /// Minimum time each connecting stage stays on screen, so a fast
  /// connection still reads as a sequence instead of flashing.
  static const Duration _minStageTime = Duration(milliseconds: 1100);

  /// How long "ROUTE FOUND" is held after the tunnel is ready before the
  /// globe zooms into the flat map.
  static const Duration _routeFoundHold = Duration(milliseconds: 1500);

  final TransformationController _tc = TransformationController();
  late final AnimationController _loop;
  late final AnimationController _highlight;
  late final AnimationController _exitMove;
  late final AnimationController _focus;

  /// 0 = flat map, 1 = globe.
  late final AnimationController _globeMix;
  late final Ticker _globeTicker;
  final GlobeCamera _camera = GlobeCamera();
  Duration? _lastTick;
  double _clock = 0; // seconds of globe time
  Matrix4Tween? _focusTween;

  VpnMapProvider? _provider;
  WorldMapData? _data;
  Object? _loadError;

  Size _viewport = Size.zero;
  Size _mapSize = Size.zero;

  VpnMapPhase? _phase;
  Offset? _origin; // normalised
  Offset? _exitFrom; // normalised, start of a marker move
  Offset? _exitTo; // normalised
  CountryShape? _originCountry;
  CountryShape? _exitCountry;
  bool _userMoved = false;
  _MarkerKind? _selected;

  // ----- globe scene -----
  bool _globeScene = false; // the globe is (or is becoming) the view
  ConnectStage? _shownStage;
  double _stageSince = 0; // _clock when _shownStage was set
  bool _leavingToExit = false; // zooming into the flat map after connecting
  RouteSnapshot _route = RouteSnapshot.empty;
  List<GlobeDot> _hopDots = const [];
  List<List<LatLon>> _routeArcs = const [];

  /// For each route arc, the index (in [RouteSnapshot.activeHops]) of the
  /// hop it ends at, or -1 when it ends at the exit.
  List<int> _arcEndHop = const [];

  /// User -> exit (searching) and last hop -> exit (waiting) legs.
  List<LatLon>? _seekArc;
  List<LatLon>? _pendingExitArc;
  bool _routeHasOrigin = false;

  /// Seconds spent searching (drives the marker heading to the exit).
  double _seekClock = 0;

  /// Seconds since the route trace (re)started.
  double _traceClock = 0;

  /// Each leg: a short pause on the hop, then an eased move to the next.
  static const double _legDwell = 0.35;
  static const double _legMove = 1.25;

  /// Legs that end at a hop (the leg to the exit is not one of them).
  int _hopLegs = 0;

  /// _clock when the trace reached the last hop / the exit (-1 = not yet).
  double _traceCompleteAt = -1;
  double _exitReachedAt = -1;

  /// _clock when the tunnel came up while the globe was showing.
  double _connectedClock = 0;

  /// How long to wait for the daemon's path after the tunnel is up.
  static const double _waitForHops = 3.0;

  void _restartTrace() {
    _traceClock = 0;
    _traceCompleteAt = -1;
    _camera
      ..trace = 0
      ..arrivalHop = -1
      ..arrivalT = 1;
  }

  /// Trace position (in legs) for [_traceClock]: pauses on each hop and
  /// eases in and out between hops, so the route draws hop by hop.
  double _tracePosition(int legs) {
    const period = _legDwell + _legMove;
    final leg = (_traceClock / period).floor();
    // Arrival ripple on the hop just reached (hop `leg` at the start of
    // each period; the last hop once the whole path is drawn).
    final arrivedAt = math.min(leg, legs);
    final sinceArrival = _traceClock - arrivedAt * period;
    _camera
      ..arrivalHop = arrivedAt
      ..arrivalT = (sinceArrival / 0.8).clamp(0.0, 1.0);
    if (leg >= legs) return legs.toDouble();
    final local = _traceClock - leg * period;
    final k = local <= _legDwell
        ? 0.0
        : Curves.easeInOutCubic.transform(
            ((local - _legDwell) / _legMove).clamp(0.0, 1.0));
    return leg + k;
  }

  /// Point of the route at trace position [t] (where the green line ends).
  LatLon? _routePointAt(double t) {
    if (_routeArcs.isEmpty) return null;
    final leg = t.floor().clamp(0, _routeArcs.length - 1);
    final arc = _routeArcs[leg];
    if (arc.isEmpty) return null;
    final f = (t - leg).clamp(0.0, 1.0);
    return arc[((arc.length - 1) * f).round()];
  }

  /// Hops "reached" before tracing starts (the first located hop).
  int _firstHopReached = 0;
  final ValueNotifier<int> _hopShown = ValueNotifier<int>(1);

  Map<String, TextPainter> _labelCache = {};
  TextPainter? _originLabel;
  TextPainter? _exitLabel;
  String? _originLabelText;
  String? _exitLabelText;
  bool? _labelsDark;

  bool _reduceMotion = false;

  MapViewTransform get _transform =>
      MapViewTransform.fromStorage(_tc.value.storage);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loop = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600));
    _highlight = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      reverseDuration: const Duration(milliseconds: 650),
    );
    _exitMove = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900), value: 1);
    _focus = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950))
      ..addListener(_onFocusTick);
    _globeMix = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      reverseDuration: const Duration(milliseconds: 1100),
    )
      ..addListener(_onGlobeMixTick)
      ..addStatusListener(_onGlobeMixStatus);
    _globeTicker = createTicker(_onGlobeTick);

    WorldMapData.load().then((data) {
      if (!mounted) return;
      setState(() => _data = data);
      _refreshCountries();
      _scheduleFocus(force: true);
    }).catchError((Object e) {
      if (mounted) setState(() => _loadError = e);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final provider = Provider.of<VpnMapProvider>(context, listen: false);
    if (!identical(provider, _provider)) {
      _provider?.removeListener(_onProviderChanged);
      _provider = provider;
      provider.addListener(_onProviderChanged);
      // Start live data after this frame: starting it synchronously would
      // notify sibling widgets while the tree is being built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) provider.setMapVisible(true);
      });
      _applyProviderState(initial: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final p = _provider;
    if (p == null) return;
    if (state == AppLifecycleState.resumed) {
      p.setMapVisible(true);
      _syncLoop();
      _syncGlobeTicker();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // No frames while backgrounded, and no status polling either.
      p.setMapVisible(false);
      _loop.stop();
      if (_globeTicker.isActive) _globeTicker.stop();
      _lastTick = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _provider?.removeListener(_onProviderChanged);
    _provider?.setMapVisible(false);
    // Never leave the rest of the home screen stuck on "connecting"; clear
    // after the frame so no listener is notified while the tree unmounts.
    final p = _provider;
    if (p != null && p.sequencePlaying) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => p.setSequencePlaying(false));
    }
    _loop.dispose();
    _highlight.dispose();
    _exitMove.dispose();
    _focus.dispose();
    _globeMix.dispose();
    _globeTicker.dispose();
    _camera.dispose();
    _hopShown.dispose();
    _tc.dispose();
    _disposeLabels();
    super.dispose();
  }

  void _disposeLabels() {
    for (final tp in _labelCache.values) {
      tp.dispose();
    }
    _labelCache = {};
    _originLabel?.dispose();
    _exitLabel?.dispose();
    _originLabel = null;
    _exitLabel = null;
    _originLabelText = null;
    _exitLabelText = null;
  }

  // ---------------------------------------------------------------------
  // Provider -> animation state

  void _onProviderChanged() {
    if (!mounted) return;
    // Providers are sometimes poked while a frame is being built; defer to
    // after the frame instead of calling setState mid-build.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _applyProviderState());
      });
      return;
    }
    setState(() => _applyProviderState());
  }

  void _applyProviderState({bool initial = false}) {
    final p = _provider!;
    final phase = p.phase;
    final phaseChanged = phase != _phase;
    _phase = phase;

    final originLoc = p.originalLocation;
    final newOrigin = originLoc != null && originLoc.hasCoordinates
        ? MapProjection.project(originLoc.latitude, originLoc.longitude)
        : null;
    final originChanged = newOrigin != _origin;
    _origin = newOrigin;

    final exitLoc = p.exit.location;
    final newExit = exitLoc != null && exitLoc.hasCoordinates
        ? MapProjection.project(exitLoc.latitude, exitLoc.longitude)
        : null;
    // Tell the shared background globe what home is looking at, so leaving
    // and coming back to home keeps the same side of the world in view.
    final focusLoc = phase == VpnMapPhase.connected &&
            exitLoc != null &&
            exitLoc.hasCoordinates
        ? exitLoc
        : originLoc;
    SharedGlobeController.instance.setHomeFocus(
      focusLoc != null && focusLoc.hasCoordinates
          ? (latitude: focusLoc.latitude, longitude: focusLoc.longitude)
          : null,
    );
    final exitChanged = newExit != _exitTo;
    if (exitChanged) {
      final current = _currentExitNormalized();
      _exitTo = newExit;
      if (current != null && newExit != null && !initial && !_reduceMotion) {
        _exitFrom = current;
        _exitMove.forward(from: 0);
      } else {
        _exitFrom = null;
        _exitMove.value = 1;
      }
    }

    if (originChanged || exitChanged || initial) _refreshCountries();
    _refreshMarkerLabels();

    if (phaseChanged || initial) {
      _driveHighlight(phase, initial: initial);
      _syncLoop();
    }

    if (!identical(p.route, _route) ||
        originChanged ||
        exitChanged ||
        phaseChanged) {
      _setRoute(p.route);
    }
    _updateScene(initial: initial);

    if (phaseChanged || exitChanged) {
      _userMoved = false;
      _scheduleFocus();
    } else if (originChanged && !_userMoved) {
      _scheduleFocus();
    }
  }

  Offset? _currentExitNormalized() {
    final to = _exitTo;
    if (to == null) return null;
    final from = _exitFrom;
    if (from == null || _exitMove.value >= 1) return to;
    return Offset.lerp(
        from, to, Curves.easeInOutCubic.transform(_exitMove.value));
  }

  void _driveHighlight(VpnMapPhase to, {bool initial = false}) {
    final instant = initial || _reduceMotion;
    switch (to) {
      case VpnMapPhase.connecting:
      case VpnMapPhase.connected:
        if (instant) {
          _highlight.value = 1;
        } else {
          _highlight.forward();
        }
        break;
      case VpnMapPhase.disconnecting:
      case VpnMapPhase.disconnected:
        if (instant) {
          _highlight.value = 0;
        } else {
          _highlight.reverse();
        }
        break;
      case VpnMapPhase.failed:
        _highlight.stop();
        _highlight.value = 0;
        break;
    }
  }

  void _syncLoop() {
    final shouldRun = !_reduceMotion &&
        _phase != VpnMapPhase.failed &&
        _globeMix.value < 1 &&
        (_origin != null || _exitTo != null);
    if (shouldRun && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!shouldRun && _loop.isAnimating) {
      _loop.stop();
    }
  }

  void _refreshCountries() {
    final data = _data;
    final p = _provider;
    if (data == null || p == null) return;
    _originCountry = data.resolveCountry(
        name: p.originalLocation?.country, normalized: _origin);
    _exitCountry = data.resolveCountry(
        name: p.exit.location?.country ?? p.exit.country,
        normalized: _exitTo);
    _syncLoop();
  }

  void _refreshMarkerLabels() {
    final p = _provider!;
    if (_labelsDark != widget.darkTheme) {
      _disposeLabels();
      _labelsDark = widget.darkTheme;
    }
    final palette = VpnMapPalette.of(widget.darkTheme);
    final origin = p.originalLocation;
    final originText = origin == null
        ? null
        : 'You · ${origin.city ?? origin.country ?? 'Unknown'}';
    if (originText != _originLabelText) {
      _originLabel?.dispose();
      _originLabel = originText == null ? null : _pill(originText, palette);
      _originLabelText = originText;
    }
    final exit = p.exit;
    final exitPlace =
        exit.location?.city ?? exit.location?.country ?? exit.country;
    final exitText = exit.location == null
        ? null
        : exitPlace == null
            ? exit.nodeName
            : '${_shortNode(exit.nodeName)} · $exitPlace';
    if (exitText != _exitLabelText) {
      _exitLabel?.dispose();
      _exitLabel = exitText == null ? null : _pill(exitText, palette);
      _exitLabelText = exitText;
    }
  }

  static String _shortNode(String name) => name.length <= 14
      ? name
      : '${name.substring(0, 6)}…${name.substring(name.length - 6)}';

  TextPainter _pill(String text, VpnMapPalette palette) => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: palette.pillText,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 180);

  // ---------------------------------------------------------------------
  // Globe scene

  /// Decides whether the globe or the flat map is shown, and runs the
  /// transitions between them.
  void _updateScene({bool initial = false}) {
    final phase = _phase ?? VpnMapPhase.disconnected;
    if (phase == VpnMapPhase.connecting) {
      _leavingToExit = false;
      if (!_globeScene) _enterGlobe(instant: initial || _reduceMotion);
      _promoteStage(force: _reduceMotion);
    } else if (phase == VpnMapPhase.connected && _globeScene) {
      // The tunnel is ready: finish on "ROUTE FOUND", then zoom in. The
      // ticker leaves the globe once the hold is over.
      // The sequence is never skipped: hops are connected one by one,
      // then ROUTE FOUND, then the zoom (see _promoteStage / the ticker).
      if (!_leavingToExit) _connectedClock = _clock;
      _leavingToExit = true;
      if (_reduceMotion || initial) {
        _leaveGlobe(instant: true);
      } else {
        _setSequencePlaying(true);
      }
    } else if (_globeScene) {
      // Disconnected / failed / disconnecting: straight back to the map.
      _leaveGlobe(instant: initial || _reduceMotion);
    }
    _syncGlobeTicker();
  }

  void _enterGlobe({required bool instant}) {
    _globeScene = true;
    _shownStage = ConnectStage.findingRoute;
    _stageSince = _clock;
    _restartTrace();
    _seekClock = 0;
    _camera.seek = 0;
    _hopShown.value = 1;
    // Start facing the user's country, like the flat map just did.
    final o = _provider?.originalLocation;
    final start = (o != null && o.hasCoordinates)
        ? (latitude: o.latitude, longitude: o.longitude)
        : _exitLatLon() ?? (latitude: 20.0, longitude: 0.0);
    _camera
      ..latitude = start.latitude.clamp(-50.0, 60.0)
      ..longitude = start.longitude;
    _selected = null;
    if (instant) {
      _globeMix.value = 1;
    } else {
      _globeMix.forward();
    }
  }

  void _leaveGlobe({required bool instant}) {
    if (!_globeScene) return;
    _globeScene = false;
    if (instant) {
      _globeMix.value = 0;
      _shownStage = null;
      _leavingToExit = false;
      _setSequencePlaying(false);
    } else {
      _globeMix.reverse();
    }
    // Frame the flat map for where we are going, without animation (it is
    // hidden behind the globe while the camera moves).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animateTo(_focusTarget(), animate: false);
    });
  }

  void _onGlobeMixTick() {
    _applyGlobeZoom();
    // The flat map only needs its own pulse loop while it is visible.
    _syncLoop();
  }

  void _onGlobeMixStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _shownStage = null;
      _leavingToExit = false;
      _setSequencePlaying(false);
      _syncGlobeTicker();
      if (mounted) setState(() {});
    }
  }

  /// Entering: zoom out from close-up. Leaving to the exit: zoom into the
  /// exit country. Either way the globe is large while it is faint.
  void _applyGlobeZoom() {
    final mix = Curves.easeInOutCubic.transform(_globeMix.value);
    final far = _leavingToExit ? 2.2 : 1.9;
    _camera.zoom = far + (1.0 - far) * mix;
  }

  /// Tells the provider (and so the panel) whether the connecting sequence
  /// is still on screen. Never notifies in the middle of a build.
  void _setSequencePlaying(bool value) {
    final p = _provider;
    if (p == null || p.sequencePlaying == value) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_provider == p) p.setSequencePlaying(value);
      });
    } else {
      p.setSequencePlaying(value);
    }
  }

  void _syncGlobeTicker() {
    final want = _globeMix.value > 0 || _globeScene;
    if (want && !_globeTicker.isActive) {
      _lastTick = null;
      _globeTicker.start();
    } else if (!want && _globeTicker.isActive) {
      _globeTicker.stop();
      _lastTick = null;
    }
  }

  ConnectStage _targetStage() {
    final p = _provider;
    if (p == null) return ConnectStage.findingRoute;
    if (p.phase == VpnMapPhase.connected) return ConnectStage.routeFound;
    return p.connectStage ?? ConnectStage.findingRoute;
  }

  /// Moves the shown stage forward (never backwards within one attempt),
  /// at most one step per [_minStageTime].
  void _promoteStage({bool force = false}) {
    final shown = _shownStage ?? ConnectStage.findingRoute;
    final target = _targetStage();
    if (target.index <= shown.index) return;
    if (force) {
      _setShownStage(target);
      return;
    }
    final elapsed = _clock - _stageSince;
    if (elapsed < _minStageTime.inMilliseconds / 1000.0) return;
    switch (shown) {
      case ConnectStage.findingRoute:
        if (_route.hasHops) {
          // Always show the hops, even when the daemon already reports the
          // route as ready on the first read.
          _setShownStage(ConnectStage.hoppingNodes);
        } else if (_phase == VpnMapPhase.connected &&
            _clock - _connectedClock >= _waitForHops) {
          // Tunnel up but the daemon never exposed the path: finish.
          _setShownStage(ConnectStage.routeFound);
        }
        break;
      case ConnectStage.hoppingNodes:
        // Only once every hop has been connected, one by one.
        if (_traceCompleteAt >= 0 && _clock - _traceCompleteAt >= 0.6) {
          _setShownStage(ConnectStage.routeFound);
        }
        break;
      case ConnectStage.routeFound:
        break;
    }
  }

  void _setShownStage(ConnectStage stage) {
    if (_shownStage == stage) return;
    _shownStage = stage;
    _stageSince = _clock;
    if (stage == ConnectStage.hoppingNodes) _restartTrace();
    if (stage == ConnectStage.routeFound) {
      // Continue from the last hop: the leg to the exit is drawn next.
      _traceClock = _hopLegs * (_legDwell + _legMove);
      _camera.trace = _hopLegs.toDouble();
      _exitReachedAt = -1;
      _hopShown.value = math.max(1, _route.activeHops.length);
    }
  }

  void _setRoute(RouteSnapshot route) {
    final changedPath = !_sameHops(route.activeHops, _route.activeHops);
    _route = route;
    final hops = route.activeHops;
    _hopDots = [
      for (final h in hops)
        if (h.country != null)
          GlobeDot(
            (latitude: h.country!.latitude, longitude: h.country!.longitude),
            group: h.country!.code,
          ),
    ];

    // Route: user -> hop 1 -> ... -> hop N (-> exit), through located
    // points, so it travels from the source towards the destination.
    final points = <(LatLon, int)>[];
    final o = _provider?.originalLocation;
    if (o != null && o.hasCoordinates && hops.isNotEmpty) {
      points.add(((latitude: o.latitude, longitude: o.longitude), -2));
    }
    for (var i = 0; i < hops.length; i++) {
      final c = hops[i].country;
      if (c != null) {
        points.add(((latitude: c.latitude, longitude: c.longitude), i));
      }
    }
    // The last leg to the exit is drawn only once that route really exists.
    final x = _exitLatLon();
    final toExit = route.routeReady || _phase == VpnMapPhase.connected;
    if (x != null && hops.isNotEmpty && toExit) points.add((x, -1));
    // Not there yet: the last located hop -> exit is shown as the leg
    // still to come.
    final lastHop = points.lastIndexWhere((p) => p.$2 >= 0);
    _pendingExitArc = (!toExit && x != null && lastHop >= 0)
        ? greatCircle(points[lastHop].$1.latitude, points[lastHop].$1.longitude,
            x.latitude, x.longitude,
            segments: 28)
        : null;
    // Source -> destination, used while the path is still being searched.
    _seekArc = (o != null && o.hasCoordinates && x != null)
        ? greatCircle(o.latitude, o.longitude, x.latitude, x.longitude,
            segments: 40)
        : null;
    _routeHasOrigin = points.isNotEmpty && points.first.$2 == -2;
    final arcs = <List<LatLon>>[];
    final ends = <int>[];
    for (var i = 0; i + 1 < points.length; i++) {
      final a = points[i].$1, b = points[i + 1].$1;
      arcs.add(greatCircle(a.latitude, a.longitude, b.latitude, b.longitude,
          segments: 28));
      ends.add(points[i + 1].$2);
    }
    _routeArcs = arcs;
    _arcEndHop = ends;
    _hopLegs = ends.where((e) => e >= 0).length;
    _firstHopReached = points.isNotEmpty && points.first.$2 >= 0
        ? points.first.$2 + 1
        : 0;
    if (changedPath &&
        _shownStage == ConnectStage.hoppingNodes &&
        _camera.trace < _hopLegs - 0.001) {
      // The daemon switched path: keep going from where the trace is
      // (no jump back to the start); the new legs are drawn from there.
      _traceCompleteAt = -1;
    }
    if (_shownStage == ConnectStage.routeFound) {
      _camera.trace = arcs.length.toDouble();
    }
  }

  static bool _sameHops(List<RouteHop> a, List<RouteHop> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].router != b[i].router) return false;
    }
    return true;
  }

  LatLon? _exitLatLon() {
    final l = _provider?.exit.location;
    if (l == null || !l.hasCoordinates) return null;
    return (latitude: l.latitude, longitude: l.longitude);
  }

  void _onGlobeTick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;
    final dt = ((elapsed - last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _clock += dt;

    final previousStage = _shownStage;
    if (_globeScene) _promoteStage();
    final stage = _shownStage;

    // --- camera ---
    if (!_reduceMotion) {
      _camera.pulse = (_clock / 2.2) % 1.0;
      LatLon? target;
      switch (stage) {
        case ConnectStage.findingRoute:
        case null:
          final seekArc = _seekArc;
          if (seekArc != null) {
            // Head from the user towards the exit while the daemon looks
            // for a path: steady progress that slows down and never claims
            // to arrive (at most 70% of the way), however long it takes.
            _seekClock += dt;
            _camera.seek = 0.7 * (1 - math.exp(-_seekClock / 6));
            final i = ((seekArc.length - 1) * _camera.seek)
                .round()
                .clamp(0, seekArc.length - 1);
            final p = seekArc[i];
            target = (
              latitude: p.latitude.clamp(-45.0, 55.0),
              longitude: p.longitude,
            );
          } else {
            // No source/destination known: turn the globe.
            _camera.longitude = wrapLongitude(_camera.longitude + 16 * dt);
            _camera.latitude += (15 - _camera.latitude) * (1 - math.exp(-dt));
          }
          break;
        case ConnectStage.hoppingNodes:
          // Glide with the route as it is drawn from hop to hop: the globe
          // turns towards the leg being connected, blended with the middle
          // of the whole path so every hop stays in view.
          final pts = <LatLon>[
            for (final arc in _routeArcs) ...[arc.first, arc.last],
          ];
          final mean = sphericalMean(pts);
          final waitingLeg = _pendingExitArc;
          // All hops linked but the tunnel is not ready yet: lean towards
          // the exit (the leg still to come) and wait there.
          final head = _traceCompleteAt >= 0 && waitingLeg != null
              ? waitingLeg[waitingLeg.length ~/ 2]
              : _routePointAt(_camera.trace);
          final aim = head == null
              ? mean
              : (mean == null ? head : sphericalMean([head, head, mean]));
          if (aim != null) {
            target = (
              latitude: aim.latitude.clamp(-45.0, 55.0),
              longitude: aim.longitude,
            );
          } else {
            _camera.longitude = wrapLongitude(_camera.longitude + 10 * dt);
          }
          break;
        case ConnectStage.routeFound:
          target = _camera.trace < _routeArcs.length - 0.001
              ? (_routePointAt(_camera.trace) ?? _exitLatLon())
              : _exitLatLon();
          break;
      }
      // Moving dashes on the leg still to come (keeps the globe alive
      // while waiting, without suggesting a finished route).
      _camera.dashPhase = (_camera.dashPhase + dt * 14) % 1000;
      if (target != null) {
        // Soft follow (time constant ~0.6 s): no jumps when the target
        // moves to the next hop or the path changes.
        final k = 1 - math.exp(-dt * 1.6);
        _camera.longitude = wrapLongitude(_camera.longitude +
            angleDelta(_camera.longitude, target.longitude) * k);
        _camera.latitude += (target.latitude - _camera.latitude) * k;
      }

      // --- route trace ---
      final segments = _routeArcs.length.toDouble();
      if (stage == ConnectStage.hoppingNodes) {
        // Connect the hops one by one; the finished path stays on screen.
        _traceClock += dt;
        _camera.trace = _tracePosition(_hopLegs);
        if (_camera.trace >= _hopLegs - 0.001 && _traceCompleteAt < 0) {
          _traceCompleteAt = _clock;
          if (mounted) setState(() {}); // status: waiting for the exit
        }
      } else if (stage == ConnectStage.routeFound) {
        // Then the last leg, to the exit.
        _traceClock += dt;
        _camera.trace = _tracePosition(segments.toInt());
        if (_camera.trace >= segments - 0.001 && _exitReachedAt < 0) {
          _exitReachedAt = _clock;
        }
      }
    } else {
      final x = _exitLatLon();
      if (stage == ConnectStage.routeFound && x != null) {
        _camera
          ..latitude = x.latitude
          ..longitude = x.longitude;
      }
      _camera.trace = _routeArcs.length.toDouble();
      if (_traceCompleteAt < 0) _traceCompleteAt = _clock;
      if (stage == ConnectStage.routeFound && _exitReachedAt < 0) {
        _exitReachedAt = _clock;
      }
    }
    _updateHopShown();
    _camera.notify();
    SharedGlobeController.instance
        .syncRotation(_camera.latitude, _camera.longitude);

    // --- leave the globe once "ROUTE FOUND" has been seen ---
    if (_leavingToExit &&
        _globeScene &&
        stage == ConnectStage.routeFound &&
        _exitReachedAt >= 0) {
      // The exit has been reached: hold ROUTE FOUND, then zoom in.
      final held = _clock - _exitReachedAt;
      final x = _exitLatLon();
      final aligned = x == null ||
          (angleDelta(_camera.longitude, x.longitude).abs() < 4 &&
              (_camera.latitude - x.latitude).abs() < 4);
      if (held >= _routeFoundHold.inMilliseconds / 1000.0 &&
          (aligned || held > 3.5)) {
        _leaveGlobe(instant: false);
      }
    }

    if (previousStage != _shownStage && mounted) setState(() {});
    if (!_globeScene && _globeMix.value == 0) _syncGlobeTicker();
  }

  void _updateHopShown() {
    final n = _route.activeHops.length;
    if (n == 0) return;
    if (_shownStage == ConnectStage.routeFound) {
      _hopShown.value = n;
      return;
    }
    var reached = _firstHopReached;
    final t = _camera.trace;
    for (var s = 0; s < _arcEndHop.length; s++) {
      if (t >= s + 1 && _arcEndHop[s] >= 0) reached = _arcEndHop[s] + 1;
    }
    _hopShown.value = math.min(n, reached + 1);
  }

  // ---------------------------------------------------------------------
  // Camera (flat map)

  void _scheduleFocus({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_userMoved && !force) return;
      // Behind the globe the camera jumps; on screen it glides.
      final visible = _globeMix.value < 0.5;
      _animateTo(_focusTarget(),
          animate: visible && (!force || _tc.value != Matrix4.identity()));
    });
  }

  MapViewTransform _focusTarget() {
    final p = _provider;
    if (p == null || _viewport.isEmpty || _mapSize.isEmpty) {
      return MapViewTransform.identity;
    }
    Offset toMap(Offset n) =>
        Offset(n.dx * _mapSize.width, n.dy * _mapSize.height);

    // The exit country while the tunnel is up, the user's own otherwise.
    final useExit = p.tunnelActive && _exitTo != null;
    final point = useExit ? _exitTo : (_origin ?? _exitTo);
    final country = useExit
        ? _exitCountry
        : (_origin != null ? _originCountry : _exitCountry);

    // The focused country fills about half the width, a little right of
    // centre (design: India spans ~33%..83% of the width).
    final w = _viewport.width;
    final padding = widget.compact
        ? EdgeInsets.fromLTRB(w * 0.22, 16, w * 0.22, 16)
        : EdgeInsets.fromLTRB(
            w * 0.30, 24, w * 0.20, math.max(28.0, widget.bottomInset + 8));
    if (point == null) {
      return MapViewTransform.focus(
        points: [Offset(_mapSize.width / 2, _mapSize.height * 0.42)],
        viewport: _viewport,
        mapSize: _mapSize,
        singlePointScale: 1.0,
      );
    }
    // Frame the country, but never tighter than a region about 30° of
    // longitude wide: small countries (Netherlands, Singapore) are shown
    // with their surroundings, as in the design.
    var region = Rect.fromCenter(center: point, width: 0, height: 0);
    if (country != null && country.mainBounds.inflate(0.03).contains(point)) {
      region = country.mainBounds;
    }
    const minW = 0.085;
    final minH = minW * MapProjection.aspectRatio * 0.62;
    if (region.width < minW || region.height < minH) {
      region = Rect.fromCenter(
        center: region.center,
        width: math.max(region.width, minW),
        height: math.max(region.height, minH),
      );
    }
    return MapViewTransform.focus(
      points: [toMap(point), toMap(region.topLeft), toMap(region.bottomRight)],
      viewport: _viewport,
      mapSize: _mapSize,
      maxScale: 7.0,
      padding: padding,
    );
  }

  void _animateTo(MapViewTransform target, {bool animate = true}) {
    final end = Matrix4.fromList(target.toStorage());
    if (!animate || _reduceMotion) {
      _focus.stop();
      _tc.value = end;
      return;
    }
    _focusTween = Matrix4Tween(begin: _tc.value.clone(), end: end);
    _focus.forward(from: 0);
  }

  void _onFocusTick() {
    final tween = _focusTween;
    if (tween == null) return;
    _tc.value =
        tween.transform(Curves.easeInOutCubic.transform(_focus.value));
  }

  void _onInteractionStart(ScaleStartDetails details) {
    _focus.stop();
    _userMoved = true;
  }

  void _zoomBy(double factor) {
    final t = _transform;
    final newScale = (t.scale * factor).clamp(1.0, _maxScale);
    final centre = Offset(_viewport.width / 2, _viewport.height / 2);
    final mapCentre = t.toMap(centre);
    final target = MapViewTransform.clamp(
      MapViewTransform(newScale, centre - mapCentre * newScale),
      viewport: _viewport,
      mapSize: _mapSize,
    );
    _userMoved = true;
    _animateTo(target);
  }

  void _recenter() {
    _userMoved = false;
    setState(() => _selected = null);
    _animateTo(_focusTarget());
  }

  // ---------------------------------------------------------------------
  // Taps on markers

  Offset? _markerScreen(_MarkerKind kind) {
    final n = kind == _MarkerKind.origin ? _origin : _currentExitNormalized();
    if (n == null) return null;
    return _transform
        .toScreen(Offset(n.dx * _mapSize.width, n.dy * _mapSize.height));
  }

  void _onTapUp(TapUpDetails details) {
    if (_globeMix.value > 0) return;
    final pos = details.localPosition;
    _MarkerKind? hit;
    var best = 30.0;
    for (final kind in _MarkerKind.values) {
      final s = _markerScreen(kind);
      if (s == null) continue;
      final d = (s - pos).distance;
      if (d < best) {
        best = d;
        hit = kind;
      }
    }
    setState(() => _selected = hit == _selected ? null : hit);
  }

  // ---------------------------------------------------------------------
  // Build

  @override
  void didUpdateWidget(covariant VpnWorldMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.darkTheme != widget.darkTheme) {
      _refreshMarkerLabels();
    }
    if ((oldWidget.bottomInset != widget.bottomInset ||
            oldWidget.compact != widget.compact) &&
        !_userMoved) {
      _scheduleFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = VpnMapPalette.of(widget.darkTheme);
    final home = VpnHomeStyle.of(widget.darkTheme);
    return ClipRect(
      child: LayoutBuilder(builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        if (viewport != _viewport) {
          final aspect = MapProjection.aspectRatio;
          var mapSize = Size(viewport.height * aspect, viewport.height);
          if (mapSize.width < viewport.width) {
            mapSize = Size(viewport.width, viewport.width / aspect);
          }
          final firstLayout = _viewport.isEmpty;
          _viewport = viewport;
          _mapSize = mapSize;
          if (!viewport.isEmpty) {
            if (firstLayout) {
              _scheduleFocus(force: true);
            } else {
              // Resize (panel expanded/collapsed, rotation): re-frame.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_userMoved) {
                  _animateTo(_focusTarget(), animate: false);
                }
              });
            }
          }
        }

        final data = _data;
        final flatOpacity = ReverseAnimation(_globeMix);
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: _onTapUp,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ---------------- radial glow behind map and globe ----------
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: home.mapBackground,
                  ),
                ),
              ),
              // ---------------- flat map ----------------
              Positioned.fill(
                child: FadeTransition(
                  opacity: flatOpacity,
                  child: Stack(
                      children: [
                        Positioned.fill(
                            child: ColoredBox(color: palette.ocean)),
                        if (data != null && !_mapSize.isEmpty)
                          Positioned.fill(child: _buildInteractive(data, palette)),
                        // Vignette: the map fades into the edges (design).
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(0, -0.45),
                                  radius: 1.15,
                                  colors: [
                                    home.mapEdge.withOpacity(0),
                                    home.mapEdge.withOpacity(0),
                                    home.mapEdge.withOpacity(home.dark ? 0.6 : 0.85),
                                  ],
                                  stops: const [0.0, 0.55, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!_mapSize.isEmpty)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: VpnOverlayPainter(
                                    mapSize: _mapSize,
                                    transform: () => _transform,
                                    palette: palette,
                                    phase: _phase ?? VpnMapPhase.disconnected,
                                    loop: _loop,
                                    highlight: _highlight,
                                    exitMove: _exitMove,
                                    origin: _origin,
                                    exitFrom: _exitFrom,
                                    exitTo: _exitTo,
                                    originCountry: _originCountry,
                                    exitCountry: _exitCountry,
                                    originLabel: _originLabel,
                                    exitLabel: _exitLabel,
                                    selectedExit: _selected == _MarkerKind.exit,
                                    showLabels: false,
                                    repaint: Listenable.merge(
                                        [_loop, _highlight, _exitMove, _tc]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ),
              ),
              // ---------------- globe ----------------
              if (data != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _globeMix,
                      builder: (context, child) => _globeMix.value == 0
                          ? const SizedBox.shrink()
                          : Opacity(
                              opacity: Curves.easeIn
                                  .transform(_globeMix.value)
                                  .clamp(0.0, 1.0),
                              child: child,
                            ),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _globePainter(data, palette),
                        ),
                      ),
                    ),
                  ),
                ),
              if (data == null)
                Positioned.fill(
                  child: Center(
                    child: _loadError != null
                        ? Text(
                            'Map unavailable',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: palette.label,
                            ),
                          )
                        : SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.exit,
                            ),
                          ),
                  ),
                ),
              if (_selected != null && !_globeScene) _buildPopup(palette),
              // Shadow under the app bar: the map fades into the bar colour
              // at the top, so no hard horizontal edge (design).
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 64,
                child: IgnorePointer(
                  // Lighter over the globe so its top and the spin arrow
                  // stay visible.
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 1, end: 0.35)
                        .animate(_globeMix),
                    child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          home.headerBackground,
                          home.headerBackground.withOpacity(0.75),
                          home.headerBackground.withOpacity(0),
                        ],
                        stops: const [0.0, 0.35, 1.0],
                      ),
                    ),
                  ),
                  ),
                ),
              ),
              if (widget.showStatus)
                Positioned(
                  left: 18,
                  right: 64,
                  bottom: 12,
                  child: AnimatedOpacity(
                    opacity: widget.compact ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: _StatusBlock(
                    dark: widget.darkTheme,
                    phase: _phase ?? VpnMapPhase.disconnected,
                    stage: _globeScene || _globeMix.value > 0.5
                        ? _shownStage
                        : null,
                    hopShown: _hopShown,
                    hopTotal: _route.activeHops.length,
                    // Every hop linked, tunnel not ready yet.
                    waiting: _shownStage == ConnectStage.hoppingNodes &&
                        _traceCompleteAt >= 0,
                    ),
                  ),
                ),
              Positioned(
                right: 12,
                bottom: 12,
                child: AnimatedBuilder(
                  animation: _globeMix,
                  builder: (context, child) => IgnorePointer(
                    ignoring: _globeMix.value > 0.05 || widget.compact,
                    child: Opacity(
                      opacity: widget.compact
                          ? 0
                          : (1 - _globeMix.value * 1.6).clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                  child: _MapControls(
                    dark: widget.darkTheme,
                    onZoomIn: () => _zoomBy(1.6),
                    onZoomOut: () => _zoomBy(1 / 1.6),
                    onRecenter: _recenter,
                  ),
                ),
              ),
              ...?widget.overlay,
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInteractive(WorldMapData data, VpnMapPalette palette) {
    return InteractiveViewer(
      transformationController: _tc,
      constrained: false,
      minScale: 1.0,
      maxScale: _maxScale,
      boundaryMargin: EdgeInsets.zero,
      clipBehavior: Clip.none,
      onInteractionStart: _onInteractionStart,
      child: SizedBox.fromSize(
        size: _mapSize,
        child: RepaintBoundary(
          child: ValueListenableBuilder<Matrix4>(
            valueListenable: _tc,
            builder: (context, m, _) {
              // Bucket the zoom so the static layer repaints only on large
              // zoom changes.
              final scale = m.storage[0];
              final bucket = math
                  .pow(2, (math.log(scale) / math.ln2 * 2).round() / 2)
                  .toDouble();
              return CustomPaint(
                size: _mapSize,
                isComplex: true,
                willChange: false,
                painter: BaseMapPainter(
                  data: data,
                  palette: palette,
                  borderWidth: 0.7 / bucket,
                  showGraticule: false,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  GlobePainter _globePainter(WorldMapData data, VpnMapPalette palette) {
    final stage = _shownStage;
    final finding = stage == null || stage == ConnectStage.findingRoute;
    final found = stage == ConnectStage.routeFound;
    final o = _provider?.originalLocation;
    return GlobePainter(
      geometry: GlobeGeometry.of(data),
      camera: _camera,
      palette: palette,
      // Design: the user's country is lit only while the route is searched.
      highlight: finding ? _originCountry : null,
      // On the globe the user's country reads a touch lighter (design).
      highlightColor: widget.darkTheme
          ? const Color(0xFF4A4A4A)
          : palette.originHighlight,
      highlightBorder: palette.originHighlightBorder,
      origin: o != null && o.hasCoordinates
          ? (latitude: o.latitude, longitude: o.longitude)
          : null,
      // The user stays marked as the start of the route in every stage.
      showOrigin: true,
      exit: _exitLatLon(),
      exitActive: found,
      hops: finding ? const [] : _hopDots,
      // Only the hops of the current path (not every node in use).
      otherNodes: const [],
      routeArcs: _routeArcs,
      // Hops then exit are connected one by one (solid green, growing).
      routeMode: finding ? GlobeRouteMode.none : GlobeRouteMode.tracing,
      // The route starts at the user, so the first arc is origin -> hop 1.
      firstHopArc: _routeHasOrigin ? 1 : 0,
      // Leg still to come, drawn as moving dashes (never as "connected").
      pendingArc: finding ? _seekArc : (found ? null : _pendingExitArc),
      showSeek: finding,
      // Destination is shown as a hollow ring until the tunnel is up.
      showDestination: stage != null,
      // No arrow above the globe any more.
      showSpinArrow: false,
    );
  }

  Widget _buildPopup(VpnMapPalette palette) {
    final kind = _selected!;
    final p = _provider!;
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([_tc, _exitMove]),
        builder: (context, _) {
          final at = _markerScreen(kind);
          if (at == null) return const SizedBox.shrink();
          const width = 220.0;
          final double maxLeft =
              math.max<double>(8.0, _viewport.width - width - 8);
          final double left = (at.dx - width / 2).clamp(8.0, maxLeft);
          final below = at.dy < _viewport.height * 0.55;
          return Stack(
            children: [
              Positioned(
                left: left,
                top: below ? at.dy + 18 : null,
                bottom: below ? null : _viewport.height - at.dy + 18,
                width: width,
                child: _MarkerPopup(
                  dark: widget.darkTheme,
                  accent: kind == _MarkerKind.origin
                      ? palette.origin
                      : (p.phase == VpnMapPhase.failed
                          ? palette.failed
                          : palette.exit),
                  title: kind == _MarkerKind.origin
                      ? 'Your location'
                      : 'VPN exit server',
                  rows: kind == _MarkerKind.origin
                      ? _originRows(p)
                      : _exitRows(p),
                  onClose: () => setState(() => _selected = null),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<MapEntry<String, String>> _originRows(VpnMapProvider p) {
    final loc = p.originalLocation;
    return [
      MapEntry('Public IP', p.originalIp ?? '—'),
      MapEntry('Location',
          loc?.displayName.isNotEmpty == true ? loc!.displayName : '—'),
      if (loc?.region != null) MapEntry('Region', loc!.region!),
      MapEntry('Status', p.tunnelActive ? 'Hidden by BelNet' : 'Exposed'),
    ];
  }

  List<MapEntry<String, String>> _exitRows(VpnMapProvider p) {
    final exit = p.exit;
    final loc = exit.location;
    final where = loc?.displayName.isNotEmpty == true
        ? loc!.displayName
        : (exit.country ?? '—');
    return [
      MapEntry('Exit node', exit.nodeName),
      MapEntry('Location', where),
      MapEntry('Exit IP', p.exitIp ?? '—'),
      MapEntry('Status', _phaseLabel(p.phase)),
      if (loc != null)
        MapEntry(
            'Source',
            exit.locationIsLastKnown
                ? 'Last known (${_sourceLabel(loc.source)})'
                : _sourceLabel(loc.source)),
    ];
  }
}

String _phaseLabel(VpnMapPhase phase) {
  switch (phase) {
    case VpnMapPhase.connected:
      return 'Connected';
    case VpnMapPhase.connecting:
      return 'Connecting…';
    case VpnMapPhase.disconnecting:
      return 'Disconnecting…';
    case VpnMapPhase.failed:
      return 'Connection failed';
    case VpnMapPhase.disconnected:
      return 'Selected, not connected';
  }
}

String _sourceLabel(GeoLocationSource source) {
  switch (source) {
    case GeoLocationSource.nodeMetadata:
      return 'Exit-node list';
    case GeoLocationSource.builtInDefault:
      return 'Default exit node';
    case GeoLocationSource.ipLookup:
      return 'IP geolocation';
  }
}

/// Status block at the bottom-left of the map:
///
///   ● UNPROTECTED        ● CONNECTING        ● PROTECTED
///   INDIA                HOPPING NODES       NETHERLANDS
///   Your location · IP   Hop 2 of 4 · ...    Exit node · IP hidden
class _StatusBlock extends StatelessWidget {
  const _StatusBlock({
    required this.dark,
    required this.phase,
    required this.stage,
    required this.hopShown,
    required this.hopTotal,
    this.waiting = false,
  });

  final bool waiting;
  final bool dark;
  final VpnMapPhase phase;

  /// Connecting stage currently shown by the globe (null on the flat map).
  final ConnectStage? stage;
  final ValueListenable<int> hopShown;
  final int hopTotal;

  @override
  Widget build(BuildContext context) {
    final s = VpnHomeStyle.of(dark);
    final p = context.watch<VpnMapProvider>();
    final exitName = _exitCountryName(p);

    late final Color dot;
    late final String label;
    late final String title;
    late Widget detail;
    var blinking = false;

    if (stage != null) {
      switch (stage!) {
        case ConnectStage.findingRoute:
          dot = s.textMuted;
          label = 'CONNECTING';
          title = 'FINDING ROUTE';
          detail = Text('Searching Beldex nodes…', style: s.mono());
          blinking = true;
          break;
        case ConnectStage.hoppingNodes:
          dot = s.textMuted;
          label = 'CONNECTING';
          title = 'HOPPING NODES';
          detail = ValueListenableBuilder<int>(
            valueListenable: hopShown,
            builder: (context, k, _) => Text(
              waiting
                  ? (hopTotal > 0
                      ? 'Hop $hopTotal of $hopTotal · waiting for exit node…'
                      : 'Waiting for exit node…')
                  : hopTotal > 0
                      ? 'Hop ${math.min(k, hopTotal)} of $hopTotal · onion routing'
                      : 'Onion routing',
              style: s.mono(),
            ),
          );
          blinking = true;
          break;
        case ConnectStage.routeFound:
          dot = s.green;
          label = 'ROUTE FOUND';
          title = exitName;
          detail = Text('Securing tunnel…', style: s.mono());
          break;
      }
    } else {
      switch (phase) {
        case VpnMapPhase.connected:
          dot = s.green;
          label = 'PROTECTED';
          title = exitName;
          detail = Text('Exit node · IP hidden', style: s.mono());
          break;
        case VpnMapPhase.connecting:
          dot = s.textMuted;
          label = 'CONNECTING';
          title = 'FINDING ROUTE';
          detail = Text('Searching Beldex nodes…', style: s.mono());
          blinking = true;
          break;
        case VpnMapPhase.disconnecting:
          dot = s.amber;
          label = 'DISCONNECTING';
          title = exitName;
          detail = Text('Closing tunnel…', style: s.mono());
          blinking = true;
          break;
        case VpnMapPhase.failed:
          dot = s.red;
          label = 'CONNECTION FAILED';
          title = exitName;
          detail = Text(p.failureReason ?? 'Could not connect',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: s.mono());
          break;
        case VpnMapPhase.disconnected:
          dot = s.red;
          label = 'UNPROTECTED';
          title = _originCountryName(p);
          final ip = p.originalIp;
          detail = Text(
            ip != null
                ? 'Your location · $ip'
                : (p.originalLocationLoading
                    ? 'Your location · detecting…'
                    : 'Your location'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: s.mono(),
          );
          break;
      }
    }

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 0.15), end: Offset.zero)
                .animate(anim),
            child: child,
          ),
        ),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.bottomLeft,
          children: [...previous, if (current != null) current],
        ),
        child: Column(
          key: ValueKey('$label|$title'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BlinkDot(color: dot, blinking: blinking),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: s.label(
                    // PROTECTED / ROUTE FOUND are green in the design.
                    color: identical(dot, s.green)
                        ? s.green
                        : (label == 'CONNECTION FAILED' ? s.red : null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(title, maxLines: 1, style: s.title()),
            ),
            const SizedBox(height: 5),
            detail,
          ],
        ),
      ),
    );
  }

  static String _exitCountryName(VpnMapProvider p) {
    final name = p.exit.location?.country ?? p.exit.country;
    return (name == null || name.trim().isEmpty)
        ? 'EXIT NODE'
        : name.trim().toUpperCase();
  }

  static String _originCountryName(VpnMapProvider p) {
    final name = p.originalLocation?.country;
    if (name != null && name.trim().isNotEmpty) return name.trim().toUpperCase();
    if (p.originalLocationLoading) return 'LOCATING…';
    return 'UNKNOWN';
  }
}

class _BlinkDot extends StatefulWidget {
  const _BlinkDot({required this.color, required this.blinking});

  final Color color;
  final bool blinking;

  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void initState() {
    super.initState();
    if (widget.blinking) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _BlinkDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blinking && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.blinking && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.3).animate(_c),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: widget.color.withOpacity(0.6), blurRadius: 5),
          ],
        ),
      ),
    );
  }
}

class _MarkerPopup extends StatelessWidget {
  const _MarkerPopup({
    required this.dark,
    required this.accent,
    required this.title,
    required this.rows,
    required this.onClose,
  });

  final bool dark;
  final Color accent;
  final String title;
  final List<MapEntry<String, String>> rows;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xF21A1A1A) : const Color(0xF7FFFFFF);
    final fg = dark ? const Color(0xFFEBEBEB) : const Color(0xFF222222);
    final muted = dark ? const Color(0xFF9A9A9A) : const Color(0xFF6B6B6B);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accent.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: fg,
                    ),
                  ),
                ),
                InkResponse(
                  onTap: onClose,
                  radius: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 15, color: muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(top: 3, right: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 66,
                      child: Text(
                        row.key,
                        style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 10.5, color: muted),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 10.5, color: fg),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Zoom in / zoom out / recenter: separate square buttons, as designed.
class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.dark,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
  });

  final bool dark;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    final s = VpnHomeStyle.of(dark);
    Widget button(IconData icon, String tooltip, VoidCallback onTap) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: s.controlFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: dark ? BorderSide(color: s.controlBorder) : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Icon(icon, size: 16, color: s.controlIcon),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(Icons.add, 'Zoom in', onZoomIn),
        const SizedBox(height: 4),
        button(Icons.remove, 'Zoom out', onZoomOut),
        const SizedBox(height: 12),
        button(Icons.my_location, 'Recenter', onRecenter),
      ],
    );
  }
}
