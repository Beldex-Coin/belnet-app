import 'dart:async';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/country_code_list.dart';
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
import 'package:belnet_mobile/src/screens/add_exitnode_screen.dart';
import 'package:belnet_mobile/src/utils/show_toast.dart';
import 'package:belnet_mobile/src/vpn_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToExitNodes;

  const HomeScreen({super.key, required this.onNavigateToExitNodes});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>  with TickerProviderStateMixin, WidgetsBindingObserver{

late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  // late AnimationController _bounceButtonController;
  // late Animation<Offset> _bounceButtonAnimationOffset;
   // late VideoPlayerController _videoLoaderController;
 TextEditingController exitNodeController = TextEditingController();
 TextEditingController dnsController = TextEditingController();

  StreamSubscription<bool>? _isConnectedEventSubscription;

late ChartDataController chartController;




 bool isInitialAddExitNode = false;






@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);

  _controller = AnimationController(
    duration: const Duration(milliseconds: 400),// 600
    vsync: this,
  );

  _offsetAnimation = Tween<Offset>(
    begin: const Offset(0.0, -0.2),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.bounceIn,
  ));

  _controller.forward();


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

  BelnetLib.disconnectEventChannel.receiveBroadcastStream().listen((event){
   if (event == "notification_disconnect") {
      debugPrint("User clicked disconnect from notification");
      // Handle your logic
      try{
       vpnConnectionProvider.cancelDelay();
      loaderVideoProvider.setLoading(false);
      loaderVideoProvider.setConnectionStatus(ConnectionStatus.DISCONNECTED);
      logProvider.addLog('Belnet Daemon stopped');
      logProvider.addLog('Belnet disconnected');
      stopNotification();
      resetIfCustomExitnode(ipProvider,introStateProvider,nodeProvider);
      //AwesomeNotifications().cancelAll();
      }catch(e){

      }
          }
  },
   onError: (error) {
    debugPrint("Notification disconnect stream error: $error");
  }
  
  );

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








String displaySpeed(int data){
  double rate = (data * 8) / 1000000.0;
  return '${rate.toStringAsFixed(2)} Mb/s';
}


checkCanAddExitNodeEnabled()async{
 SharedPreferences prefs = await SharedPreferences.getInstance();
 setState(() {
   isInitialAddExitNode = prefs.getBool('isinitialaddnode') ?? true;
 });
}

