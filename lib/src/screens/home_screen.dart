import 'dart:async';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/node_provider.dart';
import 'package:belnet_mobile/src/app_list_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/providers/log_provider.dart';
import 'package:belnet_mobile/src/providers/speed_chart_provider.dart';
import 'package:belnet_mobile/src/providers/vpn_provider.dart';
import 'package:belnet_mobile/src/vpn_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToExitNodes;

  const HomeScreen({super.key, required this.onNavigateToExitNodes});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>  with SingleTickerProviderStateMixin, WidgetsBindingObserver{

late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
   // late VideoPlayerController _videoLoaderController;
 TextEditingController exitNodeController = TextEditingController();
 TextEditingController dnsController = TextEditingController();

  StreamSubscription<bool>? _isConnectedEventSubscription;




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
  final loaderVideoProvider = Provider.of<LoaderVideoProvider>(context,listen: false);
    final vpnConnectionProvider = Provider.of<VpnConnectionProvider>(context,listen: false);
    final logProvider = Provider.of<LogProvider>(context,listen: false);
     Future.microtask(() {
  print('inside the exitnode screen ${Provider.of<NodeProvider>(context,listen: false).nodeData}');
  });

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
      }catch(e){

      }
          }
  },
   onError: (error) {
    debugPrint("Notification disconnect stream error: $error");
  }
  
  );
}

int count = 0;
checkVPN(bool isConnect)async{
    bool connect = await BelnetLib.isRunning;  
  setState(() {
    




  });

}



String displaySpeed(int data){
  double rate = (data * 8) / 1000000.0;
  return '${rate.toStringAsFixed(2)} Mb/s';
}




