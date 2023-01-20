import 'dart:async';
import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:belnet_mobile/displaylog.dart';
import 'package:belnet_mobile/src/model/exitnodeModel.dart';
import 'package:belnet_mobile/src/model/exitnodeRepo.dart';
import 'package:belnet_mobile/src/model/exitnodeCategoryModel.dart'
    as exitNodeModel;
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/splash_screen.dart';
import 'package:belnet_mobile/src/utils/styles.dart';
import 'package:belnet_mobile/src/widget/LineChartSample10.dart';
import 'package:belnet_mobile/src/widget/aboutpage.dart';
import 'package:belnet_mobile/src/widget/appUpdate.dart';
import 'package:belnet_mobile/src/widget/bottomnavbaroptions.dart';
import 'package:belnet_mobile/src/widget/connecting_status.dart';
import 'package:belnet_mobile/src/widget/exit_node_list.dart';
import 'package:belnet_mobile/src/widget/expandablelist.dart';
import 'package:belnet_mobile/src/widget/logProvider.dart';
import 'package:belnet_mobile/src/widget/nointernet_connection.dart';
// import 'package:belnet_mobile/src/widget/logProvider.dart';
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
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' as pr;
import 'package:shared_preferences/shared_preferences.dart';

//Global variables

bool netValue = true;
bool isClick = false;
bool loading = false;
bool isOpen = false;
// these data just for testing purpose

void main() async {
  //Load settings
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.getInstance()!.initialize();
  Paint.enableDithering = true;
  pr.Provider.debugCheckInvalidValueType = null;

  runApp(ProviderScope(child: BelnetApp()));
}

List<exitNodeModel.ExitNodeDataList> ranExitData = [];
List ids = [];
var selectedId;
var exitName = "", exitIcon = "";
List<exitNodeModel.ExitNodeDataList> exitData = [];

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
    getRandomExitData();
    _initAppTheme();
  }

//////////////////////////////////////////////////////////////////////////////

  getRandomExitData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (BelnetLib.isConnected == false) {
      print(
          "inside getRandomExitData function the belnetlib is false ${BelnetLib.isConnected}");
      var responses = await DataRepo().getListData();
      exitData.addAll(responses);
      setState(() {
        exitData.forEach((element) {
          element.node.forEach((elements) {
            ids.add(elements.id);
          });
        });

        final random = Random();
        selectedId = ids[random.nextInt(ids.length)];
      });

      setState(() {
        exitData.forEach((element) {
          element.node.forEach((element) {
            if (selectedId == element.id) {
              selectedValue = element.name;
              selectedConIcon = element.icon;
              print("icon id value $selectedId");
              print("selected exitnode value $selectedValue");
              print("icon image url : ${element.icon}");
            }
          });
        });

        // if(BelnetLib.isConnected == false){
        // preferences.setString('hintValue',selectedValue!);
        // preferences.setString('hintContryicon',selectedConIcon!);
        // }
      });
    }
    setState(() {
      hintValue = preferences.getString('hintValue');
      hintCountryIcon = preferences.getString('hintCountryicon');
      print('print hintvalue $hintValue and hintCountryIcon $hintCountryIcon');
    });
  }

////////////////////////////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return pr.ChangeNotifierProvider<AppModel>.value(
      value: appModel,
      child: pr.Consumer<AppModel>(builder: (context, value, child) {
        return GetMaterialApp(
            title: 'Belnet App',
            debugShowCheckedModeBanner: false,
            theme: appModel.darkTheme ? buildDarkTheme() : buildLightTheme(),
            home: SplashScreens() //BelnetHomePage(),
            );
      }),
    );
  }
}

List<String> exitItems = [];

class BelnetHomePage extends StatefulWidget {
  BelnetHomePage({Key? key}) : super(key: key);

  @override
  BelnetHomePageState createState() => BelnetHomePageState();
}

