import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:belnet_mobile/displaylog.dart';
import 'package:belnet_mobile/node_provider.dart';
import 'package:belnet_mobile/src/app_list.dart';
import 'package:belnet_mobile/src/app_list_provider.dart';
import 'package:belnet_mobile/src/fetch_ip.dart';
import 'package:belnet_mobile/src/model/exitnodeModel.dart';
import 'package:belnet_mobile/src/model/exitnodeRepo.dart';
import 'package:belnet_mobile/src/model/exitnodeCategoryModel.dart'
    as exitNodeModel;
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/providers/internet_checking_provider.dart';
import 'package:belnet_mobile/src/providers/introstate_provider.dart';
import 'package:belnet_mobile/src/providers/ip_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/providers/log_provider.dart';
import 'package:belnet_mobile/src/providers/speed_chart_provider.dart';
import 'package:belnet_mobile/src/providers/vpn_provider.dart';
import 'package:belnet_mobile/src/splash_screen.dart';
import 'package:belnet_mobile/src/utils/styles.dart';
import 'package:belnet_mobile/src/widget/LineChartSample10.dart';
import 'package:belnet_mobile/src/widget/aboutpage.dart';
import 'package:belnet_mobile/src/widget/appUpdate.dart';
import 'package:belnet_mobile/src/widget/bottomnavbaroptions.dart';
import 'package:belnet_mobile/src/widget/connecting_status.dart';
import 'package:belnet_mobile/src/widget/exit_node_list.dart';
import 'package:belnet_mobile/src/widget/expandablelist.dart';
import 'package:belnet_mobile/src/widget/local_notifications.dart';
import 'package:belnet_mobile/src/widget/logProvider.dart';
import 'package:belnet_mobile/src/widget/modelResponse.dart';
import 'package:belnet_mobile/src/widget/nointernet_connection.dart';
// import 'package:belnet_mobile/src/widget/logProvider.dart';
import 'package:belnet_mobile/src/widget/notifications.dart';
import 'package:belnet_mobile/src/widget/notifications_controller.dart';
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
//import 'package:in_app_update/in_app_update.dart';
// import 'package:native_updater/native_updater.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart' as pr;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

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

  // await LocalNotificationService.initializedNotification();
  await AwesomeNotifications()
      .initialize("resource://drawable/res_notification_app_icon", [
    NotificationChannel(
        channelGroupKey: "basic_channel_group",
        channelKey: "belnets_channel",
        channelName: "Belnet notification",
        channelDescription: "Belnet notification channel",
        //icon: "assets/images/belnet_ic.png",
        locked: true,
        importance: NotificationImportance.Low)
  ], channelGroups: [
    NotificationChannelGroup(
        channelGroupKey: "basic_channel_group", channelGroupName: "Basic group")
  ]);
  bool isNotificationAllowed =
      await AwesomeNotifications().isNotificationAllowed();
  if (!isNotificationAllowed) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }
  //Paint .enableDithering = true;
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

class _BelnetAppState extends State<BelnetApp>  with WidgetsBindingObserver{
  // This widget is the root of your application.

  AppModel appModel = new AppModel();
  bool canHideSplash = false;
  void _initAppTheme() async {
    appModel.darkTheme = await appModel.appPreference.getTheme();
  }

  @override
  void initState() {
    super.initState();
    //SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.addObserver(this);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));
    checkShowSpalsh();
   // getRandomExitData();
    _initAppTheme();
  }





checkShowSpalsh()async{
  setState(() { });
  print('THE SPLASH SCREEN HIDE OR NOT');
  var isRun = await BelnetLib.isRunning;
  if(isRun){
    setState(() {
           canHideSplash = true;
    });
      print('THE SPLASH SCREEN HIDE OR NOT 11 $isRun --- $canHideSplash');
    
  }else{

    canHideSplash = false;
      print('THE SPLASH SCREEN HIDE OR NOT 22 $isRun --- $canHideSplash');

  }
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




@override
  void dispose() {
        WidgetsBinding.instance.removeObserver(this);

   // AwesomeNotifications().requestPermissionToSendNotifications()
    super.dispose();
  }

////////////////////////////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
 return pr.MultiProvider(
      providers: [
        pr.ChangeNotifierProvider<AppModel>.value(value: appModel),
        pr.ChangeNotifierProvider<NotificationProvider>(
          create: (context) => NotificationProvider(),
        ),
        pr.ChangeNotifierProvider<NodeProvider>(create: (_)=> NodeProvider()..fetchNodes()),
        pr.ChangeNotifierProvider<VpnConnectionProvider>(create: (_)=> VpnConnectionProvider()),
        pr.ChangeNotifierProvider<IpProvider>(create: (_)=> IpProvider()),
        pr.ChangeNotifierProvider<LogProvider>(create: (_)=>LogProvider()),
        pr.ChangeNotifierProvider<ConnectivityProvider>(create: (_)=> ConnectivityProvider()),
        pr.ChangeNotifierProvider<IntroStateProvider>(create: (_)=>IntroStateProvider()),
        pr.ChangeNotifierProvider<SpeedChartProvider>(create: (_)=> SpeedChartProvider()),
        pr.ChangeNotifierProvider<LoaderVideoProvider>(create: (_)=> LoaderVideoProvider()..initialize(appModel.darkTheme ? 'assets/images/dark_theme/Loading_v1_slow.webm' : 'assets/images/light_theme/loading_white_theme.webm')),
                pr.ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
        pr.ChangeNotifierProvider<AppSelectionProvider>(create: (_)=>AppSelectionProvider()..loadSelectedApps(),),
        pr.ChangeNotifierProvider<AppSelectingProvider>(create: (_)=>AppSelectingProvider())
      ],
      child: pr.Consumer<AppModel>(
        builder: (context, appModel, child) {
          return GetMaterialApp(
            title: 'Belnet App',
            debugShowCheckedModeBanner: false,
            theme: appModel.darkTheme ? buildDarkTheme() : buildLightTheme(),
            home: canHideSplash ? MainBottomNavbar() : SplashScreens(), //BelnetHomePage()
          );
        },
      ),
    );

    // return pr.ChangeNotifierProvider<AppModel>.value(
    //   value: appModel,
    //   child: pr.Consumer<AppModel>(builder: (context, value, child) {
    //     return pr.ChangeNotifierProvider(
    //       create: (context) => NotificationProvider(),
    //       child: GetMaterialApp(
    //         title: 'Belnet App',
    //         debugShowCheckedModeBanner: false,
    //         theme: appModel.darkTheme ? buildDarkTheme() : buildLightTheme(),
    //           home: SplashScreens() //BelnetHomePage(),
    //   ),
    // );
    //   }),
    // );
  }
}

