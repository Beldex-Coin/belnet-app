import 'dart:async';
import 'dart:math';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/widget/txrxspeed.dart';
import 'package:chart_sparkline/chart_sparkline.dart';
//import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/theme_set_provider.dart';

late DateTime _now;
late AppModel appModel;
double mbForDown = 0.0;
double mbForUp = 0.0, mbForUpDown=0.0;
class ChartData extends StatefulWidget {
  const ChartData({Key? key}) : super(key: key);

  @override
  State<ChartData> createState() => _ChartDataState();
}

class _ChartDataState extends State<ChartData> {
  List<SpeedValues> mySpeedData = [];
  List<SpeedValues> mySpeedForUploadData = [];
  List<double> samdata = [];
  List<double> dataForup = [];
  int _windowLen = 10 * 6;
  @override
  void initState() {
    getDataFromDaemon();
    setIntervalToCall();
    changeData();
    super.initState();
  }

  getDataFromDaemon() async {
    Timer.periodic(Duration(milliseconds: 2000), (timer) {
      if (BelnetLib.isConnected) TxRxSpeed().getDataFromChannel(appModel);
    });
  }

  late Timer timer;
  setIntervalToCall() async {
    timer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (BelnetLib.isConnected) {
        getAndAssignForDownloadData(timer);
        getAndAssignForUploadData(timer);
      }
    });
  }

  getAndAssignForDownloadData(timer) async {
    _now = DateTime.now();
    if (appModel.downloadList.length >= _windowLen) {
      print("download list items are [${appModel.listDownloadItems}]");
      appModel.downloadList.removeAt(0);
    }
    if (appModel.singleDownload != "")
      appModel.downloadList.add(stringBeforeSpace(appModel.singleDownload));

     
  }

  getAndAssignForUploadData(timer) async {
    _now = DateTime.now(); //.add(Duration(minutes: 3));
    if (appModel.uploadList.length >= _windowLen) {
      print("upload list items are [${appModel.listUploadItems}]");
      appModel.uploadList.removeAt(0);
    }
    if (appModel.singleUpload != "")
      appModel.uploadList.add(stringBeforeSpace(appModel.singleUpload));
  }

// Getting Data for the live connection

  double stringBeforeSpace(String value) {
    String str = value;
    double valu;
    str = value.split(' ').first;
    // val = str as double;
    valu = double.parse(str);
    setState(() {});
    return valu;
  }

  changeData() async {
    Timer.periodic(Duration(seconds: 1), (timer) {
      setChangeData();
    });
  }
 List makeList =[];
  setChangeData() async {
    List s1 = [2.0, 4.0, 8.5, 6.3];
    List s2 = [2.0, 2.0, 1.2, 7.0];
    List s3 = [8.2, 2.7, 3.0, 9.2];
    if (BelnetLib.isConnected) {
    //  makeList =[];
    //   var rand = Random();
    //   var a = s1[rand.nextInt(s1.length)];
    //   var b = s2[rand.nextInt(s2.length)];
    //   var c = s3[rand.nextInt(s3.length)];
    //   makeList.add(a);
    //   makeList.add(b);
    //   makeList.add(c);
    //   makeList.sort();

    // setState(() {
    //    mbForUpDown = makeList[0];
    //   mbForUp = makeList[1];
    //   mbForDown = makeList[2];
     
    // });

      // var a1, a2;
      // if (a < b) {
      //   mbForDown = a;
      //   mbForUp = b;
      //   setState(() {});
      // } else {
      //   mbForDown = b;
      //   mbForUp = a;
      //   setState(() {});
      // }

    List myD=[];
    myD.add(appModel.graphData1);
    myD.add(appModel.graphData2);
    myD.add(appModel.graphData3);
    myD.sort();
    setState(() {
      mbForDown = myD[0];
    mbForUp = myD[1];
    mbForUpDown = myD[2];
    });
    



      print(" valeu fpr this $mbForUp $mbForDown $mbForUpDown");
    }
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    appModel = Provider.of<AppModel>(context);
    return Charts(
      data: mySpeedData,
      dataUpload: mySpeedForUploadData,
      dsam: appModel.downloadList,
      samUp: appModel.uploadList,
    );
  }
}