class BelnetHomePageState extends State<BelnetHomePage>
// with SingleTickerProviderStateMixin
{
  late ConnectivityResult connectivityResult;
  LogController logControllers = Get.put(LogController());
  @override
  void initState() {
    UpdateApp().checkVersion(context);
    Timer.periodic(Duration(seconds: 5), (timer) {
      myNetwork();
    });
    setState(() {});
    //  getExitnodeListDataFromAPI();
    super.initState();
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

  //List<ExitnodeList> exitList = <ExitnodeList>[];
  List myExitData = [];
  getExitnodeListDataFromAPI() async {
    List<ExitnodeList> exitList = await DataRepo().getDataFromNet();
    exitList.forEach(
      (element) {
        myExitData.add(element.name);
      },
    );

    setInitialLog();

    print("exitdata in foreach $myExitData");
    print("exitlist from json ${exitList.length}");
    print("jsonvalue from the data ${exitList[0].country}");
    setState(() {});
  }

  setInitialLog() {
    if (BelnetLib.isConnected) {
      logControllers.addDataTolist(
        " Belnet Daemon started",
        "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
      );
      logControllers.addDataTolist(
        " Connected successfully",
        "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
      );
    }
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
              body: MyForm(appModel),
            ),
          );
  }
}

// global list for exitnode

// Create a Form widget.

dynamic downloadRate = '';
dynamic uploadRate = '';
String? selectedValue =
    'snoq7arak4d5mkpfsg69saj7bp1ikxyzqjkhzb96keywn6iyhc5y.bdx';
String? selectedConIcon =
    "https://testdeb.beldex.dev/Beldex-Projects/Belnet/android/countryicons/icons8-france.png";
String? hintValue = '';
String? hintCountryIcon = '';

class MyForm extends StatefulWidget {
  final AppModel appModel;
  const MyForm(this.appModel);
  @override
  MyFormState createState() {
    return MyFormState();
  }
}

class MyFormState extends State<MyForm> with SingleTickerProviderStateMixin {
  static final key = new GlobalKey<FormState>();
  StreamSubscription<bool>? _isConnectedEventSubscription;
  LogController logController = Get.put(LogController());
  String downloadProgress = '0';
  String uploadProgress = '0';
  double displayRate = 0;
  String displayRateTxt = '0.0';
  double displayPer = 0;
  OverlayEntry? overlayEntry;
  int flag = 0;
  late AppModel appModel;
  //late LogProvider logProvider;

