import 'package:belnet_lib/belnet_lib.dart';
import 'package:flutter/material.dart';
//mport 'package:belnet_mobile/src/utils/is_darkmode.dart';
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
          // boxShadow: [
          //   BoxShadow(
          //     color:BelnetLib.isConnected ? Color(0xff00C000).withOpacity(0.6): Colors.transparent,
          //     blurRadius:BelnetLib.isConnected ? 10 : 0,
          //     spreadRadius: BelnetLib.isConnected ? 10 : 0,
          //   ),
          // ],
        ),
        height: MediaQuery.of(context).size.height * 0.85 / 3,
        width: MediaQuery.of(context).size.width * 1.58 / 3,
        child: appModel.darkTheme ? SvgPicture.asset(
         BelnetLib.isConnected
            ? 'assets/images/dark_power_on.svg'
            : 'assets/images/power_off.svg'):
            SvgPicture.asset(
            BelnetLib.isConnected
            ? 'assets/images/power_on.svg'
            : 'assets/images/power_off_white.svg'),
      ),
    );
  }
}
