import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

/// Country of an IP address from the bundled offline database.
class IpCountry {
  const IpCountry({
    required this.code,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  /// ISO 3166-1 alpha-2 code ("DE").
  final String code;
  final String name;

  /// Geographic centre of the country (not of the address itself).
  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) => other is IpCountry && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'IpCountry($code)';
}

/// Offline IPv4 -> country lookup used to place BelNet masternode hops on
/// the globe.
///
/// Hop addresses are never sent anywhere: asking an online geolocation
/// service about them would tell a third party the user's real IP together
/// with their whole onion route. The table is built from the free DB-IP
/// "IP to Country Lite" data (CC BY 4.0) by tool/build_ip_country_db.py.
///
/// Lookups are a binary search over a sorted Uint32List (about 20 steps),
/// so they are cheap enough to run on the UI isolate.
class IpCountryDb {
  IpCountryDb._(this._countries, this._starts, this._index);

  static const String assetPath = 'assets/map/ip_country.bin';

  final List<IpCountry> _countries;
  final Uint32List _starts;
  final Uint8List _index;

  static Future<IpCountryDb>? _loading;

  /// Loads the asset once per process; later calls share the same future.
  static Future<IpCountryDb> load() {
    return _loading ??= rootBundle.load(assetPath).then(parse).catchError(
      (Object e) {
        _loading = null; // allow a retry
        throw e;
      },
    );
  }

  /// Parses the binary table (see tool/build_ip_country_db.py).
  static IpCountryDb parse(ByteData data) {
    if (data.lengthInBytes < 16 ||
        data.getUint8(0) != 0x42 || // B
        data.getUint8(1) != 0x4E || // N
        data.getUint8(2) != 0x49 || // I
        data.getUint8(3) != 0x50 || // P
        data.getUint8(4) != 1) {
      throw const FormatException('Not an ip_country.bin v1 file');
    }
    final countryCount = data.getUint32(8, Endian.little);
    final rangeCount = data.getUint32(12, Endian.little);
    var o = 16;
    final countries = <IpCountry>[];
    for (var i = 0; i < countryCount; i++) {
      final code = String.fromCharCodes([data.getUint8(o), data.getUint8(o + 1)]);
      final lat = data.getFloat32(o + 2, Endian.little);
      final lon = data.getFloat32(o + 6, Endian.little);
      final nameLength = data.getUint8(o + 10);
      o += 11;
      final name = utf8.decode(
        Uint8List.view(data.buffer, data.offsetInBytes + o, nameLength),
        allowMalformed: true,
      );
      o += nameLength;
      countries.add(IpCountry(
        code: code,
        name: name,
        latitude: lat,
        longitude: lon,
      ));
    }
    while (o % 4 != 0) {
      o++;
    }
    final end = o + rangeCount * 5;
    if (end > data.lengthInBytes) {
      throw const FormatException('Truncated ip_country.bin');
    }
    // Copy into fresh typed lists: the asset ByteData's buffer offset is
    // not guaranteed to be 4-byte aligned, which a Uint32List view needs.
    final starts = Uint32List(rangeCount);
    for (var i = 0; i < rangeCount; i++) {
      starts[i] = data.getUint32(o + i * 4, Endian.little);
    }
    final index = Uint8List.fromList(Uint8List.view(
        data.buffer, data.offsetInBytes + o + rangeCount * 4, rangeCount));
    return IpCountryDb._(countries, starts, index);
  }

  /// Country of [ip], or null for private/reserved/unknown addresses and
  /// for anything that is not an IPv4 address (including IPv4-mapped IPv6
  /// "::ffff:1.2.3.4", which is accepted).
  IpCountry? lookup(String? ip) {
    final v = parseIpv4(ip);
    if (v == null || _starts.isEmpty) return null;
    // Last range whose start <= v.
    var lo = 0, hi = _starts.length - 1;
    if (v < _starts[0]) return null;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_starts[mid] <= v) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    final i = _index[lo];
    return i == 255 || i >= _countries.length ? null : _countries[i];
  }
}

/// Parses dotted IPv4 ("1.2.3.4") or IPv4-mapped IPv6 ("::ffff:1.2.3.4",
/// "::ffff:102:304") into an unsigned 32-bit value.
int? parseIpv4(String? raw) {
  if (raw == null) return null;
  var s = raw.trim();
  if (s.isEmpty) return null;
  // Strip a port ("1.2.3.4:1090") or brackets ("[::ffff:1.2.3.4]:1090").
  if (s.startsWith('[')) {
    final close = s.indexOf(']');
    if (close < 0) return null;
    s = s.substring(1, close);
  } else if (s.contains('.') && s.indexOf(':') == s.lastIndexOf(':') &&
      s.contains(':')) {
    s = s.substring(0, s.indexOf(':'));
  }
  final lower = s.toLowerCase();
  if (lower.startsWith('::ffff:')) {
    final rest = lower.substring(7);
    if (rest.contains('.')) {
      s = rest;
    } else {
      final parts = rest.split(':');
      if (parts.length != 2) return null;
      final hi = int.tryParse(parts[0], radix: 16);
      final lo = int.tryParse(parts[1], radix: 16);
      if (hi == null || lo == null || hi > 0xffff || lo > 0xffff) return null;
      return (hi << 16) | lo;
    }
  }
  final parts = s.split('.');
  if (parts.length != 4) return null;
  var v = 0;
  for (final p in parts) {
    if (p.isEmpty || p.length > 3) return null;
    final n = int.tryParse(p);
    if (n == null || n < 0 || n > 255) return null;
    v = (v << 8) | n;
  }
  return v;
}
