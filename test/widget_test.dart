// Widget test for the home-screen map: every connection state, including
// the rotating globe with a real (fixture) onion route.

import 'package:belnet_mobile/node_provider.dart';
import 'package:belnet_mobile/src/map/vpn_map_provider.dart';
import 'package:belnet_mobile/src/map/vpn_world_map.dart';
import 'package:belnet_mobile/src/map/world_map_data.dart';
import 'package:belnet_mobile/src/providers/introstate_provider.dart';
import 'package:belnet_mobile/src/providers/ip_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/vpn_controller.dart' show ConnectionStatus;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'map/route_snapshot_test.dart' show dumpStatus, path, testDb;

/// Pumps in small steps so tickers see realistic frame intervals.
Future<void> pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  var t = Duration.zero;
  while (t < total) {
    await tester.pump(step);
    t += step;
  }
}

void main() {
  for (final dark in [true, false]) {
    testWidgets('map walks through every state (dark: $dark)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('belnet_lib_method_channel'),
        (call) async => call.method == 'isRunning' ? false : null,
      );
      await tester.runAsync(() => WorldMapData.load());

      Map<String, dynamic>? daemon; // what DumpStatus returns right now
      final db = testDb();
      final loader = LoaderVideoProvider();
      final map = VpnMapProvider(
        loader: loader,
        nodes: NodeProvider(),
        ip: IpProvider(),
        intro: IntroStateProvider(),
        statusStream: () => const Stream.empty(),
        routeStatus: () async => daemon,
        ipCountryDb: () async => db,
        failureDisplayDuration: const Duration(seconds: 3),
        routePollInterval: const Duration(milliseconds: 200),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<VpnMapProvider>.value(
          value: map,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 380,
                  height: 420,
                  child: VpnWorldMap(darkTheme: dark, bottomInset: 72),
                ),
              ),
            ),
          ),
        ),
      );
      await pumpFor(tester, const Duration(milliseconds: 400));
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('UNPROTECTED'), findsOneWidget);
      expect(find.byTooltip('Zoom in'), findsOneWidget);

      // Connecting: the globe spins while no path exists yet.
      loader.setConnectionStatus(ConnectionStatus.CONNECTING);
      await pumpFor(tester, const Duration(milliseconds: 600));
      expect(find.text('FINDING ROUTE'), findsOneWidget);
      expect(find.text('Searching Beldex nodes…'), findsOneWidget);

      // The daemon starts building a 4-hop path.
      daemon = dumpStatus(paths: [
        path('building', [
          ('aa', '5.9.10.10'),
          ('bb', '51.15.0.1'),
          ('cc', '95.216.0.1'),
          ('dd', '8.8.8.8'),
        ]),
      ]);
      await pumpFor(tester, const Duration(milliseconds: 1600));
      expect(map.connectStage, ConnectStage.hoppingNodes);
      expect(find.text('HOPPING NODES'), findsOneWidget);
      expect(find.textContaining('of 4'), findsOneWidget);
      // The trace walks the route hop by hop.
      await pumpFor(tester, const Duration(seconds: 3));
      expect(find.textContaining('of 4'), findsOneWidget);

      // A path to the exit is established.
      daemon = dumpStatus(remoteSessions: [
        {
          'readyToSend': true,
          'paths': [
            path('established', [
              ('aa', '5.9.10.10'),
              ('bb', '51.15.0.1'),
              ('cc', '95.216.0.1'),
              ('dd', '8.8.8.8'),
            ]),
          ],
        },
      ]);
      // The map still connects every hop one by one before ROUTE FOUND.
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(map.connectStage, ConnectStage.routeFound);
      expect(find.text('HOPPING NODES'), findsOneWidget);
      await pumpFor(tester, const Duration(seconds: 3));
      expect(find.text('ROUTE FOUND'), findsOneWidget);
      expect(find.text('Securing tunnel…'), findsOneWidget);

      // Tunnel verified: the leg to the exit is drawn, "route found" is
      // held, then the globe zooms into the flat map.
      loader.setConnectionStatus(ConnectionStatus.CONNECTED);
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(find.text('ROUTE FOUND'), findsOneWidget);
      await pumpFor(tester, const Duration(seconds: 8));
      expect(find.text('PROTECTED'), findsOneWidget);
      expect(find.text('FRANCE'), findsOneWidget); // default exit.bdx

      // Zoom controls and a pan gesture on the flat map.
      await tester.tap(find.byTooltip('Zoom in'));
      await pumpFor(tester, const Duration(seconds: 1));
      await tester.drag(find.byType(InteractiveViewer), const Offset(-60, 20));
      await pumpFor(tester, const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('Recenter'));
      await pumpFor(tester, const Duration(seconds: 1));

      map.markDisconnecting();
      await pumpFor(tester, const Duration(milliseconds: 400));
      expect(find.text('DISCONNECTING'), findsOneWidget);
      loader.setConnectionStatus(ConnectionStatus.DISCONNECTED);
      await pumpFor(tester, const Duration(milliseconds: 800));
      expect(find.text('UNPROTECTED'), findsOneWidget);

      // A failed attempt goes back to the flat map.
      loader.setConnectionStatus(ConnectionStatus.CONNECTING);
      await pumpFor(tester, const Duration(milliseconds: 500));
      map.markFailed('Exit tunnel did not become ready');
      loader.setConnectionStatus(ConnectionStatus.DISCONNECTED);
      await pumpFor(tester, const Duration(milliseconds: 1400));
      expect(find.text('CONNECTION FAILED'), findsOneWidget);
      expect(find.text('Exit tunnel did not become ready'), findsOneWidget);
      await pumpFor(tester, const Duration(seconds: 2));
      expect(find.text('UNPROTECTED'), findsOneWidget);

      // Tear down: tickers and timers must all stop.
      await tester.pumpWidget(const SizedBox.shrink());
      map.dispose();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a fast connection still shows every hop before the exit',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('belnet_lib_method_channel'),
      (call) async => call.method == 'isRunning' ? false : null,
    );
    await tester.runAsync(() => WorldMapData.load());
    // The very first read already reports the route as ready.
    final daemon = dumpStatus(remoteSessions: [
      {
        'readyToSend': true,
        'paths': [
          path('established', [
            ('aa', '5.9.10.10'),
            ('bb', '51.15.0.1'),
            ('cc', '95.216.0.1'),
          ]),
        ],
      },
    ]);
    final loader = LoaderVideoProvider();
    final map = VpnMapProvider(
      loader: loader,
      nodes: NodeProvider(),
      ip: IpProvider(),
      intro: IntroStateProvider(),
      statusStream: () => const Stream.empty(),
      routeStatus: () async => daemon,
      ipCountryDb: () async => testDb(),
      routePollInterval: const Duration(milliseconds: 200),
    );
    await tester.pumpWidget(ChangeNotifierProvider<VpnMapProvider>.value(
      value: map,
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(
              width: 380, height: 420, child: VpnWorldMap(darkTheme: true)),
        ),
      ),
    ));
    await pumpFor(tester, const Duration(milliseconds: 300));
    loader.setConnectionStatus(ConnectionStatus.CONNECTING);
    await pumpFor(tester, const Duration(milliseconds: 300));
    // ...and the tunnel is up almost at once.
    loader.setConnectionStatus(ConnectionStatus.CONNECTED);
    await pumpFor(tester, const Duration(milliseconds: 1500));
    expect(find.text('HOPPING NODES'), findsOneWidget);
    expect(find.text('PROTECTED'), findsNothing);
    await pumpFor(tester, const Duration(seconds: 4));
    expect(find.text('ROUTE FOUND'), findsOneWidget);
    await pumpFor(tester, const Duration(seconds: 7));
    expect(find.text('PROTECTED'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    map.dispose();
  });
}