List<String> exitItems = [];

class BelnetHomePage extends StatefulWidget {
  BelnetHomePage({Key? key}) : super(key: key);

  @override
  BelnetHomePageState createState() => BelnetHomePageState();
}

class BelnetHomePageState extends State<BelnetHomePage> {
  late List<ConnectivityResult> connectivityResult;
  LogController logControllers = Get.put(LogController());
 // AppUpdateInfo? updateInfo;
  late Timer timer;
  @override
  void initState() {
     
   timer = Timer.periodic(Duration(seconds: 5), (timer) {
      myNetwork();
    });
    setState(() {});
    //  getExitnodeListDataFromAPI();
    super.initState();
  }

// Future<void> _checkForAppUpdate(BuildContext context)async{
//     UpgradeAlert(
//       upgrader: Upgrader(
//       ),
//       child: ,
//     );
// }

 
  // Future<void> checkVersion(BuildContext context) async {
  //   /// For example: You got status code of 412 from the
  //   /// response of HTTP request.
  //   /// Let's say the statusCode 412 requires you to force update
  //   final statusCode = 412;

  //   /// This could be kept in our local
  //   // final localVersion = 9;

  //   /// This could get from the API
  //   //final serverLatestVersion = 10;

  //   Future.delayed(Duration.zero, () {
  //     if (statusCode == 412) {
  //       NativeUpdater.displayUpdateAlert(
  //         context,
  //         forceUpdate: true,
  //         appStoreUrl: '',
  //         playStoreUrl:
  //             'https://play.google.com/store/apps/details?id=io.beldex.belnet',
  //         iOSDescription:
  //             'A new version of the Belnet application is available. Update to continue using it.',
  //         iOSUpdateButtonLabel: 'Upgrade',
  //         iOSCloseButtonLabel: 'Exit',
  //         iOSAlertTitle: 'Mandatory Update',
  //       );
  //     } /* else if (serverLatestVersion > localVersion) {
  //       NativeUpdater.displayUpdateAlert(
  //         context,
  //         forceUpdate: true,
  //         appStoreUrl: 'https://apps.apple.com/in/app/beldex-official-wallet/id1603063369',
  //         playStoreUrl: 'https://play.google.com/store/apps/details?id=io.beldex.wallet',
  //         iOSDescription: 'Your App requires that you update to the latest version. You cannot use this app until it is updated.',
  //         iOSUpdateButtonLabel: 'Upgrade',
  //         iOSCloseButtonLabel: 'Exit',
  //       );*/
  //   });
  // }

  myNetwork() async {
    connectivityResult = await (Connectivity().checkConnectivity());
    if(connectivityResult.contains(ConnectivityResult.wifi)){
       setState(() {});
       netValue = true;
    }else  if(connectivityResult.contains(ConnectivityResult.ethernet)){
       setState(() {});
       netValue = true;
    }else  if(connectivityResult.contains(ConnectivityResult.mobile)){
       setState(() {});
       netValue = true;
    }else  if(connectivityResult.contains(ConnectivityResult.none)){
       setState(() {});
       netValue = false;
    }else{
      print('Error occured while checking network');
    }
  }

  @override
  void dispose() {
    timer.cancel();
    //AwesomeNotifications();
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
        : UpgradeAlert(
          showIgnore: false,
          showLater: false,
            upgrader: Upgrader(
             // debugLogging: true
            ),
            child: Container(
              decoration: BoxDecoration(
                color:
                    appModel.darkTheme ? Color(0xFF242430) : Color(0xFFF9F9F9),
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
            ),
          );
  }
}

// global list for exitnode

// Create a Form widget.

dynamic downloadRate = '';
dynamic uploadRate = '';
String? selectedValue = 'exit.bdx';
    //'5n6w1xd8hazxu68mrnahtupbyocqhehfy8xhnttttby64e3g3k6y.bdx';
String? selectedConIcon =
    "https://belnet-exitnode.s3.ap-south-1.amazonaws.com/countryflag/icons8-france.png";
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

class MyFormState extends State<MyForm> with SingleTickerProviderStateMixin, WidgetsBindingObserver 
{
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
  bool canValidateExit= false;
late Timer? timer1;
bool f = false;
  @override
  initState() {
    super.initState();
   WidgetsBinding.instance.addObserver(this);
    _isConnectedEventSubscription = BelnetLib.isConnectedEventStream
        .listen((bool isConnected) => setState(() {
          vpnStatus(context,isConnected);
         // showMyNotification(context,isConnected);
        }));
    //callForUpdate();
    // getConnectingData();
    getRandomExitNodes();
    saveData();
     
   // showNotification(pr.Provider.of<AppModel>(context,listen: false));
  }

// void showMyNotification(BuildContext context, bool isConnected){
//   var appModel = pr.Provider.of<AppModel>(context,listen: false);
//   if(isConnected){
//     showNotification(appModel);
//   }{
//     _dismissNotification();
//   }
// }

int count = 0;
 void vpnStatus(BuildContext context,bool isConnected)async{
   bool val = await BelnetLib.isRunning;
   setState(() {
     
   });
   if(isConnected == false){
   try{
    AwesomeNotifications().cancel(10);
   }catch(e){
   }
    
   }
   if (loading == true) {
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
            //SystemNavigator.pop();
           await _disconnectFromBelnet();
           setState(() {
             
           });
           count = 0;
           canLoading = false;
          }
        }
        //});
      }
 }

 @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
  try{
   if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      timer1?.cancel();
      AwesomeNotifications().cancel(10); // Cancel the notification with id 10
    }
  }catch(e){
}
   
  }




