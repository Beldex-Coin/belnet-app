

import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/node_provider.dart';
import 'package:belnet_mobile/src/app_list_provider.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/providers/chartData_controller.dart';
import 'package:belnet_mobile/src/providers/introstate_provider.dart';
import 'package:belnet_mobile/src/providers/ip_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/providers/log_provider.dart';
import 'package:belnet_mobile/src/providers/speed_chart_provider.dart';
import 'package:belnet_mobile/src/providers/vpn_provider.dart';
import 'package:belnet_mobile/src/settings.dart';
import 'package:belnet_mobile/src/utils/show_toast.dart';
import 'package:belnet_mobile/src/widget/modelResponse.dart';
import 'package:belnet_mobile/src/widget/sampChart.dart';
import 'package:flutter/widgets.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


enum ConnectionStatus{
  CONNECTED,
  CONNECTING,
  DISCONNECTED
}

late ChartDataController chartDataController;

Future<void> toggleBelnet(BuildContext context,AppSelectingProvider appSelectingProvider,{String? dns,isCustomeExitNode = false})async{

  final nodeProvider = Provider.of<NodeProvider>(context,listen: false);
  final loaderVideoProvider = Provider.of<LoaderVideoProvider>(context,listen: false);
  final vpnConnectionProvider = Provider.of<VpnConnectionProvider>(context,listen: false);
  final speedChartProvider = Provider.of<SpeedChartProvider>(context,listen: false);
  final ipProvider = Provider.of<IpProvider>(context,listen: false);
  final logProvider = Provider.of<LogProvider>(context,listen: false);
  final appModel = Provider.of<AppModel>(context,listen:false);
  final introStateProvider = Provider.of<IntroStateProvider>(context,listen: false);
  resetStatevalue(introStateProvider);
 
 if (BelnetLib.isConnected) {
    await _disconnectFromBelnet(vpnConnectionProvider,loaderVideoProvider,speedChartProvider,ipProvider,logProvider,introStateProvider,nodeProvider);
  } else {
    await _connectToBelnet(context,appSelectingProvider,nodeProvider,loaderVideoProvider,vpnConnectionProvider,speedChartProvider,ipProvider,logProvider,appModel,introStateProvider ,dns:dns,isCustomeExitNode: isCustomeExitNode);
  }









//   if(BelnetLib.isConnected){
//      print('TOGGLE isConnected 111--${BelnetLib.isConnected} ');
//      await BelnetLib.disconnectFromBelnet();
//      vpnConnectionProvider.cancelDelay();
//       loaderVideoProvider.setConnectionStatus(ConnectionStatus.DISCONNECTED);
//      //context.loaderOverlay.hide();
//      loaderVideoProvider.setLoading(false);
       

//   }else{
//     print('TOGGLE isConnected 222 --${BelnetLib.isConnected} ');
//      final result = await BelnetLib.prepareConnection();
//     if(!result){
//          loaderVideoProvider.setLoading(false);
//           loaderVideoProvider.setConnectionStatus(ConnectionStatus.DISCONNECTED);
//       return ;
//     }
//     print('TOGGLE isConnected 333--${BelnetLib.isConnected} ');
//    // context.loaderOverlay.show();
//     loaderVideoProvider.setLoading(true);
//     loaderVideoProvider.showLoader();
//     print('TOGGLE isConnected 4444--${BelnetLib.isConnected} ${context.loaderOverlay.visible}');
//     loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTING);
//     _saveSettings(nodeProvider);



// print('ISCONNECT IS CONNNECTED AR NOT --> ${BelnetLib.isConnected} -------${appSelectingProvider.isSPEnabled} ${appSelectingProvider.selectedApps.toList()}');


//     bool con = await BelnetLib.connectToBelnet(
//       appSelectingProvider.isSPEnabled ?
//      appSelectingProvider.selectedApps.toList() : [],
//     exitNode: Settings.getInstance()!.exitNode!,
//     upstreamDNS: dns != null && dns.isNotEmpty ? dns : "9.9.9.9",
//   );
// print('TOGGLE isConnected 555--${BelnetLib.isConnected} ');
//   vpnConnectionProvider.startConnectionDelay((){
//   //context.loaderOverlay.hide();
//   loaderVideoProvider.hideLoader();
//      loaderVideoProvider.setLoading(false);
//          loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTED);
//      print('ISCONNECT IS CONNNECTED AR NOT --> ${BelnetLib.isConnected}');
//   });
//   // Future.delayed(Duration(seconds: 19),(){
     
//   // });
//   }
    
  


}



