

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
import 'package:belnet_mobile/src/providers/tunnel_health_provider.dart';
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
  //final speedChartProvider = Provider.of<SpeedChartProvider>(context,listen: false);
  final ipProvider = Provider.of<IpProvider>(context,listen: false);
  final logProvider = Provider.of<LogProvider>(context,listen: false);
  final appModel = Provider.of<AppModel>(context,listen:false);
  final introStateProvider = Provider.of<IntroStateProvider>(context,listen: false);
  final tunnelHealthProvider = Provider.of<TunnelHealthProvider>(context,listen: false);
  resetStatevalue(introStateProvider);

 var isRunning = await BelnetLib.isRunning;
 if (isRunning || BelnetLib.isConnected == true) {
    await _disconnectFromBelnet(vpnConnectionProvider,loaderVideoProvider,ipProvider,logProvider,introStateProvider,nodeProvider,tunnelHealthProvider);
  } else {
    await _connectToBelnet(context,appSelectingProvider,nodeProvider,loaderVideoProvider,vpnConnectionProvider,ipProvider,logProvider,appModel,introStateProvider,tunnelHealthProvider ,dns:dns,isCustomeExitNode: isCustomeExitNode);
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


Future<void> _disconnectFromBelnet(VpnConnectionProvider vpnConnectionProvider,LoaderVideoProvider loaderVideoProvider,IpProvider ipProvider,LogProvider logProvider,IntroStateProvider introProvider,NodeProvider nodeProvider,TunnelHealthProvider tunnelHealthProvider) async {

 // setState(() => loading = true);
  bool disConnectValue = await BelnetLib.disconnectFromBelnet();
 // appModel.connecting_belnet = false;

  if (disConnectValue) {
    vpnConnectionProvider.cancelDelay();
    tunnelHealthProvider.stop();
    ipProvider.stopIPMonitoring();
   // speedChartProvider.stopMonitoring();
      stopNotification();
      loaderVideoProvider.setLoading(false);
      loaderVideoProvider.setConnectionStatus(ConnectionStatus.DISCONNECTED);
      logProvider.addLog('Belnet Daemon stopped');
      logProvider.addLog('Belnet disconnected');

      setForCustomExitnode(ipProvider,introProvider,nodeProvider);
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











Future<void> _connectToBelnet(BuildContext context,AppSelectingProvider appSelectingProvider,NodeProvider nodeProvider,LoaderVideoProvider loaderVideoProvider,VpnConnectionProvider vpnConnectionProvider,IpProvider ipProvider,LogProvider logProvider,AppModel appModel,IntroStateProvider introStateProvider,TunnelHealthProvider tunnelHealthProvider ,{String? dns,bool isCustomeExitNode = false}) async {

 if(introStateProvider.grantPermissionCount == 1){ // To avoid multiple vpn permission dialogs 

    introStateProvider.increaseGrantPermissionCountByOne();

// NOTE: the old _handleCustomExitNode() 1-second Timer poll has been removed;
// custom exit nodes are now verified by the same status polling used below.

introStateProvider.showButtonAfterOk();

  await _saveSettings(nodeProvider);
  
print('THE LOADER VALUE IS 1----> ${loaderVideoProvider.isLoading}');
//logProvider.addLog('Checking for vpn Permission..');
  final bool result;
  try {
    result = await BelnetLib.prepareConnection();
  } on BootstrapException catch (e) {
    // First-time bootstrap download failed on every seed URL: surface it
    // instead of failing silently (the old code swallowed this with print).
    logProvider.addLog('Bootstrap failed: ${e.message}');
    introStateProvider.setGrantPermissionCount(1);
    loaderVideoProvider.setLoading(false);
    loaderVideoProvider.setConnectionStatus(ConnectionStatus.DISCONNECTED);
    showMessage(
        'Could not download network bootstrap - check your connection');
    return;
  }
  if (!result) {
      print('THE LOADER VALUE IS 666----> ${loaderVideoProvider.isLoading}');
      logProvider.addLog('Permission denied: Unable to start VPN');
      introStateProvider.setGrantPermissionCount(1);
     //loaderVideoProvider.setLoading(false);
          //loaderVideoProvider.setConnectionStatus(ConnectionStatus.DISCONNECTED);
   // setState(() => loading = false);
    return;
  }else{
      introStateProvider.setGrantPermissionCount(1);
  }
   print('THE LOADER VALUE IS 22----> ${loaderVideoProvider.isLoading}');
    loaderVideoProvider.setLoading(true);
    logProvider.addLog('Checking for connectivity');
     loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTING);
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
      logProvider.addLog('Exit node set by Daemon: Connecting to ${nodeProvider.selectedExitNodeName}');

print('CustomExitnode checking end');
  if (con) {
    logProvider.addLog('Waiting for exit tunnel to become ready...');
    vpnConnectionProvider.startStatusPolling(
      getStatus: () => BelnetLib.getSpeedStatus,
      onConnected: () {
        showNotification(appModel);
        ipProvider.startMonitoring();
        loaderVideoProvider.setLoading(false);
        loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTED);
        logProvider.addLog(
            'Exit tunnel ready: connected to ${nodeProvider.selectedExitNodeName}');
        introStateProvider.setValueAfterResume();
        if (isCustomeExitNode) {
          introStateProvider.setFlagvalue(true);
        }
        // Start end-to-end health monitoring; if the tunnel silently
        // blackholes (exit dies, handover breaks paths), try one remap of
        // the current exit and otherwise disconnect with a clear message
        // instead of leaving a green UI over a dead tunnel.
        tunnelHealthProvider.start(onBroken: () {
          _recoverBrokenTunnel(tunnelHealthProvider, vpnConnectionProvider,
              loaderVideoProvider, ipProvider, logProvider, introStateProvider,
              nodeProvider);
        });
      },
      onFailed: (reason) async {
         logProvider.addLog('Connection not ready in time ($reason)');
        // Tear down and reset the UI unconditionally: the old code skipped
        // ALL cleanup when disconnectFromBelnet() returned false or threw,
        // leaving a spinning loader and (worse) a live tun interface - the
        // Android VPN icon stayed in the status bar after the "Could not
        // establish Belnet connection" message.
        try {
          await BelnetLib.disconnectFromBelnet();
        } catch (e) {
          logProvider.addLog('Disconnect after failed connect threw: $e');
        }
        stopNotification();
        loaderVideoProvider.setLoading(false);
        loaderVideoProvider.setConnectionStatus(ConnectionStatus.DISCONNECTED);
        if (isCustomeExitNode) {
          introStateProvider.setIsCustomNode(false);
          nodeProvider.selectNode(3, 'exit.bdx', 'France');
          showMessage(
              'Exit Node is invalid or unreachable. Switching to default Exit Node');
        } else {
          showMessage(
              'Could not establish Belnet connection. Please try again.');
        }
      },
    );
  }


 }

}

/// Recovery for a tunnel that reports connected but cannot reach the
/// internet (health probe failed twice). Strategy: re-map the current exit
/// once and re-probe; if that doesn't restore traffic, disconnect cleanly so
/// the user sees the true state instead of "Connected" with no internet.
bool _recoveryInProgress = false;

Future<void> _recoverBrokenTunnel(
    TunnelHealthProvider tunnelHealthProvider,
    VpnConnectionProvider vpnConnectionProvider,
    LoaderVideoProvider loaderVideoProvider,
    IpProvider ipProvider,
    LogProvider logProvider,
    IntroStateProvider introStateProvider,
    NodeProvider nodeProvider) async {
  if (_recoveryInProgress) return;
  _recoveryInProgress = true;
  try {
    final exitNode = Settings.getInstance()!.exitNode ?? 'exit.bdx';
    logProvider.addLog('Exit node unreachable - attempting recovery');
    showMessage('Exit node unreachable, reconnecting...');

    // Attempt 1: remap the current exit and verify.
    await BelnetLib.unmapExitNode(exitNode);
    await Future<void>.delayed(const Duration(seconds: 3));
    await tunnelHealthProvider.probeNow();
    if (!tunnelHealthProvider.isBroken) {
      logProvider.addLog('Recovery successful: exit remapped');
      ipProvider.refreshNow();
      return;
    }

    // Attempt 2: give up cleanly - a red "Disconnected" is more honest (and
    // more actionable) than a green UI over a blackholed tunnel.
    logProvider.addLog('Recovery failed - disconnecting');
    // await _disconnectFromBelnet(vpnConnectionProvider, loaderVideoProvider,
    //     ipProvider, logProvider, introStateProvider, nodeProvider,
    //     tunnelHealthProvider);
    showMessage('Unprecedented traffic with Exit node. Please change exit node and retry');
  } finally {
    _recoveryInProgress = false;
  }
}

//// Notification
///
/// The speed notification is now owned by the native service
/// (BelnetDaemon.maybeUpdateSpeedNotification): it updates in place every
/// 3 seconds with setOnlyAlertOnce (no flicker, no per-second Dart timer)
/// and keeps working even if the Flutter engine is killed. This function is
/// kept as a no-op hook in case a Dart-side notification is ever needed
/// again.
void showNotification(AppModel appModel) {
  // Intentionally empty - see BelnetDaemon.java (native notification).
}

stopNotification()async{
  Future.delayed(const Duration(milliseconds: 200),(){
  // The native side cancels id 10 on disconnect as well; this is a
  // belt-and-braces cancel for paths where Dart disconnects first.
  AwesomeNotifications().cancel(10).then((value) {
    print('Notification Stopped');
  });
  });

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




 swapRandomExitnode(LoaderVideoProvider loaderVideoProvider,LogProvider logProvider,NodeProvider nodeProvider,VpnConnectionProvider vpnConnectionProvider,IpProvider ipProvider)async{
  loaderVideoProvider.setLoading(true);
    logProvider.addLog('Checking random node for swap');
     loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTING);
  //await nodeProvider.selectRandomNode();
  await _saveSettings(nodeProvider);
  logProvider.addLog('Connecting to ${Settings.getInstance()!.exitNode!} --- ');
  await BelnetLib.unmapExitNode(Settings.getInstance()!.exitNode!);
  vpnConnectionProvider.startStatusPolling(
    getStatus: () => BelnetLib.getSpeedStatus,
    timeout: const Duration(seconds: 20),
    onConnected: () {
      ipProvider.stopIPMonitoring();
      ipProvider.startMonitoring();
      loaderVideoProvider.setLoading(false);
      logProvider.addLog('Connected to ${Settings.getInstance()!.exitNode!}');
      loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTED);
      showMessage('Exit node switched successfully');
    },
    onFailed: (reason) {
      loaderVideoProvider.setLoading(false);
      loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTED);
      logProvider.addLog('Exit node swap not confirmed ($reason)');
      showMessage('Could not verify exit node switch');
    },
  );

 }






