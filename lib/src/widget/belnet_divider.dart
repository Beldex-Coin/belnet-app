import 'package:flutter/material.dart';
import 'package:belnet_mobile/src/utils/is_darkmode.dart';

class BelnetDivider extends StatelessWidget {
  final String _ending;

  BelnetDivider({bool minus = false}) : _ending = minus ? "-" : "+";

  @override
  Widget build(BuildContext context) {
    final color = inDarkMode(context) ? Colors.white : Colors.black;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
      child: Row(
        children: [
          Container(
            child: Text(
              _ending,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color, fontSize: 30, fontWeight: FontWeight.w100),
            ),
            width: 15,
          ),
          Expanded(
            child: new Container(
                margin: const EdgeInsets.only(left: 10.0, right: 10.0),
                child: Divider(
                  color: color,
                  height: 0,
                )),
          ),
          Container(
            child: Text(
              _ending,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color, fontSize: 30, fontWeight: FontWeight.w100),
            ),
            width: 15,
          ),
        ],
      ),
    );
  }
}
