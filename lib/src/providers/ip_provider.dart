import 'dart:async';
import 'dart:convert';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class IpProvider with ChangeNotifier {
  String _realIp = '000.000.000.00';
  String _currentIPv4 = '000.000.000.00';
  String _currentIPv6 = '000.000.000.00';

  static const _realIpKey = 'stored_real_ip';

 static const _customCountryKey = 'stored_custom_country';
static const _customCountryCodeKey = 'stored_custom_country_code';


String? _customNodeCountry;
String? _customCountryCode;
String? get customCountryCode => _customCountryCode;

 String? get customNodeCountry => _customNodeCountry;



  String get realIp => _realIp;
  String get currentIPv4 => _currentIPv4;
  String get currentIPv6 => _currentIPv6;

  Timer? _timer;

  IpProvider() {
    //fetchIp();
    _loadStoredRealIp();
    fetchInitialIP();
    startMonitoring();
   _loadStoredCustomNode();
  }

 void resetIPS(){
  _currentIPv4 = '000.000.000.00';
  _currentIPv6 = '000.000.000.00';
  notifyListeners();
 }




 resetCustomValue()async{
      final prefs = await SharedPreferences.getInstance();
  _customCountryCode = null;
  _customNodeCountry = null;
   await prefs.setString(_customCountryKey, '');
   await prefs.setString(_customCountryCodeKey, '');
  notifyListeners();
 }





 /// Load stored IP from SharedPreferences
  Future<void> _loadStoredRealIp() async {
    final prefs = await SharedPreferences.getInstance();
    _realIp = prefs.getString(_realIpKey) ?? 'Fetching...';
    notifyListeners();
  }

  Future<void> fetchInitialIP() async {
    try {
      final isConnected = await BelnetLib.isRunning;
      if(isConnected){

      }else{
        final response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        _realIp = response.body;
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_realIpKey, _realIp);
      } 
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
         checkCustomNodeCountry();


    }else{
      _currentIPv4 = '000.000.000.00';
    }

   }
    final response = await http.get(Uri.parse('https://api64.ipify.org?format=json'));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    //return data['ip'];
    
    
    if(_currentIPv4 != '000.000.000.00'){
      _currentIPv6 =  isIPv6(data['ip']) ? data['ip'] : ipv4ToIpv6(data['ip']);
    }else{
      _currentIPv6 = '000.000.000.00';
    }
     }
  //  final ipv6Res = await http.get(Uri.parse('https://api.ip.sb/geoip'));
  //  if(ipv6Res.statusCode == 200){
  //   _currentIPv6 = jsonDecode(ipv6Res.body)['ip'];
  //   print('THE STREAM CURRENT IP $_currentIPv6');
  //  }

   notifyListeners();
  }catch(_){
    //convertToIPv6(_currentIPv4);
    print('NOT LOADING IPs-------->');
  }
}




Future<void> checkCustomNodeCountry()async{
  // if(_currentIPv4.isNotEmpty){
  //    final getIpDetails = await http.get(Uri.parse('http://ip-api.com/json/$_currentIPv4'));
  //    if(getIpDetails.re)
  // }


  try {
   if(_currentIPv4.isNotEmpty){
    //  final response = await http.get(Uri.parse('http://ip-api.com/json/$_currentIPv4'));
    final response = await http.get(Uri.parse('https://ipwho.is/$_currentIPv4'));



if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
        _customNodeCountry = data['country'];
        _customCountryCode = data['country_code'];
          final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_customCountryKey, _customNodeCountry!);
               await prefs.setString(_customCountryCodeKey, _customCountryCode!);
    print('Custom exitnode country name is $_customNodeCountry $customCountryCode');

    } else {
      print('API Error: ${data['message']}');
    }
  } else {
    print('Failed to fetch IP info: ${response.statusCode}');
  }
    // if (response.statusCode == 200) {
    //   final data = json.decode(response.body);
    //   if (data['status'] == 'success') {
    //     _customNodeCountry = data['country'];
    //     _customCountryCode = data['country_code'];
    //     print('Custom exitnode country name is $_customNodeCountry $customCountryCode');
    //     //return data['country']; // e.g., "India"
    //   } else {
    //     print("Error: ${data['message']}");
    //   }
    // } else {
    //   print("HTTP error: ${response.statusCode}");
    // }
   }
  notifyListeners();
   
  } catch (e) {
    print("Exception: $e");
  }

}

Future<void> _saveCustomNodeValues() async {
  final prefs = await SharedPreferences.getInstance();
  if (_customNodeCountry != null) {
    await prefs.setString(_customCountryKey, _customNodeCountry!);
  } else {
    await prefs.remove(_customCountryKey);
  }

  if (_customCountryCode != null) {
    await prefs.setString(_customCountryCodeKey, _customCountryCode!);
  } else {
    await prefs.remove(_customCountryCodeKey);
  }
}


Future<void> _loadStoredCustomNode() async {
  final prefs = await SharedPreferences.getInstance();
  _customNodeCountry = prefs.getString(_customCountryKey);
  _customCountryCode = prefs.getString(_customCountryCodeKey);
  notifyListeners();
}






String ipv4ToIpv6(String ipv4) {
  final parts = ipv4.split('.');
  if (parts.length != 4) {
    throw FormatException('Invalid IPv4 address');
  }

  final nums = parts.map(int.parse).toList();
  if (nums.any((n) => n < 0 || n > 255)) {
    throw FormatException('Invalid IPv4 octet');
  }

  // Combine to get two 16-bit groups
  final firstGroup = ((nums[0] << 8) | nums[1]).toRadixString(16).padLeft(4, '0');
  final secondGroup = ((nums[2] << 8) | nums[3]).toRadixString(16).padLeft(4, '0');

  return '::ffff:$firstGroup:$secondGroup';
}

// String convertToIPv6(String ipv4) {
//     // Validate IPv4 address format
//     final regex = RegExp(r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
//     if (!regex.hasMatch(ipv4)) {
//       return ''; //'Invalid IPv4 address';
//     }
//     // Convert to IPv4-mapped IPv6 address by prepending ::ffff:
//     return '::ffff:$ipv4';
//   }



bool isIPv6(String ip) {
    // Check if the IP contains colons and no periods (basic IPv6 check)
    final regex = RegExp(r'^[0-9a-fA-F:]+$');
    return regex.hasMatch(ip) && ip.contains(':') && !ip.contains('.');
  }

void stopIPMonitoring(){
  _timer?.cancel();
  resetIPS();

}


void startMonitoring()async{
 final isConnect = await BelnetLib.isRunning;
 if(isConnect){
    _timer = Timer.periodic(Duration(seconds: 5), (_)=> fetchNewIPs());

 }
}




@override
void dispose(){
  _timer?.cancel();
  super.dispose();
}



}