resetStatevalue(IntroStateProvider introStateProvider)async{
  introStateProvider.setMyExitValue(false);
  introStateProvider.setFlagvalue(false);
//Future.delayed(Duration(milliseconds: ))
  //  chartController = ChartDataController();
  //   chartController.init(appModel);

 }

Future<void> _saveSettings(NodeProvider nodeProvider ,{String? exitvalue, String? dns}) async {
  final settings = Settings.getInstance()!;
  settings.exitNode = nodeProvider.selectedExitNodeName!.trim().toString();
  settings.upstreamDNS = dns ?? '9.9.9.9';
  // final myVal = selectedValue!.trim().toString();
  // logController.addDataTolist(" Exit node = $myVal",
  //     "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");

  // final preferences = await SharedPreferences.getInstance();
  // await preferences.setString('hintValue', myVal);
  // hintValue = preferences.getString('hintValue');

  // logController.addDataTolist(dns == null
  //     ? " default Upstream DNS = 9.9.9.9"
  //     : " DNS = $dns", "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");

  // settings.upstreamDNS = dns ?? '9.9.9.9';

  // final eIcon = selectedConIcon!.trim().toString();
  // await preferences.setString('hintCountryicon', eIcon);
  // hintCountryIcon = preferences.getString('hintCountryicon');
  // logController.addDataTolist(" Connected to $myVal",
  //     "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
}


Future<void> _disconnectFromBelnet(VpnConnectionProvider vpnConnectionProvider,LoaderVideoProvider loaderVideoProvider,SpeedChartProvider speedChartProvider,IpProvider ipProvider,LogProvider logProvider,IntroStateProvider introProvider,NodeProvider nodeProvider) async {
  
 // setState(() => loading = true);
  bool disConnectValue = await BelnetLib.disconnectFromBelnet();
 // appModel.connecting_belnet = false;

  if (disConnectValue) {
    vpnConnectionProvider.cancelDelay();
      loaderVideoProvider.setConnectionStatus(ConnectionStatus.DISCONNECTED);
     //context.loaderOverlay.hide();
     print('THE LOADER VALUE IS D11----> ${loaderVideoProvider.isLoading}');
     //loaderVideoProvider.setLoading(false);
     print('THE LOADER VALUE IS D22 ----> ${loaderVideoProvider.isLoading}');
  }
//stopNotification();
  // Future.delayed(const Duration(seconds: 2), () {
  // //  setState(() => loading = false);
  // });
  
}

setForCustomExitnode(IpProvider ipProvider,IntroStateProvider introProvider,NodeProvider nodeProvider)async{
  final prefs = await SharedPreferences.getInstance();
  if(introProvider.isCustomNode){
    introProvider.setIsCustomNode(false);
    ipProvider.resetCustomValue();
     nodeProvider.selectNode(3,'exit.bdx','France');
    showMessage('Switching to default Exit Node');
  }


}



// Future<void> _saveCustomSettings({String? exitvalue, String? dns}) async {
//   final settings = Settings.getInstance()!;
//   settings.exitNode = exitvalue;
//   settings.upstreamDNS = dns ?? '9.9.9.9';
// }











