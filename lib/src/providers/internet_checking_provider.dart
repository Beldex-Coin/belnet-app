// import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';

// class ConnectivityProvider with ChangeNotifier {
//   bool _isConnected = true;
//   bool get isConnected => _isConnected;

//   ConnectivityProvider() {
//     _initConnectivity();
//     Connectivity().onConnectivityChanged.listen((results) {
//       _updateConnectionStatusFromList(results);
//     });
//   }

//   Future<void> _initConnectivity() async {
//     final results = await Connectivity().checkConnectivity();
//     _updateConnectionStatusFromList(results);
//   }

//   void _updateConnectionStatusFromList(List<ConnectivityResult> results) {
//     final hasConnection = results.any((result) => result != ConnectivityResult.none);
//     if (hasConnection != _isConnected) {
//       _isConnected = hasConnection;
//       notifyListeners();
//     }
//   }
// }
// connectivity_provider.dart

import 'package:belnet_mobile/src/utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  ConnectivityProvider() {
    _initConnectivity();
    Connectivity().onConnectivityChanged.listen((results) {
      _updateConnectionStatusFromList(results);
    });
  }

  Future<void> _initConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatusFromList(results);
  }

  void _updateConnectionStatusFromList(List<ConnectivityResult> results) {
    final hasConnection = results.any((result) => (result == ConnectivityResult.wifi) || result == ConnectivityResult.mobile); //(result != ConnectivityResult.none)
 
    // Only show toast when internet is lost
    if (_isConnected && !hasConnection) {
      showMessage('No Internet. Make sure WiFi/Mobile data is on');
      // Fluttertoast.showToast(
      //   msg: "No Internet",
      //   toastLength: Toast.LENGTH_SHORT,
      //   gravity: ToastGravity.BOTTOM,
      // );
    }

    if (_isConnected != hasConnection) {
      _isConnected = hasConnection;
      notifyListeners();
    }
  }
}
