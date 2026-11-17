import 'dart:convert';

import 'package:belnet_mobile/src/providers/ad_blocker_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Native Ad Blocker simulated behind the plugin's method channel.
class _FakeNative {
  bool enabled = false;
  bool failNext = false;
  final calls = <MethodCall>[];

  Map<String, dynamic> status() => {
        'enabled': enabled,
        'gatewayActive': true,
        'filteringActive': enabled,
        'systemDnsProtected': false,
        'domains': 152318,
        'usingBuiltinList': false,
        'updating': false,
        'listsUpdatedAt': DateTime(2026, 11, 1).millisecondsSinceEpoch,
        'lastError': null,
        'sessionBlocked': 42,
        'privateDnsMode': 'opportunistic',
        'privateDnsActive': false,
        'sources': [],
      };

  Future<Object?> handle(MethodCall call) async {
    calls.add(call);
    switch (call.method) {
      case 'adBlockerGetStatus':
        return jsonEncode(status());
      case 'adBlockerSetEnabled':
        if (failNext) {
          failNext = false;
          throw PlatformException(code: 'boom');
        }
        enabled = (call.arguments as Map)['enabled'] as bool;
        return jsonEncode(status());
      case 'adBlockerRefresh':
        return true;
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('belnet_lib_method_channel');
  late _FakeNative native;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AdBlockerProvider.preload(); // reset the start-up value per test
    native = _FakeNative();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, native.handle);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('saved ON preference is shown immediately after reopening the app',
      () async {
    SharedPreferences.setMockInitialValues({'ad_blocker_enabled': true});
    native.enabled = true;
    await AdBlockerProvider.preload();
    final p = AdBlockerProvider();
    // No await yet: this is what Settings draws on its first frame.
    expect(p.enabled, isTrue);
    final seen = <bool>[];
    p.addListener(() => seen.add(p.enabled));
    await p.load();
    expect(p.enabled, isTrue);
    expect(seen.where((v) => v == false), isEmpty,
        reason: 'the switch must never flash OFF');
  });

  test('saved OFF preference starts OFF', () async {
    SharedPreferences.setMockInitialValues({'ad_blocker_enabled': false});
    await AdBlockerProvider.preload();
    expect(AdBlockerProvider().enabled, isFalse);
  });

  test('load takes the native preference as the source of truth', () async {
    native.enabled = true;
    final p = AdBlockerProvider();
    await p.load();
    expect(p.enabled, isTrue);
    expect(p.status!.domains, 152318);
    expect(p.status!.sessionBlocked, 42);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('ad_blocker_enabled'), isTrue);
  });

  test('setEnabled applies natively and mirrors the value', () async {
    final p = AdBlockerProvider();
    await p.load();
    expect(p.enabled, isFalse);

    expect(await p.setEnabled(true), isTrue);
    expect(native.enabled, isTrue);
    expect(p.enabled, isTrue);
    expect(p.status!.filteringActive, isTrue);
    expect(
      native.calls.where((c) => c.method == 'adBlockerSetEnabled').single.arguments,
      {'enabled': true},
    );

    expect(await p.setEnabled(false), isTrue);
    expect(native.enabled, isFalse);
    expect(p.status!.filteringActive, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('ad_blocker_enabled'), isFalse);
  });

  test('a failed toggle reverts the switch', () async {
    final p = AdBlockerProvider();
    await p.load();
    native.failNext = true;
    expect(await p.setEnabled(true), isFalse);
    expect(p.enabled, isFalse);
    expect(p.busy, isFalse);
  });

  test('status parsing and Private DNS detection', () {
    final s = AdBlockerStatus.fromMap({
      'enabled': true,
      'domains': 10,
      'listsUpdatedAt': 0,
      'lastError': '',
      'privateDnsMode': 'hostname',
    });
    expect(s.enabled, isTrue);
    expect(s.listsUpdatedAt, isNull);
    expect(s.lastError, isNull);
    expect(s.privateDnsBypass, isTrue);
    expect(AdBlockerStatus.fromMap({'privateDnsMode': 'opportunistic'}).privateDnsBypass,
        isFalse);
  });

  test('filter lists and download progress are parsed', () {
    final s = AdBlockerStatus.fromMap({
      'enabled': true,
      'updating': true,
      'updateDone': 3,
      'updateTotal': 11,
      'sources': [
        {
          'id': 'adguard_dns',
          'name': 'AdGuard DNS filter',
          'site': 'adguardteam.github.io',
          'state': null,
          'percent': -1,
          'status': 'updated',
          'rules': 190357,
          'fetchedAt': DateTime(2026, 11, 16).millisecondsSinceEpoch,
          'error': null,
        },
        {
          'id': 'hagezi_multi',
          'name': 'HaGeZi Multi Normal',
          'site': 'github.com/hagezi',
          'state': 'downloading',
          'percent': 64,
          'status': 'missing',
          'rules': 0,
          'fetchedAt': 0,
        },
        {
          'id': 'hagezi_tif_mini',
          'name': 'HaGeZi Threat Intelligence (mini)',
          'site': 'github.com/hagezi',
          'state': 'waiting',
          'status': 'failed',
          'rules': 0,
          'error': 'HTTP 503',
        },
        'not a map',
      ],
    });
    expect(s.updateDone, 3);
    expect(s.updateTotal, 11);
    expect(s.sources.length, 3);
    final a = s.sources[0];
    expect(a.site, 'adguardteam.github.io');
    expect(a.domains, 190357);
    expect(a.downloaded, isTrue);
    expect(a.downloading || a.waiting, isFalse);
    expect(a.updatedAt, DateTime(2026, 11, 16));
    expect(s.sources[1].downloading, isTrue);
    expect(s.sources[1].percent, 64);
    expect(s.sources[2].waiting, isTrue);
    expect(s.sources[2].percent, -1);
    expect(s.sources[2].failed, isTrue);
    expect(AdBlockerStatus.fromMap({'enabled': false}).sources, isEmpty);
  });

  test('refreshLists asks native to check for updates', () async {
    final p = AdBlockerProvider();
    await p.refreshLists();
    expect(native.calls.map((c) => c.method), contains('adBlockerRefresh'));
  });
}