Future<void> _connectToBelnet(BuildContext context,AppSelectingProvider appSelectingProvider,NodeProvider nodeProvider,LoaderVideoProvider loaderVideoProvider,VpnConnectionProvider vpnConnectionProvider,SpeedChartProvider speedChartProvider,IpProvider ipProvider,LogProvider logProvider,AppModel appModel,IntroStateProvider introStateProvider ,{String? dns,bool isCustomeExitNode = false}) async {

 if(introStateProvider.grantPermissionCount == 1){ // To avoid multiple vpn permission dialogs 

    introStateProvider.increaseGrantPermissionCountByOne();

if(isCustomeExitNode){
 await _handleCustomExitNode(introStateProvider);
}

introStateProvider.showButtonAfterOk();

  await _saveSettings(nodeProvider);
  
print('THE LOADER VALUE IS 1----> ${loaderVideoProvider.isLoading}');
  final result = await BelnetLib.prepareConnection();
  if (!result) {
      print('THE LOADER VALUE IS 666----> ${loaderVideoProvider.isLoading}');
     //loaderVideoProvider.setLoading(false);
          //loaderVideoProvider.setConnectionStatus(ConnectionStatus.DISCONNECTED);
   // setState(() => loading = false);
    return;
  }
   print('THE LOADER VALUE IS 22----> ${loaderVideoProvider.isLoading}');
    loaderVideoProvider.setLoading(true);
    //loaderVideoProvider.showLoader();
  // if (await BelnetLib.isPrepared) {
  //   appModel.connecting_belnet = true;
  // }
  print('THE LOADER VALUE IS 333----> ${loaderVideoProvider.isLoading}');
 print('CustomExitnode checking start ${Settings.getInstance()!.exitNode!}');
  bool con = await BelnetLib.connectToBelnet(
       appSelectingProvider.isSPEnabled && appSelectingProvider.selectedApps.toList().isNotEmpty ?
      [...appSelectingProvider.selectedApps.toList(),'io.beldex.belnet'] : [],
    exitNode: Settings.getInstance()!.exitNode!,
    upstreamDNS: dns != null && dns.isNotEmpty ? dns : "9.9.9.9",
  );
print('CustomExitnode checking end');
  if (con) {
    vpnConnectionProvider.startConnectionDelay((){
  //context.loaderOverlay.hide();
 // loaderVideoProvider.hideLoader();
     loaderVideoProvider.setLoading(false);
         loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTED);
     print('ISCONNECT IS CONNNECTED AR NOT --> ${BelnetLib.isConnected}');
     print('THE LOADER VALUE IS 4444----> ${loaderVideoProvider.isLoading}');
  });
  } else {
    //setState(() => loading = false);
  }


 }

}

bool myExit = false;
bool f = false;
 



 Future<void> _handleCustomExitNode(IntroStateProvider introStateProvider, {String? exitvalue}) async {
  

 // if (exitvalue != null && exitvalue.isNotEmpty) {
    // setState(() {
    //   selectedValue = exitvalue;
    //   selectedConIcon = "";
    // });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!introStateProvider.myExit && !introStateProvider.flagvalue) {
        getDataFromDaemon(introStateProvider);
      } else {
        timer.cancel();
      }
      // if (!myExit && !f) {
      //   getDataFromDaemon();
      // } else {
      //   timer.cancel();
      // }
    });












 // }
 //if(canValidateExit){
  //  if (myExit) {
  //   setState(() {
  //     f = true;
  //     mystr = "exitnode is valid";
  //    // loading = false;
  //   });
  // } else {
  //   setState(() {
  //     mystr = "exitnode is invalid";
  //   });
  //   print("myExitvalue is $mystr");
  //   await BelnetLib.disconnectFromBelnet();
  //   logController.addDataTolist(
  //     "$selectedValue is Invalid Exit Node",
  //     "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
  //   );
  //   setState(() {
  //     selectedValue =
  //         'exit.bdx';
  //     selectedConIcon =
  //         "https://belnet-exitnode.s3.ap-south-1.amazonaws.com/countryflag/icons8-france.png";
  //   });
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       backgroundColor: appModel.darkTheme
  //           ? Colors.black.withOpacity(0.50)
  //           : Colors.white,
  //       behavior: SnackBarBehavior.floating,
  //       width: MediaQuery.of(context).size.height * 2.5 / 3,
  //       content: Text(
  //         "Exit Node is Invalid!.switching to default Exit Node",
  //         style: TextStyle(
  //             color: appModel.darkTheme ? Colors.white : Colors.black),
  //         textAlign: TextAlign.center,
  //       )));
  // }
 //}
  
}

