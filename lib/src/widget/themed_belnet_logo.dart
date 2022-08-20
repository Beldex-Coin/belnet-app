import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:flutter/material.dart';
import 'package:belnet_mobile/src/utils/is_darkmode.dart';

class ThemedBelnetLogo extends StatelessWidget {

  final bool model;

  const ThemedBelnetLogo({Key? key, required this.model}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final belnetLogo ="assets/images/belnet_logo_white.png";

    return Image.asset(
      belnetLogo,
      width: MediaQuery.of(context).size.width * 0.68,
    );
  }
}
