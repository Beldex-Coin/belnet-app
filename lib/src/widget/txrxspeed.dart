import 'dart:async';
import 'dart:convert';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';

import 'modelResponse.dart';

const int MAX_NUMBER_POINT_HISTORY = 60;

class TxRxSpeed {
  List uploadUsage = []; //List.filled(MAX_NUMBER_POINT_HISTORY, 0);
  List downloadUsage = []; //List.filled(MAX_NUMBER_POINT_HISTORY, 0);
  var lastUploadUsage;
  var lastDownloadUsage;
  var rxRate, txRate;

  List<Welcome> welcome = <Welcome>[];

  // dataString() {
  //   // if (lastDownloadUsage == null || lastUploadUsage == null) {

  //   // }
  //   Timer.periodic(Duration(milliseconds: 500), ((timer){
  //     getDataFromChannel();
  //   }));
  // }

  getDataFromChannel(AppModel appModel) async {
    var fromDaemon = await BelnetLib.getSpeedStatus;
    if (fromDaemon != null) {
      var data1 = Welcome.fromJson(fromDaemon);

      rxRate = data1.rxRate;
      txRate = data1.txRate;

      //  rxRate = fromDaemon["rxRate"];
      //  txRate = fromDaemon["txRate"];
      print("rxRate from getDataChannel $rxRate");
      print("txRate from getDataChannel $txRate");
      uploadRate(rxRate, appModel);
      downloadRate(txRate, appModel);
    }
  }

  uploadRate(var rxRate, AppModel appModel) {
    var upD = makeRate(rxRate);
    appModel.singleUpload = upD;
    //appModel.addDownloadUItem(upD);

    print("uprate from the data $upD");
  }

  downloadRate(var txRate, AppModel appModel) {
    var downD = makeRate(txRate);
    appModel.singleDownload = downD;

    // print("uprate from the data ${downloadUsage[MAX_NUMBER_POINT_HISTORY - 1]}");
  }

// callShiftForDownload(AppModel appModel){
//     for(var i=0;i< appModel.downloadSpeedDisplay.length;i++){
//       appModel.downloadSpeedDisplay[i] = appModel.downloadSpeedDisplay[1 + i];
//     }
// }

// callShiftForUpload(AppModel appModel){
//     for(var i = 0;i< appModel.uploadSpeedDisplay.length;i++){
//     appModel.uploadSpeedDisplay[i] = appModel.uploadSpeedDisplay[1 + i];
//   }

// }

  String makeRate(dynamic originalValue, {bool forceMBUnit = false}) {
    var unit_idx = 0;
    List units = ['B', 'KB', 'MB'];
    if (forceMBUnit) {
      return "${(originalValue / (1024 * 1024)).toStringAsFixed(2)} ${units[2]}/s";
    }
    var value = originalValue;
    while (value > 1024.0 && unit_idx + 1 < units.length) {
      value /= 1024.0;
      unit_idx += 1;
    }
    var unitSpeed = " ${units[unit_idx]}ps";
    return value.toStringAsFixed(1) + unitSpeed;
  }
}