Future<void> _checkingExitnodeAfterDelay(NodeProvider nodeProvider,LogProvider logProvider,VpnConnectionProvider vpnConnectionProvider,LoaderVideoProvider loaderVideoProvider,SpeedChartProvider speedChartProvider,IpProvider ipProvider,AppModel appModel,IntroStateProvider introStateProvider) async {
 //if(canValidateExit){
   if (introStateProvider.myExit) {
   // setState(() {
      f = true;
      introStateProvider.setFlagvalue(true);
       showNotification(appModel);
      ipProvider.startMonitoring();
     loaderVideoProvider.setLoading(false);
         loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTED);
               logProvider.addLog('Exit node set by Daemon: Connected to ${nodeProvider.selectedExitNodeName}');

     // mystr = "exitnode is valid";
     // loading = false;
   // });
  } else {
    // setState(() {
    //   mystr = "exitnode is invalid";
    // });
   // print("myExitvalue is $mystr");
    bool disConnectValue = await BelnetLib.disconnectFromBelnet();
 // appModel.connecting_belnet = false;

  if (disConnectValue) {
    vpnConnectionProvider.cancelDelay();
   // ipProvider.stopIPMonitoring();
   // speedChartProvider.stopMonitoring();
     stopNotification();
       loaderVideoProvider.setLoading(false);
      loaderVideoProvider.setConnectionStatus(ConnectionStatus.DISCONNECTED);
      logProvider.addLog('Exit Node is Invalid!.switching to default Exit Node');
       introStateProvider.setIsCustomNode(false);
      //logProvider.addLog('Belnet disconnected');
     //context.loaderOverlay.hide();
     print('THE LOADER VALUE IS D11----> ${loaderVideoProvider.isLoading}');
     //loaderVideoProvider.setLoading(false);
     print('THE LOADER VALUE IS D22 ----> ${loaderVideoProvider.isLoading}');
  }
   // _disconnectFromBelnet(vpnConnectionProvider, loaderVideoProvider, speedChartProvider, ipProvider, logProvider);
   // await BelnetLib.disconnectFromBelnet();
    //timer1?.cancel();
     // AwesomeNotifications().cancel(10);
    // logController.addDataTolist(
    //   "$selectedValue is Invalid Exit Node",
    //   "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
    // );


   nodeProvider.selectNode(3,'exit.bdx','France');


    // setState(() {
    //   selectedValue =
    //       'exit.bdx';
    //   selectedConIcon =
    //       "https://belnet-exitnode.s3.ap-south-1.amazonaws.com/countryflag/icons8-france.png";
    // });

    showMessage('Exit Node is Invalid!.switching to default Exit Node');
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //     backgroundColor: appModel.darkTheme
    //         ? Colors.black.withOpacity(0.50)
    //         : Colors.white,
    //     behavior: SnackBarBehavior.floating,
    //     width: MediaQuery.of(context).size.height * 2.5 / 3,
    //     content: Text(
    //       "Exit Node is Invalid!.switching to default Exit Node",
    //       style: TextStyle(
    //           color: appModel.darkTheme ? Colors.white : Colors.black),
    //       textAlign: TextAlign.center,
    //     )));
  }
 //}
  
}
getDataFromDaemon(IntroStateProvider introStateProvider) async {
    var fromDaemon = await BelnetLib.getSpeedStatus;
    if (fromDaemon != null) {
      var data1 = Welcome.fromJson(fromDaemon);
      print("isConnected before ${data1.isConnected}");
      introStateProvider.setMyExitValue(data1.isConnected);
      myExit = data1.isConnected;

      print("isConnected after the myExit $myExit");
      //setState(() {});
    }
  }
  




//// Notification 
///
void showNotification(AppModel appModel) {
  print('Comes inside show Notification function');
 
 showMyNotifaction(appModel);
 timer1 = Timer.periodic(Duration(seconds: 1),(timer){
    updateNotification(appModel);
 });
 
 
 
 
 
 
  //Timer.periodic(Duration(milliseconds: 100), (timer) {
   // if (BelnetLib.isConnected) {
     // _updateNotification(appModel);
    // } else {
    //   //timer.cancel();
    //   _dismissNotification();
    // }
 // });
}

Timer? timer1;

stopNotification()async{
  Future.delayed(const Duration(milliseconds: 200),(){
    timer1?.cancel();

  AwesomeNotifications().cancel(10).then((value) {
    print('Notification Stopped');
  });
  });
 
}





void showMyNotifaction(AppModel appModel){
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 10, 
      channelKey: 'belnets_channel',
    title: "belnet dVPN",
    body:
        '↑ ${stringBeforeSpace(appModel.singleUpload)}${stringAfterSpace(appModel.singleUpload)} ↓ ${stringBeforeSpace(appModel.singleDownload)}${stringAfterSpace(appModel.singleDownload)}',
    locked: true,
    autoDismissible: false,
    category: NotificationCategory.Service,)
      );
}

void updateNotification(AppModel appModel){
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 10, 
        channelKey: 'belnets_channel',
    title: "Belnet dVPN",
    body:
        '↑ ${stringBeforeSpace(appModel.singleUpload)}${stringAfterSpace(appModel.singleUpload)} ↓ ${stringBeforeSpace(appModel.singleDownload)}${stringAfterSpace(appModel.singleDownload)}',
    locked: true,
    autoDismissible: false,
    category: NotificationCategory.Service,)
      );
}


String stringBeforeSpace(String value) {
   // String str = value;
   String str = value.split(' ').first;
    //setState(() {});
    return str;
  }

  String stringAfterSpace(String value) {
   // String str = value;
   String str = value.split(' ').last;
   // setState(() {});
    return str;
  }