class Charts extends StatelessWidget {
  final List<SpeedValues> data;
  final List<SpeedValues> dataUpload;
  final List<double> dsam;
  final List<double> samUp;
  const Charts(
      {Key? key,
      required this.data,
      required this.dataUpload,
      required this.dsam,
      required this.samUp})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        // color: Colors.yellow,
        margin: EdgeInsets.only(top: 20.0),
        padding: EdgeInsets.only(
            //bottom: MediaQuery.of(context).size.height*0.10/3,
            left: 15.0),
        child: BelnetLib.isConnected
            ? Stack(
                children: [
                  Container(
                      padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.height * 0.05 / 3,
                          right: MediaQuery.of(context).size.height * 0.05 / 3,
                          bottom: MediaQuery.of(context).size.height * 0.10 / 3
                          //top: MediaQuery.of(context).size.height * 0.09 / 3
                          ),
                      // height:160,width:300,
                      child: Container(
                        height: MediaQuery.of(context).size.height *
                            0.70 /
                            3, //130,
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height * 0.08 / 3,
                          left: MediaQuery.of(context).size.height *
                              0.10 /
                              3, //right: MediaQuery.of(context).size.height*0.08/3
                        ),
                        child: Container(
                          // height: MediaQuery.of(context).size.height*0.65/3,
                          padding: EdgeInsets.only(
                            top: 60.0,
                            bottom:
                                MediaQuery.of(context).size.height * 0.03 / 3,
                            // left: MediaQuery.of(context).size.height*0.10/3,
                            // right: MediaQuery.of(context).size.height*0.08/3
                          ),
                          decoration: BoxDecoration(
                              border: Border(
                                  left: BorderSide(
                                    color: Colors.grey,
                                  ),
                                  bottom: BorderSide(color: Colors.grey))),
                          child: Stack(
                            children: [
                              Sparkline(
                                data: dsam,
                                useCubicSmoothing: true,
                                cubicSmoothingFactor: 0.2,
                                lineColor: Colors.green,
                                sharpCorners: true,
                                //thresholdSize: 0.8,
                                // min: 0,
                                // max:8,
                              ),
                              Positioned(
                                // bottom: 3.0,

                                child: Sparkline(
                                  data: samUp,
                                  useCubicSmoothing: true,
                                  cubicSmoothingFactor: 0.2,
                                  lineColor: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )

                      //  charts.TimeSeriesChart(

                      //     [
                      //       charts.Series<SpeedValues, DateTime>(
                      //         id: 'Values',
                      //         colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
                      //         domainFn: (SpeedValues values, _) => values.time,
                      //         measureFn: (SpeedValues values, _) => values.speed,
                      //         data: data,
                      //         //overlaySeries: false //added extra
                      //       ),
                      //       charts.Series<SpeedValues, DateTime>(
                      //        // domainFormatterFn: (datum, index) => getString() ,
                      //         id: 'Values',
                      //         colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
                      //         domainFn: (SpeedValues values, _) => values.time,
                      //         measureFn: (SpeedValues values, _) => values.speed,
                      //         data: dataUpload,
                      //         //radiusPxFn: (datum, index) => datum.speed,
                      //       ),

                      //     ],

                      //     animate: false,
                      //     primaryMeasureAxis: charts.NumericAxisSpec(
                      //       //viewport: charts.NumericExtents(0, 10),
                      //       showAxisLine: true,
                      //       tickProviderSpec:  charts.BasicNumericTickProviderSpec(zeroBound: false,
                      //       dataIsInWholeNumbers: true,
                      //      desiredMinTickCount: 3,
                      //      desiredMaxTickCount: 4

                      //       ),
                      //       renderSpec: charts.SmallTickRendererSpec(
                      //         //minimumPaddingBetweenLabelsPx: 15
                      //       ) //charts.NoneRenderSpec(),
                      //     ),
                      //   //  domainAxis: new charts.DateTimeAxisSpec(
                      //   //   //tickProviderSpec: ,
                      //   //   renderSpec: new charts.NoneRenderSpec()
                      //   //   ),
                      //     secondaryMeasureAxis: charts.NumericAxisSpec(
                      //       showAxisLine: true,
                      //    viewport: charts.NumericExtents(100,-100),

                      //       tickProviderSpec:  charts.BasicNumericTickProviderSpec(zeroBound: false,
                      //       dataIsInWholeNumbers: true,
                      //       //desiredTickCount: 1
                      //       ),
                      //       renderSpec: charts.NoneRenderSpec()
                      //       // charts.SmallTickRendererSpec(
                      //       //   //labelOffsetFromAxisPx: 5,
                      //       //   //labelStyle:

                      //       //  // minimumPaddingBetweenLabelsPx: 10
                      //       // )   //charts.NoneRenderSpec(),
                      //     ),
                      // ),
                      ),
                  Positioned(
                    bottom: 0.0, right: 5.0,
                    left: MediaQuery.of(context).size.height * 0.05 / 3,
                    top: MediaQuery.of(context).size.height * 0.54 / 3,
                    //width: double.infinity,
                    child: Container(
                      //color: Colors.black,
                      // color: Colors.pink,
                      height: MediaQuery.of(context).size.height * 0.50 / 3,
                      padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.height * 0.10 / 3,
                        right: MediaQuery.of(context).size.height * 0.10 / 3,
                      ),
                      child: Column(children: [
                        // Text("dad"),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, right: 8.0),
                              child: Text(
                                "a minute ago",
                                style: TextStyle(
                                    color: appModel.darkTheme
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize:
                                        MediaQuery.of(context).size.height *
                                            0.03 /
                                            3),
                              ),
                            ),
                            Text(
                              "now",
                              style: TextStyle(
                                  color: appModel.darkTheme
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: MediaQuery.of(context).size.height *
                                      0.03 /
                                      3),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                  Positioned(
                      bottom: MediaQuery.of(context).size.height * 0.01 / 3,
                      top: MediaQuery.of(context).size.height * 0.55 / 3,
                      right: MediaQuery.of(context).size.height * 0.0 / 3,
                      child: Container(
                          //color: Colors.pink,
                          // height: MediaQuery.of(context).size.height*0.20/3,
                          //width: double.infinity,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                            Container(
                              height: 10.0,
                              width: 10.0,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xff23DC27)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, right: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  // Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //         builder: (context) =>
                                  //             ChartPainter()));
                                },
                                child: Text(
                                  "Download",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                              0.04 /
                                              3,
                                      color: Color(0xff23DC27)),
                                ),
                              ),
                            ),
                            Container(
                              height: 10.0,
                              width: 10.0,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xff1CA3FC)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, right: 8.0),
                              child: Text(
                                "Upload",
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.height *
                                            0.04 /
                                            3,
                                    color: Color(0xff1CA3FC)),
                              ),
                            )
                          ]))),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.15 / 3,
                    left: MediaQuery.of(context).size.height * 0.0 / 3,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.60 / 3,
                      width: MediaQuery.of(context).size.width * 0.30 / 3,
                      // decoration: BoxDecoration(color: Colors.orange),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "${mbForUpDown.toStringAsFixed(1)} Mb/s",
                            style: TextStyle(
                              color: appModel.darkTheme
                                  ? Colors.white
                                  : Colors.black,
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.03 / 3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).size.height *
                                  0.15 /
                                  3),
                          Text(
                            "${mbForUp.toStringAsFixed(1)} Mb/s",
                            style: TextStyle(
                              color: appModel.darkTheme
                                  ? Colors.white
                                  : Colors.black,
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.03 / 3,
                            ),
                             maxLines: 2,
                            overflow: TextOverflow.ellipsis
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.15 / 3,
                          ),
                          Text(
                            "${mbForDown.toStringAsFixed(1)} Mb/s",
                            style: TextStyle(
                              color: appModel.darkTheme
                                  ? Colors.white
                                  : Colors.black,
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.03 / 3,
                            ),
                             maxLines: 2,
                            overflow: TextOverflow.ellipsis
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.10 / 3,
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              )
            : Stack(
                children: [
                  Container(
                      padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.height * 0.05 / 3,
                          right: MediaQuery.of(context).size.height * 0.05 / 3,
                          bottom: MediaQuery.of(context).size.height * 0.10 / 3
                          //top: MediaQuery.of(context).size.height * 0.09 / 3
                          ),
                      // height:160,width:300,
                      child: Container(
                        height: MediaQuery.of(context).size.height *
                            0.70 /
                            3, //130,
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height * 0.08 / 3,
                          left: MediaQuery.of(context).size.height *
                              0.10 /
                              3, //right: MediaQuery.of(context).size.height*0.08/3
                        ),
                        child: Container(
                          // height: MediaQuery.of(context).size.height*0.65/3,
                          padding: EdgeInsets.only(
                            top: 60.0,
                            bottom:
                                MediaQuery.of(context).size.height * 0.03 / 3,
                            // left: MediaQuery.of(context).size.height*0.10/3,
                            // right: MediaQuery.of(context).size.height*0.08/3
                          ),
                          decoration: BoxDecoration(
                              border: Border(
                                  left: BorderSide(
                                    color: Colors.grey,
                                  ),
                                  bottom: BorderSide(color: Colors.grey))),
                          child: Stack(
                            children: [],
                          ),
                        ),
                      )),
                  Positioned(
                    bottom: 0.0, right: 5.0,
                    left: MediaQuery.of(context).size.height * 0.05 / 3,
                    top: MediaQuery.of(context).size.height * 0.54 / 3,
                    //width: double.infinity,
                    child: Container(
                      //color: Colors.black,
                      // color: Colors.pink,
                      height: MediaQuery.of(context).size.height * 0.50 / 3,
                      padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.height * 0.10 / 3,
                        right: MediaQuery.of(context).size.height * 0.10 / 3,
                      ),
                      child: Column(children: [
                        // Text("dad"),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, right: 8.0),
                              child: Text(
                                "a minute ago",
                                style: TextStyle(
                                    color: Color(0xff56566F),
                                    fontSize:
                                        MediaQuery.of(context).size.height *
                                            0.03 /
                                            3),
                              ),
                            ),
                            Text(
                              "now",
                              style: TextStyle(
                                  color: Color(0xff56566F),
                                  fontSize: MediaQuery.of(context).size.height *
                                      0.03 /
                                      3),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                  Positioned(
                      bottom: MediaQuery.of(context).size.height * 0.01 / 3,
                      top: MediaQuery.of(context).size.height * 0.55 / 3,
                      right: MediaQuery.of(context).size.height * 0.0 / 3,
                      child: Container(
                          //color: Colors.pink,
                          // height: MediaQuery.of(context).size.height*0.20/3,
                          //width: double.infinity,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                            Container(
                              height: 10.0,
                              width: 10.0,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xff56566F)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, right: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  // Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //         builder: (context) =>
                                  //             ChartPainter()));
                                },
                                child: Text(
                                  "Download",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                              0.04 /
                                              3,
                                      color: Color(0xff56566F)),
                                ),
                              ),
                            ),
                            Container(
                              height: 10.0,
                              width: 10.0,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xff56566F)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, right: 8.0),
                              child: Text(
                                "upload",
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.height *
                                            0.04 /
                                            3,
                                    color: Color(0xff56566F)),
                              ),
                            )
                          ]))),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.15 / 3,
                    left: MediaQuery.of(context).size.height * 0.0 / 3,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.60 / 3,
                      width: MediaQuery.of(context).size.width * 0.29 / 3,
                      // decoration: BoxDecoration(color: Colors.orange),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "0.0 Mb/s",
                            style: TextStyle(
                              color: Color(0xff56566F),
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.03 / 3,
                            ),
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).size.height *
                                  0.15 /
                                  3),
                          Text(
                            "0.0 Mb/s",
                            style: TextStyle(
                              color: Color(0xff56566F),
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.03 / 3,
                            ),
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.15 / 3,
                          ),
                          Text(
                            "0.0 Mb/s",
                            style: TextStyle(
                              color: Color(0xff56566F),
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.03 / 3,
                            ),
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.10 / 3,
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ));
  }
}

