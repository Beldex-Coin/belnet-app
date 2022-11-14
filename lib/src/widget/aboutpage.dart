import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';

import '../model/theme_set_provider.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: appModel.darkTheme
              ? [
                  Color(0xFF242430),
                  Color(0xFF1C1C26),
                ]
              : [
                  Color(0xFFF9F9F9),
                  Color(0xFFEBEBEB),
                ],
        ),
      ),
      child: Scaffold(  
        appBar: AppBar(
           backgroundColor: Colors.transparent,
           title: Center(
            child: Row(
              children: [

              ],
            ),
           ),
        ),
      )
    );
  }
}