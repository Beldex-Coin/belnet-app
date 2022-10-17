import 'dart:async';
import 'dart:math' as math;
import 'package:belnet_lib/belnet_lib.dart';
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

  convertUploadDownloadStringToInt() async {
    setTimers();
    if (BelnetLib.isConnected) {
      setState(() {});
      print("the value from provider ${appModel.uploads}");
      uploadData = stringBeforeSpace(appModel.uploads);
      downloadData = stringBeforeSpace(appModel.downloads);
       print('${appModel.downloads}');
      // print("upload value for chart $upload");
      // print("download value for chart $download");
      // print("upload data for chart $uploadData");
      // print("download data for chart $downloadData");
    } else {
      upload = null;
      download = null;
      downloadData = 0.0;
      uploadData = 0.0;
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
      LiveData(0.0, 0),
      LiveData(0.0, 0),
      LiveData(0.0, 0),
    ];
  }

  List<LiveData> chartata() {
    return <LiveData>[
      LiveData(0.0, 0),
      LiveData(0.0, 0),
      LiveData(0.0, 0),
      LiveData(0.0, 0),
      LiveData(0.0, 0),
      LiveData(0.0, 0),
      LiveData(0.0, 0),
      LiveData(0.0, 0),
      LiveData(0.0, 0),
    ];
  }

  @override
  void initState() {
    chartData = getChart();
    charts = chartata();
    setTimers();
    setState(() {});
    super.initState();
  }

  setTimers() {
    var ti;
    if (BelnetLib.isConnected) {
      ti = Timer.periodic(Duration(seconds: 1), (timer) {
        _updateData(timer);
        _updateDownload(timer);
      });
    } else {
    //ti.cancel();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  int time = 10;
  _updateData(Timer timer) {
    print("updating data forr all uploads $uploadData");
    chartData.add(LiveData(uploadData, time++));
    chartData.removeAt(0);
    _chartSeriesController.updateDataSource(
        addedDataIndex: chartData.length - 1, removedDataIndex: 0);
  }

  _updateDownload(Timer timer) {
    print("updating data forr all downloads $downloadData");
    charts.add(LiveData(downloadData, time++));
    charts.removeAt(0);
    _chartSeriesController.updateDataSource(
        addedDataIndex: charts.length - 1, removedDataIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    appModel = Provider.of<AppModel>(context);
    convertUploadDownloadStringToInt();

    return Container(
        child: BelnetLib.isConnected
            ? SfCartesianChart(
            // selectionType: SelectionType.series,
                // enableSideBySideSeriesPlacement: false,
                plotAreaBorderColor: Colors.transparent,
                plotAreaBackgroundColor: Colors.transparent,
                series: <SplineSeries<LiveData, int>>[
                    SplineSeries<LiveData, int>(
                        width: 0.8,
                        initialSelectedDataIndexes: [0, 0],
                        splineType: SplineType.clamped,
                        onRendererCreated: (ChartSeriesController controller) =>
                            _chartSeriesController = controller,
                        dataSource: chartData,
                        xValueMapper: (LiveData netw, _) => netw.time,
                        color: Color(0xff23DC27),
                        yValueMapper: (LiveData netw, _) => netw.speed),
                    SplineSeries<LiveData, int>(
                        width: 0.8,
                        initialSelectedDataIndexes: [0, 0],
                        splineType: SplineType.clamped,
                        onRendererCreated: (ChartSeriesController controller) =>
                            _chartSeriesController = controller,
                        dataSource: charts,
                        xValueMapper: (LiveData netw, _) => netw.time,
                        color: Color(0xff1CA3FC),
                        yValueMapper: (LiveData netw, _) => netw.speed),
                  ])
            : SfCartesianChart(
                plotAreaBorderColor: Colors.transparent,
                plotAreaBackgroundColor: Colors.transparent,
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