  @override
  initState() {
    super.initState();
    _isConnectedEventSubscription = BelnetLib.isConnectedEventStream
        .listen((bool isConnected) => setState(() {}));
    //callForUpdate();
    // getConnectingData();
    getRandomExitNodes();
    saveData();
  }

// function for storing the previous log data
  List<String> lData = [];
  List<String> lDate = [];
  setToLogData(String value, String dateValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      lData.add(value);
      lDate.add(dateValue);
    });

    prefs.setStringList("PREV_LOG_DATA", lData);
    prefs.setStringList("Prev_TIME_DATA", lDate);
  }

  getRandomExitNodes() async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    hintValue = preference.getString('hintValue');
    hintCountryIcon = preference.getString('hintCountryicon');
    setState(() {
      
    });
  }

  @override
  void dispose() {
    super.dispose();
    _isConnectedEventSubscription?.cancel();
    AwesomeNotifications().dispose();
    overlayEntry!.remove();
  }

  late bool con;

  Future toggleBelnet() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    appModel.uploadList.addAll(SpeedMapData().sampleUpData);
    appModel.downloadList.addAll(SpeedMapData().sampleDownData);
    if (BelnetLib.isConnected == false) {
      print(
          '${DateTime.now().microsecondsSinceEpoch} netvalue from disconnected --');
      //AwesomeNotifications().dismiss(3);
      appModel.singleDownload = "";
      appModel.singleUpload = "";
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
      // AwesomeNotifications()
      //     .dismiss(3); // dismiss the notification when belnet disconnected

      //logProvider.logata_set = "belnet disconnected";
      if (disConnectValue)
        logController.addDataTolist(" Belnet Daemon stopped..",
            "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
      logController.addDataTolist(" Belnet disconnected",
          "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
    } else {
      //Save the exit node and upstream dns
      final Settings settings = Settings.getInstance()!;
      settings.exitNode = selectedValue!.trim().toString();
      var myVal = selectedValue!.trim().toString();
      logController.addDataTolist(" Exit node = $myVal",
          "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
      preferences.setString('hintValue', myVal);
      hintValue = preferences.getString('hintValue');
     
      setState(() {});
      var eIcon = selectedConIcon!.trim().toString();
      preferences.setString('hintCountryicon', eIcon);
      hintCountryIcon = preferences.getString('hintCountryicon');
       print('hint value is stored from getString $hintValue and the hintCountryicon is $hintCountryIcon');
      logController.addDataTolist(" Connected to $myVal",
          "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");

      print('hint value is stored from getString $hintValue');
      setState(() {});
      settings.upstreamDNS = '';

      final result = await BelnetLib.prepareConnection();
      logController.addDataTolist(" Preparing Daemon connection..",
          "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
      if (await BelnetLib.isPrepared) {
        appModel.connecting_belnet = true;
      }
      if (result) {
        con = await BelnetLib.connectToBelnet(
            exitNode: settings.exitNode!, upstreamDNS: "");
        logController.addDataTolist(
          " Connected successfully",
          "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
        );
        print("connection data value for display $con");
      }

      setState(() {});
      // MyNotificationWorkLoad(
      //   appModel: appModel,
      //   isLoading: loading,
      //   function: () {
      //     setState(() {});
      //   },
      // ).createMyNotification(
      //   dismiss,
      //   uploadRate,
      //   downloadRate,
      // );
      if (BelnetLib.isConnected) {
        appModel.connecting_belnet = true;
        logController.addDataTolist(
          " Connected successfully",
          "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
        );
        setToLogData(
          " Connected successfully",
          "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
        );
      }
    }
  }

  var uploadUnit = ' Mbps';
  var downloadUnit = ' Mbps';
  var uploadValue, kb, mb, gb, downloadValue, kb1, mb1, gb1;

  // getUploadAndDownload() async {
  //   if (BelnetLib.isConnected) {
  //     print('upload speed will be');

  //     var uploadR = await BelnetLib.upload;
  //     var downloadR = await BelnetLib.download;

  //     Future.delayed(Duration(seconds: 1), () {
  //       appModel.uploads = uploadR;
  //       appModel.downloads = downloadR;
  //       setState(() {
  //         uploadRate = uploadR;
  //         print('upload displayed from dart side $uploadRate');
  //         downloadRate = downloadR;
  //       });
  //     });
  //     print("printed after 3seconds");
  //   }
  // }

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

  List<exitNodeModel.ExitNodeDataList> exitData = [];

  String valueS = "";

  saveData() async {
    exitData = [];
    var res = await DataRepo().getListData();
    exitData.addAll(res);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    appModel = pr.Provider.of<AppModel>(context);
    Color color = appModel.darkTheme ? Color(0xff292937) : Colors.white;
    //logProvider = pr.Provider.of<LogProvider>(context);
    double mHeight = MediaQuery.of(context).size.height;
    // if(BelnetLib.isConnected){
    //     getUploadAndDownload();
    // }
     if(netValue == false && isOpen){
      overlayEntry!.remove();
    }
    return
        // SingleChildScrollView(
        // child:
        // Scaffold(
        // resizeToAvoidBottomInset: true,
        GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Stack(
                    children: [
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
                                  : Image.asset(
                                      'assets/images/map_white (3).png'),
                              //appModel.connecting_belnet &&
                              BelnetLib.isConnected
                                  ? Image.asset(
                                      'assets/images/Map_white_gif (1).gif') //Image.asset('assets/images/Mobile_1.gif')
                                  : Container()
                            ])),
                      ),
                      Positioned(
                        top: mHeight * 0.10 / 3,
                        left: mHeight * 0.04 / 3,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AboutPage()));
                          },
                          child: Container(
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.height *
                                    0.06 /
                                    3),
                            // color: Colors.yellow,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                appModel.darkTheme
                                    ? SvgPicture.asset(
                                        'assets/images/About_dark.svg',
                                        width: mHeight * 0.06 / 3,
                                        height: mHeight * 0.06 / 3)
                                    : SvgPicture.asset(
                                        'assets/images/about_white_theme.svg',
                                        width: mHeight * 0.06 / 3,
                                        height: mHeight * 0.06 / 3),
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: MediaQuery.of(context).size.height *
                                        0.02 /
                                        3,
                                    top: MediaQuery.of(context).size.height *
                                        0.06 /
                                        3,
                                    bottom: MediaQuery.of(context).size.height *
                                        0.06 /
                                        3,
                                  ),
                                  child: Text(
                                    'About',
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height *
                                                0.06 /
                                                3,
                                        color: Color(0xffAEAEBC)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: mHeight * 0.10 / 3,
                        right: mHeight * 0.04 / 3,
                        child: GestureDetector(
                            onTap: () {
                              appModel.darkTheme = !appModel.darkTheme;
                            },
                            child: appModel.darkTheme
                                ? Image.asset(
                                    'assets/images/dark_theme_4x (2).png',
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
                          padding:
                              EdgeInsets.only(top: mHeight * 0.70 / 3), //0.63
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
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: mHeight * 0.10 / 3),
                    child: ConnectingStatus(
                      isConnect: BelnetLib.isConnected,
                    ),
                  ),
                  //SizedBox(height: MediaQuery.of(context),)
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            left: mHeight * 0.10 / 3, top: mHeight * 0.10 / 3),
                        child: GestureDetector(
                          onTap: () {
                            // Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //         builder: (context) =>
                            //             ExpandDropdownList()));
                          },
                          child: Text('Exit Node',
                              style: TextStyle(
                                  color: appModel.darkTheme
                                      ? Colors.white
                                      : Colors.black,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w900,
                                  fontSize: mHeight * 0.05 / 3)),
                        ),
                      ),
                    ],
                  ),

                  // Container(
                  //     color: Colors.transparent,
                  //     child: Stack(
                  //       children: [
                  //         Padding(
                  //             padding: EdgeInsets.only(
                  //                 left:
                  //                     MediaQuery.of(context).size.height * 0.08 / 3,
                  //                 right:
                  //                     MediaQuery.of(context).size.height * 0.10 / 3,
                  //                 top: MediaQuery.of(context).size.height *
                  //                     0.03 /
                  //                     3),
                  //             child: GestureDetector(
                  //               onTap: () {
                  //                 setState(() {
                  //                   canShow = canShow ? false : true;
                  //                 });
                  //               },
                  //               child: Container(
                  //                   height: MediaQuery.of(context).size.height *
                  //                       0.16 /
                  //                       3,
                  //                   decoration: BoxDecoration(
                  //                       color: appModel.darkTheme
                  //                           ? Color(0xff292937)
                  //                           : Color(0xffFFFFFF),
                  //                       borderRadius:
                  //                           BorderRadius.all(Radius.circular(5))),
                  //                   child: Padding(
                  //                       padding: const EdgeInsets.only(
                  //                           left: 4.0,
                  //                           right: 6.0,
                  //                           top: 3.0,
                  //                           bottom: 5.0),
                  //                       child: Row(
                  //                         crossAxisAlignment:
                  //                             CrossAxisAlignment.center,
                  //                         children: [
                  //                           Container(

                  //                               // margin:EdgeInsets.only(right:mHeight*0.03/3,),
                  //                               child: SvgPicture.network(
                  //                                   "https://testdeb.beldex.dev/Beldex-Projects/Belnet/android/countryicons/icons8-france.svg")),
                  //                           Expanded(
                  //                               child: Center(
                  //                             child: Text("$hintValue",
                  //                                 overflow: TextOverflow.ellipsis,
                  //                                 maxLines: 1,
                  //                                 style: TextStyle(
                  //                                     color: Color(0xff00DC00))),
                  //                           )),
                  //                           Container(
                  //                               child: Icon(
                  //                             Icons.arrow_drop_down,
                  //                             color: Colors.grey,
                  //                           ))
                  //                         ],
                  //                       ))),
                  //             )),

                  //       ],
                  //     ),
                  //   ),

                  Container(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        BelnetLib.isConnected
                            ? Padding(
                                padding: EdgeInsets.only(
                                    left: MediaQuery.of(context).size.height *
                                        0.08 /
                                        3,
                                    right: MediaQuery.of(context).size.height *
                                        0.10 /
                                        3,
                                    top: MediaQuery.of(context).size.height *
                                        0.03 /
                                        3),
                                child: Container(
                                    height: MediaQuery.of(context).size.height *
                                        0.16 /
                                        3,
                                    decoration: BoxDecoration(
                                      
                                        color: appModel.darkTheme
                                            ? Color(0xff292937)
                                            : Color(0xffFFFFFF),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5))),
                                    child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 4.0,
                                            right: 6.0,
                                            top: 3.0,
                                            bottom: 5.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                                margin: EdgeInsets.all(8.0),
                                                // margin:EdgeInsets.only(right:mHeight*0.03/3,),
                                                child:
                                                hintCountryIcon != ""?
                                                 Image.network(
                                                  "$hintCountryIcon",
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Icon(
                                                      Icons.more_horiz,
                                                      color: Colors.grey,
                                                    );
                                                  },
                                                ):Icon(Icons
                                                          .more_horiz,color: Colors.grey,)),
                                            Expanded(
                                                child: Center(
                                              child: Text("$hintValue",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color:
                                                          Color(0xff00DC00))),
                                            )),
                                            Container(
                                                child: Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.grey,
                                            ))
                                          ],
                                        ))))
                            : Padding(
                                padding: EdgeInsets.only(
                                    left: MediaQuery.of(context).size.height *
                                        0.08 /
                                        3,
                                    right: MediaQuery.of(context).size.height * 0.10 / 3,
                                    top: MediaQuery.of(context).size.height * 0.03 / 3),
                                child: GestureDetector(
                                  onTap: () {
                                    // setState(() {
                                    //   canShow = canShow ? false : true;
                                    // });
                                    setState(() {
                                      isOpen = isOpen ? false : true;
                                    });
                                    if (isOpen && exitData.isEmpty) {
                                      // exitData.clear();
                                      saveData();
                                    }
                                    print("the value of the isOpen $isOpen");

                                    OverlayState? overlayState =
                                        Overlay.of(context);
                                    overlayEntry = OverlayEntry(
                                      builder: (context) {
                                        return _buildExitnodeListView(mHeight);
                                      },
                                    );

                                    overlayState?.insert(overlayEntry!);
                                    // if(isOpen == false)
                                    //   overlayEntry?.remove();
                                  },
                                  child: Container(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.16 /
                                              3,
                                      decoration: BoxDecoration(
                                          color: appModel.darkTheme
                                              ? Color(0xff292937)
                                              : Color(0xffFFFFFF),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5))),
                                      child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: 4.0,
                                              right: 6.0,
                                              top: 3.0,
                                              bottom: 5.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                  margin: EdgeInsets.all(8),
                                                  //height:mHeight*0.15/3,width: mHeight*0.20/3,
                                                  // margin:EdgeInsets.only(right:mHeight*0.03/3,),
                                                  child: 
                                                  selectedConIcon != ""
                                                      ? Image.network(
                                                        //"$hintCountryIcon",
                                                         "$selectedConIcon",
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return Icon(
                                                                Icons
                                                                    .more_horiz,
                                                                color: Colors
                                                                    .grey);
                                                          },
                                                        )
                                                      : 
                                                      Icon(Icons
                                                          .more_horiz,color: Colors.grey,)),
                                              Expanded(
                                                  child: Center(
                                                child: Text("$selectedValue",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xff00DC00))),
                                              )),
                                              Container(
                                                  child: Icon(
                                                Icons.arrow_drop_down,
                                                color: Colors.grey,
                                              ))
                                            ],
                                          ))),
                                )),
                        // canShow ? Positioned(
                        //      // top:mHeight*0.02/3,
                        //       child:
                        //       Padding(
                        //           padding: EdgeInsets.only(
                        //               left: MediaQuery.of(context).size.height *
                        //                   0.08 /
                        //                   3,
                        //               right: MediaQuery.of(context).size.height *
                        //                   0.10 /
                        //                   3,
                        //               top: MediaQuery.of(context).size.height *
                        //                   0.03 /
                        //                   3),
                        //           child: Container(
                        //             height: MediaQuery.of(context).size.height *
                        //                 0.70 /
                        //                 3,
                        //             width:
                        //                 MediaQuery.of(context).size.width * 2.7 / 3,
                        //             color: appModel.darkTheme
                        //                 ? Color(0xff292937)
                        //                 : Colors.white,
                        //             child:
                        //             ListView.builder(
                        //                 padding: EdgeInsets.zero,
                        //                 shrinkWrap: true,
                        //                 itemCount: exitData.length,
                        //                 itemBuilder:
                        //                     (BuildContext context, int index) {
                        //                   // print("data inside listview ${exitData[index]}");
                        //                   return Container(
                        //                     margin: EdgeInsets.all(0),
                        //                     //padding: const EdgeInsets.only(top:0.0,bottom:0.0),
                        //                     child: ExpansionTile(
                        //                       // backgroundColor: Colors.yellow,
                        //                       tilePadding: EdgeInsets.only(
                        //                           left: mHeight * 0.08 / 3,
                        //                           right: mHeight * 0.08 / 3),
                        //                       title: Text(
                        //                         exitData[index].type,
                        //                         style: TextStyle(
                        //                             color: index == 0
                        //                                 ? Color(0xff1CBE20)
                        //                                 : Color(0xff1994FC),
                        //                             fontSize: MediaQuery.of(context)
                        //                                     .size
                        //                                     .height *
                        //                                 0.06 /
                        //                                 3,
                        //                             fontWeight: FontWeight.bold),
                        //                       ),
                        //                       iconColor: index == 0
                        //                           ? Color(0xff1CBE20)
                        //                           : Color(0xff1994FC),
                        //                       collapsedIconColor: index == 0
                        //                           ? Color(0xff1CBE20)
                        //                           : Color(0xff1994FC),
                        //                       subtitle: Text(
                        //                         "${exitData[index].node.length} Nodes",
                        //                         style: TextStyle(
                        //                             color: Colors.grey,
                        //                             fontSize: MediaQuery.of(context)
                        //                                     .size
                        //                                     .height *
                        //                                 0.04 /
                        //                                 3),
                        //                       ),
                        //                       children: <Widget>[
                        //                         Column(
                        //                           children: _buildExpandableContent(
                        //                               exitData[index].node),
                        //                         ),
                        //                       ],
                        //                     ),
                        //                   );
                        //                 }
                        //                 // _buildList(exitData[index]),
                        //                 ),
                        //           ),
                        //         ),
                        //     )
                        //     : SizedBox.shrink()
                      ],
                    ),
                  ),

                  // Padding(
                  //   padding: EdgeInsets.only(
                  //       left: mHeight * 0.08 / 3,
                  //       right: mHeight * 0.10 / 3,
                  //       top: mHeight * 0.03 / 3),
                  //   child: BelnetLib.isConnected
                  //       ? Container(
                  //           height: mHeight * 0.16 / 3,
                  //           decoration: BoxDecoration(
                  //               color: color,
                  //               borderRadius:
                  //                   BorderRadius.all(Radius.circular(5))),
                  //           child: Padding(
                  //               padding: const EdgeInsets.only(
                  //                   left: 4.0, right: 6.0, top: 3.0, bottom: 5.0),
                  //               child: Row(
                  //                 crossAxisAlignment: CrossAxisAlignment.center,
                  //                 children: [
                  //                   Expanded(
                  //                       child: Center(
                  //                     child: Text('$hintValue',
                  //                         overflow: TextOverflow.ellipsis,
                  //                         maxLines: 1,
                  //                         style: TextStyle(
                  //                             color: Color(0xff00DC00))),
                  //                   )),
                  //                   Container(
                  //                       child: Icon(
                  //                     Icons.arrow_drop_down,
                  //                     color: Colors.grey,
                  //                   ))
                  //                 ],
                  //               )))
                  //       :
                  //       Container(
                  //           height: mHeight * 0.16 / 3,
                  //           decoration: BoxDecoration(
                  //               color: color,
                  //               borderRadius:
                  //                   BorderRadius.all(Radius.circular(5))),
                  //           child: Padding(
                  //             padding: const EdgeInsets.only(
                  //                 left: 0.0, right: 6.0, top: 3.0, bottom: 5.0),
                  //             child:
                  //             CustDropDown(
                  //               maxListHeight: 120,
                  //               items: exitItems
                  //                   .map((e) => CustDropdownMenuItem(
                  //                       value: e,
                  //                       child: Center(
                  //                           child: Text(
                  //                         '$e',
                  //                         overflow: TextOverflow.ellipsis,
                  //                         maxLines: 1,
                  //                         style:
                  //                             TextStyle(color: Color(0xff00DC00)),
                  //                       ))))
                  //                   .toList(),
                  //               hintText: "$selectedValue",
                  //               borderRadius: 5,
                  //               onChanged: (val) {
                  //                 print(val);
                  //                 setState(() {
                  //                   selectedValue = val;
                  //                 });
                  //               },
                  //               appModel: appModel,
                  //             ),
                  //           ),
                  //         ),
                  // ),

                  // Padding(
                  //     padding: EdgeInsets.only(
                  //         left: mHeight * 0.08 / 3,
                  //         right: mHeight * 0.10 / 3,
                  //         top: mHeight * 0.03 / 3),
                  //     child: Container(
                  //       height: MediaQuery.of(context).size.height * 0.18 / 3,
                  //       width: double.infinity,
                  //     )),
                  SizedBox(
                    height: mHeight * 0.05 / 3,
                  )
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
                                text: appModel.singleDownload.isEmpty
                                    ? '0.0'
                                    : BelnetLib.isConnected
                                        ? '${stringBeforeSpace(appModel.singleDownload)}'
                                        : '0.0',
                                style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Poppins',
                                    color: appModel.darkTheme
                                        ? Color(0xffA1A1C1)
                                        : Colors.black),
                                children: [
                              TextSpan(
                                  text: appModel.singleDownload.isEmpty
                                      ? ' bps'
                                      : ' ${stringAfterSpace(appModel.singleDownload)}',
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
                                text: appModel.singleUpload.isEmpty
                                    ? '0.0'
                                    : BelnetLib.isConnected
                                        ? '${stringBeforeSpace(appModel.singleUpload)}'
                                        : '0.0',
                                style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Poppins',
                                    color: appModel.darkTheme
                                        ? Color(0xffA1A1C1)
                                        : Colors.black),
                                children: [
                              TextSpan(
                                  text: appModel.singleUpload.isEmpty
                                      ? ' bps'
                                      : ' ${stringAfterSpace(appModel.singleUpload)}',
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
              ),
            ],
          ),
          Flexible(
            child: Container(
                width: double.infinity,
                // color: Colors.orange,
                child: BottomNavBarOptions()),
          )
        ],
      ),
    );
    //);
    //);
  }

  Widget _buildExitnodeListView(double mHeight) {

   
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          overlayEntry!.remove();
        },
        child: Container(
          height: 200.0,
          margin: EdgeInsets.only(
              top: mHeight * 2.010 / 3,
              bottom: MediaQuery.of(context).size.height * 0.30 / 3,
              left: mHeight * 0.09 / 3,
              right: mHeight * 0.09 / 3),
          child:

              /// Padding(
              // padding: EdgeInsets.only(
              //     left: MediaQuery.of(context).size.height *
              //         0.08 /
              //         3,
              //     right: MediaQuery.of(context).size.height *
              //         0.10 /
              //         3,
              //     top: MediaQuery.of(context).size.height *
              //         0.03 /
              //         3),
              // child:
              Container(
            height: MediaQuery.of(context).size.height * 0.70 / 3,
            width: MediaQuery.of(context).size.width * 2.7 / 3,
            decoration: BoxDecoration(
              borderRadius:BorderRadius.circular(4.0),
              color: appModel.darkTheme ? Color(0xff292937) : Colors.white,
            ),
            
            child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: exitData.length,
                itemBuilder: (BuildContext context, int index) {
                  // print("data inside listview ${exitData[index]}");
                  return Container(
                    margin: EdgeInsets.all(0),
                    //padding: const EdgeInsets.only(top:0.0,bottom:0.0),
                    child: ExpansionTile(
                      // backgroundColor: Colors.yellow,
                      tilePadding: EdgeInsets.only(
                          left: mHeight * 0.08 / 3, right: mHeight * 0.08 / 3),
                      title: Text(
                        exitData[index].type,
                        style: TextStyle(
                            color: index == 0
                                ? Color(0xff1CBE20)
                                : Color(0xff1994FC),
                            fontSize:
                                MediaQuery.of(context).size.height * 0.06 / 3,
                            fontWeight: FontWeight.bold),
                      ),
                      iconColor:
                          index == 0 ? Color(0xff1CBE20) : Color(0xff1994FC),
                      collapsedIconColor:
                          index == 0 ? Color(0xff1CBE20) : Color(0xff1994FC),
                      subtitle: Text(
                        "${exitData[index].node.length} Nodes",
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize:
                                MediaQuery.of(context).size.height * 0.04 / 3),
                      ),
                      children: <Widget>[
                        Column(
                          children:
                              _buildExpandableContent(exitData[index].node),
                        ),
                      ],
                    ),
                  );
                }
                // _buildList(exitData[index]),
                ),
          ),
          // ),
        ),
      ),
    );
  }

  // _buildExpandableContent(List<exitNodeModel.Node> vnode) {
  //   List<Widget> columnContent = [];
  //   for (int i = 0; i < vnode.length; i++) {
  //     columnContent.add(Container(
  //       height: MediaQuery.of(context).size.height * 0.15 / 3,
  //       child: ListTile(
  //         onTap: () async {
  //           setState(() {
  //             valueS = vnode[i].name;
  //             selectedValue = vnode[i].name;
  //             selectedConIcon = vnode[i].icon;
  //           });
  //           overlayEntry?.remove();
  //           SharedPreferences preferences =
  //               await SharedPreferences.getInstance();
  //           preferences.setString('hintValue', selectedValue.toString());
  //           preferences.setString('hintContryicon', selectedConIcon.toString());
  //           print("$i th index value $valueS ");
  //         },
  //         title: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               vnode[i].name,
  //               style: TextStyle(
  //                   color: appModel.darkTheme ? Colors.white : Colors.black,
  //                   fontSize: MediaQuery.of(context).size.height * 0.05 / 3),
  //               overflow: TextOverflow.ellipsis,
  //               maxLines: 1,
  //             ),
  //             Text(
  //               vnode[i].country,
  //               style: TextStyle(
  //                   color: Colors.grey,
  //                   fontSize: MediaQuery.of(context).size.height * 0.04 / 3),
  //               overflow: TextOverflow.ellipsis,
  //               maxLines: 1,
  //             ),
  //           ],
  //         ),
  //         leading: Container(
  //           //color:Colors.yellow,
  //           height: MediaQuery.of(context).size.height * 0.050 / 3,
  //           width: MediaQuery.of(context).size.height * 0.060 / 3,
  //           child: vnode[i].icon.isNotEmpty
  //               ? Image.network(
  //                   vnode[i].icon,
  //                   // height: MediaQuery.of(context).size.height * 0.10 / 3,
  //                   // width: MediaQuery.of(context).size.height * 0.15 / 3,
  //                   fit: BoxFit.fill,
  //                 )
  //               : Icon(Icons.info_outline_rounded),
  //         ),
  //         trailing: Container(
  //           height: 5.0,
  //           width: 5.0,
  //           decoration: BoxDecoration(
  //               shape: BoxShape.circle,
  //               color: vnode[i].isActive == "true" ? Colors.green : Colors.red),
  //         ),
  //       ),
  //     ));
  //   }
  //   return columnContent;
  // }



