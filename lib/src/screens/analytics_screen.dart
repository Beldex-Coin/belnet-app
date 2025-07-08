import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/graph_ui.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/providers/ip_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/providers/log_provider.dart';
import 'package:belnet_mobile/src/utils/show_toast.dart';
import 'package:belnet_mobile/src/widget/LineChartSample10.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:provider/provider.dart';

class ChartScreen extends StatefulWidget {
  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> with SingleTickerProviderStateMixin{


late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _widthAnimation;
 bool value = false;

 bool canShowIP = false;
  final ScrollController _scrollController = ScrollController();


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1), // From top
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _widthAnimation = Tween<double>(
      begin: 0.2,  // Narrow (20% of full width)
      end: 1.0,    // Full width
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

checkRunning();

  }


  void checkRunning()async{
     value = await BelnetLib.isRunning.asStream().first;
     setState(() {
       
     });
     print('THE STREAM VALUE FROM THE RUNNING STATUS ${value}');
  }



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen for changes in log list and auto-scroll
    final logProvider = Provider.of<LogProvider>(context);
    logProvider.addListener(() {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }




  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }










  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
                final appModel = Provider.of<AppModel>(context);
        final ipProvider = Provider.of<IpProvider>(context);
        final logProvider = Provider.of<LogProvider>(context);
        final loaderVideoProvider = Provider.of<LoaderVideoProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text( 'Analytics', style: TextStyle(fontFamily: 'Poppins',fontSize: 18,fontWeight: FontWeight.w500),),
              centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.only(left:  8.0),
            child: Row(
                        children: [
                           SvgPicture.asset('assets/images/dark_theme/Belnet_logo_new.svg',height: 15),
       
                        ],
                      
                      ),
          ),
          leadingWidth: 100,
          actions: [
           GestureDetector(
          onTap: (){
             appModel.darkTheme = !appModel.darkTheme;
            // loaderVideoProvider.initialize(appModel.darkTheme ? 'assets/images/dark_theme/Loading_v1_slow.webm' : 'assets/images/light_theme/loading_white_theme.webm');
      
             },
           child: Container(
              padding: EdgeInsets.all(7),
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color:appModel.darkTheme? Colors.grey.withOpacity(0.1):Color(0xffA1A1A1).withOpacity(0.2),// Colors.grey.withOpacity(0.1),
               borderRadius: BorderRadius.circular(10)
              ),
              child:appModel.darkTheme? SvgPicture.asset('assets/images/dark_theme/light_Theme.svg'):SvgPicture.asset('assets/images/light_theme/dark_theme.svg') ),
         )
          ],
          ),
        body: GlassContainer.clearGlass(
           width: double.infinity,
         height:double.infinity, // height*2.26/3,
         margin: EdgeInsets.only(top: 10,left:10,right:10),
        blur: 5.0,
          color:appModel.darkTheme ? Color(0xff080C29).withOpacity(0.7) :Color(0x33FFFFFF).withOpacity(0.02), //.black38, // Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          borderColor: Color(0xffACACAC).withOpacity(0.6),
          borderWidth: 0.3,
          boxShadow:appModel.darkTheme ? [] : [
                          BoxShadow(
                      color: Color(0xff00FFDD).withOpacity(0.03) //Color(0xFF00DC00).withOpacity(0.2) ,// Colors.black12,,
                     
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      spreadRadius: -01.0,
                      blurRadius: 23.5,
                      offset: Offset(-3.0, 4.5),
                    )
                       ],
          padding: EdgeInsets.symmetric(vertical: 15,horizontal: 10),
          child: Column(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassContainer.clearGlass(
                blur: 15.0,
                color:appModel.darkTheme ? Colors.white.withOpacity(0.01): Color(0xffBEBEBE).withOpacity(0.1),
                height: MediaQuery.of(context).size.height*0.50/3, //130,
                width: double.infinity,
                borderRadius: BorderRadius.circular(14),
                borderColor: Colors.transparent,
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('IP Address',style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w600),),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children:[
                        Expanded(
                          child: GlassContainer(
                            height:  height*0.30/3,
                             blur: 15.0,
                                       color:  appModel.darkTheme ? Colors.white.withOpacity(0.06) : Color(0xffBEBEBE).withOpacity(0.2),
                                           borderRadius: BorderRadius.circular(14),
                                        borderColor: Colors.transparent,
                                        padding: EdgeInsets.all(8),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text('My IP  ',style: TextStyle(color:appModel.darkTheme ? Color(0xffACACAC): Color(0xff4D4D4D),fontSize: 11,fontFamily: 'Poppins'),),
                                                GestureDetector(
                                                  onTap: ()=>setState(() {
                                                    canShowIP = !canShowIP;
                                                  }),
                                                  child:canShowIP ? SvgPicture.asset('assets/images/dark_theme/view_IP.svg') : SvgPicture.asset('assets/images/dark_theme/hide.svg')),
                                                  //Icon(Icons)
                                              ],
      
                                            ),
                                            SizedBox(height: 10,),
                                        !canShowIP ? Text( '***.**.***.**',style: TextStyle(fontFamily: 'Poppins',fontSize: 11),)
                                        : Text( '${ipProvider.realIp}',style: TextStyle(fontFamily: 'Poppins',fontSize: 11),),
      
                                          ],
                                        ),
                          ),
                        ),
                        SizedBox(width: 5,),
                        Expanded(
                          child: GlassContainer(
                            height: height*0.30/3,
                             blur: 15.0,
                                        color: appModel.darkTheme ? Colors.white.withOpacity(0.06) : Color(0xffBEBEBE).withOpacity(0.2),
                                           borderRadius: BorderRadius.circular(14),
                                        borderColor: Colors.transparent,
                                        padding: EdgeInsets.only(left:5),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children:[
                                         Text('VPN IP  ',style: TextStyle(color:appModel.darkTheme ? Color(0xffACACAC): Color(0xff4D4D4D),fontSize: 11,fontFamily: 'Poppins'),),
                                            RichText(
                            textAlign: TextAlign.justify,
                            maxLines: 1,
                              text: TextSpan(
                                  text: "IPV4: ",
                                  style: TextStyle(
                                      fontSize:11, //mHeight * 0.060 / 3,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      color: Color(0xff00DC00)),
                                  children: [
                                TextSpan(
                                    text:ipProvider.currentIPv4,
                                        style: TextStyle(
                                        fontSize:11, //mHeight * 0.056 / 3,
                                        fontWeight: FontWeight.w100,
                                        fontFamily: 'Poppins',
                                        color:appModel.darkTheme ? Color(0xffffffff): Color(0xff333333),
                                        overflow: TextOverflow.ellipsis
                                            ))
                              ])),
                              SizedBox(height: 5,),
                                RichText(
                            textAlign: TextAlign.justify,
                            maxLines: 1,
                              text: TextSpan(
                                  text: "IPV6: ",
                                  style: TextStyle(
                                      fontSize:11, //mHeight * 0.060 / 3,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      color: Color(0xff00A3FF)),
                                  children: [
                                TextSpan(
                                    text:ipProvider.currentIPv6,
                                        style: TextStyle(
                                        fontSize:11, //mHeight * 0.056 / 3,
                                        fontWeight: FontWeight.w100,
                                        fontFamily: 'Poppins',
                                        color:appModel.darkTheme ? Color(0xffffffff): Color(0xff333333),
                                        overflow: TextOverflow.ellipsis
                                        
                                            ))
                              ])),
                                          ]
                                        ),
                          ),
                        )
                        ]
                      ),
                    )
                  ],
                ),
              ),
              //DynamicNetworkSpeedChart(),
              SizedBox(height: 8,),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         CircleAvatar(radius: 3, backgroundColor: Color(0xff00DC00)),
                         SizedBox(width: 5),
                         Text('Download', style: TextStyle(color:appModel.darkTheme ? Color(0xffACACAC) : Colors.black,fontFamily: 'Poppins',fontSize: 9)),
                       ],
                     ),
                     SizedBox(width: 10),
                     Row(
                       children: [
                         CircleAvatar(radius: 3, backgroundColor: Color(0xff00A3FF)),
                         SizedBox(width: 5),
                         Text('Upload', style: TextStyle(color:appModel.darkTheme ? Color(0xffACACAC) : Colors.black,fontFamily: 'Poppins',fontSize: 9)),
                       ],
                     ),
                   ],
                 ),
              //ChartData(),
              Container(
                height: 180,
                child: ChartWidget()),
             // NetworkSpeedChart(),
              Flexible(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: AnimatedBuilder(
                    builder: (context, snapshot) {
                      return GlassContainer.clearGlass(
                        blur: 1.0,
                        color:appModel.darkTheme ? Colors.grey.withOpacity(0.08): Color(0xffBEBEBE).withOpacity(0.2),
                        width: screenWidth * _widthAnimation.value,
                        borderColor: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        padding: EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Row(
                              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Logs',style: TextStyle(fontFamily: 'Poppins',fontSize: 14,fontWeight: FontWeight.w600),),
                                Spacer(),
                                Row(
                                  children: [
                                  //   Container(
                                  //     height: 33,//width: 70,
                                  // padding: EdgeInsets.symmetric(vertical:  8,horizontal: 10),
                                  //     decoration: BoxDecoration(
                                  //       color: Colors.grey.withOpacity(0.06),
                                  //       borderRadius: BorderRadius.circular(20)
                                  //     ),
                                  //     child: Row(
                                  //       children:[
                                  //          SvgPicture.asset(),
                                  //          SizedBox(width: 5,),
                                  //         Text('Clear',style: TextStyle(fontFamily: 'Poppins',fontSize: 11),)
                                  //       ]
                                  //     ),
                                  //   ),
                                optionButton(icon: 'assets/images/dark_theme/clear_logs.svg', text: 'Clear', 
                                onPressed:logProvider.logs.isEmpty ? (){} : (){
                                  logProvider.clearLogs();
                                  showMessage("Logs cleared!");
                                  // ScaffoldMessenger.of(context)
                                  //   .showSnackBar(SnackBar(
                                  //       backgroundColor: appModel.darkTheme
                                  //           ? Colors.black.withOpacity(0.50)
                                  //           : Colors.white,
                                  //       behavior: SnackBarBehavior.floating,
                                  //       duration: Duration(milliseconds: 200),
                                  //       width: 200,
                                        
                                  //       content: Text(
                                  //         "Logs cleared!",
                                  //         style: TextStyle(
                                  //             color: appModel.darkTheme
                                  //                 ? Colors.white
                                  //                 : Colors.black),
                                  //         textAlign: TextAlign.center,
                                  //       )
                                  //       //content: Text("Sending Message"),
                                  //       ));
                                }
                                
                                ),
      
                                  ],
                                ),
                                SizedBox(width: 5,),
                                optionButton(onPressed:logProvider.logs.isEmpty ? (){} :(){
                                   FlutterClipboard.copy(logProvider.getAllLogs().toString())
                                .then((value) => showMessage('Copied to clipboard!')
                                // ScaffoldMessenger.of(context)
                                //     .showSnackBar(SnackBar(
                                //         backgroundColor: appModel.darkTheme
                                //             ? Colors.black.withOpacity(0.50)
                                //             : Colors.white,
                                //         behavior: SnackBarBehavior.floating,
                                //         duration: Duration(milliseconds: 200),
                                //         width: 200,
                                //         content: Text(
                                //           "Copied to clipboard!",
                                //           style: TextStyle(
                                //               color: appModel.darkTheme
                                //                   ? Colors.white
                                //                   : Colors.black),
                                //           textAlign: TextAlign.center,
                                //         )
                                //         //content: Text("Sending Message"),
                                //         ))
                                );
      
                           
      
                                 // Clipboard.setData(ClipboardData(text: logProvider.logs.toString()));
                                  
                                  }  ,text: 'Copy',icon:'assets/images/dark_theme/copy_logs.svg',)
                              ],
                            ),
                            Expanded(
                    child: RawScrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      thickness: 3,
                      radius: Radius.circular(5),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: SelectableText.rich(
                            TextSpan(
                              children: logProvider.logs.map(_buildStyledLog).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                          ],
                        ),
                      );
                    }, animation: _widthAnimation,
                  ),
                ),
              ),
            ],
          ),
        )
      ),
    );
  }
  

  TextSpan _buildStyledLog(LogEntry log) {
  final appModel = Provider.of<AppModel>(context, listen: false);
  final dark = appModel.darkTheme;

  final timestamp = log.timestamp.millisecondsSinceEpoch.toString();
  final message = log.message;
  final daemonIndex = message.indexOf("Daemon");

  List<TextSpan> spans = [];

  // 1. Add timestamp (gray)
  spans.add(
    TextSpan(
      text: "$timestamp: ",
      style: const TextStyle(color: Color(0xffACACAC), fontSize: 11),
    ),
  );

  if (daemonIndex != -1) {
    // 2. Before "Daemon" (in message)
    final beforeDaemon = message.substring(0, daemonIndex);
    spans.add(
      TextSpan(
        text: beforeDaemon,
        style: TextStyle(
          color: dark ? Colors.white : Colors.black,
          fontSize: 11,
        ),
      ),
    );

    // 3. The word "Daemon"
    spans.add(
      const TextSpan(
        text: "Daemon",
        style: TextStyle(
          color: Color(0xff00DC00),
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );

    // 4. After "Daemon"
    final afterDaemon = message.substring(daemonIndex + "Daemon".length);
    spans.add(
      TextSpan(
        text: "$afterDaemon\n",
        style: TextStyle(
          color: dark ? Colors.white : Colors.black,
          fontSize: 11,
        ),
      ),
    );
  } else {
    // No "Daemon" — regular log
    spans.add(
      TextSpan(
        text: "$message\n",
        style: TextStyle(
          color: dark ? Colors.white : Colors.black,
          fontSize: 11,
        ),
      ),
    );
  }

  return TextSpan(children: spans);
}

//   TextSpan _buildStyledLog(LogEntry log) {
//     final formattedTime = log.timestamp.millisecondsSinceEpoch.toString();
//     final fullMessage = "$formattedTime: ${log.message}";
//     final parts = fullMessage.split("Daemon");
//     final appModel = Provider.of<AppModel>(context,listen: false);
//     if (parts.length == 2) {
//       return TextSpan(
//         style: TextStyle(fontSize: 11),
//         children: [

//         TextSpan(text: parts[0], style: const TextStyle(color: Color(0xffACACAC))),
//         const TextSpan(text: "Daemon", style: TextStyle(color: Color(0xff00DC00), fontWeight: FontWeight.bold)),
//         TextSpan(text: parts[1] + "\n", style: TextStyle(color:appModel.darkTheme ? Colors.white : Colors.black)),
//       ]);
//     } else {
//       return TextSpan(
//         children: [
//           TextSpan(text: formattedTime,style: const TextStyle(color: Color(0xffACACAC),fontSize: 11)),
//           TextSpan(text: ": "+log.message + "\n", style: TextStyle(color: appModel.darkTheme ? Colors.white : Colors.black,fontSize: 11)
// )
//         ],
        
//         );
//     }
//   }
}






class optionButton extends StatelessWidget {
  final String icon;
  final String text;
  final VoidCallback onPressed;
  const optionButton({
    super.key, required this.icon, required this.text, required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 33,//width: 70,
        padding: EdgeInsets.symmetric(vertical:  8,horizontal: 10),
        decoration: BoxDecoration(
          color:appModel.darkTheme ? Colors.grey.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20)
        
        ),
        child: Row(
          children:[
             SvgPicture.asset(icon),
             SizedBox(width: 5,),
            Text(text,style: TextStyle(fontFamily: 'Poppins',fontSize: 11),)
          ]
        ),
      ),
    );
  }
}