@override
  void dispose() {
    _controller.dispose();
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
    final nodeProvider = Provider.of<NodeProvider>(context);
    final appSelectingProvider = Provider.of<AppSelectingProvider>(context);
    final loaderVideoProvider = Provider.of<LoaderVideoProvider>(context);
  //  final speedChartProvider = Provider.of<SpeedChartProvider>(context);
    final appModel = Provider.of<AppModel>(context);
    final mHeight = MediaQuery.of(context).size.height;
        final ipProvider = Provider.of<IpProvider>(context);
    final loaderProvider = Provider.of<LoaderVideoProvider>(context);
        final introProvider = Provider.of<IntroStateProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(bottom:20.0),
      child: Scaffold(
         backgroundColor: Colors.transparent,
        //resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: Padding(
              padding: const EdgeInsets.symmetric(vertical:  10.0,horizontal: 15),
              child: Text('1.3.0',style: TextStyle(fontFamily: 'Poppins',color: appModel.darkTheme ? Colors.white : Color(0xff4D4D4D)),),
            ),
          leadingWidth: 100,
          actions: [
         GestureDetector(
          onTap: (){
            try{
              appModel.darkTheme = !appModel.darkTheme;
            }catch(e){
      
            }
                      // loaderVideoProvider.initialize(appModel.darkTheme ? 'assets/images/dark_theme/Loading_v1_slow.webm' : 'assets/images/light_theme/loading_white_theme.webm');
      
             },
           child: Container(
              padding: EdgeInsets.all(7),
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color:appModel.darkTheme? Colors.grey.withOpacity(0.1):Color(0xffA1A1A1).withOpacity(0.2),
               borderRadius: BorderRadius.circular(10)
              ),
              child:appModel.darkTheme? SvgPicture.asset('assets/images/dark_theme/light_Theme.svg'):SvgPicture.asset('assets/images/light_theme/dark_theme.svg') ),
         )
          ],
          ),
         
        body: SizedBox(
          //height: MediaQuery.of(context).size.height*2.3/3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
                           
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30.0),
                    child: SvgPicture.asset('assets/images/dark_theme/Belnet_logo_new.svg',height:MediaQuery.of(context).size.height*0.20/3),
                  ),
                  
                  // GestureDetector(
                  //   onTap:()=>toggleBelnet(context,appSelectingProvider,dns: '9.9.9.9',isCustomeExitNode: false),
                  //   child: GlassContainer.clearGlass(
                  //     height: 180,
                  //   width: 180,
                  //   shape: BoxShape.circle,
                  //   borderColor: Colors.transparent,
                  //   blur: 10,
                  //   color: Colors.white.withOpacity(0.05),
                      
                  //     child:loaderVideoProvider.conStatus == ConnectionStatus.CONNECTED //|| BelnetLib.isConnected
                  //      ? appModel.darkTheme ? SvgPicture.asset('assets/images/dark_theme/disconnect.svg') : SvgPicture.asset('assets/images/light_theme/disconnect.svg') : appModel.darkTheme ? SvgPicture.asset('assets/images/dark_theme/connect.svg') : SvgPicture.asset('assets/images/light_theme/connect.svg')),
                  // ),
                  // SizedBox(height: 20),
                  !loaderProvider.isLoading ? GestureDetector(
                    onTap:()=>toggleBelnet(context,appSelectingProvider,dns: '9.9.9.9',isCustomeExitNode: false),
                    child: GlassContainer.clearGlass(
                       height: MediaQuery.of(context).size.height*0.70/3, // 180,
                    width:MediaQuery.of(context).size.height*0.70/3,// 180,
                    shape: BoxShape.circle,
                    borderColor: Colors.transparent,
                    blur: 10,
                    color: Colors.white.withOpacity(0.05),
                      
                      child:loaderVideoProvider.conStatus == ConnectionStatus.CONNECTED //|| BelnetLib.isConnected
                       ? 
                       //appModel.darkTheme ? SvgPicture.asset('assets/images/dark_theme/disconnect.svg') : SvgPicture.asset('assets/images/light_theme/disconnect.svg') : appModel.darkTheme ? SvgPicture.asset('assets/images/dark_theme/connect.svg') : SvgPicture.asset('assets/images/light_theme/connect.svg')),
                             appModel.darkTheme ?
                              SvgPicture.asset('assets/images/dark_theme/disconnect1_dark.svg') 
                              : SvgPicture.asset('assets/images/light_theme/disconnect_wht_theme.svg') 
                              : appModel.darkTheme 
                              ? SvgPicture.asset('assets/images/dark_theme/Connnect1_dark.svg',) 
                              : SvgPicture.asset('assets/images/light_theme/connect_wht_theme.svg')
                              ),
                                 
                  ):SizedBox.shrink(),
                  SizedBox(height: 15),
      
      loaderVideoProvider.conStatus == ConnectionStatus.CONNECTED ? appModel.darkTheme ? Image.asset('assets/images/dark_theme/connected.png',height: 40,) :
                  Image.asset('assets/images/light_theme/connected_wht_theme.png',height: 40,) : SizedBox.shrink(),
      
      
      
         !loaderProvider.isLoading ?
                  GestureDetector(
                    onTap:loaderVideoProvider.conStatus == ConnectionStatus.CONNECTED || !introProvider.showButton ? null :  ()=>  showCustomDialog(context,appModel),
                  
                    child: 
                    appModel.darkTheme ? 
       // loaderVideoProvider.conStatus == ConnectionStatus.CONNECTED ||
         !introProvider.showButton ?
              SvgPicture.asset('assets/images/dark_theme/add_exit_node_disabled.svg',height: 55,)
            : loaderVideoProvider.conStatus == ConnectionStatus.DISCONNECTED ? SvgPicture.asset('assets/images/dark_theme/add_exit_node_dark.svg',height: 55,) : SizedBox.shrink()
           :  
            !introProvider.showButton ? SvgPicture.asset('assets/images/light_theme/add_exit_node_wht_theme_disabled.svg',height: 55,) : loaderVideoProvider.conStatus == ConnectionStatus.DISCONNECTED ? SvgPicture.asset('assets/images/light_theme/add_exit_node_wht theme.svg',height: 55,) : SizedBox.shrink(),
      // GlassContainer.clearGlass(
      //             width: 164,
      //              height: 50,
      //             //decoration: BoxDecoration(
      //               color: Color(0xff80808A).withOpacity(0.01),
      //               borderRadius: BorderRadius.circular(40),
      //                  borderColor:  Color(0xff4D4D4D).withOpacity(0.5),
      //               borderWidth: 2, 
      //             child: 
      //             Row(
      //                     mainAxisAlignment: MainAxisAlignment.center,
      //                     children: [
      
      //                       SvgPicture.asset('assets/images/dark_theme/add_exit_node.svg',color: Color(0xff4D4D4D).withOpacity(0.9)), // Color(0xFF00B400)),
      //                     Padding(
      //                       padding: const EdgeInsets.only(left:8.0),
      //                       child: Text('Add Exit Node',style: TextStyle(color: Color(0xff4D4D4D).withOpacity(0.9)
      //                       ,fontFamily: 'Poppins',fontWeight: FontWeight.w600,fontSize: 12),),
      //                     )
                        
      //                     ],
      //                   ),
      //           ):
      //                   Stack(
      //                           alignment: Alignment.center,
      //                           children: [
      //                             // Outer container for the gradient border
      //                             Container(
      //                               width: 164,
      //                               height: 50,
      //                               decoration: BoxDecoration(
      //                                 borderRadius: BorderRadius.circular(44),
      //                                 border: Border.all(color: Color(0xfff00DC00),width: 0.3),
      //                                 gradient: LinearGradient(
      //                   colors: [
      //                     Color(0xFF464663), // Gradient start color
      //                     Color(0xFF00DC00).withOpacity(0.6), // Gradient end color
      //                   ],
      //                   begin: Alignment.topLeft,
      //                   end: Alignment.bottomRight,
      //                                 ),
      //                               ),
      //                             ),
      //                             // Inner container for the background and inner shadow
      //                             ClipRRect(
      //                               borderRadius: BorderRadius.circular(44),
      //                               child: Container(
      //                                 width: 162, // Slightly smaller to account for the 1px border
      //                                 height: 48,
      //                                 decoration: BoxDecoration(
      //                   color: Color(0xff3A496266), // Colors.transparent, //(0xFF3A4962).withOpacity(0.4), // Background color with 40% opacity
      //                   borderRadius: BorderRadius.circular(44),
      //                   boxShadow: [
      //                     BoxShadow(
      //                       //color: Color(0xFF0094FF), // Inner shadow color
      //                       offset: Offset(-3, 3), // X: -2, Y: 2
      //                       blurRadius: 16, // Blur: 12
      //                       spreadRadius: -2, // Negative spread to create inner shadow
      //                     ),
      //                   ],
      //                                 ),
      //                                 child: Row(
      //                   mainAxisAlignment: MainAxisAlignment.center,
      //                   children: [
      //                     SvgPicture.asset('assets/images/dark_theme/add_exit_node.svg',color: Color(0xFF00DC00)),
      //                     Padding(
      //                       padding: const EdgeInsets.only(left:8.0),
      //                       child: Text('Add Exit Node',style: TextStyle(color: Color(0xFF00DC00),fontFamily: 'Poppins',fontWeight: FontWeight.w600,fontSize: 12),),
      //                     )
      //                   ],
      //                                 ),
      //                               ),
      //                             ),
      //                           ],
      //                               )
            //                     :
            //                     Container(
            //   width: 164,
            //    height: 50,
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(20),
            //     border: Border.all(
            //        color:loaderVideoProvider.conStatus == ConnectionStatus.CONNECTED || !introProvider.showButton ?  Color(0xff4D4D4D).withOpacity(0.3) :Color(0xFF00B400),
            //        //  selectedType == 'Beldex Official' && type == 'Beldex Official'
            //       //         ? Color(0xFF00DC00)
            //       //         : selectedType == 'Contributor exit node' && type == 'Contributor exit node'
            //       //             ? Color(0xFF0094FF)
            //       //             : Colors.transparent,
            //       //Color(0xFF0094FF)
                
            //     width: 1),
            //     boxShadow: 
            //      [
            //                 BoxShadow(
            //         color: Color(0xFF00B400).withOpacity(0.1) ,// Colors.black12,,
                   
            //       ),
            //       BoxShadow(
            //         color: Colors.white,
            //         spreadRadius: -01.0,
            //         blurRadius: 23.5,
            //         offset: Offset(-3.0, 4.5),
            //       )
                          
            //     ]
            //   ),
            //   child: 
            //   Row(
            //           mainAxisAlignment: MainAxisAlignment.center,
            //           children: [
      
            //             SvgPicture.asset('assets/images/dark_theme/add_exit_node.svg',color:loaderVideoProvider.conStatus == ConnectionStatus.CONNECTED || !introProvider.showButton ? Color(0xff4D4D4D).withOpacity(0.3) : Color(0xFF00B400)), // Color(0xFF00B400)),
            //           Padding(
            //             padding: const EdgeInsets.only(left:8.0),
            //             child: Text('Add Exit Node',style: TextStyle(color:loaderVideoProvider.conStatus == ConnectionStatus.CONNECTED || !introProvider.showButton ? Color(0xff4D4D4D).withOpacity(0.3) : Color(0xFF00B400)
            //             ,fontFamily: 'Poppins',fontWeight: FontWeight.w600,fontSize: 12),),
            //           )
                        
            //           ],
            //         ),
            // ),
                  ):SizedBox.shrink(),  
                ],
              ),
          Column(
                children: [
                  SlideTransition(
                    position: _offsetAnimation,
                    child: GestureDetector(
                      onTap:loaderVideoProvider.conStatus == ConnectionStatus.DISCONNECTED ? widget.onNavigateToExitNodes : null,
                      child: GlassContainer.clearGlass(
                          height: MediaQuery.of(context).size.height*0.37/3,
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(horizontal: 10,vertical: 5
                          ),
                         // decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color:appModel.darkTheme ? Color(0xff707070).withOpacity(0.07) //s.white.withOpacity(0.02) 
                            : Colors.white.withOpacity(0.6), // Color(0xFF00B400).withOpacity(0.02),
                            borderColor: //Border.all(color: 
                            appModel.darkTheme ? Color(0xff00DC00) :Color(0xFF00B400),
                            borderWidth:appModel.darkTheme ? 0.8 : 0.3,//),
                  //           boxShadow:appModel.darkTheme ? [] :[
                  //                  BoxShadow(
                  //   color: Color(0xFF00B400).withOpacity(0.1) ,// Colors.black12,,
                   
                  // ),
                  // BoxShadow(
                  //   color: Colors.white.withOpacity(0.8),
                  //   spreadRadius: -01.0,
                  //   blurRadius: 23.5,
                  //   offset: Offset(-3.0, 4.5),
                  // )
                  //           ],
                         // ),
                          padding: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                         child: Row(
                          children: [
                              Container(
                                height: 45,width: 45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                 color: appModel.darkTheme ? Color(0xff707070).withOpacity(0.3) //s.white.withOpacity(0.1)
                                  : Color(0xffBEBEBE).withOpacity(0.3)
                                ),
                                padding: EdgeInsets.all(10),
                                child:introProvider.isCustomNode ? Image.asset('${countryCodeToFlag[ipProvider.customCountryCode?.toUpperCase()]}',
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.broken_image,color: appModel.darkTheme ? Colors.white : Colors.black);
                                  },
                                  ) : Image.asset('assets/images/flags/${nodeProvider.selectedExitNodeCountry ?? 'France'}.png',
                                   errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.broken_image,color: appModel.darkTheme ? Colors.white : Colors.black);
                                  },
                                  ),
                              ),
                              SizedBox(width: 8,),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                   introProvider.isCustomNode ? Text('${ipProvider.customNodeCountry ?? 'Fetching country name...'}', style: TextStyle(fontFamily: 'Poppins',fontSize: 12,color:appModel.darkTheme ? Color(0xffACACAC) : Colors.black)) : Text('${nodeProvider.selectedExitNodeCountry ?? 'France'}', style: TextStyle(fontFamily: 'Poppins',fontSize: 12,color:appModel.darkTheme ? Color(0xffACACAC) : Colors.black)),
                                    SizedBox(height: 5,),
                                    Text('${nodeProvider.selectedExitNodeName ?? 'exit.bdx'}', maxLines: 2, style: TextStyle(overflow: TextOverflow.ellipsis,fontFamily: 'Poppins',fontSize: 12),)
                                  ],
                                ),
                              ),
                              SizedBox(width: 10,),
                             loaderVideoProvider.conStatus == ConnectionStatus.DISCONNECTED ? Container(
                                height: 35,width: 35,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:appModel.darkTheme ? Color(0xff707070).withOpacity(0.07) : Color(0xffBEBEBE).withOpacity(0.3)
                                ),
                                padding: EdgeInsets.all(9),
                                child: SvgPicture.asset('assets/images/dark_theme/arrow_settings.svg',height: 20,color:appModel.darkTheme ? Colors.white : Colors.black,))
                                : SizedBox.shrink()
                          ],
                         ),
                        ),
                    ),
                  ),
                  SizedBox(height: 5,),
                   
                    Padding(
                  padding: const EdgeInsets.symmetric(horizontal:8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GlassContainer(
                          height:55,// MediaQuery.of(context).size.height * 0.10,
                          borderRadius: BorderRadius.circular(10),
                          color:appModel.darkTheme ? Color(0xffACACAC).withOpacity(0.05):Colors.white.withOpacity(0.6) , //s.black12,
                          blur: 5.0,
                          borderColor: Colors.transparent, //(0xffACACAC),
                          borderWidth: 0.5,
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            
                            children: [
                              Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(color:appModel.darkTheme ? Colors.transparent : Color(0xffA1A1AF),width: 0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: 
                                                CircleAvatar(
                                                  backgroundColor:appModel.darkTheme ? Colors.white.withOpacity(0.1) : Color(0xffBEBEBE).withOpacity(0.3),
                                                  radius: 13,
                                                  child: SvgPicture.asset('assets/images/dark_theme/connection.svg',height: 13,width: 13, color: appModel.darkTheme ? Colors.white : Colors.black,) //Icon(Icons.download, color: Colors.white, size: 20),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   
                                              // CircleAvatar(
                                              //   backgroundColor: Colors.white.withOpacity(0.1),
                                              //   radius: 20,
                                              //   child: SvgPicture.asset('assets/images/dark_theme/connection.svg',color: appModel.darkTheme ? Colors.white : Colors.black,) //Icon(Icons.link, color: Colors.white, size: 20),
                                              // ),
                                              SizedBox(height: 8),
                                              Text("Status", style: TextStyle(color:appModel.darkTheme ? Colors.white70 : Color(0xff4D4D4D), fontSize: 10)),
                                              SizedBox(height: 4),
                                              Text(capitalizeFirstLetter(loaderVideoProvider.conStatus.name), style: TextStyle(color:loaderVideoProvider.conStatus == ConnectionStatus.CONNECTED ?  Color(0xff00DC00) : loaderVideoProvider.conStatus == ConnectionStatus.CONNECTING ? Colors.blue : appModel.darkTheme ? Colors.white : Colors.black, fontSize: 9, fontWeight: FontWeight.bold,overflow: TextOverflow.ellipsis),maxLines: 1,),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: GlassContainer(
                          height:55, //MediaQuery.of(context).size.height * 0.10,
                          borderRadius: BorderRadius.circular(10),
                          color:appModel.darkTheme ? Color(0xffACACAC).withOpacity(0.05):Colors.white.withOpacity(0.6), 
                          blur: 5.0,
                          borderColor: Colors.transparent, //(0xffACACAC),
                          borderWidth: 0.5,
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(color:appModel.darkTheme ? Colors.transparent : Color(0xffA1A1AF),width: 0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: 
                                                CircleAvatar(
                                                  backgroundColor:appModel.darkTheme ? Colors.white.withOpacity(0.1) : Color(0xffBEBEBE).withOpacity(0.3),
                                                  radius: 13,
                                                  child: SvgPicture.asset('assets/images/dark_theme/Download.svg',height: 13,width: 13,) //Icon(Icons.download, color: Colors.white, size: 20),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                              
                                              SizedBox(height: 8),
                                              Text("Download", style: TextStyle(color: appModel.darkTheme ? Colors.white70 : Color(0xff4D4D4D), fontSize: 10)),
                                              SizedBox(height: 4),
                                              Text(loaderVideoProvider.conStatus == ConnectionStatus.CONNECTED ? '${stringBeforeSpace(appModel.singleDownload)} ${stringAfterSpace(appModel.singleDownload)}' : '0.0 Mb/s', //displaySpeed(speedChartProvider.download), //"40.5 Mb/s",
                                               style: TextStyle(color:appModel.darkTheme ? Colors.white : Colors.black, fontSize: 10,// fontWeight: FontWeight.bold
                                               )),
                                               SizedBox(height: 2,)
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: GlassContainer(
                          height: 55, // MediaQuery.of(context).size.height * 0.10,
                          borderRadius: BorderRadius.circular(10),
                          color: appModel.darkTheme ? Color(0xffACACAC).withOpacity(0.05):Colors.white.withOpacity(0.6) ,
                          blur: 5.0,
                          borderColor: Colors.transparent, //(0xffACACAC),
                          borderWidth: 0.5,
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
      
                            children: [
                              Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(color:appModel.darkTheme ? Colors.transparent : Color(0xffA1A1AF),width: 0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: 
                                                CircleAvatar(
                                                  backgroundColor:appModel.darkTheme ? Colors.white.withOpacity(0.1) : Color(0xffBEBEBE).withOpacity(0.3),
                                                  radius: 13,
                                                  child: SvgPicture.asset('assets/images/dark_theme/upload.svg',height: 13,width: 13,) //Icon(Icons.download, color: Colors.white, size: 20),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                             // Spacer(),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                      
                                              // CircleAvatar(
                                              //   backgroundColor: Colors.white.withOpacity(0.1),
                                              //   radius: 20,
                                              //   child: SvgPicture.asset('assets/images/dark_theme/upload.svg') //Icon(Icons.upload, color: Colors.white, size: 20),
                                              // ),
                                              SizedBox(height: 8),
                                              Text("Upload", style: TextStyle(color: appModel.darkTheme ? Colors.white70 : Color(0xff4D4D4D), fontSize: 10)),
                                              SizedBox(height: 4),
                                              Text(loaderVideoProvider.conStatus == ConnectionStatus.CONNECTED ? '${stringBeforeSpace(appModel.singleUpload)} ${stringAfterSpace(appModel.singleUpload)}': '0.0 Mb/s', //displaySpeed(speedChartProvider.upload), //"12.5 Mb/s", 
                                              style: TextStyle(color:appModel.darkTheme ? Colors.white : Colors.black, fontSize: 10, //fontWeight: FontWeight.bold
                                              )),
                                              SizedBox(height: 2,)
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ],
              ),
          ],  
          ),
        )
        
        //Center(child: Text('Working', style: TextStyle(fontSize: 24))),
      ),
    );
  }

void showCustomDialog(BuildContext context,AppModel appModel) {

   showDialog(
                                  useSafeArea: false,
                                  // barrierColor: Colors.white.withOpacity(0.09),
                                  context: context,
                                  builder: (BuildContext dcontext) => Padding(
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
                                        : GlassContainer.clearGlass(
                                         color: Color(0x80FFFFFF),//(0xffFFFFFF).withOpacity(0.9), //s.white.withOpacity(0.8),
                                        // blur: 6.0,
                                        borderColor: Colors.transparent,
                                          child: Dialog(
                                           // scrollable: true,
                                           insetPadding: EdgeInsets.all(18),
                                            backgroundColor: Colors.transparent,
                                            //contentPadding: EdgeInsets.all(0.0),
                                            child:CustomAddExitNodeDialog() //containerWidget(dcontext,mHeight,appModel),
                                          ),
                                        ),
                                      ));

}


}

