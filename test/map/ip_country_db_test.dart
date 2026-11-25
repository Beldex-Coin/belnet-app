import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:belnet_mobile/src/map/ip_country_db.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a table in the ip_country.bin format.
ByteData buildTable(
  List<(String code, double lat, double lon, String name)> countries,
  List<(int start, int index)> ranges,
) {
  final b = BytesBuilder();
  b.add(ascii.encode('BNIP'));
  b.add([1, 0, 0, 0]);
  final head = ByteData(8)
    ..setUint32(0, countries.length, Endian.little)
    ..setUint32(4, ranges.length, Endian.little);
  b.add(head.buffer.asUint8List());
  for (final c in countries) {
    final name = utf8.encode(c.$4);
    final e = ByteData(11)
      ..setUint8(0, c.$1.codeUnitAt(0))
      ..setUint8(1, c.$1.codeUnitAt(1))
      ..setFloat32(2, c.$2, Endian.little)
      ..setFloat32(6, c.$3, Endian.little)
      ..setUint8(10, name.length);
    b.add(e.buffer.asUint8List());
    b.add(name);
  }
  while (b.length % 4 != 0) {
    b.addByte(0);
  }
  final starts = ByteData(ranges.length * 4);
  for (var i = 0; i < ranges.length; i++) {
    starts.setUint32(i * 4, ranges[i].$1, Endian.little);
  }
  b.add(starts.buffer.asUint8List());
  b.add([for (final r in ranges) r.$2]);
  return ByteData.sublistView(b.toBytes());
}

void main() {
  group('parseIpv4', () {
    test('dotted and IPv4-mapped forms', () {
      expect(parseIpv4('1.2.3.4'), 0x01020304);
      expect(parseIpv4('::ffff:1.2.3.4'), 0x01020304);
      expect(parseIpv4('::FFFF:102:304'), 0x01020304);
      expect(parseIpv4('1.2.3.4:1090'), 0x01020304);
      expect(parseIpv4('[::ffff:1.2.3.4]:1090'), 0x01020304);
      expect(parseIpv4('255.255.255.255'), 0xFFFFFFFF);
    });

    test('rejects everything else', () {
      for (final bad in [
        null,
        '',
        '1.2.3',
        '1.2.3.256',
        '1..3.4',
        'a.b.c.d',
        '2001:db8::1',
        '::ffff:zz:1',
      ]) {
        expect(parseIpv4(bad), isNull, reason: '$bad');
      }
    });
  });

  test('lookup by range with gaps', () {
    final db = IpCountryDb.parse(buildTable(
      [('DE', 51.2, 10.4, 'Germany'), ('NL', 52.1, 5.3, 'Netherlands')],
      [
        (0, 255), // 0.0.0.0 - 4.255.255.255 unknown
        (0x05000000, 0), // 5.0.0.0 - DE
        (0x06000000, 255), // 6.0.0.0 - unknown
        (0x33000000, 1), // 51.0.0.0 - NL
        (0x34000000, 255),
      ],
    ));
    expect(db.lookup('4.255.255.255'), isNull);
    expect(db.lookup('5.0.0.0')?.code, 'DE');
    expect(db.lookup('5.9.10.10')?.name, 'Germany');
    expect(db.lookup('5.255.255.255')?.code, 'DE');
    expect(db.lookup('6.0.0.1'), isNull);
    final nl = db.lookup('::ffff:51.15.0.1')!;
    expect(nl.code, 'NL');
    expect(nl.latitude, closeTo(52.1, 1e-4));
    expect(nl.longitude, closeTo(5.3, 1e-4));
    expect(db.lookup('200.1.1.1'), isNull);
    expect(db.lookup('not an ip'), isNull);
  });

  test('rejects a file that is not a table', () {
    expect(() => IpCountryDb.parse(ByteData(4)), throwsFormatException);
  });

  test('bundled asset resolves well-known addresses', () {
    final bytes = File(IpCountryDb.assetPath).readAsBytesSync();
    final db = IpCountryDb.parse(ByteData.sublistView(bytes));
    expect(db.lookup('8.8.8.8')?.code, 'US');
    expect(db.lookup('5.9.10.10')?.code, 'DE');
    expect(db.lookup('51.15.0.1')?.code, 'NL');
    expect(db.lookup('95.216.0.1')?.code, 'FI');
    expect(db.lookup('192.168.1.1'), isNull);
    expect(db.lookup('10.0.0.1'), isNull);
  });
}
