import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroStateProvider with ChangeNotifier {
  bool _showButton = false;

  bool _isFirstResume = false;
  bool get isFirstResume => _isFirstResume;

  bool get showButton => _showButton;

 bool _myExit = false;
bool _flagValue = false;

bool get myExit => _myExit;

bool get flagvalue => _flagValue;

setMyExitValue(bool value){
  _myExit = value;
  notifyListeners();
}

setFlagvalue(bool value){
  _flagValue = value;
  notifyListeners();
}
 

  IntroStateProvider() {
    _loadInitialState();
    _loadInitialResume();
  }

  Future<void> _loadInitialState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _showButton = prefs.getBool('showButton') ?? false;
    notifyListeners();
  }

  Future<void> showButtonAfterOk() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _showButton = true;
    await prefs.setBool('showButton', true);
    notifyListeners();
  }

  //Fitst app resume on higher version


  Future<void> _loadInitialResume() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isFirstResume = prefs.getBool('isFirstResume') ?? false;
    notifyListeners();
  }

  Future<void> setValueAfterResume() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isFirstResume = true;
    await prefs.setBool('isFirstResume', true);
    notifyListeners();
  }
}
