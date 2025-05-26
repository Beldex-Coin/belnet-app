import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class IpProvider with ChangeNotifier {
  String _realIp = 'Fetching...';
  String _currentIPv4 = 'Fetching...';
  String _currentIPv6 = 'Fetching...';





  String get realIp => _realIp;
  String get currentIPv4 => _currentIPv4;
  String get currentIPv6 => _currentIPv6;

  Timer? _timer;

  IpProvider() {
    //fetchIp();
    fetchInitialIP();
    startMonitoring();

  }

 void resetIPS(){
  _currentIPv4 = 'Fetching...';
  _currentIPv6 = 'Fetching...';
  notifyListeners();
 }




  Future<void> fetchInitialIP() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        _realIp = response.body;
      } else {
        //_realIp = 'Error: ${response.statusCode}';
      }
    } catch (e) {
      //_realIp = 'Error: $e';
    }
    notifyListeners();
  }

// Fetch IP

  Future<void> fetchNewIPs()async{
  try{
   final ipv4Res = await http.get(Uri.parse('https://api.ipify.org' //'https://api.ipfy.org?format=json'
   ));
   if(ipv4Res.statusCode == 200){
    if(ipv4Res.body != _realIp){
         _currentIPv4 = ipv4Res.body; //jsonDecode(ipv4Res.body)['ip'];

    }else{
      _currentIPv4 = 'Fetching...';
    }

   }

   final ipv6Res = await http.get(Uri.parse('https://api.ip.sb/geoip'));
   if(ipv6Res.statusCode == 200){
    _currentIPv6 = jsonDecode(ipv6Res.body)['ip'];
    print('THE STREAM CURRENT IP $_currentIPv6');
   }

   notifyListeners();
  }catch(_){
    print('NOT LOADING IPs-------->');
  }
}


void stopIPMonitoring(){
  _timer?.cancel();

}


void startMonitoring(){
  _timer = Timer.periodic(Duration(seconds: 5), (_)=> fetchNewIPs());
}




@override
void dispose(){
  _timer?.cancel();
  super.dispose();
}



}


