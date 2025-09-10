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


static const EventChannel disconnectEventChannel = EventChannel('belnet_lib_notification_disconnect_event_channel');



  static bool _isConnected = false;

  static bool get isConnected => _isConnected;

  static Stream<bool> _isConnectedEventStream = _isConnectedEventChannel
      .receiveBroadcastStream()
      .cast<bool>()
    ..listen((dynamic newIsConnected) => _isConnected = newIsConnected);

  static Stream<bool> get isConnectedEventStream => _isConnectedEventStream;

  static Future bootstrapBelnet() async {
    try{
      final request = await HttpClient().getUrl(Uri.parse('https://belnet-exitnode.s3.ap-south-1.amazonaws.com/bootstrap-files/bootstrap.signed'
        //'https://deb.beldex.io/Beldex-projects/Belnet/bootstrap-files/bootstrap.signed'
      ));
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
    }catch(e){
      print('Exception $e');
    }
   
  }

  static Future<bool> prepareConnection() async {
    if (!(await isBootstrapped)) await bootstrapBelnet();
    final bool prepare = await _methodChannel.invokeMethod('prepare');
    return prepare;
  }

//conncting belnet
  static Future<bool> connectToBelnet(
      //"9.9.9.9"
      List<String> packageNames,
      {String exitNode =
          "exit.bdx",
      String upstreamDNS = "9.9.9.9"}) async {
    final bool connect = await _methodChannel.invokeMethod(
        'connect', {"exit_node": exitNode, "upstream_dns": upstreamDNS, "package_names": packageNames});

    return connect;
  }

  static Future<bool> disconnectFromBelnet() async {
    final bool disconnect = await _methodChannel.invokeMethod('disconnect');

    return disconnect;
  }

// is prepared function
  static Future<bool> get isPrepared async {
    final bool prepared = await _methodChannel.invokeMethod('isPrepared');

    return prepared;
  }

  static Future<bool> get isRunning async {
    final bool isRunning = await _methodChannel.invokeMethod('isRunning');
    return isRunning;
  }

//isbootstrap function
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

  static Future<Map<String, dynamic>?> getStatus() async {
    var status = await _methodChannel.invokeMethod('getStatus') as String?;
    if (status != null && status.isNotEmpty) return jsonDecode(status);
    return null;
  }

  static Future<dynamic> get upload async {
    var uploadStatus = await _methodChannel.invokeMethod('getUploadSpeed');
    return uploadStatus;
  }

  static Future<dynamic> get download async {
    var downloadStatus = await _methodChannel.invokeMethod('getDownloadSpeed');
    return downloadStatus;
  }

  static Future<String> get logDetails async {
    var logD;
    // try{
    logD = await _methodChannel.invokeMethod("logData");

    print("this is from log data $logD");

    return logD;
  }

  static Future<dynamic> get getSpeedStatus async {
    var status = await _methodChannel.invokeMethod('getDataStatus') as String;
    if (status.isNotEmpty) return jsonDecode(status);
    return null;
  }
static Future<dynamic>  unmapExitNode(String swapNode) async {
    final dynamic isUnmap = await _methodChannel.invokeMethod('getMap',{"swap_node": swapNode});
    return isUnmap;
  }

static Future<bool> isDisconnectForBelnetNotification() async {
    final bool disconnect = await _methodChannel.invokeMethod('disconnectForNotification');

    return disconnect;
  }

static Future<dynamic> getInstalledApps()async{
    final List<dynamic> result = await _methodChannel.invokeMethod('getInstalledAppsWithInternetPermission');
    return result;
}

}
