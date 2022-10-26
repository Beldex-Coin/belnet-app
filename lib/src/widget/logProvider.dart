
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class LogController extends GetxController{

List data = ["Connect to belnet"].obs;

addDataTolist(String dats){
  data.add(dats);
//data.obs;
}

}

