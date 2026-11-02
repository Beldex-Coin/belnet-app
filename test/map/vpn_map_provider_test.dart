import 'dart:async';
import 'dart:convert';

import 'package:belnet_mobile/node_provider.dart';
import 'package:belnet_mobile/src/map/geo_location.dart';
import 'package:belnet_mobile/src/map/vpn_map_provider.dart';
import 'package:belnet_mobile/src/providers/introstate_provider.dart';
import 'package:belnet_mobile/src/providers/ip_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/vpn_controller.dart' show ConnectionStatus;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds the real providers with the native channel mocked as "tunnel not
/// running". (Network requests return HTTP 400 inside testWidgets.)
Future<
    ({
      LoaderVideoProvider loader,
      NodeProvider nodes,
      IpProvider ip,
      IntroStateProvider intro,
    })> _providers(WidgetTester tester,
    {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues({
    'selected_node_id': 3,
    'selected_node_name': 'exit.bdx',
    'selected_node_country': 'France',
    ...prefs,
  });
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('belnet_lib_method_channel'),
    (call) async {
      switch (call.method) {
        case 'isRunning':
        case 'isPrepared':
          return false;
      }
      return null;
    },
  );
  final loader = LoaderVideoProvider();
  final nodes = NodeProvider();
  final ip = IpProvider();
  final intro = IntroStateProvider();
  await tester.pump(const Duration(milliseconds: 50));
  return (loader: loader, nodes: nodes, ip: ip, intro: intro);
}

