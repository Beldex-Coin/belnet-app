

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../map/shared_globe.dart';
import '../map/vpn_home_style.dart';
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
          // Plain page colour + the app's globe rising from the bottom
          // (design), instead of the old background image.
          Positioned.fill(
            child: ColoredBox(
                color: VpnHomeStyle.of(appModel.darkTheme).background),
          ),
          Positioned.fill(
            child: BackdropGlobe(dark: appModel.darkTheme, horizon: 0.64),
          ),
          Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.40 / 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon and text sit a little higher (design).
                  Spacer(
                    flex: 3,
                  ),
                  Container(
                      height: MediaQuery.of(context).size.height * 1 / 3,
                      width: MediaQuery.of(context).size.width * 1.3 / 3,
                      child://appModel.darkTheme ?
                       SvgPicture.asset('assets/images/dark_theme/no_connection.svg',height: MediaQuery.of(context).size.height * 0.20 / 3,color: appModel.darkTheme ? Color(0xff8D8D8D).withOpacity(0.6) : Color(0xff8D8D8D).withOpacity(0.6),)),
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
                                      : Color(0xff222222),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w300,
                                  fontFamily: 'Poppins')))),
                  Spacer(flex: 4,),
                appModel.darkTheme ?  Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.14 / 3,
                        bottom: MediaQuery.of(context).size.height * 0.25 / 3,

                        ),

                    // Solid dark button (design): the old see-through glass
                    // let the globe lines show through it.
                    child: Container(
                        height: MediaQuery.of(context).size.height * 0.20 / 3,
                        width: MediaQuery.of(context).size.height * 0.70 / 3,
                        decoration: BoxDecoration(
                          color: const Color(0xff1F1F1F),
                          border: Border.all(
                              color: const Color(0xff3A3A3A), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.45),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi,size:22 ,color: Color(0xff00DC00),),
                              SizedBox(width: 8,),
                              Text(
                                'Retry',
                                style: TextStyle(
                                  color:appModel.darkTheme ? Color(0xffEBEBEB) : Color(0xff222222),
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize:22
                                      //MediaQuery.of(context).size.height * 0.07 / 3,
                                  // fontWeight: FontWeight.w900
                                ),
                              ),
                            ],
                          ),
                          onPressed:null //() {},
                        )),
                  ):Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.14 / 3,
                        bottom: MediaQuery.of(context).size.height * 0.25 / 3,

                        ),

                    child: Container(
                        height: MediaQuery.of(context).size.height * 0.20 / 3,
                        width: MediaQuery.of(context).size.height * 0.70 / 3,
                         decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color:  Color(0xffACACAC) //: Color(0xffACACAC)
                          ,width: 0.6),
                          //color: Colors.grey,
                          // gradient: LinearGradient(
                          //     colors: [const Color(0xff007ED1),const Color(0xff0093FF)]),
                         
                          boxShadow: [
                             BoxShadow(
                    color: Color(0xff00B400).withOpacity(0.2)                  
                  ),
                  BoxShadow(
                    color: Colors.white,
                    spreadRadius: -02.0,
                    blurRadius: 13.5,
                   // offset: Offset(-3.0, 4.5),
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
                                  color:Color(0xff222222),
                                  fontFamily: 'Poppins',
                                  fontSize:
                                      MediaQuery.of(context).size.height * 0.07 / 3,
                                   fontWeight: FontWeight.w700
                                ),
                              ),
                            ],
                          ),
                          onPressed:null// () {},
                        )),
                  ),
                 // SizedBox(height: 30,)
                ],
              )),
        ],
      ),
    );
  }
}
