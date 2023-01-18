import 'package:belnet_mobile/src/widget/LineChartSample10.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../displaylog.dart';
import '../model/theme_set_provider.dart';

var pageIndex = 0;

class BottomNavBarOptions extends StatefulWidget {
  const BottomNavBarOptions({Key? key}) : super(key: key);

  @override
  State<BottomNavBarOptions> createState() => _BottomNavBarOptionsState();
}

class _BottomNavBarOptionsState extends State<BottomNavBarOptions> {
  Widget getBody() {
    List<Widget> pages = [
      ChartData(),
      // LiveChart(
      //   upData: uploadRate,
      //   downData: downloadRate,
      // ),
      DisplayLog()
    ];
    return IndexedStack(
      index: pageIndex,
      children: pages,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    return Scaffold(
        backgroundColor:
            appModel.darkTheme ? Color(0xFF1C1C26) : Color(0xFFEBEBEB),
        body: Container(
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
          child: getBody(),
        ),
        bottomNavigationBar: Container(
            height: MediaQuery.of(context).size.height * 0.18 / 3,
            decoration: BoxDecoration(
              color: appModel.darkTheme ? Color(0xff272734) : Color(0xffF8F8F8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      pageIndex = 0;
                      //canShow = false;
                    });
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.height * 0.55 / 3,
                    height: MediaQuery.of(context).size.height * 0.16 / 3,
                    color: Colors.transparent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SvgPicture.asset(
                            'assets/images/chart (1).svg',
                            color: pageIndex == 0
                                ? Color(0xff1DC021)
                                : Color(0xffA1A1C1),
                            height:
                                MediaQuery.of(context).size.height * 0.06 / 3,
                          ),
                        ),
                        Text(
                          'Chart',
                          style: TextStyle(
                              color: pageIndex == 0
                                  ? Color(0xff1DC021)
                                  : Color(0xffA1A1C1),
                              fontWeight: pageIndex == 0
                                  ? FontWeight.w900
                                  : FontWeight.normal,
                              fontFamily: "poppins"),
                        )
                      ],
                    ),
                  ),
                ),
                VerticalDivider(
                  color: appModel.darkTheme ? Colors.black : Color(0xffA1A1C1),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      pageIndex = 1;
                      //canShow = false;
                    });
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.height * 0.55 / 3,
                    height: MediaQuery.of(context).size.height * 0.16 / 3,
                    color: Colors.transparent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SvgPicture.asset(
                            'assets/images/Log.svg',
                            color: pageIndex == 1
                                ? Color(0xff1DC021)
                                : Color(0xffA1A1C1),
                            height:
                                MediaQuery.of(context).size.height * 0.05 / 3,
                          ),
                        ),
                        Text(
                          'Log',
                          style: TextStyle(
                              color: pageIndex == 1
                                  ? Color(0xff1DC021)
                                  : Color(0xffA1A1C1),
                              fontWeight: pageIndex == 1
                                  ? FontWeight.w900
                                  : FontWeight.normal,
                              fontFamily: "poppins"),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ))

        //  BottomNavigationBar(items: [
        //   BottomNavigationBarItem(
        //     label: "",
        //     icon: Row(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //       SvgPicture.asset('assets/images/chart (1).svg',height: MediaQuery.of(context).,),
        //       Text('Chart')
        //     ],)
        //     ),

        //     BottomNavigationBarItem(
        //       label: "",
        //     icon: Row(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //      // SvgPicture.asset('assets/images/chart (1).svg'),
        //       Text('Log')
        //     ],)
        //     )
        //  ])
        //  Container(
        //   color: Colors.white,
        //   width:double.infinity,
        //   height:45),
        );
  }
}
