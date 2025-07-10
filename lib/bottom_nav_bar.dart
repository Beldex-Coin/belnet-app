
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/node_provider.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/providers/internet_checking_provider.dart';
import 'package:belnet_mobile/src/providers/introstate_provider.dart';
import 'package:belnet_mobile/src/providers/ip_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/providers/log_provider.dart';
import 'package:belnet_mobile/src/providers/speed_chart_provider.dart';
import 'package:belnet_mobile/src/providers/vpn_provider.dart';
import 'package:belnet_mobile/src/screens/analytics_screen.dart';
import 'package:belnet_mobile/src/screens/exit_node_screen.dart';
import 'package:belnet_mobile/src/screens/home_screen.dart';
import 'package:belnet_mobile/src/screens/settings_screen.dart';
import 'package:belnet_mobile/src/vpn_controller.dart';
import 'package:belnet_mobile/src/widget/nointernet_connection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import 'package:video_player/video_player.dart';

class MainBottomNavbar extends StatefulWidget {
  const MainBottomNavbar({super.key});

  @override
  State<MainBottomNavbar> createState() => _MainBottomNavbarState();
}

class _MainBottomNavbarState extends State<MainBottomNavbar> with WidgetsBindingObserver{
 int _selectedIndex = 0;

  final List<Widget> _screens = [];
StreamSubscription<bool>? _isConnectedEventSubscription;
bool isBelConnect = false;


@override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
   
    final loaderVideoProvider = Provider.of<LoaderVideoProvider>(context,listen: false);
    final nodeProvider = Provider.of<NodeProvider>(context,listen: false);
    final logProvider = Provider.of<LogProvider>(context,listen: false);
    final ipProvider = Provider.of<IpProvider>(context,listen: false);
    final introStateProvider = Provider.of<IntroStateProvider>(context,listen: false);
     // final vpnConnectionProvider = Provider.of<VpnConnectionProvider>(context,listen: false);
      
   _isConnectedEventSubscription = BelnetLib.isConnectedEventStream
        .listen((bool isConnected) => setState(() {
          isBelConnect = isConnected;
        }));
       
        checkNode(nodeProvider,loaderVideoProvider,logProvider,ipProvider,introStateProvider);
  }


checkNode(NodeProvider nodeProvider,LoaderVideoProvider loaderVideoProvider,LogProvider logProvider,IpProvider ipProvider,IntroStateProvider introProvider)async{
  //print('inside the bottom nav bar ${nodeProvider.nodeData.length}');
  try{
var value = await BelnetLib.isRunning;
  if(value){
     // print('inside the bottom nav bar if statement');

      loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTED);
       logProvider.addLog('Exit node set by Daemon: Connected to ${nodeProvider.selectedExitNodeName}');
      // nodeProvider.selectRandomNode();
  }else{
    checkIsCustomNode(ipProvider,introProvider);
     nodeProvider.selectRandomNode();
      //print('inside the bottom nav bar else statement');
     //Future.delayed(Duration(milliseconds: 200),(){
        //  nodeProvider.selectRandomNode();

     //});
  }
    //print('inside the bottom nav bar --- ${BelnetLib.isConnected} ${await BelnetLib.isRunning}');

  }catch(e){
      print('inside the bottom nav bar $e');
  }
  
}


checkIsCustomNode(IpProvider ipProvider,IntroStateProvider introProvider)async{
   if(introProvider.isCustomNode){
    introProvider.setIsCustomNode(false);
    ipProvider.resetCustomValue();
   }
}


int index = 0;
isConnectedStatus(bool isConnected,LoaderVideoProvider loaderVideoProvider){
  setState(() {
    
  });
  if(isConnected && index == 0){

    loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTED);
    index = 1;
    return ;
  }else{
     index = 0;
  }
}




getStatus(LoaderVideoProvider loaderVideoProvider){
        //final loaderVideoProvider = Provider.of<LoaderVideoProvider>(context,listen: false);
                //print('I AM INTO 1112----->${BelnetLib.isConnected}----- ${loaderVideoProvider.conStatus}');
                setState(() {
                  
                });
     if(isBelConnect){
                     // print('I AM INTO 1112----->$isBelConnect----- ${loaderVideoProvider.conStatus}');
      loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTED);
     }
   }


Future<int?> getAndroidSdkInt() async {
  if (Platform.isAndroid) {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }
  return null;
}





