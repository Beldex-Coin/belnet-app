import 'dart:async';

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

List<SpeedValues> mySpeedData=[];

  @override
  void initState() {
    setIntervalToCall();
    super.initState();
  }

  setIntervalToCall()async{
    Timer.periodic(Duration(milliseconds: 1000), (timer) {
     getAndAssignData(timer);
    });
  }
  getAndAssignData(timer)async{
    if(mySpeedData.length < 10){
      //mySpeedData.add(SpeedValues(timer, appModel.singleDownload));
      setState(() {

      });
    }else{
      setState(() {
        for(int i=0;i<mySpeedData.length;i++){
          mySpeedData[i] = mySpeedData[1+i];

        }
      });

    }
  }


  @override
  Widget build(BuildContext context) {
    appModel = Provider.of<AppModel>(context);
    return Scaffold(
      body:Charts(data: [],)
    );
  }
}




class Charts extends StatelessWidget {
  final List<SpeedValues> data;
  const Charts({Key? key, required this.data}) : super(key: key);


  @override
  Widget build(BuildContext context) {

    return Container(
        child: charts.TimeSeriesChart(
            [
              charts.Series<SpeedValues, DateTime>(
                id: 'Values',
                colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
                domainFn: (SpeedValues values, _) => values.time,
                measureFn: (SpeedValues values, _) => values.speed,
                data: data,
              ),
              // charts.Series<SpeedValues, DateTime>(
              //   id: 'Values',
              //   colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
              //   domainFn: (SpeedValues values, _) => values.time,
              //   measureFn: (SpeedValues values, _) => values.speed,
              //   data: data,
              // )
            ]
        )
    );
  }
}






class SpeedValues{
   final DateTime time;
   final double speed;

  SpeedValues(this.time, this.speed);

}