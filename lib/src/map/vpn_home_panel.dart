import 'dart:async';

import 'package:belnet_mobile/country_code_list.dart';
import 'package:belnet_mobile/node_provider.dart';
import 'package:belnet_mobile/src/map/vpn_home_style.dart';
import 'package:belnet_mobile/src/map/vpn_map_provider.dart';
import 'package:belnet_mobile/src/providers/ad_blocker_provider.dart';
import 'package:belnet_mobile/src/providers/block_malware_provider.dart';
import 'package:belnet_mobile/src/providers/introstate_provider.dart';
import 'package:belnet_mobile/src/providers/ip_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

/// Bottom panel of the home screen (V3 design): exit node, connect button,
/// and - when expanded (tap the arrow or swipe up) - live speeds, session
/// time and the protection settings.
class VpnHomePanel extends StatefulWidget {
  const VpnHomePanel({
    super.key,
    required this.dark,
    required this.onConnectToggle,
    required this.onAddExitNode,
    required this.onChangeNode,
    required this.onOpenExitNodes,
    required this.expanded,
    required this.onExpandedChanged,
  });

  final bool dark;

  /// Connect when disconnected, disconnect when connected.
  final VoidCallback onConnectToggle;
  final VoidCallback onAddExitNode;
  final VoidCallback onChangeNode;
  final VoidCallback onOpenExitNodes;

  /// Stats and protection rows are shown. The home screen owns this so the
  /// map can shrink with it.
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  @override
  State<VpnHomePanel> createState() => _VpnHomePanelState();
}

class _VpnHomePanelState extends State<VpnHomePanel> {
  Timer? _adBlockPoll;

  bool get _expanded => widget.expanded;

  @override
  void initState() {
    super.initState();
    if (widget.expanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncAdBlockPoll());
    }
  }

  @override
  void didUpdateWidget(covariant VpnHomePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) _syncAdBlockPoll();
  }

  @override
  void dispose() {
    _adBlockPoll?.cancel();
    super.dispose();
  }

  void _setExpanded(bool value) {
    if (_expanded == value) return;
    widget.onExpandedChanged(value);
  }

  /// "186 blocked this session" comes from the native Ad Blocker; refresh
  /// it only while the expanded panel shows it.
  void _syncAdBlockPoll() {
    final want = _expanded && mounted;
    if (want && _adBlockPoll == null) {
      final ads = context.read<AdBlockerProvider>();
      unawaited(ads.refreshStatus());
      _adBlockPoll = Timer.periodic(
          const Duration(seconds: 3), (_) => unawaited(ads.refreshStatus()));
    } else if (!want) {
      _adBlockPoll?.cancel();
      _adBlockPoll = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = VpnHomeStyle.of(widget.dark);
    final map = context.watch<VpnMapProvider>();
    final loader = context.watch<LoaderVideoProvider>();
    final intro = context.watch<IntroStateProvider>();
    // What the map shows: stays "connecting" until the globe has finished.
    final phase = map.displayPhase;
    final connected = phase == VpnMapPhase.connected;
    final idle =
        phase == VpnMapPhase.disconnected || phase == VpnMapPhase.failed;
    final canAdd = idle && intro.showButton;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -150) _setExpanded(true);
        if (v > 150) _setExpanded(false);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle: arrow up (collapsed) / down (expanded).
            Center(
              child: InkResponse(
                onTap: () => _setExpanded(!_expanded),
                radius: 22,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                  child: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_up_rounded,
                        size: 20, color: s.textMuted),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Text('EXIT NODE', style: s.label(color: s.textMuted)),
                const Spacer(),
                if (connected)
                  _Chip(
                    style: s,
                    label: 'Change Node',
                    fill: s.changeNodeFill,
                    border: s.changeNodeBorder,
                    textColor: s.changeNodeText,
                    onTap: widget.onChangeNode,
                  )
                else
                  _Chip(
                    style: s,
                    label: 'Add Exit Node',
                    icon: Icons.add,
                    fill: s.chipFill,
                    border: canAdd ? s.chipGreenBorder : s.chipBorder,
                    textColor: canAdd ? s.green : s.chipDisabledText,
                    onTap: canAdd ? widget.onAddExitNode : null,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _ExitNodeCard(
              style: s,
              phase: phase,
              onTap: idle
                  ? widget.onOpenExitNodes
                  : (connected ? widget.onChangeNode : null),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StatsRow(style: s, map: map),
                          const SizedBox(height: 18),
                          Text('PROTECTION', style: s.label(color: s.textMuted)),
                          const SizedBox(height: 12),
                          _ProtectionRows(style: s, editable: idle),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 12),
            _ConnectButton(
              style: s,
              phase: phase,
              busy: loader.isLoading,
              onTap: widget.onConnectToggle,
            ),
          ],
        ),
      ),
    );
  }
}

