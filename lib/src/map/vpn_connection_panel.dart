import 'package:belnet_mobile/src/map/vpn_map_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Status chip shown at the top-left of the map.
class VpnMapStatusChip extends StatelessWidget {
  const VpnMapStatusChip({super.key, required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final phase = context.select<VpnMapProvider, VpnMapPhase>((p) => p.phase);
    final style = _PhaseStyle.of(phase, dark);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: dark ? const Color(0xCC1A1D22) : const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusDot(color: style.color, blinking: style.blinking),
          const SizedBox(width: 6),
          Icon(style.icon, size: 13, color: style.color),
          const SizedBox(width: 4),
          Text(
            style.chipLabel,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: style.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable connection information panel overlaid on the bottom of the
/// map: status, duration, exit node, original vs exit IP and location, and
/// live download / upload speed. Everything shown comes from real data;
/// unknown values are rendered as a dash.
class VpnConnectionPanel extends StatefulWidget {
  const VpnConnectionPanel({super.key, required this.dark});

  final bool dark;

  /// Height of the collapsed panel, used by the map to keep markers clear.
  static const double collapsedHeight = 60;

  @override
  State<VpnConnectionPanel> createState() => _VpnConnectionPanelState();
}

class _VpnConnectionPanelState extends State<VpnConnectionPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VpnMapProvider>();
    final dark = widget.dark;
    final style = _PhaseStyle.of(p.phase, dark);
    final fg = dark ? const Color(0xFFEBEBEB) : const Color(0xFF222222);
    final muted = dark ? const Color(0xFF9A9A9A) : const Color(0xFF6B6B6B);
    final bg = dark ? const Color(0xE6121418) : const Color(0xF2FFFFFF);

    final subtitle = switch (p.phase) {
      VpnMapPhase.failed => p.failureReason ?? 'Could not connect',
      VpnMapPhase.disconnected => p.originalIp != null
          ? 'Your IP ${p.originalIp} is visible'
          : 'Your IP address is visible',
      _ => p.exit.nodeName,
    };

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: style.color.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.35 : 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: style.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(style.icon, size: 16, color: style.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              style.title,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: style.color,
                              ),
                            ),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10.5,
                                  color: muted),
                            ),
                          ],
                        ),
                      ),
                      ValueListenableBuilder<VpnLiveStats>(
                        valueListenable: p.stats,
                        builder: (context, stats, _) => Text(
                          p.tunnelActive
                              ? formatConnectionDuration(stats.connectedFor)
                              : '',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: fg,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(Icons.keyboard_arrow_up,
                            size: 20, color: muted),
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 10),
                    Container(height: 1, color: muted.withOpacity(0.2)),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _InfoColumn(
                            heading: 'Original',
                            accent: dark
                                ? const Color(0xFF7FA8FF)
                                : const Color(0xFF3D6BE0),
                            ip: p.originalIp ??
                                (p.originalLocationLoading
                                    ? 'Detecting…'
                                    : '—'),
                            location: _originText(p),
                            fg: fg,
                            muted: muted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoColumn(
                            heading: 'VPN exit',
                            accent: style.exitAccent,
                            ip: p.exitIp ??
                                (p.phase == VpnMapPhase.connected
                                    ? 'Detecting…'
                                    : '—'),
                            location: _exitText(p),
                            fg: fg,
                            muted: muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<VpnLiveStats>(
                      valueListenable: p.stats,
                      builder: (context, stats, _) {
                        final live = p.phase == VpnMapPhase.connected ||
                            p.phase == VpnMapPhase.disconnecting;
                        return Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                icon: Icons.arrow_downward_rounded,
                                label: 'Download',
                                value: live
                                    ? formatBitRate(stats.downloadBytesPerSec)
                                    : '—',
                                fg: fg,
                                muted: muted,
                              ),
                            ),
                            Expanded(
                              child: _Metric(
                                icon: Icons.arrow_upward_rounded,
                                label: 'Upload',
                                value: live
                                    ? formatBitRate(stats.uploadBytesPerSec)
                                    : '—',
                                fg: fg,
                                muted: muted,
                              ),
                            ),
                            Expanded(
                              child: _Metric(
                                icon: Icons.timer_outlined,
                                label: 'Duration',
                                value: p.tunnelActive
                                    ? formatConnectionDuration(
                                        stats.connectedFor)
                                    : '—',
                                fg: fg,
                                muted: muted,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _Metric(
                      icon: Icons.dns_outlined,
                      label: 'Exit node',
                      value: p.exit.nodeName,
                      fg: fg,
                      muted: muted,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _originText(VpnMapProvider p) {
    final loc = p.originalLocation;
    if (loc != null && loc.displayName.isNotEmpty) return loc.displayName;
    if (p.originalLocationLoading) return 'Detecting…';
    if (p.originalLocationFailed) return 'Location unavailable';
    return '—';
  }

  String _exitText(VpnMapProvider p) {
    final loc = p.exit.location;
    if (loc != null && loc.displayName.isNotEmpty) {
      return p.exit.locationIsLastKnown
          ? '${loc.displayName} (last known)'
          : loc.displayName;
    }
    if (p.exit.country != null) return p.exit.country!;
    if (p.phase == VpnMapPhase.connected) return 'Detecting…';
    return '—';
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.heading,
    required this.accent,
    required this.ip,
    required this.location,
    required this.fg,
    required this.muted,
  });

  final String heading;
  final Color accent;
  final String ip;
  final String location;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              heading,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SelectableText(
          ip,
          maxLines: 1,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
        Text(
          location,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: muted),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.fg,
    required this.muted,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: muted),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 9.5, color: muted)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhaseStyle {
  const _PhaseStyle({
    required this.color,
    required this.exitAccent,
    required this.icon,
    required this.title,
    required this.chipLabel,
    required this.blinking,
  });

  final Color color;
  final Color exitAccent;
  final IconData icon;
  final String title;
  final String chipLabel;
  final bool blinking;

  static _PhaseStyle of(VpnMapPhase phase, bool dark) {
    final green = dark ? const Color(0xFF00DC00) : const Color(0xFF00B400);
    final amber = dark ? const Color(0xFFFFC94D) : const Color(0xFFD99A00);
    final red = dark ? const Color(0xFFFF5252) : const Color(0xFFE53935);
    final grey = dark ? const Color(0xFFACACAC) : const Color(0xFF6B6B6B);
    switch (phase) {
      case VpnMapPhase.connected:
        return _PhaseStyle(
          color: green,
          exitAccent: green,
          icon: Icons.verified_user_rounded,
          title: 'Protected',
          chipLabel: 'Connected',
          blinking: false,
        );
      case VpnMapPhase.connecting:
        return _PhaseStyle(
          color: amber,
          exitAccent: green,
          icon: Icons.sync_rounded,
          title: 'Connecting…',
          chipLabel: 'Connecting',
          blinking: true,
        );
      case VpnMapPhase.disconnecting:
        return _PhaseStyle(
          color: amber,
          exitAccent: green,
          icon: Icons.power_settings_new_rounded,
          title: 'Disconnecting…',
          chipLabel: 'Disconnecting',
          blinking: true,
        );
      case VpnMapPhase.failed:
        return _PhaseStyle(
          color: red,
          exitAccent: red,
          icon: Icons.error_outline_rounded,
          title: 'Connection failed',
          chipLabel: 'Failed',
          blinking: false,
        );
      case VpnMapPhase.disconnected:
        return _PhaseStyle(
          color: grey,
          exitAccent: grey,
          icon: Icons.shield_outlined,
          title: 'Not protected',
          chipLabel: 'Disconnected',
          blinking: false,
        );
    }
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color, required this.blinking});

  final Color color;
  final bool blinking;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.blinking) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blinking && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.blinking && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.25).animate(_c),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
