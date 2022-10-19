import 'dart:async';
import 'dart:math' as math;
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/widget/LineChartSample10.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';

import 'package:syncfusion_flutter_charts/charts.dart';

import '../model/theme_set_provider.dart';

class LiveChart extends StatefulWidget {
  String upData;
  String downData;
  LiveChart({Key? key, required this.upData, required this.downData})
      : super(key: key);

  @override
  State<LiveChart> createState() => _LiveChartState();
}

class _LiveChartState extends State<LiveChart> {
  late List<LiveData> chartData;
  late ChartSeriesController _chartSeriesController;

  late List<LiveData> charts;
  late AppModel appModel;
  var upload, download, uploadData = 0.0, downloadData = 0.0;
  int time = 10;
  convertUploadDownloadStringToInt() async {
    //setTimers();
    try {
      if (BelnetLib.isConnected) {
        setState(() {});
        print("the value from provider ${appModel.uploads}");
        uploadData = stringBeforeSpace(appModel.uploads);
        downloadData = stringBeforeSpace(appModel.downloads);
        print('${appModel.downloads}');

        _updateData();
        _updateDownload();
      } else {
        upload = null;
        download = null;
        downloadData = 0.0;
        uploadData = 0.0;
      }
    } catch (e) {
      print("$e");
    }
  }

  double stringBeforeSpace(String value) {
    String str = value;
    double valu;
    str = value.split(' ').first;
    // val = str as double;
    valu = double.parse(str);
    setState(() {});
    return valu;
  }

  List<LiveData> getChart() {
    return <LiveData>[
      LiveData(0.0, 0),
      LiveData(0.0, 0),
      LiveData(0.0, 1),
      LiveData(3, 12),
      LiveData(4, 12),
      LiveData(5, 12),
      // LiveData(0.0, 0),
      // LiveData(0.0, 0),
      // LiveData(0.0, 0),
    ];
  }

  List<LiveData> chartata() {
    return <LiveData>[
      LiveData(0.0, 0),
      LiveData(0.0, 0),
      LiveData(0.0, 0),
      LiveData(3, 12),
      LiveData(4, 12),
      LiveData(5, 12),
      // LiveData(0.0, 0),
      // LiveData(0.0, 0),
      // LiveData(0.0, 0),
    ];
  }

  @override
  void initState() {
    chartData = getChart();
    charts = chartata();
    // setTimers();
    setState(() {});
    super.initState();
  }

  // setTimers() {
  //   var ti;
  //   if (BelnetLib.isConnected) {
  //     ti = Timer.periodic(Duration(seconds: 1), (timer) {
  //       _updateData(timer);
  //       _updateDownload(timer);
  //     });
  //   } else {
  //   //ti.cancel();
  //   }
  // }

  @override
  void dispose() {
    super.dispose();
  }

  _updateData() {
    print("updating data forr all uploads $uploadData");
    chartData.add(LiveData(uploadData, time++));
    chartData.removeAt(0);
    _chartSeriesController.updateDataSource(
        addedDataIndex: chartData.length - 1, removedDataIndex: 0);
  }

