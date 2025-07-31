import 'dart:typed_data';
import 'dart:convert';

class AppInfos {
  final String name;
  final String packageName;
  final bool isSystemApp;
  final Uint8List icon;

  AppInfos({
    required this.name,
    required this.packageName,
    required this.isSystemApp,
    required this.icon,
  });
factory AppInfos.fromMap(Map<dynamic, dynamic> map) {
  Uint8List decodedIcon;
  try {
    decodedIcon = base64Decode(map['icon'] ?? '');
  } catch (_) {
    decodedIcon = Uint8List(0);
  }

  return AppInfos(
    name: map['appName'] ?? '',
    packageName: map['packageName'] ?? '',
    isSystemApp: map['isSystemApp'] ?? false,
    icon: decodedIcon,
  );
}

  // factory AppInfos.fromMap(Map<dynamic, dynamic> map) {
  //   return AppInfos(
  //     name: map['appName'] ?? '',
  //     packageName: map['packageName'] ?? '',
  //     isSystemApp: map['isSystemApp'] ?? false,
  //     icon: base64Decode(map['icon'] ?? ''),
  //   );
  // }
}
