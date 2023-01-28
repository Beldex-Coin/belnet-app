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



  




 
}