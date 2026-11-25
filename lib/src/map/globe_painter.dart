import 'dart:math' as math;
import 'dart:typed_data';

import 'package:belnet_mobile/src/map/world_map_data.dart';
import 'package:belnet_mobile/src/map/world_map_painters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A geographic point.
typedef LatLon = ({double latitude, double longitude});

/// Camera and animation clock of the globe. One notifier for everything that
/// changes per frame, so each tick repaints the globe exactly once.
class GlobeCamera extends ChangeNotifier {
  double latitude = 20;
  double longitude = 0;

  /// Radius multiplier (1 = globe fits the view).
  double zoom = 1;

  /// Route trace position in segments (0..segment count).
  double trace = 0;

  /// 0..1 repeating clock for pulses.
  double pulse = 0;

  /// Hop the route has just reached (index in the path) and how far its
  /// arrival ripple has progressed (0..1, 1 = done).
  int arrivalHop = -1;
  double arrivalT = 1;

  void notify() => notifyListeners();
}

/// Sines/cosines of every outline vertex, computed once per map so a frame
/// only needs multiplications to rotate the globe.
class GlobeGeometry {
  GlobeGeometry._(this.countries, this._byShape);

  final List<_GeoCountry> countries;
  final Map<CountryShape, _GeoCountry> _byShape;

  static final Expando<GlobeGeometry> _cache = Expando<GlobeGeometry>();

  static GlobeGeometry of(WorldMapData data) {
    return _cache[data] ??= _build(data);
  }

  static GlobeGeometry _build(WorldMapData data) {
    const deg = math.pi / 180.0;
    final list = <_GeoCountry>[];
    final byShape = <CountryShape, _GeoCountry>{};
    for (final shape in data.countries) {
      final rings = <Float32List>[];
      for (final ring in shape.geoRings) {
        final n = ring.length ~/ 2;
        if (n < 3) continue;
        // [cosPhi, sinPhi, cosLambda, sinLambda] per vertex.
        final t = Float32List(n * 4);
        for (var i = 0; i < n; i++) {
          final lam = ring[i * 2] * deg;
          final phi = ring[i * 2 + 1] * deg;
          t[i * 4] = math.cos(phi);
          t[i * 4 + 1] = math.sin(phi);
          t[i * 4 + 2] = math.cos(lam);
          t[i * 4 + 3] = math.sin(lam);
        }
        rings.add(t);
      }
      final g = _GeoCountry(shape, rings);
      list.add(g);
      byShape[shape] = g;
    }
    return GlobeGeometry._(list, byShape);
  }

  _GeoCountry? operator [](CountryShape? shape) =>
      shape == null ? null : _byShape[shape];
}

class _GeoCountry {
  _GeoCountry(this.shape, this.rings);
  final CountryShape shape;
  final List<Float32List> rings;
}

/// Rotation of the globe for one frame.
class _Rotation {
  _Rotation(double lat, double lon)
      : sinPhi0 = math.sin(lat * math.pi / 180),
        cosPhi0 = math.cos(lat * math.pi / 180),
        sinLam0 = math.sin(lon * math.pi / 180),
        cosLam0 = math.cos(lon * math.pi / 180);

  final double sinPhi0, cosPhi0, sinLam0, cosLam0;

  /// Projected (x, y) in radius units, and z (>= 0 on the visible side).
  ({double x, double y, double z}) fromTrig(
      double cosPhi, double sinPhi, double cosLam, double sinLam) {
    final cosDl = cosLam * cosLam0 + sinLam * sinLam0;
    final sinDl = sinLam * cosLam0 - cosLam * sinLam0;
    final x = cosPhi * sinDl;
    final y = cosPhi0 * sinPhi - sinPhi0 * cosPhi * cosDl;
    final z = sinPhi0 * sinPhi + cosPhi0 * cosPhi * cosDl;
    return (x: x, y: -y, z: z);
  }

