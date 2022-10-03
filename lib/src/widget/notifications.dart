import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:flutter/material.dart';
bool setValue = false;
class MyNotificationWorkLoad extends StatelessWidget {
  AppModel appModel;
  MyNotificationWorkLoad({Key? key, required this.appModel}) : super(key: key);
  Future<void> createMyNotification(bool dismiss) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 3,
          channelKey: 'basic_channel',
          title: 'Belnet',
          body: 'Belnet is connected',
          //notificationLayout: NotificationLayout.BigPicture,
          displayOnBackground: true,
          showWhen: false,  //need to test
          locked: true,


          autoDismissible: dismiss,
          color: BelnetLib.isConnected ? Color(0xff00DC00) : Colors.blue,
          category: NotificationCategory.Status    //Service,    // need to test
          //displayOnForeground: false
        ),
        actionButtons: [
          NotificationActionButton(
            showInCompactView: true,
              key: 'DISCONNECT',
              label: 'DISCONNECT',
              buttonType: ActionButtonType.KeepOnTop,
              autoDismissible: true)
        ]);
    AwesomeNotifications().actionStream.listen((event) async {
     print("calling from Awesome Nofication Disconnect button");
      if (event.buttonKeyPressed == "DISCONNECT") {
        if (BelnetLib.isConnected) {
          await BelnetLib.disconnectFromBelnet();
         // appModel.connecting_belnet = false;
        }
      }
    });

   //await AwesomeNotifications().dismiss(3);

  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
