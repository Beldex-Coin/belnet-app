

import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/node_provider.dart';
import 'package:belnet_mobile/src/app_list_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/providers/vpn_provider.dart';
import 'package:belnet_mobile/src/settings.dart';
import 'package:flutter/widgets.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';


enum ConnectionStatus{
  CONNECTED,
  CONNECTING,
  DISCONNECTED
}



Future<void> toggleBelnet(BuildContext context,AppSelectingProvider appSelectingProvider,String? dns,)async{

  final nodeProvider = Provider.of<NodeProvider>(context,listen: false);
  final loaderVideoProvider = Provider.of<LoaderVideoProvider>(context,listen: false);
  final vpnConnectionProvider = Provider.of<VpnConnectionProvider>(context,listen: false);



 if (BelnetLib.isConnected) {
    await _disconnectFromBelnet(vpnConnectionProvider,loaderVideoProvider);
  } else {
    await _connectToBelnet(context,appSelectingProvider, dns,nodeProvider,loaderVideoProvider,vpnConnectionProvider);
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


Future<void> _disconnectFromBelnet(VpnConnectionProvider vpnConnectionProvider,LoaderVideoProvider loaderVideoProvider) async {
  
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

Future<void> _connectToBelnet(BuildContext context,AppSelectingProvider appSelectingProvider,String? dns,NodeProvider nodeProvider,LoaderVideoProvider loaderVideoProvider,VpnConnectionProvider vpnConnectionProvider) async {
 
  await _saveSettings(nodeProvider);;
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


 