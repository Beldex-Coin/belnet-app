import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:belnet_mobile/src/map/map_projection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// One country of the world map, pre-projected to normalised map space.
class CountryShape {
  CountryShape({
    required this.name,
    required this.admin,
    required this.continent,
    required this.path,
    required this.bounds,
    required this.mainBounds,
    required this.labelAnchor,
    required this.area,
  });

  /// Short display name ("United States", "Czech Rep.").
  final String name;

  /// Long administrative name ("United States of America").
  final String admin;
  final String continent;

  /// Outline in normalised map space (0..1 on both axes).
  final Path path;
  final Rect bounds;

  /// Bounds of the largest polygon only (e.g. mainland France without
  /// French Guiana, the contiguous US without Alaska). Used to zoom to a
  /// country the way it is usually pictured.
  final Rect mainBounds;

  /// Where to put the country label (normalised map space).
  final Offset labelAnchor;

  /// Projected area of the largest polygon, used for label priority.
  final double area;

  /// Cache of [path] scaled to a concrete map size.
  Path? _scaledPath;
  Size? _scaledFor;

  Path pathForSize(Size size) {
    if (_scaledPath == null || _scaledFor != size) {
      _scaledPath = path.transform(Float64List.fromList(<double>[
        size.width, 0, 0, 0, //
        0, size.height, 0, 0, //
        0, 0, 1, 0, //
        0, 0, 0, 1,
      ]));
      _scaledFor = size;
    }
    return _scaledPath!;
  }
}

/// The parsed world map plus country-name matching helpers.
class WorldMapData {
  WorldMapData._(this.countries) {
    for (final c in countries) {
      _byKey.putIfAbsent(normalizeCountryKey(c.name), () => c);
      _byKey.putIfAbsent(normalizeCountryKey(c.admin), () => c);
    }
  }

  static const String assetPath = 'assets/map/world_map.json';

  final List<CountryShape> countries;
  final Map<String, CountryShape> _byKey = {};

  static Future<WorldMapData>? _loading;

  /// Loads and parses the asset once per process; later calls share the
  /// same future. JSON parsing and projection run on a background isolate.
  static Future<WorldMapData> load() {
    return _loading ??= _load().catchError((Object e) {
      _loading = null; // allow a retry on the next call
      throw e;
    });
  }

  static Future<WorldMapData> _load() async {
    final raw = await rootBundle.loadString(assetPath);
    final parsed = await compute(parseWorldMapGeoJson, raw);
    return fromParsed(parsed);
  }

  /// Builds [Path]s on the UI isolate from the isolate-parsed data.
  static WorldMapData fromParsed(List<ParsedCountry> parsed) {
    final shapes = <CountryShape>[];
    for (final p in parsed) {
      final path = Path()..fillType = PathFillType.evenOdd;
      for (final ring in p.rings) {
        if (ring.length < 6) continue;
        path.moveTo(ring[0], ring[1]);
        for (var i = 2; i < ring.length; i += 2) {
          path.lineTo(ring[i], ring[i + 1]);
        }
        path.close();
      }
      shapes.add(CountryShape(
        name: p.name,
        admin: p.admin,
        continent: p.continent,
        path: path,
        bounds: Rect.fromLTRB(p.minX, p.minY, p.maxX, p.maxY),
        mainBounds:
            Rect.fromLTRB(p.mainMinX, p.mainMinY, p.mainMaxX, p.mainMaxY),
        labelAnchor: Offset(p.labelX, p.labelY),
        area: p.area,
      ));
    }
    // Largest first: label placement gives big countries priority.
    shapes.sort((a, b) => b.area.compareTo(a.area));
    return WorldMapData._(shapes);
  }

  /// Finds the map country for a name coming from exit-node metadata or an
  /// IP-geolocation API ("USA", "UK", "Czechia", "United States", ...).
  CountryShape? findCountry(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final key = normalizeCountryKey(name);
    final direct = _byKey[key];
    if (direct != null) return direct;
    final alias = _countryAliases[key];
    return alias == null ? null : _byKey[alias];
  }

