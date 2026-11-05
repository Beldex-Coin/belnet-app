import 'dart:async';

import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/providers/ad_blocker_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/utils/show_toast.dart';
import 'package:belnet_mobile/src/vpn_controller.dart' show ConnectionStatus;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:provider/provider.dart';

/// "Ad Blocker" row of the VPN settings page: switch, description and a
/// one-line live status (active / list size / blocked count / warnings).
///
/// Styled like the neighbouring "Auto-connect" and "Invite People" rows.
class AdBlockerSettingTile extends StatefulWidget {
  const AdBlockerSettingTile({super.key});

  static const String description =
      'Block advertisements and known tracking domains across apps connected through BelNet.';

  @override
  State<AdBlockerSettingTile> createState() => _AdBlockerSettingTileState();
}

class _AdBlockerSettingTileState extends State<AdBlockerSettingTile> {
  Timer? _poll;

  static const _titleStyle = TextStyle(fontFamily: 'Poppins', fontSize: 14);
  static const _descStyle =
      TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xff8D8D8D));
  static const _statusStyle = TextStyle(fontFamily: 'Poppins', fontSize: 11);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<AdBlockerProvider>();
      p.refreshStatus();
      // Cheap in-memory native call: keeps "blocked this session" and the
      // list-update progress current while Settings is open.
      _poll = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted) p.refreshStatus();
      });
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _onToggle(bool value) async {
    final adBlocker = context.read<AdBlockerProvider>();
    final loader = context.read<LoaderVideoProvider>();
    final ok = await adBlocker.setEnabled(value);
    if (!ok) {
      showMessage('Could not change the Ad Blocker setting. Please try again.');
      return;
    }
    final s = adBlocker.status;
    if (value && s != null && s.privateDnsBypass) {
      showMessage(
          'Android Private DNS is set to a provider: turn it off in Android settings for ad blocking to work.');
    } else if (value &&
        loader.conStatus == ConnectionStatus.CONNECTED &&
        s != null &&
        !s.filteringActive) {
      // The filter is attached to the tunnel when it is established.
      showMessage('Ad Blocker is on. Reconnect BelNet to start blocking ads.');
    }
  }

  void _onStatusTap(AdBlockerProvider p) {
    final s = p.status;
    if (!p.enabled || s == null || s.updating) return;
    p.refreshLists();
    showMessage('Checking filter lists for updates…');
  }

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    final loader = Provider.of<LoaderVideoProvider>(context);
    final adBlocker = Provider.of<AdBlockerProvider>(context);
    final connected = loader.conStatus == ConnectionStatus.CONNECTED;
    final status = _statusLine(adBlocker, connected);

    return LayoutBuilder(builder: (context, constraints) {
      // GlassContainer needs an explicit height: measure the wrapped text so
      // the row grows with the device width and the user's font size.
      final scaler = MediaQuery.textScalerOf(context);
      final textWidth = (constraints.maxWidth - 20 - 22 - 10).clamp(80.0, 2000.0);
      double measure(String text, TextStyle style, int maxLines) {
        final tp = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: maxLines,
        )..layout(maxWidth: textWidth);
        final h = tp.height;
        tp.dispose();
        return h;
      }

      final height = 12 +
          24 + // title row (switch height)
          2 +
          measure(AdBlockerSettingTile.description, _descStyle, 4) +
          4 +
          measure(status.text, _statusStyle, 2) +
          12 +
          4; // slack for font metrics differences

      return GlassContainer.clearGlass(
        height: height,
        width: double.infinity,
        blur: 21.0,
        color: appModel.darkTheme
            ? Colors.grey.shade600.withOpacity(0.06)
            : Colors.grey.withOpacity(0.2),
        borderColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: SvgPicture.asset(
                'assets/images/light_theme/Ad Blocker.svg',
                color: appModel.darkTheme ? Colors.white : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ad Blocker', style: _titleStyle),
                        FlutterSwitch(
                          width: 45.0,
                          height: 24.0,
                          toggleSize: 19.0,
                          value: adBlocker.enabled,
                          borderRadius: 30.0,
                          padding: 2.0,
                          activeToggleColor: adBlocker.busy
                              ? const Color(0xff00DC00).withOpacity(0.5)
                              : const Color(0xff00DC00),
                          inactiveToggleColor: adBlocker.busy
                              ? const Color(0xff929492).withOpacity(0.5)
                              : const Color(0xff929492),
                          activeSwitchBorder:
                              Border.all(color: const Color(0xffA1A1AF), width: 0.3),
                          inactiveSwitchBorder:
                              Border.all(color: const Color(0xffA1A1AF), width: 0.3),
                          activeColor: Colors.transparent,
                          inactiveColor: Colors.transparent,
                          onToggle: (value) {
                            if (adBlocker.busy) return;
                            _onToggle(value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(AdBlockerSettingTile.description,
                      style: _descStyle, maxLines: 4),
                  const SizedBox(height: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onStatusTap(adBlocker),
                    child: Text(
                      status.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _statusStyle.copyWith(color: status.color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  ({String text, Color color}) _statusLine(AdBlockerProvider p, bool connected) {
    const grey = Color(0xff8D8D8D);
    const green = Color(0xff00DC00);
    const amber = Color(0xffF5A623);
    final s = p.status;
    if (!p.enabled) return (text: 'Off', color: grey);
    if (s == null) return (text: 'On', color: green);
    if (s.privateDnsBypass) {
      return (
        text: 'Android Private DNS is on: turn it off in Android settings so ads can be blocked',
        color: amber
      );
    }
    if (s.updating) {
      return (text: 'Downloading filter lists…', color: grey);
    }
    final domains = '${_thousands(s.domains)} domains';
    if (s.usingBuiltinList) {
      return (
        text: 'Basic built-in list ($domains) · full lists download when online · tap to retry',
        color: s.lastError != null ? amber : grey
      );
    }
    final updated =
        s.listsUpdatedAt != null ? ' · updated ${_ago(s.listsUpdatedAt!)}' : '';
    final failed = s.lastError != null ? ' · last update failed' : '';
    if (connected && s.filteringActive) {
      return (
        text: 'Active · ${_thousands(s.sessionBlocked)} blocked · $domains$updated$failed',
        color: failed.isEmpty ? green : amber
      );
    }
    if (connected) {
      // Connected but the tunnel's DNS is not routed through the filter
      // (e.g. the relay could not be set up): be honest about it.
      return (text: 'Reconnect BelNet to activate · $domains', color: amber);
    }
    return (
      text: 'Applies when BelNet is connected · $domains$updated$failed',
      color: failed.isEmpty ? grey : amber
    );
  }

  static String _thousands(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }
}
