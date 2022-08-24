import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_awesome_notifications_tutorial/utilities.dart';

Future<void> createMyNotification() async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 3,
      channelKey: 'basic_channel',
      title:
      'Connected to the Belnet',
      body: 'Click to go to belnet',
      //notificationLayout: NotificationLayout.BigPicture,
      displayOnBackground: true,
      locked: true,
      color: BelnetLib.isConnected ? Color(0xff00DC00) : Colors.blue,
      category: NotificationCategory.Service,
      //displayOnForeground: true
    ),
    actionButtons: [
    BelnetLib.isConnected ?
    NotificationActionButton(key: 'CONNECTED', label: 'Connect to Belnet',
        buttonType: ActionButtonType.KeepOnTop,
        autoDismissible: true,


    ) :
    NotificationActionButton(key: 'DISCONNECTED', label: 'DISCONNECTED',
      buttonType: ActionButtonType.KeepOnTop,
        autoDismissible: true

      )
    ]
  );
}

