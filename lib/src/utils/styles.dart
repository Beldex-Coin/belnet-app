import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
//import 'package:flutter/material.dart';

/// Status bar for each theme: transparent, with dark icons on the light
/// theme and light icons on the dark theme.
///
/// The app bars are transparent, and Flutter picks the status bar icon
/// colour from the app bar's background colour; transparent counts as
/// "dark", so the light theme got white icons on a light page (unreadable
/// time, Wi-Fi, network, VPN key). Setting it explicitly fixes every screen.
const SystemUiOverlayStyle lightStatusBar = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark, // Android
  statusBarBrightness: Brightness.light, // iOS
);
const SystemUiOverlayStyle darkStatusBar = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
);

ThemeData buildLightTheme() {
  final ThemeData base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    cardColor: Colors.white,
    colorScheme: base.colorScheme.copyWith(
      background: const Color(0xffF9F9F9), // Replaces backgroundColor
      primary: Color(0xff00DC00),
    ),
    textTheme: base.textTheme.copyWith(
      headlineMedium: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w900,
        fontFamily: 'Poppins',
      ), // Replaces headline6
    ),
    scaffoldBackgroundColor: const Color(0xffF9F9F9),
    // Material 3 tints an AppBar with the primary colour (blue in the dark
    // theme) when content scrolls under it. The app bars here are
    // transparent over the background, so keep them unchanged on scroll.
    appBarTheme: base.appBarTheme.copyWith(
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: lightStatusBar,
    ),
  );
}

ThemeData buildDarkTheme() {
  final ThemeData base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    cardColor: Colors.grey[800],
    colorScheme: base.colorScheme.copyWith(
      background: const Color(0xff242430), // Replaces backgroundColor
      primary: Color(0xff007BFF),
    ),
    textTheme: base.textTheme.copyWith(
      headlineMedium: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontFamily: 'Poppins',
      ), // Replaces headline6
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    // Material 3 tints an AppBar with the primary colour (blue in the dark
    // theme) when content scrolls under it. The app bars here are
    // transparent over the background, so keep them unchanged on scroll.
    appBarTheme: base.appBarTheme.copyWith(
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: darkStatusBar,
    ),
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