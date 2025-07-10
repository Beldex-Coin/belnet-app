import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/widget/modelResponse.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SpeedChartProvider with ChangeNotifier {
  List<FlSpot> downloadSpots = [];
  List<FlSpot> uploadSpots = [];
  double _xValue = 0;
  final int maxPoints = 20;
  Timer? _timer;

 int _download = 0;
 int _upload = 0;

int get download => _download;
int get upload => _upload;



  void startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (_)async {
      
print('START HERE S ');

var fromDaemon = await BelnetLib.getSpeedStatus;
    if (fromDaemon != null) {
      var data1 = Welcome.fromJson(fromDaemon);

      // rxRate = data1.rxRate;
      // txRate = data1.txRate;
    
     _download = data1.rxRate;
     _upload = data1.txRate;
     notifyListeners();

      // Simulate speeds
      //final downloadSpeed = data1.rxRate;
      //final uploadSpeed = data1.txRate;
      _addNewData(downloadSpeed: _download.toDouble(), //downloadSpeed,
       uploadSpeed:_upload.toDouble()// uploadSpeed
       );
    }
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
    _download = 0;
    _upload = 0;
    notifyListeners();
  }

  void _addNewData({required double downloadSpeed, required double uploadSpeed}) {
    _xValue += 1;
    downloadSpots.add(FlSpot(_xValue, downloadSpeed));
    uploadSpots.add(FlSpot(_xValue, uploadSpeed));

    if (downloadSpots.length > maxPoints) downloadSpots.removeAt(0);
    if (uploadSpots.length > maxPoints) uploadSpots.removeAt(0);

    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
