import 'dart:async';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/node_provider.dart';
import 'package:belnet_mobile/src/app_list_provider.dart';
import 'package:belnet_mobile/src/map/vpn_home_panel.dart';
import 'package:belnet_mobile/src/map/vpn_home_style.dart';
import 'package:belnet_mobile/src/map/vpn_world_map.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/providers/chartData_controller.dart';
import 'package:belnet_mobile/src/providers/introstate_provider.dart';
import 'package:belnet_mobile/src/providers/ip_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/providers/log_provider.dart';
import 'package:belnet_mobile/src/providers/vpn_provider.dart';
import 'package:belnet_mobile/src/screens/add_exitnode_screen.dart';
import 'package:belnet_mobile/src/utils/show_toast.dart';
import 'package:belnet_mobile/src/vpn_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
class HomeScreen extends StatefulWidget {
  //final VoidCallback onNavigateToExitNodes;
final Function(bool) onNavigateToExitNodes;
  const HomeScreen({super.key, required this.onNavigateToExitNodes});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>  with TickerProviderStateMixin, WidgetsBindingObserver{


  // late AnimationController _bounceButtonController;
  // late Animation<Offset> _bounceButtonAnimationOffset;
   // late VideoPlayerController _videoLoaderController;
 TextEditingController exitNodeController = TextEditingController();
 TextEditingController dnsController = TextEditingController();

  StreamSubscription<bool>? _isConnectedEventSubscription;

late ChartDataController chartController;




 bool isInitialAddExitNode = false;

 /// Bottom panel expanded (stats + protection); the map shrinks and hides
 /// its status block, as in the design.
 bool _panelExpanded = false;


 String swapText = 'Swap to exit.bdx';



@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);



// /// For the power button
// _bounceButtonController = AnimationController(
//   duration: const Duration(milliseconds: 450),
//   vsync: this);

//  _bounceButtonAnimationOffset = Tween<Offset>(
//   begin: const Offset(0.0, -0.2),
//   end: Offset.zero
//  ).animate(CurvedAnimation(
//   parent: _bounceButtonController,
//   curve:Curves.bounceInOut ));
//  _bounceButtonController.forward(); // Start bounce animation

  final loaderVideoProvider = Provider.of<LoaderVideoProvider>(context,listen: false);
    final vpnConnectionProvider = Provider.of<VpnConnectionProvider>(context,listen: false);
    final logProvider = Provider.of<LogProvider>(context,listen: false);
    final appModel = Provider.of<AppModel>(context,listen: false);
    final ipProvider = Provider.of<IpProvider>(context,listen: false);
     final introStateProvider = Provider.of<IntroStateProvider>(context,listen: false);
    final nodeProvider = Provider.of<NodeProvider>(context,listen: false);

//checkCanAddExitNodeEnabled();
  _isConnectedEventSubscription = BelnetLib.isConnectedEventStream.listen(
    (bool isConnected) {
      if (!mounted) return;
      setState(() {
        print('Belnet is running NAVVVV $isConnected');
        // Update UI
        //checkVPN(isConnected);
      });
    },
  );

  // BelnetLib.disconnectEventChannel.receiveBroadcastStream().listen((event){
  //  if (event == "notification_disconnect") {
  //     debugPrint("User clicked disconnect from notification");
  //     // Handle your logic
  //     try{
  //      vpnConnectionProvider.cancelDelay();
  //     Provider.of<TunnelHealthProvider>(context, listen: false).stop();
  //     loaderVideoProvider.setLoading(false);
  //     loaderVideoProvider.setConnectionStatus(ConnectionStatus.DISCONNECTED);
  //     logProvider.addLog('Belnet Daemon stopped');
  //     logProvider.addLog('Belnet disconnected');
  //     stopNotification();
  //     resetIfCustomExitnode(ipProvider,introStateProvider,nodeProvider);
  //     //AwesomeNotifications().cancelAll();
  //     }catch(e){

  //     }
  //         }
  // },
  //  onError: (error) {
  //   debugPrint("Notification disconnect stream error: $error");
  // }
  
  // );

   chartController = ChartDataController();
    chartController.init(appModel);
}




  resetIfCustomExitnode(IpProvider ipProvider,IntroStateProvider introProvider,NodeProvider nodeProvider){
  if(introProvider.isCustomNode){
    introProvider.setIsCustomNode(false);
    ipProvider.resetCustomValue();
     nodeProvider.selectNode(3,'exit.bdx','France');
    showMessage('Switching to default Exit Node');
  


}
}

  String stringBeforeSpace(String value) {
    String str = value;
    str = value.split(' ').first;
    setState(() {});
    return str;
  }

  String stringAfterSpace(String value) {
    String str = value;
    str = value.split(' ').last;
    setState(() {});
    return str;
  }










checkCanAddExitNodeEnabled()async{
 SharedPreferences prefs = await SharedPreferences.getInstance();
 setState(() {
   isInitialAddExitNode = prefs.getBool('isinitialaddnode') ?? true;
 });
}