  _updateDownload() {
    print("updating data forr all downloads $downloadData");
    charts.add(LiveData(downloadData, time++));
    charts.removeAt(0);
    _chartSeriesController.updateDataSource(
        addedDataIndex: charts.length - 1, removedDataIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    appModel = Provider.of<AppModel>(context);
    if (BelnetLib.isConnected) {
      convertUploadDownloadStringToInt();
    }

    return Container(
        margin: EdgeInsets.only(top: 20.0),
        padding: EdgeInsets.only(bottom: 20.0, left: 15.0),
        child: BelnetLib.isConnected
            ? Stack(
                children: [
                  Container(
                    // color: Colors.green,
                    padding: EdgeInsets.only(left: 37.0, right: 20.0),
                    // decoration: BoxDecoration(
                    //   border: Border(bottom: BorderSide(width: 1.0, color: Colors.lightBlue.shade600))
                    // ),
                    child: SfCartesianChart(
                        // axes:<ChartAxis>[

                        // ],
                        // enableAxisAnimation: true,
                        //zoomPanBehavior: ZoomPanBehavior(enablePinching: true),
                        primaryXAxis: NumericAxis(
                            //rangePadding: ChartRangePadding.,
                            labelFormat: " ",
                            // anchorRangeToVisiblePoints: false,
                            //associatedAxisName: "time",
                            majorGridLines:
                                MajorGridLines(color: Colors.transparent)),
                        primaryYAxis: NumericAxis(
                            labelFormat: " ",
                            majorGridLines: MajorGridLines(
                              color: Colors.transparent,
                            )),
                        // primaryYAxis: CategoryAxis(),
                        // primaryXAxis: NumericAxis(isVisible: false),
                        // primaryYAxis: NumericAxis(isVisible: false),
                        selectionType: SelectionType.series,
                        plotAreaBorderColor: Colors.transparent,
                        plotAreaBackgroundColor: Colors.transparent,
                        series: <LineSeries<LiveData, int>>[
                          LineSeries<LiveData, int>(
                              //xAxisName: "Download",
                              width: 0.8,
                              //initialSelectedDataIndexes: [0, 0],

                              //splineType: SplineType.clamped,
                              onRendererCreated:
                                  (ChartSeriesController controller) =>
                                      _chartSeriesController = controller,
                              dataSource: chartData,
                              xValueMapper: (LiveData netw, _) => netw.time,
                              color: Color(0xff23DC27),
                              yValueMapper: (LiveData netw, _) => netw.speed),
                          LineSeries<LiveData, int>(
                              width: 0.8,
                              // initialSelectedDataIndexes: [0, 0],
                              //splineType: SplineType.clamped,
                              onRendererCreated:
                                  (ChartSeriesController controller) =>
                                      _chartSeriesController = controller,
                              dataSource: charts,
                              xValueMapper: (LiveData netw, _) => netw.time,
                              color: Color(0xff1CA3FC),
                              yValueMapper: (LiveData netw, _) => netw.speed),
                        ]),
                  ),
                  Positioned(
                    bottom: 0.0, right: 5.0, left: 15.0,
                    top: MediaQuery.of(context).size.height * 0.50 / 3,
                    //width: double.infinity,
                    child: Container(
                      color: Colors.transparent,
                      height: MediaQuery.of(context).size.height * 0.50 / 3,
                      padding: EdgeInsets.only(left: 25.0),
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
                        // Row(
                        //   children: [
                        //     Text("a minute ago",style: TextStyle(fontSize: 0.5,color: Colors.white),),
                        //     Text("now",style: TextStyle(fontSize:0.5,color: Colors.white),)
                        //   ],
                        // )
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
                          // Text(
                          //   "0.5 mb",
                          //   style: TextStyle(
                          //     fontSize:
                          //         MediaQuery.of(context).size.height * 0.04 / 3,
                          //   ),
                          // )
                        ],
                      ),
                    ),
                  )
                ],
              )
            : Stack(
                children: [
                  Container(
                    // color: Colors.green,
                    padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.height *
                            0.18 /
                            3), //37.0),
                    // decoration: BoxDecoration(
                    //   border: Border(bottom: BorderSide(width: 1.0, color: Colors.lightBlue.shade600))
                    // ),
                    child: SfCartesianChart(
                        // axes:<ChartAxis>[

                        // ],
                        // enableAxisAnimation: true,

                        primaryXAxis: NumericAxis(
                            //rangePadding: ChartRangePadding.,
                            labelFormat: " ",
                            // anchorRangeToVisiblePoints: false,
                            //associatedAxisName: "time",
                            majorGridLines:
                                MajorGridLines(color: Colors.transparent)),
                        primaryYAxis: NumericAxis(
                            labelFormat: " ",
                            majorGridLines: MajorGridLines(
                              color: Colors.transparent,
                            )),
                        // primaryYAxis: CategoryAxis(),
                        // primaryXAxis: NumericAxis(isVisible: false),
                        // primaryYAxis: NumericAxis(isVisible: false),
                        selectionType: SelectionType.series,
                        //enableSideBySideSeriesPlacement: false,
                        plotAreaBorderColor: Colors.transparent,
                        plotAreaBackgroundColor: Colors.transparent,
                        series: <SplineSeries<LiveData, int>>[
                          // SplineSeries<LiveData, int>(
                          //     //xAxisName: "Download",
                          //     width: 0.8,
                          //     initialSelectedDataIndexes: [0, 0],

                          //     //splineType: SplineType.clamped,
                          //     onRendererCreated:
                          //         (ChartSeriesController controller) =>
                          //             _chartSeriesController = controller,
                          //     dataSource: chartData,
                          //     xValueMapper: (LiveData netw, _) => netw.time,
                          //     color: Color(0xff23DC27),
                          //     yValueMapper: (LiveData netw, _) => netw.speed),
                          // SplineSeries<LiveData, int>(
                          //     width: 0.8,
                          //     initialSelectedDataIndexes: [0, 0],
                          //     //splineType: SplineType.clamped,
                          //     onRendererCreated:
                          //         (ChartSeriesController controller) =>
                          //             _chartSeriesController = controller,
                          //     dataSource: charts,
                          //     xValueMapper: (LiveData netw, _) => netw.time,
                          //     color: Color(0xff1CA3FC),
                          //     yValueMapper: (LiveData netw, _) => netw.speed),
                        ]),
                  ),
                  Positioned(
                    bottom: 0.0, right: 5.0, left: 15.0,
                    top: MediaQuery.of(context).size.height * 0.50 / 3,
                    //width: double.infinity,
                    child: Container(
                      color: Colors.transparent,
                      height: MediaQuery.of(context).size.height * 0.50 / 3,
                      padding: EdgeInsets.only(left: 25.0),
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
                                    color: Color(0xff56566F),
                                    fontSize:
                                        MediaQuery.of(context).size.height *
                                            0.04 /
                                            3),
                              ),
                            ),
                            Text(
                              "now",
                              style: TextStyle(
                                  color: Color(0xff56566F),
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
                                    color: Color(0xff56566F)),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                LineChartSample2()));
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
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0),
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
                            ])
                        // Row(
                        //   children: [
                        //     Text("a minute ago",style: TextStyle(fontSize: 0.5,color: Colors.white),),
                        //     Text("now",style: TextStyle(fontSize:0.5,color: Colors.white),)
                        //   ],
                        // )
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
                              color: Color(0xff56566F),
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.04 / 3,
                            ),
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.08 / 3,
                          ),
                          Text(
                            "4.0 mb",
                            style: TextStyle(
                              color: Color(0xff56566F),
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.04 / 3,
                            ),
                          ),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.10 / 3,
                          ),
                          Text("2.0 mb",
                              style: TextStyle(
                                color: Color(0xff56566F),
                                fontSize: MediaQuery.of(context).size.height *
                                    0.04 /
                                    3,
                              )),
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.10 / 3,
                          ),
                          // Text(
                          //   "0.5 mb",
                          //   style: TextStyle(
                          //     color: Color(0xff56566F),
                          //     fontSize:
                          //         MediaQuery.of(context).size.height * 0.04 / 3,
                          //   ),
                          // )
                        ],
                      ),
                    ),
                  )
                ],
              ));
  }
}

class LiveData {
  final int time;
  final double speed;

  LiveData(
    this.speed,
    this.time,
  );
}
