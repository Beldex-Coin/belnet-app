

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:flutter/material.dart';

class LocalNotificationService{

  static Future<void> initializedNotification()async{
    await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
              channelKey: 'basic_channel',
              channelName: 'Basic notifications',
              channelDescription: 'Notification channel for basic tests',
          defaultColor: Colors.white,
            importance: NotificationImportance.Low,
            channelShowBadge: true,
            playSound: false,
            locked: true,

          )
        ],
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'basic_channel',
            channelGroupName: 'Group 1'
        ),
      ]

    );
    // await AwesomeNotifications().isNotificationAllowed().then((isAllowed) async{
    //   if(!isAllowed){
    //     await AwesomeNotifications().requestPermissionToSendNotifications();
    //   }
    // });

    await AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod:onNotificationDisplayedMethod ,
      onDismissActionReceivedMethod:onDismissActionReceivedMethod,
    );
  }

  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification)async{

  }

  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification)async{

  }

  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction)async{

  }

  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction)async{
    final payload = receivedAction.payload ?? {};
    if(payload["disconnect"] == "true"){
      if(BelnetLib.isConnected){

        await BelnetLib.disconnectFromBelnet();
        await AwesomeNotifications().dismiss(1);
      }
    }
  }

  static Future<void> showNotification({
    required final String title,
    required final String body,
    final String? summary,
    final Map<String,String>? payload,
    final ActionType actionType = ActionType.SilentBackgroundAction,
    final NotificationLayout notificationLayout = NotificationLayout.Default,
    final NotificationCategory? category,
    final String? bigPicture,
    final List<NotificationActionButton>? actionButtons,
    final bool scheduled = false,
    final int? interval,
})async{
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 1,
            channelKey: 'basic_channel',
           title: title,
           body: body,
          actionType: actionType,
          notificationLayout: notificationLayout,
          summary: summary,
          category: category,
          payload: payload,
          bigPicture: bigPicture
        ),
      actionButtons: actionButtons,
      schedule: null
    );
  }
}