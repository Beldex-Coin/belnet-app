import 'package:belnet_mobile/src/providers/ad_blocker_provider.dart';
import 'package:belnet_mobile/src/providers/block_malware_provider.dart';
import 'package:belnet_mobile/src/utils/show_toast.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Ad Blocker and Block malware can't be on at the same time (each sets the
/// DNS used by the connection). Turning one on while the other is on is
/// refused with a message; turning either off is always allowed.

const String enableAdBlockerBlockedMessage =
    'Disable Block malware to enable Ad Blocker';
const String enableBlockMalwareBlockedMessage =
    'Disable Ad Blocker to enable Block malware';

/// True when the Ad Blocker may be set to [value]; otherwise shows the
/// message and returns false.
bool allowAdBlockerChange(BuildContext context, bool value) {
  if (value && context.read<BlockMalwareProvider>().enabled) {
    showMessage(enableAdBlockerBlockedMessage);
    return false;
  }
  return true;
}

/// True when Block malware may be set to [value]; otherwise shows the
/// message and returns false.
bool allowBlockMalwareChange(BuildContext context, bool value) {
  if (value && context.read<AdBlockerProvider>().enabled) {
    showMessage(enableBlockMalwareBlockedMessage);
    return false;
  }
  return true;
}
