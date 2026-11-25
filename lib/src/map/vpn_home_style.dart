import 'package:flutter/material.dart';

/// Colours and type of the V3 home screen (header, map, status block,
/// exit-node panel, bottom bar). Values are sampled from the V3 design
/// (dark and light).
@immutable
class VpnHomeStyle {
  const VpnHomeStyle._({
    required this.dark,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.background,
    required this.headerBackground,
    required this.mapCenter,
    required this.mapEdge,
    required this.panel,
    required this.panelTopLine,
    required this.labelColor,
    required this.green,
    required this.red,
    required this.amber,
    required this.cardFill,
    required this.cardBorder,
    required this.cardConnectedBorder,
    required this.flagCircle,
    required this.chipFill,
    required this.chipBorder,
    required this.chipGreenBorder,
    required this.chipDisabledText,
    required this.changeNodeFill,
    required this.changeNodeBorder,
    required this.changeNodeText,
    required this.connectFill,
    required this.connectBorder,
    required this.connectIcon,
    required this.disconnectFill,
    required this.disconnectBorder,
    required this.disconnectIcon,
    required this.busyFill,
    required this.busyBorder,
    required this.buttonText,
    required this.divider,
    required this.controlFill,
    required this.controlBorder,
    required this.controlIcon,
    required this.themeToggleFill,
    required this.navBar,
    required this.navItem,
    required this.navIcon,
  });

  final bool dark;
  final Color text;
  final Color textMuted;
  final Color textFaint;

  /// Page behind the panel and the bottom bar.
  final Color background;
  final Color headerBackground;

  /// Radial glow behind the map / globe: centre and edges.
  final Color mapCenter;
  final Color mapEdge;

  final Color panel;
  final Color panelTopLine;
  final Color labelColor;

  final Color green;
  final Color red;
  final Color amber;

  final Color cardFill;
  final Color cardBorder;
  final Color cardConnectedBorder;
  final Color flagCircle;

  final Color chipFill;
  final Color chipBorder;
  final Color chipGreenBorder;
  final Color chipDisabledText;
  final Color changeNodeFill;
  final Color changeNodeBorder;
  final Color changeNodeText;

  /// Main button: gradient left -> right, border, icon colour.
  final List<Color> connectFill;
  final Color connectBorder;
  final Color connectIcon;
  final List<Color> disconnectFill;
  final Color disconnectBorder;
  final Color disconnectIcon;
  final Color busyFill;
  final Color busyBorder;
  final Color buttonText;

  final Color divider;

  final Color controlFill;
  final Color controlBorder;
  final Color controlIcon;
  final Color themeToggleFill;

  final Color navBar;
  final Color navItem;
  final Color navIcon;

  static const VpnHomeStyle darkStyle = VpnHomeStyle._(
    dark: true,
    text: Color(0xFFF2F2F2),
    textMuted: Color(0xFF8D8D8D),
    textFaint: Color(0xFF4E4E4E),
    background: Color(0xFF0F0F0F),
    headerBackground: Color(0xFF0E0E0E),
    mapCenter: Color(0xFF1A1A1A),
    mapEdge: Color(0xFF0D0D0D),
    panel: Color(0xFF161616),
    panelTopLine: Color(0xFF222222),
    labelColor: Color(0xFFD0D0D0),
    green: Color(0xFF00DB00),
    red: Color(0xFFFF3D00),
    amber: Color(0xFFFFC94D),
    cardFill: Color(0xFF1B1B1B),
    cardBorder: Color(0xFF2E2E2E),
    cardConnectedBorder: Color(0xFF1FA51F),
    flagCircle: Color(0xFF262626),
    chipFill: Color(0xFF1C1C1C),
    chipBorder: Color(0xFF2E2E2E),
    chipGreenBorder: Color(0xFF2E2E2E),
    chipDisabledText: Color(0xFF4A4A4A),
    changeNodeFill: Color(0xFF1A1A1A),
    changeNodeBorder: Color(0xFF2E2E2E),
    changeNodeText: Color(0xFFF2F2F2),
    // Sampled: brighter at the left edge, darkest in the middle.
    connectFill: [Color(0xFF0D420D), Color(0xFF0E230E), Color(0xFF0F2D0F)],
    connectBorder: Color(0xFF0BBF0B),
    connectIcon: Color(0xFF19E619),
    disconnectFill: [Color(0xFF5A1F0C), Color(0xFF24130F), Color(0xFF2E160F)],
    disconnectBorder: Color(0xFFC4380A),
    disconnectIcon: Color(0xFFFF4A12),
    busyFill: Color(0xFF1B1B1B),
    busyBorder: Color(0xFF5E5E5E),
    buttonText: Color(0xFFF2F2F2),
    divider: Color(0xFF2A2A2A),
    controlFill: Color(0xFF1A1A1A),
    controlBorder: Color(0xFF2E2E2E),
    controlIcon: Color(0xFFE0E0E0),
    themeToggleFill: Color(0xFF1C1C1C),
    navBar: Color(0xFF1C1C1C),
    navItem: Color(0xFF2B2B2B),
    navIcon: Color(0xFF9E9E9E),
  );

