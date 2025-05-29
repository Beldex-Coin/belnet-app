

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../model/theme_set_provider.dart';

class NoInternetConnection extends StatelessWidget {
  const NoInternetConnection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
            Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/dark_theme/BG.png'), // <-- your image
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.40 / 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Spacer(
                    flex: 4,
                  ),
                  Container(
                      height: MediaQuery.of(context).size.height * 1 / 3,
                      width: MediaQuery.of(context).size.width * 1.3 / 3,
                      child: SvgPicture.asset('assets/images/dark_theme/no_connection.svg',
                         // 'assets/images/icons8-wi-fi_disconnected (1).svg',
                          // color: appModel.darkTheme
                          //     ? Color(0xff4D4D64)
                          //     : Color(0xffC7C7C7),
                          height: MediaQuery.of(context).size.height * 0.20 / 3)),
                  Container(
                    padding: EdgeInsets.only(
                      left: 15.0,
                      right: 15.0,
                    ),
                    child: Center(
                      child: Text(
                        'No internet connection',
                        style: TextStyle(
                            color: appModel.darkTheme
                                ? Color(0xffEBEBEB)
                                : Color(0xff56566F),
                            fontWeight: FontWeight.w900,
                            fontSize:
                                MediaQuery.of(context).size.height * 0.09 / 3,
                            fontFamily: 'Poppins'),
                      ),
                    ),
                  ),
                  Container(
                      //color: Colors.green,
                      padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.height * 0.10 / 3,
                          right: MediaQuery.of(context).size.height * 0.10 / 3,
                          top: 5.0),
                      child: Center(
                          child: Text(
                              'You are not connected to the internet. Make sure WiFi/Mobile data is on.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: appModel.darkTheme
                                      ? Color(0xffACACAC)
                                      : Color(0xff56566F),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w100,
                                  fontFamily: 'Poppins')))),
                  Spacer(flex: 3,),
                  Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.19 / 3,
                        bottom: MediaQuery.of(context).size.height * 0.12 / 3,

                        ),

                    child: Container(
                        height: MediaQuery.of(context).size.height * 0.20 / 3,
                        width: MediaQuery.of(context).size.height * 0.70 / 3,
                        decoration: BoxDecoration(
                            color: Colors.transparent,// Color(0xff00DC00),
                            borderRadius: BorderRadius.all(Radius.circular(14.0)),
                            border:
                                Border.all(color: Color(0xff00DC00), width: 1)),
                        child: TextButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi,color: Color(0xff00DC00),),
                              SizedBox(width: 8,),
                              Text(
                                'Retry',
                                style: TextStyle(
                                  color:Color(0xff00DC00),
                                  fontFamily: 'Poppins',
                                  fontSize:
                                      MediaQuery.of(context).size.height * 0.07 / 3,
                                  // fontWeight: FontWeight.w900
                                ),
                              ),
                            ],
                          ),
                          onPressed: () {},
                        )),
                  )
                ],
              )),
        ],
      ),
    );
  }
}
