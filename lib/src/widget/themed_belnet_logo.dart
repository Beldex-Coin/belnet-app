import 'package:flutter/material.dart';
import 'package:belnet_mobile/src/utils/is_darkmode.dart';

class ThemedBelnetLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final belnetLogo = inDarkMode(context)
        ? "assets/images/belnet_logo_white.png"
        : "assets/images/belnet_logo_white.png";

    return Image.asset(
      belnetLogo,
      width: MediaQuery.of(context).size.width * 0.60,
    );
  }
}
