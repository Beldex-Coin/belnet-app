import 'package:belnet_mobile/main.dart';
import 'package:belnet_mobile/src/widget/network_connectivity.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class SplashScreens extends StatefulWidget {
  const SplashScreens({Key? key}) : super(key: key);

  @override
  State<SplashScreens> createState() => _SplashScreensState();
}

class _SplashScreensState extends State<SplashScreens>
    with TickerProviderStateMixin {
 AnimationController? _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: Duration(seconds:5));
    super.initState();
  }

@override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final networkStatus = Provider.of<NetworkStatus>(context);

    return
      Scaffold(
      backgroundColor: Color(0xff1C1C26),
        body: Center(
      child: Container(
        child: Lottie.asset('assets/images/Splash_belnet_1 (1).json',    //belnet_splash.json
            controller: _controller, onLoaded: (composition) {
          _controller!
            ..duration = composition.duration
            ..forward().whenComplete(() => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) =>networkStatus == NetworkStatus.disconnected ?
                NoInternetConnection() : BelnetHomePage())));
        }),
      ),
    ));
  }
}