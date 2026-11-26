import 'dart:async';
import 'dart:math' as math;

import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/providers/ad_blocker_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/utils/show_toast.dart';
import 'package:belnet_mobile/src/utils/protection_exclusive.dart';
import 'package:belnet_mobile/src/vpn_controller.dart' show ConnectionStatus;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:provider/provider.dart';

/// Shared colours of the Ad Blocker UI.
class AdBlockerColors {
  AdBlockerColors._();
  static const green = Color(0xff00DC00);
  static const grey = Color(0xff8D8D8D);
  static const amber = Color(0xffF5A623);

  /// Secondary text (descriptions, labels, "Off"). Darker on the light
  /// theme so it stays readable on the light grey background.
  static Color muted(bool dark) => dark ? grey : const Color(0xff6B6B6B);

  /// Least important text (filter list website).
  static Color faint(bool dark) => dark ? grey : const Color(0xff9A9A9A);

  /// Warnings: the bright amber is hard to read on the light theme.
  static Color warning(bool dark) => dark ? amber : const Color(0xffC27400);

  /// Background of the toggle card and the counter tiles.
  static Color tile(bool dark) =>
      dark ? Colors.grey.shade600.withOpacity(0.08) : Colors.grey.withOpacity(0.2);

  /// Switch track: transparent on dark, white pill on light (as in the design).
  static Color switchTrack(bool dark) => dark ? Colors.transparent : Colors.white;

  static BoxBorder switchBorder(bool dark) => dark
      ? Border.all(color: const Color(0xffA1A1AF), width: 0.3)
      : Border.all(color: const Color(0xffCFCFCF), width: 0.8);
}

/// Thin, flat progress bar (no Material 3 track gap, stop dot or tint).
class _FlatProgressBar extends StatelessWidget {
  const _FlatProgressBar({required this.value, required this.dark});

  final double value;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        height: 3,
        color: dark ? Colors.grey.withOpacity(0.25) : const Color(0xffDADADA),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 400),
          builder: (_, v, __) => FractionallySizedBox(
            widthFactor: v,
            heightFactor: 1,
            child: const ColoredBox(color: AdBlockerColors.green),
          ),
        ),
      ),
    );
  }
}

/// Settings → Ad Blocker. Same structure as Split Tunneling: the on/off
/// switch at the top, then (when on) live counters, then the filter lists
/// with their download progress.
class AdBlockerScreen extends StatefulWidget {
  const AdBlockerScreen({super.key});

  static const String description =
      'Block ads and known tracking domains across apps connected through BelNet.';

  /// Rough average size of the ad / tracker request a blocked lookup
  /// prevents, used for the "Data saved" estimate. Not a measurement.
  static const int estimatedBytesPerBlock = 10 * 1024;

  @override
  State<AdBlockerScreen> createState() => _AdBlockerScreenState();
}

class _AdBlockerScreenState extends State<AdBlockerScreen> {
  Timer? _poll;
  bool _fastPolling = false;

  /// "Check for updates" was tapped: show the spinner straight away, until
  /// the native side reports the download (or that nothing needed it).
  DateTime? _refreshTappedAt;

  static const String _lockedMessage =
      'Please disconnect BelNet to turn the Ad Blocker on or off.';

