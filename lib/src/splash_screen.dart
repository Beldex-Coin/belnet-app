import 'package:belnet_mobile/src/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';

/// Launch screen.
///
/// It used to show the old splash GIF (Splash_1.gif, the previous globe)
/// for 3 s on every launch and then push home with a plain page route, which
/// is why the old splash came back on every relaunch and home appeared with
/// a jump. Now every launch goes through the intro globe: the onboarding on
/// first launch, and its short automatic form afterwards, which zooms
/// straight into home.
class SplashScreens extends StatelessWidget {
  const SplashScreens({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const OnboardingScreen();
}
