import 'dart:async';
import 'dart:math' as math;

import 'package:belnet_mobile/bottom_nav_bar.dart';
import 'package:belnet_mobile/src/map/geo_location.dart';
import 'package:belnet_mobile/src/map/globe_painter.dart';
import 'package:belnet_mobile/src/map/globe_projection.dart';
import 'package:belnet_mobile/src/map/map_projection.dart';
import 'package:belnet_mobile/src/map/shared_globe.dart';
import 'package:belnet_mobile/src/map/world_map_data.dart';
import 'package:belnet_mobile/src/map/world_map_painters.dart';
import 'package:belnet_mobile/src/providers/ip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences flag: the V3 onboarding has been completed.
const String kOnboardingSeenKey = 'onboarding_v3_seen';

/// Intro globe: the one-time onboarding on first launch, and the launch
/// (splash) screen on every later launch.
///
/// Both use the same globe, so the app always opens the same way and hands
/// over to home without a jump. On later launches the text and Next are not
/// shown: after a short beat the globe rises, finds the user and zooms into
/// home by itself (and nothing is written to preferences).
///
/// 1. Logo, "FAST & SECURE DVPN" and Next, with the globe parked at the
///    bottom, turning slowly.
/// 2. Next: the text fades out, the globe rises to the centre and spins
///    while the user's location is looked up (the same lookup the home
///    screen uses, so its result is ready there).
/// 3. Located: the globe turns to the user's country and lights it up.
/// 4. It zooms into that country and fades into the home screen, whose map
///    opens on the same country.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { intro, rising, searching, focusing, zooming }

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  static const _background = Color(0xFF0D0D0D);

  /// Globe size (GlobePainter zoom): parked low and huge behind the intro
  /// (top edge at ~70% of the height, design frame 1), then centred with a
  /// radius of ~0.76 x the width (frame 2).
  static const double _parkZoom = 3.35;
  static const double _centerZoom = 2.15;

  /// After Next the centred globe sits a little lower than the middle and
  /// stays large (fraction of the height it is moved down).
  static const double _centerDrop = 0.05;

  /// Extra zoom into the user's country at the end, while home fades in.
  static const double _finalZoom = 3.2;

  /// Spin at least this long after the globe is centred, so the search
  /// reads as a search even when the location is already known.
  static const double _minSearch = 1.4;

  /// Give up on the location after this long and go home anyway.
  static const double _maxSearch = 10;

  /// Launch (splash) mode: a much shorter search, and no long wait for a
  /// location (home keeps looking it up).
  static const double _splashMinSearch = 0.4;
  static const double _splashMaxSearch = 2.5;

  /// null until the preferences are read; true = first launch (onboarding).
  bool? _firstLaunch;
  Timer? _autoStart;

  final GlobeCamera _camera = GlobeCamera();
  late final Ticker _ticker;
  late final AnimationController _ui; // 1 = intro visible
  late final AnimationController _rise; // 0 = parked at the bottom
  late final AnimationController _zoom;

  WorldMapData? _data;
  _Step _step = _Step.intro;
  Duration? _lastTick;
  double _clock = 0;
  double _searchStart = 0;

  GeoLocation? _found;
  bool _lookupDone = false;
  CountryShape? _country;
  Timer? _poll;
  bool _navigated = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _camera
      ..latitude = 8
      ..longitude = 18
      ..zoom = _parkZoom;
    // Hidden until we know whether this is the first launch (the native
    // launch screen is plain dark too, so nothing jumps).
    _ui = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450), value: 0);
    _rise = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && _step == _Step.rising) {
          _searchStart = _clock;
          if (mounted) setState(() => _step = _Step.searching);
        }
      });
    _zoom = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..addListener(() {
        // Home starts fading in while the globe is still zooming, so the
        // zoom flows straight into the home map.
        if (_zoom.value >= 0.45) _goHome();
      });
    _ticker = createTicker(_tick)..start();

    WorldMapData.load().then((data) {
      if (mounted) setState(() => _data = data);
    }).catchError((Object _) {});

    // Start the location lookup right away; by the time Next is tapped it
    // is often already known.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startLookup());
    _readFirstLaunch();
  }

  Future<void> _readFirstLaunch() async {
    var first = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      first = !(prefs.getBool(kOnboardingSeenKey) ?? false);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _firstLaunch = first);
    if (first) {
      _ui.forward();
      return;
    }
    // Launch screen: show the logo for a beat, then go.
    if (_reduceMotion) {
      _goHome();
      return;
    }
    _ui.forward();
    _autoStart = Timer(const Duration(milliseconds: 650), _startFlow);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  @override
  void dispose() {
    _poll?.cancel();
    _autoStart?.cancel();
    _ticker.dispose();
    _ui.dispose();
    _rise.dispose();
    _zoom.dispose();
    _camera.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Location

  void _startLookup() {
    if (!mounted) return;
    final ip = context.read<IpProvider>();
    unawaited(ip.ensureOriginalLocation());
    _checkLocation(ip);
    _poll = Timer.periodic(
        const Duration(milliseconds: 250), (_) => _checkLocation(ip));
  }

  void _checkLocation(IpProvider ip) {
    final loc = ip.originalLocation;
    if (loc != null && loc.hasCoordinates) {
      _found = loc;
      _lookupDone = true;
    } else if (ip.originalLocationFailed && !ip.originalLocationLoading) {
      _lookupDone = true;
    }
    if (_lookupDone) {
      _poll?.cancel();
      _poll = null;
    }
  }

  // ---------------------------------------------------------------------
  // Flow

  Future<void> _onNext() async {
    if (_step != _Step.intro || _firstLaunch != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingSeenKey, true);
    await prefs.setBool('isFirstLaunch', false); // legacy flag
    if (!mounted) return;
    if (_reduceMotion) {
      _goHome();
      return;
    }
    _startFlow();
  }

  /// Rise, search, focus, zoom into home (onboarding Next, or automatic on
  /// later launches).
  void _startFlow() {
    if (!mounted || _step != _Step.intro) return;
    setState(() => _step = _Step.rising);
    _ui.reverse();
    _rise.forward();
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    // Freeze the globe where it is: home starts from this exact view.
    _zoom.stop();
    // Hand the globe's pose to the shared globe (other tabs / home), so
    // the next globe the user sees continues from here.
    final shared = SharedGlobeController.instance
      ..syncRotation(_camera.latitude, _camera.longitude);
    final f = _found;
    if (f != null && f.hasCoordinates) {
      shared.setHomeFocus((latitude: f.latitude, longitude: f.longitude));
      // Where the user's location is on screen right now, and how large
      // the map is there, so the home map can start from the same view.
      final size = MediaQuery.sizeOf(context);
      final rise = Curves.easeInOutCubic.transform(_rise.value);
      final center = Offset(
        size.width / 2,
        size.height * 0.45 +
            _parkOffset(size) * (1 - rise) +
            size.height * _centerDrop * rise,
      );
      final radius =
          math.min(size.width * 0.39, size.height * 0.36) * _camera.zoom;
      final local = GlobeProjection(_camera.latitude, _camera.longitude)
          .toScreen(f.latitude, f.longitude, center, radius);
      final box = context.findRenderObject() as RenderBox?;
      shared.setIntroHandoff(IntroHandoff(
        latitude: f.latitude,
        longitude: f.longitude,
        globalPoint: box != null && box.hasSize
            ? box.localToGlobal(local)
            : local,
        pixelsPerRadian: radius,
      ));
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => MainBottomNavbar(),
        transitionsBuilder: (_, animation, __, child) {
          // Plain cross-fade: home's map starts from the globe's exact view
          // (see IntroHandoff), so nothing should move or scale here.
          return FadeTransition(
            opacity:
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  void _tick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;
    final dt = ((elapsed - last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _clock += dt;
    _camera.pulse = (_clock / 2.2) % 1.0;
    if (_navigated) {
      // Handed over to home: hold still while it fades in on top.
      _camera.notify();
      return;
    }
    final rise = Curves.easeInOutCubic.transform(_rise.value);
    final zoomIn = Curves.easeInCubic.transform(_zoom.value);
    _camera.zoom = (_parkZoom + (_centerZoom - _parkZoom) * rise) *
        (1 + (_finalZoom - 1) * zoomIn);

    switch (_step) {
      case _Step.intro:
      case _Step.rising:
      case _Step.searching:
        // Idle turn at the bottom, faster once it is searching.
        final speed = _step == _Step.intro ? 5.0 : 26.0;
        _camera.longitude = wrapLongitude(_camera.longitude + speed * dt);
        // Intro: Europe/Africa along the visible top edge; then tilt up.
        final tilt = _step == _Step.intro ? 8.0 : 18.0;
        _camera.latitude += (tilt - _camera.latitude) * (1 - math.exp(-dt));
        if (_step == _Step.searching) {
          final searched = _clock - _searchStart;
          final splash = _firstLaunch == false;
          final ready = _lookupDone ||
              searched > (splash ? _splashMaxSearch : _maxSearch);
          if (ready &&
              searched >= (splash ? _splashMinSearch : _minSearch)) {
            final f = _found;
            if (f != null && f.hasCoordinates) {
              _country = _data?.resolveCountry(
                name: f.country,
                normalized: MapProjection.project(f.latitude, f.longitude),
              );
              setState(() => _step = _Step.focusing);
            } else {
              // No location: still finish with a zoom into home.
              setState(() => _step = _Step.zooming);
              _zoom.forward();
            }
          }
        }
        break;
      case _Step.focusing:
      case _Step.zooming:
        final f = _found;
        if (f != null) {
          // Ease towards the user's country (soft follow).
          final k = 1 - math.exp(-dt * 2.2);
          final targetLat = f.latitude.clamp(-60.0, 70.0);
          _camera.longitude = wrapLongitude(_camera.longitude +
              angleDelta(_camera.longitude, f.longitude) * k);
          _camera.latitude += (targetLat - _camera.latitude) * k;
          if (_step == _Step.focusing &&
              angleDelta(_camera.longitude, f.longitude).abs() < 1.5 &&
              (_camera.latitude - targetLat).abs() < 1.5) {
            setState(() => _step = _Step.zooming);
            _zoom.forward();
          }
        }
        break;
    }
    _camera.notify();
  }

  /// Fraction of the height where the parked globe's top edge sits.
  static const double _introHorizon = 0.70;

  /// Downward shift that parks the globe with its top edge at
  /// [_introHorizon] (GlobePainter centres it at 45% of the height).
  double _parkOffset(Size size) {
    final r = math.min(size.width * 0.39, size.height * 0.36) * _parkZoom;
    return size.height * (_introHorizon - 0.45) + r;
  }

  // ---------------------------------------------------------------------
  // Build

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final palette = VpnMapPalette.dark;
    final data = _data;
    final f = _found;
    final located = f != null && f.hasCoordinates;
    final lit = located &&
        (_step == _Step.focusing || _step == _Step.zooming);

    return Scaffold(
      backgroundColor: _background,
      extendBody: true,
      body: Stack(
        children: [
          // Faint stars (all frames).
          const Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: _StarsPainter())),
          ),
          // Intro sky: light glow above the globe's edge and vertical light
          // streaks rising from it (design frame 1). Fades as it rises.
          Positioned.fill(
            child: FadeTransition(
              opacity: _ui,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0C0C0C),
                      Color(0xFF0D0D0D),
                      Color(0xFF181818),
                      Color(0xFF0D0D0D),
                    ],
                    stops: [0.0, 0.40, 0.69, 1.0],
                  ),
                ),
                child: RepaintBoundary(
                  child: CustomPaint(
                      painter: _StreaksPainter(horizon: _introHorizon)),
                ),
              ),
            ),
          ),

          // The globe: parked low and large behind the intro, then rising
          // to the centre.
          if (data != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rise,
                builder: (context, child) {
                  // Size comes from the camera zoom (crisp lines); only the
                  // position is moved here.
                  final t = Curves.easeInOutCubic.transform(_rise.value);
                  return Transform.translate(
                    offset: Offset(
                        0,
                        _parkOffset(size) * (1 - t) +
                            size.height * _centerDrop * t),
                    child: child,
                  );
                },
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: GlobePainter(
                      geometry: GlobeGeometry.of(data),
                      camera: _camera,
                      palette: palette,
                      highlight: lit ? _country : null,
                      highlightColor: const Color(0xFF444444),
                      highlightBorder: palette.originHighlightBorder,
                      origin: located
                          ? (latitude: f!.latitude, longitude: f.longitude)
                          : null,
                      // The marker appears as it zooms in, like on home.
                      showOrigin: located && _step == _Step.zooming,
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
            ),

          // Intro: the bottom of the globe fades into a dark blue (design).
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _ui,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00050612),
                        Color(0x00050612),
                        Color(0xCC060713),
                        Color(0xFF050612),
                      ],
                      stops: [0.0, 0.78, 0.92, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Intro content.
          SafeArea(
            child: IgnorePointer(
              ignoring: _step != _Step.intro,
              child: FadeTransition(
                opacity: _ui,
                child: Column(
                  children: [
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: SvgPicture.asset(
                          'assets/images/dark_theme/belnet_onboard_logo.svg'),
                    ),
                    const Spacer(flex: 5),
                    // Launch screen: logo only (same layout, so nothing
                    // moves between the two modes).
                    Visibility(
                      visible: _firstLaunch == true,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Column(children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        border: Border.all(
                            color: const Color(0xffACACAC), width: 0.5),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'FAST & SECURE',
                            style: TextStyle(
                              fontFamily: 'Conthrax',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'DVPN',
                            style: TextStyle(
                              fontFamily: 'Conthrax',
                              color: Color(0xff8D8D8D),
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: size.height * 0.20 / 3),
                    GestureDetector(
                      onTap: _onNext,
                      child: Container(
                        height: 56,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        color: const Color(0xFFEBEBEB),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xff0B0B0B),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                      ]),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// Thin vertical light streaks rising from the globe's edge, plus a soft
/// glow along it (intro, design frame 1). Static: painted once.
class _StreaksPainter extends CustomPainter {
  const _StreaksPainter({required this.horizon});

  /// Height fraction of the globe's top edge.
  final double horizon;

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.height * horizon;
    final glow = Rect.fromCenter(
      center: Offset(size.width / 2, base),
      width: size.width * 1.8,
      height: size.height * 0.30,
    );
    canvas.drawOval(
      glow,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withOpacity(0.07),
          Colors.white.withOpacity(0),
        ]).createShader(glow),
    );
    final rnd = math.Random(7); // fixed seed: same streaks every frame
    for (var i = 0; i < 110; i++) {
      final x = rnd.nextDouble() * size.width;
      final top = size.height * (0.28 + rnd.nextDouble() * 0.30);
      final alpha = 0.025 + rnd.nextDouble() * 0.085;
      final w = rnd.nextDouble() < 0.18 ? 1.4 : 0.8;
      final rect = Rect.fromLTRB(x, top, x + w, base + 6);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.white.withOpacity(alpha),
              Colors.white.withOpacity(0),
            ],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_StreaksPainter old) => old.horizon != horizon;
}

/// A few faint stars over the dark background (all frames).
class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(3);
    final paint = Paint();
    for (var i = 0; i < 70; i++) {
      paint.color = Colors.white.withOpacity(0.05 + rnd.nextDouble() * 0.16);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.5 + rnd.nextDouble() * 0.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => false;
}
