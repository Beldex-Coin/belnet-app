import 'dart:convert';

import 'package:belnet_mobile/src/map/geo_location.dart';
import 'package:http/http.dart' as http;

/// Public-IP geolocation (never GPS).
///
/// Uses the two HTTPS endpoints the app already relied on, in order:
///   1. https://ipwho.is/[ip]
///   2. https://ipapi.co/[ip/]json/
/// Both are keyless free tiers, so no API configuration is required.
///
/// Called without [ip] the services geolocate the caller's own public IP:
/// the user's real address while the tunnel is down, or the exit node's
/// address while it is up.
class IpGeolocationService {
  IpGeolocationService._();

  static const Duration requestTimeout = Duration(seconds: 5);

  /// Returns null when every provider failed (offline, rate-limited, ...).
  static Future<GeoLocation?> lookup({
    String? ip,
    http.Client? client,
    Duration timeout = requestTimeout,
  }) async {
    final target = (ip == null || ip.trim().isEmpty) ? null : ip.trim();
    final owned = client == null;
    final c = client ?? http.Client();
    try {
      final whoIs = await _get(
        c,
        timeout,
        Uri.parse(
            target == null ? 'https://ipwho.is/' : 'https://ipwho.is/$target'),
      );
      final fromWhoIs = whoIs == null ? null : parseIpWhoIs(whoIs);
      if (fromWhoIs != null) return fromWhoIs;

      final ipApi = await _get(
        c,
        timeout,
        Uri.parse(target == null
            ? 'https://ipapi.co/json/'
            : 'https://ipapi.co/$target/json/'),
      );
      return ipApi == null ? null : parseIpApi(ipApi);
    } finally {
      if (owned) c.close();
    }
  }

  static Future<Map<String, dynamic>?> _get(
      http.Client c, Duration timeout, Uri uri) async {
    try {
      final res = await c.get(uri).timeout(timeout);
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Network error, timeout or malformed body: try the next provider.
    }
    return null;
  }

  /// Parses an ipwho.is response. Returns null for `success: false` or when
  /// coordinates are missing.
  static GeoLocation? parseIpWhoIs(Map<String, dynamic> data) {
    if (data['success'] == false) return null;
    final lat = parseGeoDouble(data['latitude']);
    final lon = parseGeoDouble(data['longitude']);
    if (lat == null || lon == null) return null;
    final loc = GeoLocation(
      latitude: lat,
      longitude: lon,
      ip: parseGeoString(data['ip']),
      city: parseGeoString(data['city']),
      region: parseGeoString(data['region']),
      country: parseGeoString(data['country']),
      countryCode: parseGeoString(data['country_code'])?.toUpperCase(),
      source: GeoLocationSource.ipLookup,
    );
    return loc.hasCoordinates ? loc : null;
  }

  /// Parses an ipapi.co response. Returns null for `error: true` or when
  /// coordinates are missing.
  static GeoLocation? parseIpApi(Map<String, dynamic> data) {
    if (data['error'] == true) return null;
    final lat = parseGeoDouble(data['latitude']);
    final lon = parseGeoDouble(data['longitude']);
    if (lat == null || lon == null) return null;
    final loc = GeoLocation(
      latitude: lat,
      longitude: lon,
      ip: parseGeoString(data['ip']),
      city: parseGeoString(data['city']),
      region: parseGeoString(data['region']),
      country: parseGeoString(data['country_name']),
      countryCode: parseGeoString(data['country_code'] ?? data['country'])
          ?.toUpperCase(),
      source: GeoLocationSource.ipLookup,
    );
    return loc.hasCoordinates ? loc : null;
  }
}