@override
  void didChangeAppLifecycleState(AppLifecycleState state)async {
  try{

     // Safely use the provider with `context.read<T>()`
    if (!mounted) return;
    final loaderVideoProvider = context.read<LoaderVideoProvider>();
    //final appModel = context.read<AppModel>();
    final  introStateProvider = context.read<IntroStateProvider>();
    // final vpnConnectionProvider = context.read<VpnConnectionProvider>();
    // final speedChartProvider = context.read<SpeedChartProvider>();
    //final
    if(state == AppLifecycleState.paused){
      print('Notification stopped in paused state');
      stopNotification();
    }
   if (state == AppLifecycleState.detached) {
              stopNotification();

    if(introStateProvider.isCustomNode){
      if(loaderVideoProvider.conStatus == ConnectionStatus.CONNECTING){
       // disconnectFromBelnet(vpnConnectionProvider, loaderVideoProvider, speedChartProvider, ipProvider, logProvider, introStateProvider, nodeProvider)
        exit(0);
      }
    }else if(loaderVideoProvider.conStatus == ConnectionStatus.DISCONNECTED){
      exit(0);
    }else{
      stopNotification();
    }
     print('Notification stopped in detached state');
        //  stopNotification();
    }
    if(state == AppLifecycleState.resumed){
      // if(loaderVideoProvider.conStatus == ConnectionStatus.CONNECTING){
      //               print('VIDEO IS NOT INITIALIZED 1');
      //     if(!loaderVideoProvider.isInitialized){
      //       print('VIDEO IS NOT INITIALIZED  22');
      //      loaderVideoProvider.initialize(appModel.darkTheme ? 'assets/images/dark_theme/Loading_v1_slow.webm' : 'assets/images/light_theme/loading_white_theme.webm');
      //     }
      // }///////////// it was hidden prev
      // else{
         final sdkInt = await getAndroidSdkInt();
      if (sdkInt != null && sdkInt >= 34) {
        // Android 14 (API 34) and 15+ detected while resuming
        print("App resumed on Android SDK $sdkInt");

           var conStatus = await BelnetLib.isRunning;
      if(conStatus){
        //loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTED);
      }else{
        if(introStateProvider.isFirstResume){
          loaderVideoProvider.setLoading(false);
        loaderVideoProvider.setConnectionStatus(ConnectionStatus.DISCONNECTED);
         print('Notification stopped in resumed1 state');
        stopNotification();
        }
        
       //await AwesomeNotifications().cancelAll();
      }
      }
      
      } ////////////////////
         print('Notification stopped in resumed2 state');
    // stopNotification();
    //}
  }catch(e){
    print('$e');
}
   
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }




