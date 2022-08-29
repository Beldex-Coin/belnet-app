import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/main.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:flutter_awesome_notifications_tutorial/utilities.dart';

bool setValue = false;

AppModel appModel = AppModel();
var conttext ;
class MyNotificationWorkLoad extends StatelessWidget {
  const MyNotificationWorkLoad({Key? key}) : super(key: key);
Future<void> createMyNotification() async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 3,
      channelKey: 'basic_channel',
      title:
      'Belnet',
      body: 'Belnet is connected',
      //notificationLayout: NotificationLayout.BigPicture,
      displayOnBackground: true,
      locked: true,
      color: BelnetLib.isConnected ? Color(0xff00DC00) : Colors.blue,
      category: NotificationCategory.Service,
      //displayOnForeground: true
    ),
    actionButtons: [
    //setValue ?
    NotificationActionButton(key: 'CONNECT', label: 'CONNECT',
        buttonType: ActionButtonType.KeepOnTop,
        autoDismissible: true,


    ) ,
    NotificationActionButton(key: 'DISCONNECT', label: 'DISCONNECT',
      buttonType: ActionButtonType.KeepOnTop,
        autoDismissible: true
      )
    ]
  );
  AwesomeNotifications().actionStream.listen((event) async {

    if(event.buttonKeyPressed == "DISCONNECT"){
      if(BelnetLib.isConnected){
        await BelnetLib.disconnectFromBelnet();
        appModel.connecting_belnet = false;
      }
    }
    if(event.buttonKeyPressed == "CONNECT"){
      if(!BelnetLib.isConnected){
        setValue = true;
        Navigator.pushAndRemoveUntil(
            conttext,
            MaterialPageRoute(
              builder: (_) => BelnetHomePage(),
            ),
                (route) => route.isFirst);
      }
    }
  });

}

  @override
  Widget build(BuildContext context) {

 appModel = Provider.of<AppModel>(context);

 conttext = context;
    return Container();
  }
}




