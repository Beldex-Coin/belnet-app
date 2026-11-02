// Widget smoke test for the interactive VPN world map.
//
// (This file previously held Flutter's default "counter increments"
// template test, which could never pass against this app.)

import 'package:belnet_mobile/node_provider.dart';
import 'package:belnet_mobile/src/map/vpn_connection_panel.dart';
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

void main() {
  for (final dark in [true, false]) {
    testWidgets('world map renders every connection phase (dark: $dark)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('belnet_lib_method_channel'),
        (call) async => call.method == 'isRunning' ? false : null,
      );
      // Parse the bundled GeoJSON on a real isolate before pumping.
      await tester.runAsync(() => WorldMapData.load());

      final loader = LoaderVideoProvider();
      final nodes = NodeProvider();
      final ip = IpProvider();
      final intro = IntroStateProvider();
      final map = VpnMapProvider(
        loader: loader,
        nodes: nodes,
        ip: ip,
        intro: intro,
        statusStream: () => const Stream.empty(),
        failureDisplayDuration: const Duration(seconds: 1),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<VpnMapProvider>.value(
          value: map,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 380,
                  height: 340,
                  child: VpnWorldMap(
                    darkTheme: dark,
                    bottomInset: VpnConnectionPanel.collapsedHeight + 16,
                    overlay: [
                      Positioned(
                        left: 10,
                        top: 10,
                        child: VpnMapStatusChip(dark: dark),
                      ),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: VpnConnectionPanel(dark: dark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('Not protected'), findsOneWidget);
      expect(find.text('Disconnected'), findsOneWidget);

      // Expand the information panel.
      await tester.tap(find.text('Not protected'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Original'), findsOneWidget);
      expect(find.text('VPN exit'), findsOneWidget);

      loader.setConnectionStatus(ConnectionStatus.CONNECTING);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Connecting…'), findsOneWidget);

      loader.setConnectionStatus(ConnectionStatus.CONNECTED);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('Protected'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);

      // Zoom controls and a pan gesture.
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump(const Duration(seconds: 1));
      await tester.drag(find.byType(InteractiveViewer), const Offset(-60, 20));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('Recenter'));
      await tester.pump(const Duration(seconds: 1));

      map.markDisconnecting();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Disconnecting…'), findsOneWidget);
      loader.setConnectionStatus(ConnectionStatus.DISCONNECTED);
      await tester.pump(const Duration(milliseconds: 800));

      map.markFailed('Exit tunnel did not become ready');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Connection failed'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Not protected'), findsOneWidget);

      // Tear down: tickers and timers must all stop.
      await tester.pumpWidget(const SizedBox.shrink());
      map.dispose();
      expect(tester.takeException(), isNull);
    });
  }
}
