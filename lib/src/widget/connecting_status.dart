import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

class ConnectingStatus extends StatefulWidget {
  bool? isConnect;
  bool connecting;
  ConnectingStatus({Key? key, this.isConnect,required this.connecting}) : super(key: key);

  @override
  State<ConnectingStatus> createState() => _ConnectingStatusState();
}

class _ConnectingStatusState extends State<ConnectingStatus> {
  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    final mHeight = MediaQuery.of(context).size.height;
    return Column(
      // mainAxisAlignment: MainAxisAlignment.center,
      // crossAxisAlignment: CrossAxisAlignment.center,
      children: [
      widget.connecting ?  Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                //checking the connection for belnet
               'Connecting',
                style: TextStyle(
                    color: appModel.darkTheme
                        ? widget.isConnect!
                            ? Colors.white
                            : const Color(0xffA8A8B7)
                        : widget.isConnect!
                            ?const Color(0xff222222)
                            :const Color(0xffA8A8B7),
                    fontFamily: 'Poppins',
                    fontSize: mHeight*0.05/3,
                    fontWeight: widget.isConnect! ? FontWeight.bold : FontWeight.w500),
              ),
            ),
            Container(
              height: 10, //
              width: 10,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xffFFFF00) ),
            )
          ],
        ):
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                //checking the connection for belnet
                widget.isConnect! && widget.connecting == false ? 'Connected' : 'Disconnected',
                style: TextStyle(
                    color: appModel.darkTheme
                        ? widget.isConnect!
                            ? Colors.white
                            : Color(0xffA8A8B7)
                        : widget.isConnect!
                            ? Color(0xff222222)
                            : Color(0xffA8A8B7),
                    fontFamily: 'Poppins',
                    fontSize: mHeight*0.05/3,
                    fontWeight: widget.isConnect! ? FontWeight.bold : FontWeight.w500),
              ),
            ),
            Container(
              height: 10, //
              width: 10,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isConnect! ?const Color(0xff00C000) :const Color(0xffFF3030)),
            )
          ],
        ),
       widget.connecting ? 
       Padding(
          padding: EdgeInsets.only(top: 5.0,left:mHeight*0.45/3,right:mHeight*0.45/3),
          child: LinearPercentIndicator(  
            lineHeight: 2.0,
            animation: true,
            animationDuration: 12000,
            percent: 1.0,
            backgroundColor: Color(0xffA8A8B7),
            progressColor: Color(0xff00C000),
          )
          // ValueListenableBuilder<double?>(
          //   builder: (context,percent,child) {
          //     return LinearProgressIndicator(backgroundColor:Color(0xffA8A8B7),
          //     color: Color(0xff00C000),
          //     minHeight: 2.0,canLoading
          //     value:percent
          //     );
          //   }, valueListenable:manager.progressNotifier ,
          // )
        )
        :
        Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: SvgPicture.asset(
            'assets/images/line_white_theme.svg',
            color: Color(0xffA8A8B7),
          ),
        )
      ],
    );
  }
}