//  @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // TODO: implement didChangeAppLifecycleState
//    print('BELNET Applifecycle state--- $state ');
//     super.didChangeAppLifecycleState(state);
//     switch(state){
      
//       case AppLifecycleState.detached:
//      print('BELNET Applifecycle state--- $state ');
//         //Future.delayed(const Duration(microseconds: 100),()=> stopNotification());
//          AwesomeNotifications().dismissAllNotifications();
//         break;
//       case AppLifecycleState.resumed:
      
//         break;
//       case AppLifecycleState.inactive:
//        break;
//       case AppLifecycleState.hidden:
//         break;
//       case AppLifecycleState.paused:
//         break;
//     }
//   }















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
    setState(() {
     hintValue = preference.getString('hintValue');
    hintCountryIcon = preference.getString('hintCountryicon');
    isAddExitStatus = preference.getBool('onFreshInitAddExit') ?? false;
   // isAddExitStatus = preference.getBool('oneTimeAddExit') ?? false;
    print("value of isAddExitStatus onFreshInitAddExit is $isAddExitStatus");
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  
    stopNotification();
    _isConnectedEventSubscription?.cancel();
    //timer1.cancel();
   // AwesomeNotifications().dismissAllNotifications();
    AwesomeNotifications().cancel(10);
    overlayEntry!.remove();
       super.dispose();
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
      setState(() {});
    }
  }
 
  List<String> cusExits = [];

  late bool con;
  


Future<void> toggleBelnet([String? exitvalue, String? dns, bool isCustomExit = false]) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  appModel.uploadList.addAll(SpeedMapData().sampleUpData);
  appModel.downloadList.addAll(SpeedMapData().sampleDownData);
  if (!BelnetLib.isConnected) {
    print('${DateTime.now().microsecondsSinceEpoch} netvalue from disconnected --');
    appModel.singleDownload = "";
    appModel.singleUpload = "";
  }

  await preferences.setBool('onFreshInitAddExit', true);
  //await preferences.setBool('oneTimeAddExit', true);
  isAddExitStatus = preferences.getBool('onFreshInitAddExit');
  //isAddExitStatus = preferences.getBool('oneTimeAddExit');
  print("isAddExitStatus is having the value $isAddExitStatus");

  setState(() {});

  if (BelnetLib.isConnected) {
    await _disconnectFromBelnet();
  } else {
    await _connectToBelnet(exitvalue, dns, isCustomExit);
  }

  setState(() {});
}

