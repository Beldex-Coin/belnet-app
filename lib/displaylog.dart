// import 'dart:async';
// import 'dart:developer';

// import 'package:belnet_lib/belnet_lib.dart';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/widget/logProvider.dart';
import 'package:clipboard/clipboard.dart';

import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/src/foundation/key.dart';
// import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisplayLog extends StatefulWidget {
  const DisplayLog({Key? key}) : super(key: key);

  @override
  State<DisplayLog> createState() => _DisplayLogState();
}

class _DisplayLogState extends State<DisplayLog> {
  late AppModel appModel;
  final LogController logController = Get.put(LogController());
  // final SaveForLog logCon = Get.put(SaveForLog());
  ScrollController _scrollController = new ScrollController();

  bool canCancel = true;
  bool canCopy = true;
  int count = 0;
  @override
  void initState() {
    // continueslyCall();
    //_scrollController.initialScrollOffset.isInfinite
    getCorrectData();
    super.initState();
  }

  getCorrectData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (BelnetLib.isConnected) {
      print(
          "data from sharedpreferences PREV_LOG_DATA ${prefs.getStringList("PREV_LOG_DATA")}");
      logController.data.add(prefs.getStringList("PREV_LOG_DATA"));
      logController.timeData.add(prefs.getStringList("Prev_TIME_DATA"));
    }
  }

  void _scrollDown() {
    _scrollController.jumpTo(
      _scrollController.position.maxScrollExtent,
    );
  }

  setCancel() {
    if (logController.data.isNotEmpty) {
      canCancel = true;
      canCopy = true;
    } else {
      canCancel = false;
      canCopy = false;
      count = 0;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // getDataFromLog();
    // _scrollDown();
    setCancel();
    appModel = Provider.of<AppModel>(context);
    return Container(
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
              child: Padding(
            padding: EdgeInsets.only(
                left: MediaQuery.of(context).size.height * 0.08 / 3,
                right: MediaQuery.of(context).size.height * 0.08 / 3,
                top: MediaQuery.of(context).size.height * 0.0 / 3,
                bottom: MediaQuery.of(context).size.height * 0.03 / 3),
            child: Container(
                padding: EdgeInsets.only(left: 10, top: 8, right: 10),
                // height: MediaQuery.of(context).size.height * 1 / 3,
                width: double.infinity,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(9.0),
                    color:
                        appModel.darkTheme ? Color(0xff252532) : Colors.white),
                child: Obx(
                  () {
                    return Container(
                      //color: Colors.yellow,
                      child: ListView.builder(
                          padding: EdgeInsets.zero,
                          controller: _scrollController,
                          itemCount: logController.data.length,
                          itemBuilder: ((context, index) {
                            if (logController.data.length > 6) {
                              _scrollDown();
                            }

                            return Container(
                              child: RichText(
                                  text: TextSpan(
                                      text: '${logController.timeData[index]}',
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.04 /
                                              3,
                                          fontFamily: "Poppins",
                                          color: Color(0xffA1A1C1)),
                                      children: <TextSpan>[
                                    TextSpan(
                                        text: '${logController.data[index]}',
                                        style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.04 /
                                                3,
                                            fontFamily: "Poppins",
                                            color: appModel.darkTheme
                                                ? Color(0xffFFFFFF)
                                                : Color(0xff222222)))
                                  ])),
                            );
                          })),
                    );
                  },
                )),
          )),
          Padding(
            padding: const EdgeInsets.only(bottom: 5.0),
            child: Container(
                height: MediaQuery.of(context).size.height * 0.15 / 3,
                width: double.infinity,
                decoration: BoxDecoration(
                    // color: Colors.orange,

                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (logController.data.isNotEmpty) {
                          logController.data.clear();
                        } else {
                          setState(() {
                            canCancel = false;
                          });
                        }

                        print('cancelled');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Container(
                            padding: EdgeInsets.all(6.0),
                            width: MediaQuery.of(context).size.width * 0.85 / 3,
                            // height:MediaQuery.of(context).size.height*0.04/3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              color: Colors.grey,
                              boxShadow: appModel.darkTheme
                                  ? [
                                      // BoxShadow(
                                      //     color: Colors.black12,
                                      //     offset: Offset(-10, -10),
                                      //     spreadRadius: 0,
                                      //     blurRadius: 10),
                                      BoxShadow(
                                          color: Colors.black,
                                          offset: Offset(0, 1),
                                          blurRadius: 2.0)
                                    ]
                                  : [
                                      BoxShadow(
                                          color: Color(0xff6E6E6E),
                                          offset: Offset(0, 1),
                                          blurRadius: 2.0)
                                    ],
                              border: Border.all(
                                color: Color(0xffA1A1C1).withOpacity(0.1),
                              ),
                              gradient: LinearGradient(
                                  colors: appModel.darkTheme
                                      ? [Color(0xff20202B), Color(0xff2C2C39)]
                                      : [Color(0xffF2F0F0), Color(0xffFAFAFA)]),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: SvgPicture.asset(
                                    'assets/images/clear_x.svg',
                                    color: canCancel
                                        ? Color(0xffFF3030)
                                        : Colors.grey,
                                  ),
                                  //child: Icon(Icons.close,size:MediaQuery.of(context).size.height*0.07/3 ,color: Color(0xffFF3030),),
                                ),
                                Text(
                                  "cancel",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                              0.05 /
                                              3,
                                      fontFamily: "Poppins",
                                      color: canCancel
                                          ? Color(0xffFF3030)
                                          : Colors.grey),
                                ),
                              ],
                            )),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.07 / 3,
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          count++;
                        });
                        if (logController.data.isNotEmpty && count == 1) {
                          FlutterClipboard.copy(logController.data.toString())
                              .then((value) => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      backgroundColor: appModel.darkTheme
                                          ? Colors.black.withOpacity(0.50)
                                          : Colors.white,
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(milliseconds: 200),
                                      width: 200,
                                      content: Text(
                                        "Copied to clipboard!",
                                        style: TextStyle(
                                            color: appModel.darkTheme
                                                ? Colors.white
                                                : Colors.black),
                                        textAlign: TextAlign.center,
                                      )
                                      //content: Text("Sending Message"),
                                      )));

                          // Logger("data");

                          print('copied');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Container(
                          padding: EdgeInsets.all(6.0),
                          width: MediaQuery.of(context).size.width * 0.85 / 3,
                          // height:MediaQuery.of(context).size.height*0.04/3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            color: Colors.grey,
                            boxShadow: appModel.darkTheme
                                ? [
                                    // BoxShadow(
                                    //     color: Colors.black12,
                                    //     offset: Offset(-10, -10),
                                    //     spreadRadius: 0,
                                    //     blurRadius: 10),
                                    BoxShadow(
                                        color: Colors.black,
                                        offset: Offset(0, 1),
                                        blurRadius: 2.0)
                                  ]
                                : [
                                    BoxShadow(
                                        color: Color(0xff6E6E6E),
                                        offset: Offset(0, 1),
                                        blurRadius: 2.0)
                                  ],
                            border: Border.all(
                              color: Color(0xffA1A1C1).withOpacity(0.1),
                            ),
                            gradient: LinearGradient(
                                colors: appModel.darkTheme
                                    ? [Color(0xff20202B), Color(0xff2C2C39)]
                                    : [Color(0xffF2F0F0), Color(0xffFAFAFA)]),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: SvgPicture.asset(
                                    'assets/images/copy.svg',
                                    color: canCopy
                                        ? Color(0xff1DC021)
                                        : Colors.grey,
                                  )),
                              Text(
                                "copy",
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize:
                                        MediaQuery.of(context).size.height *
                                            0.05 /
                                            3,
                                    fontFamily: "Poppins",
                                    color: canCopy
                                        ? Color(0xff1DC021)
                                        : Colors.grey),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
          )
        ],
      ),
    );
  }
}
