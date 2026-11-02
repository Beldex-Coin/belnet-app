import 'dart:math' as math;

import 'package:belnet_mobile/src/map/map_projection.dart';
import 'package:belnet_mobile/src/map/vpn_map_provider.dart';
import 'package:belnet_mobile/src/map/world_map_data.dart';
import 'package:flutter/material.dart';

/// Colours for one theme of the map.
@immutable
class VpnMapPalette {
  const VpnMapPalette({
    required this.ocean,
    required this.land,
    required this.border,
    required this.graticule,
    required this.label,
    required this.labelHalo,
    required this.origin,
    required this.exit,
    required this.failed,
    required this.markerRing,
    required this.pillBackground,
    required this.pillText,
    required this.inactiveExit,
  });

  final Color ocean;
  final Color land;
  final Color border;
  final Color graticule;
  final Color label;
  final Color labelHalo;
  final Color origin;
  final Color exit;
  final Color failed;
  final Color markerRing;
  final Color pillBackground;
  final Color pillText;
  final Color inactiveExit;

  static const dark = VpnMapPalette(
    ocean: Color(0xFF0D0F12),
    land: Color(0xFF23272E),
    border: Color(0xFF3A3F49),
    graticule: Color(0x14FFFFFF),
    label: Color(0x99D5D9E0),
    labelHalo: Color(0xCC0D0F12),
    origin: Color(0xFF7FA8FF),
    exit: Color(0xFF00DC00),
    failed: Color(0xFFFF5252),
    markerRing: Color(0xFFFFFFFF),
    pillBackground: Color(0xE61A1D22),
    pillText: Color(0xFFEBEBEB),
    inactiveExit: Color(0xFF8D8D8D),
  );

  static const light = VpnMapPalette(
    ocean: Color(0xFFEFF2F5),
    land: Color(0xFFD5DAE1),
    border: Color(0xFFFFFFFF),
    graticule: Color(0x14000000),
    label: Color(0xA64D4D4D),
    labelHalo: Color(0xCCEFF2F5),
    origin: Color(0xFF3D6BE0),
    exit: Color(0xFF00B400),
    failed: Color(0xFFE53935),
    markerRing: Color(0xFFFFFFFF),
    pillBackground: Color(0xF2FFFFFF),
    pillText: Color(0xFF222222),
    inactiveExit: Color(0xFF8D8D8D),
  );

  static VpnMapPalette of(bool dark) => dark ? VpnMapPalette.dark : light;
}

/// Static world geography. Painted inside InteractiveViewer, in map
/// coordinates, behind a RepaintBoundary so pan/zoom never repaints it.
class BaseMapPainter extends CustomPainter {
  BaseMapPainter({
    required this.data,
    required this.palette,
    required this.borderWidth,
  });

  final WorldMapData data;
  final VpnMapPalette palette;

  /// Border stroke width in map units (screen width / current zoom bucket),
  /// so borders stay hairline-thin at every zoom level.
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final graticule = Paint()
      ..color = palette.graticule
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    for (var lon = -150; lon <= 150; lon += 30) {
      final x = MapProjection.normX(lon.toDouble()) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), graticule);
    }
    for (final lat in const [-30.0, 0.0, 30.0, 60.0]) {
      final y = MapProjection.normY(lat) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), graticule);
    }

    final fill = Paint()
      ..color = palette.land
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = palette.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeJoin = StrokeJoin.round;
    for (final country in data.countries) {
      final path = country.pathForSize(size);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(BaseMapPainter old) =>
      old.data != data ||
      old.palette != palette ||
      old.borderWidth != borderWidth;
}

