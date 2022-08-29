import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:flutter/material.dart';
import 'package:belnet_mobile/src/utils/is_darkmode.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class ThemedBelnetLogo extends StatelessWidget {

  final bool model;

  const ThemedBelnetLogo({Key? key, required this.model}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final belnetLogoForDark ="assets/images/belnet_logo_dark_theme.svg";
    final belnetLogoForWhite = "assets/images/belnet_logo_white_theme.svg";
    final appModel = Provider.of<AppModel>(context);
    return SvgPicture.asset(
      appModel.darkTheme ?
          belnetLogoForDark
         :belnetLogoForWhite,
      width: MediaQuery.of(context).size.width * 0.68,
    );
  }
}
