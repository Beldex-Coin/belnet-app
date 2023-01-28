import 'package:flutter/material.dart';
import 'package:native_updater/native_updater.dart';

class UpdateApp{



    Future<void> checkVersion(BuildContext context) async {
    /// For example: You got status code of 412 from the
    /// response of HTTP request.
    /// Let's say the statusCode 412 requires you to force update
    final statusCode = 412;

    /// This could be kept in our local
    // final localVersion = 9;

    /// This could get from the API
    //final serverLatestVersion = 10;

    Future.delayed(Duration.zero, () {
      if (statusCode == 412) {
        NativeUpdater.displayUpdateAlert(
          context,
          forceUpdate: true,
          appStoreUrl: '',
          playStoreUrl:
              'https://play.google.com/store/apps/details?id=io.beldex.belnet',
          iOSDescription:
              'A new version of the Belnet application is available. Update to continue using it.',
          iOSUpdateButtonLabel: 'Upgrade',
          iOSCloseButtonLabel: 'Exit',
          iOSAlertTitle: 'Mandatory Update',
        );
      } /* else if (serverLatestVersion > localVersion) {
        NativeUpdater.displayUpdateAlert(
          context,
          forceUpdate: true,
          appStoreUrl: 'https://apps.apple.com/in/app/beldex-official-wallet/id1603063369',
          playStoreUrl: 'https://play.google.com/store/apps/details?id=io.beldex.wallet',
          iOSDescription: 'Your App requires that you update to the latest version. You cannot use this app until it is updated.',
          iOSUpdateButtonLabel: 'Upgrade',
          iOSCloseButtonLabel: 'Exit',
        );*/
    });
  }
}