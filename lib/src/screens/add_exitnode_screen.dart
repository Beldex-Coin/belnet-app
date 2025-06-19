import 'dart:async';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/node_provider.dart';
import 'package:belnet_mobile/src/app_list_provider.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/providers/ip_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/providers/log_provider.dart';
import 'package:belnet_mobile/src/providers/speed_chart_provider.dart';
import 'package:belnet_mobile/src/providers/vpn_provider.dart';
import 'package:belnet_mobile/src/settings.dart';
import 'package:belnet_mobile/src/utils/show_toast.dart';
import 'package:belnet_mobile/src/vpn_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:provider/provider.dart';

class CustomAddExitNodeDialog extends StatefulWidget {
  @override
  _CustomAddExitNodeDialogState createState() => _CustomAddExitNodeDialogState();
}

class _CustomAddExitNodeDialogState extends State<CustomAddExitNodeDialog> {
  final TextEditingController _exitNodeController = TextEditingController();
  final TextEditingController _authCodeController = TextEditingController();
  bool _isChecked = false;
 bool isError = false;
  String? _exitNodeError;
  String? _authCodeError;
  bool isAuthCode = false;
  void _validateInputs() {
    setState(() {
      _exitNodeError =
          _exitNodeController.text.isEmpty ||
              !_exitNodeController.text.contains('wookajaspd')
          ? 'Please enter valid Exit Node'
          : null;
      _authCodeError =
          _authCodeController.text.isEmpty ||
              !_authCodeController.text.contains('wookajaspd')
          ? 'Please enter valid Auth Code'
          : null;
    });
  }








// Future<void> _handleCustomExitNode(String? exitvalue) async {
  

//   if (exitvalue != null && exitvalue.isNotEmpty) {
//     setState(() {
//       selectedValue = exitvalue;
//       selectedConIcon = "";
//     });

//     Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!myExit && !f) {
//         getDataFromDaemon();
//       } else {
//         timer.cancel();
//       }
//     });
//   }
//  //if(canValidateExit){
//   //  if (myExit) {
//   //   setState(() {
//   //     f = true;
//   //     mystr = "exitnode is valid";
//   //    // loading = false;
//   //   });
//   // } else {
//   //   setState(() {
//   //     mystr = "exitnode is invalid";
//   //   });
//   //   print("myExitvalue is $mystr");
//   //   await BelnetLib.disconnectFromBelnet();
//   //   logController.addDataTolist(
//   //     "$selectedValue is Invalid Exit Node",
//   //     "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
//   //   );
//   //   setState(() {
//   //     selectedValue =
//   //         'exit.bdx';
//   //     selectedConIcon =
//   //         "https://belnet-exitnode.s3.ap-south-1.amazonaws.com/countryflag/icons8-france.png";
//   //   });
//   //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//   //       backgroundColor: appModel.darkTheme
//   //           ? Colors.black.withOpacity(0.50)
//   //           : Colors.white,
//   //       behavior: SnackBarBehavior.floating,
//   //       width: MediaQuery.of(context).size.height * 2.5 / 3,
//   //       content: Text(
//   //         "Exit Node is Invalid!.switching to default Exit Node",
//   //         style: TextStyle(
//   //             color: appModel.darkTheme ? Colors.white : Colors.black),
//   //         textAlign: TextAlign.center,
//   //       )));
//   // }
//  //}
  
// }







// Future<void> _checkingExitnodeAfterDelay() async {
//  //if(canValidateExit){
//    if (myExit) {
//     setState(() {
//       f = true;
//       mystr = "exitnode is valid";
//       loading = false;
//     });
//   } else {
//     setState(() {
//       mystr = "exitnode is invalid";
//     });
//     print("myExitvalue is $mystr");
//     await BelnetLib.disconnectFromBelnet();
//     timer1?.cancel();
//     //  AwesomeNotifications().cancel(10);
//     logController.addDataTolist(
//       "$selectedValue is Invalid Exit Node",
//       "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
//     );
//     setState(() {
//       selectedValue =
//           'exit.bdx';
//       selectedConIcon =
//           "https://belnet-exitnode.s3.ap-south-1.amazonaws.com/countryflag/icons8-france.png";
//     });
//     showMessage('Exit Node is Invalid!.switching to default Exit Node');
//     // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//     //     backgroundColor: appModel.darkTheme
//     //         ? Colors.black.withOpacity(0.50)
//     //         : Colors.white,
//     //     behavior: SnackBarBehavior.floating,
//     //     width: MediaQuery.of(context).size.height * 2.5 / 3,
//     //     content: Text(
//     //       "Exit Node is Invalid!.switching to default Exit Node",
//     //       style: TextStyle(
//     //           color: appModel.darkTheme ? Colors.white : Colors.black),
//     //       textAlign: TextAlign.center,
//     //     )));
//   }
//  //}
  
// }


// Future<void> _saveCustomExitnodeSettings({String? exitvalue, String? dns}) async {
//   final settings = Settings.getInstance()!;
//   settings.exitNode = exitvalue.toString(); //nodeProvider.selectedExitNodeName!.trim().toString();
//   settings.upstreamDNS = dns ?? '9.9.9.9';
//   // final myVal = selectedValue!.trim().toString();
//   // logController.addDataTolist(" Exit node = $myVal",
//   //     "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");

//   // final preferences = await SharedPreferences.getInstance();
//   // await preferences.setString('hintValue', myVal);
//   // hintValue = preferences.getString('hintValue');

//   // logController.addDataTolist(dns == null
//   //     ? " default Upstream DNS = 9.9.9.9"
//   //     : " DNS = $dns", "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");

//   // settings.upstreamDNS = dns ?? '9.9.9.9';

//   // final eIcon = selectedConIcon!.trim().toString();
//   // await preferences.setString('hintCountryicon', eIcon);
//   // hintCountryIcon = preferences.getString('hintCountryicon');
//   // logController.addDataTolist(" Connected to $myVal",
//   //     "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
// }


// Future<void> connectToCustomBelnet(BuildContext context,AppSelectingProvider appSelectingProvider,NodeProvider nodeProvider,LoaderVideoProvider loaderVideoProvider,VpnConnectionProvider vpnConnectionProvider,SpeedChartProvider speedChartProvider,IpProvider ipProvider,LogProvider logProvider,[String? exitvalue, String? dns, bool isCustomExit = false]) async {
 

 
//   await _saveCustomExitnodeSettings(exitvalue: exitvalue,dns: dns);;
// print('THE LOADER VALUE IS 1----> ${loaderVideoProvider.isLoading}');
// logProvider.addLog('Checking for vpn Permission..');
//   final result = await BelnetLib.prepareConnection();
//   if (!result) {
//       print('THE LOADER VALUE IS 666----> ${loaderVideoProvider.isLoading}');
//       logProvider.addLog('VPN is not allowed to run');

//     return;
//   }
//     loaderVideoProvider.setLoading(true);
//     logProvider.addLog('Checking for connectivity');
//   bool con = await BelnetLib.connectToBelnet(
//       appSelectingProvider.isSPEnabled ?
//      appSelectingProvider.selectedApps.toList() : [],
//     exitNode: Settings.getInstance()!.exitNode!,
//     upstreamDNS: dns != null && dns.isNotEmpty ? dns : "9.9.9.9",
//   );
//       logProvider.addLog('Exit node set by Daemon: Connecting to ${nodeProvider.selectedExitNodeName}');


// print('CustomExitnode checking end');
//   if (con) {
//     vpnConnectionProvider.startConnectionDelay((){
   
//    ipProvider.startMonitoring();
//      loaderVideoProvider.setLoading(false);
//          loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTED);
//                logProvider.addLog('Exit node set by Daemon: Connected to ${nodeProvider.selectedExitNodeName}');

//         // speedChartProvider.startMonitoring();
//      print('ISCONNECT IS CONNNECTED AR NOT --> ${BelnetLib.isConnected}');
//      print('THE LOADER VALUE IS 4444----> ${loaderVideoProvider.isLoading}');
//   });
//   } else {
//     //setState(() => loading = false);
//   }
// }








