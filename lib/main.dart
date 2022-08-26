import 'dart:async';
//import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/splash_screen.dart';
import 'package:belnet_mobile/src/utils/styles.dart';
// import 'package:belnet_mobile/src/widget/backgroundImage.dart';
import 'package:belnet_mobile/src/widget/connecting_status.dart';
import 'package:belnet_mobile/src/widget/notifications.dart';
import 'package:flutter/material.dart';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/settings.dart';
import 'package:belnet_mobile/src/widget/belnet_power_button.dart';
import 'package:belnet_mobile/src/widget/themed_belnet_logo.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

// import 'package:scaffold_gradient_background/scaffold_gradient_background.dart';
//Global variables
final exitInput = TextEditingController(text: Settings.getInstance()!.exitNode);
final dnsInput =
    TextEditingController(text: Settings.getInstance()!.upstreamDNS);

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
        //channelShowBadge: true,
        locked: true,
        defaultPrivacy: NotificationPrivacy.Private)
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
    //SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack, overlays: [SystemUiOverlay.top]);
    _initAppTheme();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return ChangeNotifierProvider<AppModel>.value(
      value: appModel,
      child: Consumer<AppModel>(builder: (context, value, child) {
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
    lottieController = AnimationController(
      vsync: this,
    );
    super.initState();
  }

  @override
  void dispose() {
    lottieController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    //final key = new GlobalKey<ScaffoldState>();
    double mHeight = MediaQuery.of(context).size.height;
    // double mWidth = MediaQuery.of(context).size.width;
    final appModel = Provider.of<AppModel>(context);

    return SafeArea(
      child: Container(
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
              false, //Prevents overflow when keyboard is shown
          body: Container(
            // color: appModel.darkTheme ? Color(0xff242430) : Color(0xffF9F9F9),
            child: Stack(
              children: [
                Container(
                    width: double.infinity,
                    //color:Colors.green,
                    height: mHeight * 1.20 / 3,
                    child: appModel.darkTheme
                        ? Lottie.asset(
                            appModel.connecting_belnet
                                ? 'assets/images/dark_animations.json'
                                : 'assets/images/Map_dark_BG.json',
                            fit: BoxFit.fitHeight,
                            width: double.infinity)
                        : Lottie.asset(
                            appModel.connecting_belnet
                                ? 'assets/images/White_animation.json'
                                : 'assets/images/white_static.json',
                            fit: BoxFit.fitHeight,
                            width: double.infinity)),
                Positioned(
                  top: mHeight * 0.09 / 3,
                  right: mHeight * 0.03 / 3,
                  child: GestureDetector(
                    onTap: () {
                      appModel.darkTheme = !appModel.darkTheme;
                    },
                    child: appModel.darkTheme
                        ? SvgPicture.asset('assets/images/dark_theme.svg')
                        : SvgPicture.asset('assets/images/light_theme.svg'),
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
    '7a4cpzri7qgqen9a3g3hgfjrijt9337qb19rhcdmx5y7yttak33o.bdx',
    'gosihdxzcwwcc4zibikc9fte7i8dxqkaohcgyqcjcwj5cncyy36o.bdx',
    'c17bqguk87hroszro9s69bm5ne6edrronpasfkcyp9mcwogikdmo.bdx',
    'exit.bdx',
    'service.bdx',
    'belnet.bdx'
  ];
  String? selectedValue =
      '7a4cpzri7qgqen9a3g3hgfjrijt9337qb19rhcdmx5y7yttak33o.bdx';
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  @override
  initState() {
    super.initState();
    _isConnectedEventSubscription = BelnetLib.isConnectedEventStream
        .listen((bool isConnected) => setState(() {}));



    //for notification

    // AwesomeNotifications().createdStream.listen((notification) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Notification Created on ${notification.channelKey}'),
    //     ),
    //   );
    // });
    //
    // AwesomeNotifications().actionStream.listen((notification) {
    //   Navigator.pushAndRemoveUntil(
    //       context,
    //       MaterialPageRoute(
    //         builder: (_) => BelnetHomePage(),
    //       ),
    //           (route) => route.isFirst);
    // });
  }

  @override
  void dispose() {
    // _animationController.dispose();
    super.dispose();

    _isConnectedEventSubscription?.cancel();
  }

  Future toggleBelnet() async {
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
      await BelnetLib.disconnectFromBelnet();
      appModel.connecting_belnet = false;
      print('belnet status 2 ${appModel.status_belnet}');
    } else {
      //Save the exit node and upstream dns
      final Settings settings = Settings.getInstance()!;
      settings.exitNode =
          selectedValue!.trim().toString(); //exitInput.value.text.trim();
      settings.upstreamDNS = dnsInput.value.text.trim();

      final result = await BelnetLib.prepareConnection();
      // appModel.connecting_belnet = true;
      if (await BelnetLib.isPrepared) {
        appModel.connecting_belnet = true;
      }
      if (result)
        BelnetLib.connectToBelnet(
            exitNode: settings.exitNode!,
            upstreamDNS: "" //settings.upstreamDNS!
            );

      setState(() {});
      if (BelnetLib.isConnected) {
        appModel.connecting_belnet = true;
      }

      MyNotificationWorkLoad().createMyNotification();
      //_showNotificationWithoutSound();
    }

    //appModel.status_belnet = false;
  }

  // Future _showNotificationWithoutSound() async {
  //   var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
  //     'basic_channel',
  //     '1',
  //     playSound: false,
  //     importance: Importance.max,
  //     priority: Priority.max,
  //     ongoing: true,
  //   );
  //   var iOSPlatformChannelSpecifics =
  //       IOSNotificationDetails(presentSound: false);
  //   var platformChannelSpecifics = NotificationDetails(
  //       android: androidPlatformChannelSpecifics,
  //       iOS: iOSPlatformChannelSpecifics);
  //   await flutterLocalNotificationsPlugin.show(
  //     0,
  //     'Belnet is Running...',
  //     'Click to go to Belnet app',
  //     platformChannelSpecifics,
  //     payload: 'No_Sound',
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    //String val = 'test ';
    appModel = Provider.of<AppModel>(context);
    Color color = appModel.darkTheme ? Color(0xff292937) : Colors.white;
    double mHeight = MediaQuery.of(context).size.height;
    //double mWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      // crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: mHeight * 0.15 / 3),
          child: BelnetPowerButton(
              onPressed: toggleBelnet,
              isClick: BelnetLib.isConnected,
              isLoading: loading),
        ),
        Padding(
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
          child: Container(
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.all(Radius.circular(5))),
            child: Padding(
                padding: const EdgeInsets.only(
                    left: 0.0, right: 6.0, top: 3.0, bottom: 3.0),
                child: BelnetLib.isConnected
                    ? Container(
                     // color:Colors.amber,
                        height: mHeight * 0.20 / 3,
                        width: MediaQuery.of(context).size.height * 2 / 3,
                        child: Padding(
                          padding: EdgeInsets.only(left:0,right:5.0),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Container(
                                    width:mHeight*1/3,
                                    child: Center(
                                      child: Text(
                                        '$selectedValue',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: mHeight * 0.06 / 3,
                                          color: Color(0xff00DC00),
                                          overflow: TextOverflow.ellipsis
                                        ),
                                        //maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                   // color: Colors.green,
                                    width: mHeight * 0.10 / 3,
                                    child: Icon(
                                      Icons.arrow_drop_down,
                                      color: Color(0xffD4D4D4),
                                    ))
                              ]),
                        ))
                    : DropdownButtonHideUnderline(
                        child: DropdownButton(
                            enableFeedback: true,
                            isExpanded: true,
                            //underline: const SizedBox(),
                            value: selectedValue,
                            icon: Icon(Icons.arrow_drop_down,
                                color: Color(0xffD4D4D4)),
                            style: TextStyle(
                                color: Color(0xff00DC00),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                fontSize: mHeight * 0.06 / 3,
                                overflow: TextOverflow.ellipsis),
                            items: exitItems
                                .map((item) => DropdownMenuItem<String>(
                                      value: item,
                                      enabled:
                                          BelnetLib.isConnected ? false : true,
                                      child: Center(
                                        child: Text(
                                          item,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xff00DC00),
                                              fontFamily: 'Poppins'),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (dynamic value) {
                              setState(() {
                                selectedValue = value;
                                print('$selectedValue');
                              });
                            }),
                      )),
          ),
        ),
        TextButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ButtonTest()));
            },
            child: Text('click me to go')),
      ],
    );
  }
}

class ButtonTest extends StatefulWidget {
  const ButtonTest({Key? key}) : super(key: key);

  @override
  State<ButtonTest> createState() => _ButtonTestState();
}

class _ButtonTestState extends State<ButtonTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            // color:Colors.transparent,
            // color: Colors.white,               //off_whitess.json
            child: Lottie.asset('assets/images/Map_static_dark (2).json'),),);
  }
}
