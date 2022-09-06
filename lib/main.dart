import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/splash_screen.dart';
import 'package:belnet_mobile/src/utils/styles.dart';
import 'package:belnet_mobile/src/widget/connecting_status.dart';
import 'package:belnet_mobile/src/widget/exit_node_list.dart';
import 'package:belnet_mobile/src/widget/network_connectivity.dart';
import 'package:belnet_mobile/src/widget/notifications.dart';
import 'package:flutter/material.dart';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/settings.dart';
import 'package:belnet_mobile/src/widget/belnet_power_button.dart';
import 'package:belnet_mobile/src/widget/themed_belnet_logo.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
//import 'package:new_version/new_version.dart';
import 'package:provider/provider.dart';

//Global variables
// final exitInput = TextEditingController(text: Settings.getInstance()!.exitNode);
// final dnsInput =
//    TextEditingController(text: Settings.getInstance()!.upstreamDNS);

bool isClick = false;
bool loading = false;
void main() async {
  //Load settings
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.getInstance()!.initialize();
  Provider.debugCheckInvalidValueType = null;
  AwesomeNotifications()
      .initialize('resource://drawable/res_notification_app_icon', [
    NotificationChannel(
        channelKey: 'basic_channel',
        channelDescription: '',
        channelName: 'basic notifications',
        defaultColor: Colors.teal,
        importance: NotificationImportance.High,
        locked: true,
        defaultPrivacy: NotificationPrivacy.Public
    )
  ]);
  runApp(BelnetApp());
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
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack, overlays: [SystemUiOverlay.top]);
    _initAppTheme();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppModel>.value(value: appModel),
        StreamProvider(
            create: (context) => NetworkService().controller.stream,
            initialData: NetworkStatus.connected)
      ],
      child: Consumer<AppModel>(builder: (context, value, child) {
        return MaterialApp(
            title: 'Belnet App',
            debugShowCheckedModeBanner: false,
            theme: appModel.darkTheme ? buildDarkTheme() : buildLightTheme(),
            home: SplashScreens() //BelnetHomePage(),
            );
      }),
    );

    // return ChangeNotifierProvider<AppModel>.value(
    //   value: appModel,
    //   child: Consumer<AppModel>(builder: (context, value, child) {
    //     return MaterialApp(
    //         title: 'Belnet App',
    //         debugShowCheckedModeBanner: false,
    //         theme: appModel.darkTheme ? buildDarkTheme() : buildLightTheme(),
    //         home: SplashScreens() //BelnetHomePage(),
    //         );
    //   }),
    // );
  }
}

class BelnetHomePage extends StatefulWidget {
  BelnetHomePage({Key? key}) : super(key: key);

  @override
  BelnetHomePageState createState() => BelnetHomePageState();
}

