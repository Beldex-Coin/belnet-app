
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/node_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/providers/log_provider.dart';
import 'package:belnet_mobile/src/providers/vpn_provider.dart';
import 'package:belnet_mobile/src/screens/analytics_screen.dart';
import 'package:belnet_mobile/src/screens/exit_node_screen.dart';
import 'package:belnet_mobile/src/screens/home_screen.dart';
import 'package:belnet_mobile/src/screens/settings_screen.dart';
import 'package:belnet_mobile/src/vpn_controller.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
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
    // _screens.addAll(
    //   [
    //  HomeScreen(
    //   onNavigateToExitNodes: () {
    //     Provider.of<LoaderVideoProvider>(context, listen: false).setIndex(1);
    //     // setState(() {
    //     //   _selectedIndex = 1; //  switches to ExitNodesScreen
    //     // });
    //   },
    //  ),
    // ExitNodesScreen(),
    // ChartScreen(),
    // SettingsScreen(),
    //   ]
    // );
    final loaderVideoProvider = Provider.of<LoaderVideoProvider>(context,listen: false);
    final nodeProvider = Provider.of<NodeProvider>(context,listen: false);
    final logProvider = Provider.of<LogProvider>(context,listen: false);
     // final vpnConnectionProvider = Provider.of<VpnConnectionProvider>(context,listen: false);
      
   _isConnectedEventSubscription = BelnetLib.isConnectedEventStream
        .listen((bool isConnected) => setState(() {
          print('Belnet is running NAVVVV $isConnected');
                          print('I AM INTO 111----->$isConnected}----- ${loaderVideoProvider.conStatus}');
          isBelConnect = isConnected;
          //isConnectedStatus(isConnected,loaderVideoProvider);
          //loaderVideoProvider.setbelnetIsConnected(isConnected);
          //vpnStatus(context,isConnected,loaderVideoProvider,vpnConnectionProvider);
         // showMyNotification(context,isConnected);
        }));
       
        checkNode(nodeProvider,loaderVideoProvider,logProvider);
        // Future.delayed(Duration(milliseconds: 150),(){
        //           getStatus(loaderVideoProvider);
         
        // });
  }


checkNode(NodeProvider nodeProvider,LoaderVideoProvider loaderVideoProvider,LogProvider logProvider)async{
  print('inside the bottom nav bar ${nodeProvider.nodeData.length}');
  try{
var value = await BelnetLib.isRunning;
  if(value){
      print('inside the bottom nav bar if statement');

      loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTED);
       logProvider.addLog('Exit node set by Daemon: Connected to ${nodeProvider.selectedExitNodeName}');
      // nodeProvider.selectRandomNode();
  }else{
      print('inside the bottom nav bar else statement');
     //Future.delayed(Duration(milliseconds: 200),(){
        //  nodeProvider.selectRandomNode();

     //});
  }
    print('inside the bottom nav bar --- ${BelnetLib.isConnected} ${await BelnetLib.isRunning}');

  }catch(e){
      print('inside the bottom nav bar $e');
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
                print('I AM INTO 1112----->${BelnetLib.isConnected}----- ${loaderVideoProvider.conStatus}');
                setState(() {
                  
                });
     if(isBelConnect){
                      print('I AM INTO 1112----->$isBelConnect----- ${loaderVideoProvider.conStatus}');
      loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTED);
     }
   }