class SpeedValues {
  final DateTime time;
  final double speed;

  SpeedValues(this.time, this.speed);
}

// original code

// import 'dart:async';

// import 'package:belnet_lib/belnet_lib.dart';
// import 'package:belnet_mobile/src/widget/txrxspeed.dart';
// import 'package:charts_flutter/flutter.dart' as charts;
// import 'package:flutter/material.dart';
// import 'package:flutter/src/widgets/framework.dart';
// import 'package:flutter/src/foundation/key.dart';
// import 'package:provider/provider.dart';

// import '../model/theme_set_provider.dart';

// class ChartData extends StatefulWidget {
//   const ChartData({Key? key}) : super(key: key);

//   @override
//   State<ChartData> createState() => _ChartDataState();
// }

// class _ChartDataState extends State<ChartData> {

//   late AppModel appModel;
// late DateTime _now;
// List<SpeedValues> mySpeedData=[];
// List<SpeedValues> mySpeedForUploadData =[];
//  int _windowLen = 30 * 6;
//   @override
//   void initState() {
//     getDataFromDaemon();
//     setIntervalToCall();
//     super.initState();
//   }

//  getDataFromDaemon() async {
//     Timer.periodic(Duration(milliseconds: 2000), (timer) {
//       if (BelnetLib.isConnected) TxRxSpeed().getDataFromChannel(appModel);
//     });
//   }

