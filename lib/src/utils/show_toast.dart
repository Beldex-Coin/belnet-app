import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Short toast-style message at the bottom of the screen.
///
/// Pure Dart (GetX snackbar, the app already uses GetMaterialApp), replacing
/// the fluttertoast plugin, which still applies the Kotlin Gradle Plugin and
/// will stop building on future Flutter versions.
void showMessage(message) {
  if (Get.isSnackbarOpen) {
    Get.closeCurrentSnackbar();
  }
  Get.rawSnackbar(
    messageText: Text(
      '$message',
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
    ),
    backgroundColor: const Color(0xE6323232),
    snackPosition: SnackPosition.BOTTOM,
    snackStyle: SnackStyle.FLOATING,
    margin: const EdgeInsets.fromLTRB(32, 0, 32, 48),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    borderRadius: 24,
    duration: const Duration(seconds: 2),
    isDismissible: true,
  );
}
