import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroStateProvider with ChangeNotifier {

  static const _isCustomExitNodeKey = 'stored_is_custom_node';

  bool _showButton = false;

  bool _isFirstResume = false;
  bool get isFirstResume => _isFirstResume;

  bool get showButton => _showButton;

 bool _myExit = false;
bool _flagValue = false;

bool get myExit => _myExit;

bool get flagvalue => _flagValue;

int _grantPermissionCount = 1;

int get grantPermissionCount => _grantPermissionCount;

setGrantPermissionCount(int value){
  _grantPermissionCount = value;
  notifyListeners();
}

increaseGrantPermissionCountByOne(){
  _grantPermissionCount++;
  notifyListeners();

}


// For checking Added node is Custom exitnode
bool _isCustomNode = false;

bool get isCustomNode => _isCustomNode;

setIsCustomNode(bool value)async{
     final prefs = await SharedPreferences.getInstance();
  _isCustomNode = value;
  await prefs.setBool(_isCustomExitNodeKey,value);
  notifyListeners();
}
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
    _loadStoredIsCustomNode();
  }


Future<void> _loadStoredIsCustomNode() async {
  final prefs = await SharedPreferences.getInstance();
  _isCustomNode = prefs.getBool(_isCustomExitNodeKey) ?? false;
  notifyListeners();
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