  ({double x, double y, double z}) of(double lat, double lon) {
    final phi = lat * math.pi / 180, lam = lon * math.pi / 180;
    return fromTrig(math.cos(phi), math.sin(phi), math.cos(lam), math.sin(lam));
  }
}

/// A dot on the globe (a masternode hop, the user, the exit).
@immutable
class GlobeDot {
  const GlobeDot(this.position, {this.group = ''});
  final LatLon position;

  /// Dots with the same non-empty group share a location (same country);
  /// they are fanned out slightly so each hop stays visible.
  final String group;
}

/// How the route is drawn on the globe.
enum GlobeRouteMode {
  /// No route (finding route).
  none,

  /// Hopping: the traced part is solid green, the rest dashed.
  tracing,

  /// Route found: every leg dashed, the exit glowing (design frame 04).
  dashed,
}

/// Paints the rotating Earth used while a connection is being set up:
/// outline countries, the user's country, the real masternode hops of the
/// onion route and the route itself.
class GlobePainter extends CustomPainter {
  GlobePainter({
    required this.geometry,
    required this.camera,
    required this.palette,
    required this.highlight,
    required this.highlightColor,
    required this.highlightBorder,
    required this.origin,
    required this.showOrigin,
    required this.exit,
    required this.exitActive,
    required this.hops,
    required this.otherNodes,
    required this.routeArcs,
    required this.routeMode,
    required this.showSpinArrow,
  }) : super(repaint: camera);

  final GlobeGeometry geometry;
  final GlobeCamera camera;
  final VpnMapPalette palette;

  /// Country drawn emphasised (the user's while searching).
  final CountryShape? highlight;
  final Color highlightColor;
  final Color highlightBorder;

  final LatLon? origin;
  final bool showOrigin;
  final LatLon? exit;

  /// Exit is the destination of a found route (green, blinking).
  final bool exitActive;

  /// Hops of the active onion path, in order.
  final List<GlobeDot> hops;

  /// Other masternodes the daemon currently has paths through.
  final List<GlobeDot> otherNodes;

  /// Great-circle samples of each route leg (hop 1 -> hop 2 -> ... and, once
  /// found, -> exit); only legs whose two ends have a location.
  final List<List<LatLon>> routeArcs;
  final GlobeRouteMode routeMode;

  /// Dashed arrow above the globe while it spins.
  final bool showSpinArrow;

