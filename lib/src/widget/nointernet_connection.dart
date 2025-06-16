

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
                    image:appModel.darkTheme ? AssetImage('assets/images/dark_theme/BG.png') :AssetImage('assets/images/light_theme/BG.png'),
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
                      child:appModel.darkTheme ? SvgPicture.asset('assets/images/dark_theme/no_connection.svg',height: MediaQuery.of(context).size.height * 0.20 / 3) : SvgPicture.asset('assets/images/light_theme/no_connection.svg',height: MediaQuery.of(context).size.height * 0.20 / 3)),
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
                                : Color(0xff333333),
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
                                      : Color(0xff4D4D4D),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w100,
                                  fontFamily: 'Poppins')))),
                  Spacer(flex: 3,),
                appModel.darkTheme ?  Padding(
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
                  ):Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.19 / 3,
                        bottom: MediaQuery.of(context).size.height * 0.12 / 3,

                        ),

                    child: Container(
                        height: MediaQuery.of(context).size.height * 0.20 / 3,
                        width: MediaQuery.of(context).size.height * 0.70 / 3,
                         decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color:  Color(0xff00B400) //: Color(0xffACACAC)
                          ,width: 0.3),
                          //color: Colors.grey,
                          // gradient: LinearGradient(
                          //     colors: [const Color(0xff007ED1),const Color(0xff0093FF)]),
                         
                          boxShadow: [
                             BoxShadow(
                    color: Color(0xff00B400).withOpacity(0.2)                  
                  ),
                  BoxShadow(
                    color: Colors.white,
                    spreadRadius: -01.0,
                    blurRadius: 23.5,
                    offset: Offset(-3.0, 4.5),
                  )]),
                        // decoration: BoxDecoration(
                        //     color: Colors.transparent,// Color(0xff00DC00),
                        //     borderRadius: BorderRadius.all(Radius.circular(14.0)),
                        //     border:
                        //         Border.all(color: Color(0xff00DC00), width: 1)),
                        child: TextButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi,color: Color(0xff00B400),),
                              SizedBox(width: 8,),
                              Text(
                                'Retry',
                                style: TextStyle(
                                  color:Color(0xff00B400),
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