  /// Only changeable while BelNet is fully disconnected.
  static bool _isLocked(LoaderVideoProvider loader) =>
      loader.conStatus != ConnectionStatus.DISCONNECTED || loader.isLoading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdBlockerProvider>().refreshStatus();
      _schedulePoll(fast: false);
    });
  }

  /// Every second while lists download (progress), otherwise every 4 s.
  void _schedulePoll({required bool fast}) {
    _poll?.cancel();
    _fastPolling = fast;
    _poll = Timer.periodic(Duration(seconds: fast ? 1 : 4), (_) {
      if (!mounted) return;
      final p = context.read<AdBlockerProvider>();
      p.refreshStatus();
      final updating = p.status?.updating == true;
      if (updating != _fastPolling) _schedulePoll(fast: updating);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _onToggle(bool value) async {
    final adBlocker = context.read<AdBlockerProvider>();
    if (_isLocked(context.read<LoaderVideoProvider>())) {
      showMessage(_lockedMessage);
      return;
    }
    if (!allowAdBlockerChange(context, value)) return;
    final ok = await adBlocker.setEnabled(value);
    if (!ok) {
      showMessage('Could not change the Ad Blocker setting. Please try again.');
      return;
    }
    // Turning it on starts downloading missing lists: follow the progress.
    if (value) _schedulePoll(fast: true);
    final s = adBlocker.status;
    if (value && s != null && s.privateDnsBypass) {
      showMessage(
          'Android Private DNS is set to a provider: turn it off in Android settings for ad blocking to work.');
    }
  }

  void _onRefresh(AdBlockerProvider p) {
    if (!p.enabled) {
      showMessage('Turn on the Ad Blocker to download its filter lists.');
      return;
    }
    if (p.status?.updating == true) return;
    setState(() => _refreshTappedAt = DateTime.now());
    p.refreshLists();
    _schedulePoll(fast: true);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Provider.of<AppModel>(context).darkTheme;
    final loader = Provider.of<LoaderVideoProvider>(context);
    final adBlocker = Provider.of<AdBlockerProvider>(context);
    final s = adBlocker.status;
    final locked = _isLocked(loader);
    final connected = loader.conStatus == ConnectionStatus.CONNECTED;
    final updating = adBlocker.enabled && s?.updating == true;
    final tapped = _refreshTappedAt;
    if (tapped != null &&
        (updating ||
            !adBlocker.enabled ||
            DateTime.now().difference(tapped) > const Duration(seconds: 2))) {
      _refreshTappedAt = null;
    }
    final showSpinner = updating || _refreshTappedAt != null;
    final sources = s?.sources ?? const <AdBlockerSource>[];
    final textColor = dark ? Colors.white : Colors.black;
    final muted = AdBlockerColors.muted(dark);
    final line = _statusLine(adBlocker, connected, textColor, dark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // On/off card.
        GlassContainer.clearGlass(
          height: 50,
          width: double.infinity,
          blur: 30.0,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          color: dark ? Colors.grey.withOpacity(0.1) : AdBlockerColors.tile(dark),
          borderColor: Colors.transparent,
          child: Row(
            children: [
              SvgPicture.asset('assets/images/light_theme/Ad Blocker.svg',
                  color: dark ? Colors.white : null),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Ad Blocker',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
              ),
              FlutterSwitch(
                width: 45.0,
                height: 24.0,
                toggleSize: 19.0,
                value: adBlocker.enabled,
                borderRadius: 30.0,
                padding: 2.0,
                // Dimmed while connected/busy, like Split Tunneling.
                activeToggleColor: locked || adBlocker.busy
                    ? AdBlockerColors.green.withOpacity(0.5)
                    : AdBlockerColors.green,
                inactiveToggleColor: locked || adBlocker.busy
                    ? const Color(0xff929492).withOpacity(0.5)
                    : const Color(0xff929492),
                activeSwitchBorder: AdBlockerColors.switchBorder(dark),
                inactiveSwitchBorder: AdBlockerColors.switchBorder(dark),
                activeColor: AdBlockerColors.switchTrack(dark),
                inactiveColor: AdBlockerColors.switchTrack(dark),
                onToggle: (value) {
                  if (locked) {
                    showMessage(_lockedMessage);
                    return;
                  }
                  if (adBlocker.busy) return;
                  _onToggle(value);
                },
              ),
            ],
          ),
        ),

        // Description + one-line status.
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AdBlockerScreen.description,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      height: 1.45,
                      color: muted)),
              Text(line.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      height: 1.45,
                      color: line.color)),
            ],
          ),
        ),

        // Overall download progress ("4 of 11").
        if (updating && (s?.updateTotal ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: _FlatProgressBar(value: _overallProgress(s!), dark: dark),
          ),

        // Live counters while on and not downloading.
        if (adBlocker.enabled && s != null && !updating && !s.usingBuiltinList)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    value: _thousands(s.sessionBlocked),
                    label: 'Ads & trackers\nblocked',
                    valueColor: dark ? AdBlockerColors.green : const Color(0xff00B400),
                    dark: dark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _StatTile(
                    value: _thousands(s.domains),
                    label: 'Domains in\nfilter lists',
                    valueColor: textColor,
                    dark: dark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _StatTile(
                    value: _dataSaved(s.sessionBlocked),
                    label: 'Data saved\nthis session',
                    valueColor: textColor,
                    dark: dark,
                  ),
                ),
              ],
            ),
          ),

        // Filter lists.
        Expanded(
          child: GlassContainer.clearGlass(
            height: double.infinity,
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12, left: 10, right: 10),
            blur: 18.0,
            color: dark
                ? const Color(0xff0B0B0B).withOpacity(0.8)
                : const Color(0x33F5F5F5).withOpacity(0.3),
            borderColor: dark
                ? const Color(0xffACACAC).withOpacity(0.6)
                : const Color(0xffACACAC),
            borderWidth: 0.3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 4, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          sources.isEmpty
                              ? 'Filter lists'
                              : 'Filter lists (${sources.length})',
                          style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 14),
                        ),
                      ),
                      // Spinner in place of the refresh button (same 48 px
                      // slot) while lists download.
                      showSpinner
                          ? SizedBox(
                              height: 48,
                              width: 48,
                              child: Center(
                                child: SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.8, color: textColor),
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: 'Check for updates',
                              onPressed: () => _onRefresh(adBlocker),
                              icon: Icon(Icons.refresh, size: 20, color: textColor),
                            ),
                    ],
                  ),
                ),
                if (!adBlocker.enabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                    child: Text(
                      'Lists download once and update automatically every 24 hours.',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          height: 1.45,
                          color: muted),
                    ),
                  ),
                Expanded(
                  child: sources.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AdBlockerColors.green))
                      // No Android overscroll glow/stretch: it shows as a
                      // blue shade at the top of the list on this dark card.
                      : ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context)
                              .copyWith(overscroll: false),
                          child: ListView.separated(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: sources.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: Colors.grey.withOpacity(dark ? 0.18 : 0.3),
                          ),
                          itemBuilder: (context, i) => _SourceTile(
                            source: sources[i],
                            enabled: adBlocker.enabled,
                            textColor: textColor,
                            dark: dark,
                          ),
                        ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static double _overallProgress(AdBlockerStatus s) {
    // Count the list in progress partially, so the bar moves smoothly.
    double current = 0;
    for (final src in s.sources) {
      if (src.downloading && src.percent >= 0) current = src.percent / 100;
    }
    return math.min(1, (s.updateDone + current) / s.updateTotal);
  }

  ({String text, Color color}) _statusLine(
      AdBlockerProvider p, bool connected, Color textColor, bool dark) {
    final s = p.status;
    final muted = AdBlockerColors.muted(dark);
    final warning = AdBlockerColors.warning(dark);
    final green = dark ? AdBlockerColors.green : const Color(0xff00B400);
    if (!p.enabled) return (text: 'Off', color: muted);
    if (s == null) return (text: 'On', color: green);
    if (s.updating && s.updateTotal > 0) {
      final n = math.min(s.updateDone + 1, s.updateTotal);
      return (
        text: 'Downloading filter lists… $n of ${s.updateTotal}',
        color: textColor
      );
    }
    if (s.privateDnsBypass) {
      return (
        text: 'Android Private DNS is on: turn it off in Android settings so ads can be blocked',
        color: warning
      );
    }
    if (s.usingBuiltinList) {
      return (
        text: s.lastError != null
            ? "Couldn't download filter lists · using a basic list · tap ⟳ to retry"
            : 'Using a basic list until the filter lists download',
        color: s.lastError != null ? warning : muted
      );
    }
    if (connected && s.filteringActive) {
      return (
        text: 'Active · protecting connected apps',
        color: green
      );
    }
    if (connected) {
      return (text: 'Reconnect BelNet to activate', color: warning);
    }
    return (
      text: 'On · protects apps when BelNet is connected',
      color: muted
    );
  }

  static String _dataSaved(int blocked) {
    final bytes = blocked * AdBlockerScreen.estimatedBytesPerBlock;
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    if (mb < 1) return '~${(bytes / 1024).round()} KB';
    if (mb < 1024) return '~${mb.toStringAsFixed(1)} MB';
    return '~${(mb / 1024).toStringAsFixed(1)} GB';
  }
}

