import 'package:belnet_lib/belnet_lib.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One filter list used by the Ad Blocker, as reported by the native side.
@immutable
class AdBlockerSource {
  const AdBlockerSource({
    required this.id,
    required this.name,
    required this.site,
    required this.status,
    required this.domains,
    this.state,
    this.percent = -1,
    this.updatedAt,
    this.error,
  });

  final String id;
  final String name;

  /// Where the list comes from, e.g. "github.com/hagezi" or "small.oisd.nl".
  final String site;

  /// Result of the last check: cached, fresh, updated, not_modified,
  /// failed or missing.
  final String status;

  /// While an update runs: "downloading" or "waiting"; otherwise null.
  final String? state;

  /// Download progress 0-100 while [downloading], or -1 if unknown.
  final int percent;

  /// Domains in the cached copy; 0 if not downloaded yet.
  final int domains;

  /// When the cached copy was last downloaded or confirmed unchanged.
  final DateTime? updatedAt;

  /// Error of the most recent failed download.
  final String? error;

  bool get downloading => state == 'downloading';
  bool get waiting => state == 'waiting';
  bool get downloaded => domains > 0;
  bool get failed => status == 'failed' || (error != null && error!.isNotEmpty);

  static AdBlockerSource fromMap(Map<String, dynamic> m) {
    int asInt(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
    final fetched = asInt(m['fetchedAt']);
    final error = m['error'];
    final state = m['state'];
    return AdBlockerSource(
      id: (m['id'] ?? '').toString(),
      name: (m['name'] ?? m['id'] ?? '').toString(),
      site: (m['site'] ?? '').toString(),
      status: (m['status'] ?? '').toString(),
      state: state is String && state.isNotEmpty ? state : null,
      percent: asInt(m['percent'], -1),
      domains: asInt(m['rules']),
      updatedAt: fetched > 0 ? DateTime.fromMillisecondsSinceEpoch(fetched) : null,
      error: error is String && error.isNotEmpty ? error : null,
    );
  }
}

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
    this.updateDone = 0,
    this.updateTotal = 0,
    this.sources = const [],
  });

  /// While lists are being updated: how many are done, out of how many.
  final int updateDone;
  final int updateTotal;

  /// The filter lists, in the order they are downloaded and applied.
  final List<AdBlockerSource> sources;

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
      updateDone: asInt(m['updateDone']),
      updateTotal: asInt(m['updateTotal']),
      sources: (m['sources'] is List)
          ? (m['sources'] as List)
              .whereType<Map>()
              .map((e) => AdBlockerSource.fromMap(e.cast<String, dynamic>()))
              .toList(growable: false)
          : const [],
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

  /// Saved preference read by [preload] before the app starts, so the
  /// switch is drawn in its real position on the very first frame instead
  /// of starting OFF and flipping once an async read completes.
  static bool _preloadedEnabled = false;

  /// Reads the saved preference. Call (and await) in main() before runApp.
  static Future<void> preload() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _preloadedEnabled = prefs.getBool(_mirrorKey) ?? false;
    } catch (_) {
      _preloadedEnabled = false;
    }
  }

  AdBlockerProvider() : _enabled = _preloadedEnabled;

  bool _enabled;
  bool get enabled => _enabled;

  AdBlockerStatus? _status;
  AdBlockerStatus? get status => _status;

  bool _busy = false;

  /// A toggle is being applied.
  bool get busy => _busy;

  bool _disposed = false;

  /// Syncs with the native state (the source of truth). The saved value is
  /// already in place from [preload], so nothing flips on screen unless the
  /// native state really differs.
  Future<void> load() async {
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

  /// Saves the preference natively; it is used from the next connection.
  /// The settings tile only allows this while BelNet is disconnected.
  /// Returns false when the change could not be applied.
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
