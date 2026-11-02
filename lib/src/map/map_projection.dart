import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show EdgeInsets;

/// Miller cylindrical projection, normalised to the unit square.
///
/// The map asset (Natural Earth 110m) spans latitudes -55.6..83.6 and has no
/// Antarctica, so the visible band is cropped to [minLatitude, maxLatitude].
/// x = 0 is longitude -180, x = 1 is +180; y = 0 is [maxLatitude] (north),
/// y = 1 is [minLatitude] (south). Points outside the band are clamped.
class MapProjection {
  const MapProjection._();

  static const double minLatitude = -58.0;
  static const double maxLatitude = 84.0;

  static double _millerY(double latDeg) {
    final phi = latDeg * math.pi / 180.0;
    return 1.25 * math.log(math.tan(math.pi / 4 + 0.4 * phi));
  }

  static final double _yTop = _millerY(maxLatitude);
  static final double _yBottom = _millerY(minLatitude);

  /// Width / height of the projected band (about 1.99).
  static double get aspectRatio => (2 * math.pi) / (_yTop - _yBottom);

  /// Normalised x in [0, 1].
  static double normX(double longitude) {
    final lon = longitude.clamp(-180.0, 180.0);
    return (lon + 180.0) / 360.0;
  }

  /// Normalised y in [0, 1] (0 = north edge).
  static double normY(double latitude) {
    final lat = latitude.clamp(minLatitude, maxLatitude);
    return (_yTop - _millerY(lat)) / (_yTop - _yBottom);
  }

  /// Projects to normalised map space.
  static Offset project(double latitude, double longitude) =>
      Offset(normX(longitude), normY(latitude));

  /// Projects to a map of [size] logical pixels.
  static Offset toMap(double latitude, double longitude, Size size) {
    final n = project(latitude, longitude);
    return Offset(n.dx * size.width, n.dy * size.height);
  }

  /// Inverse projection from normalised map space.
  static ({double latitude, double longitude}) unproject(Offset normalized) {
    final lon = normalized.dx * 360.0 - 180.0;
    final y = _yTop - normalized.dy * (_yTop - _yBottom);
    final phi = (math.atan(math.exp(y / 1.25)) - math.pi / 4) / 0.4;
    return (latitude: phi * 180.0 / math.pi, longitude: lon);
  }
}

/// A 2D transform made of a uniform scale and a translation - exactly what
/// InteractiveViewer produces (it never rotates). Converts between the
/// map's own coordinate space and on-screen viewport coordinates.
class MapViewTransform {
  const MapViewTransform(this.scale, this.translation);

  /// Reads scale/translation from a column-major 4x4 matrix storage.
  factory MapViewTransform.fromStorage(List<double> m) =>
      MapViewTransform(m[0], Offset(m[12], m[13]));

  static const identity = MapViewTransform(1.0, Offset.zero);

  final double scale;
  final Offset translation;

  Offset toScreen(Offset mapPoint) => mapPoint * scale + translation;
  Offset toMap(Offset screenPoint) => (screenPoint - translation) / scale;

  /// Column-major matrix storage suitable for `Matrix4.fromList`.
  List<double> toStorage() => <double>[
        scale, 0, 0, 0, //
        0, scale, 0, 0, //
        0, 0, 1, 0, //
        translation.dx, translation.dy, 0, 1,
      ];

  /// Transform that frames [points] (map coordinates) inside [viewport],
  /// keeping the whole map ([mapSize]) covering the viewport.
  ///
  /// A single point is centred at [singlePointScale]. Several points are
  /// fitted with [padding] logical pixels on every side and the scale is
  /// clamped to [minScale]..[maxScale].
  static MapViewTransform focus({
    required List<Offset> points,
    required Size viewport,
    required Size mapSize,
    double minScale = 1.0,
    double maxScale = 5.0,
    double singlePointScale = 2.4,
    EdgeInsets padding = const EdgeInsets.fromLTRB(56, 64, 56, 96),
  }) {
    if (points.isEmpty || viewport.isEmpty || mapSize.isEmpty) {
      return clamp(
        MapViewTransform(minScale, Offset.zero),
        viewport: viewport,
        mapSize: mapSize,
      );
    }
    double scale;
    Offset centre;
    if (points.length == 1) {
      scale = singlePointScale;
      centre = points.first;
    } else {
      var left = points.first.dx, right = points.first.dx;
      var top = points.first.dy, bottom = points.first.dy;
      for (final p in points.skip(1)) {
        left = math.min(left, p.dx);
        right = math.max(right, p.dx);
        top = math.min(top, p.dy);
        bottom = math.max(bottom, p.dy);
      }
      final availW = math.max(1.0, viewport.width - padding.horizontal);
      final availH = math.max(1.0, viewport.height - padding.vertical);
      final w = math.max(right - left, 1.0);
      final h = math.max(bottom - top, 1.0);
      scale = math.min(availW / w, availH / h);
      // Centre of the padded area, mapped back to the bounding-box centre.
      final paddedCentre = Offset(
        padding.left + availW / 2,
        padding.top + availH / 2,
      );
      final boxCentre = Offset((left + right) / 2, (top + bottom) / 2);
      scale = scale.clamp(minScale, maxScale);
      final t = paddedCentre - boxCentre * scale;
      return clamp(MapViewTransform(scale, t),
          viewport: viewport, mapSize: mapSize);
    }
    scale = scale.clamp(minScale, maxScale);
    final t = Offset(viewport.width / 2, viewport.height / 2) - centre * scale;
    return clamp(MapViewTransform(scale, t),
        viewport: viewport, mapSize: mapSize);
  }

  /// Keeps the scaled map covering the viewport (no empty borders), which
  /// matches InteractiveViewer's own clamping with a zero boundary margin.
  static MapViewTransform clamp(
    MapViewTransform t, {
    required Size viewport,
    required Size mapSize,
  }) {
    final scaledW = mapSize.width * t.scale;
    final scaledH = mapSize.height * t.scale;
    double tx = t.translation.dx;
    double ty = t.translation.dy;
    tx = scaledW <= viewport.width
        ? (viewport.width - scaledW) / 2
        : tx.clamp(viewport.width - scaledW, 0.0);
    ty = scaledH <= viewport.height
        ? (viewport.height - scaledH) / 2
        : ty.clamp(viewport.height - scaledH, 0.0);
    return MapViewTransform(t.scale, Offset(tx, ty));
  }
}
