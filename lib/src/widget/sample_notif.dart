// import 'dart:async';
// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class SampleNotif extends StatefulWidget {
//   const SampleNotif({super.key});

//   @override
//   State<SampleNotif> createState() => _SampleNotifState();
// }

// class _SampleNotifState extends State<SampleNotif> {
//  final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//   Timer? _speedUpdateTimer;
//   bool _isRunning = false;
//   double _uploadSpeed = 0.0;
//   double _downloadSpeed = 0.0;

//   @override
//   void initState() {
//     super.initState();
//     _initializeNotifications();
//   }

//   Future<void> _initializeNotifications() async {
//     const androidInitSettings = AndroidInitializationSettings('resource://drawable/res_notification_app_icon');
//     const initializationSettings = InitializationSettings(
//       android: androidInitSettings,
//     );
//     await _notificationsPlugin.initialize(initializationSettings);
//   }

//   void _startSpeedSimulation() {
//     setState(() {
//       _isRunning = true;
//     });
//     _speedUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         // Simulate random speeds (0.0 to 10.0 Mbps)
//         _uploadSpeed = Random().nextDouble() * 10;
//         _downloadSpeed = Random().nextDouble() * 10;

//         // Occasionally set speeds to 0 to simulate stopping
//         if (Random().nextInt(10) < 2) {
//           _uploadSpeed = 0.0;
//           _downloadSpeed = 0.0;
//         }

//         _updateNotification();
//       });
//     });
//   }

//   void _stopSpeedSimulation() {
//     setState(() {
//       _isRunning = false;
//       _uploadSpeed = 0.0;
//       _downloadSpeed = 0.0;
//     });
//     _speedUpdateTimer?.cancel();
//     _dismissNotification();
//   }

//   Future<void> _updateNotification() async {
//     if (_uploadSpeed == 0.0 && _downloadSpeed == 0.0) {
//       await _dismissNotification();
//       return;
//     }

//     const androidDetails = AndroidNotificationDetails(
//       'speed_channel',
//       'Network Speed',
//       channelDescription: 'Shows upload and download speeds',
//       importance: Importance.high,
//       priority: Priority.high,
//       ongoing: true, // Makes notification non-dismissable
//       autoCancel: false, // Ensures notification isn't auto-canceled
//       showProgress: false,
//     );
//     const notificationDetails = NotificationDetails(android: androidDetails);

//     await _notificationsPlugin.show(
//       0,
//       'Network Speed',
//       'Upload: ${_uploadSpeed.toStringAsFixed(2)} Mbps | Download: ${_downloadSpeed.toStringAsFixed(2)} Mbps',
//       notificationDetails,
//     );
//   }

//   Future<void> _dismissNotification() async {
//     await _notificationsPlugin.cancel(0);
//   }

//   @override
//   void dispose() {
//     _speedUpdateTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Speed Notification Demo')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Upload: ${_uploadSpeed.toStringAsFixed(2)} Mbps',
//               style: const TextStyle(fontSize: 20),
//             ),
//             Text(
//               'Download: ${_downloadSpeed.toStringAsFixed(2)} Mbps',
//               style: const TextStyle(fontSize: 20),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _isRunning ? _stopSpeedSimulation : _startSpeedSimulation,
//               child: Text(_isRunning ? 'Stop' : 'Start'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

// }