  /// Country containing a normalised map point, or - for coastal points the
  /// coarse 110m outlines put just offshore - the closest country whose
  /// outline is within [tolerance]. Null in open sea or for territories
  /// missing from the 110m data (Singapore, Hong Kong, Malta, ...).
  CountryShape? countryAt(Offset normalized, {double tolerance = 0.004}) {
    for (final c in countries) {
      if (c.bounds.contains(normalized) && c.path.contains(normalized)) {
        return c;
      }
    }
    CountryShape? best;
    var bestDistance = double.infinity;
    for (final c in countries) {
      if (!c.bounds.inflate(tolerance).contains(normalized)) continue;
      // Probe a small ring of points around the location.
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        final probe = normalized +
            Offset(tolerance * math.cos(a), tolerance * math.sin(a));
        if (c.path.contains(probe)) {
          final d = (c.labelAnchor - normalized).distance;
          if (d < bestDistance) {
            bestDistance = d;
            best = c;
          }
          break;
        }
      }
    }
    return best;
  }

  /// Best map country for a location.
  ///
  /// A known country name is trusted on its own: when it is not in the 110m
  /// data the territory is simply too small to be drawn (Singapore, Hong
  /// Kong, Malta, Bahrain), and falling back to the position would wrongly
  /// highlight a neighbour (the 110m outline of Malaysia covers Singapore,
  /// China's covers Hong Kong). The position is only used when no country
  /// name is available at all.
  CountryShape? resolveCountry({String? name, Offset? normalized}) {
    if (name != null && name.trim().isNotEmpty) return findCountry(name);
    return normalized == null ? null : countryAt(normalized);
  }
}


/// Lower-case, punctuation-insensitive key for country-name comparisons.
String normalizeCountryKey(String name) => _foldAccents(name.toLowerCase())
    .replaceAll('&', 'and')
    .replaceAll(RegExp(r"[^a-z0-9]+"), ' ')
    .trim();

const Map<String, String> _accentFolds = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', //
  'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ñ': 'n', //
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', //
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y', //
};

/// "Türkiye" -> "turkiye", "Côte d'Ivoire" -> "cote d'ivoire".
String _foldAccents(String s) {
  final b = StringBuffer();
  for (final ch in s.split('')) {
    b.write(_accentFolds[ch] ?? ch);
  }
  return b.toString();
}

/// Common spellings -> normalised key of a name present in the asset.
const Map<String, String> _countryAliases = {
  'usa': 'united states',
  'us': 'united states',
  'u s a': 'united states',
  'america': 'united states',
  'uk': 'united kingdom',
  'u k': 'united kingdom',
  'great britain': 'united kingdom',
  'britain': 'united kingdom',
  'england': 'united kingdom',
  'scotland': 'united kingdom',
  'wales': 'united kingdom',
  'south korea': 'korea',
  'republic of korea': 'korea',
  'korea republic of': 'korea',
  'north korea': 'dem rep korea',
  'czechia': 'czech rep',
  'the netherlands': 'netherlands',
  'holland': 'netherlands',
  'russian federation': 'russia',
  'bosnia': 'bosnia and herz',
  'north macedonia': 'macedonia',
  'eswatini': 'swaziland',
  'turkiye': 'turkey',
  'ivory coast': 'cote d ivoire',
  'laos': 'lao pdr',
  'viet nam': 'vietnam',
  'dr congo': 'dem rep congo',
  'drc': 'dem rep congo',
  'republic of the congo': 'congo',
  'uae': 'united arab emirates',
  'korea south': 'korea',
  'korea democratic people s republic of': 'dem rep korea',
  'czech republic': 'czech rep',
  'russia federation': 'russia',
  'iran islamic republic of': 'iran',
  'syrian arab republic': 'syria',
  'lao people s democratic republic': 'lao pdr',
  'moldova republic of': 'moldova',
  'tanzania united republic of': 'tanzania',
  'congo democratic republic of the': 'dem rep congo',
  'bolivia plurinational state of': 'bolivia',
  'venezuela bolivarian republic of': 'venezuela',
  'myanmar burma': 'myanmar',
  'burma': 'myanmar',
  'republic of lithuania': 'lithuania',
  'republic of serbia': 'serbia',
  'east timor': 'timor leste',
};

/// Isolate-friendly parse result (only primitives / typed data).
class ParsedCountry {
  ParsedCountry({
    required this.name,
    required this.admin,
    required this.continent,
    required this.rings,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.labelX,
    required this.labelY,
    required this.area,
    required this.mainMinX,
    required this.mainMinY,
    required this.mainMaxX,
    required this.mainMaxY,
  });

