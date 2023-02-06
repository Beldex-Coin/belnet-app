
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/styles.dart';


class LogController extends GetxController{

List data = [" Connect to belnet",
             " Checking for connection..",
             " Click start button to start belnet"].obs;

List timeData = ["${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
   "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
   "${ConvertTimeToHMS().displayHour_minute_seconds(DateTime.now()).toString()}",
].obs;
addDataTolist(String dats, String time){
  data.add(dats);
  timeData.add(time);
//data.obs;
}


// getData()async{
//   SharedPreferences prefs= await SharedPreferences.getInstance();
// }





}

