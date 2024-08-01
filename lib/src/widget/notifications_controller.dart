

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationController{

  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification
      )async{

  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification
      )async{

  }

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedNotification receivedNotification
      )async{

  }

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedNotification receivedNotification
      )async{
    // String? action = receivedNotification.payload?['action'];
    // if(action == "disconnect"){
    //  await BelnetLib.disconnectFromBelnet();
    //  AwesomeNotifications().cancelAll();
    // }
  }

}




class NotificationProvider extends ChangeNotifier {
  String _notificationBody = '';

  String get notificationBody => _notificationBody;

  void updateNotificationBody(String body) {
    _notificationBody = body;
    notifyListeners();
  }

  void showNotification({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    required bool locked,
    required bool autoDismissible,
    required NotificationCategory category,
  }) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
       // title: title,
        body: body,
        locked: locked,
        autoDismissible: autoDismissible,
        category: category,
        //payload: {'action': 'disconnect'}
      ),
      // actionButtons: [
      // NotificationActionButton(key: 'discon_button',
      //     label: 'Disconnect')
      // ]
    );
    updateNotificationBody(body); // Update the notification body in the provider
  }

  void dismissNotification(int id) {
    AwesomeNotifications().cancel(1);
    AwesomeNotifications().cancelAll();
    AwesomeNotifications().cancelNotificationsByChannelKey('belnets_channel');
    _notificationBody = ''; // Clear the notification body when dismissing
    notifyListeners();
  }
}
