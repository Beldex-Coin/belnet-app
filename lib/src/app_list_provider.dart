import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/model/installed_apps_model.dart';
import 'package:flutter/material.dart';
//import 'package:installed_apps/app_info.dart';
//import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSelectionProvider with ChangeNotifier {
  Set<String> _selectedApps = {};

  Set<String> get selectedApps => _selectedApps;

  Future<void> loadSelectedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('selectedApps') ?? [];
    _selectedApps = savedList.toSet();
    notifyListeners();
  }

  Future<void> toggleApp(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedApps.contains(packageName)) {
      _selectedApps.remove(packageName);
    } else {
      _selectedApps.add(packageName);
    }
    await prefs.setStringList('selectedApps', _selectedApps.toList());
    notifyListeners();
  }

  bool isSelected(String packageName) => _selectedApps.contains(packageName);
}


// Singleton to cache app list
// class AppCache {
//   static final AppCache instance = AppCache._internal();
//   List<AppInfo> _apps = [];

//   AppCache._internal();

//   List<AppInfo> get apps => _apps;

//   Future<void> loadApps() async {
//     try {
//       _apps = await InstalledApps.getInstalledApps(false, true);
//       // Debug: Log fetched apps
//       _apps.removeWhere((app) => app.packageName == 'io.beldex.belnet');
//       _apps.removeWhere((app) => app.packageName == 'io.beldex.beldex_browser');
//       print('Fetched ${_apps.length} apps:');
//       for (var app in _apps) {
//         print('App: ${app.name}, Package: ${app.packageName}');
//       }
//     } catch (e) {
//       _apps = [];
//       print('Error fetching apps: $e');
//     }
//   }
// }

class AppCache {
  static final AppCache instance = AppCache._internal();
  List<AppInfos> _apps = [];

  AppCache._internal();

  List<AppInfos> get apps => _apps;

  Future<void> loadApps() async {
    try {
      final List<dynamic> result = await BelnetLib.getInstalledApps(); //_channel.invokeMethod('getInstalledAppsWithInternetPermission');
      final List<AppInfos> fetchedApps = result.map((map) => AppInfos.fromMap(map)).toList();

      // Filter out your own apps
      fetchedApps.removeWhere((app) =>
          app.packageName == 'io.beldex.belnet' ||
          app.packageName == 'io.beldex.beldex_browser');

      _apps = fetchedApps;

      print('Fetched ${_apps.length} apps with INTERNET permission');
    } catch (e) {
      _apps = [];
      print('Error fetching apps: $e');
    }
  }
}

class AppSelectingProvider with ChangeNotifier {
  List<String> _selectedApps = [];
  bool _showSystemApps = false;
  String _searchQuery = '';

  List<String> get selectedApps => _selectedApps;
  bool get showSystemApps => _showSystemApps;
  String get searchQuery => _searchQuery;



bool _isSPEnabled = false;

  bool get isSPEnabled => _isSPEnabled;



  AppSelectingProvider() {
    _loadPreferences();
    _loadToggleValue();
  }



void _loadToggleValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isSPEnabled = prefs.getBool('toggleValue') ?? false;
    notifyListeners();
  }

  void toggle() async {
    _isSPEnabled = !_isSPEnabled;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('toggleValue', _isSPEnabled);
  }














  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedApps = prefs.getStringList('selected_apps') ?? [];
    _showSystemApps = prefs.getBool('show_system_apps') ?? false;
    notifyListeners();
  }

  Future<void> addApp(String packageName) async {
    if (!_selectedApps.contains(packageName)) {
      _selectedApps = [..._selectedApps, packageName];
      await _savePreferences();
      print('Added app: $packageName');
      notifyListeners();
    }
  }

  Future<void> removeApp(String packageName) async {
    if (_selectedApps.contains(packageName)) {
      _selectedApps = _selectedApps.where((p) => p != packageName).toList();
      await _savePreferences();
      print('Removed app: $packageName');
      notifyListeners();
    }
  }

  Future<void> toggleSystemApps(bool value) async {
    _showSystemApps = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_system_apps', _showSystemApps);
    print('Toggled system apps: $value');
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    print('Search query: $query');
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_apps', _selectedApps);
  }
}









/// For the settings screen navigation 

enum SettingsView { general, splitTunneling }

class SettingsProvider with ChangeNotifier {
  SettingsView _currentView = SettingsView.general;

  SettingsView get currentView => _currentView;

  void showGeneral() {
    _currentView = SettingsView.general;
    notifyListeners();
  }

  void showSplitTunneling() {
    _currentView = SettingsView.splitTunneling;
    notifyListeners();
  }
}






///////////////////////////////
// class AppSelectingProvider with ChangeNotifier {
//   List<String> _selectedApps = [];
//   bool _showSystemApps = false;

//   List<String> get selectedApps => _selectedApps;
//   bool get showSystemApps => _showSystemApps;

//   AppSelectingProvider() {
//     _loadPreferences();
//   }

//   Future<void> _loadPreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     _selectedApps = prefs.getStringList('selected_apps') ?? [];
//     _showSystemApps = prefs.getBool('show_system_apps') ?? false;
//     notifyListeners();
//   }

//   Future<void> addApp(String packageName) async {
//     if (!_selectedApps.contains(packageName)) {
//       _selectedApps = [..._selectedApps, packageName];
//       await _savePreferences();
//       print('Added app: $packageName');
//       notifyListeners();
//     }
//   }

//   Future<void> removeApp(String packageName) async {
//     if (_selectedApps.contains(packageName)) {
//       _selectedApps = _selectedApps.where((p) => p != packageName).toList();
//       await _savePreferences();
//       print('Removed app: $packageName');
//       notifyListeners();
//     }
//   }

//   Future<void> toggleSystemApps(bool value) async {
//     _showSystemApps = value;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('show_system_apps', _showSystemApps);
//     print('Toggled system apps: $value');
//     notifyListeners();
//   }

//   Future<void> _savePreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setStringList('selected_apps', _selectedApps);
//   }
// }
////////////////////////////////////////



// class AppSelectingProvider with ChangeNotifier {
//   List<String> _selectedApps = [];
//   bool _showSystemApps = false;

//   List<String> get selectedApps => _selectedApps;
//   bool get showSystemApps => _showSystemApps;

//   AppSelectingProvider() {
//     _loadPreferences();
//   }

//   Future<void> _loadPreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     _selectedApps = prefs.getStringList('selected_apps') ?? [];
//     _showSystemApps = prefs.getBool('show_system_apps') ?? false;
//     notifyListeners();
//   }

//   Future<void> addApp(String packageName) async {
//     if (!_selectedApps.contains(packageName)) {
//       _selectedApps.add(packageName);
//       await _savePreferences();
//       notifyListeners();
//     }
//   }

//   Future<void> removeApp(String packageName) async {
//     _selectedApps.remove(packageName);
//     await _savePreferences();
//     notifyListeners();
//   }

//   Future<void> toggleSystemApps(bool value) async {
//     _showSystemApps = value;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('show_system_apps', _showSystemApps);
//     notifyListeners();
//   }

//   Future<void> _savePreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setStringList('selected_apps', _selectedApps);
//   }
// }
