import 'package:belnet_mobile/src/providers/vpn_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fires onConnected once daemon reports a ready exit tunnel', () async {
    final provider = VpnConnectionProvider();
    var calls = 0;
    var connected = false;
    String? failReason;

    Future<Map<String, dynamic>?> fakeStatus() async {
      calls++;
      if (calls == 1) return null; // service not bound yet
      if (calls == 2) {
        return {'isconnected': false, 'numPathsBuilt': 0}; // still building
      }
      return {
        'isconnected': true,
        'numPathsBuilt': 4,
        'numPeersConnected': 6,
        'exitMap': {'::/0': 'exit.bdx'},
      };
    }

    provider.startStatusPolling(
      getStatus: fakeStatus,
      interval: const Duration(milliseconds: 10),
      timeout: const Duration(seconds: 2),
      onConnected: () => connected = true,
      onFailed: (r) => failReason = r,
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(connected, isTrue);
    expect(failReason, isNull);
  });

  test('fires onFailed with last state after timeout', () async {
    final provider = VpnConnectionProvider();
    var connected = false;
    String? failReason;

    provider.startStatusPolling(
      getStatus: () async => {'isconnected': false, 'numPathsBuilt': 0},
      interval: const Duration(milliseconds: 10),
      timeout: const Duration(milliseconds: 100),
      onConnected: () => connected = true,
      onFailed: (r) => failReason = r,
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(connected, isFalse);
    expect(failReason, contains('paths built: 0'));
  });

  test('cancelPolling prevents any further callbacks', () async {
    final provider = VpnConnectionProvider();
    var fired = false;

    provider.startStatusPolling(
      getStatus: () async => {
        'isconnected': true,
        'numPathsBuilt': 1,
        'exitMap': {'::/0': 'exit.bdx'},
      },
      interval: const Duration(milliseconds: 50),
      timeout: const Duration(seconds: 1),
      onConnected: () => fired = true,
      onFailed: (_) => fired = true,
    );
    provider.cancelPolling();

    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(fired, isFalse);
  });
}