  @override
  Widget build(BuildContext context) {
    final mHeight = MediaQuery.of(context).size.height;
    final appModel = Provider.of<AppModel>(context);
    final appSelectingProvider = Provider.of<AppSelectingProvider>(context);
    final nodeProvider = Provider.of<NodeProvider>(context);
        final loaderVideoProvider =  Provider.of<LoaderVideoProvider>(context, listen: false);

    return GlassContainer.clearGlass(
       padding:const EdgeInsets.all(15.0),
        height: mHeight * 1.47 / 3,
         width:double.infinity, //MediaQuery.of(dcontext).size.width * 2 / 3,
       // decoration: BoxDecoration(
          color: appModel.darkTheme ?Colors.transparent// black.withOpacity(0.7)
           :const Color(0xffF5F5F5).withOpacity(0.6),
          borderColor:appModel.darkTheme ? Color(0xffACACAC).withOpacity(0.5) : const Color(0xffACACAC),
          borderWidth:appModel.darkTheme ? 1.0 : 0.3,
          borderRadius: BorderRadius.circular(14.0),
          boxShadow: appModel.darkTheme ? [] : [
            
                          BoxShadow(
                  color: Color(0xFF00FFDD).withOpacity(0.3) ,// Colors.black12,,
                 
                ),
                BoxShadow(
                  color: Colors.white,
                  spreadRadius: -01.0,
                  blurRadius: 23.5,
                  offset: Offset(-3.0, 4.5),
                )
                        
          ],

      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
               Icon(Icons.close_rounded,color: Colors.transparent,),
                Text(
                  'Add Exit Node',
                  style: TextStyle(
                    color:appModel.darkTheme ? Colors.white : Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins'
                  ),
                ),
                 GestureDetector(
                  onTap: ()=> Navigator.pop(context),
                   child: SvgPicture.asset('assets/images/dark_theme/close.svg',color: appModel.darkTheme ? Colors.white: Colors.black,))
              ],
            ),
            SizedBox(height: 10),
           Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                  'Exit Node',
                  style: TextStyle(
                    color:appModel.darkTheme ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins'
                  ),
                ),
                SizedBox(height: 10,),
                Container(
              height: 50,
              decoration: BoxDecoration(
                color:appModel.darkTheme ? Color(0xff3A4962).withOpacity(0.12) : Color(0xffBEBEBE).withOpacity(0.13),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color:_exitNodeError != null ? Colors.red : Colors.transparent)
                
              ),
              padding: EdgeInsets.symmetric(vertical: 2,horizontal: 8),
              child: TextField(
                cursorColor: Color(0xff00B400),
                controller: _exitNodeController,
                style: TextStyle(color: Color(0xff00DC00)),
                decoration: InputDecoration(
                  hintText: 'Exit Node',
                 border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey,fontSize: 12),
                  // errorText: _exitNodeError,
                  // error: Container(
                  //   width: double.infinity,
                
                  //   color: Colors.white,
                  //   child: Text(_exitNodeError ?? ''),
                  // ),
                  // errorStyle: TextStyle(color: Colors.red,backgroundColor: Colors.white),
                  // enabledBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Colors.transparent, width: 1),
                  // ),
                  // focusedBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Colors.transparent, width: 1),
                  // ),
                  // errorBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Colors.red, width: 1),
                  // ),
                  // focusedErrorBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Colors.red, width: 1),
                  // ),
                ),
                  onChanged: (value) {
                  setState(() {
                    _authCodeError = null;
                    _exitNodeError = null;
                  });
                },
              ),
            ),
            _exitNodeError != null ? Text(
                  '$_exitNodeError',
                  style: TextStyle(
                    color:Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins'
                  ),
                ):SizedBox.shrink(),
            SizedBox(height: 10,),
            Text(
                  'DNS',
                  style: TextStyle(
                    color:isAuthCode ? appModel.darkTheme ? Colors.white : Colors.black : Color(0xff90909A),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins'
                  ),
                ),
               SizedBox(height: 10,),
              isAuthCode ?  Container(
              height: 50,
              decoration: BoxDecoration(
                color:appModel.darkTheme ? Color(0xff3A4962).withOpacity(0.12) : Color(0xffBEBEBE).withOpacity(0.13),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color:_authCodeError != null ? Colors.red : Colors.transparent)
                
              ),
              padding: EdgeInsets.symmetric(vertical: 2,horizontal: 8),
              child: TextField(
                cursorColor: Color(0xff00B400),
                controller: _authCodeController,
                style: TextStyle(color:Color(0xff00A3FF)),
                decoration: InputDecoration(
                  hintText: 'DNS',
                 border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey,fontSize: 12),
                  
                  // errorText: _exitNodeError,
                  // error: Container(
                  //   width: double.infinity,
                
                  //   color: Colors.white,
                  //   child: Text(_exitNodeError ?? ''),
                  // ),
                  // errorStyle: TextStyle(color: Colors.red,backgroundColor: Colors.white),
                  // enabledBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Colors.transparent, width: 1),
                  // ),
                  // focusedBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Colors.transparent, width: 1),
                  // ),
                  // errorBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Colors.red, width: 1),
                  // ),
                  // focusedErrorBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Colors.red, width: 1),
                  // ),
                ),
                onChanged: (value) {
                  setState(() {
                    _authCodeError = null;
                    _exitNodeError = null;
                  });
                },
              ),
            ): Container(
               height: 50,width: double.infinity,
              decoration: BoxDecoration(
                color:appModel.darkTheme ? Color(0xff3A4962).withOpacity(0.12) : Color(0xffBEBEBE).withOpacity(0.13),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.transparent)
                
              ),
              padding: EdgeInsets.symmetric(vertical: 10,horizontal: 8),
              child: Text('9.9.9.9',style: TextStyle(color: Colors.grey.withOpacity(0.3)),),
            ),
         isAuthCode ? _authCodeError != null ? 
         Text(
                  '$_authCodeError',
                  style: TextStyle(
                    color:Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins'
                  ),
                ):SizedBox.shrink():SizedBox.shrink(),
             ],
           ),
            
            SizedBox(height: 20),
                // isAuthCode ? Stack(
                //   children: [
                //     // Background container only for input area
                //     Container(
                //       height: 54, // Adjust height to match TextField content
                //       decoration: BoxDecoration(
                //         color: Color(0xffBEBEBE).withOpacity(0.13), // Background only behind input
                //         borderRadius: BorderRadius.circular(8),
                //       ),
                //     ),
                //     TextField(
                //       controller: _authCodeController,
                //       style: TextStyle(color: Colors.white),
                //       decoration: InputDecoration(
                //         isDense: true,
                //         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                //         hintText: 'Auth Code',
                //         hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                //         errorText: _authCodeError,
                //         errorStyle: TextStyle(color: Colors.red),
                //         border: OutlineInputBorder(
                //           borderSide: BorderSide.none,
                //           borderRadius: BorderRadius.circular(4),
                //         ),
                //         enabledBorder: OutlineInputBorder(
                //           borderSide: BorderSide.none,
                //           borderRadius: BorderRadius.circular(4),
                //         ),
                //         focusedBorder: OutlineInputBorder(
                //           borderSide: BorderSide.none,
                //           borderRadius: BorderRadius.circular(4),
                //         ),
                //         errorBorder: OutlineInputBorder(
                //           borderSide: BorderSide(color: Colors.red, width: 1),
                //           borderRadius: BorderRadius.circular(4),
                //         ),
                //         focusedErrorBorder: OutlineInputBorder(
                //           borderSide: BorderSide(color: Colors.red, width: 1),
                //           borderRadius: BorderRadius.circular(4),
                //         ),
                //       ),
                //     ),
                //   ],
                // ):  Container(
                //       height: 54,width: double.infinity, // Adjust height to match TextField content
                //       decoration: BoxDecoration(
                //         color: Color(0xffBEBEBE).withOpacity(0.13), // Background only behind input
                //         borderRadius: BorderRadius.circular(8),
                //       ),
                //     ),
                
          //  isAuthCode ? Container(
          //      height: 65,
          //     decoration: BoxDecoration(
          //       color: Color(0xffBEBEBE).withOpacity(0.13),
          //       borderRadius: BorderRadius.circular(8),
                
          //     ),
          //     child: TextField(
          //       controller: _authCodeController,
          //       style: TextStyle(color: Colors.white),
          //       decoration: InputDecoration(
          //         hintText: 'Auth Code',
          //         //labelText: 'Auth Code',
          //         hintStyle: TextStyle(color: Colors.grey,fontSize: 12),
          //         errorText: _authCodeError,
          //         errorStyle: TextStyle(color: Colors.red),
          //         enabledBorder: OutlineInputBorder(
          //           borderSide: BorderSide(color: Colors.transparent, //blue, 
          //           width: 1),
          //         ),
          //         focusedBorder: OutlineInputBorder(
          //           borderSide: BorderSide(color: Colors.transparent, width: 1),
          //         ),
          //         errorBorder: OutlineInputBorder(
          //           borderSide: BorderSide(color: Colors.red, width: 1),
          //         ),
          //         focusedErrorBorder: OutlineInputBorder(
          //           borderSide: BorderSide(color: Colors.red, width: 1),
          //         ),
          //       ),
          //     ),
          //   ) 
            // : Container(
            //    height: 65,
            //    width: double.infinity,
            //   decoration: BoxDecoration(
            //     color: Color(0xffBEBEBE).withOpacity(0.13),
            //     borderRadius: BorderRadius.circular(8),
                
            //   ),
            //   child: Text('9.9.9.9'),
            // ),
          //  SizedBox(height: 20),
            Row(
                children: [
                  
                  GestureDetector(
                      onTap: () {
                        setState(() {
                          isAuthCode = isAuthCode ? false : true;
                          _authCodeController.text = "9.9.9.9";
                          _authCodeError = null;
                          print("this is for authcode$isAuthCode");
                        });
                      },
                      child: appModel.darkTheme
                          ? SvgPicture.asset(isAuthCode
                              ? 'assets/images/check.svg'
                              : 'assets/images/Rectangle 10.svg')
                          : SvgPicture.asset(isAuthCode
                              ? 'assets/images/check.svg'
                              : 'assets/images/Rectangle 10 (1).svg')),
                              Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 8.0),
                    child: Text(
                      'DNS',
                      style: TextStyle(
                          color: appModel.darkTheme ? Colors.white : Colors.black,
                          fontSize:
                              mHeight * 0.05 / 3,
                          fontWeight: FontWeight.w100,
                          fontFamily: "Poppins"),
                    ),
                  ),
                ],
              ),
           // SizedBox(height: 20),
          // Spacer(),
            Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: GestureDetector(
                  onTap: () {
                  setState(
                    () {
                      _exitNodeError = null;
                      _authCodeError = null;
                    },
                  );
                
                  if (_exitNodeController.text == null || _exitNodeController.text == "") {
                    setState(() {
                      _exitNodeError = "Exitnode should not  be empty";
                      //color = "red";
                    });
                  } 
                  else if (_exitNodeController.text.length > 56) {
                    setState(() {
                      _exitNodeError = "Please enter a valid Exit Node";
                    });
                  } 
                  else if (_exitNodeController.text.isNotEmpty &&
                      !_exitNodeController.text.endsWith(".bdx")) {
                    setState(() {
                      _exitNodeError = "Please enter a valid Exit Node";
                      print(
                          "is contain method call ${!_exitNodeController.text.contains(".bdx")}");
                      //color = "red";
                    });
                  } else {
                    setState(() {
                      _exitNodeError = null;
                      //isSet = true;
                      //color = "green";
                    });
                    if (!isAuthCode && _authCodeController.text.isEmpty) {
                      print('DEFAULT AUTH CODE');
                      nodeProvider.selectNode(100,_exitNodeController.text,'');
                      toggleBelnet(context,appSelectingProvider,dns:  '9.9.9.9',isCustomeExitNode: true);
                      loaderVideoProvider.setIndex(0);
                      //toggleBelnet(AppSelectingProvider()..selectedApps.toList(),_cusExitNode.text, _cusAuthCode.text, true);
                      Navigator.pop(context);

                    } else if (isAuthCode && _authCodeController.text.isNotEmpty) {
                      print('${_authCodeController.text} is the dns');
                      if (_authCodeController.text == "1.1.1.1" ||
                          _authCodeController.text == "9.9.9.9" ||
                          _authCodeController.text == "8.8.8.8") {
                            nodeProvider.selectNode(100,_exitNodeController.text,'');
                      toggleBelnet(context,appSelectingProvider,dns:  _authCodeController.text,isCustomeExitNode: true);

                        // toggleBelnet(AppSelectingProvider()..selectedApps.toList(),
                        //     _cusExitNode.text, _cusAuthCode.text, true);
                        loaderVideoProvider.setIndex(0);
                        Navigator.pop(context);
                      } else {
                        setState((() {
                          _authCodeError = "Please enter a valid DNS";
                        }));
                      }
                    }
                  }
                },
                  child: appModel.darkTheme ?
                  Container(
                      //padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color:(_authCodeError == null && _exitNodeError == null) ?  Color(0xff00B400) : Color(0xffACACAC).withOpacity(0.4) //: Color(0xffACACAC)
                          ,width: 1),
                          //color: Colors.grey,
                          // gradient: LinearGradient(
                          //     colors: [const Color(0xff007ED1),const Color(0xff0093FF)]),
                         
                          boxShadow: [
                             BoxShadow(
                    color:(_authCodeError == null && _exitNodeError == null) ? Color(0xff00B400).withOpacity(0.02) : Color(0xff00FFDD).withOpacity(0.05) //Color(0xFF00DC00).withOpacity(0.2) ,// Colors.black12,,
                   
                  ),
                  BoxShadow(
                    color: Color(0xff000000), //s.transparent, //.white,
                    spreadRadius: -01.0,
                    blurRadius: 23.5,
                    offset: Offset(-3.0, 4.5),
                  )
                           ],
                          ),
                      height: mHeight * 0.21 / 3,
                      width: double.infinity,
                      child: 
                          Center(
                              child: Text(
                              "OK",
                              style: TextStyle(
                                   color:(_authCodeError == null && _exitNodeError == null) ? Colors.white: Color(0xffACACAC), //isSet ?
                                  //     Colors.white, // : Color(0xff56566F),
                                  fontFamily: "Poppins",
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900),
                            ))
                      )
                  
                  : Container(
                      //padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color:(_authCodeError == null && _exitNodeError == null) ?  Color(0xff00B400) : Color(0xffACACAC) //: Color(0xffACACAC)
                          ,width: 0.3),
                          //color: Colors.grey,
                          // gradient: LinearGradient(
                          //     colors: [const Color(0xff007ED1),const Color(0xff0093FF)]),
                         
                          boxShadow: [
                             BoxShadow(
                    color:(_authCodeError == null && _exitNodeError == null) ? Color(0xff00B400).withOpacity(0.2) : Color(0xff00FFDD).withOpacity(0.05) //Color(0xFF00DC00).withOpacity(0.2) ,// Colors.black12,,
                   
                  ),
                  BoxShadow(
                    color: Colors.white,
                    spreadRadius: -01.0,
                    blurRadius: 23.5,
                    offset: Offset(-3.0, 4.5),
                  )
                          //   appModel.darkTheme
                          //       ? BoxShadow(
                          //           color: Colors.black,
                          //           offset: Offset(0, 1),
                          //           //spreadRadius: 0,
                          //           blurRadius: 2.0)
                          //       : BoxShadow(
                          //           color: Color(0xff6E6E6E),
                          //           offset: Offset(0, 1),
                          //           blurRadius: 2.0)
                           ],
                          ),
                      height: mHeight * 0.21 / 3,
                      width: double.infinity,
                      child: 
                      // isCheckLoad
                      //     ? Expanded(
                      //         child: LinearPercentIndicator(
                      //           lineHeight:
                      //               mHeight * 0.30 / 3,
                      //           padding: EdgeInsets.zero,
                      //           animation: true,
                      //           animationDuration: 10000,
                      //           barRadius: Radius.circular(12.0),
                      //           percent: 1.0,
                      //           backgroundColor:const Color(0xffA8A8B7),
                      //           progressColor:const Color(0xff007ED1),
                      //         ),
                      //       )
                      //     :
                          Center(
                              child: Text(
                              "OK",
                              style: TextStyle(
                                   color:(_authCodeError == null && _exitNodeError == null) ? Colors.black: Color(0xffACACAC), //isSet ?
                                  //     Colors.white, // : Color(0xff56566F),
                                  fontFamily: "Poppins",
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900),
                            ))
                      ),
                ),
              ),
            // ElevatedButton(
            //   onPressed: () {
            //     _validateInputs();
            //     if (_exitNodeError == null && _authCodeError == null) {
            //       Navigator.of(context).pop();
            //     }
            //   },
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.grey[800],
            //     foregroundColor: Colors.white,
            //     padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            //   ),
            //   child: Text('OK'),
            // ),
          ],
        ),
      ),
    );
  }
}
