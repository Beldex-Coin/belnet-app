import 'package:belnet_lib/belnet_lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../model/theme_set_provider.dart';

class BelnetPowerButton extends StatefulWidget {
  final VoidCallback? onPressed;
  bool? isClick;
  final AnimationController? animationController;
  final Animation? animation;
  BelnetPowerButton({this.onPressed,
  this.animationController, this.animation,
  this.isClick
  });

  @override
  State<BelnetPowerButton> createState() => _BelnetPowerButtonState();
}

class _BelnetPowerButtonState extends State<BelnetPowerButton> with SingleTickerProviderStateMixin{
  


  @override
  void initState() {
  
    super.initState();
  }

@override
  void dispose() {
   // widget.animationController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
  final appModel = Provider.of<AppModel>(context);

    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        decoration:BoxDecoration(
         // color: Colors.yellow,
          shape: BoxShape.circle,
        ),
        height: MediaQuery.of(context).size.height * 0.70 / 3,
        width: MediaQuery.of(context).size.width * 1.48 / 3,
        child: appModel.darkTheme ? SvgPicture.asset(
         BelnetLib.isConnected
            ? 'assets/images/power_on (2).svg'
            : 'assets/images/power_off.svg',
        ):
            SvgPicture.asset(
            BelnetLib.isConnected
            ? 'assets/images/power_on.svg'
            : 'assets/images/power_off_white.svg',
            ),
      ),
    );
  }
}
