// import 'dart:async';
// import 'dart:math' as math;

// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';

// class LineChartSample10 extends StatefulWidget {
//   const LineChartSample10({Key? key}):super(key: key);

//   @override
//   State<LineChartSample10> createState() => _LineChartSample10State();
// }

// class _LineChartSample10State extends State<LineChartSample10> {
//   final Color sinColor = Colors.redAccent;
//   final Color cosColor = Colors.blueAccent;

//   final limitCount = 100;
//   final sinPoints = <FlSpot>[];
//   final cosPoints = <FlSpot>[];

//   double xValue = 0;
//   double step = 0.05;

//   late Timer timer;

//   @override
//   void initState() {
//     super.initState();
//     timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
//       while (sinPoints.length > limitCount) {
//         sinPoints.removeAt(0);
//         cosPoints.removeAt(0);
//       }
//       setState(() {
//         sinPoints.add(FlSpot(xValue, math.sin(xValue)));
//         cosPoints.add(FlSpot(xValue, math.cos(xValue)));
//       });
//       xValue += step;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return cosPoints.isNotEmpty
//         ? Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 'x: ${xValue.toStringAsFixed(1)}',
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 'sin: ${sinPoints.last.y.toStringAsFixed(1)}',
//                 style: TextStyle(
//                   color: sinColor,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 'cos: ${cosPoints.last.y.toStringAsFixed(1)}',
//                 style: TextStyle(
//                   color: cosColor,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(
//                 height: 12,
//               ),
//               SizedBox(
//                 width: 300,
//                 height: 300,
//                 child: LineChart(
//                   LineChartData(
//                     minY: -1,
//                     maxY: 1,
//                     minX: sinPoints.first.x,
//                     maxX: sinPoints.last.x,
//                     lineTouchData: LineTouchData(enabled: false),
//                     clipData: FlClipData.all(),
//                     gridData: FlGridData(
//                       show: true,
//                       drawVerticalLine: false,
//                     ),
//                     lineBarsData: [
//                       sinLine(sinPoints),
//                       cosLine(cosPoints),
//                     ],
//                     titlesData: FlTitlesData(
//                       show: false,
//                     ),
//                   ),
//                 ),
//               )
//             ],
//           )
//         : Container();
//   }

//   LineChartBarData sinLine(List<FlSpot> points) {
//     return LineChartBarData(
//       spots: points,
//       dotData: FlDotData(
//         show: false,
//       ),
//       gradient: LinearGradient(
//         colors: [sinColor.withOpacity(0), sinColor],
//         stops: const [0.1, 1.0],
//       ),
//       barWidth: 4,
//       isCurved: false,
//     );
//   }

//   LineChartBarData cosLine(List<FlSpot> points) {
//     return LineChartBarData(
//       spots: points,
//       dotData: FlDotData(
//         show: false,
//       ),
//       gradient: LinearGradient(
//         colors: [sinColor.withOpacity(0), sinColor],
//         stops: const [0.1, 1.0],
//       ),
//       barWidth: 4,
//       isCurved: false,
//     );
//   }

//   @override
//   void dispose() {
//     timer.cancel();
//     super.dispose();
//   }
// }
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LineChartSample2 extends StatefulWidget {
  const LineChartSample2({Key? key}):super(key: key);

  @override
  State<LineChartSample2> createState() => _LineChartSample2State();
}

class _LineChartSample2State extends State<LineChartSample2> {
  List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  bool showAvg = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1.70,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(18),
                ),
                color: Color(0xff232d37),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 18,
                  left: 12,
                  top: 24,
                  bottom: 12,
                ),
                child: LineChart(
                  showAvg ? avgData() : mainData(),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 60,
            height: 34,
            child: TextButton(
              onPressed: () {
                setState(() {
                  showAvg = !showAvg;
                });
              },
              child: Text(
                'avg',
                style: TextStyle(
                  fontSize: 12,
                  color: showAvg ? Colors.white.withOpacity(0.5) : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff68737d),
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    Widget text;
    switch (value.toInt()) {
      case 2:
        text = const Text('a minute ago', style: style);
        break;
      case 5:
        text = const Text('', style: style);
        break;
      case 8:
        text = const Text('now', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff67727d),
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );
    String text;
    switch (value.toInt()) {
      case 1:
        text = '1.0 mb';
        break;
      case 3:
        text = '30k';
        break;
      case 5:
        text = '50k';
        break;
      default:
        return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.left);
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 3),
            FlSpot(2.6, 2),
            FlSpot(4.9, 5),
            FlSpot(6.8, 3.1),
            FlSpot(8, 4),
            FlSpot(9.5, 3),
            FlSpot(11, 4),
          ],
          isCurved: true,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withOpacity(0.3))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  LineChartData avgData() {
    return LineChartData(
      lineTouchData: LineTouchData(enabled: false),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        verticalInterval: 1,
        horizontalInterval: 1,
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: bottomTitleWidgets,
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
            interval: 1,
          ),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 3.44),
            FlSpot(2.6, 3.44),
            FlSpot(4.9, 3.44),
            FlSpot(6.8, 3.44),
            FlSpot(8, 3.44),
            FlSpot(9.5, 3.44),
            FlSpot(11, 3.44),
          ],
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              ColorTween(begin: gradientColors[0], end: gradientColors[1])
                  .lerp(0.2)!,
              ColorTween(begin: gradientColors[0], end: gradientColors[1])
                  .lerp(0.2)!,
            ],
          ),
          barWidth: 1,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          // belowBarData: BarAreaData(
          //   show: true,
          //   gradient: LinearGradient(
          //     colors: [
          //       ColorTween(begin: gradientColors[0], end: gradientColors[1])
          //           .lerp(0.2)!
          //           .withOpacity(0.1),
          //       ColorTween(begin: gradientColors[0], end: gradientColors[1])
          //           .lerp(0.2)!
          //           .withOpacity(0.1),
          //     ],
          //   ),
          // ),
        ),
        LineChartBarData(
          spots: const [
            FlSpot(0, 3.44),
            FlSpot(2.6, 3.44),
            // FlSpot(4.9, 3.44),
            // FlSpot(6.8, 3.44),
            // FlSpot(8, 3.44),
            // FlSpot(9.5, 3.44),
            // FlSpot(11, 3.44),
          ],
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              ColorTween(begin: gradientColors[0], end: gradientColors[1])
                  .lerp(0.2)!,
              ColorTween(begin: gradientColors[0], end: gradientColors[1])
                  .lerp(0.2)!,
            ],
          ),
          barWidth: 1,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          // belowBarData: BarAreaData(
          //   show: true,
          //   gradient: LinearGradient(
          //     colors: [
          //       ColorTween(begin: gradientColors[0], end: gradientColors[1])
          //           .lerp(0.2)!
          //           .withOpacity(0.1),
          //       ColorTween(begin: gradientColors[0], end: gradientColors[1])
          //           .lerp(0.2)!
          //           .withOpacity(0.1),
          //     ],
          //   ),
          // ),
        ),
      ],
    );
  }
}