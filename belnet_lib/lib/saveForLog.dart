


import 'package:get/get.dart';

class SaveForLog extends GetxController{
  List data = ["Connect to belnet","checking for connection..","click start button to start belnet"].obs;
  static String getLogDetails(String data) {
    var myStrig = data;
    print("from belnetlog details side $myStrig");

    return myStrig;
  }



}