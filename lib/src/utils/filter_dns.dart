/// Upstream DNS servers used by the Settings filtering toggles.
class FilterDns {
  FilterDns._();

  /// AdGuard DNS (default): blocks ads, trackers and phishing.
  static const String adBlocker = '94.140.14.14';

  /// Cloudflare 1.1.1.1 for Families: blocks malware and adult content.
  static const String blockMalware = '1.1.1.3';

  /// Used when no DNS was given and no filtering toggle is on.
  static const String fallback = '9.9.9.9';

  /// The upstream DNS to pass with the exit node when connecting.
  ///
  /// * Block malware on -> Cloudflare for Families, also when the Ad Blocker
  ///   is on (AdGuard DNS does not block adult content). Ads are then still
  ///   blocked by the Ad Blocker's own lists on the device.
  /// * Only Ad Blocker on -> AdGuard DNS.
  /// * Neither -> the DNS that was requested (e.g. a custom exit node's
  ///   choice), or the usual default.
  static String select({
    required bool adBlocker,
    required bool blockMalware,
    String? requested,
  }) {
    if (blockMalware) return FilterDns.blockMalware;
    if (adBlocker) return FilterDns.adBlocker;
    final r = requested?.trim();
    return r != null && r.isNotEmpty ? r : fallback;
  }
}
