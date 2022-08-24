

import 'package:belnet_lib/belnet_lib.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../model/theme_set_provider.dart';

class BackgroundImages extends StatelessWidget {
  bool? isConnect;
   BackgroundImages({Key? key,this.isConnect }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    return appModel.darkTheme
        ? Lottie.asset(
         isConnect!
            ? 'assets/images/dark_animations.json'
            : 'assets/images/Map_dark_BG.json',
        fit: BoxFit.fitHeight,
        width: double.infinity)
        : Lottie.asset(
        isConnect!
            ? 'assets/images/White_animation.json'
            : 'assets/images/white_static.json',
        fit: BoxFit.fitHeight,
        width: double.infinity);
  }
}
