import 'package:shared_preferences/shared_preferences.dart';

class AppPreference {

  static const THEME_SETTING = "THEMESETTING";
  static const CONNECTING_BELNET = "CONNECTBELNET";

  setThemePref(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(THEME_SETTING, value);
  }

  Future<bool> getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(THEME_SETTING) ?? false;
  }

  setConnectingBelnet(bool value)async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(CONNECTING_BELNET, value);
  }

  Future<bool> getConnectingBelnet()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(CONNECTING_BELNET) ?? false;
  }


}