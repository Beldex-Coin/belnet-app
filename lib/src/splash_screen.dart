import 'dart:async';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/bottom_nav_bar.dart';
import 'package:belnet_mobile/main.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/screens/onboarding_screen.dart';
import 'package:belnet_mobile/src/vpn_controller.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';


class SplashScreens extends StatefulWidget {
  const SplashScreens({Key? key}) : super(key: key);

  @override
  State<SplashScreens> createState() => _SplashScreensState();
}

class _SplashScreensState extends State<SplashScreens>
    with WidgetsBindingObserver {
 //AnimationController? _controller;

 late VideoPlayerController _videoController;
 Timer? timer;

  @override
  void initState() {
    // _controller = AnimationController(vsync: this, duration: Duration(seconds:5));
    super.initState();
   // _controller = AnimationController(vsync: this, duration: Duration(seconds:5));

    WidgetsBinding.instance.addObserver(this);
    // _videoController = VideoPlayerController.asset('assets/images/dark_theme/splash_video.mp4')
    //   ..initialize().then((_) {
    //     setState(() {});
    //     _videoController.play();
    //   });

    // _videoController.addListener((){
    //   if (_videoController.value.position == _videoController.value.duration) {
       
    //     _goToNextScreen();
    //   }
    // });
  timer = Timer(const Duration(seconds: 3), () {
    _goToNextScreen();
     // Navigator.pushReplacementNamed(context, '/home'); // or use Navigator.pushReplacement(...)
    });

  }

void _goToNextScreen()async {
     SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
   //getStatus(context);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => isFirstLaunch ? OnboardingScreen() : MainBottomNavbar() //BelnetHomePage()
      ),
    );
  }


// @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//   try{

//      // Safely use the provider with `context.read<T>()`
//     if (!mounted) return;

//     final loaderVideoProvider = context.read<LoaderVideoProvider>();
//    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {

//       //timer1?.cancel();
//       //AwesomeNotifications().cancel(10); // Cancel the notification with id 10
//     }
//     if(state == AppLifecycleState.resumed){
//       if(BelnetLib.isConnected){
//         print('I AM INside ----->');
//         loaderVideoProvider.setConnectionStatus(ConnectionStatus.CONNECTED);
//         print('I AM INside 111----->${loaderVideoProvider.conStatus}');

//       }
//         print('I AM INside out 222----->${loaderVideoProvider.conStatus}');

//     }
//   }catch(e){
// }
   
//   }













@override
  void dispose() {
    timer?.cancel();
    //_controller!.dispose();
   // _videoController.dispose();
        WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return
      Scaffold(
        extendBody: true,
      backgroundColor: Colors.black,// Color(0xff1C1C26),
         body:Center(
          child: Image.asset('assets/images/dark_theme/Splash_1.gif',
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
          ),
         )
        //  _videoController.value.isInitialized
        //    ?
        //    SizedBox.expand(
        //       child: FittedBox(
        //         fit: BoxFit.cover,
        //         child: SizedBox(
        //           width: _videoController.value.size.width,
        //           height: _videoController.value.size.height,
        //           child: VideoPlayer(_videoController),
        //         ),
        //       ),
        //     )
        //   : 
        //   Center(child: Image.asset('assets/images/belnet_ic.png',)),
    //      Center(
    //   child: Container(
    //     child: Lottie.asset('assets/images/Splash_belnet_1 (1).json',    //belnet_splash.json
    //         controller: _controller, onLoaded: (composition) {
    //       _controller!
    //         ..duration = composition.duration
    //         ..forward().whenComplete(() => Navigator.pushReplacement(context,
    //             MaterialPageRoute(builder: (context) => MainBottomNavbar())));
    //     }),
    //   ),
    // ),
    );
  }
}