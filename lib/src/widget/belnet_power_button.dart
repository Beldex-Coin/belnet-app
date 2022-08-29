import 'package:belnet_lib/belnet_lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../model/theme_set_provider.dart';

class BelnetPowerButton extends StatefulWidget {
  final VoidCallback? onPressed;
  bool? isClick;
 bool? isLoading;
  BelnetPowerButton({this.onPressed,required this.isClick, required this.isLoading});

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

   // var whiteLoadingImage =Lottie.asset('assets/images/load_white.json'); //Lottie.asset('assets/images/loading_button.json');
   // var powerOnDark =  Lottie.asset('assets/images/on_darks.json'); // Lottie.asset('assets/images/on_dark.json');
    //var powerOffDark = Lottie.asset('assets/images/off_darks.json'); //Lottie.asset('assets/images/off_7.json');
    //var darkLoadingImage = Lottie.asset('assets/images/load_dark.json'); //Lottie.asset('assets/images/button_Loading_dark (1).json');
    //var powerOnWhite =  Lottie.asset('assets/images/on_whites.json');//Lottie.asset('assets/images/on_white.json');
    //var powerOffWhite = Lottie.asset('assets/images/off_whites.json'); //Lottie.asset('assets/images/off_white.json');


    var whiteLoadingImage = Image.asset('assets/images/load_white.gif');
    var powerOnDark =  Image.asset('assets/images/on_dark.png');
    var powerOffDark = Image.asset('assets/images/off_dark.png');
    var darkLoadingImage = Image.asset('assets/images/load_dark.gif');
    var powerOnWhite = Image.asset('assets/images/on_white.png');
    var powerOffWhite = Image.asset('assets/images/off_white.png');

    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
          decoration: BoxDecoration(
            // color: Colors.yellow,
            shape: BoxShape.circle,
          ),
          height: MediaQuery.of(context).size.height * 0.98 / 3,
          width: MediaQuery.of(context).size.width * 1.78 / 3,
          child:
          appModel.darkTheme
              ?
          widget.isLoading!
                  ? darkLoadingImage
                  : BelnetLib.isConnected
                      ? powerOnDark
                      : powerOffDark
              :
        widget.isLoading!
                  ? whiteLoadingImage
                  : BelnetLib.isConnected
                      ? powerOnWhite
                      : powerOffWhite
          ),
    );
  }
}