  static const VpnHomeStyle lightStyle = VpnHomeStyle._(
    dark: false,
    text: Color(0xFF151515),
    textMuted: Color(0xFF6E6E6E),
    textFaint: Color(0xFFBDBDBD),
    background: Color(0xFFF8F8F8),
    headerBackground: Color(0xFFEAEAEA),
    mapCenter: Color(0xFFF8F8F8),
    mapEdge: Color(0xFFDCDCDC),
    panel: Color(0xFFF8F8F8),
    panelTopLine: Color(0xFFE2E2E2),
    labelColor: Color(0xFF2A2A2A),
    green: Color(0xFF00B800),
    red: Color(0xFFFF3D00),
    amber: Color(0xFFD99A00),
    cardFill: Color(0xFFFCFCFC),
    cardBorder: Color(0xFFE3E3E3),
    cardConnectedBorder: Color(0xFF7AD87A),
    flagCircle: Color(0xFFFFFFFF),
    chipFill: Color(0xFFFFFFFF),
    chipBorder: Color(0xFFDADADA),
    chipGreenBorder: Color(0xFF2EC42E),
    chipDisabledText: Color(0xFFC2C2C2),
    changeNodeFill: Color(0xFFFFFFFF),
    changeNodeBorder: Color(0xFF7AD87A),
    changeNodeText: Color(0xFF111111),
    connectFill: [Color(0xFFD4F3D4), Color(0xFFEAF9EA)],
    connectBorder: Color(0xFF2EC42E),
    connectIcon: Color(0xFF13C613),
    disconnectFill: [Color(0xFFFCD7CB), Color(0xFFFDEAE4)],
    disconnectBorder: Color(0xFFF2794F),
    disconnectIcon: Color(0xFFFF4A12),
    busyFill: Color(0xFFF8F8F8),
    busyBorder: Color(0xFFA8A8A8),
    buttonText: Color(0xFF151515),
    divider: Color(0xFFE0E0E0),
    controlFill: Color(0xFFF4F4F4),
    controlBorder: Color(0xFFE0E0E0),
    controlIcon: Color(0xFF1E1E1E),
    themeToggleFill: Color(0xFFD9D9D9),
    navBar: Color(0xFFEBEBEB),
    navItem: Color(0xFFDADADA),
    navIcon: Color(0xFF1E1E1E),
  );

  static VpnHomeStyle of(bool dark) => dark ? darkStyle : lightStyle;

  /// Panel background: dark fades from #161616 to the page colour so it
  /// meets the bottom bar area without an edge (design).
  Gradient get panelBackground => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark ? [panel, background] : [panel, panel],
      );

  /// Background behind the map / globe. Dark: an almost flat grey, a bit
  /// darker at the top and bottom (sampled #121212 / #191919 / #0d0d0d).
  /// Light: a soft white glow.
  Gradient get mapBackground => dark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Starts at the app-bar colour (#0e0e0e) so the bar and the map
          // blend with no edge, brightens to #1a1a1a, darkens at the bottom.
          colors: [
            Color(0xFF0E0E0E),
            Color(0xFF1A1A1A),
            Color(0xFF181818),
            Color(0xFF0A0A0A),
          ],
          stops: [0.0, 0.2, 0.62, 1.0],
        )
      : RadialGradient(
          center: const Alignment(0, -0.15),
          radius: 0.85,
          colors: [mapCenter, mapEdge],
        );

  /// Small upper-case monospace label ("EXIT NODE", "UNPROTECTED").
  TextStyle label({Color? color, double size = 8.5}) => TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: size,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w500,
        color: color ?? labelColor,
        height: 1.2,
      );

  /// Monospace detail line ("Your location · 152.58.158.87").
  TextStyle mono({Color? color, double size = 9.5}) => TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: size,
        letterSpacing: 0.2,
        color: color ?? textMuted,
        height: 1.3,
      );

  /// Big status title ("INDIA", "FINDING ROUTE").
  TextStyle title({double size = 19}) => TextStyle(
        fontFamily: 'Conthrax',
        fontSize: size,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w600,
        color: text,
        height: 1.15,
      );

  /// Regular UI text (Poppins, like the rest of the app).
  TextStyle body({Color? color, double size = 12, FontWeight? weight}) =>
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: size,
        fontWeight: weight,
        color: color ?? text,
        height: 1.3,
      );
}
