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
    // When set, "ready" additionally requires the daemon's exit mapping to
    // actually reflect the swap: either it matches [expectedExitNode] or it
    // differs from [previousExitValue] (the mapping observed BEFORE the
    // swap). Without this, a failed exit-node swap is reported as success,
    // because the OLD exit already satisfies the generic readiness check.
    String? expectedExitNode,
    String? previousExitValue,
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
          final exitValue = s.exitMap?.the0 ?? '';
          lastState = 'paths built: ${s.numPathsBuilt}, '
              'peers: ${s.numPeersConnected}, '
              'exit mapped: ${exitValue.isEmpty ? 'none' : exitValue}, '
              'daemon ready: ${s.isConnected}';
          bool ready = s.isConnected &&
              exitValue.isNotEmpty &&
              s.numPathsBuilt > 0;
          if (ready && (expectedExitNode != null || previousExitValue != null)) {
            final matchesExpected = expectedExitNode != null &&
                exitValuesMatch(exitValue, expectedExitNode);
            final changedFromPrevious = previousExitValue != null &&
                previousExitValue.isNotEmpty &&
                !exitValuesMatch(exitValue, previousExitValue);
            ready = matchesExpected || changedFromPrevious;
            if (!ready) {
              lastState = 'exit mapping still $exitValue ($lastState)';
            }
          }
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

/// True when two exit-node identifiers plausibly refer to the same node.
/// The daemon may report either the human-readable BNS name (exit.bdx) or a
/// resolved address for the same exit, so compare case-insensitively and
/// accept containment in either direction.
bool exitValuesMatch(String a, String b) {
  final x = a.trim().toLowerCase();
  final y = b.trim().toLowerCase();
  if (x.isEmpty || y.isEmpty) return false;
  return x == y || x.contains(y) || y.contains(x);
}
