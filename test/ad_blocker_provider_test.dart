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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    native = _FakeNative();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, native.handle);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
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

  test('refreshLists asks native to check for updates', () async {
    final p = AdBlockerProvider();
    await p.refreshLists();
    expect(native.calls.map((c) => c.method), contains('adBlockerRefresh'));
  });
}