  @override
  void paint(Canvas canvas, Size size) {
    // Slightly above centre, leaving room for the status block (design).
    final center = Offset(size.width / 2, size.height * 0.45);
    final radius = math.min(size.width * 0.39, size.height * 0.36) * camera.zoom;
    if (radius <= 1) return;
    final rot = _Rotation(camera.latitude, camera.longitude);
    final sphere = Rect.fromCircle(center: center, radius: radius);

    // Halo: soft light just outside the rim, fading out gradually.
    final haloR = radius * palette.globeHaloWidth;
    final rimStop = radius / haloR;
    final g = palette.globeGlow;
    // A wide light halo needs a fuller falloff to read as a soft glow.
    final wide = palette.globeHaloWidth > 1.15;
    canvas.drawCircle(
      center,
      haloR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            g,
            g,
            g.withOpacity(g.opacity * (wide ? 0.62 : 0.45)),
            g.withOpacity(g.opacity * (wide ? 0.22 : 0.12)),
            g.withOpacity(0),
          ],
          stops: [
            0.0,
            rimStop,
            rimStop + (1 - rimStop) * 0.35,
            rimStop + (1 - rimStop) * 0.7,
            1.0,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: haloR)),
    );
    // Sphere.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          radius: 1.05,
          colors: [palette.globeLight, palette.globeDark],
        ).createShader(sphere),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(sphere));

    // No latitude/longitude grid on the globe (design).

    // Countries: outline map, one path for all (cheap); highlight apart.
    final land = Path();
    final hl = geometry[highlight];
    for (final c in geometry.countries) {
      if (identical(c, hl)) continue;
      _addCountry(land, c, rot, center, radius);
    }
    if (palette.globeLand.opacity > 0) {
      canvas.drawPath(land, Paint()..color = palette.globeLand);
    }
    canvas.drawPath(
      land,
      Paint()
        ..color = palette.globeBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..strokeJoin = StrokeJoin.round,
    );
    if (hl != null) {
      final p = Path();
      _addCountry(p, hl, rot, center, radius);
      canvas.drawPath(p, Paint()..color = highlightColor);
      canvas.drawPath(
        p,
        Paint()
          ..color = highlightBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Inner rim light: the edge of the sphere glows softly inwards (design).
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.globeGlow.withOpacity(0),
            palette.globeGlow.withOpacity(0),
            palette.globeGlow.withOpacity(palette.globeGlow.opacity *
                (palette.globeHaloWidth > 1.15 ? 0.85 : 0.6)),
          ],
          stops: const [0.0, 0.84, 1.0],
        ).createShader(sphere),
    );
    // Limb shading for depth (when the palette asks for it).
    if (palette.globeShade.opacity > 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.transparent,
              Colors.transparent,
              palette.globeShade,
            ],
            stops: const [0.0, 0.75, 1.0],
          ).createShader(sphere),
      );
    }
    canvas.restore();
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = palette.globeRim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    if (showSpinArrow) _paintSpinArrow(canvas, center, radius);

    final pulse = camera.pulse;

    // Route.
    if (routeMode != GlobeRouteMode.none && routeArcs.isNotEmpty) {
      _paintRoute(canvas, rot, center, radius);
    }

    // Masternodes: white (dark) / grey (light) dots with a ring.
    for (final e in _fanOut(otherNodes, rot, center, radius)) {
      _hopDot(canvas, e.$1, e.$2, 2.2);
    }
    final hopPos = _fanOut(hops, rot, center, radius);
    for (var i = 0; i < hopPos.length; i++) {
      final at = hopPos[i].$1;
      final alpha = hopPos[i].$2;
      final reached = routeMode != GlobeRouteMode.tracing ||
          camera.trace >= i - 0.001;
      if (reached && at.isFinite && alpha > 0) {
        // Soft glow on hops the route has reached.
        canvas.drawCircle(
          at,
          8,
          Paint()
            ..shader = RadialGradient(colors: [
              palette.hopDot.withOpacity(0.28 * alpha),
              palette.hopDot.withOpacity(0),
            ]).createShader(Rect.fromCircle(center: at, radius: 8)),
        );
      }
      // Ripple when the route arrives at this hop.
      if (i == camera.arrivalHop && camera.arrivalT < 1 && at.isFinite) {
        final t = Curves.easeOut.transform(camera.arrivalT);
        canvas.drawCircle(
          at,
          3 + 11 * t,
          Paint()
            ..color = palette.exit.withOpacity((1 - t) * 0.7 * alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3,
        );
      }
      _hopDot(canvas, at, reached ? alpha : alpha * 0.55, reached ? 2.7 : 2.3);
    }

    // The user (finding route).
    final o = origin;
    if (showOrigin && o != null) {
      final p = rot.of(o.latitude, o.longitude);
      if (p.z > 0) {
        drawBlinkingMarker(canvas, center + Offset(p.x, p.y) * radius,
            palette.origin,
            pulse: pulse, size: 4, opacity: _fade(p.z));
      }
    }
    // The exit (route found).
    final x = exit;
    // The exit lights up once the route has reached it.
    final exitReached =
        routeArcs.isEmpty || camera.trace >= routeArcs.length - 0.01;
    if (exitActive && exitReached && x != null) {
      final p = rot.of(x.latitude, x.longitude);
      if (p.z > 0) {
        drawBlinkingMarker(canvas, center + Offset(p.x, p.y) * radius,
            palette.exit,
            pulse: pulse, size: 4, opacity: _fade(p.z));
      }
    }
  }

  static double _fade(double z) => (z * 5).clamp(0.0, 1.0);

  void _hopDot(Canvas canvas, Offset at, double alpha, double r) {
    if (!at.isFinite || alpha <= 0) return;
    canvas.drawCircle(
        at, r + 1.6, Paint()..color = palette.hopRing.withOpacity(alpha));
    canvas.drawCircle(
        at, r, Paint()..color = palette.hopDot.withOpacity(alpha));
  }

  /// Dashed arc with an arrow head over the top-left of the globe.
  void _paintSpinArrow(Canvas canvas, Offset center, double radius) {
    final r = radius * 1.09;
    final rect = Rect.fromCircle(center: center, radius: r);
    const start = -math.pi / 2 + 0.38; // right of top
    const sweep = -0.70; // towards the left
    final arc = Path()..addArc(rect, start, sweep);
    final paint = Paint()
      ..color = palette.spinArrow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_dash(arc, 3, 3.5), paint);
    // Arrow head at the end, pointing along the motion.
    const a = start + sweep;
    final tip = center + Offset(math.cos(a), math.sin(a)) * r;
    final dir = Offset(math.sin(a), -math.cos(a)); // tangent, counter-clockwise
    final normal = Offset(math.cos(a), math.sin(a));
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx - dir.dx * 6 + normal.dx * 3.5,
            tip.dy - dir.dy * 6 + normal.dy * 3.5)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - dir.dx * 6 - normal.dx * 3.5,
            tip.dy - dir.dy * 6 - normal.dy * 3.5),
      paint,
    );
  }

  /// Dashes [source] ([on] / [off] logical pixels).
  static Path _dash(Path source, double on, double off) {
    final out = Path();
    for (final m in source.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        out.addPath(m.extractPath(d, math.min(d + on, m.length)), Offset.zero);
        d += on + off;
      }
    }
    return out;
  }

  void _addCountry(
      Path path, _GeoCountry c, _Rotation rot, Offset center, double r) {
    for (final t in c.rings) {
      final n = t.length ~/ 4;
      var anyVisible = false;
      for (var i = 0; i < n; i++) {
        final cosDl = t[i * 4 + 2] * rot.cosLam0 + t[i * 4 + 3] * rot.sinLam0;
        final z = rot.sinPhi0 * t[i * 4 + 1] + rot.cosPhi0 * t[i * 4] * cosDl;
        if (z >= 0) {
          anyVisible = true;
          break;
        }
      }
      if (!anyVisible) continue;
      for (var i = 0; i < n; i++) {
        final p =
            rot.fromTrig(t[i * 4], t[i * 4 + 1], t[i * 4 + 2], t[i * 4 + 3]);
        var x = p.x, y = p.y;
        if (p.z < 0) {
          // Far side: push onto the horizon so outlines hug the rim.
          final len = math.sqrt(x * x + y * y);
          if (len > 1e-9) {
            x /= len;
            y /= len;
          }
        }
        final sx = center.dx + x * r, sy = center.dy + y * r;
        if (i == 0) {
          path.moveTo(sx, sy);
        } else {
          path.lineTo(sx, sy);
        }
      }
      path.close();
    }
  }

  /// Visible part of samples [from]..[to] (fractional) of one arc.
  Path _arcPath(List<LatLon> arc, double from, double to, _Rotation rot,
      Offset center, double r) {
    final path = Path();
    final n = arc.length - 1;
    if (n < 1 || to <= from) return path;
    Offset? at(double f) {
      final i = f.floor().clamp(0, n - 1);
      final k = f - i;
      final a = rot.of(arc[i].latitude, arc[i].longitude);
      final b = rot.of(arc[i + 1].latitude, arc[i + 1].longitude);
      if (a.z < 0 || b.z < 0) return null;
      return center + Offset(a.x + (b.x - a.x) * k, a.y + (b.y - a.y) * k) * r;
    }

    var pen = false;
    final steps = <double>[from];
    for (var i = from.floor() + 1; i < to; i++) {
      steps.add(i.toDouble());
    }
    steps.add(to);
    for (final f in steps) {
      final pt = at(f.clamp(0.0, n.toDouble()));
      if (pt == null) {
        pen = false;
        continue;
      }
      if (pen) {
        path.lineTo(pt.dx, pt.dy);
      } else {
        path.moveTo(pt.dx, pt.dy);
        pen = true;
      }
    }
    return path;
  }

  void _paintRoute(Canvas canvas, _Rotation rot, Offset center, double r) {
    final solid = Path();
    final dashed = Path();
    final reached =
        routeMode == GlobeRouteMode.tracing ? camera.trace : 0.0;
    Offset? head;
    for (var s = 0; s < routeArcs.length; s++) {
      final arc = routeArcs[s];
      final n = (arc.length - 1).toDouble();
      if (n < 1) continue;
      final frac = (reached - s).clamp(0.0, 1.0);
      if (frac > 0) {
        solid.addPath(_arcPath(arc, 0, n * frac, rot, center, r), Offset.zero);
        if (frac < 1) {
          final i = (n * frac).floor().clamp(0, arc.length - 2);
          final k = n * frac - i;
          final a = rot.of(arc[i].latitude, arc[i].longitude);
          final b = rot.of(arc[i + 1].latitude, arc[i + 1].longitude);
          if (a.z >= 0 && b.z >= 0) {
            head = center +
                Offset(a.x + (b.x - a.x) * k, a.y + (b.y - a.y) * k) * r;
          }
        }
      }
      if (frac < 1) {
        dashed.addPath(
            _arcPath(arc, n * frac, n, rot, center, r), Offset.zero);
      }
    }
    canvas.drawPath(
      _dash(dashed, 3, 3),
      Paint()
        ..color = palette.routeDash
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      solid,
      Paint()
        ..color = palette.exit.withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(
      solid,
      Paint()
        ..color = palette.exit
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (head != null) {
      canvas.drawCircle(head, 5, Paint()..color = palette.exit.withOpacity(0.35));
      canvas.drawCircle(head, 2.2, Paint()..color = palette.exit);
    }
  }

  /// Screen positions of [dots] on the visible side, fanning out dots that
  /// share a group (country) around their common point.
  List<(Offset, double)> _fanOut(
      List<GlobeDot> dots, _Rotation rot, Offset center, double r) {
    final out = <(Offset, double)>[];
    final groupCount = <String, int>{};
    final groupSeen = <String, int>{};
    for (final d in dots) {
      if (d.group.isNotEmpty) {
        groupCount[d.group] = (groupCount[d.group] ?? 0) + 1;
      }
    }
    for (final d in dots) {
      final p = rot.of(d.position.latitude, d.position.longitude);
      if (p.z <= 0) {
        out.add((Offset.infinite, 0.0));
        continue;
      }
      var at = center + Offset(p.x, p.y) * r;
      final n = d.group.isEmpty ? 1 : groupCount[d.group]!;
      if (n > 1) {
        final k = groupSeen[d.group] = (groupSeen[d.group] ?? -1) + 1;
        final a = -math.pi / 2 + k * 2 * math.pi / n;
        at += Offset(math.cos(a), math.sin(a)) * 6.0;
      }
      out.add((at, _fade(p.z)));
    }
    return out;
  }

  @override
  bool shouldRepaint(GlobePainter old) =>
      old.geometry != geometry ||
      old.palette != palette ||
      old.highlight != highlight ||
      old.highlightColor != highlightColor ||
      old.highlightBorder != highlightBorder ||
      old.origin != origin ||
      old.showOrigin != showOrigin ||
      old.exit != exit ||
      old.exitActive != exitActive ||
      !identical(old.hops, hops) ||
      !identical(old.otherNodes, otherNodes) ||
      !identical(old.routeArcs, routeArcs) ||
      old.routeMode != routeMode ||
      old.showSpinArrow != showSpinArrow;
}
