import 'dart:async';

import 'package:belnet_mobile/src/vpn_controller.dart';
import 'package:belnet_mobile/src/widget/modelResponse.dart';
import 'package:flutter/material.dart';

class VpnConnectionProvider with ChangeNotifier {
  ConnectionStatus _status = ConnectionStatus.DISCONNECTED;
  Timer? _pollTimer;
  DateTime? _pollDeadline;
  bool _pollBusy = false;

  ConnectionStatus get status => _status;

  /// Polls the daemon status until the exit tunnel is actually ready,
  /// replacing the old fixed 19-second delay.
  ///
  /// "Ready" means the daemon reports:
  ///   isconnected == true  AND  an exit is mapped  AND  numPathsBuilt > 0.
  ///
  /// Calls [onConnected] as soon as that is true (typically 4-8 s), or
  /// [onFailed] with the last observed daemon state if [timeout] elapses.
  void startStatusPolling({
    required Future<Map<String, dynamic>?> Function() getStatus,
    required void Function() onConnected,
    required void Function(String reason) onFailed,
    Duration interval = const Duration(milliseconds: 500),
    Duration timeout = const Duration(seconds: 30),
  }) {
    cancelPolling();
    _pollDeadline = DateTime.now().add(timeout);
    String lastState = 'no status received from daemon';

    _pollTimer = Timer.periodic(interval, (timer) async {
      if (_pollBusy) return; // don't overlap slow platform-channel calls
      if (DateTime.now().isAfter(_pollDeadline!)) {
        cancelPolling();
        onFailed(lastState);
        return;
      }
      _pollBusy = true;
      try {
        final raw = await getStatus();
        if (raw != null) {
          final s = Welcome.fromJson(raw);
          lastState = 'paths built: ${s.numPathsBuilt}, '
              'peers: ${s.numPeersConnected}, '
              'exit mapped: ${s.exitMap != null}, '
              'daemon ready: ${s.isConnected}';
          final ready = s.isConnected &&
              s.exitMap != null &&
              s.exitMap!.the0.isNotEmpty &&
              s.numPathsBuilt > 0;
          if (ready && _pollTimer != null) {
            cancelPolling();
            onConnected();
          }
        }
      } catch (_) {
        // Malformed/missing status: keep polling until the deadline.
      } finally {
        _pollBusy = false;
      }
    });
  }

  void cancelPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Kept for backwards compatibility with existing call sites
  /// (e.g. home_screen.dart) that cancel the old fixed delay.
  void cancelDelay() => cancelPolling();
}
