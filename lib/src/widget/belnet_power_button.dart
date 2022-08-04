import 'package:flutter/material.dart';
import 'package:belnet_mobile/src/utils/is_darkmode.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BelnetPowerButton extends StatelessWidget {
  final VoidCallback onPressed;
  bool isClick;
  bool isDark = false;
  BelnetPowerButton({this.onPressed, this.isClick});

  @override
  Widget build(BuildContext context) {

    //  return GestureDetector(
    //   onTap: onPressed,
    //    child: Container(
    //     height:MediaQuery.of(context).size.height*1.5/3,
    //     width: MediaQuery.of(context).size.width*1.5/3,
    //          child: SvgPicture.asset('assets/images/power_off_white.svg')
    //    ),
    //  );
    final color = inDarkMode(context) ? Colors.white : Colors.black;

    // return OutlinedButton(
    //   style: OutlinedButton.styleFrom(
    //     side: BorderSide(color: color, width: 1, style: BorderStyle.solid),
    //     shape: CircleBorder(),
    //   ),
    //   onPressed: onPressed,
    //   child: Padding(
    //     padding: EdgeInsets.all(40),
    //     child: Icon(
    //       Icons.power_settings_new_outlined,
    //       size: 60,
    //       color: color,
    //     ),
    //   ),
    // );
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          // boxShadow: [
          //   BoxShadow(
          //     color:Color(0xffE0E0E0),
          //     //spreadRadius: 0.1,
          //     blurRadius: 10,
          //      offset: Offset(0, 5),
          //   ),
          // ],

          //color:Color(0xff00C000)
        ),
        height: MediaQuery.of(context).size.height * 1.6 / 3,
        width: MediaQuery.of(context).size.width * 1.6 / 3,
        child: isDark ? SvgPicture.asset(isClick
            ? 'assets/images/dark_power_on.svg'
            : 'assets/images/power_off.svg'):
            SvgPicture.asset(isClick
            ? 'assets/images/power_on.svg'
            : 'assets/images/power_off_white.svg'),
      ),
    );
  }
}