Widget _getScreen(int index) {
  switch (index) {
    case 0:
      return HomeScreen(
        onNavigateToExitNodes: () {
          Provider.of<LoaderVideoProvider>(context, listen: false).setIndex(1);
        },
      );
    case 1:
      return ExitNodesScreen();
    case 2:
      return ChartScreen();
    case 3:
      return SettingsScreen();
    default:
      return HomeScreen(onNavigateToExitNodes: () {});
  }
}







  @override
  void dispose() {
     WidgetsBinding.instance.removeObserver(this);
    _isConnectedEventSubscription!.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loaderProvider = Provider.of<LoaderVideoProvider>(context);
     final selectedIndex = loaderProvider.selectedIndex;
     final connectivityProvider = Provider.of<ConnectivityProvider>(context);
    //loaderProvider.initialize('assets/loader.webm');
    final appModel = Provider.of<AppModel>(context);
    return connectivityProvider.isConnected ? WillPopScope(
      onWillPop: () async {

    if (loaderProvider.isLoading) {
      // Block back navigation while loading
      return false;
    }
     if (selectedIndex != 0) {
          // Not on Home -> Go back to Home
          loaderProvider.setIndex(0);
          return false; // Prevent app from closing
        }
        stopNotification();
        return true; // Allow app to close if on Home tab
      },
      // child:
      //  LoaderOverlay(
      //   useDefaultLoading: false,
      //   overlayColor: Colors.black38.withOpacity(0.97),
      //   overlayWidgetBuilder: (progress) {
      //     return Center(
      //       child: Container(
      //         height: MediaQuery.of(context).size.height*1.8/3,
      //          width: double.infinity,              
      //          padding: EdgeInsets.all(20),
      //          decoration: BoxDecoration(
      //           borderRadius: BorderRadius.circular(15.0)
      //          ),
      //         child: Stack(
      //           children: [
      //             ClipRRect(
      //               borderRadius:BorderRadius.circular(15.0) ,
      //               child: VideoPlayer(loaderProvider.controller)),

      //              Column(
      //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //                children: [
      //                  Center(child: Padding(
      //                    padding: const EdgeInsets.only(top: 15.0),
      //                    child: Text('Connecting',style: TextStyle(fontSize: 16,fontFamily: 'Poppins',fontWeight: FontWeight.w700),),
      //                  )),
      //                 Center(
      //                   child: Column(
      //                     children: [
      //                       Text('Getting you to the Node..',style: TextStyle(color: Color(0xff41FF41),fontSize: 18,fontFamily: 'Poppins',fontWeight: FontWeight.w600),),
      //                       Text('This may take some time', style: TextStyle(color: Color(0xffACACAC),fontSize: 12,fontFamily: 'Poppins'),),
      //                       SizedBox(height: 15,)
      //                     ],
      //                   ),
      //                 )
      //                ],
      //              )
      //           ],
      //         )),
      //     );
      //   },
        child:
         SafeArea(
          top:false,
          bottom: true,
           child: UpgradeAlert(
            showIgnore: false,
        showLater: false,
            upgrader: Upgrader(
              //debugLogging: true
            ),
             child: Scaffold(
              extendBody: true, // lets nav bar float over body
              body: Stack(
                children: [
                  // Background image
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image:appModel.darkTheme ? AssetImage('assets/images/dark_theme/Dark_background.png') :AssetImage('assets/images/light_theme/White__theme_background_v1.png') , // <-- your image
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
             loaderProvider.conStatus == ConnectionStatus.CONNECTED ? Container(
                      child:appModel.darkTheme ? Lottie.asset('assets/images/dark_theme/Dots_v1(1).json',fit: BoxFit.cover) : Lottie.asset('assets/images/light_theme/Dots_wht_theme(2).json',fit: BoxFit.cover),
                    ): SizedBox(),
             
                  
                  loaderProvider.isLoading ? Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child:appModel.darkTheme ? Lottie.asset('assets/images/dark_theme/Loading_dark_theme.json',repeat: false,fit: BoxFit.cover //dark_theme/Loading_dark_with_text.json',repeat: false //Loading_dark.json',repeat: false 
                    ) : Lottie.asset('assets/images/light_theme/Loading_white_theme.json',repeat: false ,fit: BoxFit.cover//Loading_white_theme_with_text.json',repeat: false //Loading_white_theme_v1.json',repeat: false
                    ),
                   ):SizedBox.shrink(),
                  // // Active screen
                  // _screens[_selectedIndex],
                  // Inside your Stack:
                     AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: Offset(0.0, 0.1), // slightly from bottom
                end: Offset.zero,
              ).animate(animation);
                     
              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                     opacity: animation,
                     child: child,
                ),
              );
                     },
                     
              // transitionBuilder: (child, animation) {
              //   return FadeTransition(
              //     opacity: animation,
              //     child: child,
              //   );
              // },
              child:Padding(
                padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
                child: _getScreen(selectedIndex),
              ) // _screens[selectedIndex],
                     ),
                  // Positioned bottom nav bar
                  // Align(
                  //   alignment: Alignment.bottomCenter,
                  //   child:MediaQuery.of(context).viewInsets.bottom == 0 ? CustomBottomNavBar(
                  //     selectedIndex: selectedIndex,
                  //     onItemTapped:loaderProvider.setIndex //_onItemTapped,
                  //   ): SizedBox.shrink(),
                  // ),
                ],
              ),
              bottomNavigationBar: Align(
                    alignment: Alignment.bottomCenter,
                    child:MediaQuery.of(context).viewInsets.bottom == 0 ? CustomBottomNavBar(
                      selectedIndex: selectedIndex,
                      onItemTapped:loaderProvider.setIndex //_onItemTapped,
                    ): SizedBox.shrink(),),
                     ),
           ),
         ),
     // ),
    ) : NoInternetConnection();
  }


}


class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  CustomBottomNavBar({required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
       final appModel = Provider.of<AppModel>(context);

    return Padding(
      padding: EdgeInsets.only(right:9,left: 9), // little bottom space
      child:
       ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: 
          Container(
            padding: EdgeInsets.symmetric( vertical: 15),
             decoration: BoxDecoration(
    color: appModel.darkTheme ? Colors.white.withOpacity(0.05) : Color(0xffC0C0C0).withOpacity(0.2),
    borderRadius: BorderRadius.circular(12),
    //border: Border. //all(color: Color(0xff3A496266).withOpacity(0.1)),
  ),
           // color: Colors.black.withOpacity(0.3),
            //margin: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem('assets/images/dark_theme/home.svg', 0,activeColor: Color(0xff00DC00),appModel: appModel),
                _buildNavItem('assets/images/dark_theme/Nodes.svg', 1,activeColor: Color(0xff00DC00),appModel: appModel),
                _buildNavItem('assets/images/dark_theme/Analytics.svg', 2,activeColor: Color(0xff00DC00),appModel: appModel),
                _buildNavItem('assets/images/dark_theme/Settings.svg', 3,activeColor: Color(0xff00DC00),appModel: appModel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String icon, int index, {Color activeColor = Colors.white,AppModel? appModel}) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:isSelected ? appModel!.darkTheme ? Colors.white.withOpacity(0.12) 
          : Colors.white : appModel!.darkTheme ? Color(0xff3A4962).withOpacity(0.3) : Color(0xffA1A1A1).withOpacity(0.3), // Colors.grey.shade900.withOpacity(0.7),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10)
        ),
        child: SvgPicture.asset(icon, color: isSelected ? activeColor : appModel.darkTheme ? Colors.grey : Color(0xff4D4D4D),height: 20,)
        // Icon(
        //   icon,
        //   color: isSelected ? activeColor : Colors.grey,
        //   size: 28,
        // ),
      ),
    );
  }
}