  final String name;
  final String admin;
  final String continent;

  /// Each ring is [x0, y0, x1, y1, ...] in normalised map space.
  final List<Float64List> rings;
  final double minX, minY, maxX, maxY;
  final double labelX, labelY;
  final double area;

  /// Bounds of the largest outer ring.
  final double mainMinX, mainMinY, mainMaxX, mainMaxY;
}

/// Parses a GeoJSON FeatureCollection of Polygon/MultiPolygon countries
/// (WGS84 lon/lat) into projected rings. Top-level so it can run in
/// `compute`.
List<ParsedCountry> parseWorldMapGeoJson(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map || decoded['features'] is! List) return const [];
  final result = <ParsedCountry>[];
  for (final feature in decoded['features'] as List) {
    if (feature is! Map) continue;
    final geometry = feature['geometry'];
    if (geometry is! Map) continue;
    final props = feature['properties'] is Map
        ? feature['properties'] as Map
        : const <String, dynamic>{};
    final type = geometry['type'];
    final coords = geometry['coordinates'];
    if (coords is! List) continue;

    // Normalise to a list of polygons, each a list of rings.
    final polygons = <List>[];
    if (type == 'Polygon') {
      polygons.add(coords);
    } else if (type == 'MultiPolygon') {
      for (final poly in coords) {
        if (poly is List) polygons.add(poly);
      }
    } else {
      continue;
    }

    final rings = <Float64List>[];
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    var bestArea = -1.0;
    var labelX = 0.5, labelY = 0.5;
    var mainMinX = 0.0, mainMinY = 0.0, mainMaxX = 0.0, mainMaxY = 0.0;

    for (final polygon in polygons) {
      var outerRingIndex = true;
      for (final ring in polygon) {
        if (ring is! List || ring.length < 3) {
          outerRingIndex = false;
          continue;
        }
        final pts = Float64List(ring.length * 2);
        var n = 0;
        var rMinX = double.infinity, rMinY = double.infinity;
        var rMaxX = -double.infinity, rMaxY = -double.infinity;
        for (final pt in ring) {
          if (pt is! List || pt.length < 2) continue;
          final lon = (pt[0] as num).toDouble();
          final lat = (pt[1] as num).toDouble();
          final x = MapProjection.normX(lon);
          final y = MapProjection.normY(lat);
          pts[n++] = x;
          pts[n++] = y;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
          if (x < rMinX) rMinX = x;
          if (x > rMaxX) rMaxX = x;
          if (y < rMinY) rMinY = y;
          if (y > rMaxY) rMaxY = y;
        }
        final trimmed = n == pts.length ? pts : Float64List.sublistView(pts, 0, n);
        rings.add(trimmed);

        if (outerRingIndex) {
          // Shoelace area + centroid of the outer ring.
          var a = 0.0, cx = 0.0, cy = 0.0;
          for (var i = 0; i + 3 < n; i += 2) {
            final x0 = trimmed[i], y0 = trimmed[i + 1];
            final x1 = trimmed[i + 2], y1 = trimmed[i + 3];
            final cross = x0 * y1 - x1 * y0;
            a += cross;
            cx += (x0 + x1) * cross;
            cy += (y0 + y1) * cross;
          }
          final area = a.abs() / 2;
          if (area > bestArea && a != 0) {
            bestArea = area;
            labelX = cx / (3 * a);
            labelY = cy / (3 * a);
            mainMinX = rMinX;
            mainMinY = rMinY;
            mainMaxX = rMaxX;
            mainMaxY = rMaxY;
          }
        }
        outerRingIndex = false;
      }
    }
    if (rings.isEmpty) continue;

    result.add(ParsedCountry(
      name: (props['name'] ?? props['admin'] ?? '').toString(),
      admin: (props['admin'] ?? props['name'] ?? '').toString(),
      continent: (props['continent'] ?? '').toString(),
      rings: rings,
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      labelX: labelX,
      labelY: labelY,
      area: bestArea < 0 ? 0 : bestArea,
      mainMinX: bestArea < 0 ? minX : mainMinX,
      mainMinY: bestArea < 0 ? minY : mainMinY,
      mainMaxX: bestArea < 0 ? maxX : mainMaxX,
      mainMaxY: bestArea < 0 ? maxY : mainMaxY,
    ));
  }
  return result;
}