// late Timer timer;
//   setIntervalToCall()async{
//   timer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
//     if(BelnetLib.isConnected){
//       getAndAssignForDownloadData(timer);
//      getAndAssignForUploadData(timer);
//     }

//     });

//   }
//   getAndAssignForDownloadData(timer)async{

//     _now = DateTime.now();
//     if(mySpeedData.length >= _windowLen){
//       mySpeedData.removeAt(0);
//     }
//     setState(() {
//       mySpeedData.add(SpeedValues(_now, stringBeforeSpace(appModel.singleDownload)));
//     });
//     // if(mySpeedData.length < 10){
//     //   _now = DateTime.now();
//     //   setState(() {
//     //    mySpeedData.add(SpeedValues(_now,stringBeforeSpace(appModel.singleUpload)));
//     //   });
//     // }else{
//     //   setState(() {
//     //     for(int i=0;i<mySpeedData.length;i++){
//     //       mySpeedData[i] = mySpeedData[1+i];

//     //     }
//     //   });

//     // }
//   }

// getAndAssignForUploadData(timer)async{
//    _now = DateTime.now();
//    if(mySpeedForUploadData.length >= _windowLen){
//     mySpeedForUploadData.removeAt(0);
//    }
//    setState(() {
//      mySpeedForUploadData.add(SpeedValues(_now, stringBeforeSpace(appModel.singleUpload)));
//    });
//   // if(mySpeedForUploadData.length < 10){
//   //   _now = DateTime.now();
//   //   setState(() {
//   //     mySpeedForUploadData.add(SpeedValues(_now,stringBeforeSpace(appModel.singleUpload)));
//   //   });
//   // }else{
//   // setState(() {
//   //   for(int i=0;i<mySpeedForUploadData.length;i++){
//   //     mySpeedForUploadData[i] = mySpeedForUploadData[1 + i];
//   //   }
//   // });
//   // }
// }