@override
  void dispose() {
    _isConnectedEventSubscription?.cancel();
       WidgetsBinding.instance.removeObserver(this);
       //_bounceButtonController.dispose();
   // _videoLoaderController.dispose();
       chartController.dispose();
    super.dispose();
  }


String capitalizeFirstLetter(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}



  @override
  Widget build(BuildContext context) {
    final appSelectingProvider = Provider.of<AppSelectingProvider>(context);
    final appModel = Provider.of<AppModel>(context);
    final style = VpnHomeStyle.of(appModel.darkTheme);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: style.headerBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('1.4.1',
                  style: style.body(size: 12, color: style.labelColor)),
            ),
          ),
          leadingWidth: 100,
          centerTitle: true,
          title: appModel.darkTheme
              ? SvgPicture.asset('assets/images/dark_theme/home_logo_dark_theme.svg', height: 19)
              : SvgPicture.asset('assets/images/light_theme/home_logo_white_theme.svg', height: 19),
          actions: [
            // Theme toggle in a small square, as designed.
            Tooltip(
              message: appModel.darkTheme ? 'Light theme' : 'Dark theme',
              child: Material(
                color: style.themeToggleFill,
                borderRadius: BorderRadius.circular(3),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    try {
                      appModel.darkTheme = !appModel.darkTheme;
                    } catch (e) {}
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: appModel.darkTheme
                        ? SvgPicture.asset('assets/images/dark_theme/light_Theme.svg', height: 18, width: 18)
                        : SvgPicture.asset('assets/images/light_theme/dark_theme.svg', height: 18, width: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            // Map: own country while unprotected, rotating globe with the
            // real onion route while connecting, exit country when
            // protected. The status block lives inside the map.
            Expanded(
              child: VpnWorldMap(
                darkTheme: appModel.darkTheme,
                bottomInset: 70,
                compact: _panelExpanded,
              ),
            ),
            // Panel: its own block under the map (design).
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: style.panelBackground,
                border: Border(top: BorderSide(color: style.panelTopLine)),
              ),
              child: VpnHomePanel(
              dark: appModel.darkTheme,
              onConnectToggle: () => toggleBelnet(context, appSelectingProvider,
                  dns: '9.9.9.9', isCustomeExitNode: false),
              onAddExitNode: () => showCustomDialog(context, appModel),
              onChangeNode: () => widget.onNavigateToExitNodes(true),
              onOpenExitNodes: () => widget.onNavigateToExitNodes(false),
              expanded: _panelExpanded,
              onExpandedChanged: (v) => setState(() => _panelExpanded = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

void showCustomDialog(BuildContext context,AppModel appModel) {

   showDialog(
                                  useSafeArea: false,
                                  // barrierColor: Colors.white.withOpacity(0.09),
                                  context: context,
                                  builder: (BuildContext dcontext) => SafeArea(
                                    child: Padding(
                                          padding: const EdgeInsets.all(0.0),
                                          child: appModel.darkTheme ?
                                          GlassContainer.clearGlass(
                                           color: Colors.black.withOpacity(0.3), //s.white.withOpacity(0.8),
                                           blur: 15.0,
                                           borderColor: Colors.transparent,
                                            child: Dialog(
                                             // scrollable: true,
                                             insetPadding: EdgeInsets.all(18),
                                              backgroundColor: Colors.transparent,
                                              //contentPadding: EdgeInsets.all(0.0),
                                              child:CustomAddExitNodeDialog() //containerWidget(dcontext,mHeight,appModel),
                                            ),
                                          )
                                          :
                                    
                                           Container(
                                           color: Color(0xffFFFFFF).withOpacity(0.9),//(0xffFFFFFF).withOpacity(0.9), //s.white.withOpacity(0.8),
                                          // blur: 6.0,
                                          //borderColor: Colors.transparent,
                                            child: Dialog(
                                             // scrollable: true,
                                             insetPadding: EdgeInsets.all(18),
                                              backgroundColor: Colors.transparent,
                                              //contentPadding: EdgeInsets.all(0.0),
                                              child:CustomAddExitNodeDialog() //containerWidget(dcontext,mHeight,appModel),
                                            ),
                                          ),
                                          //  GlassContainer.clearGlass(
                                          //  color: Color(0x80FFFFFF),//(0xffFFFFFF).withOpacity(0.9), //s.white.withOpacity(0.8),
                                          // // blur: 6.0,
                                          // borderColor: Colors.transparent,
                                          //   child: Dialog(
                                          //    // scrollable: true,
                                          //    insetPadding: EdgeInsets.all(18),
                                          //     backgroundColor: Colors.transparent,
                                          //     //contentPadding: EdgeInsets.all(0.0),
                                          //     child:CustomAddExitNodeDialog() //containerWidget(dcontext,mHeight,appModel),
                                          //   ),
                                          // ),
                                        ),
                                  ));

}


}

