import 'dart:convert';

import 'package:belnet_mobile/src/map/geo_location.dart';
import 'package:belnet_mobile/src/map/ip_geolocation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GeoLocation', () {
    test('JSON round trip', () {
      const loc = GeoLocation(
        latitude: 12.97,
        longitude: 77.59,
        ip: '203.0.113.7',
        city: 'Bengaluru',
        region: 'Karnataka',
        country: 'India',
        countryCode: 'IN',
      );
      final back = GeoLocation.fromJson(jsonDecode(jsonEncode(loc.toJson())));
      expect(back, loc);
      expect(back!.displayName, 'Bengaluru, India');
    });

    test('fromJson tolerates garbage', () {
      expect(GeoLocation.fromJson(null), isNull);
      expect(GeoLocation.fromJson('x'), isNull);
      expect(GeoLocation.fromJson({'latitude': 'a'}), isNull);
    });

    test('(0,0) and out-of-range coordinates are not drawable', () {
      expect(const GeoLocation(latitude: 0, longitude: 0).hasCoordinates,
          isFalse);
      expect(const GeoLocation(latitude: 95, longitude: 0).hasCoordinates,
          isFalse);
      expect(const GeoLocation(latitude: 48.58, longitude: 7.74).hasCoordinates,
          isTrue);
    });
  });

  group('IpGeolocationService parsing', () {
    test('parses ipwho.is', () {
      final loc = IpGeolocationService.parseIpWhoIs({
        'ip': '198.51.100.4',
        'success': true,
        'country': 'France',
        'country_code': 'fr',
        'region': 'Grand Est',
        'city': 'Strasbourg',
        'latitude': 48.5734053,
        'longitude': 7.7521113,
      });
      expect(loc, isNotNull);
      expect(loc!.ip, '198.51.100.4');
      expect(loc.countryCode, 'FR');
      expect(loc.city, 'Strasbourg');
      expect(loc.source, GeoLocationSource.ipLookup);
    });

    test('rejects ipwho.is failures', () {
      expect(
          IpGeolocationService.parseIpWhoIs(
              {'success': false, 'message': 'Reserved range'}),
          isNull);
    });

    test('parses ipapi.co', () {
      final loc = IpGeolocationService.parseIpApi({
        'ip': '192.0.2.1',
        'city': 'Mumbai',
        'region': 'Maharashtra',
        'country_name': 'India',
        'country_code': 'IN',
        'latitude': 19.07,
        'longitude': 72.88,
      });
      expect(loc!.country, 'India');
      expect(loc.latitude, 19.07);
    });

    test('rejects ipapi.co errors', () {
      expect(
          IpGeolocationService.parseIpApi(
              {'error': true, 'reason': 'RateLimited'}),
          isNull);
    });

    test('falls back to ipapi.co when ipwho.is fails', () async {
      final requested = <String>[];
      final client = MockClient((req) async {
        requested.add(req.url.host);
        if (req.url.host == 'ipwho.is') return http.Response('oops', 503);
        return http.Response(
            jsonEncode({
              'ip': '192.0.2.1',
              'country_name': 'Germany',
              'country_code': 'DE',
              'city': 'Berlin',
              'latitude': 52.52,
              'longitude': 13.40,
            }),
            200);
      });
      final loc = await IpGeolocationService.lookup(client: client);
      expect(requested, ['ipwho.is', 'ipapi.co']);
      expect(loc!.city, 'Berlin');
    });

    test('returns null when every provider fails', () async {
      final client = MockClient((_) async => http.Response('', 500));
      expect(await IpGeolocationService.lookup(ip: '1.1.1.1', client: client),
          isNull);
    });
  });
}
