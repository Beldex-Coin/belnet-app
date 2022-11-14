import 'package:belnet_lib/belnet_lib.dart';
import 'package:charts_painter/chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../model/theme_set_provider.dart';
import 'containChart.dart';

class ContainChart extends StatefulWidget {
  const ContainChart({Key? key}) : super(key: key);

  @override
  State<ContainChart> createState() => _ContainChartState();
}

class _ContainChartState extends State<ContainChart> {

late AppModel appModel;
List dataforUp =[];
List dataforDown =[];
var time = 0, tim = 0;
late List<LiveData> charts;
late List<LiveData> chartData;
var uploadData,downloadData;
 late ChartSeriesController _chartSeriesController;
convertUploadDownloadStringToInt() async {
    //setTimers();
    try {
      if (BelnetLib.isConnected) {
        setState(() {});
        print("the value from provider ${appModel.uploads}");
        uploadData = stringBeforeSpace(appModel.singleUpload);
        downloadData = stringBeforeSpace(appModel.singleDownload);
        print('${appModel.downloads}');
        if(dataforUp.length < 10){
            dataforUp.add(uploadData);
            tim = time++;
            setState(() {
              
            });
        }else{
          callShiftForUps();
        }
       if(dataforDown.length <10){
           dataforDown.add(downloadData);
           setState(() {
             
           });
       }else{
        callShiftForDowns();
       }
       
        _updateData();
        _updateDownload();
      } else {
        
        downloadData = 0.0;
        uploadData = 0.0;
      }
    } catch (e) {
      print("$e");
    }
  }







callShiftForUps(){
  setState(() {
    for(var i=0;i< dataforUp.length;i++){
      dataforUp[i] = dataforUp[1 + i];
    }
  });
    
}


callShiftForDowns(){
  setState(() {
     for(var i=0;i< dataforDown.length;i++){
      dataforDown[i] = dataforDown[1 + i];
    }
  });
   
}


@override
  void initState() {
      chartData = getChart();
    charts = chartata();
    setState(() {
      
    });
    super.initState();
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




 _updateData() {
    print("updating data forr all uploads $uploadData");
    
    setState(() {
      
    });
    chartData.add(LiveData(dataforUp[tim], time++));
    chartData.removeAt(0);
    _chartSeriesController.updateDataSource(
        addedDataIndex: chartData.length - 1, removedDataIndex: 0);
  }

  _updateDownload() {
    print("updating data forr all downloads $downloadData");
    //tim = time++;
    charts.add(LiveData(dataforDown[tim], time++));
    setState(() {
      
    });
    charts.removeAt(0);
    _chartSeriesController.updateDataSource(
        addedDataIndex: charts.length - 1, removedDataIndex: 0);
  }







 List<LiveData> getChart() {
    return <LiveData>[
      LiveData(0, 1),
      LiveData(0,1),
      LiveData(3, 3),
      LiveData(0,1),
      LiveData(3, 3),
      LiveData(0,1),
      LiveData(3, 3),
      LiveData(0,1),
      LiveData(3, 3),
      LiveData(0,1),
      LiveData(3, 3),
        LiveData(0, 1),
      LiveData(0,1),
      LiveData(3, 3),
      LiveData(0,1),
      LiveData(3, 3),
      LiveData(0,1),
      LiveData(3, 3),
      LiveData(0,1),
      LiveData(3, 3),
      LiveData(0,1),
      LiveData(3, 3)

    ];
  }

  List<LiveData> chartata() {
    return <LiveData>[
      LiveData(0, 1),
        LiveData(0, 1),
      LiveData(0,1),
      LiveData(3, 3),
        LiveData(0, 1),
      LiveData(0,1),
      LiveData(3, 3),
      LiveData(0,1),
      LiveData(3, 3),
      LiveData(0,1),
      LiveData(3, 3),
      LiveData(0,1),
      LiveData(3, 3),
      LiveData(0,1),
      LiveData(3, 3),
        LiveData(0, 1),
      LiveData(0,1),
      LiveData(3, 3),
      LiveData(0,1),
      LiveData(3, 3),
      LiveData(0,1),
      LiveData(3, 3)
      // LiveData(0, 0),
      // LiveData(0, 0),
    ];
  }









  @override
  Widget build(BuildContext context) {
    appModel = Provider.of<AppModel>(context);
     if (BelnetLib.isConnected) {
      convertUploadDownloadStringToInt();
    }
    return Scaffold(
      body: Container(
//        child: 




        ///Chart(state: ChartState.line( 
        ///  ChartData.fromList(
        ///    [2,3,4,5],
        ///  ),
        ///) 
        ///)
        
      ),
    );
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