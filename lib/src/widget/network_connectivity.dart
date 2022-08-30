import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { connected, disconnected }

class NetworkService {
  StreamController<NetworkStatus> controller = StreamController();

  NetworkService() {
    Connectivity().onConnectivityChanged.listen((event) {
      controller.add(_networkStatus(event));
    });
  }

  NetworkStatus _networkStatus(ConnectivityResult connectivityResult) {
    return connectivityResult == ConnectivityResult.mobile ||
            connectivityResult == ConnectivityResult.wifi ||
            connectivityResult == ConnectivityResult.ethernet
        ? NetworkStatus.connected
        : NetworkStatus.disconnected;
  }
}
