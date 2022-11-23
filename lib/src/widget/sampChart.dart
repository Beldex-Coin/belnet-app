import 'dart:async';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:chart_sparkline/chart_sparkline.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';

import '../model/theme_set_provider.dart';
// import 'package:flutter_sinusoidals/flutter_sinusoidals.dart';

late AppModel appModel;

class FCharts extends StatefulWidget {
  const FCharts({Key? key}) : super(key: key);

  @override
  State<FCharts> createState() => _FChartsState();
}

class _FChartsState extends State<FCharts> {
  List<double> sparkData = [];
  List<double> sparkUpload = [];
  int _windowLen = 20 * 6;

  @override
  void initState() {
    setIntervalToCall();
    super.initState();
  }

  late Timer timer;
  setIntervalToCall() async {
    timer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (BelnetLib.isConnected) {
        getAndAssignForDownloadData(timer);
        getAndAssignForUploadData(timer);
      } else {
        timer.cancel();
      }
    });
  }

  getAndAssignForDownloadData(timer) async {
    if (sparkData.length >= _windowLen) {
      sparkData.removeAt(0);
      setState(() {});
    }
    setState(() {
      if (appModel.singleDownload != "")
        sparkData.add(stringBeforeSpace(appModel.singleDownload));
    });
  }

  getAndAssignForUploadData(timer) async {
    if (sparkUpload.length >= _windowLen) {
      sparkUpload.removeAt(0);
      setState(() {});
    }
    setState(() {
      if (appModel.singleUpload != "")
        sparkUpload.add(stringBeforeSpace(appModel.singleUpload));
    });
  }

  double stringBeforeSpace(String value) {
    String str = value;
    double valu;
    str = value.split(' ').first;
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
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Container(
              height: 100.0,
              width: double.infinity,
              child: Stack(
                children: [
                  Sparkline(data: sparkData,
                  useCubicSmoothing: true,
                  
                  ),
                  Sparkline(
                    data: sparkUpload,
                    useCubicSmoothing: true,
                    cubicSmoothingFactor: 0.2,
                    //lineColor: Colors.green,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  SideTitles get _bottomtiles => SideTitles(
      showTitles: true,
      getTitlesWidget: ((value, meta) {
        String text = '';
        return Text(value == 60
            ? 'now'
            : value == 10
                ? 'a minute ago'
                : '');
      }));

  SideTitles get _leftTiles => SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          String text = '';

          if (value < 1024.0)
            return Text("$value Kbps");
          else
            return Text("$value Mb");
        },
      );

  String stringAfterSpace(String value) {
    String str = value;
    str = value.split(' ').last;
    setState(() {});
    return str;
  }
}











































// import 'dart:async';

// import 'package:belnet_lib/belnet_lib.dart';
// import 'package:chart_sparkline/chart_sparkline.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/src/foundation/key.dart';
// import 'package:flutter/src/widgets/framework.dart';
// import 'package:provider/provider.dart';

// import '../model/theme_set_provider.dart';
// // import 'package:flutter_sinusoidals/flutter_sinusoidals.dart';

// late AppModel appModel;

// class FCharts extends StatefulWidget {
//   const FCharts({Key? key}) : super(key: key);

//   @override
//   State<FCharts> createState() => _FChartsState();
// }

// class _FChartsState extends State<FCharts> {
//   List<SpeedValues> mySpeedData = [];
//   List<SpeedValues> mySpeedForUploadData = [];
//   List<double> sparkData = [];
//   List<double> sparkUpload = [];
//   double _now = 0;
//   int _windowLen = 20 * 6;

//   @override
//   void initState() {
//     setIntervalToCall();
//     super.initState();
//   }

//   late Timer timer;
//   setIntervalToCall() async {
//     timer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
//       if (BelnetLib.isConnected) {
//         getAndAssignForDownloadData(timer);
//         getAndAssignForUploadData(timer);
//       } else {
//         timer.cancel();
//       }
//     });
//   }

//   getAndAssignForDownloadData(timer) async {
//     _now = _now + 0.03;
//     if (mySpeedData.length >= _windowLen) {
//       mySpeedData.removeAt(0);
//       sparkData.removeAt(0);
//       setState(() {});
//     }
//     setState(() {
//       if (appModel.singleDownload != "")
//         mySpeedData
//             .add(SpeedValues(_now, stringBeforeSpace(appModel.singleDownload)));
//         sparkData.add(stringBeforeSpace(appModel.singleDownload));

//       //appModel.addDownloadToList(SpeedValues(_now, stringBeforeSpace(appModel.singleDownload)));
//     });
//   }

//   getAndAssignForUploadData(timer) async {
//     _now = _now + 0.03;
//     if (mySpeedForUploadData.length >= _windowLen) {
//       print("upload list items are [${appModel.listUploadItems}]");
//       mySpeedForUploadData.removeAt(0);
//       sparkUpload.removeAt(0);
//       setState(() {});
//     }
//     setState(() {
//       if (appModel.singleUpload != "")
//         mySpeedForUploadData
//             .add(SpeedValues(_now, stringBeforeSpace(appModel.singleUpload)));
      
//         // appModel.uploadList
//         //     .add(SpeedValues(_now, stringBeforeSpace(appModel.singleUpload)));
//             sparkUpload.add(stringBeforeSpace(appModel.singleUpload));
      
//       //appModel.addUploadToList(SpeedValues(_now, stringBeforeSpace(appModel.singleUpload)));
//     });
//   }

//   double stringBeforeSpace(String value) {
//     String str = value;
//     double valu;
//     str = value.split(' ').first;
//     // val = str as double;
//     valu = double.parse(str);
//     setState(() {});
//     return valu;
//   }

//   @override
//   void dispose() {
//     timer.cancel();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     appModel = Provider.of<AppModel>(context);
//     return Scaffold(
//       body: Center(
//         child: Column(
//           children: [
//             // Container(
//             //     height: 130.0,
//             //     width: double.infinity,
//             //     margin: EdgeInsets.only(left: 10.0),
//             //     child: LineChart(
//             //       LineChartData(
//             //         //  minX: 0,
//             //         //         maxX: 8,
//             //         //         minY: 0,
//             //         //         maxY: 6,
//             //           lineBarsData: [
//             //             LineChartBarData(
//             //                 spots: mySpeedData
//             //                     .map((e) => FlSpot(e.time, e.speed))
//             //                     .toList(),
//             //                 isCurved: false,
//             //                 curveSmoothness: 3,
//             //                 isStrokeCapRound: true,
//             //                 barWidth: 0.5,
//             //                 dotData: FlDotData(show: false),
//             //                 color: Colors.green),
//             //             LineChartBarData(
//             //                 spots: mySpeedForUploadData
//             //                     .map((e) => FlSpot(e.time, e.speed))
//             //                     .toList(),
//             //                 isCurved: false,
//             //                 curveSmoothness: 3,
//             //                 //isStrokeCapRound: true,
//             //                 barWidth: 0.5,
//             //                 isStrokeJoinRound: true,
//             //                 isStepLineChart: false,
//             //                 //preventCurveOverShooting: true,
//             //                 lineChartStepData:
//             //                     LineChartStepData(stepDirection: 1.3),
//             //                 dotData: FlDotData(show: false),
//             //                 color: Colors.blue),
//             //           ],
//             //           borderData: FlBorderData(
//             //               border: const Border(
//             //                   bottom: BorderSide(), left: BorderSide())),
//             //           gridData: FlGridData(
//             //             show: false,
//             //             //verticalInterval: 3
//             //           ),
//             //           titlesData: FlTitlesData(
//             //             bottomTitles:
//             //                 AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             //             leftTitles: AxisTitles(sideTitles: _leftTiles),
//             //             topTitles:
//             //                 AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             //             rightTitles:
//             //                 AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             //           )),
//             //     )),
          
//            Container(

//              height:100.0,width:double.infinity,
//              child:Sparkline(
//              data: sparkUpload,
//              useCubicSmoothing: true,
//              cubicSmoothingFactor: 0.2,
//              lineColor: Colors.green,
//              ),

//            )
//           ],
//         ),
//       ),
//     );
//   }

//   SideTitles get _bottomtiles => SideTitles(
//       showTitles: true,
//       getTitlesWidget: ((value, meta) {
//         String text = '';
//         return Text(value == 60
//             ? 'now'
//             : value == 10
//                 ? 'a minute ago'
//                 : '');
//       }));

//   SideTitles get _leftTiles => SideTitles(
//         showTitles: true,
//         getTitlesWidget: (value, meta) {
//           String text = '';

//           if (value < 1024.0)
//             return Text("$value Kbps");
//           else
//             return Text("$value Mb");
//         },
//       );

//   String stringAfterSpace(String value) {
//     String str = value;
//     str = value.split(' ').last;
//     setState(() {});
//     return str;
//   }
// }

// class SpeedValues {
//   final double time;
//   final double speed;

//   SpeedValues(this.time, this.speed);
// }