@override
  void dispose() {
    _controller.dispose();
       WidgetsBinding.instance.removeObserver(this);
   // _videoLoaderController.dispose();
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
    final speedChartProvider = Provider.of<SpeedChartProvider>(context);
    return Scaffold(
       backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text( '1.2.0', style: TextStyle(fontFamily: 'Poppins',fontSize: 18),),
            centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left:  8.0),
          child: Row(
                      children: [
                       Image.asset('assets/images/belnet_ic.png',height: 28,color:Colors.white),
                       Text('Belnet',style: TextStyle(fontFamily: 'Poppins',),),
                       
                      ],
                    
                    ),
        ),
        leadingWidth: 100,
        actions: [
       Container(
          padding: EdgeInsets.all(7),
          margin: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
           borderRadius: BorderRadius.circular(8)
          ),
          child: SvgPicture.asset('assets/images/dark_theme/light_Theme.svg'))
        ],
        ),
        //floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
        // floatingActionButton: Column(
        //   children:[
        //     Container(
        //       height: 60,width: double.infinity,
        //       decoration: BoxDecoration(
        //         border: Border.all(color: Colors.green)
        //       ),
        //     )
        //   ]
        // ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height*2.3/3,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
                         
            Column(
              children: [
                GestureDetector(
                  onTap:()=>toggleBelnet(context,appSelectingProvider,'9.9.9.9'),
                  child: GlassContainer.clearGlass(
                    height: 180,
                  width: 180,
                  shape: BoxShape.circle,
                  borderColor: Colors.transparent,
                  blur: 10,
                  color: Colors.white.withOpacity(0.05),
                    
                    child:loaderVideoProvider.conStatus == ConnectionStatus.CONNECTED //|| BelnetLib.isConnected
                     ? SvgPicture.asset('assets/images/dark_theme/disconnect.svg') : SvgPicture.asset('assets/images/dark_theme/connect.svg')),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap:()=> showCenteredBottomSheet(context),
                  child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer container for the gradient border
                            Container(
                              width: 164,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(44),
                                border: Border.all(color: Color(0xfff00DC00),width: 0.3),
                                gradient: LinearGradient(
                  colors: [
                    Color(0xFF464663), // Gradient start color
                    Color(0xFF00DC00).withOpacity(0.6), // Gradient end color
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            // Inner container for the background and inner shadow
                            ClipRRect(
                              borderRadius: BorderRadius.circular(44),
                              child: Container(
                                width: 162, // Slightly smaller to account for the 1px border
                                height: 42,
                                decoration: BoxDecoration(
                  color: Color(0xff3A496266), // Colors.transparent, //(0xFF3A4962).withOpacity(0.4), // Background color with 40% opacity
                  borderRadius: BorderRadius.circular(44),
                  boxShadow: [
                    BoxShadow(
                      //color: Color(0xFF0094FF), // Inner shadow color
                      offset: Offset(-3, 3), // X: -2, Y: 2
                      blurRadius: 16, // Blur: 12
                      spreadRadius: -2, // Negative spread to create inner shadow
                    ),
                  ],
                                ),
                                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset('assets/images/dark_theme/add_exit_node.svg',color: Color(0xFF00DC00)),
                    Padding(
                      padding: const EdgeInsets.only(left:8.0),
                      child: Text('Add Exit Node',style: TextStyle(color: Color(0xFF00DC00),fontFamily: 'Poppins',fontWeight: FontWeight.w600,fontSize: 12),),
                    )
                  ],
                                ),
                              ),
                            ),
                          ],
                              ),
                ),  
              ],
            ),
             
        
        
        
        
        
            Column(
              children: [
                SlideTransition(
                  position: _offsetAnimation,
                  child: GestureDetector(
                    onTap: widget.onNavigateToExitNodes,
                    child: Container(
                        height: MediaQuery.of(context).size.height*0.35/3,width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xff00DC00).withOpacity(0.02),
                          border: Border.all(color: Color(0xff00DC00),width: 0.8)
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10,horizontal: 8),
                       child: Row(
                        children: [
                            Container(
                              height: 45,width: 45,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                               color:  Colors.white.withOpacity(0.1)
                              ),
                              padding: EdgeInsets.all(10),
                              child: Image.asset('assets/images/flags/${nodeProvider.selectedExitNodeCountry}.png'),
                            ),
                            SizedBox(width: 8,),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${nodeProvider.selectedExitNodeCountry}', style: TextStyle(fontFamily: 'Poppins',fontSize: 12,color: Color(0xffACACAC))),
                                  SizedBox(height: 5,),
                                  Text('${nodeProvider.selectedExitNodeName}', maxLines: 2, style: TextStyle(overflow: TextOverflow.ellipsis,fontFamily: 'Poppins',fontSize: 12),)
                                ],
                              ),
                            ),
                            SizedBox(width: 10,),
                            Container(
                              height: 30,width: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1)
                              ),
                              padding: EdgeInsets.all(8),
                              child: SvgPicture.asset('assets/images/dark_theme/arrow_settings.svg',height: 20,color: Colors.white,))
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
                        height: MediaQuery.of(context).size.height * 0.15,
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xffACACAC).withOpacity(0.05), //s.black12,
                        blur: 5.0,
                        borderColor: Color(0xffACACAC),
                        borderWidth: 0.5,
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  radius: 20,
                  child: SvgPicture.asset('assets/images/dark_theme/connection.svg') //Icon(Icons.link, color: Colors.white, size: 20),
                ),
                SizedBox(height: 8),
                Text("Status", style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(height: 4),
                Text(capitalizeFirstLetter(loaderVideoProvider.conStatus.name), style: TextStyle(color:loaderVideoProvider.conStatus == ConnectionStatus.CONNECTED ?  Color(0xff00DC00) : loaderVideoProvider.conStatus == ConnectionStatus.CONNECTING ? Colors.blue : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: GlassContainer(
                        height: MediaQuery.of(context).size.height * 0.15,
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xffACACAC).withOpacity(0.05),
                        blur: 5.0,
                        borderColor: Color(0xffACACAC),
                        borderWidth: 0.5,
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  radius: 20,
                  child: SvgPicture.asset('assets/images/dark_theme/Download.svg') //Icon(Icons.download, color: Colors.white, size: 20),
                ),
                SizedBox(height: 8),
                Text("Download", style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(height: 4),
                Text(displaySpeed(speedChartProvider.download), //"40.5 Mb/s",
                 style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: GlassContainer(
                        height: MediaQuery.of(context).size.height * 0.15,
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xffACACAC).withOpacity(0.05),
                        blur: 5.0,
                        borderColor: Color(0xffACACAC),
                        borderWidth: 0.5,
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  radius: 20,
                  child: SvgPicture.asset('assets/images/dark_theme/upload.svg') //Icon(Icons.upload, color: Colors.white, size: 20),
                ),
                SizedBox(height: 8),
                Text("Upload", style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(height: 4),
                Text(displaySpeed(speedChartProvider.upload), //"12.5 Mb/s", 
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
        
              ],
            ),
        
              
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Expanded(
              //         child: GlassContainer(
              //           height:MediaQuery.of(context).size.height*0.43/3,
              //           color: Colors.black12,
              //           blur: 5.0,
        
              //           //decoration: BoxDecoration(
              //             borderRadius: BorderRadius.circular(10),
              //         borderColor:// Border.all(
              //         Color(0xffACACAC),//)
              //         borderWidth: 0.5,
              //           //),
              //           child: Column(
              //             children: [
        
              //             ],
              //           ),
              //         ),
              //       ),
              //       SizedBox(width: 5,),
              //       Expanded(
              //         child: GlassContainer(
              //           height:MediaQuery.of(context).size.height*0.43/3,
              //           color: Colors.black12,
              //           blur: 5.0,
        
              //           //decoration: BoxDecoration(
              //             borderRadius: BorderRadius.circular(10),
              //         borderColor:// Border.all(
              //         Color(0xffACACAC),//)
              //         borderWidth: 0.5,
              //           //),
              //           child: Column(
              //             mainAxisAlignment: MainAxisAlignment.start,
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //                 Container(
              //                   height: 50,
              //                   decoration: BoxDecoration(
              //                     shape: BoxShape.circle,
              //                     color: Colors.white.withOpacity(0.1),
              //                     border: Border.all(color: Color(0xffA1A1AF80).withOpacity(0.3),)
              //                   ),
              //                 )
              //             ],
              //           ),
              //         ),
              //       ),
              //       SizedBox(width: 5,),
              //       Expanded(
              //         child: GlassContainer(
              //           height:MediaQuery.of(context).size.height*0.43/3,
              //           color: Colors.black12,
              //           blur: 5.0,
        
              //           //decoration: BoxDecoration(
              //             borderRadius: BorderRadius.circular(10),
              //         borderColor:// Border.all(
              //         Color(0xffACACAC),//)
              //         borderWidth: 0.5,
              //           //),
              //           child: Column(
              //             children: [
        
              //             ],
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // )
        ],  
        ),
      )
      
      //Center(child: Text('Working', style: TextStyle(fontSize: 24))),
    );
  }

  void showCenteredBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // make background transparent
    builder: (context) {
      return StatefulBuilder(
        builder: (context, snapshot) {
          return GlassContainer.clearGlass(
            height: double.infinity,width: double.infinity,
            color: Colors.black.withOpacity(0.5),
            borderColor: Colors.transparent,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Material(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    //margin: EdgeInsets.all(15),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xffACACAC),width: 0.5),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    // constraints: BoxConstraints(
                    //   maxWidth: 400, // optional for tablet/landscape sizing
                    //   maxHeight: 300,
                    // ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SvgPicture.asset('assets/images/dark_theme/close.svg',color: Colors.transparent,),
                            Text("Add Exit Node", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SvgPicture.asset('assets/images/dark_theme/close.svg')
                          ],
                        ),

                        SizedBox(height: 10),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text("Exit Node"),
                            Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xff3A496266).withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: exitNodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter Exit node',
                     // prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      hintStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff5B5B69)
                      ),
                
                    ),
                    onChanged: (value) {
                      Provider.of<AppSelectingProvider>(context, listen: false)
                          .updateSearchQuery(value);
                    },
                  ),
                ),
                          ],
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Close"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      );
    },
  );
}

}

