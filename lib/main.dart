import 'dart:async';
import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:belnet_mobile/displaylog.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/splash_screen.dart';
import 'package:belnet_mobile/src/utils/styles.dart';
import 'package:belnet_mobile/src/widget/connecting_status.dart';
import 'package:belnet_mobile/src/widget/exit_node_list.dart';
import 'package:belnet_mobile/src/widget/liveChart.dart';
import 'package:belnet_mobile/src/widget/notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/settings.dart';
import 'package:belnet_mobile/src/widget/belnet_power_button.dart';
import 'package:belnet_mobile/src/widget/themed_belnet_logo.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:native_updater/native_updater.dart';

import 'package:provider/provider.dart' as pr;
import 'package:shared_preferences/shared_preferences.dart';

//Global variables

bool netValue = true;
bool isClick = false;
bool loading = false;

void main() async {
  //Load settings
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.getInstance()!.initialize();
  Paint.enableDithering = true;
  pr.Provider.debugCheckInvalidValueType = null;

  AwesomeNotifications()
      .initialize('resource://drawable/res_notification_app_icon', [
    NotificationChannel(
        channelKey: 'basic_channel',
        channelDescription: '',
        channelName: 'basic notifications',
        defaultColor: Colors.teal,
        enableVibration: true,
        importance: NotificationImportance.Low,
        locked: true,
        defaultPrivacy: NotificationPrivacy.Public)
  ]);

  setExitStringsToSharedPrrefs();
  runApp(ProviderScope(child: BelnetApp()));
}

setExitStringsToSharedPrrefs() async {
  List<String> exitNodes = [
    'iyu3gajuzumj573tdy54sjs7b94fbqpbo3o44msrba4zez1o4p3o.bdx',
    'a6iiyy3c4qsp8kdt49ao79dqxskd81eejidhq9j36d8oodznibqy.bdx',
    'snoq7arak4d5mkpfsg69saj7bp1ikxyzqjkhzb96keywn6iyhc5y.bdx'
  ];
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList("ExitNodes", exitNodes);
}

class BelnetApp extends StatefulWidget {
  @override
  State<BelnetApp> createState() => _BelnetAppState();
}

class _BelnetAppState extends State<BelnetApp> {
  // This widget is the root of your application.

  AppModel appModel = new AppModel();

  void _initAppTheme() async {
    appModel.darkTheme = await appModel.appPreference.getTheme();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));

    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack, overlays: [SystemUiOverlay.top]);
    setvalueToExitNode();

    _initAppTheme();
  }

  setvalueToExitNode() async {
    final prefs = await SharedPreferences.getInstance();
    exitItems = prefs.getStringList("ExitNodes")!;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return pr.ChangeNotifierProvider<AppModel>.value(
      value: appModel,
      child: pr.Consumer<AppModel>(builder: (context, value, child) {
        return MaterialApp(
            title: 'Belnet App',
            debugShowCheckedModeBanner: false,
            theme: appModel.darkTheme ? buildDarkTheme() : buildLightTheme(),
            home: SplashScreens() //BelnetHomePage(),
            );
      }),
    );
  }
}

late List<String> exitItems;

class BelnetHomePage extends StatefulWidget {
  BelnetHomePage({Key? key}) : super(key: key);

  @override
  BelnetHomePageState createState() => BelnetHomePageState();
}