int count = 0;
 void vpnStatus(BuildContext context,bool isConnected,LoaderVideoProvider loaderVideoProvider, VpnConnectionProvider vpnConnectionProvider)async{

   bool val = await BelnetLib.isRunning;
            print('Connecting12344 val $val -- $count');

   setState(() {
     
   });
   if(isConnected == false){
   try{
    
   // AwesomeNotifications().cancel(10);
   }catch(e){
   }
    
   }
   if (loaderVideoProvider.isLoading == true) {
        //print('belnet is running $val');
         print('Connecting1 val $val -- $count');
        // Future.delayed(Duration(milliseconds: 600), () {
        if (val == true) {
          // print('belnet is disconnected111');
          count = 1;
        }
        if (count == 1) {
          print('Connecting 2 val $val -- $count');
          if (val == false) {
            print('Connecting 3 val $val -- $count');
           await BelnetLib.disconnectFromBelnet();
           setState(() {
             
           });
           
           count = 0;
           vpnConnectionProvider.cancelDelay();
          // context.loaderOverlay.hide();
           //loaderVideoProvider.setLoading(false);
               //loaderVideoProvider.setConnectionStatus(ConnectionStatus.DISCONNECTED);
          }
        }
        //});
      }
 }



 @override
  void didChangeAppLifecycleState(AppLifecycleState state)async {
  try{

     // Safely use the provider with `context.read<T>()`
    if (!mounted) return;

    final loaderVideoProvider = context.read<LoaderVideoProvider>();
   if (state == AppLifecycleState.detached) {
      //  exit(0);
      //timer1?.cancel();
      //AwesomeNotifications().cancel(10); // Cancel the notification with id 10
    }
    if(state == AppLifecycleState.resumed){
      // var conStatus = await BelnetLib.isRunning;
      // if(conStatus){
      //   loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTED);
      // }else{
      //   loaderVideoProvider.setLoading(false);
      //   loaderVideoProvider.setConnectionStatus(ConnectionStatus.DISCONNECTED);

      // }
    }
  }catch(e){
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
    //loaderProvider.initialize('assets/loader.webm');
    return WillPopScope(
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
         Scaffold(
          extendBody: true, // lets nav bar float over body
          body: Stack(
            children: [
              // Background image
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/dark_theme/BG.png'), // <-- your image
                    fit: BoxFit.cover,
                  ),
                ),
              ),
        
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
          child:_getScreen(selectedIndex) // _screens[selectedIndex],
        ),
              // Positioned bottom nav bar
              Align(
                alignment: Alignment.bottomCenter,
                child:MediaQuery.of(context).viewInsets.bottom == 0 ? CustomBottomNavBar(
                  selectedIndex: selectedIndex,
                  onItemTapped:loaderProvider.setIndex //_onItemTapped,
                ): SizedBox.shrink(),
              ),

// Consumer<LoaderVideoProvider>(
//   builder: (context, loaderProvider, _) {
//     if (!loaderProvider.isLoading) return SizedBox(child: Text('HELLO HELLO HELLOOOOOOOOOO'),);

//     return GlassContainer.clearGlass(
//       height: double.infinity,
//       width: double.infinity,
//       color: Colors.black.withOpacity(0.6),
//       borderColor: Colors.transparent,
//       child: Center(
//         child: Container(
//           height: MediaQuery.of(context).size.height * 1.8 / 3,
//           width: double.infinity,
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(15.0),
//           ),
//           child:Stack(
//                   children: [
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(15.0),
//                       child: VideoPlayer(
//                         loaderProvider.controller,
//                         key: ValueKey(DateTime.now().millisecondsSinceEpoch),
//                       ),
//                     ),
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Padding(
//                           padding: EdgeInsets.only(top: 15.0),
//                           child: Text(
//                             'Connecting',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontFamily: 'Poppins',
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                         Column(
//                           children: const [
//                             Text(
//                               'Getting you to the Node..',
//                               style: TextStyle(
//                                 color: Color(0xff41FF41),
//                                 fontSize: 18,
//                                 fontFamily: 'Poppins',
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             Text(
//                               'This may take some time',
//                               style: TextStyle(
//                                 color: Color(0xffACACAC),
//                                 fontSize: 12,
//                                 fontFamily: 'Poppins',
//                               ),
//                             ),
//                             SizedBox(height: 15),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ],
//                 )
//               //: const CircularProgressIndicator(),
//         ),
//       ),
//     );
//   },
// )


  loaderProvider.isLoading ?  GlassContainer.clearGlass(
        height: double.infinity,width: double.infinity,
        color: Colors.black.withOpacity(0.6),
        borderColor: Colors.transparent,
        child:Center(
            child: Container(
              height: MediaQuery.of(context).size.height*1.8/3,
               width: double.infinity,              
               padding: EdgeInsets.all(20),
               decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0)
               ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:BorderRadius.circular(15.0) ,
                    child: VideoPlayer(loaderProvider.controller,
                     key: ValueKey(DateTime.now().millisecondsSinceEpoch)
                    )),

                   Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Center(child: Padding(
                         padding: const EdgeInsets.only(top: 15.0),
                         child: Text('Connecting',style: TextStyle(fontSize: 16,fontFamily: 'Poppins',fontWeight: FontWeight.w700),),
                       )),
                      Center(
                        child: Column(
                          children: [
                            Text('Getting you to the Node..',style: TextStyle(color: Color(0xff41FF41),fontSize: 18,fontFamily: 'Poppins',fontWeight: FontWeight.w600),),
                            Text('This may take some time', style: TextStyle(color: Color(0xffACACAC),fontSize: 12,fontFamily: 'Poppins'),),
                            SizedBox(height: 15,)
                          ],
                        ),
                      )
                     ],
                   )
                ],
              )),
          )
    ):SizedBox(),






