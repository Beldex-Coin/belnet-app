import 'dart:async';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/widget/txrxspeed.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:provider/provider.dart';

import '../model/theme_set_provider.dart';


class ChartData extends StatefulWidget {
  const ChartData({Key? key}) : super(key: key);

  @override
  State<ChartData> createState() => _ChartDataState();
}

class _ChartDataState extends State<ChartData> {

  late AppModel appModel;
late DateTime _now;
List<SpeedValues> mySpeedData=[];
List<SpeedValues> mySpeedForUploadData =[];
 int _windowLen = 30 * 6; 
  @override
  void initState() {
    getDataFromDaemon();
    setIntervalToCall();
    super.initState();
  }

 getDataFromDaemon() async {
    Timer.periodic(Duration(milliseconds: 2000), (timer) {
      if (BelnetLib.isConnected) TxRxSpeed().getDataFromChannel(appModel);
    });
  }



late Timer timer;
  setIntervalToCall()async{
  timer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
    if(BelnetLib.isConnected){
      getAndAssignForDownloadData(timer);
     getAndAssignForUploadData(timer);
    }
    
    });

   
  }
  getAndAssignForDownloadData(timer)async{

    _now = DateTime.now();
    if(mySpeedData.length >= _windowLen){
      mySpeedData.removeAt(0);
    }
    setState(() {
      mySpeedData.add(SpeedValues(_now, stringBeforeSpace(appModel.singleDownload)));
    });
    // if(mySpeedData.length < 10){
    //   _now = DateTime.now();
    //   setState(() {
    //    mySpeedData.add(SpeedValues(_now,stringBeforeSpace(appModel.singleUpload)));
    //   });
    // }else{
    //   setState(() {
    //     for(int i=0;i<mySpeedData.length;i++){
    //       mySpeedData[i] = mySpeedData[1+i];

    //     }
    //   });

    // }
  }


getAndAssignForUploadData(timer)async{ 
   _now = DateTime.now();
   if(mySpeedForUploadData.length >= _windowLen){
    mySpeedForUploadData.removeAt(0);
   }
   setState(() {
     mySpeedForUploadData.add(SpeedValues(_now, stringBeforeSpace(appModel.singleUpload)));
   });
  // if(mySpeedForUploadData.length < 10){
  //   _now = DateTime.now();
  //   setState(() {
  //     mySpeedForUploadData.add(SpeedValues(_now,stringBeforeSpace(appModel.singleUpload)));
  //   });
  // }else{
  // setState(() {
  //   for(int i=0;i<mySpeedForUploadData.length;i++){
  //     mySpeedForUploadData[i] = mySpeedForUploadData[1 + i];
  //   }
  // });
  // }
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



@override
  void dispose() {
    timer.cancel();
    super.dispose();
  }







  @override
  Widget build(BuildContext context) {
    appModel = Provider.of<AppModel>(context);
    return Charts(data: mySpeedData,dataUpload: mySpeedForUploadData,);
    
  }
}




class Charts extends StatelessWidget {
  final List<SpeedValues> data;
  final List<SpeedValues> dataUpload;
  const Charts({Key? key, required this.data, required this.dataUpload}) : super(key: key);







  @override
  Widget build(BuildContext context) {

    return Container(
          margin: EdgeInsets.only(top: 20.0),
        padding: EdgeInsets.only(bottom: 35.0, left: 15.0),
        child:BelnetLib.isConnected ?
        Stack(

          children: [
            Container(
               padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.height * 0.20 / 3,
                          //top: MediaQuery.of(context).size.height * 0.09 / 3
                          ),
             // height:160,width:300,
              child: charts.TimeSeriesChart(
                  [
                    charts.Series<SpeedValues, DateTime>(
                      id: 'Values',
                      colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
                      domainFn: (SpeedValues values, _) => values.time,
                      measureFn: (SpeedValues values, _) => values.speed,
                      data: data,
                      overlaySeries: true //added extra
                    ),
                    charts.Series<SpeedValues, DateTime>(
                      id: 'Values',
                      colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
                      domainFn: (SpeedValues values, _) => values.time,
                      measureFn: (SpeedValues values, _) => values.speed,
                      data: dataUpload,
                    )
                  ],
                  animate: false,
                  primaryMeasureAxis: charts.NumericAxisSpec(
                    tickProviderSpec:  charts.BasicNumericTickProviderSpec(zeroBound: false),
                    renderSpec: charts.NoneRenderSpec(),
                  ),
                 domainAxis: new charts.DateTimeAxisSpec(
                  renderSpec: new charts.NoneRenderSpec())
              ),
            ),
            Positioned(
                    bottom: 0.0, right: 5.0, left: 15.0,
                    top: MediaQuery.of(context).size.height * 0.50 / 3,
                    //width: double.infinity,
                    child: Container(
                      color: Colors.transparent,
                      height: MediaQuery.of(context).size.height * 0.50 / 3,
                      padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.height * 0.10 / 3),
                      child: Column(children: [
                        // Text("dad"),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                "a minute ago",
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.height *
                                            0.04 /
                                            3),
                              ),
                            ),
                            Text(
                              "now",
                              style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.height *
                                      0.04 /
                                      3),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 2.0,
                        ),
                        Row(
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
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0),
                                child: GestureDetector(
                                  // onTap: (() => Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //         builder: (context) =>
                                  //             ChartPainter()))),
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
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0),
                                child: Text(
                                  "upload",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                              0.04 /
                                              3,
                                      color: Color(0xff1CA3FC)),
                                ),
                              )
                            ])
                      ]),
                    ),
                  ),
                Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.15 / 3,
                    left: MediaQuery.of(context).size.height * 0.0 / 3,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.60 / 3,
                      width: MediaQuery.of(context).size.width * 0.49 / 3,
                      // decoration: BoxDecoration(color: Colors.orange),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "8.0 mb",
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.04 / 3,
                            ),
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).size.height *
                                  0.10 /
                                  3),
                          Text(
                            "4.0 mb",
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.04 / 3,
                            ),
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.10 / 3,
                          ),
                          Text(
                            "2.0 mb",
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.04 / 3,
                            ),
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.04 / 3,
                          ),
                        ],
                      ),
                    ),
                  )



          ],
        ):
        Container()
    );
  }
}






class SpeedValues{
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