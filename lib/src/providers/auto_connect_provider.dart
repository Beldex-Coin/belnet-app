import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoConnectProvider extends ChangeNotifier {
  bool _autoConnect = false;

  bool get autoConnect => _autoConnect;

  Future<void> loadAutoConnect() async {
    final prefs = await SharedPreferences.getInstance();
    _autoConnect = prefs.getBool("auto_connect") ?? false;
    notifyListeners();
  }

  Future<void> setAutoConnect(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("auto_connect", value);

    _autoConnect = value;
    notifyListeners();
  }
}