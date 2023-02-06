import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
ThemeData buildLightTheme() {
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    cardColor: Colors.white,
    backgroundColor: Color(0xffF9F9F9),
    primaryColor: Colors.red,
    textTheme: TextTheme(headline6: TextStyle(color:Colors.black,fontWeight: FontWeight.w900,
      fontFamily: 'Poppins',)),
    scaffoldBackgroundColor: Color(0xffF9F9F9),
  );
}

ThemeData buildDarkTheme() {
  final ThemeData base = ThemeData.dark();
  return base.copyWith(
    cardColor: Colors.grey[800],
    backgroundColor: Color(0xff242430),
    primaryColor: Colors.blue[900],
    textTheme: TextTheme(headline6: TextStyle(color:Colors.white,fontWeight: FontWeight.w900,
      fontFamily: 'Poppins',)),
    scaffoldBackgroundColor: Colors.grey[900],
  );
}


class ConvertTimeToHMS{

  String displayHour_minute_seconds(DateTime DateTim){
    var dateTime = DateTime.parse(DateTim.toString());
    var date = DateFormat('hh:mm:ss').format(dateTime);

    return date;
  }
}

class SpeedMapData{
  List<double> sampleUpData = [
  26.6,
  26.6,
  16.2,
  16.2,
  2.0,
  2.0,
  6.0,
  6.0,
  2.0,
  2.0,
  2.0,
  2.0,
  9.8,
  9.8,
  2.0,
  2.0,
  2.0,
  2.0,
  9.8,
  9.8,
  25.1,
  25.1,
  19.5,
  19.5,
  5.0,
  5.0,
  2.0,
  2.0,
  5.0,
  5.0,
  2.0,
  2.0,
  13.7,
  13.7,
  6.0,
  6.0,
  6.0,
  6.0,
  5.0,
  5.0,
  15.4,
  15.4,
  2.0,
  2.0,
  6.0,
  6.0,
  2.0,
  2.0,
  2.0,
  2.0,
  2.0,
  2.0,
  16.1,
  16.1,
  2.0,
  2.0,
  5.0,
  5.0,
  5.0,
  5.0
];
List<double> sampleDownData = [
  5.0,
  2.0,
  2.0,
  2.0,
  2.0,
  5.0,
  5.0,
  15.6,
  15.6,
  22.1,
  22.1,
  2.0,
  2.0,
  2.0,
  2.0,
  2.0,
  2.0,
  2.0,
  2.0,
  2.0,
  2.0,
  5.0,
  5.0,
  2.0,
  2.0,
  12.1,
  12.1,
  15.7,
  15.7,
  10.1,
  10.1,
  2.0,
  2.0,
  2.0,
  2.0,
  6.0,
  6.0,
  2.0,
  2.0,
  6.0,
  6.0,
  2.0,
  2.0,
  6.0,
  6.0,
  6.0,
  6.0,
  5.0,
  5.0,
  10.5,
  10.5,
  6.0,
  6.0,
  5.0,
  5.0,
  5.0,
  5.0,
  2.0,
  2.0,
  5.0
];
}