import 'dart:async';
import 'dart:convert';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/map/geo_location.dart';
import 'package:belnet_mobile/src/map/ip_geolocation_service.dart';
import 'package:belnet_mobile/src/widget/random_nearest_node_selection.dart';
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



  static const _originalLocationKey = 'stored_original_location';

  /// Approximate location of the user's REAL public IP. Detected while the
  /// tunnel is down and persisted, so it is never replaced by the exit's
  /// location after connecting.
  GeoLocation? _originalLocation;
  GeoLocation? get originalLocation => _originalLocation;

  bool _originalLocationLoading = false;
  bool get originalLocationLoading => _originalLocationLoading;

  /// True when the last attempt to detect the original location failed
  /// (offline, rate-limited, ...). Cleared by the next successful lookup.
  bool _originalLocationFailed = false;
  bool get originalLocationFailed => _originalLocationFailed;

  /// IP-geolocation of the current exit IP (only while connected).
  GeoLocation? _exitLocation;
  GeoLocation? get exitLocation => _exitLocation;

  /// Exit IP whose geolocation is already known / being fetched, so the
  /// 60-second IP refresh does not re-geolocate an unchanged address.
  String? _exitLookupIp;

  /// True when [ip] is a real address rather than one of this provider's
  /// placeholder values.
  static bool isKnownIp(String? ip) =>
      ip != null &&
      ip.isNotEmpty &&
      ip != '000.000.000.00' &&
      ip != 'Fetching...' &&
      (ip.contains('.') || ip.contains(':'));

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
  _exitLocation = null;
  _exitLookupIp = null;
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
    // Don't clobber a value fetchInitialIP() already obtained.
    if (!isKnownIp(_realIp)) {
      _realIp = prefs.getString(_realIpKey) ?? 'Fetching...';
    }
    if (_originalLocation == null) {
      final stored = prefs.getString(_originalLocationKey);
      if (stored != null && stored.isNotEmpty) {
        try {
          _originalLocation = GeoLocation.fromJson(jsonDecode(stored));
        } catch (_) {
          _originalLocation = null;
        }
      }
    }
    notifyListeners();
  }

  Future<void> fetchInitialIP() async {
    try {
      final isConnected = await BelnetLib.isRunning;
      if(isConnected){
        // The tunnel is up: any lookup now would return the EXIT's address.
        // Keep the persisted original IP/location untouched.
      }else{
        await _detectOriginalLocation();
        if (!isKnownIp(_realIp) || _originalLocation?.ip == null) {
          // Geolocation unavailable: still try the plain IP endpoint so
          // the real IP is known for exit-IP comparisons.
          final response = await http
              .get(Uri.parse('https://api.ipify.org'))
              .timeout(_fetchTimeout);
          if (response.statusCode == 200 && isKnownIp(response.body.trim())) {
            _realIp = response.body.trim();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_realIpKey, _realIp);
          }
        }
      }
      
    } catch (e) {
      //_realIp = 'Error: $e';
    }
    notifyListeners();
  }

  /// Detects the original (pre-VPN) public IP location if it is missing,
  /// e.g. after the first launch happened offline. No-op while the tunnel
  /// is running or a lookup is already in flight.
  Future<void> ensureOriginalLocation() async {
    if (_originalLocationLoading) return;
    if (_originalLocation != null && !_originalLocationFailed) return;
    try {
      if (await BelnetLib.isRunning) return;
    } catch (_) {
      return;
    }
    await _detectOriginalLocation();
    notifyListeners();
  }

  Future<void> _detectOriginalLocation() async {
    if (_originalLocationLoading) return;
    _originalLocationLoading = true;
    notifyListeners();
    try {
      // Shared with nearest-node selection, which runs at the same moment
      // on start-up: one network request serves both.
      final pos = await getUserLocationFromAPI();
      final geo = pos.location;
      // Re-check: if the tunnel came up while we were waiting, the answer
      // describes the exit, not the user.
      final runningNow = await BelnetLib.isRunning;
      if (geo != null && geo.hasCoordinates && !runningNow) {
        _originalLocation = geo;
        _originalLocationFailed = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_originalLocationKey, jsonEncode(geo.toJson()));
        if (isKnownIp(geo.ip)) {
          _realIp = geo.ip!;
          await prefs.setString(_realIpKey, _realIp);
        }
      } else if (geo == null) {
        _originalLocationFailed = true;
      }
    } catch (_) {
      _originalLocationFailed = true;
    } finally {
      _originalLocationLoading = false;
    }
  }

