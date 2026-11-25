import 'dart:math' as math;
import 'dart:ui';

/// Orthographic ("seen from space") projection of the Earth onto a disc.
///
/// [centerLatitude] / [centerLongitude] is the point facing the viewer.
/// Projected coordinates are relative to the disc centre, in units of the
/// globe radius: x to the right, y downwards, both in -1..1 for visible
/// points.
class GlobeProjection {
  GlobeProjection(this.centerLatitude, this.centerLongitude)
      : _sinPhi0 = math.sin(centerLatitude * _deg),
        _cosPhi0 = math.cos(centerLatitude * _deg),
        _lambda0 = centerLongitude * _deg;

  static const double _deg = math.pi / 180.0;

  final double centerLatitude;
  final double centerLongitude;
  final double _sinPhi0;
  final double _cosPhi0;
  final double _lambda0;

  /// Projects a point. Returns (x, y, z) where z > 0 means the point is on
  /// the visible hemisphere (z is the cosine of the angular distance to the
  /// centre).
  ({double x, double y, double z}) project(double latitude, double longitude) {
    final phi = latitude * _deg;
    final dl = longitude * _deg - _lambda0;
    final cosPhi = math.cos(phi);
    final sinPhi = math.sin(phi);
    final cosDl = math.cos(dl);
    final x = cosPhi * math.sin(dl);
    final y = _cosPhi0 * sinPhi - _sinPhi0 * cosPhi * cosDl;
    final z = _sinPhi0 * sinPhi + _cosPhi0 * cosPhi * cosDl;
    return (x: x, y: -y, z: z);
  }

  /// Projects to a disc of [radius] centred at [center]. Hidden points are
  /// pushed onto the rim (see [projectClamped]).
  Offset toScreen(double latitude, double longitude, Offset center, double radius) {
    final p = projectClamped(latitude, longitude);
    return Offset(center.dx + p.dx * radius, center.dy + p.dy * radius);
  }

  /// Like [project] but points on the far side are moved to the horizon
  /// along their direction from the centre. Filled outlines that cross the
  /// horizon then hug the rim instead of folding back over the visible side.
  Offset projectClamped(double latitude, double longitude) {
    final p = project(latitude, longitude);
    if (p.z >= 0) return Offset(p.x, p.y);
    final len = math.sqrt(p.x * p.x + p.y * p.y);
    if (len < 1e-9) return const Offset(1, 0);
    return Offset(p.x / len, p.y / len);
  }

  /// True when the point is on the visible hemisphere.
  bool isVisible(double latitude, double longitude) =>
      project(latitude, longitude).z >= 0;
}

/// Shortest signed difference [to] - [from] in degrees, in -180..180.
double angleDelta(double from, double to) {
  var d = (to - from) % 360.0;
  if (d > 180) d -= 360;
  if (d < -180) d += 360;
  return d;
}

/// Normalises a longitude to -180..180.
double wrapLongitude(double lon) {
  var l = (lon + 180.0) % 360.0;
  if (l < 0) l += 360.0;
  return l - 180.0;
}

/// Points along the great circle between two locations (inclusive), for
/// drawing route arcs. [segments] >= 1.
List<({double latitude, double longitude})> greatCircle(
  double lat1,
  double lon1,
  double lat2,
  double lon2, {
  int segments = 24,
}) {
  const deg = math.pi / 180.0;
  final p1 = lat1 * deg, l1 = lon1 * deg;
  final p2 = lat2 * deg, l2 = lon2 * deg;
  final x1 = math.cos(p1) * math.cos(l1), y1 = math.cos(p1) * math.sin(l1), z1 = math.sin(p1);
  final x2 = math.cos(p2) * math.cos(l2), y2 = math.cos(p2) * math.sin(l2), z2 = math.sin(p2);
  final dot = (x1 * x2 + y1 * y2 + z1 * z2).clamp(-1.0, 1.0);
  final omega = math.acos(dot);
  final out = <({double latitude, double longitude})>[];
  final n = math.max(1, segments);
  for (var i = 0; i <= n; i++) {
    final t = i / n;
    double x, y, z;
    if (omega < 1e-6) {
      x = x1 + (x2 - x1) * t;
      y = y1 + (y2 - y1) * t;
      z = z1 + (z2 - z1) * t;
    } else {
      final s = math.sin(omega);
      final a = math.sin((1 - t) * omega) / s;
      final b = math.sin(t * omega) / s;
      x = a * x1 + b * x2;
      y = a * y1 + b * y2;
      z = a * z1 + b * z2;
    }
    out.add((
      latitude: math.atan2(z, math.sqrt(x * x + y * y)) / deg,
      longitude: math.atan2(y, x) / deg,
    ));
  }
  return out;
}

/// Spherical mean of locations (the point "in the middle" of them), used to
/// turn the globe towards a route. Null for an empty list.
({double latitude, double longitude})? sphericalMean(
    Iterable<({double latitude, double longitude})> points) {
  const deg = math.pi / 180.0;
  var x = 0.0, y = 0.0, z = 0.0;
  var n = 0;
  for (final p in points) {
    final phi = p.latitude * deg, lam = p.longitude * deg;
    x += math.cos(phi) * math.cos(lam);
    y += math.cos(phi) * math.sin(lam);
    z += math.sin(phi);
    n++;
  }
  if (n == 0) return null;
  final len = math.sqrt(x * x + y * y + z * z);
  if (len < 1e-9) return null; // antipodal points: no meaningful middle
  return (
    latitude: math.asin((z / len).clamp(-1.0, 1.0)) / deg,
    longitude: math.atan2(y, x) / deg,
  );
}