class BelnetHomePageState extends State<BelnetHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController lottieController;

  @override
  void initState() {
    // final newVersion = NewVersion(
    //   androidId:'io.beldex.belnet',
    // );
    //
    // // You can let the plugin handle fetching the status and showing a dialog,
    // // or you can fetch the status and display your own dialog, or no dialog.
    // const simpleBehavior = true;
    //
    // if (simpleBehavior) {
    //   basicStatusCheck(newVersion);
    // } else {
    //   advancedStatusCheck(newVersion);
    // }
    super.initState();
  }

  // basicStatusCheck(NewVersion newVersion) {
  //   newVersion.showAlertIfNecessary(context: context);
  // }
  // advancedStatusCheck(NewVersion newVersion) async {
  //   final status = await newVersion.getVersionStatus();
  //
  //   if (status != null) {
  //     debugPrint(status.releaseNotes);
  //     debugPrint(status.appStoreLink);
  //     debugPrint(status.localVersion);
  //     debugPrint(status.storeVersion);
  //     debugPrint(status.canUpdate.toString());
  //     newVersion.showUpdateDialog(
  //       context: context,
  //       versionStatus: status,
  //       dialogTitle: 'App update available',
  //       dialogText: 'Update your app from ${status.localVersion} to ${status.storeVersion}',
  //     );
  //   }
  // }



  @override
  void dispose() {
    lottieController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    double mHeight = MediaQuery.of(context).size.height;
    final appModel = Provider.of<AppModel>(context);
    final networkStatus = Provider.of<NetworkStatus>(context);
    return networkStatus == NetworkStatus.disconnected
        ? NoInternetConnection()
        : Container(
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
              //key: key,
              resizeToAvoidBottomInset:
                  true, //Prevents overflow when keyboard is shown
              body: Container(
                // color: appModel.darkTheme ? Color(0xff242430) : Color(0xffF9F9F9),
                child: Stack(
                  children: [
                    Container(
                        width: double.infinity,
                        //color:Colors.green,
                        height: mHeight * 1.35 / 3,
                        child: Stack(children: [
                          appModel.darkTheme
                              ? Image.asset(
                                  'assets/images/Map_dark (1).png',
                                )
                              : Image.asset('assets/images/map_white (3).png'),
                          appModel.connecting_belnet
                              ? Image.asset(
                                  'assets/images/Map_white_gif (1).gif') //Image.asset('assets/images/Mobile_1.gif')
                              : Container()
                        ])),
                    Positioned(
                      top: mHeight * 0.09 / 3,
                      right: mHeight * 0.03 / 3,
                      child: GestureDetector(
                        onTap: () {
                          appModel.darkTheme = !appModel.darkTheme;
                        },
                        child: appModel.darkTheme
                            ?  SvgPicture.asset('assets/images/dark_theme.svg')  // Image.asset('assets/images/dark_theme_4x (1).png',)//dark_themess.png
                            :  SvgPicture.asset('assets/images/light_theme.svg'), //Image.asset('assets/images/white_theme_4x (1).png') //white_themess.png
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.40 / 3,
                      left: MediaQuery.of(context).size.height * 0.20 / 3,
                      child: ThemedBelnetLogo(
                        model: appModel.darkTheme,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 0),
                      // top:mHeight * 0.20 / 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MyForm(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}

// Create a Form widget.
class MyForm extends StatefulWidget {
  @override
  MyFormState createState() {
    return MyFormState();
  }
}

class MyFormState extends State<MyForm> with SingleTickerProviderStateMixin {
  static final key = new GlobalKey<FormState>();
  StreamSubscription<bool>? _isConnectedEventSubscription;

  late AppModel appModel;
  final List<String> exitItems = [
    'br5i6rsr9yg97kbnsxrqe47cbgknbfdxbmnt7ubjejt485zw4ggy.bdx',
    '7a4cpzri7qgqen9a3g3hgfjrijt9337qb19rhcdmx5y7yttak33o.bdx',
    'n8a8y1i5jo74i5trc81tagagah4cy5xy3m1iowyr68kn3pfa5jgo.bdx',
     'Custom'
  ];
  var _textCustomController = TextEditingController();
  String? selectedValue =
      'br5i6rsr9yg97kbnsxrqe47cbgknbfdxbmnt7ubjejt485zw4ggy.bdx';
  @override
  initState() {
    super.initState();
    _isConnectedEventSubscription = BelnetLib.isConnectedEventStream
        .listen((bool isConnected) => setState(() {}));
  }

  @override
  void dispose() {
    // _animationController.dispose();
    super.dispose();
    _isConnectedEventSubscription?.cancel();
  }

  Future toggleBelnet() async {
    if(selectedValue == 'Custom'){
      setState(() {
        selectedValue = _textCustomController.value.text;
      });
    }
    bool dismiss = false;
    //  isClick = isClick ? false : true;
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
     print('is disconnect ? $disConnectValue' );
      appModel.connecting_belnet = false;
      dismiss = true;
      AwesomeNotifications()
          .dismiss(3); // dismiss the notification when belnet disconnected
    } else {
      //Save the exit node and upstream dns
      final Settings settings = Settings.getInstance()!;
      settings.exitNode =
          selectedValue!.trim().toString(); //exitInput.value.text.trim();
      settings.upstreamDNS = ''; //dnsInput.value.text.trim();

      final result = await BelnetLib.prepareConnection();
      // appModel.connecting_belnet = true;
      if (await BelnetLib.isPrepared) {
        appModel.connecting_belnet = true;
      }
      if (result)
        BelnetLib.connectToBelnet(
            exitNode: settings.exitNode!, upstreamDNS: "");

      setState(() {});
      if (BelnetLib.isConnected) {
        appModel.connecting_belnet = true;
      }

      MyNotificationWorkLoad(
        appModel: appModel,
      ).createMyNotification(dismiss);
    }
  }

  @override
  Widget build(BuildContext context) {
    //String val = 'test ';
    appModel = Provider.of<AppModel>(context);
    Color color = appModel.darkTheme ? Color(0xff292937) : Colors.white;
    double mHeight = MediaQuery.of(context).size.height;
    return
       Column(
        mainAxisAlignment: MainAxisAlignment.center,
        // crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: mHeight * 0.01 / 3),
            child: Container(
              //color:Colors.yellow,
              child: BelnetPowerButton(
                  onPressed: toggleBelnet,
                  isClick: BelnetLib.isConnected,
                  isLoading: loading),
            ),
          ),
         selectedValue == 'Custom' ? SizedBox.shrink() : Padding(
            padding: EdgeInsets.only(top: mHeight * 0.10 / 3),
            child: ConnectingStatus(
              isConnect: BelnetLib.isConnected,
            ),
          ),
          Row(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    left: mHeight * 0.10 / 3, top: mHeight * 0.15 / 3),
                child: Text('Exit Node',
                    style: TextStyle(
                        color: appModel.darkTheme ? Colors.white : Colors.black,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        fontSize: mHeight * 0.06 / 3)),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
                left: MediaQuery.of(context).size.height * 0.08 / 3,
                right: MediaQuery.of(context).size.height * 0.10 / 3,
                top: MediaQuery.of(context).size.height * 0.06 / 3),
            child:
            BelnetLib.isConnected
                ? Container(
                    height: mHeight * 0.20 / 3,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.all(Radius.circular(5))),
                    child: Padding(
                        padding: const EdgeInsets.only(
                            left: 4.0, right: 6.0, top: 3.0, bottom: 5.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                                child: Text('$selectedValue',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(color: Color(0xff00DC00)))),
                            Container(child: Icon(Icons.arrow_drop_down))
                          ],
                        )))
                : selectedValue == "Custom" ?
            Container(
                height: mHeight * 0.20 / 3,
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                child: Padding(
                    padding: const EdgeInsets.only(
                        left: 4.0, right: 6.0, top: 3.0, bottom: 5.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            child: TextField(
                              controller: _textCustomController,
                              //maxLength: 200,
                              //autofocus: true ,
                              style: TextStyle(color:Color(0xff00DC00)),
                              decoration: InputDecoration(
                                border: InputBorder.none,

                              ),
                              // onChanged: (value){
                              //   setState(() {
                              //     selectedValue = value;
                              //   });
                              // },
                            )
                        ),
                        Container(child: IconButton(icon:Icon(Icons.close),
                          onPressed: (){
                          setState(() {

                          });
                            selectedValue = "br5i6rsr9yg97kbnsxrqe47cbgknbfdxbmnt7ubjejt485zw4ggy.bdx";
                        }, ))
                      ],
                    )))
            :Container(
                    height: mHeight * 0.20 / 3,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.all(Radius.circular(5))),
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
                                  style: TextStyle(color: Color(0xff00DC00)),
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
            // BelnetLib.isConnected
            //     ? Container(
            //         height: mHeight * 0.20 / 3,
            //         decoration: BoxDecoration(
            //             color: color,
            //             borderRadius: BorderRadius.all(Radius.circular(5))),
            //         child: Padding(
            //             padding: const EdgeInsets.only(
            //                 left: 4.0, right: 6.0, top: 3.0, bottom: 5.0),
            //             child: Row(
            //               crossAxisAlignment: CrossAxisAlignment.center,
            //               children: [
            //                 Expanded(
            //                     child: Text('$selectedValue',
            //                         overflow: TextOverflow.ellipsis,
            //                         maxLines: 1,
            //                         style: TextStyle(color: Color(0xff00DC00)))),
            //                 Container(child: Icon(Icons.arrow_drop_down))
            //               ],
            //             )))
            //     : Container(
            //         height: mHeight * 0.20 / 3,
            //         decoration: BoxDecoration(
            //             color: color,
            //             borderRadius: BorderRadius.all(Radius.circular(5))),
            //         child: Padding(
            //           padding: const EdgeInsets.only(
            //               left: 0.0, right: 6.0, top: 3.0, bottom: 5.0),
            //           child: CustDropDown(
            //             maxListHeight: 120,
            //             items: exitItems
            //                 .map((e) => CustDropdownMenuItem(
            //                     value: e,
            //                     child: Center(
            //                         child: Text(
            //                       '$e',
            //                       overflow: TextOverflow.ellipsis,
            //                       maxLines: 1,
            //                       style: TextStyle(color: Color(0xff00DC00)),
            //                     ))))
            //                 .toList(),
            //             hintText: "$selectedValue",
            //             borderRadius: 5,
            //             onChanged: (val) {
            //               print(val);
            //               setState(() {
            //                 selectedValue = val;
            //               });
            //             },
            //             appModel: appModel,
            //           ),
            //         ),
            //       ),
          ),
          // TextButton(onPressed: ()async{
          //   print('check status for belnet ${await BelnetLib.status}');
          //
          //   print('check for the mboundStatus ${BelnetLib.downloadUploadStream}');
          //  // Navigator.push(context, MaterialPageRoute(builder: (context)=>SplashScreens()));
          // }, child: Text('click me'))
        ],

    );
  }
}

// if there is no internet, this page only displays when there is no inter
class NoInternetConnection extends StatelessWidget {
  const NoInternetConnection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
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
                    ))),
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