String _thousands(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// One of the three counters above the filter lists.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.dark,
  });

  final String value;
  final String label;
  final Color valueColor;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      color: AdBlockerColors.tile(dark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                maxLines: 1,
                style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 14, color: valueColor)),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  height: 1.35,
                  color: AdBlockerColors.muted(dark))),
        ],
      ),
    );
  }
}

/// One filter list: state dot, name, source site and status.
class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.source,
    required this.enabled,
    required this.textColor,
    required this.dark,
  });

  final AdBlockerSource source;
  final bool enabled;
  final Color textColor;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final String detail;
    final muted = AdBlockerColors.muted(dark);
    final warning = AdBlockerColors.warning(dark);
    final green = dark ? AdBlockerColors.green : const Color(0xff00C800);
    Widget marker = _dot(muted);
    if (source.downloading) {
      detail = source.percent >= 0
          ? 'Downloading… ${source.percent}%'
          : 'Downloading…';
      marker = SizedBox(
        width: 8,
        height: 8,
        child: CircularProgressIndicator(strokeWidth: 1.4, color: muted),
      );
    } else if (source.waiting) {
      detail = 'Waiting';
    } else if (source.downloaded) {
      final updated = source.updatedAt != null
          ? ' · updated ${_ago(source.updatedAt!)}'
          : '';
      detail = '${_thousands(source.domains)} domains$updated'
          '${source.failed ? ' · last update failed' : ''}';
      marker = _dot(source.failed ? warning : (enabled ? green : muted));
    } else if (source.failed) {
      detail = 'Download failed · will retry';
      marker = _dot(warning);
    } else {
      detail = 'Not downloaded yet';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(width: 8, height: 8, child: Center(child: marker)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(source.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 13, color: textColor)),
                if (source.site.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Transform.rotate(
                          angle: -math.pi / 4,
                          child: Icon(Icons.link,
                              size: 11, color: AdBlockerColors.faint(dark)),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(source.site,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: AdBlockerColors.faint(dark))),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: textColor.withOpacity(dark ? 0.75 : 0.7))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _dot(Color c) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }
}

