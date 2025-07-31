import 'package:async/async.dart';
import 'package:belnet_mobile/src/vpn_controller.dart';
import 'package:flutter/material.dart';

class VpnConnectionProvider with ChangeNotifier {
  ConnectionStatus _status = ConnectionStatus.DISCONNECTED;
  CancelableOperation? _delayOperation;

  ConnectionStatus get status => _status;

  // void setStatus(ConnectionStatus status) {
  //   _status = status;
  //   notifyListeners();
  // }

  void startConnectionDelay(VoidCallback onCompleted) {
    cancelDelay(); // Cancel if already running

    _delayOperation = CancelableOperation.fromFuture(
      Future.delayed(Duration(seconds: 19)),
      onCancel: () => print("VPN connection delay cancelled."),
    );

    _delayOperation!.value.then((_) {
      //if (_status == ConnectionStatus.CONNECTING) {
        //setStatus(ConnectionStatus.CONNECTED);
        onCompleted();
      //}
    });
  }

  void cancelDelay() {
    _delayOperation?.cancel();
    _delayOperation = null;
  }
}