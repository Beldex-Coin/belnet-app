import 'dart:ui';

import 'package:belnet_mobile/src/map/globe_projection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the facing point projects to the centre', () {
    final g = GlobeProjection(28.6, 77.2); // New Delhi
    final p = g.project(28.6, 77.2);
    expect(p.x, closeTo(0, 1e-9));
    expect(p.y, closeTo(0, 1e-9));
    expect(p.z, closeTo(1, 1e-9));
  });

  test('east is right, north is up, the far side is hidden', () {
    final g = GlobeProjection(0, 0);
    final east = g.project(0, 30);
    expect(east.x, greaterThan(0));
    expect(east.y, closeTo(0, 1e-9));
    final north = g.project(30, 0);
    expect(north.y, lessThan(0)); // screen y grows downwards
    expect(g.isVisible(0, 89), isTrue);
    expect(g.isVisible(0, 91), isFalse);
    expect(g.isVisible(0, 180), isFalse);
  });

  test('hidden points are clamped onto the rim', () {
    final g = GlobeProjection(0, 0);
    final p = g.projectClamped(0, 120);
    expect(p.distance, closeTo(1, 1e-9));
    expect(p.dx, greaterThan(0));
    expect(g.toScreen(0, 0, const Offset(100, 100), 50), const Offset(100, 100));
  });

  test('angleDelta takes the short way round', () {
    expect(angleDelta(170, -170), closeTo(20, 1e-9));
    expect(angleDelta(-170, 170), closeTo(-20, 1e-9));
    expect(angleDelta(10, 40), closeTo(30, 1e-9));
    expect(wrapLongitude(190), closeTo(-170, 1e-9));
    expect(wrapLongitude(-190), closeTo(170, 1e-9));
  });

  test('great circle starts and ends at the endpoints', () {
    final pts = greatCircle(52.1, 5.3, 20.6, 79.0, segments: 10);
    expect(pts.length, 11);
    expect(pts.first.latitude, closeTo(52.1, 1e-6));
    expect(pts.first.longitude, closeTo(5.3, 1e-6));
    expect(pts.last.latitude, closeTo(20.6, 1e-6));
    expect(pts.last.longitude, closeTo(79.0, 1e-6));
    // Same point: no NaN.
    final same = greatCircle(10, 10, 10, 10, segments: 4);
    expect(same.every((p) => p.latitude.isFinite && p.longitude.isFinite),
        isTrue);
  });

  test('spherical mean', () {
    final m = sphericalMean([
      (latitude: 0.0, longitude: -10.0),
      (latitude: 0.0, longitude: 10.0),
    ])!;
    expect(m.latitude, closeTo(0, 1e-9));
    expect(m.longitude, closeTo(0, 1e-9));
    // Across the date line.
    final d = sphericalMean([
      (latitude: 0.0, longitude: 170.0),
      (latitude: 0.0, longitude: -170.0),
    ])!;
    expect(d.longitude.abs(), closeTo(180, 1e-6));
    expect(sphericalMean(const []), isNull);
  });
}
