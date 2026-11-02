import 'dart:math' as math;

import 'package:belnet_mobile/src/map/geo_location.dart';
import 'package:belnet_mobile/src/map/map_projection.dart';
import 'package:belnet_mobile/src/map/vpn_map_provider.dart';
import 'package:belnet_mobile/src/map/world_map_data.dart';
import 'package:belnet_mobile/src/map/world_map_painters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

enum _MarkerKind { origin, exit }

/// Interactive, Proton-style world map. Disconnected it zooms to the user's
/// own country (original public-IP location); connecting/connected it zooms
/// to the exit server's country and highlights it. No route line is drawn.
///
/// Reads everything from [VpnMapProvider]; it never changes connection
/// state itself.
class VpnWorldMap extends StatefulWidget {
  const VpnWorldMap({
    super.key,
    required this.darkTheme,
    this.bottomInset = 0,
    this.overlay,
  });

  final bool darkTheme;

  /// Space covered by a panel at the bottom of the map; auto-focus keeps
  /// markers above it.
  final double bottomInset;

  /// Widgets drawn on top of the map (status chip, info panel, ...).
  final List<Widget>? overlay;

  @override
  State<VpnWorldMap> createState() => _VpnWorldMapState();
}

class _VpnWorldMapState extends State<VpnWorldMap>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const double _maxScale = 8.0;

  final TransformationController _tc = TransformationController();
  late final AnimationController _loop;
  late final AnimationController _highlight;
  late final AnimationController _exitMove;
  late final AnimationController _focus;
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
      // Start live stats after this frame: starting them synchronously
      // would notify sibling widgets while the tree is being built.
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
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // No frames while backgrounded, and no status polling either.
      p.setMapVisible(false);
      _loop.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _provider?.removeListener(_onProviderChanged);
    _provider?.setMapVisible(false);
    _loop.dispose();
    _highlight.dispose();
    _exitMove.dispose();
    _focus.dispose();
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
    // Providers are sometimes poked while a frame is being built (e.g. a
    // lazily created provider notifying from its constructor chain); defer
    // to after the frame instead of calling setState mid-build.
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
    final previousPhase = _phase;
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
    final exitChanged = newExit != _exitTo;
    if (exitChanged) {
      final current = _currentExitNormalized();
      _exitTo = newExit;
      if (current != null && newExit != null && !initial && !_reduceMotion) {
        // Glide the server marker (and the route end) to the new exit.
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

  /// Fades the emphasis from the user's country to the exit country (and
  /// back). Disconnecting fades out while the tunnel tears down.
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
        // Stop everything; the painter shows the failed exit in red.
        _highlight.stop();
        _highlight.value = 0;
        break;
    }
  }

  void _syncLoop() {
    final shouldRun = !_reduceMotion &&
        _phase != VpnMapPhase.failed &&
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
    // By name first, then by position: catches spellings the name table
    // does not know ("Türkiye", localised names) and custom exit nodes whose
    // country only comes from IP geolocation.
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
    final exitPlace = exit.location?.city ?? exit.location?.country ?? exit.country;
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

  static String _shortNode(String name) =>
      name.length <= 14 ? name : '${name.substring(0, 6)}…${name.substring(name.length - 6)}';

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
  // Camera

  void _scheduleFocus({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_userMoved && !force) return;
      _animateTo(_focusTarget(), animate: !force || _tc.value != Matrix4.identity());
    });
  }

  MapViewTransform _focusTarget() {
    final p = _provider;
    if (p == null || _viewport.isEmpty || _mapSize.isEmpty) {
      return MapViewTransform.identity;
    }
    Offset toMap(Offset n) =>
        Offset(n.dx * _mapSize.width, n.dy * _mapSize.height);

    // Proton-style country zoom: the exit country while the tunnel is up,
    // the user's own country otherwise.
    final useExit = p.tunnelActive && _exitTo != null;
    final point = useExit ? _exitTo : (_origin ?? _exitTo);
    final country = useExit
        ? _exitCountry
        : (_origin != null ? _originCountry : _exitCountry);

    final padding = EdgeInsets.fromLTRB(
        40, 64, 56, math.max(40.0, widget.bottomInset + 28));
    if (point == null) {
      // Nothing known yet: whole map, centred.
      return MapViewTransform.focus(
        points: [Offset(_mapSize.width / 2, _mapSize.height * 0.42)],
        viewport: _viewport,
        mapSize: _mapSize,
        singlePointScale: 1.0,
      );
    }
    final points = <Offset>[toMap(point)];
    // Only frame the country when the marker is actually in/near it (the
    // marker must always stay visible).
    if (country != null &&
        country.mainBounds.inflate(0.03).contains(point)) {
      final b = country.mainBounds;
      points
        ..add(toMap(b.topLeft))
        ..add(toMap(b.bottomRight));
    }
    return MapViewTransform.focus(
      points: points,
      viewport: _viewport,
      mapSize: _mapSize,
      maxScale: 7.0,
      // Countries missing from the 110m outlines (Singapore, Hong Kong,
      // ...) still get a close-up of the marker.
      singlePointScale: 5.0,
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
    final pos = details.localPosition;
    _MarkerKind? hit;
    var best = 30.0; // finger-friendly hit radius in logical pixels
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
  }

  @override
  Widget build(BuildContext context) {
    final palette = VpnMapPalette.of(widget.darkTheme);
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
              // Rotation / resize: re-frame without animation.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _animateTo(_focusTarget(), animate: false);
              });
            }
          }
        }

        final data = _data;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: _onTapUp,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(child: ColoredBox(color: palette.ocean)),
              if (data != null && !_mapSize.isEmpty)
                Positioned.fill(
                  child: InteractiveViewer(
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
                            // Bucket the zoom so the static layer repaints
                            // only on large zoom changes.
                            final scale = m.storage[0];
                            final bucket = math.pow(
                                    2,
                                    (math.log(scale) / math.ln2 * 2).round() /
                                        2)
                                .toDouble();
                            return CustomPaint(
                              size: _mapSize,
                              isComplex: true,
                              willChange: false,
                              painter: BaseMapPainter(
                                data: data,
                                palette: palette,
                                borderWidth: 0.7 / bucket,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              if (data != null && !_mapSize.isEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: CountryLabelPainter(
                          data: data,
                          mapSize: _mapSize,
                          transform: () => _transform,
                          palette: palette,
                          labelCache: _labelCache,
                          repaint: _tc,
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
                          repaint:
                              Listenable.merge([_loop, _highlight, _exitMove, _tc]),
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
              if (_selected != null) _buildPopup(palette),
              Positioned(
                right: 10,
                top: 10,
                child: _MapControls(
                  dark: widget.darkTheme,
                  onZoomIn: () => _zoomBy(1.6),
                  onZoomOut: () => _zoomBy(1 / 1.6),
                  onRecenter: _recenter,
                ),
              ),
              ...?widget.overlay,
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPopup(VpnMapPalette palette) {
    final kind = _selected!;
    final p = _provider!;
    // Positioned must be a direct child of a Stack, so the popup layer is
    // its own (hit-transparent) Stack that follows the marker.
    return Positioned.fill(
      child: AnimatedBuilder(
      animation: Listenable.merge([_tc, _exitMove]),
      builder: (context, _) {
        final at = _markerScreen(kind);
        if (at == null) return const SizedBox.shrink();
        const width = 220.0;
        // math.max<double> explicitly: inside clamp()'s num-typed parameter
        // it would otherwise infer num and make `left` a num.
        final double maxLeft =
            math.max<double>(8.0, _viewport.width - width - 8);
        final double left = (at.dx - width / 2).clamp(8.0, maxLeft);
        // Prefer below the marker; flip above near the bottom.
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
                rows:
                    kind == _MarkerKind.origin ? _originRows(p) : _exitRows(p),
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
      MapEntry('Location', loc?.displayName.isNotEmpty == true ? loc!.displayName : '—'),
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
    final bg = dark ? const Color(0xF21A1D22) : const Color(0xF7FFFFFF);
    final fg = dark ? const Color(0xFFEBEBEB) : const Color(0xFF222222);
    final muted = dark ? const Color(0xFF9A9A9A) : const Color(0xFF6B6B6B);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
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
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
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
    final bg = dark ? const Color(0xCC1A1D22) : const Color(0xE6FFFFFF);
    final fg = dark ? const Color(0xFFEBEBEB) : const Color(0xFF222222);
    Widget button(IconData icon, String tooltip, VoidCallback onTap) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 18, color: fg),
          ),
        ),
      );
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.add, 'Zoom in', onZoomIn),
          Container(height: 1, width: 22, color: fg.withOpacity(0.12)),
          button(Icons.remove, 'Zoom out', onZoomOut),
          Container(height: 1, width: 22, color: fg.withOpacity(0.12)),
          button(Icons.my_location, 'Recenter', onRecenter),
        ],
      ),
    );
  }
}