// GlassContainer.clearGlass(
//             height: double.infinity,width: double.infinity,
//             color: Colors.black.withOpacity(0.5),
//             borderColor: Colors.transparent,
//             child: Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(10.0),
//                 child: Material(
//                   borderRadius: BorderRadius.circular(15),
//                   color: Colors.transparent,
//                   child: Container(
//                     width: double.infinity,
//                     //margin: EdgeInsets.all(15),
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Color(0xffACACAC),width: 0.5),
//                       borderRadius: BorderRadius.circular(10)
//                     ),
//                     // constraints: BoxConstraints(
//                     //   maxWidth: 400, // optional for tablet/landscape sizing
//                     //   maxHeight: 300,
//                     // ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [

//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             SvgPicture.asset('assets/images/dark_theme/close.svg',color: Colors.transparent,),
//                             Text("Add Exit Node", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                             SvgPicture.asset('assets/images/dark_theme/close.svg')
//                           ],
//                         ),

//                         SizedBox(height: 10),

//                         Column(
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           crossAxisAlignment: CrossAxisAlignment.baseline,
//                           textBaseline: TextBaseline.alphabetic,
//                           children: [
//                             Text("Exit Node"),
//                             Container(
//                   height: 50,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.05),
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(color: const Color(0xff3A496266).withOpacity(0.1)),
//                   ),
//                   child: TextField(
//                     //controller: exitNodeController,
//                     decoration: InputDecoration(
//                       hintText: 'Enter Exit node',
//                      // prefixIcon: const Icon(Icons.search),
//                       border: InputBorder.none,
//                       hintStyle: const TextStyle(
//                         fontFamily: 'Poppins',
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Color(0xff5B5B69)
//                       ),
                
//                     ),
//                     onChanged: (value) {
//                       // Provider.of<AppSelectingProvider>(context, listen: false)
//                       //     .updateSearchQuery(value);
//                     },
//                   ),
//                 ),
//                 Text("Exit Node"),
//                             Container(
//                   height: 50,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.05),
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(color: const Color(0xff3A496266).withOpacity(0.1)),
//                   ),
//                   child: TextField(
//                     //controller: exitNodeController,
//                     decoration: InputDecoration(
//                       hintText: 'Enter Auth Code',
//                      // prefixIcon: const Icon(Icons.search),
//                       border: InputBorder.none,
//                       hintStyle: const TextStyle(
//                         fontFamily: 'Poppins',
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Color(0xff5B5B69)
//                       ),
                
//                     ),
//                     onChanged: (value) {
//                       // Provider.of<AppSelectingProvider>(context, listen: false)
//                       //     .updateSearchQuery(value);
//                     },
//                   ),
//                 ),
//                           ],
//                         ),
//                         SizedBox(height: 20),
//                         ElevatedButton(
//                           onPressed: () => Navigator.pop(context),
//                           child: Text("Close"),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           )






            ],
          ),
        ),
     // ),
    );
  }
}


class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  CustomBottomNavBar({required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10), // little bottom space
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric( vertical: 15),
             decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(12),
    //border: Border. //all(color: Color(0xff3A496266).withOpacity(0.1)),
  ),
           // color: Colors.black.withOpacity(0.3),
            margin: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem('assets/images/dark_theme/home.svg', 0,activeColor: Color(0xff00DC00)),
                _buildNavItem('assets/images/dark_theme/Nodes.svg', 1,activeColor: Color(0xff00DC00)),
                _buildNavItem('assets/images/dark_theme/Analytics.svg', 2,activeColor: Color(0xff00DC00)),
                _buildNavItem('assets/images/dark_theme/Settings.svg', 3,activeColor: Color(0xff00DC00)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String icon, int index, {Color activeColor = Colors.white}) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:isSelected ? Colors.white.withOpacity(0.11) : Colors.white.withOpacity(0.07), // Colors.grey.shade900.withOpacity(0.7),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10)
        ),
        child: SvgPicture.asset(icon, color: isSelected ? activeColor : Colors.grey,height: 20,)
        // Icon(
        //   icon,
        //   color: isSelected ? activeColor : Colors.grey,
        //   size: 28,
        // ),
      ),
    );
  }
}





