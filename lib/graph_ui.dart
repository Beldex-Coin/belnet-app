// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';

// class NetworkSpeedGraph extends StatefulWidget {
//   const NetworkSpeedGraph({super.key});

//   @override
//   State<NetworkSpeedGraph> createState() => _NetworkSpeedGraphState();
// }

// class _NetworkSpeedGraphState extends State<NetworkSpeedGraph> {
//   List<FlSpot> downloadSpots = [];
//   List<FlSpot> uploadSpots = [];
//   List<FlSpot> pingSpots = [];
//   final int maxDataPoints = 60; // 60 seconds of data
//   double time = 0;
//   final double maxY = 0.06; // Max speed in Mbps
//   Timer? timer;

//   @override
//   void initState() {
//     super.initState();
//     // Initialize with some data
//     for (int i = 0; i < maxDataPoints; i++) {
//       downloadSpots.add(FlSpot(i.toDouble(), 0));
//       uploadSpots.add(FlSpot(i.toDouble(), 0));
//       pingSpots.add(FlSpot(i.toDouble(), 0));
//     }
//     // Start updating data dynamically
//     startUpdatingData();
//   }

//   void startUpdatingData() {
//     timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
//       setState(() {
//         time++;
//         // Simulate random network speed data (in Mbps)
//         double downloadSpeed = Random().nextDouble() * 0.05;
//         double uploadSpeed = Random().nextDouble() * 0.03;
//         double pingValue = Random().nextDouble() * 0.04;

//         // Add new data points
//         downloadSpots.add(FlSpot(time, downloadSpeed));
//         uploadSpots.add(FlSpot(time, uploadSpeed));
//         pingSpots.add(FlSpot(time, pingValue));

//         // Remove oldest data points if we exceed maxDataPoints
//         if (downloadSpots.length > maxDataPoints) {
//           downloadSpots.removeAt(0);
//           uploadSpots.removeAt(0);
//           pingSpots.removeAt(0);
//         }

//         // Normalize x-values to span from 0 to maxDataPoints - 1
//         for (int i = 0; i < downloadSpots.length; i++) {
//           double normalizedX = (i / (downloadSpots.length - 1)) * (maxDataPoints - 1);
//           downloadSpots[i] = FlSpot(normalizedX, downloadSpots[i].y);
//           uploadSpots[i] = FlSpot(normalizedX, uploadSpots[i].y);
//           pingSpots[i] = FlSpot(normalizedX, pingSpots[i].y);
//         }
//       });
//     });
//   }

