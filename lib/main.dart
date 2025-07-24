import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:belnet_mobile/bottom_nav_bar.dart';
import 'package:belnet_mobile/node_provider.dart';
import 'package:belnet_mobile/src/app_list_provider.dart';
import 'package:belnet_mobile/src/model/exitnodeCategoryModel.dart' as exitNodeModel;
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
import 'package:belnet_mobile/src/widget/notifications_controller.dart';
import 'package:flutter/material.dart';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart' as pr;
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
  //pr.Provider.debugCheckInvalidValueType = null;

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

  // getRandomExitData() async {
  //   SharedPreferences preferences = await SharedPreferences.getInstance();

  //   // setState(() {
  //   //   customExitAdd = preferences.getStringList("customData")!; //for custom exit node save

  //   // });
  //   if (BelnetLib.isConnected == false) {
  //     print(
  //         "inside getRandomExitData function the belnetlib is false ${BelnetLib.isConnected}");
  //     var responses = await DataRepo().getListData();
  //     exitData.addAll(responses);
  //     setState(() {
  //       exitData.forEach((element) {
  //         element.node.forEach((elements) {
  //           ids.add(elements.id);
  //         });
  //       });

  //       final random = Random();
  //       selectedId = ids[random.nextInt(ids.length)];
  //     });

  //     setState(() {
  //       exitData.forEach((element) {
  //         element.node.forEach((element) {
  //           if (selectedId == element.id) {
  //             selectedValue = element.name;
  //             selectedConIcon = element.icon;
  //             print("icon id value $selectedId");
  //             print("selected exitnode value $selectedValue");
  //             print("icon image url : ${element.icon}");
  //           }
  //         });
  //       });

  //       // if(BelnetLib.isConnected == false){
  //       // preferences.setString('hintValue',selectedValue!);
  //       // preferences.setString('hintContryicon',selectedConIcon!);
  //       // }
  //     });
  //   }
  //   setState(() {
  //     hintValue = preferences.getString('hintValue');
  //     hintCountryIcon = preferences.getString('hintCountryicon');
  //     print('print hintvalue $hintValue and hintCountryIcon $hintCountryIcon');
  //   });
  // }




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
        //pr.ChangeNotifierProvider<SpeedChartProvider>(create: (_)=> SpeedChartProvider()),
        pr.ChangeNotifierProvider<LoaderVideoProvider>(create: (_)=> LoaderVideoProvider()..initialize('')),
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
