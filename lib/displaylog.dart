import 'dart:async';
import 'dart:developer';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:clipboard/clipboard.dart';

import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/src/foundation/key.dart';
// import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class DisplayLog extends StatefulWidget {
  const DisplayLog({Key? key}) : super(key: key);

  @override
  State<DisplayLog> createState() => _DisplayLogState();
}

class _DisplayLogState extends State<DisplayLog> {
  ScrollController _scrollController =
      new ScrollController(initialScrollOffset: 50.0);
  // List<String> comments = <String>[];
  // Stream<List<String>> coms = <String>[] as Stream<List<String>>;
  List datas = ["belnet about to start", "work good"];
  final _recipeStreamController = StreamController();
  bool canCancel = true;
  @override
  void initState() {
    // Timer.periodic(Duration(milliseconds: 100),(timer){
    getDataFromLog();
    //});

    super.initState();
  }

  getDataFromLog() async {
    var data = await BelnetLib.logDetails;
    _recipeStreamController.sink.add(data);

    setState(() {
      datas.add(data);
    });
  }

  @override
  void dispose() {
    _recipeStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    getDataFromLog();

    final appModel = Provider.of<AppModel>(context);
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
              child: Padding(
            padding: EdgeInsets.only(
                left: MediaQuery.of(context).size.height * 0.08 / 3,
                right: MediaQuery.of(context).size.height * 0.08 / 3,
                top: MediaQuery.of(context).size.height * 0.06 / 3,
                bottom: MediaQuery.of(context).size.height * 0.03 / 3),
            child: Container(
                height: MediaQuery.of(context).size.height * 1 / 3,
                width: double.infinity,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(9.0),
                    color:
                        appModel.darkTheme ? Color(0xff252532) : Colors.white),
                child: ListView.builder(
                    itemCount: datas.length,
                    itemBuilder: ((context, index) {
                      return Text(
                        '${datas[index]}',
                        style: TextStyle(
                            color: appModel.darkTheme
                                ? Colors.white
                                : Colors.black),
                      );
                    }))),
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
                    InkWell(
                      onTap: () {
                        if (datas.isNotEmpty) {
                          datas.clear();
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
                                      'assets/images/clear_x.svg'),
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
                                )
                              ],
                            )),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.07 / 3,
                    ),
                    InkWell(
                      onTap: () {
                        if (datas.isNotEmpty || datas == "") {
                          FlutterClipboard.copy(datas.toString()).then(
                              (value) => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      backgroundColor: Colors.black,
                                      content: Text(
                                        "Copied successfully!",
                                        style: TextStyle(color: Colors.white),
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
                                      'assets/images/copy.svg')),
                              Text(
                                "copy",
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize:
                                        MediaQuery.of(context).size.height *
                                            0.05 /
                                            3,
                                    fontFamily: "Poppins",
                                    color: Color(0xff1DC021)),
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
