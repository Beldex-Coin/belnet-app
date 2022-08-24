import 'package:flutter/material.dart';

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