import 'package:belnet_lib/belnet_lib.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Snapshot of the native Ad Blocker state (see BelnetLib.getAdBlockerStatus).
@immutable
class AdBlockerStatus {
  const AdBlockerStatus({
    required this.enabled,
    required this.filteringActive,
    required this.systemDnsProtected,
    required this.domains,
    required this.usingBuiltinList,
    required this.updating,
    required this.sessionBlocked,
    this.listsUpdatedAt,
    this.lastError,
    this.privateDnsMode,
    this.privateDnsActive = false,
  });

  /// User preference.
  final bool enabled;

  /// Enabled AND the tunnel's DNS currently flows through the filter.
  final bool filteringActive;

  /// This session announced BelNet's private DNS address to Android, so
  /// browsers' automatic Secure DNS cannot bypass the filter.
  final bool systemDnsProtected;

  /// Number of blocked domains in the active list.
  final int domains;

  /// Still on the small built-in list (no filter list downloaded yet).
  final bool usingBuiltinList;

  final bool updating;
  final int sessionBlocked;
  final DateTime? listsUpdatedAt;
  final String? lastError;

  /// Android Private DNS: "off", "opportunistic" or "hostname" (strict).
  final String? privateDnsMode;
  final bool privateDnsActive;

  /// Strict Private DNS sends all DNS encrypted to the chosen provider,
  /// around any DNS filter.
  bool get privateDnsBypass => privateDnsMode == 'hostname';

  static AdBlockerStatus fromMap(Map<String, dynamic> m) {
    int asInt(Object? v) => v is num ? v.toInt() : 0;
    final updated = asInt(m['listsUpdatedAt']);
    final error = m['lastError'];
    return AdBlockerStatus(
      enabled: m['enabled'] == true,
      filteringActive: m['filteringActive'] == true,
      systemDnsProtected: m['systemDnsProtected'] == true,
      domains: asInt(m['domains']),
      usingBuiltinList: m['usingBuiltinList'] == true,
      updating: m['updating'] == true,
      sessionBlocked: asInt(m['sessionBlocked']),
      listsUpdatedAt:
          updated > 0 ? DateTime.fromMillisecondsSinceEpoch(updated) : null,
      lastError: error is String && error.isNotEmpty ? error : null,
      privateDnsMode: m['privateDnsMode'] as String?,
      privateDnsActive: m['privateDnsActive'] == true,
    );
  }
}

/// Settings-side state of the Ad Blocker.
///
/// The native layer owns the preference (it must survive app restarts,
/// reboots and Android restarting the VPN service on its own). A copy is
/// kept in SharedPreferences only so the switch renders in the right
/// position before the first native round trip completes.
class AdBlockerProvider extends ChangeNotifier {
  static const String _mirrorKey = 'ad_blocker_enabled';

  bool _enabled = false;
  bool get enabled => _enabled;

  AdBlockerStatus? _status;
  AdBlockerStatus? get status => _status;

  bool _busy = false;

  /// A toggle is being applied.
  bool get busy => _busy;

  bool _disposed = false;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_mirrorKey) ?? false;
      _notify();
    } catch (_) {}
    await refreshStatus();
  }

  Future<void> refreshStatus() async {
    try {
      final map = await BelnetLib.getAdBlockerStatus();
      if (map.isEmpty) return;
      _apply(AdBlockerStatus.fromMap(map));
    } on PlatformException catch (_) {
      // Plugin not attached yet (e.g. very early in start-up): keep the
      // mirrored value; the settings tile polls again shortly.
    } on MissingPluginException catch (_) {}
  }

  /// Applies the preference natively (live, no reconnect). Returns false
  /// when the change could not be applied.
  Future<bool> setEnabled(bool value) async {
    if (_busy) return false;
    _busy = true;
    final previous = _enabled;
    _enabled = value; // optimistic: the switch moves immediately
    _notify();
    try {
      final map = await BelnetLib.setAdBlockerEnabled(value);
      if (map.isNotEmpty) {
        _apply(AdBlockerStatus.fromMap(map), fromToggle: true);
      } else {
        await _saveMirror(value);
      }
      return _enabled == value;
    } catch (_) {
      _enabled = previous;
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  /// Checks the filter lists for updates now.
  Future<void> refreshLists() async {
    try {
      await BelnetLib.refreshAdBlockerLists();
    } catch (_) {}
    await refreshStatus();
  }

  /// [fromToggle]: the status returned by [setEnabled]. A status poll that
  /// was issued before an in-flight toggle must not flip the switch back.
  void _apply(AdBlockerStatus s, {bool fromToggle = false}) {
    _status = s;
    if (fromToggle || !_busy) {
      _enabled = s.enabled;
      _saveMirror(s.enabled);
    }
    _notify();
  }

  Future<void> _saveMirror(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_mirrorKey) != value) {
        await prefs.setBool(_mirrorKey, value);
      }
    } catch (_) {}
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