/// "+ Add Exit Node" / "Change Node".
class _Chip extends StatelessWidget {
  const _Chip({
    required this.style,
    required this.label,
    required this.fill,
    required this.border,
    required this.textColor,
    required this.onTap,
    this.icon,
  });

  final VpnHomeStyle style;
  final String label;
  final IconData? icon;
  final Color fill;
  final Color border;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: BorderSide(color: border, width: style.dark ? 1 : 1.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: textColor),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExitNodeCard extends StatelessWidget {
  const _ExitNodeCard({
    required this.style,
    required this.phase,
    required this.onTap,
  });

  final VpnHomeStyle style;
  final VpnMapPhase phase;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = style;
    final nodes = context.watch<NodeProvider>();
    final ip = context.watch<IpProvider>();
    final intro = context.watch<IntroStateProvider>();

    final country = intro.isCustomNode
        ? (ip.customNodeCountry ?? 'Fetching country…')
        : (nodes.selectedExitNodeCountry ?? 'France');
    final flagAsset = intro.isCustomNode
        ? countryCodeToFlag[ip.customCountryCode?.toUpperCase()]
        : 'assets/images/flags/${nodes.selectedExitNodeCountry ?? 'France'}.png';
    final node = nodes.selectedExitNodeName ?? 'exit.bdx';

    final (String? state, Color stateColor) = switch (phase) {
      VpnMapPhase.connecting => ('Connecting…', s.textMuted),
      VpnMapPhase.connected => ('Connected', s.green),
      VpnMapPhase.disconnecting => ('Disconnecting…', s.textMuted),
      _ => (null, s.textMuted),
    };
    final connected = phase == VpnMapPhase.connected;

    return Material(
      color: s.cardFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: BorderSide(
          color: connected ? s.cardConnectedBorder : s.cardBorder,
          width: connected ? 1.3 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 9, 12, 9),
          child: Row(
            children: [
              // Flag in a circle.
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: s.flagCircle,
                  shape: BoxShape.circle,
                  boxShadow: s.dark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1.5),
                  child: SizedBox(
                    width: 20,
                    height: 14,
                    child: flagAsset == null
                        ? Icon(Icons.public, size: 15, color: s.textMuted)
                        : Image.asset(
                            '$flagAsset',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Icon(
                                Icons.public,
                                size: 15,
                                color: s.textMuted),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: country),
                        if (state != null) ...[
                          const TextSpan(text: ' · '),
                          TextSpan(
                              text: state, style: TextStyle(color: stateColor)),
                        ],
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: s.body(size: 10, color: s.textMuted),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      node,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: s.body(size: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: onTap == null ? s.textFaint : s.text),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.style, required this.map});

  final VpnHomeStyle style;
  final VpnMapProvider map;

  @override
  Widget build(BuildContext context) {
    final s = style;
    final live = map.phase == VpnMapPhase.connected ||
        map.phase == VpnMapPhase.disconnecting;
    return ValueListenableBuilder<VpnLiveStats>(
      valueListenable: map.stats,
      builder: (context, stats, _) {
        final down = live ? splitBitRate(stats.downloadBytesPerSec) : null;
        final up = live ? splitBitRate(stats.uploadBytesPerSec) : null;
        final session =
            map.tunnelActive ? formatSessionClock(stats.connectedFor) : null;
        Widget divider() =>
            Container(width: 1, height: 34, color: s.divider);
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _Stat(
                  style: s,
                  icon: Icons.south_rounded,
                  iconColor: s.green,
                  label: 'DOWNLOAD',
                  value: down?.$1,
                  unit: down?.$2,
                ),
              ),
              divider(),
              const SizedBox(width: 14),
              Expanded(
                child: _Stat(
                  style: s,
                  icon: Icons.north_rounded,
                  iconColor: s.textMuted,
                  label: 'UPLOAD',
                  value: up?.$1,
                  unit: up?.$2,
                ),
              ),
              divider(),
              const SizedBox(width: 14),
              Expanded(
                child: _Stat(
                  style: s,
                  icon: Icons.schedule_rounded,
                  iconColor: s.textMuted,
                  label: 'SESSION',
                  value: session,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.style,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.unit,
  });

  final VpnHomeStyle style;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final s = style;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 5),
            Text(label, style: s.label(size: 8.5, color: s.textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: value ?? '—',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: s.text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (value != null && unit != null)
              TextSpan(
                text: ' $unit',
                style: s.mono(size: 9, color: s.textMuted),
              ),
          ]),
          maxLines: 1,
        ),
      ],
    );
  }
}

class _ProtectionRows extends StatelessWidget {
  const _ProtectionRows({required this.style, required this.editable});