class BelnetHomePageState extends State<BelnetHomePage>
// with SingleTickerProviderStateMixin
{
  late ConnectivityResult connectivityResult;

  @override
  void initState() {
    checkVersion(context);
    Timer.periodic(Duration(seconds: 5), (timer) {
      myNetwork();
    });
    setState(() {});

    super.initState();
  }

  Future<void> checkVersion(BuildContext context) async {
    /// For example: You got status code of 412 from the
    /// response of HTTP request.
    /// Let's say the statusCode 412 requires you to force update
    final statusCode = 412;

    /// This could be kept in our local
    // final localVersion = 9;

    /// This could get from the API
    //final serverLatestVersion = 10;

    Future.delayed(Duration.zero, () {
      if (statusCode == 412) {
        NativeUpdater.displayUpdateAlert(
          context,
          forceUpdate: true,
          appStoreUrl: '',
          playStoreUrl:
              'https://play.google.com/store/apps/details?id=io.beldex.belnet',
          iOSDescription:
              'A new version of the Belnet application is available. Update to continue using it.',
          iOSUpdateButtonLabel: 'Upgrade',
          iOSCloseButtonLabel: 'Exit',
          iOSAlertTitle: 'Mandatory Update',
        );
      } /* else if (serverLatestVersion > localVersion) {
        NativeUpdater.displayUpdateAlert(
          context,
          forceUpdate: true,
          appStoreUrl: 'https://apps.apple.com/in/app/beldex-official-wallet/id1603063369',
          playStoreUrl: 'https://play.google.com/store/apps/details?id=io.beldex.wallet',
          iOSDescription: 'Your App requires that you update to the latest version. You cannot use this app until it is updated.',
          iOSUpdateButtonLabel: 'Upgrade',
          iOSCloseButtonLabel: 'Exit',
        );*/
    });
  }

  myNetwork() async {
    connectivityResult = await Connectivity().checkConnectivity();
    switch (connectivityResult) {
      case ConnectivityResult.wifi:
        {
          setState(() {});
          netValue = true;
        }
        break;
      case ConnectivityResult.ethernet:
        {
          setState(() {});
          netValue = true;
        }
        break;
      case ConnectivityResult.mobile:
        {
          setState(() {});
          netValue = true;
        }
        break;
      case ConnectivityResult.none:
        {
          setState(() {});
          netValue = false;
        }
        break;
      default:
        print('Error occured while checking network');
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget build(BuildContext context) {
    final appModel = pr.Provider.of<AppModel>(context);
    return netValue == false
        ? NoInternetConnection()
        : Container(
            decoration: BoxDecoration(
              color: appModel.darkTheme ? Color(0xFF242430) : Color(0xFFF9F9F9),
              // gradient: LinearGradient(
              //   begin: Alignment.topCenter,
              //   end: Alignment.bottomCenter,
              //   colors: appModel.darkTheme
              //       ? [
              //           Color(0xFF242430),
              //           Color(0xFF1C1C26),
              //         ]
              //       : [
              //           Color(0xFFF9F9F9),
              //           Color(0xFFEBEBEB),
              //         ],
              // ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              //key: key,
              resizeToAvoidBottomInset:
                  false, //Prevents overflow when keyboard is shown
              body: MyForm(),
            ),
          );
  }
}

// global list for exitnode

// Create a Form widget.

dynamic downloadRate = '';
dynamic uploadRate = '';

class MyForm extends StatefulWidget {
  @override
  MyFormState createState() {
    return MyFormState();
  }
}

class MyFormState extends State<MyForm> with SingleTickerProviderStateMixin {
  static final key = new GlobalKey<FormState>();
  StreamSubscription<bool>? _isConnectedEventSubscription;

  String downloadProgress = '0';
  String uploadProgress = '0';
  double displayRate = 0;
  String displayRateTxt = '0.0';
  double displayPer = 0;
  String unitText = 'Mbps';
  String? hintValue = '';
  late AppModel appModel;

  String? selectedValue =
      'iyu3gajuzumj573tdy54sjs7b94fbqpbo3o44msrba4zez1o4p3o.bdx';
  @override
  initState() {
    super.initState();
    _isConnectedEventSubscription = BelnetLib.isConnectedEventStream
        .listen((bool isConnected) => setState(() {}));
    //callForUpdate();
    getRandomExitNodes();
  }

  // callForUpdate() {
  //   Timer.periodic(Duration(milliseconds: 200), (timer) {
  //     getUploadAndDownload();
  //   });
  // }

  getRandomExitNodes() async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    hintValue = preference.getString('hintValue');
    if (BelnetLib.isConnected == false) {
      print(
          "is connected value from getRandomExitNodes ${BelnetLib.isConnected}");
      final random = Random();
      selectedValue = exitItems[random.nextInt(exitItems.length)];
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    _isConnectedEventSubscription?.cancel();
    AwesomeNotifications().dispose();
  }


late bool con;


  Future toggleBelnet() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (BelnetLib.isConnected == false) {
      print('netvalue from disconnected --');
      AwesomeNotifications().dismiss(3);
    }
    bool dismiss = false;
    loading = true;
    setState(() {});
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        loading = false;
      });
    });
    if (mounted) setState(() {});

    if (BelnetLib.isConnected) {
      var disConnectValue = await BelnetLib.disconnectFromBelnet();
      appModel.connecting_belnet = false;
      dismiss = true;
      AwesomeNotifications()
          .dismiss(3); // dismiss the notification when belnet disconnected
    } else {
      //Save the exit node and upstream dns
      final Settings settings = Settings.getInstance()!;
      settings.exitNode = selectedValue!.trim().toString();
      var myVal = selectedValue!.trim().toString();
      preferences.setString('hintValue', myVal);
      hintValue = preferences.getString('hintValue');
      print('hint value is stored from getString $hintValue');
      setState(() {});
      settings.upstreamDNS = '';

      final result = await BelnetLib.prepareConnection();
      if (await BelnetLib.isPrepared) {
        appModel.connecting_belnet = true;
      }
      if (result)
      con =await BelnetLib.connectToBelnet(
            exitNode: settings.exitNode!, upstreamDNS: "");



      if(!con){
      print("connection value is $con");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: Colors.black,
                          content: Text("Exit node could not connected!",style: TextStyle(color:Colors.white),)

    )); 
      }else{

      }



      if (BelnetLib.isConnected) {
        appModel.connecting_belnet = true;
      }

      setState(() {});
      MyNotificationWorkLoad(
        appModel: appModel,
        isLoading: loading,
        function: () {
          setState(() {});
        },
      ).createMyNotification(
        dismiss,
        uploadRate,
        downloadRate,
      );
    }
  }

  var uploadUnit = ' Mbps';
  var downloadUnit = ' Mbps';
  var uploadValue, kb, mb, gb, downloadValue, kb1, mb1, gb1;

  getUploadAndDownload() async {
    if (BelnetLib.isConnected) {
      print('upload speed will be');

      var uploadR = await BelnetLib.upload;
      var downloadR = await BelnetLib.download;
     
     
      Future.delayed(Duration(seconds:1),(){
         appModel.uploads = uploadR;
      appModel.downloads = downloadR;
           setState(() {

        uploadRate = uploadR;
        print('upload displayed from dart side $uploadRate');
        downloadRate = downloadR;
      });
      });
      print("printed after 3seconds");
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

  @override
  Widget build(BuildContext context) {
    appModel = pr.Provider.of<AppModel>(context);
    Color color = appModel.darkTheme ? Color(0xff292937) : Colors.white;
    double mHeight = MediaQuery.of(context).size.height;
    if(BelnetLib.isConnected){
        getUploadAndDownload();
    }
   
    return
        // SingleChildScrollView(
        // child:
        // Scaffold(
        // resizeToAvoidBottomInset: true,
        Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Stack(children: [
                  Positioned(
                    //top:0,
                    child: Container(
                        width: double.infinity,
                        //color:Colors.green,
                        height: mHeight * 1.35 / 3,
                        child: Stack(children: [
                          appModel.darkTheme
                              ? Image.asset(
                                  'assets/images/Map_dark (1).png',
                                )
                              : Image.asset('assets/images/map_white (3).png'),
                          //appModel.connecting_belnet &&
                          BelnetLib.isConnected
                              ? Image.asset(
                                  'assets/images/Map_white_gif (1).gif') //Image.asset('assets/images/Mobile_1.gif')
                              : Container()
                        ])),
                  ),
                  Positioned(
                    top: mHeight * 0.10 / 3,
                    right: mHeight * 0.04 / 3,
                    child: GestureDetector(
                        onTap: () {
                          appModel.darkTheme = !appModel.darkTheme;
                        },
                        child: appModel.darkTheme
                            ? Image.asset('assets/images/dark_theme_4x (2).png',
                                width: mHeight * 0.25 / 3,
                                height: mHeight * 0.25 / 3)
                            : Image.asset(
                                'assets/images/white_theme_4x (3).png',
                                width: mHeight * 0.24 / 3,
                                height: mHeight * 0.24 / 3)),
                  ),
                  Positioned(
                    top: mHeight * 0.40 / 3,
                    left: mHeight * 0.20 / 3,
                    child: ThemedBelnetLogo(
                      model: appModel.darkTheme,
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: mHeight * 0.63 / 3),
                      child: Container(
                        decoration: BoxDecoration(
                            //color:Colors.yellow,
                            shape: BoxShape.circle),
                        child: BelnetPowerButton(
                            onPressed: toggleBelnet,
                            isClick: BelnetLib.isConnected,
                            isLoading: loading),
                      ),
                    ),
                  ),
                ]),
                Padding(
                  padding: EdgeInsets.only(top: 5.0),
                  child: ConnectingStatus(
                    isConnect: BelnetLib.isConnected,
                  ),
                ),
                Row(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.only(left: mHeight * 0.10 / 3, top: 10),
                      child: Text('Exit Node',
                          style: TextStyle(
                              color: appModel.darkTheme
                                  ? Colors.white
                                  : Colors.black,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w900,
                              fontSize: mHeight * 0.05 / 3)),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(
                      left: mHeight * 0.08 / 3,
                      right: mHeight * 0.10 / 3,
                      top: mHeight * 0.03 / 3),
                  child: BelnetLib.isConnected
                      ? Container(
                          height: mHeight * 0.16 / 3,
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5))),
                          child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 4.0, right: 6.0, top: 3.0, bottom: 5.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                      child: Center(
                                    child: Text('$hintValue',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                            color: Color(0xff00DC00))),
                                  )),
                                  Container(
                                      child: Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ))
                                ],
                              )))
                      : Container(
                          height: mHeight * 0.16 / 3,
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5))),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 0.0, right: 6.0, top: 3.0, bottom: 5.0),
                            child: CustDropDown(
                              maxListHeight: 120,
                              items: exitItems
                                  .map((e) => CustDropdownMenuItem(
                                      value: e,
                                      child: Center(
                                          child: Text(
                                        '$e',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style:
                                            TextStyle(color: Color(0xff00DC00)),
                                      ))))
                                  .toList(),
                              hintText: "$selectedValue",
                              borderRadius: 5,
                              onChanged: (val) {
                                print(val);
                                setState(() {
                                  selectedValue = val;
                                });
                              },
                              appModel: appModel,
                            ),
                          ),
                        ),
                ),

                Padding(
                  padding: EdgeInsets.only(
                      left: mHeight * 0.08 / 3,
                      right: mHeight * 0.10 / 3,
                      top: mHeight * 0.03 / 3),
                  child: BelnetLib.isConnected
                      ? Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            color: Colors.grey,
                           boxShadow: appModel.darkTheme
                            ? [
                                // BoxShadow(
                                //     color: Colors.black12,
                                //     offset: Offset(-10, -10),
                                //     spreadRadius: 0,
                                //     blurRadius: 10),
                                BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(0, 1),
                                    blurRadius: 2.0)
                              ]
                            : [
                                BoxShadow(
                                    color: Color(0xff6E6E6E),
                                    offset: Offset(0, 1),
                                    blurRadius: 2.0)
                              ],
                            border: Border.all(
                              color: Color(0xffA1A1C1).withOpacity(0.1),
                            ),
                            gradient: LinearGradient(
                                colors: appModel.darkTheme
                                    ? [Color(0xff20202B), Color(0xff2C2C39)]
                                    : [Color(0xffF2F0F0), Color(0xffFAFAFA)]),
                            //               boxShadow: [
                            //                 BoxShadow(
                            //                 color: Colors.grey.shade600,
                            // blurRadius: 10.0,
                            // spreadRadius: 0.1,
                            // offset: Offset(
                            //  4.0,4.0
                            // )
                            //               ),
                            //               BoxShadow(
                            //                 color: Colors.white,
                            // blurRadius: 10.0,
                            // spreadRadius: 0.1,
                            // offset: Offset(
                            //  -4.0,-4.0
                            // )
                            //               )

                            //               ],
                          ),
                          height: MediaQuery.of(context).size.height * 0.18 / 3,
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/images/Add.svg',
                                color: Color(0xff56566F),
                                height: MediaQuery.of(context).size.height *
                                    0.05 /
                                    3,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 5.0),
                                child: Text(
                                  "Add Exit Node",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                              0.05 /
                                              3,
                                      color: Color(0xff56566F),
                                      fontFamily: "Poppins",
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ))

                      // :
                      //  Container()
                      : GestureDetector(
                          onTap: () {
                            showDialog(
                                useSafeArea: false,
                                // barrierColor: Colors.orange,
                                context: context,
                                builder: (BuildContext dcontext) => Padding(
                                      padding: const EdgeInsets.all(0.0),
                                      child: AlertDialog(
                                        scrollable: true,
                                        backgroundColor: Colors.transparent,
                                        contentPadding: EdgeInsets.all(0.0),
                                        //insetPadding: EdgeInsets.all(8.0),
                                        //clipBehavior: Clip.antiAliasWithSaveLayer,
                                        content: containerWidget(dcontext),
                                      ),
                                    ));

                            // Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //         builder: (context) =>
                            //             ShowModelDialogbox()));
                            // showCustomExitNodeDialogBox(context,);
                          },
                          child: Container(
                              padding: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  color: Colors.grey,
                                  gradient: LinearGradient(colors: [
                                    Color(0xff00B504),
                                    Color(0xff23DC27)
                                  ])),
                              height:
                                  MediaQuery.of(context).size.height * 0.18 / 3,
                              width: double.infinity,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/Add.svg',
                                    height: MediaQuery.of(context).size.height *
                                        0.05 /
                                        3,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 5.0),
                                    child: Text(
                                      "Add Exit Node",
                                      style: TextStyle(
                                          fontFamily: "Poppins",
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              )),
                        ),
                ),
              SizedBox(height:mHeight*0.05/3,)
                //Spacer(),
              ],
            ),

            Positioned(
              top: MediaQuery.of(context).size.height * 1.2 / 3,
              left: 5,
              right: 5,
              child: Container(
                  padding: EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/images/download_white_theme.svg',
                            height: 9,
                            width: 9,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text(
                              'Download',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Poppins',
                                  color: appModel.darkTheme
                                      ? Color(0xffA1A1C1)
                                      : Colors.black),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Text(
                              'Upload',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Poppins',
                                  color: appModel.darkTheme
                                      ? Color(0xffA1A1C1)
                                      : Colors.black),
                            ),
                          ),
                          SvgPicture.asset(
                            'assets/images/upload_white_theme.svg',
                            height: 9,
                            width: 9,
                          ),
                        ],
                      ),
                    ],
                  )),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 1.25 / 3,
              left: 5,
              right: 5,
              child: Container(
                  padding: EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Row(
                      //   children: [
                      RichText(
                          text: TextSpan(
                              text: downloadRate == ''
                                  ? '00.00'
                                  : BelnetLib.isConnected
                                      ? '${stringBeforeSpace(downloadRate)}'
                                      : '00.00',
                              style: TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Poppins',
                                  color: appModel.darkTheme
                                      ? Color(0xffA1A1C1)
                                      : Colors.black),
                              children: [
                            TextSpan(
                                text: downloadRate == ''
                                    ? ' Mbps'
                                    : ' ${stringAfterSpace(downloadRate)}',
                                style: TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w100,
                                    fontFamily: 'Poppins',
                                    color: appModel.darkTheme
                                        ? Color(0xffA1A1C1)
                                        : Colors.black))
                          ])),

                      RichText(
                          text: TextSpan(
                              text: uploadRate == ''
                                  ? '00.00'
                                  : BelnetLib.isConnected
                                      ? '${stringBeforeSpace(uploadRate)}'
                                      : '00.00',
                              style: TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Poppins',
                                  color: appModel.darkTheme
                                      ? Color(0xffA1A1C1)
                                      : Colors.black),
                              children: [
                            TextSpan(
                                text: uploadRate == ''
                                    ? ' Mbps'
                                    : ' ${stringAfterSpace(uploadRate)}',
                                style: TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w100,
                                    fontFamily: 'Poppins',
                                    color: appModel.darkTheme
                                        ? Color(0xffA1A1C1)
                                        : Colors.black))
                          ])),

                      //   ],
                      // ),
                    ],
                  )),
            )

            // Positioned(
            //   top: MediaQuery.of(context).size.height*1.2/3,
            //   left: 5, right: 5,
            //   // top:MediaQuery.of(context).size.height*1/3,
            //
            //   child: Container(
            //     padding: EdgeInsets.only(left: 8.0, right: 8.0),
            //     // color: Colors.yellow,
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       children: [
            //         Column(
            //           children: [
            //             Row(
            //               children: [
            //                 SvgPicture.asset(
            //                   'assets/images/download_white_theme.svg',
            //                   height: 9,
            //                   width: 9,
            //                 ),
            //                 Padding(
            //                   padding: const EdgeInsets.only(left: 4.0),
            //                   child: Text(
            //                     'Download',
            //                     style: TextStyle(
            //                         fontSize: 11,
            //                         fontFamily: 'Poppins',
            //                         color: appModel.darkTheme
            //                             ? Color(0xffA1A1C1)
            //                             : Colors.black),
            //                   ),
            //                 ),
            //               ],
            //             ),
            //             RichText(
            //                 text: TextSpan(
            //                     text: downloadRate == ''
            //                         ? '0.00'
            //                         : BelnetLib.isConnected
            //                             ? '${stringBeforeSpace(downloadRate)}'
            //                             : '0.00',
            //                     style: TextStyle(
            //                         fontSize: 15.0,
            //                         fontWeight: FontWeight.w900,
            //                         fontFamily: 'Poppins',
            //                         color: appModel.darkTheme
            //                             ? Color(0xffA1A1C1)
            //                             : Colors.black),
            //                     children: [
            //                   TextSpan(
            //                       text: downloadRate == '' ? ' MBps' : ' ${stringAfterSpace(downloadRate)}',
            //                       style: TextStyle(
            //                           fontSize: 11.0,
            //                           fontWeight: FontWeight.w100,
            //                           fontFamily: 'Poppins',
            //                           color: appModel.darkTheme
            //                               ? Color(0xffA1A1C1)
            //                               : Colors.black))
            //                 ])),
            //           ],
            //         ),
            //         Column(
            //           children: [
            //             Row(
            //               children: [
            //                 Padding(
            //                   padding: const EdgeInsets.only(right: 4.0),
            //                   child: Text(
            //                     'Upload',
            //                     style: TextStyle(
            //                         fontSize: 11,
            //                         fontFamily: 'Poppins',
            //                         color: appModel.darkTheme
            //                             ? Color(0xffA1A1C1)
            //                             : Colors.black),
            //                   ),
            //                 ),
            //                 SvgPicture.asset(
            //                   'assets/images/upload_white_theme.svg',
            //                   height: 9,
            //                   width: 9,
            //                 ),
            //               ],
            //             ),
            //             RichText(
            //                 text: TextSpan(
            //                     text: uploadRate == ''
            //                         ? '0.00'
            //                         : BelnetLib.isConnected
            //                             ? '${stringBeforeSpace(uploadRate)}'
            //                             : '0.00',
            //                     style: TextStyle(
            //                         fontSize: 15.0,
            //                         fontWeight: FontWeight.w900,
            //                         fontFamily: 'Poppins',
            //                         color: appModel.darkTheme
            //                             ? Color(0xffA1A1C1)
            //                             : Colors.black),
            //                     children: [
            //                   TextSpan(
            //                       text: uploadRate == '' ? ' MBps' : ' ${stringAfterSpace(uploadRate)}',
            //                       style: TextStyle(
            //                           fontSize: 11.0,
            //                           fontWeight: FontWeight.w100,
            //                           fontFamily: 'Poppins',
            //                           color: appModel.darkTheme
            //                               ? Color(0xffA1A1C1)
            //                               : Colors.black))
            //                 ])),
            //             // SizedBox(
            //             //   height: 20,
            //             // ),
            //           ],
            //         )
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),

        Flexible(
          child: Container(
              width: double.infinity,
              // color: Colors.orange,
              child: BottomNavBarOptions()),
        )
        // Container(
        //     height: mHeight * 0.20 / 3,
        //     child: Center(
        //         child: Text(
        //       'v0.0.1',
        //       style: TextStyle(color: Color(0xffA8A8B7)),
        //     ))),
      ],
    );
    //);
    //);
  }

  var invalidExit = "";
  var invalidAuth = "";

  TextEditingController _cusExitNode = TextEditingController();
  TextEditingController _cusAuthCode = TextEditingController();

  var textForExit;
  var textForAuth;
  var isSet = false;
  var color = "blue";
  Widget containerWidget(BuildContext dcontext) {
    bool isAuthCode = false;
    return StatefulBuilder(builder: (dcontext, StateSetter setState) {
      return Container(
        padding: EdgeInsets.all(15.0),
        height: MediaQuery.of(dcontext).size.height * 1.63 / 3,
        // width: MediaQuery.of(dcontext).size.width * 2 / 3,
        decoration: BoxDecoration(
          color: appModel.darkTheme ? Color(0xff1C1C26) : Color(0xffF5F5F5),
          border: Border.all(color: Color(0xff707070).withOpacity(0.4)),
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  EdgeInsets.only(left: 5.0, right: 5.0, top: 4.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Container(
                      // color: Colors.orange,
                      child: Stack(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Center(
                                  child: Text(
                                "Add Exit Node",
                                style: TextStyle(
                                    color: appModel.darkTheme
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize:
                                        MediaQuery.of(dcontext).size.height *
                                            0.062 /
                                            3,
                                    fontFamily: "Poppins"),
                              )),
                            ],
                          ),
                          Positioned(
                            right: 0.0,
                            bottom: 0.3,
                            child: Container(
                              padding: EdgeInsets.only(top: 8.0),
                              width:
                                  MediaQuery.of(context).size.width * 0.16 / 3,
                              child: GestureDetector(
                                  onTap: () {
                                    invalidExit = "";
                                    invalidAuth = "";

                                    // _cusExitNode.dispose();
                                    // _cusAuthCode.dispose();

                                    textForExit = null;
                                    //textForAuth = null;
                                    isSet = false;
                                    color = "blue";

                                    Navigator.pop(dcontext);

                                    // Navigator.
                                  },
                                  child: SvgPicture.asset(
                                    'assets/images/close.svg',
                                    color: appModel.darkTheme
                                        ? Colors.white
                                        : Colors.black,
                                  )),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.end,
                  //   children: [
                  //     //Flexible(child: Container()),

                  //   ],
                  // )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text(
                'Exit Node',
                style: TextStyle(
                    color: appModel.darkTheme ? Colors.white : Colors.black,
                    fontSize: MediaQuery.of(dcontext).size.height * 0.06 / 3,
                    fontWeight: FontWeight.w900,
                    fontFamily: "Poppins"),
              ),
            ),
            Container(
              height: MediaQuery.of(dcontext).size.height * 0.18 / 3,
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                  color: appModel.darkTheme ? Color(0xff292937) : Colors.white,
                  //boxShadow: [

                  //  BoxShadow(
                  //             color: Colors.white,
                  //             offset: Offset(-10, -10),
                  //             blurRadius: 20,
                  //             spreadRadius: 0),
                  //         // BoxShadow(
                  //         //     color: Color(0xff6E6E6E),
                  //         //     offset: Offset(-10, -10),
                  //         //     blurRadius: 20,
                  //         //     spreadRadius: 0)
                  //           ],
                  borderRadius: BorderRadius.circular(5.0)),
              child: TextFormField(
                style: TextStyle(color: Color(0xff00DC00)),
                controller: _cusExitNode,
                decoration: InputDecoration(border: InputBorder.none),
                validator: (value) {
                  setState(() {});
                },
                onChanged: (value) {
                  if (_cusExitNode.text == null || _cusExitNode.text == "") {
                    setState(() {});
                    isSet = false;
                  }
                },
              ),
            ),
            Container(
                height: MediaQuery.of(dcontext).size.height * 0.10 / 3,
                //color:Colors.orange,
                child: Center(
                    child: Text(
                  textForExit == null ? " " : '$textForExit',
                  style: TextStyle(
                      fontSize: MediaQuery.of(dcontext).size.height * 0.05 / 3,
                      color: Color(0xffFF3333),
                      fontFamily: "Poppins"),
                ))),
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text(
                'Auth Code',
                style: TextStyle(
                    color: isAuthCode
                        ? appModel.darkTheme
                            ? Colors.white
                            : Colors.black
                        : Color(0xff38384D),
                    fontSize: MediaQuery.of(dcontext).size.height * 0.06 / 3,
                    fontWeight: FontWeight.w900,
                    fontFamily: "Poppins"),
              ),
            ),
            Container(
              height: MediaQuery.of(dcontext).size.height * 0.18 / 3,
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                  color: appModel.darkTheme ? Color(0xff292937) : Colors.white,
                  borderRadius: BorderRadius.circular(5.0)),
              child: isAuthCode
                  ? TextFormField(
                      controller: _cusAuthCode,
                      style: TextStyle(color: Color(0xff1994FC)),
                      decoration: InputDecoration(border: InputBorder.none),
                    )
                  : Container(),
            ),
            Container(
                height: MediaQuery.of(dcontext).size.height * 0.10 / 3,
                // color:Colors.orange,
                child: Center(
                    child: Text(
                  textForAuth == null ? " " : '$textForAuth',
                  style: TextStyle(
                      fontSize: MediaQuery.of(dcontext).size.height * 0.05 / 3,
                      color: Color(0xffFF3333),
                      fontFamily: "Poppins"),
                ))),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10.0, right: 8.0),
                  child: Text(
                    'Auth Code',
                    style: TextStyle(
                        color: appModel.darkTheme ? Colors.white : Colors.black,
                        fontSize:
                            MediaQuery.of(dcontext).size.height * 0.06 / 3,
                        fontWeight: FontWeight.w900,
                        fontFamily: "Poppins"),
                  ),
                ),
                GestureDetector(
                    onTap: () {
                      setState(() {
                        isAuthCode = isAuthCode ? false : true;
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
              ],
            ),
            GestureDetector(
              onTap: () {
                print('test button clicked');
                if (_cusExitNode.text == null || _cusExitNode.text == "") {
                  setState(() {
                    textForExit = "ExitNode should not be empty";
                    color = "red";
                  });
                } else if (_cusExitNode.text.isNotEmpty &&
                    !_cusExitNode.text.contains(".bdx")) {
                  setState(() {
                    textForExit = "Please enter a valid Exit Node";
                    print(
                        "is contain method call ${!_cusExitNode.text.contains(".bdx")}");
                    color = "red";
                  });
                } else {
                  setState(() {
                    textForExit = null;
                    isSet = true;
                    color = "green";
                  });
                }

                print("isSet value $isSet");
                // if(_cusAuthCode.text.isNotEmpty)
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.grey,
                        gradient: color == "blue"
                            ? LinearGradient(
                                colors: [Color(0xff007ED1), Color(0xff0093FF)])
                            : color == "red"
                                ? LinearGradient(colors: [
                                    Color(0xffE50012),
                                    Color(0xffFF1A23)
                                  ])
                                : color == "green"
                                    ? LinearGradient(colors: [
                                        Color(0xff00B504),
                                        Color(0xff23DC27)
                                      ])
                                    : LinearGradient(colors: []),
                        boxShadow: appModel.darkTheme
                            ? [
                                // BoxShadow(
                                //     color: Colors.black12,
                                //     offset: Offset(-10, -10),
                                //     spreadRadius: 0,
                                //     blurRadius: 10),
                                BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(0, 1),
                                    blurRadius: 2.0)
                              ]
                            : [
                                BoxShadow(
                                    color: Color(0xff6E6E6E),
                                    offset: Offset(0, 1),
                                    blurRadius: 2.0)
                              ]),
                    height: MediaQuery.of(dcontext).size.height * 0.18 / 3,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        color == "red"
                            ? SvgPicture.asset(
                                'assets/images/icons8-error.svg',
                                height: MediaQuery.of(dcontext).size.height *
                                    0.05 /
                                    3,
                              )
                            : color == "green"
                                ? SvgPicture.asset(
                                    'assets/images/icons8-error.svg',
                                    height:
                                        MediaQuery.of(dcontext).size.height *
                                            0.05 /
                                            3,
                                  )
                                : Container(),
                        Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: Text(
                            "Test",
                            style: TextStyle(
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: GestureDetector(
                onTap: () {
                  if (isSet) {
                    setState(() {
                      print("Simply clicked");

                      exitItems.insert(0, _cusExitNode.text);

                      invalidExit = "";
                      invalidAuth = "";

                      // _cusExitNode.dispose();
                      // _cusAuthCode.dispose();

                      textForExit = null;
                      //textForAuth = null;
                      isSet = false;
                      color = "blue";
                    });
                    Navigator.pop(dcontext);
                  }
                },
                child: Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.grey,
                        gradient: appModel.darkTheme
                            ? isSet
                                ? LinearGradient(colors: [
                                    Color(0xff007ED1),
                                    Color(0xff0093FF)
                                  ])
                                : LinearGradient(colors: [
                                    Color(0xff20202B),
                                    Color(0xff2C2C39)
                                  ])
                            : isSet
                                ? LinearGradient(colors: [
                                    Color(0xff007ED1),
                                    Color(0xff0093FF)
                                  ])
                                : LinearGradient(colors: [
                                    Color(0xffF2F0F0),
                                    Color(0xffFAFAFA)
                                  ]),
                        // border: Border.all(color:Color(0xff56566F)),
                        boxShadow: [
                          appModel.darkTheme
                              ? BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(0, 1),
                                  //spreadRadius: 0,
                                  blurRadius: 2.0)
                              : BoxShadow(
                                  color: Color(0xff6E6E6E),
                                  offset: Offset(0, 1),
                                  blurRadius: 2.0)
                        ]),
                    height: MediaQuery.of(dcontext).size.height * 0.18 / 3,
                    width: double.infinity,
                    child: Center(
                        child: Text(
                      "OK",
                      style: TextStyle(
                          color: isSet ? Colors.white : Color(0xff56566F),
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w900),
                    ))
                    // Image.asset(
                    //   'assets/images/ok.png',
                    //   fit: BoxFit.cover,
                    // ),
                    ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// if there is no internet, this page only displays when there is no inter
class NoInternetConnection extends StatelessWidget {
  const NoInternetConnection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appModel = pr.Provider.of<AppModel>(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: appModel.darkTheme
              ? [
                  Color(0xFF242430),
                  Color(0xFF1C1C26),
                ]
              : [
                  Color(0xFFF9F9F9),
                  Color(0xFFEBEBEB),
                ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.40 / 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                    height: MediaQuery.of(context).size.height * 1 / 3,
                    width: MediaQuery.of(context).size.width * 1.3 / 3,
                    child: SvgPicture.asset(
                        'assets/images/icons8-wi-fi_disconnected (1).svg',
                        color: appModel.darkTheme
                            ? Color(0xff4D4D64)
                            : Color(0xffC7C7C7),
                        height: MediaQuery.of(context).size.height * 0.20 / 3)),
                Container(
                  padding: EdgeInsets.only(
                    left: 15.0,
                    right: 15.0,
                  ),
                  child: Center(
                    child: Text(
                      'No internet connection.',
                      style: TextStyle(
                          color: appModel.darkTheme
                              ? Color(0xffA1A1C1)
                              : Color(0xff56566F),
                          fontWeight: FontWeight.w900,
                          fontSize:
                              MediaQuery.of(context).size.height * 0.08 / 3,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                ),
                Container(
                    //color: Colors.green,
                    padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.height * 0.14 / 3,
                        right: MediaQuery.of(context).size.height * 0.14 / 3,
                        top: 5.0),
                    child: Center(
                        child: Text(
                            'You are not connected to the internet. Make sure WiFi/Mobile data is on.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: appModel.darkTheme
                                    ? Color(0xffA1A1C1)
                                    : Color(0xff56566F),
                                fontFamily: 'Poppins')))),
                Spacer(),
                Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height * 0.35 / 3),
                  child: Container(
                      height: MediaQuery.of(context).size.height * 0.20 / 3,
                      width: MediaQuery.of(context).size.height * 0.70 / 3,
                      decoration: BoxDecoration(
                          color: Color(0xff00DC00),
                          borderRadius: BorderRadius.all(Radius.circular(18.0)),
                          border:
                              Border.all(color: Color(0xff00DC00), width: 2)),
                      child: TextButton(
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize:
                                MediaQuery.of(context).size.height * 0.07 / 3,
                            // fontWeight: FontWeight.w900
                          ),
                        ),
                        onPressed: () {},
                      )),
                )
              ],
            )),
      ),
    );
  }
}



