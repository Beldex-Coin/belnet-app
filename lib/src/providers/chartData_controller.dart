import 'dart:async';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/widget/txrxspeed.dart';

class ChartDataController {
  final int windowLen = 10 * 6;

  late Timer daemonTimer;
  late Timer intervalTimer;
  late Timer changeDataTimer;

  late DateTime now;
  late AppModel appModel;

  double mbForDown = 0.0;
  double mbForUp = 0.0;
  double mbForUpDown = 0.0;

  void init(AppModel model) {
    appModel = model;
    getDataFromDaemon();
    setIntervalToCall();
    startChangeData();
  }

  void dispose() {
    daemonTimer.cancel();
    intervalTimer.cancel();
    changeDataTimer.cancel();
  }

  void getDataFromDaemon() {
    daemonTimer = Timer.periodic(Duration(milliseconds: 2000), (timer) {
      if (BelnetLib.isConnected) {
        TxRxSpeed().getDataFromChannel(appModel);
      }
    });
  }

  void setIntervalToCall() {
    intervalTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (BelnetLib.isConnected) {
        _getAndAssignForDownloadData();
        _getAndAssignForUploadData();
      }
    });
  }

  void _getAndAssignForDownloadData() {
    now = DateTime.now();
    if (appModel.downloadList.length >= windowLen) {
      appModel.downloadList.removeAt(0);
    }
    if (appModel.singleDownload.isNotEmpty) {
      appModel.downloadList.add(_stringBeforeSpace(appModel.singleDownload));
    }
  }

  void _getAndAssignForUploadData() {
    now = DateTime.now();
    if (appModel.uploadList.length >= windowLen) {
      appModel.uploadList.removeAt(0);
    }
    if (appModel.singleUpload.isNotEmpty) {
      appModel.uploadList.add(_stringBeforeSpace(appModel.singleUpload));
    }
  }

  double _stringBeforeSpace(String value) {
    String str = value.split(' ').first;
    return double.tryParse(str) ?? 0.0;
  }

  void startChangeData() {
    changeDataTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _setChangeData();
    });
  }

  void _setChangeData() {
    if (!BelnetLib.isConnected) return;

    List<double> myD = [
      appModel.graphData1,
      appModel.graphData2,
      appModel.graphData3,
    ];
    myD.sort();

    mbForDown = myD[0];
    mbForUp = myD[1];
    mbForUpDown = myD[2];

    print("Updated: $mbForUp $mbForDown $mbForUpDown");
  }
}
