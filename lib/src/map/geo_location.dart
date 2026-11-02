import 'package:flutter/foundation.dart';

/// Where a [GeoLocation] came from. Shown in the UI so users can tell an
/// IP-based estimate from published exit-node metadata.
enum GeoLocationSource {
  /// Approximate location of a public IP address (ipwho.is / ipapi.co).
  ipLookup,

  /// Latitude/longitude published in the BelNet exit-node list.
  nodeMetadata,

  /// Built-in metadata for the default exit node (exit.bdx).
  builtInDefault,
}

/// An approximate geographical location, optionally tied to a public IP.
@immutable
class GeoLocation {
  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.ip,
    this.city,
    this.region,
    this.country,
    this.countryCode,
    this.source = GeoLocationSource.ipLookup,
  });

  final double latitude;
  final double longitude;
  final String? ip;
  final String? city;
  final String? region;
  final String? country;
  final String? countryCode;
  final GeoLocationSource source;

  /// True when the coordinates are usable for drawing on the map.
  ///
  /// (0, 0) is rejected on purpose: the existing lookup code uses it as its
  /// "every API failed" fallback, and it is in the middle of the ocean.
  bool get hasCoordinates =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      !(latitude == 0 && longitude == 0);

  /// "City, Country", falling back to whichever part is known.
  String get displayName {
    final parts = <String>[
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
      if (country != null && country!.trim().isNotEmpty) country!.trim(),
    ];
    return parts.join(', ');
  }

  GeoLocation copyWith({
    double? latitude,
    double? longitude,
    String? ip,
    String? city,
    String? region,
    String? country,
    String? countryCode,
    GeoLocationSource? source,
  }) {
    return GeoLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ip: ip ?? this.ip,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'ip': ip,
        'city': city,
        'region': region,
        'country': country,
        'countryCode': countryCode,
        'source': source.name,
      };

  /// Returns null for malformed input instead of throwing, so a corrupt
  /// SharedPreferences entry can never crash start-up.
  static GeoLocation? fromJson(Object? json) {
    if (json is! Map) return null;
    final lat = _toDouble(json['latitude']);
    final lon = _toDouble(json['longitude']);
    if (lat == null || lon == null) return null;
    final sourceName = json['source']?.toString();
    final source = GeoLocationSource.values.firstWhere(
      (s) => s.name == sourceName,
      orElse: () => GeoLocationSource.ipLookup,
    );
    return GeoLocation(
      latitude: lat,
      longitude: lon,
      ip: _toNonEmptyString(json['ip']),
      city: _toNonEmptyString(json['city']),
      region: _toNonEmptyString(json['region']),
      country: _toNonEmptyString(json['country']),
      countryCode: _toNonEmptyString(json['countryCode']),
      source: source,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GeoLocation &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.ip == ip &&
      other.city == city &&
      other.region == region &&
      other.country == country &&
      other.countryCode == countryCode &&
      other.source == source;

  @override
  int get hashCode => Object.hash(
      latitude, longitude, ip, city, region, country, countryCode, source);

  @override
  String toString() =>
      'GeoLocation($displayName, $latitude, $longitude, ip: $ip, ${source.name})';
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

String? _toNonEmptyString(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

/// Parses a numeric JSON value that may arrive as a number or a string.
double? parseGeoDouble(Object? value) => _toDouble(value);

/// Normalises an optional JSON string (trimmed, empty -> null).
String? parseGeoString(Object? value) => _toNonEmptyString(value);
