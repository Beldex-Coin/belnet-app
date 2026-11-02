import 'dart:ui';

import 'package:belnet_mobile/src/map/map_projection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapProjection', () {
    test('maps the corners of the visible band to the unit square', () {
      expect(MapProjection.normX(-180), closeTo(0, 1e-9));
      expect(MapProjection.normX(180), closeTo(1, 1e-9));
      expect(MapProjection.normY(MapProjection.maxLatitude), closeTo(0, 1e-9));
      expect(MapProjection.normY(MapProjection.minLatitude), closeTo(1, 1e-9));
    });

    test('clamps out-of-range coordinates instead of overflowing', () {
      expect(MapProjection.normY(89.9), closeTo(0, 1e-9));
      expect(MapProjection.normY(-89.9), closeTo(1, 1e-9));
      expect(MapProjection.normX(200), closeTo(1, 1e-9));
    });

    test('north is up and east is right', () {
      final paris = MapProjection.project(48.85, 2.35);
      final capeTown = MapProjection.project(-33.92, 18.42);
      final tokyo = MapProjection.project(35.68, 139.69);
      expect(paris.dy, lessThan(capeTown.dy));
      expect(tokyo.dx, greaterThan(paris.dx));
    });

    test('unproject is the inverse of project', () {
      for (final c in const [
        [48.5848, 7.7419],
        [12.97, 77.59],
        [-33.86, 151.21],
        [40.71, -74.0],
      ]) {
        final back = MapProjection.unproject(MapProjection.project(c[0], c[1]));
        expect(back.latitude, closeTo(c[0], 1e-6));
        expect(back.longitude, closeTo(c[1], 1e-6));
      }
    });

    test('toMap scales normalised coordinates to the map size', () {
      const size = Size(800, 400);
      final p = MapProjection.toMap(0, 0, size);
      expect(p.dx, closeTo(400, 1e-6));
      expect(p.dy, closeTo(MapProjection.normY(0) * 400, 1e-6));
    });

    test('aspect ratio of the cropped Miller band is about 2:1', () {
      expect(MapProjection.aspectRatio, inInclusiveRange(1.9, 2.1));
    });
  });

  group('MapViewTransform', () {
    const viewport = Size(360, 300);
    const mapSize = Size(600, 300);

    test('round-trips between map and screen coordinates', () {
      const t = MapViewTransform(2.5, Offset(-120, -40));
      const p = Offset(123, 45);
      final back = t.toMap(t.toScreen(p));
      expect(back.dx, closeTo(p.dx, 1e-9));
      expect(back.dy, closeTo(p.dy, 1e-9));
      final fromStorage = MapViewTransform.fromStorage(t.toStorage());
      expect(fromStorage.scale, t.scale);
      expect(fromStorage.translation, t.translation);
    });

    test('clamp keeps the map covering the viewport', () {
      final t = MapViewTransform.clamp(
        const MapViewTransform(1, Offset(50, 30)),
        viewport: viewport,
        mapSize: mapSize,
      );
      expect(t.translation.dx, 0);
      expect(t.translation.dy, 0);
      final t2 = MapViewTransform.clamp(
        const MapViewTransform(1, Offset(-1000, -1000)),
        viewport: viewport,
        mapSize: mapSize,
      );
      expect(t2.translation.dx, viewport.width - mapSize.width);
      expect(t2.translation.dy, 0);
    });

    test('focus on one point centres it when the map allows', () {
      const point = Offset(300, 150);
      final t = MapViewTransform.focus(
        points: const [point],
        viewport: viewport,
        mapSize: mapSize,
        singlePointScale: 2,
      );
      expect(t.scale, 2);
      final s = t.toScreen(point);
      expect(s.dx, closeTo(viewport.width / 2, 1e-6));
      expect(s.dy, closeTo(viewport.height / 2, 1e-6));
    });

    test('focus on two points keeps both inside the viewport', () {
      const a = Offset(120, 90);
      const b = Offset(430, 200);
      final t = MapViewTransform.focus(
        points: const [a, b],
        viewport: viewport,
        mapSize: mapSize,
      );
      for (final p in [a, b]) {
        final s = t.toScreen(p);
        expect(s.dx, inInclusiveRange(0, viewport.width));
        expect(s.dy, inInclusiveRange(0, viewport.height));
      }
      expect(t.scale, greaterThanOrEqualTo(1));
    });
  });
}