_buildExpandableContent(List<exitNodeModel.Node> vnode) {
    List<Widget> columnContent = [];
    for (int i = 0; i < vnode.length; i++) {
      columnContent.add(
        
        Container(
          padding: EdgeInsets.only(left:MediaQuery.of(context).size.height*0.06/3,right:MediaQuery.of(context).size.height*0.06/3,
          top:MediaQuery.of(context).size.height*0.02/3,bottom: MediaQuery.of(context).size.height*0.02/3),
        height: MediaQuery.of(context).size.height * 0.15 / 3,
        child: 
        GestureDetector(
          onTap: () async {
              setState(() {
                valueS = vnode[i].name;
                selectedValue = vnode[i].name;
                selectedConIcon = vnode[i].icon;
              });
              overlayEntry?.remove();
              SharedPreferences preferences =
                  await SharedPreferences.getInstance();
              preferences.setString('hintValue', selectedValue.toString());
              preferences.setString('hintContryicon', selectedConIcon.toString());
              print("$i th index value $valueS ");
            },
          child: Row(
            children: [
               Container(
                  //color:Colors.yellow,
                  height: MediaQuery.of(context).size.height * 0.050 / 3,
                  width: MediaQuery.of(context).size.height * 0.060 / 3,
                  child: vnode[i].icon.isNotEmpty
                      ? Image.network(
                          vnode[i].icon,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.more_horiz,color: Colors.grey,size: 0.4,);
                          },
                          // height: MediaQuery.of(context).size.height * 0.10 / 3,
                          // width: MediaQuery.of(context).size.height * 0.15 / 3,
                          fit: BoxFit.fill,
                        )
                      : Icon(Icons.info_outline_rounded),
                ),
           
             Expanded(
               child: Container(
                padding: EdgeInsets.only(left:MediaQuery.of(context).size.height*0.05/3,right:MediaQuery.of(context).size.height*0.05/3),
                 child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            vnode[i].name,
                            style: TextStyle(
                                color: appModel.darkTheme ? Colors.white : Colors.black,
                                fontSize: MediaQuery.of(context).size.height * 0.05 / 3),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Text(
                          vnode[i].country,
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: MediaQuery.of(context).size.height * 0.04 / 3),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
               ),
             ),
               Container(
                  height: 5.0,
                  width: 5.0,
                  padding: EdgeInsets.only(right:MediaQuery.of(context).size.height*0.05/3),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: vnode[i].isActive == "true" ? Colors.green : Colors.red),
                ),
              
            ],
          ),
        ),
      ));
    }
    return columnContent;
  }


















  // var invalidExit = "";
  // var invalidAuth = "";

  // TextEditingController _cusExitNode = TextEditingController();
  // TextEditingController _cusAuthCode = TextEditingController();

  // var textForExit;
  // var textForAuth;
  // var isSet = false;
  // var color = "blue";

}

// if there is no internet, this page only displays when there is no inter