/// "Ad Blocker" row on the main Settings list (Privacy & Protection):
/// title, "On · N blocked this session" / "Off", and an arrow that opens
/// [AdBlockerScreen].
class AdBlockerSettingsRow extends StatefulWidget {
  const AdBlockerSettingsRow({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<AdBlockerSettingsRow> createState() => _AdBlockerSettingsRowState();
}

class _AdBlockerSettingsRowState extends State<AdBlockerSettingsRow> {
  @override
  void initState() {
    super.initState();
    // Fresh "blocked this session" count whenever Settings is opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdBlockerProvider>().refreshStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Provider.of<AppModel>(context).darkTheme;
    final adBlocker = Provider.of<AdBlockerProvider>(context);
    final blocked = adBlocker.status?.sessionBlocked ?? 0;
    final sub = TextStyle(
        fontFamily: 'Poppins', fontSize: 12, color: AdBlockerColors.muted(dark));

    return GestureDetector(
      onTap: widget.onTap,
      child: GlassContainer.clearGlass(
        height: 60,
        width: double.infinity,
        blur: 20.0,
        color: dark
            ? Colors.grey.shade600.withOpacity(0.06)
            : Colors.grey.withOpacity(0.2),
        borderColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            SvgPicture.asset('assets/images/light_theme/Ad Blocker.svg',
                color: dark ? Colors.white : null),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ad Blocker',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                  Text.rich(
                    adBlocker.enabled
                        ? TextSpan(children: [
                            TextSpan(
                                text: 'On',
                                style: TextStyle(
                                    color: dark
                                        ? AdBlockerColors.green
                                        : const Color(0xff00B400))),
                            if (blocked > 0)
                              TextSpan(
                                  text: ' · ${_thousands(blocked)} blocked this session'),
                          ])
                        : const TextSpan(text: 'Off'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sub,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SvgPicture.asset('assets/images/dark_theme/arrow_settings.svg',
                  color: dark ? Colors.white : const Color(0xff4D4D4D)),
            ),
          ],
        ),
      ),
    );
  }
}