//   @override
//   void dispose() {
//     timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     width: 8,
//                     height: 8,
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.green,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   const Text(
//                     'Download',
//                     style: TextStyle(color: Color(0xffACACAC), fontSize: 10,fontFamily: 'Poppins'),
//                   ),
//                 ],
//               ),
//               const SizedBox(width: 20),
//               Row(
//                 children: [
//                   Container(
//                     width: 8,
//                     height: 8,
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   const Text(
//                     'Upload',
//                     style: TextStyle(color: Color(0xffACACAC), fontSize: 10,fontFamily: 'Poppins'),
//                   ),
//                 ],
//               ),
            
//             ],
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             height: 100,
//             child: LineChart(
//               LineChartData(
//                 gridData: const FlGridData(
//                   //drawVerticalLine: true,
//                  // show: true
//                   ),
//                 titlesData: FlTitlesData(
//                   leftTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 50,
//                       interval: 0.02,
//                       getTitlesWidget: (value, meta) {
//                         if (value == 0.02 || value == 0.04 || value == 0.06) {
//                           return Padding(
//                             padding: const EdgeInsets.only(right: 5.0),
//                             child: Text(
//                               '${value.toStringAsFixed(2)}Mbps',
//                               style: const TextStyle(color: Colors.white, fontSize: 9),
//                               textAlign: TextAlign.right,
//                             ),
//                           );
//                         }
//                         return const Text('');
//                       },
//                     ),
//                     axisNameWidget: null,
//                     axisNameSize: 0,
//                   ),
//                   bottomTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       getTitlesWidget: (value, meta) {
//                         if (value == 0) {
//                           return const Text(
//                             'a minute ago',
//                             style: TextStyle(color: Colors.white, fontSize: 9),
//                           );
//                         } else if (value == meta.max) {
//                           return const Text(
//                             'Now',
//                             style: TextStyle(color: Colors.white, fontSize: 9),
//                           );
//                         }
//                         return const Text('');
//                       },
//                     ),
//                     axisNameWidget: null,
//                     axisNameSize: 0,
//                   ),
//                   topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 ),
//                 borderData: FlBorderData(
//                   show: true,
//                   border: const Border(
//                     left: BorderSide(color: Colors.white24, width: 1),
//                     bottom: BorderSide.none,
//                     top: BorderSide.none,
//                     right: BorderSide.none,
//                   ),
//                 ),
//                 minX: 0,
//                 maxX: maxDataPoints.toDouble() - 1,
//                 minY: 0,
//                 maxY: maxY,
//                 lineBarsData: [
//                   LineChartBarData(
//                     spots: downloadSpots,
//                     isCurved: true,
//                     color: Colors.green,
//                     barWidth: 2,
//                     dotData: const FlDotData(show: false),
//                   ),
//                   LineChartBarData(
//                     spots: uploadSpots,
//                     isCurved: true,
//                     color: Colors.blue,
//                     barWidth: 2,
//                     dotData: const FlDotData(show: false),
//                   ),
//                   // LineChartBarData(
//                   //   spots: pingSpots,
//                   //   isCurved: true,
//                   //   color: Colors.orange,
//                   //   barWidth: 2,
//                   //   dotData: const FlDotData(show: false),
//                   // ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'dart:async';
import 'dart:math';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/widget/LineChartSample10.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DynamicNetworkSpeedChart extends StatefulWidget {
  @override
  _DynamicNetworkSpeedChartState createState() => _DynamicNetworkSpeedChartState();
}

class _DynamicNetworkSpeedChartState extends State<DynamicNetworkSpeedChart> {
  List<FlSpot> downloadSpots = [];
  List<FlSpot> uploadSpots = [];
  double xValue = 0;
  Timer? _timer;
  final int maxPoints = 20; // Limit to 20 points to keep chart readable

  @override
  void initState() {
    super.initState();
    // Start simulating network speed every second
    // _timer = Timer.periodic(Duration(seconds: 1), (_) {
    //   _addNewData(
    //     downloadSpeed: Random().nextDouble() * 0.08, // Simulate 0 to 0.08 mb
    //     uploadSpeed: Random().nextDouble() * 0.02,   // Simulate 0 to 0.02 mb
    //   );
    // });
     _timer = Timer.periodic(Duration(seconds: 1), (_) async {
    try {
      final result = await BelnetLib.getSpeedStatus; // Ensure this returns a Map
      if (result != null && result['rxRate'] != null && result['txRate'] != null) {
        final int rxRate = result['rxRate']; // in bytes per second
        final int txRate = result['txRate']; // in bytes per second

        // Convert to Megabits per second (Mb/s) => bytes * 8 / 1,000,000
        final double downloadMbps = rxRate * 8 / 1000000;
        final double uploadMbps = txRate * 8 / 1000000;

        _addNewData(downloadSpeed: downloadMbps, uploadSpeed: uploadMbps);
      }
    } catch (e) {
      // Optional: log or show error
      debugPrint("Error fetching speed data: $e");
    }
  });
  }

  void _addNewData({required double downloadSpeed, required double uploadSpeed}) {
    setState(() {
      xValue += 1;
      downloadSpots.add(FlSpot(xValue, downloadSpeed));
      uploadSpots.add(FlSpot(xValue, uploadSpeed));

      // Keep points within the maxPoints window
      if (downloadSpots.length > maxPoints) downloadSpots.removeAt(0);
      if (uploadSpots.length > maxPoints) uploadSpots.removeAt(0);
    });
  }


//   double getDynamicMaxY() {
//   final allYValues = [...downloadSpots, ...uploadSpots].map((e) => e.y).toList();
//   final maxYValue = allYValues.isNotEmpty ? allYValues.reduce(max) : 0.08;
//   return maxYValue + 0.1; // Add a buffer
// }

double getDynamicMaxY() {
  final allY = [...downloadSpots, ...uploadSpots].map((e) => e.y).toList();
  final maxY = allY.isNotEmpty ? allY.reduce((a, b) => a > b ? a : b) : 0.1;
  return (maxY + 0.1);
}

double getYInterval() {
  final maxY = getDynamicMaxY();
  return (maxY / 2).clamp(0.01, double.infinity); // 3 lines: 0, mid, max
}


  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: BelnetLib.isConnected ?
      
       LineChart(
        LineChartData(
          minY: 0,
          maxY: getDynamicMaxY(), //0.08,
           minX: xValue - maxPoints + 1,
           maxX: xValue,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 40,
    interval: getYInterval(),
    getTitlesWidget: (value, meta) {
      return Text(
        '${value.toStringAsFixed(2)}mb',
        style: TextStyle(color: Colors.white54, fontSize: 10),
      );
    },
  ),

            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (downloadSpots.isNotEmpty)
                    ? (downloadSpots.last.x / 2).ceilToDouble()
                    : 1,
                getTitlesWidget: (value, meta) {
                  if (value == downloadSpots.first.x) {
                    return Text(
                      'a minute ago',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    );
                  } else if (value == downloadSpots.last.x) {
                    return Text(
                      'Now',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    );
                  }
                  return Container();
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.02,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white24,
              strokeWidth: 0.5,
              dashArray: [5, 5],
            ),
          ),
          lineBarsData: [
            // Download line
            LineChartBarData(
              spots: downloadSpots,
              isCurved: true,
              color: Colors.greenAccent,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
            // Upload line
            LineChartBarData(
              spots: uploadSpots,
              isCurved: true,
              color: Colors.cyanAccent,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(enabled: false),
        ),
      ): LineChart(LineChartData()),
    );
  }
}


class ChartWidget extends StatefulWidget {
  const ChartWidget({super.key});

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {

 List<FlSpot> downloadSpots = [];
  List<FlSpot> uploadSpots = [];
  double xValue = 0;
  Timer? _timer;
  final int maxPoints = 20; // Limit to 20 points to keep chart readable




// List<SpeedData> downloadData = [];
// List<SpeedData> uploadData = [];
// int xValue = 0;
// final int maxPoints = 20;





  @override
  void initState() {
    super.initState();
    // Start simulating network speed every second

     _timer = Timer.periodic(Duration(seconds: 1), (_) async {
    try {
      final result = await BelnetLib.getSpeedStatus; // Ensure this returns a Map
      if (result != null && result['rxRate'] != null && result['txRate'] != null) {
        final int rxRate = result['rxRate']; // in bytes per second
        final int txRate = result['txRate']; // in bytes per second

        // Convert to Megabits per second (Mb/s) => bytes * 8 / 1,000,000
        final double downloadMbps = rxRate * 8 / 1000000;
        final double uploadMbps = txRate * 8 / 1000000;

        _addNewData(downloadSpeed: downloadMbps, uploadSpeed: uploadMbps);
      }
    } catch (e) {
      // Optional: log or show error
      debugPrint("Error fetching speed data: $e");
    }
  });
  }


// void _addNewData({required double downloadSpeed, required double uploadSpeed}) {
//     setState(() {
//       xValue += 1;
//       downloadData.add(SpeedData(xValue, downloadSpeed));
//       uploadData.add(SpeedData(xValue, uploadSpeed));

//       if (downloadData.length > maxPoints) downloadData.removeAt(0);
//       if (uploadData.length > maxPoints) uploadData.removeAt(0);
//     });
//   }

  void _addNewData({required double downloadSpeed, required double uploadSpeed}) {
    setState(() {
      xValue += 1;
      downloadSpots.add(FlSpot(xValue, downloadSpeed));
      uploadSpots.add(FlSpot(xValue, uploadSpeed));

      // Keep points within the maxPoints window
      if (downloadSpots.length > maxPoints) downloadSpots.removeAt(0);
      if (uploadSpots.length > maxPoints) uploadSpots.removeAt(0);
    });
  }

@override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return ChartData();
  }
}


///// Good but Static one

class NetworkSpeedChart extends StatelessWidget {
  

 final List<FlSpot> downloadSpots;
 final List<FlSpot> uploadSpots;

  const NetworkSpeedChart({
    Key? key,
    required this.downloadSpots,
    required this.uploadSpots,
    re
  }) : super(key: key);



  // Define the data points for the lines
  // final List<FlSpot> downloadSpots = [
  //   FlSpot(0, 0.02),
  //   FlSpot(1, 0.021),
  //   FlSpot(2, 0.022),
  //   FlSpot(3, 0.025),
  //   FlSpot(4, 0.027),
  //   FlSpot(5, 0.03),
  //   FlSpot(6, 0.035),
  //   FlSpot(7, 0.04),
  //   FlSpot(8, 0.045),
  //   FlSpot(9, 0.048),
  //   FlSpot(10, 0.05),
  // ];

  // final List<FlSpot> uploadSpots = [
  //   FlSpot(0, 0.02),
  //   FlSpot(1, 0.0205),
  //   FlSpot(2, 0.021),
  //   FlSpot(3, 0.022),
  //   FlSpot(4, 0.023),
  //   FlSpot(5, 0.025),
  //   FlSpot(6, 0.027),
  //   FlSpot(7, 0.028),
  //   FlSpot(8, 0.029),
  //   FlSpot(9, 0.0295),
  //   FlSpot(10, 0.03),
  // ];

  // Function to calculate the 3 y-axis points dynamically
  Map<String, double> calculateYAxisPoints() {
    // Combine all y-values from both lines
    final List<double> allYValues = [
      ...downloadSpots.map((spot) => spot.y),
      ...uploadSpots.map((spot) => spot.y),
    ];

    // Find min and max
    final double minY = allYValues.reduce((a, b) => a < b ? a : b);
    final double maxY = allYValues.reduce((a, b) => a > b ? a : b);
    // Calculate the middle point
    final double midY = (minY + maxY) / 2;

    return {
      'min': minY,
      'mid': midY,
      'max': maxY,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the y-axis points
    final yAxisPoints = calculateYAxisPoints();
    final double minY = yAxisPoints['min']!;
    final double midY = yAxisPoints['mid']!;
    final double maxY = yAxisPoints['max']!;

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  // Display only the 3 calculated points
                  if (value == minY) {
                    return Text(
                      '${value.toStringAsFixed(2)}Mb/s',
                      style: TextStyle(color: Colors.white, fontSize: 9),
                    );
                  } else if (value == midY) {
                    return Text(
                      '${value.toStringAsFixed(2)}Mb/s',
                      style: TextStyle(color: Colors.white, fontSize: 9),
                    );
                  } else if (value == maxY) {
                    return Text(
                      '${value.toStringAsFixed(2)}Mb/s',
                      style: TextStyle(color: Colors.white, fontSize: 9),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return Text('a minute ago',
                          style: TextStyle(color: Colors.white, fontSize: 12));
                    case 10:
                      return Text('now',
                          style: TextStyle(color: Colors.white, fontSize: 12));
                  }
                  return Text('');
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 10,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            // Download line (green)
            LineChartBarData(
              spots: downloadSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.3),
              ),
              dotData: FlDotData(show: false),
            ),
            // Upload line (blue)
            LineChartBarData(
              spots: uploadSpots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.3),
              ),
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartPage extends StatelessWidget {
  final List<SpeedData> downloadData;
  final List<SpeedData> uploadData;
  final int xValue;
  final int maxPoints;

  const ChartPage({
    Key? key,
    required this.downloadData,
    required this.uploadData,
    required this.xValue,
    required this.maxPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int minX = (xValue - maxPoints).clamp(0, xValue);
    int maxX = xValue;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: 
        SfCartesianChart(
  plotAreaBorderWidth: 0,
  margin: EdgeInsets.zero,
  primaryXAxis: NumericAxis(
    minimum: downloadData.isNotEmpty
        ? (downloadData.last.time - maxPoints + 1).toDouble()
        : 0,
    maximum: downloadData.isNotEmpty
        ? downloadData.last.time.toDouble()
        : maxPoints.toDouble(),
    majorGridLines: MajorGridLines(width: 0),
    edgeLabelPlacement: EdgeLabelPlacement.shift,
    labelFormat: '',
    axisLabelFormatter: (AxisLabelRenderDetails details) {
      final int lastX = downloadData.isNotEmpty ? downloadData.last.time : 0;
      if (details.value == (lastX - maxPoints + 1).toDouble()) {
        return ChartAxisLabel('Long ago', TextStyle(color: Colors.white70, fontSize: 10));
      } else if (details.value == lastX.toDouble()) {
        return ChartAxisLabel('Now', TextStyle(color: Colors.white70, fontSize: 10));
      }
      return ChartAxisLabel('', TextStyle());
    },
  ),
  primaryYAxis: NumericAxis(
    minimum: 0,
    maximum: 3, // Always show up to 3 Mbps
    interval: 1,
    axisLine: AxisLine(width: 0),
    majorTickLines: MajorTickLines(size: 0),
  ),
  series: <CartesianSeries>[
    LineSeries<SpeedData, int>(
      dataSource: downloadData,
      xValueMapper: (SpeedData data, _) => data.time,
      yValueMapper: (SpeedData data, _) => data.speed,
      name: 'Download',
      color: Color(0xff00DC00),
      width: 2,
    ),
    LineSeries<SpeedData, int>(
      dataSource: uploadData,
      xValueMapper: (SpeedData data, _) => data.time,
      yValueMapper: (SpeedData data, _) => data.speed,
      name: 'Upload',
      color: Color(0xff00A3FF),
      width: 2,
    ),
  ],
  legend: Legend(isVisible: false),
)
      ),
    );
  }
}
class SpeedData {
  final int time;
  final double speed;
  SpeedData(this.time, this.speed);
}


/// Good but static before chganges

// class NetworkSpeedChart extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//            Padding(
//         padding: const EdgeInsets.only(bottom: 8.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(radius: 3, backgroundColor: Color(0xff00DC00)),
//                 SizedBox(width: 5),
//                 Text('Download', style: TextStyle(color: Color(0xffACACAC),fontFamily: 'Poppins',fontSize: 9)),
//               ],
//             ),
//             SizedBox(width: 10),
//             Row(
//               children: [
//                 CircleAvatar(radius: 3, backgroundColor: Color(0xff00A3FF)),
//                 SizedBox(width: 5),
//                 Text('Upload', style: TextStyle(color: Color(0xffACACAC),fontFamily: 'Poppins',fontSize: 9)),
//               ],
//             ),
//           ],
//         ),
//       ),
//         Container(
//           height: 150,
//           padding: EdgeInsets.all(16),
//           // decoration: BoxDecoration(
//           //   color: Colors.black.withOpacity(0.5),
//           //   borderRadius: BorderRadius.circular(16),
        
//           // ),
//           child: LineChart(
//             // transformationConfig: FlTransformationConfig(

//             // ),
//             LineChartData(
//               minY: 0,
//               maxY: 0.08,
//               borderData: FlBorderData(
//                 border: Border(left: BorderSide(color: Color(0xffACACAC),width: 0.04),bottom: BorderSide(color: Color(0xffACACAC),width: 0.07))
//               ),
//               titlesData: FlTitlesData(
//                 leftTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     reservedSize: 40,
//                     getTitlesWidget: (value, meta) {
//                       return Text(
//                         '${value.toStringAsFixed(2)}mb',
//                         style: TextStyle(color: Colors.white54, fontSize: 10),
//                       );
//                     },
//                   ),
//                 ),
//                 bottomTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     interval: 1,
//                     getTitlesWidget: (value, meta) {
//                       if (value == 0) {
//                         return Text(
//                           'a minute ago',
//                           style: TextStyle(color: Colors.white54, fontSize: 10),
//                         );
//                       } else if (value == 10) {
//                         return Text(
//                           'Now',
//                           style: TextStyle(color: Colors.white54, fontSize: 10),
//                         );
//                       }
//                       return Container();
//                     },
//                   ),
//                 ),
//                 rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//               ),
//               gridData: FlGridData(
//                 show: true,
//                 drawVerticalLine: false,
//                 horizontalInterval: 0.02,
//                 getDrawingHorizontalLine: (value) => FlLine(
//                   color: Colors.white24,
//                   strokeWidth: 0.5,
//                   dashArray: [5, 5],
//                 ),
//               ),
//               lineBarsData: [
//                 // Download line
//                 LineChartBarData(
//                   spots: [
//                     // FlSpot(0, 0.005),
//                     // FlSpot(2, 0.015),
//                     // FlSpot(4, 0.02),
//                     // FlSpot(6, 0.045),
//                     // FlSpot(8, 0.035),
//                     // FlSpot(10, 0.065),
//                   ],
//                   isCurved: true,
//                   color: Color(0xff00DC00),
//                   barWidth: 2,
//                   dotData: FlDotData(show: false),
//                 ),
//                 // Upload line
//                 LineChartBarData(
//                   spots: [
//                     // FlSpot(0, 0.004),
//                     // FlSpot(2, 0.01),
//                     // FlSpot(4, 0.012),
//                     // FlSpot(6, 0.015),
//                     // FlSpot(8, 0.014),
//                     // FlSpot(10, 0.018),
//                   ],
//                   isCurved: true,
//                   color: Color(0xff00A3FF),
//                   barWidth: 2,
//                   dotData: FlDotData(show: false),
//                 ),
//               ],
//               lineTouchData: LineTouchData(enabled: false),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }