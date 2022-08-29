import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class BelnetLib {
  static const MethodChannel _methodChannel =
      const MethodChannel('belnet_lib_method_channel');

  static const EventChannel _isConnectedEventChannel =
      const EventChannel('belnet_lib_is_connected_event_channel');

  static bool _isConnected = false;

  static bool get isConnected => _isConnected;

  static Stream<bool> _isConnectedEventStream = _isConnectedEventChannel
      .receiveBroadcastStream()
      .cast<bool>()
    ..listen((dynamic newIsConnected) => _isConnected = newIsConnected);

  static Stream<bool> get isConnectedEventStream => _isConnectedEventStream;

  static Future bootstrapBelnet() async {  // https://generalfile.s3.ap-south-1.amazonaws.com/bootstrap.signed  https://deb.beldex.io/Beldex-projects/Belnet/bootstrap-files/belnet.signed
    final request = await HttpClient()
        .getUrl(Uri.parse('https://deb.beldex.io/Beldex-projects/Belnet/bootstrap-files/bootstrap.signed'));
    final response = await request.close();
    var path = await getApplicationDocumentsDirectory();
    await response
        .pipe(File('${path.parent.path}/files/bootstrap.signed').openWrite());
    if (await isBootstrapped) {
      print("Successfully bootstrapped!");
    } else {
      print("Bootstrapping went wrong!");
      print(Directory('${path.parent.path}/files/').listSync().toString());
    }
  }

  static Future<bool> prepareConnection() async {
    if (!(await isBootstrapped)) await bootstrapBelnet();
    final bool prepare = await _methodChannel.invokeMethod('prepare');
    return prepare;
  }

  static Future<bool> connectToBelnet(                                                                  //"9.9.9.9"
      {String exitNode = "7a4cpzri7qgqen9a3g3hgfjrijt9337qb19rhcdmx5y7yttak33o.bdx", String upstreamDNS = "1.1.1.1"}) async {
    final bool connect = await _methodChannel.invokeMethod(
        'connect', {"exit_node": exitNode, "upstream_dns": upstreamDNS});
    return connect;
  }

  static Future<bool> disconnectFromBelnet() async {
    final bool disconnect = await _methodChannel.invokeMethod('disconnect');
    return disconnect;
  }

  static Future<bool> get isPrepared async {
    final bool prepared = await _methodChannel.invokeMethod('isPrepared');
    return prepared;
  }

  static Future<bool> get isRunning async {
    final bool isRunning = await _methodChannel.invokeMethod('isRunning');
    return isRunning;
  }

  static Future<bool> get isBootstrapped async {
    var path = await getApplicationDocumentsDirectory();
    print('path for bootstrap ${path.parent.path}/files/bootstrap.signed');
    return File('${path.parent.path}/files/bootstrap.signed').existsSync();
  }

  static Future<dynamic> get status async {
    var status = await _methodChannel.invokeMethod('getStatus') as String;
    if (status.isNotEmpty) return jsonDecode(status);
    return null;
  }
}
