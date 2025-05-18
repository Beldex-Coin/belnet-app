import 'package:belnet_mobile/bottom_nav_bar.dart';
import 'package:belnet_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';


class SplashScreens extends StatefulWidget {
  const SplashScreens({Key? key}) : super(key: key);

  @override
  State<SplashScreens> createState() => _SplashScreensState();
}

class _SplashScreensState extends State<SplashScreens>
    with TickerProviderStateMixin {
 //AnimationController? _controller;

 late VideoPlayerController _videoController;


  @override
  void initState() {
    // _controller = AnimationController(vsync: this, duration: Duration(seconds:5));
    super.initState();
    _videoController = VideoPlayerController.asset('assets/images/dark_theme/splash_v2.webm')
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
      });

    _videoController.addListener(() {
      if (_videoController.value.position == _videoController.value.duration) {
        _goToNextScreen();
      }
    });
  }

void _goToNextScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainBottomNavbar() //BelnetHomePage()
      ),
    );
  }

@override
  void dispose() {
   // _controller!.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return
      Scaffold(
      backgroundColor: Colors.black,// Color(0xff1C1C26),
        body:
         _videoController.value.isInitialized
           ?
           SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          : 
          Center(child: Image.asset('assets/images/belnet_ic.png',)),
    //      Center(
    //   child: Container(
    //     child: Lottie.asset('assets/images/Splash_belnet_1 (1).json',    //belnet_splash.json
    //         controller: _controller, onLoaded: (composition) {
    //       _controller!
    //         ..duration = composition.duration
    //         ..forward().whenComplete(() => Navigator.pushReplacement(context,
    //             MaterialPageRoute(builder: (context) => BelnetHomePage())));
    //     }),
    //   ),
    // ),
    );
  }
}