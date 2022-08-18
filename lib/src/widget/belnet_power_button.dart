import 'package:belnet_lib/belnet_lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../model/theme_set_provider.dart';

class BelnetPowerButton extends StatefulWidget {
  final VoidCallback? onPressed;
  bool? isClick;
 bool isLoading=false;
  BelnetPowerButton({this.onPressed, this.isClick, required this.isLoading});

  @override
  State<BelnetPowerButton> createState() => _BelnetPowerButtonState();
}

class _BelnetPowerButtonState extends State<BelnetPowerButton>
    with SingleTickerProviderStateMixin {
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

    var white_loading_image = Lottie.asset('assets/images/loading_button.json');
    var power_on_dark = SvgPicture.asset('assets/images/power_on (2).svg');
    var power_off_dark = SvgPicture.asset('assets/images/power_off.svg');
    var dark_loading_image = Lottie.asset('assets/images/loading_button.json');
    var power_on_white = SvgPicture.asset('assets/images/power_on (3).svg');
    var power_off_white = SvgPicture.asset('assets/images/power_off_white.svg');







    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
          decoration: BoxDecoration(
            // color: Colors.yellow,
            shape: BoxShape.circle,
          ),
          height: MediaQuery.of(context).size.height * 0.75 / 3,
          width: MediaQuery.of(context).size.width * 1.58 / 3,
          child:
          appModel.darkTheme
              ?
          widget.isLoading
                  ? dark_loading_image
                  : appModel.connecting_belnet
                      ? power_on_dark
                      : power_off_dark
              :
        widget.isLoading
                  ? white_loading_image
                  : appModel.connecting_belnet
                      ? power_on_white
                      : power_off_white

          // appModel.darkTheme ?
          // SvgPicture.asset(
          //  BelnetLib.isConnected
          //     ? 'assets/images/power_on (2).svg'
          //     : 'assets/images/power_off.svg',
          // ):
          //     SvgPicture.asset(
          //     BelnetLib.isConnected
          //     ? 'assets/images/power_on (3).svg'
          //     : 'assets/images/power_off_white.svg',
          //     ),
          ),
    );
  }
}
