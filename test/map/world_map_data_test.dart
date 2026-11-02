import 'dart:io';

import 'package:belnet_mobile/src/map/map_projection.dart';
import 'package:belnet_mobile/src/map/world_map_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<ParsedCountry> parsed;
  late WorldMapData data;

  setUpAll(() {
    final raw = File('assets/map/world_map.json').readAsStringSync();
    parsed = parseWorldMapGeoJson(raw);
    data = WorldMapData.fromParsed(parsed);
  });

  test('parses every country of the bundled map', () {
    expect(parsed.length, 176);
    for (final c in parsed) {
      expect(c.rings, isNotEmpty, reason: c.name);
      expect(c.minX, greaterThanOrEqualTo(0));
      expect(c.maxX, lessThanOrEqualTo(1));
      expect(c.minY, greaterThanOrEqualTo(0));
      expect(c.maxY, lessThanOrEqualTo(1));
    }
  });

  test('label anchors fall inside the country bounds', () {
    for (final c in parsed) {
      expect(c.labelX, inInclusiveRange(c.minX - 1e-6, c.maxX + 1e-6),
          reason: c.name);
      expect(c.labelY, inInclusiveRange(c.minY - 1e-6, c.maxY + 1e-6),
          reason: c.name);
    }
  });

  test('countries are sorted largest first', () {
    for (var i = 1; i < data.countries.length; i++) {
      expect(data.countries[i - 1].area,
          greaterThanOrEqualTo(data.countries[i].area));
    }
  });

  test('matches exit-node and geolocation country spellings', () {
    expect(data.findCountry('France')!.name, 'France');
    expect(data.findCountry('USA')!.name, 'United States');
    expect(data.findCountry('United States of America')!.name,
        'United States');
    expect(data.findCountry('UK')!.name, 'United Kingdom');
    expect(data.findCountry('Czechia')!.name, 'Czech Rep.');
    expect(data.findCountry('South Korea')!.name, 'Korea');
    expect(data.findCountry('  india ')!.name, 'India');
    expect(data.findCountry('Atlantis'), isNull);
    expect(data.findCountry(null), isNull);
  });

  test('default exit node (Strasbourg) projects inside France', () {
    final france = parsed.firstWhere((c) => c.name == 'France');
    final p = MapProjection.project(48.5848, 7.7419);
    expect(p.dx, inInclusiveRange(france.minX, france.maxX));
    expect(p.dy, inInclusiveRange(france.minY, france.maxY));
  });

  test('accented and API-style spellings resolve', () {
    expect(data.findCountry('Türkiye')!.name, 'Turkey');
    expect(data.findCountry("Côte d'Ivoire")!.name, "Côte d'Ivoire");
    expect(data.findCountry('Ivory Coast')!.name, "Côte d'Ivoire");
    expect(data.findCountry('Korea, Republic of')!.name, 'Korea');
    expect(data.findCountry('Iran, Islamic Republic of')!.name, 'Iran');
  });

  test('main bounds frame the largest polygon only', () {
    final france = data.findCountry('France')!;
    // Mainland France starts east of 5°W; French Guiana (53°W) is excluded.
    expect(france.mainBounds.left, greaterThan(MapProjection.normX(-6)));
    expect(france.bounds.left, lessThan(MapProjection.normX(-50)));
    for (final c in data.countries) {
      expect(c.bounds.inflate(1e-9).contains(c.mainBounds.topLeft), isTrue,
          reason: c.name);
      expect(c.bounds.inflate(1e-9).contains(c.mainBounds.bottomRight),
          isTrue,
          reason: c.name);
    }
  });

  test('finds the country containing a location', () {
    expect(data.countryAt(MapProjection.project(48.85, 2.35))!.name,
        'France');
    expect(data.countryAt(MapProjection.project(35.68, 139.69))!.name,
        'Japan');
    expect(data.countryAt(MapProjection.project(30, -40)), isNull);
  });

  test('a known name is never replaced by a neighbouring country', () {
    // Singapore is not in the 110m data and sits inside Malaysia's outline.
    final sg = MapProjection.project(1.3521, 103.8198);
    expect(data.countryAt(sg)!.name, 'Malaysia');
    expect(data.resolveCountry(name: 'Singapore', normalized: sg), isNull);
    // Without a name, the position decides.
    expect(
        data
            .resolveCountry(normalized: MapProjection.project(19.07, 72.88))!
            .name,
        'India');
  });

  test('malformed input yields no countries instead of throwing', () {
    expect(parseWorldMapGeoJson('{}'), isEmpty);
    expect(parseWorldMapGeoJson('{"features": [{"geometry": null}]}'),
        isEmpty);
  });
}
