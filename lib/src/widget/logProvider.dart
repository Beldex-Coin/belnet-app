
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class LogController extends GetxController{

List data = [" Connect to belnet",
             " Checking for connection..",
             " Click start button to start belnet"].obs;

List timeData = [
   "${DateTime.now().microsecondsSinceEpoch.toString()}",
   "${DateTime.now().microsecondsSinceEpoch.toString()}",
   "${DateTime.now().microsecondsSinceEpoch.toString()}",
].obs;
addDataTolist(String dats, String time){
  data.add(dats);
  timeData.add(time);
//data.obs;
}

}