// Fetch IP

  // Requests made right after the tunnel comes up travel through a fresh
  // onion path and are often slow; 5 s was too tight and left the exit IP
  // (and therefore the exit country) unknown until the next 60 s refresh.
  static const _fetchTimeout = Duration(seconds: 8);

  /// Fast retries after connecting, until both the exit IP and its
  /// geolocation are known; afterwards only the normal 60 s refresh runs.
  static const _exitRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 7),
    Duration(seconds: 12),
    Duration(seconds: 20),
    Duration(seconds: 30),
    Duration(seconds: 45),
  ];
  Timer? _exitRetryTimer;
  int _exitRetryAttempt = 0;

  bool get _exitDetailsKnown => isKnownIp(_currentIPv4) && _exitLocation != null;

  void _scheduleExitRetry({bool reset = false}) {
    if (reset) _exitRetryAttempt = 0;
    _exitRetryTimer?.cancel();
    _exitRetryTimer = null;
    if (_timer == null) return; // monitoring stopped (disconnected)
    if (_exitDetailsKnown || _exitRetryAttempt >= _exitRetryDelays.length) {
      return;
    }
    _exitRetryTimer = Timer(_exitRetryDelays[_exitRetryAttempt++], () async {
      _exitRetryTimer = null;
      if (_timer == null) return;
      if (!isKnownIp(_currentIPv4)) {
        await fetchNewIPs();
      } else if (_exitLocation == null) {
        await checkCustomNodeCountry();
      }
      _scheduleExitRetry();
    });
  }

  Future<void> fetchNewIPs()async{
  try{
   // One request instead of two: api.ipify.org (IPv4-only) tells us the
   // public IPv4, and the IPv6 display value is derived locally from it.
   // Every request here is a full round trip THROUGH the exit node, so
   // keep this endpoint single and the cadence low (see startMonitoring).
   final ipv4Res = await http
       .get(Uri.parse('https://api.ipify.org'))
       .timeout(_fetchTimeout);
   if(ipv4Res.statusCode == 200){
    if(ipv4Res.body != _realIp){
         _currentIPv4 = ipv4Res.body; //jsonDecode(ipv4Res.body)['ip'];
         checkCustomNodeCountry();


    }else{
      _currentIPv4 = '000.000.000.00';
    }

   }
    if(_currentIPv4 != '000.000.000.00'){
      _currentIPv6 =
          isIPv6(_currentIPv4) ? _currentIPv4 : ipv4ToIpv6(_currentIPv4);
    }else{
      _currentIPv6 = '000.000.000.00';
    }

   notifyListeners();
  }catch(_){
    //convertToIPv6(_currentIPv4);
    print('NOT LOADING IPs-------->');
  }
}

/// Refresh the displayed IPs immediately - called after connect, exit-node
/// swaps and tunnel recovery so the UI updates promptly without needing an
/// aggressive polling interval.
Future<void> refreshNow() => fetchNewIPs();




Future<void> checkCustomNodeCountry()async{
  final ip = _currentIPv4;
  if (!isKnownIp(ip)) return;
  // The exit IP is refreshed every 60 s; only geolocate it when it changed.
  if (_exitLookupIp == ip) return;
  _exitLookupIp = ip;
  try {
    final geo = await IpGeolocationService.lookup(
        ip: ip, timeout: _fetchTimeout);
    if (_currentIPv4 != ip) return; // exit changed while we were waiting
    if (geo == null) {
      _exitLookupIp = null; // allow a retry on the next refresh
      print('Failed to fetch IP info for exit IP');
      return;
    }
    _exitLocation = geo;
    if (geo.country != null) {
      _customNodeCountry = geo.country;
      _customCountryCode = geo.countryCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customCountryKey, _customNodeCountry!);
      await prefs.setString(_customCountryCodeKey, _customCountryCode ?? '');
      print('Custom exitnode country name is $_customNodeCountry $customCountryCode');
    }
    notifyListeners();
  } catch (e) {
    _exitLookupIp = null;
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
  _timer = null;
  _exitRetryTimer?.cancel();
  _exitRetryTimer = null;
  resetIPS();

}


void startMonitoring()async{
 final isConnect = await BelnetLib.isRunning;
 if(isConnect){
    _timer?.cancel();
    // Fetch once right away so the UI shows the tunnel IP promptly, then
    // poll slowly. The old 5-second cadence sent two external requests
    // through the exit every 5 s for the whole session - pure overhead on
    // exactly the path users want fast. Event-driven refreshes
    // (refreshNow after connect/swap/recovery) cover the cases that need
    // immediacy.
    _timer = Timer.periodic(Duration(seconds: 60), (_)=> fetchNewIPs());
    // Retry quickly until the exit IP and its country are known, so the
    // map and the exit-node card don't wait a full minute after a slow
    // first request.
    fetchNewIPs().whenComplete(() => _scheduleExitRetry(reset: true));

 }
}




@override
void dispose(){
  _timer?.cancel();
  _exitRetryTimer?.cancel();
  super.dispose();
}



}


