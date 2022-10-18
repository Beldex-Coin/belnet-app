import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:flutter/material.dart';

bool setValue = false;
// Stream<String> myStream = Stream as Stream<String>;
class MyNotificationWorkLoad extends StatelessWidget {
  AppModel appModel;
  bool isLoading;
  Function function;
  MyNotificationWorkLoad(
      {Key? key, required this.appModel, required this.isLoading, required this.function})
      : super(key: key);

  var uploading ='';





  getUploadDownloadDataUpdate(){

    Timer.periodic(Duration(seconds: 2), (timer)async{
      print('calling the periodic for uploading value');

      function();
      uploading = await BelnetLib.upload;
    // myStream = uploading.toString() as Stream<String>;
    AwesomeNotifications().displayedStream.toString();
      print('uploading value is$uploading');
      // StatefulBuilder(builder: (BuildContext context, void Function(void Function()) setState){
      //   setState(() async=>  uploading = await BelnetLib.notificationString);
      //   print('value for UP uploading $uploading');
      //   return Container();
      // },);


    });
  }



  Future<void> createMyNotification(bool dismiss, upload, download) async {
    // getUploadDownloadDataUpdate();
     appModel.notifyListeners();
    await AwesomeNotifications().createNotification(
      
        content: NotificationContent(
            id: 3,
            channelKey: 'basic_channel',
            title: 'Belnet',
            body: "Belnet started"
                  // "${appModel.downloads} ${appModel.uploads}" 
                  , //"$myStream",
            //notificationLayout: NotificationLayout.BigPicture,
            displayOnBackground: true,
            progress: 1,
            showWhen: false, //need to test
            locked: true,
            autoDismissible: dismiss,
            color: BelnetLib.isConnected ? Color(0xff00DC00) : Colors.blue,
            category: NotificationCategory.Progress //Status //Service,    // need to test
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
      print("calling from Awesome Notification Disconnect button");
      if (BelnetLib.isConnected == false) {
        if (!isLoading) {
          print('getConnected function call');
          // print('Checking isConnected value ${BelnetLib.isConnected}');
          AwesomeNotifications().dismiss(3);
        }
      }
      if (event.buttonKeyPressed == "DISCONNECT") {
        if (BelnetLib.isConnected) {
          await BelnetLib.disconnectFromBelnet();
        }
      }
    });

    //await AwesomeNotifications().dismiss(3);
  }

  @override
  Widget build(BuildContext context) {
    //getUploadDownloadDataUpdate();
    return Container();
  }
}


class StringData extends StatefulWidget {
  const StringData({Key? key}) : super(key: key);

  @override
  State<StringData> createState() => _StringDataState();
}

class _StringDataState extends State<StringData> {


  @override
  void initState() {

    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Container();
  }
}







































// import 'dart:async';
//
// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:belnet_lib/belnet_lib.dart';
// import 'package:belnet_mobile/src/model/theme_set_provider.dart';
// import 'package:flutter/material.dart';
//
// bool setValue = false;
//
// class MyNotificationWorkLoad extends StatelessWidget {
//   AppModel appModel;
//   bool isLoading;
//   Function function;
//   MyNotificationWorkLoad(
//       {Key? key, required this.appModel, required this.isLoading, required this.function})
//       : super(key: key);
//
//   var uploading ='';
//
//   // getUploadDownloadDataUpdate(){
//   //
//   //   Timer.periodic(Duration(seconds: 2), (timer)async{
//   //     print('calling the periodic for uploading value');
//   //
//   //     function();
//   //     uploading = await BelnetLib.notificationString;
//   //     print('uploading value is$uploading');
//   //     // StatefulBuilder(builder: (BuildContext context, void Function(void Function()) setState){
//   //     //   setState(() async=>  uploading = await BelnetLib.notificationString);
//   //     //   print('value for UP uploading $uploading');
//   //     //   return Container();
//   //     // },);
//   //
//   //
//   //   });
//   // }
//
//
//
//    Future<void> createMyNotification(bool dismiss, upload, download) async {
//     // getUploadDownloadDataUpdate();
//     await AwesomeNotifications().createNotification(
//         content: NotificationContent(
//             id: 3,
//             channelKey: 'basic_channel',
//             title: 'Belnet',
//             body:  'Belnet is connected'
//                     '$uploading',
//             //notificationLayout: NotificationLayout.BigPicture,
//             displayOnBackground: true,
//             progress: 1,
//             showWhen: false, //need to test
//             locked: true,
//             autoDismissible: dismiss,
//             color: BelnetLib.isConnected ? Color(0xff00DC00) : Colors.blue,
//             category: NotificationCategory.Progress //Status //Service,    // need to test
//             //displayOnForeground: false
//             ),
//         actionButtons: [
//           NotificationActionButton(
//               showInCompactView: true,
//               key: 'DISCONNECT',
//               label: 'DISCONNECT',
//               buttonType: ActionButtonType.KeepOnTop,
//               autoDismissible: true)
//         ]);
//
//     AwesomeNotifications().actionStream.listen((event) async {
//       print("calling from Awesome Notification Disconnect button");
//       if (BelnetLib.isConnected == false) {
//         if (!isLoading) {
//           print('getConnected function call');
//           // print('Checking isConnected value ${BelnetLib.isConnected}');
//           AwesomeNotifications().dismiss(3);
//         }
//       }
//       if (event.buttonKeyPressed == "DISCONNECT") {
//         if (BelnetLib.isConnected) {
//           await BelnetLib.disconnectFromBelnet();
//         }
//       }
//     });
//
//     //await AwesomeNotifications().dismiss(3);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     //getUploadDownloadDataUpdate();
//     return Container();
//   }
// }
//
//
// class StringData extends StatefulWidget {
//   const StringData({Key? key}) : super(key: key);
//
//   @override
//   State<StringData> createState() => _StringDataState();
// }
//
// class _StringDataState extends State<StringData> {
//
//
//   @override
//   void initState() {
//
//     super.initState();
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Container();
//   }
// }