var pageIndex = 0;

class BottomNavBarOptions extends StatefulWidget {
  const BottomNavBarOptions({Key? key}) : super(key: key);

  @override
  State<BottomNavBarOptions> createState() => _BottomNavBarOptionsState();
}

class _BottomNavBarOptionsState extends State<BottomNavBarOptions> {
  Widget getBody() {
    List<Widget> pages = [
      LiveChart(
        upData: uploadRate,
        downData: downloadRate,
      ),
      DisplayLog()
    ];
    return IndexedStack(
      index: pageIndex,
      children: pages,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appModel = pr.Provider.of<AppModel>(context);
    return Scaffold(
        backgroundColor:
            appModel.darkTheme ? Color(0xFF1C1C26) : Color(0xFFEBEBEB),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: appModel.darkTheme
                  ? [
                      Color(0xFF242430),
                      Color(0xFF1C1C26),
                    ]
                  : [
                      Color(0xFFF9F9F9),
                      Color(0xFFEBEBEB),
                    ],
            ),
          ),
          child: getBody(),
        ),
        bottomNavigationBar: Container(
            height: MediaQuery.of(context).size.height * 0.18 / 3,
            decoration: BoxDecoration(
              color: appModel.darkTheme ? Color(0xff272734) : Color(0xffF8F8F8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      pageIndex = 0;
                    });
                  },
                  child: Row(
                    //mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: SvgPicture.asset(
                          'assets/images/chart (1).svg',
                          color: pageIndex == 0
                              ? Color(0xff1DC021)
                              : Color(0xffA1A1C1),
                          height: MediaQuery.of(context).size.height * 0.06 / 3,
                        ),
                      ),
                      Text(
                        'Chart',
                        style: TextStyle(
                            color: pageIndex == 0
                                ? Color(0xff1DC021)
                                : Color(0xffA1A1C1),
                            fontWeight: pageIndex == 0
                                ? FontWeight.w900
                                : FontWeight.normal,
                            fontFamily: "poppins"),
                      )
                    ],
                  ),
                ),
                VerticalDivider(
                  color: appModel.darkTheme ? Colors.black : Color(0xffA1A1C1),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      pageIndex = 1;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: SvgPicture.asset(
                          'assets/images/Log.svg',
                          color: pageIndex == 1
                              ? Color(0xff1DC021)
                              : Color(0xffA1A1C1),
                          height: MediaQuery.of(context).size.height * 0.05 / 3,
                        ),
                      ),
                      Text(
                        'Log',
                        style: TextStyle(
                            color: pageIndex == 1
                                ? Color(0xff1DC021)
                                : Color(0xffA1A1C1),
                            fontWeight: pageIndex == 1
                                ? FontWeight.w900
                                : FontWeight.normal,
                            fontFamily: "poppins"),
                      )
                    ],
                  ),
                )
              ],
            ))

        //  BottomNavigationBar(items: [
        //   BottomNavigationBarItem(
        //     label: "",
        //     icon: Row(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //       SvgPicture.asset('assets/images/chart (1).svg',height: MediaQuery.of(context).,),
        //       Text('Chart')
        //     ],)
        //     ),

        //     BottomNavigationBarItem(
        //       label: "",
        //     icon: Row(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //      // SvgPicture.asset('assets/images/chart (1).svg'),
        //       Text('Log')
        //     ],)
        //     )
        //  ])
        //  Container(
        //   color: Colors.white,
        //   width:double.infinity,
        //   height:45),
        );
  }
}
