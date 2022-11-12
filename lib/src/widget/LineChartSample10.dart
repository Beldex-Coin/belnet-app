// import 'package:flutter/material.dart';
// import 'package:flutter/src/foundation/key.dart';
// import 'package:flutter/src/widgets/framework.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

// class ChartPainter extends StatefulWidget {
//   const ChartPainter({Key? key}) : super(key: key);

//   @override
//   State<ChartPainter> createState() => _ChartPainterState();
// }

// class _ChartPainterState extends State<ChartPainter> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//      body:Container(
//       child: SfCartesianChart(  
//           primaryXAxis: NumericAxis(
//                             //rangePadding: ChartRangePadding.,
//                             labelFormat: " ",
//                             // anchorRangeToVisiblePoints: false,
//                             //associatedAxisName: "time",
//                             majorGridLines:
//                                 MajorGridLines(color: Colors.transparent)),
//                         primaryYAxis: NumericAxis(
//                             labelFormat: " ",
//                             majorGridLines: MajorGridLines(
//                               color: Colors.transparent,
//                             )),

//                            selectionType: SelectionType.series,
//                         //enableSideBySideSeriesPlacement: false,
//                         plotAreaBorderColor: Colors.transparent,
//                         plotAreaBackgroundColor: Colors.transparent,
//                         series: <SplineSeries>[
//                           SplineSeries<dynamic, int>(
//                               //xAxisName: "Download",
//                               width: 0.8,
//                               initialSelectedDataIndexes: [0, 0],

//                               //splineType: SplineType.clamped,
//                               onRendererCreated:
//                                   (ChartSeriesController controller) =>
//                                       _chartSeriesController = controller,
//                               dataSource: chartData,
//                               xValueMapper: (LiveData netw, _) => netw.time,
//                               color: Color(0xff23DC27),
//                               yValueMapper: (LiveData netw, _) => netw.speed),
//                           // SplineSeries<LiveData, int>(
//                           //     width: 0.8,
//                           //     initialSelectedDataIndexes: [0, 0],
//                           //     //splineType: SplineType.clamped,
//                           //     onRendererCreated:
//                           //         (ChartSeriesController controller) =>
//                           //             _chartSeriesController = controller,
//                           //     dataSource: charts,
//                           //     xValueMapper: (LiveData netw, _) => netw.time,
//                           //     color: Color(0xff1CA3FC),
//                           //     yValueMapper: (LiveData netw, _) => netw.speed),
//                         ]), 
//       ),
//      )
//     );
//   }
// }