/// Country labels in screen space: constant text size at every zoom, more
/// labels appear as the user zooms in, no overlaps.
class CountryLabelPainter extends CustomPainter {
  CountryLabelPainter({
    required this.data,
    required this.mapSize,
    required this.transform,
    required this.palette,
    required this.labelCache,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final WorldMapData data;
  final Size mapSize;
  final MapViewTransform Function() transform;
  final VpnMapPalette palette;
  final Map<String, TextPainter> labelCache;

  TextPainter _label(String text) {
    return labelCache.putIfAbsent(text, () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9.5,
            letterSpacing: 0.3,
            color: palette.label,
            shadows: [Shadow(color: palette.labelHalo, blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = transform();
    final viewport = Offset.zero & size;
    final placed = <Rect>[];
    for (final country in data.countries) {
      // Screen-space extent of the country.
      final w = country.bounds.width * mapSize.width * t.scale;
      if (w < 34) continue; // too small on screen at this zoom
      final anchor = t.toScreen(Offset(
        country.labelAnchor.dx * mapSize.width,
        country.labelAnchor.dy * mapSize.height,
      ));
      if (!viewport.inflate(40).contains(anchor)) continue;
      final tp = _label(country.name);
      if (tp.width > w * 0.9) continue;
      final rect = Rect.fromCenter(
        center: anchor,
        width: tp.width + 6,
        height: tp.height + 2,
      );
      if (placed.any((r) => r.overlaps(rect))) continue;
      placed.add(rect);
      tp.paint(canvas, anchor - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(CountryLabelPainter old) =>
      old.data != data ||
      old.mapSize != mapSize ||
      old.palette != palette ||
      old.labelCache != labelCache;
}

/// Everything that moves: the highlighted countries, pulsing markers and
/// their labels. Screen space, so markers keep a constant size while the
/// map is zoomed.
///
/// Like Proton VPN there is no line between the user and the server: while
/// the tunnel is up the camera zooms to the exit country, which is
/// highlighted; while it is down the user's own country is highlighted.
class VpnOverlayPainter extends CustomPainter {
  VpnOverlayPainter({
    required this.mapSize,
    required this.transform,
    required this.palette,
    required this.phase,
    required this.loop,
    required this.highlight,
    required this.exitMove,
    required this.origin,
    required this.exitFrom,
    required this.exitTo,
    required this.originCountry,
    required this.exitCountry,
    required this.originLabel,
    required this.exitLabel,
    required this.selectedExit,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final Size mapSize;
  final MapViewTransform Function() transform;
  final VpnMapPalette palette;
  final VpnMapPhase phase;
  final Animation<double> loop;

  /// 0 = user's country emphasised (disconnected), 1 = exit country
  /// emphasised (connecting/connected). Animated between the two.
  final Animation<double> highlight;
  final Animation<double> exitMove;

  /// Normalised (0..1) map positions; null when unknown.
  final Offset? origin;
  final Offset? exitFrom;
  final Offset? exitTo;
  final CountryShape? originCountry;
  final CountryShape? exitCountry;
  final TextPainter? originLabel;
  final TextPainter? exitLabel;

  /// Whether the exit marker is the active (highlighted) server.
  final bool selectedExit;

  Offset _toScreen(MapViewTransform t, Offset normalized) => t.toScreen(
      Offset(normalized.dx * mapSize.width, normalized.dy * mapSize.height));

  /// Current (possibly animating) exit position, normalised.
  Offset? get exitNormalized {
    final to = exitTo;
    if (to == null) return null;
    final from = exitFrom;
    if (from == null || exitMove.value >= 1) return to;
    final k = Curves.easeInOutCubic.transform(exitMove.value);
    return Offset.lerp(from, to, k);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = transform();
    final pulse = loop.value;
    final h = Curves.easeInOut.transform(highlight.value.clamp(0.0, 1.0));
    final failed = phase == VpnMapPhase.failed;
    final active = phase == VpnMapPhase.connecting ||
        phase == VpnMapPhase.connected ||
        phase == VpnMapPhase.disconnecting;
    final exitColor = failed ? palette.failed : palette.exit;

    // --- highlighted countries (map space) ---
    canvas.save();
    canvas.translate(t.translation.dx, t.translation.dy);
    canvas.scale(t.scale);
    final sameCountry = originCountry != null && originCountry == exitCountry;
    if (originCountry != null && !(sameCountry && h > 0.5)) {
      final a = 0.16 * (1 - h);
      if (a > 0.004) {
        canvas.drawPath(
          originCountry!.pathForSize(mapSize),
          Paint()..color = palette.origin.withOpacity(a),
        );
        canvas.drawPath(
          originCountry!.pathForSize(mapSize),
          Paint()
            ..color = palette.origin.withOpacity(0.5 * (1 - h))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0 / t.scale,
        );
      }
    }
    if (exitCountry != null && (h > 0.004 || failed)) {
      final strength = failed ? 1.0 : h;
      final breathe = phase == VpnMapPhase.connected
          ? 0.07 * math.sin(pulse * 2 * math.pi).abs()
          : 0.0;
      canvas.drawPath(
        exitCountry!.pathForSize(mapSize),
        Paint()..color = exitColor.withOpacity((0.20 + breathe) * strength),
      );
      canvas.drawPath(
        exitCountry!.pathForSize(mapSize),
        Paint()
          ..color = exitColor.withOpacity(0.75 * strength)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 / t.scale
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();

    final originPt = origin == null ? null : _toScreen(t, origin!);
    final exitN = exitNormalized;
    final exitPt = exitN == null ? null : _toScreen(t, exitN);

    // --- markers ---
    if (originPt != null) {
      if (active) {
        // Tunnel up: the user's real location is hidden, show it quietly.
        canvas.drawCircle(
            originPt, 4, Paint()..color = palette.origin.withOpacity(0.45));
      } else {
        _drawMarker(
          canvas,
          originPt,
          palette.origin,
          pulse: failed ? null : pulse,
          size: 6,
        );
      }
    }
    if (exitPt != null) {
      if (active || failed) {
        _drawMarker(
          canvas,
          exitPt,
          exitColor,
          pulse: failed ? null : pulse,
          size: selectedExit ? 7.5 : 6.5,
          doublePulse: phase == VpnMapPhase.connecting,
          halo: phase == VpnMapPhase.connected,
        );
      } else {
        // Disconnected: show the selected server quietly.
        canvas.drawCircle(exitPt, 5.5,
            Paint()..color = palette.inactiveExit.withOpacity(0.35));
        canvas.drawCircle(
            exitPt,
            3.5,
            Paint()
              ..color = palette.inactiveExit
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      }
    }

    // --- marker labels ---
    Rect? originPill;
    if (originPt != null && originLabel != null && !active) {
      originPill = _drawPill(canvas, originLabel!, originPt,
          above: true, accent: palette.origin);
    }
    if (exitPt != null && exitLabel != null) {
      var above = true;
      final pillRect = _pillRect(exitLabel!, exitPt, above: true);
      if (originPill != null && originPill.overlaps(pillRect)) above = false;
      _drawPill(canvas, exitLabel!, exitPt,
          above: above,
          accent: active || failed ? exitColor : palette.inactiveExit);
    }
  }

  void _drawMarker(
    Canvas canvas,
    Offset at,
    Color color, {
    required double? pulse,
    required double size,
    bool doublePulse = false,
    bool halo = false,
  }) {
    if (pulse != null) {
      final waves = doublePulse ? [pulse, (pulse + 0.5) % 1.0] : [pulse];
      for (final w in waves) {
        final r = size + 4 + w * 22;
        canvas.drawCircle(
          at,
          r,
          Paint()
            ..color = color.withOpacity((1 - w) * 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
    }
    if (halo) {
      canvas.drawCircle(at, size + 7, Paint()..color = color.withOpacity(0.18));
    }
    canvas.drawCircle(at, size + 2.2, Paint()..color = palette.markerRing);
    canvas.drawCircle(at, size, Paint()..color = color);
    canvas.drawCircle(
        at, size * 0.38, Paint()..color = Colors.white.withOpacity(0.9));
  }

  Rect _pillRect(TextPainter tp, Offset at, {required bool above}) {
    final w = tp.width + 16;
    final h = tp.height + 8;
    final cy = above ? at.dy - 22 - h / 2 : at.dy + 22 + h / 2;
    return Rect.fromCenter(center: Offset(at.dx, cy), width: w, height: h);
  }

  Rect _drawPill(Canvas canvas, TextPainter tp, Offset at,
      {required bool above, required Color accent}) {
    final rect = _pillRect(tp, at, above: above);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(
      rrect.shift(const Offset(0, 1.5)),
      Paint()..color = Colors.black.withOpacity(0.18),
    );
    canvas.drawRRect(rrect, Paint()..color = palette.pillBackground);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = accent.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    tp.paint(canvas, Offset(rect.left + 8, rect.top + 4));
    return rect;
  }

  @override
  bool shouldRepaint(VpnOverlayPainter old) =>
      old.mapSize != mapSize ||
      old.palette != palette ||
      old.phase != phase ||
      old.origin != origin ||
      old.exitFrom != exitFrom ||
      old.exitTo != exitTo ||
      old.originCountry != originCountry ||
      old.exitCountry != exitCountry ||
      old.originLabel != originLabel ||
      old.exitLabel != exitLabel ||
      old.selectedExit != selectedExit;
}