  final VpnHomeStyle style;

  /// Toggles are shown while disconnected; while connected the settings
  /// apply to the running tunnel and are only reported (design).
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final s = style;
    final ads = context.watch<AdBlockerProvider>();
    final malware = context.watch<BlockMalwareProvider>();
    final blocked = ads.status?.sessionBlocked;
    return Column(
      children: [
        _ProtectionRow(
          style: s,
          icon: 'assets/images/light_theme/Ad Blocker.svg',
          title: 'Ad Blocker',
          on: ads.enabled,
          detail: ads.enabled && !editable && blocked != null
              ? '$blocked blocked this session'
              : 'ads & trackers',
          editable: editable,
          onChanged: (v) => ads.setEnabled(v),
        ),
        const SizedBox(height: 16),
        _ProtectionRow(
          style: s,
          icon: 'assets/images/light_theme/Block Malware.svg',
          title: 'Block Malware',
          on: malware.enabled,
          detail: 'malicious & phishing sites',
          editable: editable,
          onChanged: (v) => malware.setEnabled(v),
        ),
      ],
    );
  }
}

class _ProtectionRow extends StatelessWidget {
  const _ProtectionRow({
    required this.style,
    required this.icon,
    required this.title,
    required this.on,
    required this.detail,
    required this.editable,
    required this.onChanged,
  });

  final VpnHomeStyle style;
  final String icon;
  final String title;
  final bool on;
  final String detail;
  final bool editable;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = style;
    return Row(
      children: [
        SvgPicture.asset(
          icon,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(s.text, BlendMode.srcIn),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: s.body(size: 13.5)),
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: on ? 'On' : 'Off',
                    style: TextStyle(color: on ? s.green : s.textMuted),
                  ),
                  TextSpan(text: ' · $detail'),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: s.body(size: 10.5, color: s.textMuted),
              ),
            ],
          ),
        ),
        if (editable) _MiniSwitch(style: s, value: on, onChanged: onChanged),
      ],
    );
  }
}

/// Small pill switch.
class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({
    required this.style,
    required this.value,
    required this.onChanged,
  });

  final VpnHomeStyle style;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = style;
    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 34,
          height: 18,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: value ? s.green.withOpacity(0.18) : s.cardFill,
            border: Border.all(color: value ? s.green : s.cardBorder),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? s.green : s.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({
    required this.style,
    required this.phase,
    required this.busy,
    required this.onTap,
  });

  final VpnHomeStyle style;
  final VpnMapPhase phase;

  /// A connect/disconnect call is in flight.
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = style;
    late final String label;
    late final List<Color> fill;
    late final Color border;
    late final Color icon;
    var spinner = false;
    var enabled = true;
    var glow = true;
    switch (phase) {
      case VpnMapPhase.connected:
        label = 'DISCONNECT';
        fill = s.disconnectFill;
        border = s.disconnectBorder;
        icon = s.disconnectIcon;
        break;
      case VpnMapPhase.connecting:
      case VpnMapPhase.disconnecting:
        label = phase == VpnMapPhase.connecting
            ? 'CONNECTING'
            : 'DISCONNECTING';
        fill = [s.busyFill, s.busyFill];
        border = s.busyBorder;
        icon = s.text;
        spinner = true;
        enabled = false;
        glow = false;
        break;
      case VpnMapPhase.disconnected:
      case VpnMapPhase.failed:
        label = 'CONNECT';
        fill = s.connectFill;
        border = s.connectBorder;
        icon = s.connectIcon;
        enabled = !busy;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 51,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: fill),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: border, width: 1.2),
        // Only a faint 2-4 px halo around the border (design).
        boxShadow: glow
            ? [
                BoxShadow(
                  color: border.withOpacity(s.dark ? 0.10 : 0.12),
                  blurRadius: 5,
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (spinner)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: icon,
                  ),
                )
              else
                // Glowing power icon.
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: icon.withOpacity(0.45), blurRadius: 8),
                    ],
                  ),
                  child: Icon(Icons.power_settings_new_rounded,
                      size: 20, color: icon),
                ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3.5,
                  color: s.buttonText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bytes per second -> ("40.5", "Mb/s"); null -> null.
(String, String)? splitBitRate(int? bytesPerSec) {
  if (bytesPerSec == null) return null;
  final bits = bytesPerSec * 8.0;
  if (bits >= 1000000) return ((bits / 1000000).toStringAsFixed(1), 'Mb/s');
  if (bits >= 1000) return ((bits / 1000).toStringAsFixed(1), 'Kb/s');
  return (bits.toStringAsFixed(0), 'b/s');
}

/// Session clock "00:12:45" (hours always shown, as designed).
String? formatSessionClock(Duration? d) {
  if (d == null) return null;
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours;
  return '${two(h)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}
