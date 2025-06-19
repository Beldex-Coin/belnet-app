import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/vpn_controller.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LoaderVideoProvider with ChangeNotifier {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
 
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  ConnectionStatus _conStatus = ConnectionStatus.DISCONNECTED;
  ConnectionStatus get conStatus => _conStatus;

 bool _belnetIsConnect = false;
 bool get belnetIsConnect => _belnetIsConnect;

 void setbelnetIsConnected(bool value){
  _belnetIsConnect = value;
  notifyListeners();
 }



  void setConnectionStatus(ConnectionStatus value ){
    _conStatus = value;
    notifyListeners();
  }


  // void setLoading(bool value){
  //   _isLoading = value;
  //   notifyListeners();
  // }
  void setLoading(bool value) {
  _isLoading = value;

  if (_isInitialized) {
    if (value) {
      _controller.seekTo(Duration.zero);
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  notifyListeners();
}


  bool get isInitialized => _isInitialized;
  VideoPlayerController get controller => _controller;

  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }


  Future<void> initialize(String assetPath) async {
    _controller = VideoPlayerController.asset(assetPath);
    await _controller.initialize();
    _controller.setLooping(true);
   // await _controller.play();
    _isInitialized = true;
    notifyListeners();
  }

  void showLoader() async{
    if (_isInitialized && !_controller.value.isPlaying) {
     await _controller.play();
      notifyListeners();
    }
  }

  void hideLoader() async{
    if (_isInitialized && _controller.value.isPlaying) {
     await _controller.pause();
      notifyListeners();
    }
  }
}