// // Getting Data for the live connection

//   double stringBeforeSpace(String value) {
//     String str = value;
//     double valu;
//     str = value.split(' ').first;
//     // val = str as double;
//     valu = double.parse(str);
//     setState(() {});
//     return valu;
//   }

// @override
//   void dispose() {
//     timer.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     appModel = Provider.of<AppModel>(context);
//     return Charts(data: mySpeedData,dataUpload: mySpeedForUploadData,);

//   }
// }

// class Charts extends StatelessWidget {
//   final List<SpeedValues> data;
//   final List<SpeedValues> dataUpload;
//   const Charts({Key? key, required this.data, required this.dataUpload}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {

//     return Container(

//         child: Center(
//           child: Container(
//            // height:160,width:300,
//             child: charts.TimeSeriesChart(
//                 [
//                   charts.Series<SpeedValues, DateTime>(
//                     id: 'Values',
//                     colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
//                     domainFn: (SpeedValues values, _) => values.time,
//                     measureFn: (SpeedValues values, _) => values.speed,
//                     data: data,
//                   ),
//                   charts.Series<SpeedValues, DateTime>(
//                     id: 'Values',
//                     colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
//                     domainFn: (SpeedValues values, _) => values.time,
//                     measureFn: (SpeedValues values, _) => values.speed,
//                     data: dataUpload,
//                   )
//                 ],
//                 animate: false,
//                 primaryMeasureAxis: charts.NumericAxisSpec(
//                   tickProviderSpec:  charts.BasicNumericTickProviderSpec(zeroBound: false),
//                   renderSpec: charts.NoneRenderSpec(),
//                 ),
//                domainAxis: new charts.DateTimeAxisSpec(
//                 renderSpec: new charts.NoneRenderSpec())
//             ),
//           ),
//         )
//     );
//   }
// }

// class SpeedValues{
//    final DateTime time;
//    final double speed;

//   SpeedValues(this.time, this.speed);

// }
