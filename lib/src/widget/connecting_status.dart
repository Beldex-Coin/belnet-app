import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ConnectingStatus extends StatelessWidget {
  bool isConnect;
  ConnectingStatus({Key key, this.isConnect}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    return Column(
      // mainAxisAlignment: MainAxisAlignment.center,
      // crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                isConnect ? 'Connected' : 'Disconnected',
                style: TextStyle(
                    color: appModel.darkTheme
                        ? isConnect
                            ? Colors.white
                            : Color(0xffA8A8B7)
                        : isConnect
                            ? Color(0xff222222)
                            : Color(0xffA8A8B7),
                    fontFamily: 'Poppins',
                    fontWeight: isConnect ? FontWeight.bold : FontWeight.w500),
              ),
            ),
            Container(
              height: 10, //
              width: 10,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnect ? Color(0xff00C000) : Color(0xffFF3030)),
            )
          ],
        ),
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
