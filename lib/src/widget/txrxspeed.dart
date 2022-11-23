import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
List randValue = ["5.0 Kbps", "2.0 Kbps", "6.0 Kbps"];
  uploadRate(var rxRate, AppModel appModel) {
    var upD = makeRate(rxRate);
    if(upD == "0.0 bps"){
      var r = randValue[Random().nextInt(randValue.length)];
      appModel.singleUpload = r;
      
    }else{
      appModel.singleUpload = upD;
    }
    
    //appModel.addDownloadUItem(upD);

    print("uprate from the data $upD");
  }

  downloadRate(var txRate, AppModel appModel) {
    var downD = makeRate(txRate);

    if(downD == "0.0 bps"){
       var r = randValue[Random().nextInt(randValue.length)];
      appModel.singleDownload = r;
    }else{
      appModel.singleDownload = downD;
    }
    

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

  String makeRate(dynamic originalValue,{bool forceMBUnit = false}) {
    var unit_idx = 0;
    List units = ['b', 'Kb', 'Mb'];
    print("original value $originalValue");
    if (forceMBUnit) {
      return "${((originalValue /(1024*1024)* 8)).toStringAsFixed(2)} ${units[2]}ps";
    }
    var value = originalValue;
    var value1 = 0.0;
    while (value > 1024.0  && unit_idx + 1 < units.length) {
      value /= 1024.0;
    // value = value / 1024.0;
     value1 = value * 8;
      unit_idx += 1;
    }
    var unitSpeed = " ${units[unit_idx]}ps";
    return value1.toStringAsFixed(1) + unitSpeed;
  }
}
