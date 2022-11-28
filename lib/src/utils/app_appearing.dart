import 'package:shared_preferences/shared_preferences.dart';

class AppPreference {

  static const THEME_SETTING = "THEMESETTING";
  static const CONNECTING_BELNET = "CONNECTBELNET";
  static const STATUS_BEL = "STATUSBEL";


  setThemePref(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(THEME_SETTING, value);
  }

  Future<bool> getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(THEME_SETTING) ?? true;  //false
  }
// for background image changes into animated file
  setConnectingBelnet(bool value)async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(CONNECTING_BELNET, value);
  }

  Future<bool> getConnectingBelnet()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(CONNECTING_BELNET) ?? false;
  }

// for button loading
 setStatusBelnet(bool value)async{
    SharedPreferences prefs= await SharedPreferences.getInstance();
    prefs.setBool(STATUS_BEL, value);
  }
  Future<bool> getStatusBel()async{
    SharedPreferences prefs= await SharedPreferences.getInstance();
    return prefs.getBool(STATUS_BEL) ?? false;

  }



  




 String value = "[26.6, 26.6, 16.2, 16.2, 2.0, 2.0, 6.0, 6.0, 2.0, 2.0, 2.0, 2.0, 9.8, 9.8, 2.0, 2.0, 2.0, 2.0, 9.8, 9.8, 25.1, 25.1, 19.5, 19.5, 5.0, 5.0, 2.0, 2.0, 5.0, 5.0, 2.0, 2.0, 13.7, 13.7, 6.0, 6.0, 6.0, 6.0, 5.0, 5.0, 15.4, 15.4, 2.0, 2.0, 6.0, 6.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 16.1, 16.1, 2.0, 2.0, 5.0, 5.0, 5.0, 5.0]";
}