Future<void> _disconnectFromBelnet() async {
  setState(() => loading = true);
  bool disConnectValue = await BelnetLib.disconnectFromBelnet();
  appModel.connecting_belnet = false;

  if (disConnectValue) {
    logController.addDataTolist(" Belnet Daemon stopped..",
        "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
    logController.addDataTolist(" Belnet disconnected",
        "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
  }
stopNotification();
  Future.delayed(const Duration(seconds: 2), () {
    setState(() => loading = false);
  });
  
}

Future<void> _connectToBelnet(String? exitvalue, String? dns, bool isCustomExit) async {
  setState(() {
    loading = true;
    canLoading = true;
   // canValidateExit = false;
  });

  Future.delayed(const Duration(seconds: 20), () {
    setState(() {
      loading = false;
      canLoading = false;
      if(isCustomExit){
            _checkingExitnodeAfterDelay();
      }
    });
  });

  if (isCustomExit) {
    await _handleCustomExitNode(exitvalue);
  }

  await _saveSettings(exitvalue, dns);

  final result = await BelnetLib.prepareConnection();
  if (!result) {
    setState(() => loading = false);
    return;
  }

  if (await BelnetLib.isPrepared) {
    appModel.connecting_belnet = true;
  }
 print('CustomExitnode checking start ${Settings.getInstance()!.exitNode!}');
  bool con = await BelnetLib.connectToBelnet(
    exitNode: Settings.getInstance()!.exitNode!,
    upstreamDNS: dns != null && dns.isNotEmpty ? dns : "9.9.9.9",
  );
print('CustomExitnode checking end');
  if (con) {
    Future.delayed(Duration(seconds: 4), () => showNotification(appModel));
    Future.delayed(Duration(seconds: 19), () {
      logController.addDataTolist(" Connected successfully",
          "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
         
  //         if(BelnetLib.isConnected){
  //   showNotification(appModel);
  // }
    });
    appModel.connecting_belnet = true;
  } else {
    setState(() => loading = false);
  }
  
  if (mystr == "exitnode is invalid") {
    await BelnetLib.disconnectFromBelnet();

    logController.addDataTolist("$selectedValue is Invalid Exit Node",
        "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
  }
  // if(BelnetLib.isConnected){
  //   showNotification(appModel);
  // }
  setState(() {});
}

Future<void> _handleCustomExitNode(String? exitvalue) async {
  

  if (exitvalue != null && exitvalue.isNotEmpty) {
    setState(() {
      selectedValue = exitvalue;
      selectedConIcon = "";
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!myExit && !f) {
        getDataFromDaemon();
      } else {
        timer.cancel();
      }
    });
  }
 //if(canValidateExit){
  //  if (myExit) {
  //   setState(() {
  //     f = true;
  //     mystr = "exitnode is valid";
  //    // loading = false;
  //   });
  // } else {
  //   setState(() {
  //     mystr = "exitnode is invalid";
  //   });
  //   print("myExitvalue is $mystr");
  //   await BelnetLib.disconnectFromBelnet();
  //   logController.addDataTolist(
  //     "$selectedValue is Invalid Exit Node",
  //     "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
  //   );
  //   setState(() {
  //     selectedValue =
  //         'exit.bdx';
  //     selectedConIcon =
  //         "https://belnet-exitnode.s3.ap-south-1.amazonaws.com/countryflag/icons8-france.png";
  //   });
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       backgroundColor: appModel.darkTheme
  //           ? Colors.black.withOpacity(0.50)
  //           : Colors.white,
  //       behavior: SnackBarBehavior.floating,
  //       width: MediaQuery.of(context).size.height * 2.5 / 3,
  //       content: Text(
  //         "Exit Node is Invalid!.switching to default Exit Node",
  //         style: TextStyle(
  //             color: appModel.darkTheme ? Colors.white : Colors.black),
  //         textAlign: TextAlign.center,
  //       )));
  // }
 //}
  
}

Future<void> _checkingExitnodeAfterDelay() async {
 //if(canValidateExit){
   if (myExit) {
    setState(() {
      f = true;
      mystr = "exitnode is valid";
      loading = false;
    });
  } else {
    setState(() {
      mystr = "exitnode is invalid";
    });
    print("myExitvalue is $mystr");
    await BelnetLib.disconnectFromBelnet();
    timer1?.cancel();
      AwesomeNotifications().cancel(10);
    logController.addDataTolist(
      "$selectedValue is Invalid Exit Node",
      "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
    );
    setState(() {
      selectedValue =
          'exit.bdx';
      selectedConIcon =
          "https://belnet-exitnode.s3.ap-south-1.amazonaws.com/countryflag/icons8-france.png";
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: appModel.darkTheme
            ? Colors.black.withOpacity(0.50)
            : Colors.white,
        behavior: SnackBarBehavior.floating,
        width: MediaQuery.of(context).size.height * 2.5 / 3,
        content: Text(
          "Exit Node is Invalid!.switching to default Exit Node",
          style: TextStyle(
              color: appModel.darkTheme ? Colors.white : Colors.black),
          textAlign: TextAlign.center,
        )));
  }
 //}
  
}







Future<void> _saveSettings(String? exitvalue, String? dns) async {
  final settings = Settings.getInstance()!;
  settings.exitNode = selectedValue!.trim().toString();
  final myVal = selectedValue!.trim().toString();
  logController.addDataTolist(" Exit node = $myVal",
      "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");

  final preferences = await SharedPreferences.getInstance();
  await preferences.setString('hintValue', myVal);
  hintValue = preferences.getString('hintValue');

  logController.addDataTolist(dns == null
      ? " default Upstream DNS = 9.9.9.9"
      : " DNS = $dns", "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");

  settings.upstreamDNS = dns ?? '9.9.9.9';

  final eIcon = selectedConIcon!.trim().toString();
  await preferences.setString('hintCountryicon', eIcon);
  hintCountryIcon = preferences.getString('hintCountryicon');
  logController.addDataTolist(" Connected to $myVal",
      "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
}





//   Future toggleBelnet(
//       [String? exitvalue, String? dns, bool isCustomExit = false]) async {
//     SharedPreferences preferences = await SharedPreferences.getInstance();
//     appModel.uploadList.addAll(SpeedMapData().sampleUpData);
//     appModel.downloadList.addAll(SpeedMapData().sampleDownData);

//     if (BelnetLib.isConnected == false) {
//       print(
//           '${DateTime.now().microsecondsSinceEpoch} netvalue from disconnected --');
//       //AwesomeNotifications().dismiss(3);
//       appModel.singleDownload = "";
//       appModel.singleUpload = "";
//     }
//     bool dismiss = false;
//     //  loading = true;
//     setState(() {});

//     await preferences.setBool('oneTimeAddExit', true);
//     isAddExitStatus = preferences.getBool('oneTimeAddExit');
//     print("isAddExitStatus is having the value $isAddExitStatus");
//     if (mounted) setState(() {});

//     if (BelnetLib.isConnected) {
//       setState(() {
//         loading = true;
//       });
//       var disConnectValue = await BelnetLib.disconnectFromBelnet();
//       //  await AwesomeNotifications().dismiss(1);
//       // pr.Provider.of<NotificationProvider>(context, listen: false)
//       //       .dismissNotification(1);
//       appModel.connecting_belnet = false;
//       dismiss = true;
//       Future.delayed(const Duration(seconds: 2), () {
//         setState(() {
//           loading = false;
//         });
//       });

//       if (disConnectValue)
//         logController.addDataTolist(" Belnet Daemon stopped..",
//             "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
//       logController.addDataTolist(" Belnet disconnected",
//           "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
//     } else {
//       setState(() {
//         loading = true;
//         canLoading = true;
//       });

//       var f = false;
//       Future.delayed(const Duration(seconds: 20), () {
//         //milliseconds: 11000
//         setState(() {
//           loading = false;
//           canLoading = false;
//         });

//         if (isCustomExit) {
//           if (myExit) {
//             setState(() {
//               f = true;

//               mystr = "exitnode is valid";

//               // saveCustomForUse(
//               //     true); // this true or false value is for eligible custom exitnode
//             });

//             setState(() {
//               loading = false;
//             });
//           } else {
//             setState(() {
//               mystr = "exitnode is invalid";
//             });

//             print("myExitvalue is $mystr");
//             BelnetLib.disconnectFromBelnet();
//             logController.addDataTolist(
//               "$selectedValue is Invalid Exit Node",
//               "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
//             );
//             setState(() {
//               selectedValue =
//                   '5n6w1xd8hazxu68mrnahtupbyocqhehfy8xhnttttby64e3g3k6y.bdx';
//               selectedConIcon =
//                   "https://deb.beldex.io/Beldex-projects/Belnet/countryflag/icons8-france.png";
//             });
//             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                 backgroundColor: appModel.darkTheme
//                     ? Colors.black.withOpacity(0.50)
//                     : Colors.white,
//                 behavior: SnackBarBehavior.floating,
//                 //duration: Duration(milliseconds: 200),
//                 width: MediaQuery.of(context).size.height * 2.5 / 3,
//                 content: Text(
//                   "Exit Node is Invalid!.switching to default Exit Node",
//                   style: TextStyle(
//                       color: appModel.darkTheme ? Colors.white : Colors.black),
//                   textAlign: TextAlign.center,
//                 )));
//             // await BelnetLib.disconnectFromBelnet();
//           }
//         }
//       });

//       if (isCustomExit) {
//         if (exitvalue != "") {
//           setState(() {
//             selectedValue = exitvalue;
//             selectedConIcon = "";
//           });

// //  var f = false;
// //     Future.delayed(Duration(seconds: 17), () {
// //                               setState(() {
// //                                f = true;
// //                                 if (myExit) {
// //                                   mystr = "exitnode is valid";

// //                                   saveCustomForUse(
// //                                       true); // this true or false value is for eligible custom exitnode

// //                                  // Navigator.pop(context);
// //                                 } else {
// //                                   mystr = "exitnode is invalid";
// //                                   // await BelnetLib.disconnectFromBelnet();
// //                                 }
// //                               });
// //                             });

//            timer1 = Timer.periodic(Duration(seconds: 1), (timer) {
//             if (myExit == false && f == false) {
//               getDataFromDaemon();
//             } else {
//               timer.cancel();
//             }
//           });
//         }
//       }

//       //Save the exit node and upstream dns
//       final Settings settings = Settings.getInstance()!;
//       settings.exitNode = selectedValue!.trim().toString();
//       var myVal = selectedValue!.trim().toString();
//       logController.addDataTolist(" Exit node = $myVal",
//           "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
//       preferences.setString('hintValue', myVal);
//       hintValue = preferences.getString('hintValue');
//       if (dns == null) {
//         logController.addDataTolist(" default Upstream DNS = 9.9.9.9",
//             "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
//       } else {
//         logController.addDataTolist(" DNS = $dns",
//             "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
//       }

//       setState(() {});
//       var eIcon = selectedConIcon!.trim().toString();
//       preferences.setString('hintCountryicon', eIcon);
//       hintCountryIcon = preferences.getString('hintCountryicon');
//       print(
//           'hint value is stored from getString $hintValue and the hintCountryicon is $hintCountryIcon');
//       logController.addDataTolist(" Connected to $myVal",
//           "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");

//       print('hint value is stored from getString $hintValue');
//       setState(() {});
//       settings.upstreamDNS = '';

//       final result = await BelnetLib.prepareConnection();
//       if(!result) setState(()=>loading = false);
//       logController.addDataTolist(" Preparing Daemon connection..",
//           "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}");
//       if (await BelnetLib.isPrepared) {
//         appModel.connecting_belnet = true;
//       }
//       if (result) {
//         con = await BelnetLib.connectToBelnet(
//             exitNode: settings.exitNode!,
//             upstreamDNS:
//                 isCustomExit! == true && dns!.isNotEmpty ? dns : "9.9.9.9");
//         print('$con value is this after connect');
//         Future.delayed(Duration(seconds: 4), () {
//           showNotification(appModel);
//         });
//         Future.delayed(Duration(seconds: 19), () {
//           logController.addDataTolist(
//             " Connected successfully",
//             "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
//           );
//         });

//         print("connection data value for display $con");
//       }

//       setState(() {});

//       if (BelnetLib.isConnected) {
//         appModel.connecting_belnet = true;
//         logController.addDataTolist(
//           " Connected successfully",
//           "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
//         );
//         setToLogData(
//           " Connected successfully",
//           "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
//         );
//       }

//       if (mystr == "exitnode is invalid") {
//         BelnetLib.disconnectFromBelnet();

//         logController.addDataTolist(
//           "$selectedValue is Invalid Exit Node",
//           "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
//         );
//       }
//     }
//   }

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

  List<exitNodeModel.ExitNodeDataList> exitData1 = [];

  String valueS = "";

//  List<String> customExitAdd = [];
  bool eligibleCust = false;
  saveData() async {
    exitData1 = [];
    var res = await DataRepo().getListData();
    exitData1.addAll(res);
    setState(() {});
  }
//late Timer notificationTimer;

void showNotification(AppModel appModel) {
  print('Comes inside show Notification function');
 
 showMyNotifaction(appModel);
 timer1 = Timer.periodic(Duration(seconds: 1),(timer){
    updateNotification(appModel);
 });
 
 
 
 
 
 
  //Timer.periodic(Duration(milliseconds: 100), (timer) {
   // if (BelnetLib.isConnected) {
     // _updateNotification(appModel);
    // } else {
    //   //timer.cancel();
    //   _dismissNotification();
    // }
 // });
}



stopNotification()async{
  Future.delayed(const Duration(milliseconds: 200),(){
    timer1?.cancel();

  AwesomeNotifications().cancel(10).then((value) {
    print('Notification Stopped');
  });
  });
 
}





void showMyNotifaction(AppModel appModel){
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 10, 
      channelKey: 'belnets_channel',
    title: "belnet dVPN",
    body:
        '↑ ${stringBeforeSpace(appModel.singleUpload)}${stringAfterSpace(appModel.singleUpload)} ↓ ${stringBeforeSpace(appModel.singleDownload)}${stringAfterSpace(appModel.singleDownload)}',
    locked: true,
    autoDismissible: false,
    category: NotificationCategory.Service,)
      );
}

void updateNotification(AppModel appModel){
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 10, 
        channelKey: 'belnets_channel',
    title: "Belnet dVPN",
    body:
        '↑ ${stringBeforeSpace(appModel.singleUpload)}${stringAfterSpace(appModel.singleUpload)} ↓ ${stringBeforeSpace(appModel.singleDownload)}${stringAfterSpace(appModel.singleDownload)}',
    locked: true,
    autoDismissible: false,
    category: NotificationCategory.Service,)
      );
}



  // showNotification(AppModel appModel) async {
  //   Timer.periodic(Duration(milliseconds: 100), (timer) {
  //     if (BelnetLib.isConnected) {
  //       print('Awesome Notification starts now');
  //       pr.Provider.of<NotificationProvider>(context, listen: false)
  //           .showNotification(
  //         id: 1,
  //         channelKey: "belnets_channel",
  //         title: "belnet dVPN running",
  //         body:
  //             '↑ ${stringBeforeSpace(appModel.singleUpload)}${stringAfterSpace(appModel.singleUpload)} ↓ ${stringBeforeSpace(appModel.singleDownload)}${stringAfterSpace(appModel.singleDownload)}',
  //         locked: true,
  //         autoDismissible: false,
  //         category: NotificationCategory.Service,
  //       );
  //     } else if (BelnetLib.isConnected == false) {
  //       timer.cancel();
  //      print('Awesome Notification starts now');
  //       pr.Provider.of<NotificationProvider>(context, listen: false)
  //           .dismissNotification(1);
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    appModel = pr.Provider.of<AppModel>(context);
    double mHeight = MediaQuery.of(context).size.height;
    if (netValue == false && isOpen) {
      overlayEntry!.remove();
    }
    return
        GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                             Image.asset(
                                    appModel.darkTheme 
                                     ? 'assets/images/Map_dark (1).png'
                                     : 'assets/images/map_white (3).png',
                                    ),
                                  
                              if(BelnetLib.isConnected)
                                   Image.asset(
                                      'assets/images/Map_white_gif (1).gif') //Image.asset('assets/images/Mobile_1.gif')
                            ])),
                      ),
                      Positioned(
                        top: mHeight * 0.10 / 3,
                        left: mHeight * 0.04 / 3,
                        child: GestureDetector(
                          onTap: ()=>
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>const AboutPage())),
                          child: Container(
                            padding: EdgeInsets.only(
                                left: mHeight *
                                    0.06 /
                                    3),
                            // color: Colors.yellow,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                 SvgPicture.asset(
                                      appModel.darkTheme
                                        ?'assets/images/About_dark.svg'
                                        : 'assets/images/about_white_theme.svg',
                                        width: mHeight * 0.06 / 3,
                                        height: mHeight * 0.06 / 3),
                                    
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: mHeight *
                                        0.02 /
                                        3,
                                    top: mHeight *
                                        0.06 /
                                        3,
                                    bottom: mHeight *
                                        0.06 /
                                        3,
                                  ),
                                  child: Text(
                                    'About',
                                    style: TextStyle(
                                        fontSize:
                                            mHeight *
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
                            onTap: () =>
                              appModel.darkTheme = !appModel.darkTheme,
                            child: Image.asset(
                            appModel.darkTheme
                                ? 'assets/images/dark_theme_4x (2).png'
                                : 'assets/images/white_theme_4x (3).png',
                            width: appModel.darkTheme
                                ? mHeight * 0.25 / 3
                                : mHeight * 0.24 / 3,
                            height: appModel.darkTheme
                                ? mHeight * 0.25 / 3
                                : mHeight * 0.24 / 3,
                          ),

                                    ),
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
                                onPressed: loading
                                    ? null
                                    : toggleBelnet,
                                    // () {
                                    //     toggleBelnet();
                                    //     print("clicked this ");
                                    //     showNotification(appModel);
                                    //   },
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
                  Padding(
                    padding: EdgeInsets.only(
                        left: mHeight * 0.10 / 3, top: mHeight * 0.03 / 3),
                    child: Text('Exit Node',
                        style: TextStyle(
                            color: appModel.darkTheme
                                ? Colors.white
                                : Colors.black,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w900,
                            fontSize: mHeight * 0.05 / 3)),
                  ),
                  Container(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        BelnetLib.isConnected
                            ? Padding(
                                padding: EdgeInsets.only(
                                    left: mHeight *
                                        0.08 /
                                        3,
                                    right: mHeight *
                                        0.10 /
                                        3,
                                    top: mHeight *
                                        0.03 /
                                        3),
                                child: Container(
                                    height: mHeight *
                                        0.16 /
                                        3,
                                    decoration: BoxDecoration(
                                        color: appModel.darkTheme
                                            ? const Color(0xff292937)
                                            : const Color(0xffFFFFFF),
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
                                                child: hintCountryIcon != ""
                                                    ? Image.network(
                                                        "$hintCountryIcon",
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return Icon(
                                                            Icons.more_horiz,
                                                            color: Colors.grey,
                                                          );
                                                        },
                                                      )
                                                    :const Icon(
                                                        Icons.more_horiz,
                                                        color: Colors.grey,
                                                      )),
                                            Expanded(
                                                child: Text("$hintValue",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                        color:const Color(
                                                            0xff00DC00)))),
                                            BelnetLib.isConnected == false ? const Icon(
                                                                                          Icons.arrow_drop_down,
                                                                                          color: Colors.grey,
                                                                                        ):Container()
                                          ],
                                        ))))
                            : Padding(
                                padding: EdgeInsets.only(
                                    left: mHeight *
                                        0.08 /
                                        3,
                                    right: mHeight * 0.10 / 3,
                                    top: mHeight * 0.03 / 3),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isOpen = isOpen ? false : true;
                                    });
                                    if (isOpen &&
                                        (exitData1.isEmpty ||
                                            exitData1 == [])) {
                                      print(
                                          'cleared the data ${exitData1.length}');
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
                                    overlayState.insert(overlayEntry!);
                                  },
                                  child: Container(
                                      height:
                                          mHeight *
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
                                                      :const Icon(
                                                          Icons.more_horiz,
                                                          color: Colors.grey,
                                                        )),
                                              Expanded(
                                                  child: Text("$selectedValue",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                          color: Color(
                                                              0xff00DC00)))),
                                             BelnetLib.isConnected == false ? const Icon(
                                                Icons.arrow_drop_down,
                                                color: Colors.grey,
                                              ):Container()
                                            ],
                                          ))),
                                )),
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
                              
                              border: Border.all(
                                color: Color(0xffA1A1C1).withOpacity(0.1),
                              ),
                              gradient: LinearGradient(
                                  colors: appModel.darkTheme
                                      ? [const Color(0xff20202B),const Color(0xff2C2C39)]
                                      : [const Color(0xffF2F0F0),const Color(0xffFAFAFA)]),
                            ),
                            height:
                                mHeight * 0.15 / 3,
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/Add.svg',
                                  color:const Color(0xff56566F),
                                  height: mHeight *
                                      0.05 /
                                      3,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 5.0),
                                  child: Text(
                                    "Add Exit Node",
                                    style: TextStyle(
                                        fontSize:
                                            mHeight *
                                                0.05 /
                                                3,
                                        color:const Color(0xff56566F),
                                        fontFamily: "Poppins",
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ))
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
                                          content: containerWidget(dcontext,mHeight),
                                        ),
                                      ));
                            },
                            child: Container(
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    color: Colors.grey,
                                    gradient: LinearGradient(colors: [
                                     const Color(0xff00B504),
                                     const Color(0xff23DC27)
                                    ])),
                                height: mHeight *
                                    0.15 /
                                    3,
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/images/Add.svg',
                                      height:
                                          mHeight *
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
                  SizedBox(
                    height: mHeight * 0.05 / 3,
                  )
                  
                ],
              ),
              Positioned(
                top: mHeight * 1.2 / 3,
                left: 5,
                right: 5,
                child: Container(
                    padding:const EdgeInsets.only(left: 8.0, right: 8.0),
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
                                        ?const Color(0xffA1A1C1)
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
                top: mHeight * 1.25 / 3,
                left: 5,
                right: 5,
                child: Container(
                    padding:const EdgeInsets.only(left: 8.0, right: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                                        ?const Color(0xffA1A1C1)
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
                                          ?const Color(0xffA1A1C1)
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
                      ],
                    )),
              ),
            ],
          ),
          Flexible(
            child: Container(
                width: double.infinity,
                child:const BottomNavBarOptions()),
          )
        ],
      ),
    );
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

  Widget containerWidget(BuildContext dcontext,double mHeight) {
    bool isAuthCode = false;
    return StatefulBuilder(builder: (dcontext, StateSetter setState) {
      return Container(
        padding:const EdgeInsets.all(15.0),
        height: mHeight * 1.43 / 3,
        // width: MediaQuery.of(dcontext).size.width * 2 / 3,
        decoration: BoxDecoration(
          color: appModel.darkTheme ?const Color(0xff1C1C26) :const Color(0xffF5F5F5),
          border: Border.all(color:const Color(0xff707070).withOpacity(0.4)),
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                 const EdgeInsets.only(left: 5.0, right: 5.0, top: 4.0, bottom: 8.0),
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
                                        mHeight *
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
                                    textForExit = null;
                                    textForAuth = null;
                                    //textForAuth = null;
                                    isSet = false;
                                    color = "blue";
                                    Navigator.pop(dcontext);
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text(
                'Exit Node',
                style: TextStyle(
                    color: appModel.darkTheme ? Colors.white : Colors.black,
                    fontSize: mHeight * 0.06 / 3,
                    fontWeight: FontWeight.w900,
                    fontFamily: "Poppins"),
              ),
            ),
            Container(
              height: mHeight * 0.18 / 3,
              padding:const EdgeInsets.only(left: 3.0),
              decoration: BoxDecoration(
                  color: appModel.darkTheme ?const Color(0xff292937) : Colors.white,
                  borderRadius: BorderRadius.circular(5.0)),
              child: TextFormField(
                style: TextStyle(color:const Color(0xff00DC00)),
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
                      fontSize: mHeight * 0.05 / 3,
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
                    fontSize: mHeight * 0.06 / 3,
                    fontWeight: FontWeight.w900,
                    fontFamily: "Poppins"),
              ),
            ),
            Container(
              height: mHeight * 0.18 / 3,
              padding: EdgeInsets.only(left: 3.0),
              decoration: BoxDecoration(
                  color: appModel.darkTheme ? const Color(0xff292937) : Colors.white,
                  borderRadius: BorderRadius.circular(5.0)),
              child: isAuthCode
                  ? TextField(
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                      ],
                      controller: _cusAuthCode,
                      style: TextStyle(color: Color(0xff1994FC)),
                      decoration: InputDecoration(border: InputBorder.none),
                    )
                  : Container(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Text(
                            "9.9.9.9",
                            style: TextStyle(color: Color(0xff90909A)),
                          ),
                        ],
                      ),
                    ),
            ),
            Container(
                height: mHeight * 0.10 / 3,
                // color:Colors.orange,
                child: Center(
                    child: Text(
                  textForAuth == null ? " " : '$textForAuth',
                  style: TextStyle(
                      fontSize: mHeight * 0.05 / 3,
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
                            mHeight * 0.06 / 3,
                        fontWeight: FontWeight.w900,
                        fontFamily: "Poppins"),
                  ),
                ),
                GestureDetector(
                    onTap: () {
                      setState(() {
                        isAuthCode = isAuthCode ? false : true;
                        _cusAuthCode.text = "9.9.9.9";
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
                  } 
                  else if (_cusExitNode.text.length > 56) {
                    setState(() {
                      textForExit = "Please enter a valid Exit Node";
                    });
                  } 
                  else if (_cusExitNode.text.isNotEmpty &&
                      !_cusExitNode.text.endsWith(".bdx")) {
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
                    if (!isAuthCode && _cusAuthCode.text.isEmpty) {
                      toggleBelnet(_cusExitNode.text, _cusAuthCode.text, true);
                      Navigator.pop(context);
                    } else if (isAuthCode && _cusAuthCode.text.isNotEmpty) {
                      print('${_cusAuthCode.text} is the dns');
                      if (_cusAuthCode.text == "1.1.1.1" ||
                          _cusAuthCode.text == "9.9.9.9" ||
                          _cusAuthCode.text == "8.8.8.8") {
                        toggleBelnet(
                            _cusExitNode.text, _cusAuthCode.text, true);
                        Navigator.pop(context);
                      } else {
                        setState((() {
                          textForAuth = "Please enter a valid DNS";
                        }));
                      }
                    }
                  }
                }, //basicValidation, //customExitConnection,
                child: Container(
                    //padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.grey,
                        gradient: LinearGradient(
                            colors: [const Color(0xff007ED1),const Color(0xff0093FF)]),
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
                    height: mHeight * 0.18 / 3,
                    width: double.infinity,
                    child: isCheckLoad
                        ? Expanded(
                            child: LinearPercentIndicator(
                              lineHeight:
                                  mHeight * 0.30 / 3,
                              padding: EdgeInsets.zero,
                              animation: true,
                              animationDuration: 10000,
                              barRadius: Radius.circular(12.0),
                              percent: 1.0,
                              backgroundColor:const Color(0xffA8A8B7),
                              progressColor:const Color(0xff007ED1),
                            ),
                          )
                        :
                        Center(
                            child:const Text(
                            "OK",
                            style: TextStyle(
                                color: //isSet ?
                                    Colors.white, // : Color(0xff56566F),
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.w900),
                          ))
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
          overlayEntry?.remove();
        },
        child: Container(
          height: 200.0,
          margin: EdgeInsets.only(
              top: mHeight * 1.87 / 3, //2.010
              bottom: mHeight * 0.38 / 3,
              left: mHeight * 0.09 / 3,
              right: mHeight * 0.09 / 3),
          child: Container(
            height: mHeight * 0.70 / 3,
            width: mHeight * 2.7 / 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              color: appModel.darkTheme ?const Color(0xff292937) : Colors.white,
            ),
            child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: exitData1.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    margin: EdgeInsets.all(0),
                    child: Theme(
                       data:  Theme.of(context).copyWith( 
                              dividerColor: Colors.transparent,),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.only(
                            left: mHeight * 0.08 / 3, right: mHeight * 0.08 / 3),
                        title: Text(
                          exitData[index].type,
                          style: TextStyle(
                              color: index == 0
                                  ? Color(0xff1CBE20)
                                  : Color(0xff1994FC),
                              fontSize:
                                  mHeight * 0.06 / 3,
                              fontWeight: FontWeight.bold),
                        ),
                        iconColor:
                            index == 0 ? const Color(0xff1CBE20) :const Color(0xff1994FC),
                        collapsedIconColor:
                            index == 0 ? const Color(0xff1CBE20) :const Color(0xff1994FC),
                        subtitle: Text(
                          "${exitData1[index].node.length} Nodes",
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize:
                                  mHeight * 0.04 / 3),
                        ),
                        children: <Widget>[
                          Column(
                            children: _buildExpandableContent(
                                exitData1[index].node, exitData1[index].type,mHeight),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                ),
          ),
          // ),
        ),
      ),
    );
  }

  _buildExpandableContent(List<exitNodeModel.Node> vnode, String type,double mHeight) {
    List<Widget> columnContent = [];
    for (int i = 0; i < vnode.length; i++) {
      columnContent.add(
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

          child: Container(
          padding: EdgeInsets.only(
              left: mHeight * 0.06 / 3,
              right: mHeight * 0.06 / 3,
              top: mHeight * 0.02 / 3,
              bottom: mHeight * 0.02 / 3),
          height: mHeight* 0.19 / 3,
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      width: 0.5, color: Color(0xff56566F).withOpacity(0.2)))),
          child: Row(
            children: [
              Container(
                //color:Colors.yellow,
                height: mHeight * 0.050 / 3,
                width:mHeight * 0.060 / 3,
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
                    : const Icon(Icons.info_outline_rounded),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      left: mHeight * 0.05 / 3,
                      right:mHeight * 0.05 / 3),
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
                              fontSize: mHeight *
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
                                mHeight * 0.04 / 3),
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
                    right: mHeight * 0.05 / 3),
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
    return columnContent;
  }
}

// if there is no internet, this page only displays when there is no inter
