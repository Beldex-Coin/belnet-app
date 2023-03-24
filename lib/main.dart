import 'dart:async';
import 'dart:io';
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
import 'package:belnet_mobile/src/widget/modelResponse.dart';
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
import 'package:native_updater/native_updater.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart' as pr;
import 'package:shared_preferences/shared_preferences.dart';

//Global variables

bool netValue = true;
bool isClick = false;
bool loading = false;
bool isOpen = false;
bool isCheckLoad = false;
var isAddExitStatus;
int counter = 1;
// these data just for testing purpose
List<String> customExitAdd = [];
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

    // setState(() {
    //   customExitAdd = preferences.getStringList("customData")!; //for custom exit node save
     
    // });
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
    checkVersion(context);
    Timer.periodic(Duration(seconds: 5), (timer) {
      myNetwork();
    });
    setState(() {});
    //  getExitnodeListDataFromAPI();
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
    "https://deb.beldex.io/Beldex-projects/Belnet/countryflag/icons8-france.png";
String? hintValue = '';
String? hintCountryIcon = '';

bool canLoading = false;

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
      isAddExitStatus = preference.getBool('oneTimeAddExit') ?? false;
      print("value of isAddExitStatus is $isAddExitStatus");
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _isConnectedEventSubscription?.cancel();
    AwesomeNotifications().dispose();
    overlayEntry!.remove();
  }

  bool myExit = false;
  var mystr = "";
  getDataFromDaemon() async {
    var fromDaemon = await BelnetLib.getSpeedStatus;
    if (fromDaemon != null) {
      var data1 = Welcome.fromJson(fromDaemon);
      print("isConnected before ${data1.isConnected}");
      myExit = data1.isConnected;

      print("isConnected after the myExit $myExit");
      // if(myEx){
      //   setState(() {
      //     mystr = "valid exitnode";
      //   });
      // }else{
      //   mystr = "invalid exitnode";
      // }
      setState(() {});
    }
  } // bool myExit = false;
  // var mystr = "";
  // getDataFromDaemon() async {
  //   var fromDaemon = await BelnetLib.getSpeedStatus;
  //   if (fromDaemon != null) {
  //     var data1 = Welcome.fromJson(fromDaemon);

  //     myExit = data1.isConnected;
  //     // if(myEx){
  //     //   setState(() {
  //     //     mystr = "valid exitnode";
  //     //   });
  //     // }else{
  //     //   mystr = "invalid exitnode";
  //     // }
  //     setState(() {});
  //   }
  // }

  // List<String> cusExits = [];

  // saveCustomForUse([eligibleC]) async {
  //   var prefs = await SharedPreferences.getInstance();
  //   prefs.setBool("eligibleCust", eligibleC);
  //   if (_cusExitNode.text != null || _cusExitNode.text != "") {

  //     setState(() {
  //       cusExits = prefs.getStringList("customData")!;

  //       for(int i =0;i<customExitAdd.length;i++){
  //       if(_cusExitNode.text != customExitAdd[i]){
  //       cusExits.add(_cusExitNode.text);

  //       }
  //       }

  //       prefs.setStringList("customData", cusExits);
  //     });
  //   }
  //   setState(() {
  //     eligibleCust = prefs.getBool("eligibleCust")!;
  //     customExitAdd = prefs.getStringList("customData")!;
  //   });
  // }

  List<String> cusExits = [];

  // saveCustomForUse([eligibleC]) async {
  //   var prefs = await SharedPreferences.getInstance();
  //   prefs.setBool("eligibleCust", eligibleC);

  //   print("inside the saveCustomfor use function");
  //   if (_cusExitNode.text != null || _cusExitNode.text != "") {
  //     setState(() {
  //       cusExits = prefs.getStringList("customData")!;

  //       // for(int i =0;i<customExitAdd.length;i++){
  //       // if(_cusExitNode.text != customExitAdd[i]){
  //       cusExits.add(_cusExitNode.text);

  //       // }
  //       // }
  //       // cusExits.toSet().toList();
  //       prefs.setStringList("customData", cusExits);
  //     });
  //   }
  //   setState(() {
  //     eligibleCust = prefs.getBool("eligibleCust")!;
  //     customExitAdd = prefs.getStringList("customData")!;
  //     // customExitAdd.toSet().toList();
  //   });
  // }

  late bool con;

  Future toggleBelnet(
      [String? exitvalue, String? dns, bool isCustomExit = false]) async {
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
    //  loading = true;
    setState(() {});
  
     await preferences.setBool('oneTimeAddExit', true);
    isAddExitStatus = preferences.getBool('oneTimeAddExit');
      print("isAddExitStatus is having the value $isAddExitStatus");

    // setState(() {
    //   counter++;
    // });

    // Future.delayed(const Duration(milliseconds: 10000), () {
    //   setState(() {
    //     loading = false;
    //     canLoading = false;

    //   });
    // });
    if (mounted) setState(() {});

    if (BelnetLib.isConnected) {
      setState(() {
        loading = true;
      });
      var disConnectValue = await BelnetLib.disconnectFromBelnet();
      appModel.connecting_belnet = false;
      dismiss = true;
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          loading = false;
        });
      });

      if (disConnectValue)
        logController.addDataTolist(" Belnet Daemon stopped..",
            "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
      logController.addDataTolist(" Belnet disconnected",
          "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
    } else {
      setState(() {
        loading = true;
        canLoading = true;
      });

      var f = false;
      Future.delayed(const Duration(seconds: 20), () {
        //milliseconds: 11000
        setState(() {
          loading = false;
          canLoading = false;
        });

        if (isCustomExit) {
          if (myExit) {
            setState(() {
              f = true;

              mystr = "exitnode is valid";

              // saveCustomForUse(
              //     true); // this true or false value is for eligible custom exitnode
            });

            setState(() {
              loading = false;
            });
          } else {
            setState(() {
              mystr = "exitnode is invalid";
            });
            
            print("myExitvalue is $mystr");
            BelnetLib.disconnectFromBelnet();
            logController.addDataTolist(
              "$selectedValue is Invalid Exit Node",
              "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
            );
            setState(() {
              selectedValue =
                  'snoq7arak4d5mkpfsg69saj7bp1ikxyzqjkhzb96keywn6iyhc5y.bdx';
              selectedConIcon =
                  "https://deb.beldex.io/Beldex-projects/Belnet/countryflag/icons8-france.png";
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: appModel.darkTheme
                    ? Colors.black.withOpacity(0.50)
                    : Colors.white,
                behavior: SnackBarBehavior.floating,
                //duration: Duration(milliseconds: 200),
                width: MediaQuery.of(context).size.height*2.5/3,
                content: Text(
                  "Exit Node is Invalid!.switching to default Exit Node",
                  style: TextStyle(
                      color: appModel.darkTheme ? Colors.white : Colors.black),
                  textAlign: TextAlign.center,
                )));
            // await BelnetLib.disconnectFromBelnet();
          }
        }
      });

      if (isCustomExit) {
        if (exitvalue != "") {
          setState(() {
            selectedValue = exitvalue;
            selectedConIcon = "";
          });

//  var f = false;
//     Future.delayed(Duration(seconds: 17), () {
//                               setState(() {
//                                f = true;
//                                 if (myExit) {
//                                   mystr = "exitnode is valid";

//                                   saveCustomForUse(
//                                       true); // this true or false value is for eligible custom exitnode

//                                  // Navigator.pop(context);
//                                 } else {
//                                   mystr = "exitnode is invalid";
//                                   // await BelnetLib.disconnectFromBelnet();
//                                 }
//                               });
//                             });

          Timer timer = Timer.periodic(Duration(seconds: 1), (timer) {
            if (myExit == false && f == false) {
              getDataFromDaemon();
            } else {
              timer.cancel();
            }
          });
        }
      }

      //Save the exit node and upstream dns
      final Settings settings = Settings.getInstance()!;
      settings.exitNode = selectedValue!.trim().toString();
      var myVal = selectedValue!.trim().toString();
      logController.addDataTolist(" Exit node = $myVal",
          "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
      preferences.setString('hintValue', myVal);
      hintValue = preferences.getString('hintValue');
      if (dns == null) {
        logController.addDataTolist("default DNS = 1.1.1.1",
            "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
      }else{
        logController.addDataTolist("DNS = $dns",
            "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
      }

      setState(() {});
      var eIcon = selectedConIcon!.trim().toString();
      preferences.setString('hintCountryicon', eIcon);
      hintCountryIcon = preferences.getString('hintCountryicon');
      print(
          'hint value is stored from getString $hintValue and the hintCountryicon is $hintCountryIcon');
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

      if (mystr == "exitnode is invalid") {
        BelnetLib.disconnectFromBelnet();

        logController.addDataTolist(
          "$selectedValue is Invalid Exit Node",
          "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
        );
      }
    }
  }

  var uploadUnit = ' Mbps';
  var downloadUnit = ' Mbps';
  var uploadValue, kb, mb, gb, downloadValue, kb1, mb1, gb1;

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

//  List<String> customExitAdd = [];
  bool eligibleCust = false;
  saveData() async {
    exitData = [];
    var res = await DataRepo().getListData();
    exitData.addAll(res);

    // if(eligibleCust){

    //   var dat =
    // }

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
    if (netValue == false && isOpen) {
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
                                      bottom:
                                          MediaQuery.of(context).size.height *
                                              0.06 /
                                              3,
                                    ),
                                    child: Text(
                                      'About',
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.06 /
                                              3,
                                          color: appModel.darkTheme
                                              ? Color(0xffAEAEBC)
                                              : Color(0xff747484)),
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
                                  onPressed: loading ? null : toggleBelnet,
                                  isClick: BelnetLib.isConnected,
                                  isLoading: loading),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: mHeight * 0.02 / 3),
                      child: ConnectingStatus(
                        connecting: canLoading,
                        isConnect: BelnetLib.isConnected,
                      ),
                    ),
                    //SizedBox(height: MediaQuery.of(context),)
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: mHeight * 0.10 / 3,
                              top: mHeight * 0.03 / 3),
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
                                                  child: hintCountryIcon != ""
                                                      ? Image.network(
                                                          "$hintCountryIcon",
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return Icon(
                                                              Icons.more_horiz,
                                                              color:
                                                                  Colors.grey,
                                                            );
                                                          },
                                                        )
                                                      : Icon(
                                                          Icons.more_horiz,
                                                          color: Colors.grey,
                                                        )),
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
                                      left: MediaQuery.of(context).size.height * 0.08 / 3,
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
                                      if (isOpen &&
                                          (exitData.isEmpty ||
                                              exitData == [])) {
                                        // exitData.clear();
                                        saveData();
                                        //saveCustomForUse();   //hide for version 1.2.0
                                      }
                                      print("the value of the isOpen $isOpen");

                                      OverlayState? overlayState =
                                          Overlay.of(context);
                                      overlayEntry = OverlayEntry(
                                        builder: (context) {
                                          return _buildExitnodeListView(
                                              mHeight);
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
                                                    child: selectedConIcon != ""
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
                                                        : Icon(
                                                            Icons.more_horiz,
                                                            color: Colors.grey,
                                                          )),
                                                Expanded(
                                                    child: Center(
                                                  child: Text("$selectedValue",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                          color: Color(
                                                              0xff00DC00))),
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

                    /////////////////////////////////////////////////////////////

                    Padding(
                      padding: EdgeInsets.only(
                          left: mHeight * 0.08 / 3,
                          right: mHeight * 0.10 / 3,
                          top: mHeight * 0.03 / 3),
                      child: BelnetLib.isConnected ||
                              (isAddExitStatus == false &&
                                  BelnetLib.isConnected == false)
                          ? Container(
                              padding: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                color: Colors.grey,
                                // boxShadow: [
                                //   BoxShadow(
                                //       color: Colors.black12,
                                //       offset: Offset(-10, -10),
                                //       spreadRadius: 0,
                                //       blurRadius: 10),
                                //   BoxShadow(
                                //       color: Colors.black,
                                //       offset: Offset(10, 10),
                                //       spreadRadius: 0,
                                //       blurRadius: 10)
                                // ],
                                border: Border.all(
                                  color: Color(0xffA1A1C1).withOpacity(0.1),
                                ),
                                gradient: LinearGradient(
                                    colors: appModel.darkTheme
                                        ? [Color(0xff20202B), Color(0xff2C2C39)]
                                        : [
                                            Color(0xffF2F0F0),
                                            Color(0xffFAFAFA)
                                          ]),
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
                              height:
                                  MediaQuery.of(context).size.height * 0.15 / 3,
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
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .height *
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
                                setState(() {
                                  _cusExitNode.text = "";
                                  _cusAuthCode.text = "";
                                });
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
                                  height: MediaQuery.of(context).size.height *
                                      0.15 /
                                      3,
                                  width: double.infinity,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/Add.svg',
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.05 /
                                                3,
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 5.0),
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

                    ////////////////////////////////////////////////////////////////

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

/////////////////////////////////////////

  var invalidExit = "";
  var invalidAuth = "";
  var checkExitVal = false;
  TextEditingController _cusExitNode = TextEditingController();
  TextEditingController _cusAuthCode = TextEditingController();

  var textForExit;
  var textForAuth;
  var isSet = false;
  var color = "blue";

  getValidExitNode() async {
    var fromDaemon = await BelnetLib.getSpeedStatus;
    if (fromDaemon != null) {
      var data1 = Welcome.fromJson(fromDaemon);
      setState(
        () {
          checkExitVal = data1.isConnected;
        },
      );
    }
  }

  // bool myExit = false;
  // var mystr = "";
  // getDataFromDaemon() async {
  //   var fromDaemon = await BelnetLib.getSpeedStatus;
  //   if (fromDaemon != null) {
  //     var data1 = Welcome.fromJson(fromDaemon);

  //     myExit = data1.isConnected;
  //     // if(myEx){
  //     //   setState(() {
  //     //     mystr = "valid exitnode";
  //     //   });
  //     // }else{
  //     //   mystr = "invalid exitnode";
  //     // }
  //     setState(() {});
  //   }
  // }

  // List<String> cusExits = [];

  // saveCustomForUse([eligibleC]) async {
  //   var prefs = await SharedPreferences.getInstance();
  //   prefs.setBool("eligibleCust", eligibleC);
  //   if (_cusExitNode.text != null || _cusExitNode.text != "") {

  //     setState(() {
  //       cusExits = prefs.getStringList("customData")!;

  //       for(int i =0;i<customExitAdd.length;i++){
  //       if(_cusExitNode.text != customExitAdd[i]){
  //       cusExits.add(_cusExitNode.text);

  //       }
  //       }

  //       prefs.setStringList("customData", cusExits);
  //     });
  //   }
  //   setState(() {
  //     eligibleCust = prefs.getBool("eligibleCust")!;
  //     customExitAdd = prefs.getStringList("customData")!;
  //   });
  // }



  
  Widget containerWidget(BuildContext dcontext) {
    bool isAuthCode = false;
    return StatefulBuilder(builder: (dcontext, StateSetter setState) {
      return Container(
        padding: EdgeInsets.all(15.0),
        height: MediaQuery.of(dcontext).size.height * 1.43 / 3,
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
                                    textForAuth = null;
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
              padding: EdgeInsets.only(left: 3.0),
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
                  return null;
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
                'DNS',
                style: TextStyle(
                    color: isAuthCode
                        ? appModel.darkTheme
                            ? Colors.white
                            : Colors.black
                        : Color(0xff90909A), // Color(0xff38384D),
                    fontSize: MediaQuery.of(dcontext).size.height * 0.06 / 3,
                    fontWeight: FontWeight.w900,
                    fontFamily: "Poppins"),
              ),
            ),
            Container(
              height: MediaQuery.of(dcontext).size.height * 0.18 / 3,
              padding: EdgeInsets.only(left: 3.0),
              decoration: BoxDecoration(
                  color: appModel.darkTheme ? Color(0xff292937) : Colors.white,
                  borderRadius: BorderRadius.circular(5.0)),
              child: isAuthCode
                  ? TextFormField(
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                    ],
                      controller: _cusAuthCode,
                      style: TextStyle(color: Color(0xff1994FC)),
                      decoration: InputDecoration(border: InputBorder.none),
                      validator: (value) {
                       
                      },
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
                    'DNS',
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
            // GestureDetector(
            //   onTap: () {
            //     // print('test button clicked');
            //     // if (_cusExitNode.text == null || _cusExitNode.text == "") {
            //     //   setState(() {
            //     //     textForExit = "ExitNode should not be empty";
            //     //     color = "red";
            //     //   });
            //     // } else if (_cusExitNode.text.length != 56) {
            //     //   setState(
            //     //     () {
            //     //       textForExit = "Invalid range of exit node";
            //     //     },
            //     //   );
            //     // } else if (_cusExitNode.text.isNotEmpty &&
            //     //     !_cusExitNode.text.contains(".bdx")) {
            //     //   setState(() {
            //     //     textForExit = "Please enter a valid Exit Node";
            //     //     print(
            //     //         "is contain method call ${!_cusExitNode.text.contains(".bdx")}");
            //     //     color = "red";
            //     //   });
            //     // } else {
            //     //   //check number of characters
            //     //   if (_cusExitNode.text.contains(
            //     //       RegExp(r"^(?=.*[a-zA-Z])(?=.*[0-9])[A-Za-z0-9]+$"))) {
            //     //     //if(_cusExitNode.text.contains(".bdx")){
            //     //     setState(() {
            //     //       textForExit = null;
            //     //       isSet = true;
            //     //       color = "green";
            //     //     });
            //     //     //}
            //     //   }
            //     // }

            //     // print("isSet value $isSet");
            //     // if(_cusAuthCode.text.isNotEmpty)
            //   },
            //   child: Padding(
            //     padding: const EdgeInsets.only(top: 8.0),
            //     child: Container(
            //         padding: EdgeInsets.all(8.0),
            //         decoration: BoxDecoration(
            //             borderRadius: BorderRadius.circular(12.0),
            //             color: Colors.grey,
            //             gradient: color == "blue"
            //                 ? LinearGradient(
            //                     colors: [Color(0xff007ED1), Color(0xff0093FF)])
            //                 : color == "red"
            //                     ? LinearGradient(colors: [
            //                         Color(0xffE50012),
            //                         Color(0xffFF1A23)
            //                       ])
            //                     : color == "green"
            //                         ? LinearGradient(colors: [
            //                             Color(0xff00B504),
            //                             Color(0xff23DC27)
            //                           ])
            //                         : LinearGradient(colors: []),
            //             boxShadow: appModel.darkTheme
            //                 ? [
            //                     // BoxShadow(
            //                     //     color: Colors.black12,
            //                     //     offset: Offset(-10, -10),
            //                     //     spreadRadius: 0,
            //                     //     blurRadius: 10),
            //                     BoxShadow(
            //                         color: Colors.black,
            //                         offset: Offset(0, 1),
            //                         blurRadius: 2.0)
            //                   ]
            //                 : [
            //                     BoxShadow(
            //                         color: Color(0xff6E6E6E),
            //                         offset: Offset(0, 1),
            //                         blurRadius: 2.0)
            //                   ]),
            //         height: MediaQuery.of(dcontext).size.height * 0.18 / 3,
            //         width: double.infinity,
            //         child: Row(
            //           mainAxisAlignment: MainAxisAlignment.center,
            //           children: [
            //             color == "red"
            //                 ? SvgPicture.asset(
            //                     'assets/images/icons8-error.svg',
            //                     height: MediaQuery.of(dcontext).size.height *
            //                         0.05 /
            //                         3,
            //                   )
            //                 : color == "green"
            //                     ? SvgPicture.asset(
            //                         'assets/images/icons8-error.svg',
            //                         height:
            //                             MediaQuery.of(dcontext).size.height *
            //                                 0.05 /
            //                                 3,
            //                       )
            //                     : Container(),
            //             Padding(
            //               padding: const EdgeInsets.only(left: 5.0),
            //               child: Text( // print('test button clicked');
            //       // if (_cusExitNode.text == null || _cusExitNode.text == "") {
            //       //   setState(() {
            //       //     textForExit = "ExitNode should not be empty";
            //       //     color = "red";
            //       //   });
            //       // } else if (_cusExitNode.text.length != 56) {
            //       //   setState(
            //       //     () {
            //       //       textForExit = "Invalid range of exit node";
            //       //     },
            //       //   );
            //       // } else if (_cusExitNode.text.isNotEmpty &&
            //       //     !_cusExitNode.text.contains(".bdx")) {
            //       //   setState(() {
            //       //     textForExit = "Please enter a valid Exit Node";
            //       //     print(
            //       //         "is contain method call ${!_cusExitNode.text.contains(".bdx")}");
            //       //     color = "red";
            //       //   });
            //       // } else {
            //       //   //check number of characters
            //       //   if (_cusExitNode.text.contains(
            //       //       RegExp(r"^(?=.*[a-zA-Z])(?=.*[0-9])[A-Za-z0-9]+$"))) {
            //       //     //if(_cusExitNode.text.contains(".bdx")){
            //       //     setState(() {
            //       //       textForExit = null;
            //       //       isSet = true;
            //       //       color = "green";
            //       //     });
            //       //     //}

            //       //     var isOk = false;
            //       //     setState(
            //       //       () {
            //       //         isOk = isOk ? false : true;
            //       //       },
            //       //     );
            //       //     if (isOk) {
            //       //       var flag = false;

            //       //       con = await BelnetLib.connectToBelnet(
            //       //           exitNode: _cusExitNode.text, upstreamDNS: "");

            //       //       try {
            //       //         Future.delayed(const Duration(milliseconds: 1000),
            //       //             (() async {
            //       //           final result = await InternetAddress.lookup(
            //       //               'https://stackoverflow.com/');
            //       //           if (result.isNotEmpty &&
            //       //               result[0].rawAddress.isNotEmpty) {
            //       //             print('verified exit! ');
            //       //             print("what is inside the result $result");
            //       //           } else {
            //       //             print("invalid exits");
            //       //           }
            //       //         }));
            //       //       } catch (e) {
            //       //         print(e);
            //       //       }

            //       //       //   Timer _timer;
            //       //       //     con = await BelnetLib.connectToBelnet(
            //       //       // exitNode: _cusExitNode.text, upstreamDNS: "");

            //       //       //   Future.delayed(const Duration(milliseconds: 7000),(() {
            //       //       //      setState(() {
            //       //       //         flag = true;
            //       //       //      },);
            //       //       //   }));
            //       //       //     while(!flag){
            //       //       //        _timer = Timer.periodic(Duration(seconds: 1), (timer) async{
            //       //       //         getValidExitNode();
            //       //       //         print("the exit node is $checkExitVal");
            //       //       //     });
            //       //       //     }
            //       //       //     if(checkExitVal == true){
            //       //       //       Navigator.pop(context);
            //       //       //     }else{
            //       //       //       print("no valid exit");
            //       //       //     }

            //       //     } else {
            //       //       await BelnetLib.disconnectFromBelnet();
            //       //     }
            //       //   }
            //                 "Test",
            //                 style: TextStyle(
            //                     fontFamily: "Poppins",
            //                     fontWeight: FontWeight.w900),
            //               ),
            //             ),
            //           ],
            //         )),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: GestureDetector(
                onTap: () {
                  setState(
                    () {
                      textForExit = "";
                      textForAuth = "";
                    },
                  );

                  if (_cusExitNode.text == null || _cusExitNode.text == "") {
                    setState(() {
                      textForExit = "Exitnode should not  be empty";
                      color = "red";
                    });
                  } else if (_cusExitNode.text.length != 56) {
                    setState(() {
                      textForExit = "Please enter a valid Exit Node";
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
                    if(!isAuthCode && _cusAuthCode.text.isEmpty){
                       toggleBelnet(_cusExitNode.text, _cusAuthCode.text, true);
                    Navigator.pop(context);
                     
                    }else if(isAuthCode && _cusAuthCode.text.isNotEmpty){
                        if(_cusAuthCode.text == "1.1.1.1" || _cusAuthCode.text == "9.9.9.9"){
                          toggleBelnet(_cusExitNode.text, _cusAuthCode.text, true);
                           Navigator.pop(context);
                        }else{
                          setState((() {
                            textForAuth = "Please enter a valid DNS"; 
                          }));
                        }
                    }
                   
                  }
                }, //basicValidation, //customExitConnection,

                //{

                // if (_cusExitNode.text == null || _cusExitNode.text == "") {
                //   setState(() {
                //     textForExit = "ExitNode should not be empty";
                //     color = "red";
                //   });
                // } else if (_cusExitNode.text.length != 56) {
                //   setState(
                //     () {
                //       textForExit = "Invalid range of exit node";
                //     },
                //   );
                // } else if (_cusExitNode.text.isNotEmpty &&
                //     !_cusExitNode.text.contains(".bdx")) {
                //   setState(() {
                //     textForExit = "Please enter a valid Exit Node";
                //     print(
                //         "is contain method call ${!_cusExitNode.text.contains(".bdx")}");
                //     color = "red";
                //   });
                // } else {
                //   //check number of characters
                //   if (_cusExitNode.text.contains(
                //       RegExp(r"^(?=.*[a-zA-Z])(?=.*[0-9])[A-Za-z0-9]+$"))) {
                //     //if(_cusExitNode.text.contains(".bdx")){
                //     setState(() {
                //       textForExit = null;
                //       isSet = true;
                //       color = "green";
                //     });
                //     //}

                // }

                //}

                // print('test button clicked');
                // if (_cusExitNode.text == null || _cusExitNode.text == "") {
                //   setState(() {
                //     textForExit = "ExitNode should not be empty";
                //     color = "red";
                //   });
                // } else if (_cusExitNode.text.length != 56) {
                //   setState(
                //     () {
                //       textForExit = "Invalid range of exit node";
                //     },
                //   );
                // } else if (_cusExitNode.text.isNotEmpty &&
                //     !_cusExitNode.text.contains(".bdx")) {
                //   setState(() {
                //     textForExit = "Please enter a valid Exit Node";
                //     print(
                //         "is contain method call ${!_cusExitNode.text.contains(".bdx")}");
                //     color = "red";
                //   });
                // } else {
                //   //check number of characters
                //   if (_cusExitNode.text.contains(
                //       RegExp(r"^(?=.*[a-zA-Z])(?=.*[0-9])[A-Za-z0-9]+$"))) {
                //     //if(_cusExitNode.text.contains(".bdx")){
                //     setState(() {
                //       textForExit = null;
                //       isSet = true;
                //       color = "green";
                //     });
                //     //}

                //     var isOk = false;
                //     setState(
                //       () {
                //         isOk = isOk ? false : true;
                //       },
                //     );
                //     if (isOk) {
                //       var flag = false;

                //       con = await BelnetLib.connectToBelnet(
                //           exitNode: _cusExitNode.text, upstreamDNS: "");

                //       try {
                //         Future.delayed(const Duration(milliseconds: 1000),
                //             (() async {
                //           final result = await InternetAddress.lookup(
                //               'https://stackoverflow.com/');
                //           if (result.isNotEmpty &&
                //               result[0].rawAddress.isNotEmpty) {
                //             print('verified exit! ');
                //             print("what is inside the result $result");
                //           } else {
                //             print("invalid exits");
                //           }
                //         }));
                //       } catch (e) {
                //         print(e);
                //       }

                //       //   Timer _timer;
                //       //     con = await BelnetLib.connectToBelnet(
                //       // exitNode: _cusExitNode.text, upstreamDNS: "");

                //       //   Future.delayed(const Duration(milliseconds: 7000),(() {
                //       //      setState(() {
                //       //         flag = true;
                //       //      },);
                //       //   }));
                //       //     while(!flag){
                //       //        _timer = Timer.periodic(Duration(seconds: 1), (timer) async{
                //       //         getValidExitNode();
                //       //         print("the exit node is $checkExitVal");
                //       //     });
                //       //     }
                //       //     if(checkExitVal == true){
                //       //       Navigator.pop(context);
                //       //     }else{
                //       //       print("no valid exit");
                //       //     }

                //     } else {
                //       await BelnetLib.disconnectFromBelnet();
                //     }
                //  }
                // }

                //_timer.cancel();

                // if (isSet) {
                //   setState(() {
                //     print("Simply clicked");

                //     exitItems.insert(0, _cusExitNode.text);

                //     invalidExit = "";
                //     invalidAuth = "";

                //     // _cusExitNode.dispose();
                //     // _cusAuthCode.dispose();

                //     textForExit = null;
                //     //textForAuth = null;
                //     isSet = false;
                //     color = "blue";
                //   });
                //   Navigator.pop(dcontext);
                // }
                //  },
                child: Container(
                    //padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.grey,
                        gradient:
                            // appModel.darkTheme
                            //     ?
                            // isSet
                            //     ?
                            LinearGradient(
                                colors: [Color(0xff007ED1), Color(0xff0093FF)]),
                        // : LinearGradient(colors: [
                        //     Color(0xff20202B),
                        //     Color(0xff2C2C39)
                        //   ])
                        // :
                        // // isSet
                        // //     ?
                        // //     LinearGradient(colors: [
                        // //         Color(0xff007ED1),
                        // //         Color(0xff0093FF)
                        // //       ])
                        // //     :
                        // LinearGradient(
                        //     colors: [Color(0xffF2F0F0), Color(0xffFAFAFA)]),
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
                    child: isCheckLoad
                        ? Expanded(
                            child: LinearPercentIndicator(
                              lineHeight:
                                  MediaQuery.of(context).size.height * 0.30 / 3,
                              padding: EdgeInsets.zero,
                              animation: true,
                              animationDuration: 10000,
                              barRadius: Radius.circular(12.0),
                              percent: 1.0,
                              backgroundColor: Color(0xffA8A8B7),
                              progressColor: Color(0xff007ED1),
                            ),
                          )
                        :
                        // isCheckLoad
                        // ? Center(child: CircularProgressIndicator())
                        // :

                        Center(
                            child: Text(
                            "OK",
                            style: TextStyle(
                                color: //isSet ?
                                    Colors.white, // : Color(0xff56566F),
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

//////////////////////////////////

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
              top: mHeight * 1.87 / 3, //2.010
              bottom: MediaQuery.of(context).size.height * 0.38 / 3,
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
              borderRadius: BorderRadius.circular(4.0),
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
                      //initiallyExpanded: true,
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
                        // exitData[index].type == "Custom Exit Node" &&
                        //         customExitAdd.isNotEmpty
                        //     ? "${customExitAdd.length} Nodes":
                        "${exitData[index].node.length} Nodes",
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize:
                                MediaQuery.of(context).size.height * 0.04 / 3),
                      ),
                      children: <Widget>[
                        Column(
                          children: _buildExpandableContent(
                              exitData[index].node, exitData[index].type),
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
  //           width: MedtrueiaQuery.of(context).size.height * 0.060 / 3,
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

  _buildExpandableContent(List<exitNodeModel.Node> vnode, String type) {
    List<Widget> columnContent = [];
    for (int i = 0; i < vnode.length; i++) {
      columnContent.add(Container(
        padding: EdgeInsets.only(
            left: MediaQuery.of(context).size.height * 0.06 / 3,
            right: MediaQuery.of(context).size.height * 0.06 / 3,
            top: MediaQuery.of(context).size.height * 0.02 / 3,
            bottom: MediaQuery.of(context).size.height * 0.02 / 3),
        height: MediaQuery.of(context).size.height * 0.19 / 3,
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    width: 0.5, color: Color(0xff56566F).withOpacity(0.2)))),
        child: GestureDetector(
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
                          return Icon(
                            Icons.more_horiz,
                            color: Colors.grey,
                            size: 0.4,
                          );
                        },
                        // height: MediaQuery.of(context).size.height * 0.10 / 3,
                        // width: MediaQuery.of(context).size.height * 0.15 / 3,
                        fit: BoxFit.fill,
                      )
                    : Icon(Icons.info_outline_rounded),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(
                      left: MediaQuery.of(context).size.height * 0.05 / 3,
                      right: MediaQuery.of(context).size.height * 0.05 / 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          vnode[i].name,
                          style: TextStyle(
                              color: appModel.darkTheme
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: MediaQuery.of(context).size.height *
                                  0.05 /
                                  3),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Text(
                        vnode[i].country,
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize:
                                MediaQuery.of(context).size.height * 0.04 / 3),
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
                padding: EdgeInsets.only(
                    right: MediaQuery.of(context).size.height * 0.05 / 3),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: vnode[i].isActive == "true"
                        ? Colors.green
                        : Colors.red),
              ),
            ],
          ),
        ),
      ));
    }

    // if (customExitAdd.isNotEmpty && type == "Custom Exit Node") {
    //   for (int i = 0; i < customExitAdd.length; i++) {
    //     columnContent.add(Container(
    //       padding: EdgeInsets.only(
    //           left: MediaQuery.of(context).size.height * 0.06 / 3,
    //           right: MediaQuery.of(context).size.height * 0.06 / 3,
    //           top: MediaQuery.of(context).size.height * 0.02 / 3,
    //           bottom: MediaQuery.of(context).size.height * 0.02 / 3),
    //       height: MediaQuery.of(context).size.height * 0.19 / 3,
    //       decoration: BoxDecoration(
    //           border: Border(
    //               bottom: BorderSide(
    //                   width: 0.5, color: Color(0xff56566F).withOpacity(0.2)))),
    //       child: GestureDetector(
    //         onTap: () async {
    //           setState(() {
    //             valueS = customExitAdd[i];
    //             selectedValue = customExitAdd[i];
    //             selectedConIcon = null;
    //           });
    //           overlayEntry?.remove();
    //           SharedPreferences preferences =
    //               await SharedPreferences.getInstance();
    //           preferences.setString('hintValue', selectedValue.toString());
    //           preferences.setString(
    //               'hintContryicon', selectedConIcon.toString());
    //           print("$i th index value $valueS ");
    //         },
    //         child: Row(
    //           //crossAxisAlignment: CrossAxisAlignment.center,
    //           children: [
    //             // Container(
    //             //     //color:Colors.yellow,
    //             //     height: MediaQuery.of(context).size.height * 0.050 / 3,
    //             //     width: MediaQuery.of(context).size.height * 0.060 / 3,
    //             //     child: Text("")
    //             //     // vnode[i].icon.isNotEmpty
    //             //     //     ? Image.network(
    //             //     //         vnode[i].icon,
    //             //     //         errorBuilder: (context, error, stackTrace) {
    //             //     //           return Icon(
    //             //     //             Icons.more_horiz,
    //             //     //             color: Colors.grey,
    //             //     //             size: 0.4,
    //             //     //           );
    //             //     //         },
    //             //     //         // height: MediaQuery.of(context).size.height * 0.10 / 3,
    //             //     //         // width: MediaQuery.of(context).size.height * 0.15 / 3,
    //             //     //         fit: BoxFit.fill,
    //             //     //       )
    //             //     //     : Icon(Icons.info_outline_rounded),
    //             //     ),
    //             Expanded(
    //               child: Container(
    //                 padding: EdgeInsets.only(
    //                     left: MediaQuery.of(context).size.height * 0.05 / 3,
    //                     right: MediaQuery.of(context).size.height * 0.05 / 3),
    //                 child: Text(
    //                   customExitAdd[i],
    //                   style: TextStyle(
    //                       color: appModel.darkTheme
    //                           ? Colors.white
    //                           : Colors.black,
    //                       fontSize: MediaQuery.of(context).size.height *
    //                           0.05 /
    //                           3),
    //                   overflow: TextOverflow.ellipsis,
    //                   maxLines: 1,
    //                 ),
    //               ),
    //             ),
    //             Container(
    //                 height: MediaQuery.of(context).size.height * 0.050 / 3,
    //                 width: MediaQuery.of(context).size.height * 0.060 / 3,
    //                 padding: EdgeInsets.only(
    //                     right: MediaQuery.of(context).size.height * 0.05 / 3,
    //                     bottom: 10.0,
    //                     top: 0.0),
    //                 child: GestureDetector(
    //                   onTap: (){

    //                     setState(() {
    //                       print("before delete $customExitAdd");
    //                       customExitAdd.remove(customExitAdd[i]);
    //                       print("after delete $customExitAdd");
    //                     });
    //                   },
    //                   child: Icon(Icons.close, color: Colors.green, size: 15.0))
    //                 // // decoration: BoxDecoration(
    //                 // //     shape: BoxShape.circle,
    //                 // //     color:
    //                 // //          Colors.green
    //                 //         ),
    //                 ),
    //           ],
    //         ),
    //       ),
    //     ));
    //   }
    // }

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
