import 'dart:async';
import 'dart:io';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:flutter/foundation.dart';

/// End-to-end health of the VPN tunnel.
///
/// The daemon reporting "running" (or even "exit mapped") does not guarantee
/// packets actually reach the internet: the exit's upstream can be down, DNS
/// through the exit can be broken, or paths can silently die after a network
/// handover. Because belnet routes 0.0.0.0/0 into the TUN, any of those means
/// total loss of connectivity while the UI would otherwise show "Connected".
///
/// This provider probes a tiny generate_204 endpoint through the tunnel right
/// after connecting and every [_interval] afterwards, and flips to
/// [TunnelHealth.broken] after two consecutive failures so a single dropped
/// probe doesn't cause churn.
enum TunnelHealth { unknown, healthy, broken }

class TunnelHealthProvider with ChangeNotifier {
  static const _probeUrl = 'http://connectivitycheck.gstatic.com/generate_204';
  static const _interval = Duration(seconds: 45);
  static const _probeTimeout = Duration(seconds: 5);
  static const _failuresBeforeBroken = 2;

  TunnelHealth _health = TunnelHealth.unknown;
  Timer? _timer;
  StreamSubscription<void>? _netChangeSub;
  int _consecutiveFailures = 0;
  bool _probeBusy = false;
  void Function()? _onBroken;

  TunnelHealth get health => _health;
  bool get isBroken => _health == TunnelHealth.broken;

  /// Start monitoring. [onBroken] fires once each time health transitions to
  /// broken (reset by the next healthy probe or by [start]/[stop]).
  void start({void Function()? onBroken}) {
    stop();
    _onBroken = onBroken;
    _consecutiveFailures = 0;
    _setHealth(TunnelHealth.unknown);
    // Probe immediately, then periodically.
    _probeNow();
    _timer = Timer.periodic(_interval, (_) => _probeNow());
    // Re-probe promptly when the platform reports the underlying network
    // changed (Wi-Fi <-> mobile handover) - see BelnetDaemon network callback.
    try {
      _netChangeSub = BelnetLib.networkChangeStream.listen(
        (_) => _probeNow(),
        onError: (Object _) {},
      );
    } catch (_) {
      // Event channel not available (e.g. old native lib); periodic probing
      // still covers this, just more slowly.
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _netChangeSub?.cancel();
    _netChangeSub = null;
    _onBroken = null;
    _consecutiveFailures = 0;
    _setHealth(TunnelHealth.unknown);
  }

  /// Run one probe immediately (used after exit swaps / reconnects).
  Future<void> probeNow() => _probeNow();

  Future<void> _probeNow() async {
    if (_probeBusy) return;
    _probeBusy = true;
    try {
      final ok = await _probe();
      if (ok) {
        _consecutiveFailures = 0;
        _setHealth(TunnelHealth.healthy);
      } else if (BelnetLib.isConnected) {
        _consecutiveFailures++;
        if (_consecutiveFailures >= _failuresBeforeBroken &&
            _health != TunnelHealth.broken) {
          _setHealth(TunnelHealth.broken);
          _onBroken?.call();
        }
      }
    } finally {
      _probeBusy = false;
    }
  }

  Future<bool> _probe() async {
    final client = HttpClient()..connectionTimeout = _probeTimeout;
    try {
      final request =
          await client.getUrl(Uri.parse(_probeUrl)).timeout(_probeTimeout);
      final response = await request.close().timeout(_probeTimeout);
      await response.drain<void>();
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  void _setHealth(TunnelHealth value) {
    if (_health != value) {
      _health = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _netChangeSub?.cancel();
    super.dispose();
  }
}