void main() {
  testWidgets('phases follow the real connection status', (tester) async {
    final p = await _providers(tester);
    final status = StreamController<Map<String, dynamic>>.broadcast();
    var now = DateTime(2026, 1, 1, 12);
    final map = VpnMapProvider(
      loader: p.loader,
      nodes: p.nodes,
      ip: p.ip,
      intro: p.intro,
      statusStream: () => status.stream,
      clock: () => now,
    );
    map.setMapVisible(true);

    expect(map.phase, VpnMapPhase.disconnected);
    expect(map.exit.nodeName, 'exit.bdx');
    // Default exit node falls back to its built-in France location.
    expect(map.exit.location!.latitude, 48.5848);
    expect(map.exit.location!.longitude, 7.7419);
    expect(map.exit.location!.country, 'France');

    p.loader.setConnectionStatus(ConnectionStatus.CONNECTING);
    expect(map.phase, VpnMapPhase.connecting);
    expect(map.tunnelActive, isTrue);

    p.loader.setConnectionStatus(ConnectionStatus.CONNECTED);
    expect(map.phase, VpnMapPhase.connected);

    now = now.add(const Duration(seconds: 75));
    status.add({
      'status': {'uptime': 80000},
      'upload': 1000,
      'download': 250000,
    });
    await tester.pump();
    expect(map.stats.value.connectedFor, const Duration(seconds: 75));
    expect(map.stats.value.downloadBytesPerSec, 250000);
    expect(map.stats.value.uploadBytesPerSec, 1000);

    // User disconnects: route retracts, details stay until the tunnel is down.
    map.markDisconnecting();
    expect(map.phase, VpnMapPhase.disconnecting);
    expect(map.stats.value.connectedFor, isNotNull);

    p.loader.setConnectionStatus(ConnectionStatus.DISCONNECTED);
    expect(map.phase, VpnMapPhase.disconnected);
    expect(map.stats.value, VpnLiveStats.empty);

    map.dispose();
    await status.close();
  });

  testWidgets('failure is shown, then the map returns to disconnected',
      (tester) async {
    final p = await _providers(tester);
    final map = VpnMapProvider(
      loader: p.loader,
      nodes: p.nodes,
      ip: p.ip,
      intro: p.intro,
      statusStream: () => const Stream.empty(),
      failureDisplayDuration: const Duration(seconds: 2),
    );

    p.loader.setConnectionStatus(ConnectionStatus.CONNECTING);
    map.markFailed('Exit tunnel did not become ready');
    p.loader.setConnectionStatus(ConnectionStatus.DISCONNECTED);
    expect(map.phase, VpnMapPhase.failed);
    expect(map.failureReason, 'Exit tunnel did not become ready');

    await tester.pump(const Duration(seconds: 3));
    expect(map.phase, VpnMapPhase.disconnected);
    expect(map.failureReason, isNull);

    // A new attempt clears a failure immediately.
    map.markFailed('x');
    p.loader.setConnectionStatus(ConnectionStatus.CONNECTING);
    expect(map.phase, VpnMapPhase.connecting);

    map.dispose();
  });

  testWidgets('aborted disconnect restores the connected phase',
      (tester) async {
    final p = await _providers(tester);
    final map = VpnMapProvider(
      loader: p.loader,
      nodes: p.nodes,
      ip: p.ip,
      intro: p.intro,
      statusStream: () => const Stream.empty(),
    );
    p.loader.setConnectionStatus(ConnectionStatus.CONNECTED);
    map.markDisconnecting();
    expect(map.phase, VpnMapPhase.disconnecting);
    map.cancelDisconnecting();
    expect(map.phase, VpnMapPhase.connected);
    map.dispose();
  });

  testWidgets('restored tunnel takes its duration from daemon uptime',
      (tester) async {
    final p = await _providers(tester);
    final status = StreamController<Map<String, dynamic>>.broadcast();
    final now = DateTime(2026, 1, 1, 12);
    final map = VpnMapProvider(
      loader: p.loader,
      nodes: p.nodes,
      ip: p.ip,
      intro: p.intro,
      statusStream: () => status.stream,
      clock: () => now,
    );
    map.setMapVisible(true);
    // App opened while the tunnel was already up (bottom_nav checkNode).
    p.loader.setConnectionStatus(ConnectionStatus.CONNECTED);
    await tester.pump();
    expect(map.stats.value.connectedFor, isNull); // unknown, not invented

    status.add({
      'status': {'uptime': 3723000},
      'upload': 0,
      'download': 0,
    });
    await tester.pump();
    expect(map.stats.value.connectedFor,
        const Duration(hours: 1, minutes: 2, seconds: 3));

    map.dispose();
    await status.close();
  });

  testWidgets('exit-node swap keeps the session and moves the exit',
      (tester) async {
    final p = await _providers(tester);
    final map = VpnMapProvider(
      loader: p.loader,
      nodes: p.nodes,
      ip: p.ip,
      intro: p.intro,
      statusStream: () => const Stream.empty(),
    );
    map.setMapVisible(true);
    p.loader.setConnectionStatus(ConnectionStatus.CONNECTING);
    p.loader.setConnectionStatus(ConnectionStatus.CONNECTED);
    await tester.pump(const Duration(seconds: 2));
    final before = map.stats.value.connectedFor;
    expect(before, isNotNull);

    // Swap to a node that is not in the (empty) list: no coordinates yet,
    // and the map must not invent any.
    await p.nodes.selectNode(42, 'some-node.bdx', 'Germany');
    p.loader.setConnectionStatus(ConnectionStatus.CONNECTING);
    expect(map.exit.nodeName, 'some-node.bdx');
    expect(map.exit.location, isNull);
    expect(map.exit.country, 'Germany');
    p.loader.setConnectionStatus(ConnectionStatus.CONNECTED);
    await tester.pump(const Duration(seconds: 1));
    expect(map.stats.value.connectedFor! >= before!, isTrue);

    map.dispose();
  });

  testWidgets('custom exit node shows its last known location at once',
      (tester) async {
    const node = 'abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnop.bdx';
    final p = await _providers(tester, prefs: {
      'stored_is_custom_node': true,
      'vpn_map_last_known_exit_locations': jsonEncode({
        node: const GeoLocation(
          latitude: 52.37,
          longitude: 4.90,
          city: 'Amsterdam',
          country: 'Netherlands',
          countryCode: 'NL',
        ).toJson(),
      }),
    });
    await p.nodes.selectNode(100, node, '');
    final map = VpnMapProvider(
      loader: p.loader,
      nodes: p.nodes,
      ip: p.ip,
      intro: p.intro,
      statusStream: () => const Stream.empty(),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(p.intro.isCustomNode, isTrue);
    p.loader.setConnectionStatus(ConnectionStatus.CONNECTING);
    // Available while connecting, before this session's IP lookup finishes,
    // and clearly flagged as last known.
    expect(map.exit.location?.country, 'Netherlands');
    expect(map.exit.locationIsLastKnown, isTrue);

    map.dispose();
  });

  test('formatters never invent values', () {
    expect(formatBitRate(null), '—');
    expect(formatBitRate(0), '0 b/s');
    expect(formatBitRate(125000), '1.00 Mb/s');
    expect(formatBitRate(1250), '10.0 Kb/s');
    expect(formatConnectionDuration(null), '—');
    expect(formatConnectionDuration(const Duration(seconds: 65)), '01:05');
    expect(formatConnectionDuration(const Duration(hours: 2, seconds: 9)),
        '2:00:09');
    expect(formatConnectionDuration(const Duration(days: 1, minutes: 3)),
        '1d 00:03:00');
  });

  test('default exit node metadata', () {
    expect(kDefaultExitNodeLocation.hasCoordinates, isTrue);
    expect(kDefaultExitNodeLocation.source, GeoLocationSource.builtInDefault);
  });
}
