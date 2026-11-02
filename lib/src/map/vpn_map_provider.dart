import 'dart:async';
import 'dart:convert';

import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/node_provider.dart';
import 'package:belnet_mobile/src/map/geo_location.dart';
import 'package:belnet_mobile/src/map/world_map_data.dart'
    show normalizeCountryKey;
import 'package:belnet_mobile/src/providers/internet_checking_provider.dart';
import 'package:belnet_mobile/src/providers/introstate_provider.dart';
import 'package:belnet_mobile/src/providers/ip_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/vpn_controller.dart' show ConnectionStatus;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Connection phase as shown on the map. Derived from the real tunnel state
/// ([LoaderVideoProvider.conStatus], which vpn_controller only sets from
/// daemon status polling) plus two transient phases the existing
/// three-value enum cannot express: [disconnecting] and [failed].
enum VpnMapPhase { disconnected, connecting, connected, disconnecting, failed }

/// The default BelNet exit node and where it is hosted.
const String kDefaultExitNodeName = 'exit.bdx';
const GeoLocation kDefaultExitNodeLocation = GeoLocation(
  latitude: 48.5848,
  longitude: 7.7419,
  city: 'Strasbourg',
  country: 'France',
  countryCode: 'FR',
  source: GeoLocationSource.builtInDefault,
);

/// Exit server currently selected (and, while connected, in use).
@immutable
class ExitServerInfo {
  const ExitServerInfo({
    required this.nodeName,
    required this.isCustom,
    this.location,
    this.country,
    this.locationIsLastKnown = false,
  });

  /// BNS name / address of the exit node (e.g. exit.bdx).
  final String nodeName;

  /// User-added exit node that is not in the published list.
  final bool isCustom;

  /// Where the exit is, or null when no coordinates are known yet.
  final GeoLocation? location;

  /// Best known country name, even when coordinates are missing.
  final String? country;

  /// [location] is the position measured the last time this exit node was
  /// used (custom nodes), shown until this session's lookup completes.
  final bool locationIsLastKnown;

  @override
  bool operator ==(Object other) =>
      other is ExitServerInfo &&
      other.nodeName == nodeName &&
      other.isCustom == isCustom &&
      other.location == location &&
      other.country == country &&
      other.locationIsLastKnown == locationIsLastKnown;

  @override
  int get hashCode =>
      Object.hash(nodeName, isCustom, location, country, locationIsLastKnown);
}

/// Live numbers for the connection panel. Null means "not available" and
/// is rendered as a dash - values are never invented.
@immutable
class VpnLiveStats {
  const VpnLiveStats({
    this.uploadBytesPerSec,
    this.downloadBytesPerSec,
    this.connectedFor,
  });

  static const VpnLiveStats empty = VpnLiveStats();

  final int? uploadBytesPerSec;
  final int? downloadBytesPerSec;
  final Duration? connectedFor;

  @override
  bool operator ==(Object other) =>
      other is VpnLiveStats &&
      other.uploadBytesPerSec == uploadBytesPerSec &&
      other.downloadBytesPerSec == downloadBytesPerSec &&
      other.connectedFor == connectedFor;

  @override
  int get hashCode =>
      Object.hash(uploadBytesPerSec, downloadBytesPerSec, connectedFor);
}

/// State for the interactive VPN world map and its connection panel.
///
/// It does not own any connection logic: it observes the existing
/// providers and is told about the two transitions they do not model
/// ([markDisconnecting], [markFailed]) by vpn_controller.
class VpnMapProvider extends ChangeNotifier {
  VpnMapProvider({
    required LoaderVideoProvider loader,
    required NodeProvider nodes,
    required IpProvider ip,
    required IntroStateProvider intro,
    ConnectivityProvider? connectivity,
    Stream<Map<String, dynamic>> Function()? statusStream,
    DateTime Function()? clock,
    this.failureDisplayDuration = const Duration(seconds: 5),
  })  : _loader = loader,
        _nodes = nodes,
        _ip = ip,
        _intro = intro,
        _connectivity = connectivity,
        _statusStreamFactory = statusStream ?? (() => BelnetLib.statusStream),
        _clock = clock ?? DateTime.now {
    _loader.addListener(_sync);
    _nodes.addListener(_sync);
    _ip.addListener(_sync);
    _intro.addListener(_sync);
    _connectivity?.addListener(_onConnectivityChanged);
    _sync();
    unawaited(_loadLastKnownExits());
  }

  final LoaderVideoProvider _loader;
  final NodeProvider _nodes;
  final IpProvider _ip;
  final IntroStateProvider _intro;
  final ConnectivityProvider? _connectivity;
  final Stream<Map<String, dynamic>> Function() _statusStreamFactory;
  final DateTime Function() _clock;

  /// How long the FAILED phase stays on screen before the map returns to
  /// its disconnected state.
  final Duration failureDisplayDuration;

  VpnMapPhase _phase = VpnMapPhase.disconnected;
  VpnMapPhase get phase => _phase;

  String? _failureReason;
  String? get failureReason => _failureReason;
  Timer? _failureTimer;

  bool _disconnectRequested = false;

  /// Exit IP geolocation of exit nodes that have no published coordinates
  /// (custom nodes), keyed by lower-case node name. Persisted so the map can
  /// show the server's country immediately on the next connection.
  static const _lastKnownExitKey = 'vpn_map_last_known_exit_locations';
  static const _lastKnownExitLimit = 20;
  final Map<String, GeoLocation> _lastKnownExit = {};

  ExitServerInfo _exit = const ExitServerInfo(
    nodeName: kDefaultExitNodeName,
    isCustom: false,
  );
  ExitServerInfo get exit => _exit;

  GeoLocation? _origin;

  /// Approximate location of the user's real public IP.
  GeoLocation? get originalLocation => _origin;
  bool get originalLocationLoading => _ip.originalLocationLoading;
  bool get originalLocationFailed => _ip.originalLocationFailed;

  String? _originalIp;
  String? get originalIp => _originalIp;

  String? _exitIp;

  /// Public IP seen through the tunnel; null until it has been measured.
  String? get exitIp => _exitIp;

  /// True while the tunnel exists (connecting, up, or tearing down).
  bool get tunnelActive =>
      _phase == VpnMapPhase.connecting ||
      _phase == VpnMapPhase.connected ||
      _phase == VpnMapPhase.disconnecting;

  // ---------------------------------------------------------------------
  // Live statistics (separate notifier: changes every second and must not
  // rebuild the map itself).
  final ValueNotifier<VpnLiveStats> _stats =
      ValueNotifier<VpnLiveStats>(VpnLiveStats.empty);
  ValueListenable<VpnLiveStats> get stats => _stats;

  bool _mapVisible = false;
  StreamSubscription<Map<String, dynamic>>? _statusSub;
  Timer? _durationTimer;
  DateTime? _connectedSince;
  bool _awaitingDaemonUptime = false;
  bool _connectingFromConnected = false;
  int? _uploadBps;
  int? _downloadBps;
  bool _disposed = false;

  /// Called by the map widget when it becomes visible / hidden (tab change,
  /// app backgrounded). Live polling only runs while someone is looking.
  void setMapVisible(bool visible) {
    if (_mapVisible == visible) return;
    _mapVisible = visible;
    if (visible) {
      // Retry the original-location lookup if it failed earlier (e.g. the
      // app was started offline). No-op when already known.
      unawaited(_ip.ensureOriginalLocation());
    }
    _updateLiveFeed();
  }

  /// vpn_controller: a user-initiated disconnect has started.
  void markDisconnecting() {
    _disconnectRequested = true;
    _sync();
  }

  /// vpn_controller: the disconnect call returned without stopping the
  /// tunnel, so the previous phase is still accurate.
  void cancelDisconnecting() {
    _disconnectRequested = false;
    _sync();
  }

  /// vpn_controller: a connection attempt failed. The map shows the error
  /// for [failureDisplayDuration], then restores the disconnected view.
  void markFailed(String reason) {
    _failureReason = reason;
    _failureTimer?.cancel();
    _failureTimer = Timer(failureDisplayDuration, () {
      _failureReason = null;
      _failureTimer = null;
      _sync(force: true);
    });
    _sync(force: true);
  }

  void _onConnectivityChanged() {
    if (_connectivity?.isConnected == true) {
      unawaited(_ip.ensureOriginalLocation());
    }
  }

  void _sync({bool force = false}) {
    if (_disposed) return;
    final status = _loader.conStatus;

    // A new attempt supersedes a displayed failure.
    if (_failureReason != null && status == ConnectionStatus.CONNECTING) {
      _failureReason = null;
      _failureTimer?.cancel();
      _failureTimer = null;
    }
    if (_disconnectRequested && status == ConnectionStatus.DISCONNECTED) {
      _disconnectRequested = false;
    }

    final VpnMapPhase next;
    if (_failureReason != null && status != ConnectionStatus.CONNECTED) {
      next = VpnMapPhase.failed;
    } else if (_disconnectRequested) {
      next = VpnMapPhase.disconnecting;
    } else {
      next = switch (status) {
        ConnectionStatus.CONNECTED => VpnMapPhase.connected,
        ConnectionStatus.CONNECTING => VpnMapPhase.connecting,
        ConnectionStatus.DISCONNECTED => VpnMapPhase.disconnected,
      };
    }

    final previous = _phase;
    var changed = force || next != previous;
    if (next != previous) _onPhaseChange(previous, next);
    _phase = next;

    final origin = _ip.originalLocation;
    final originalIp =
        IpProvider.isKnownIp(_ip.realIp) ? _ip.realIp : origin?.ip;
    final exitIp = (next == VpnMapPhase.connected ||
                next == VpnMapPhase.disconnecting ||
                (next == VpnMapPhase.connecting && _connectingFromConnected)) &&
            IpProvider.isKnownIp(_ip.currentIPv4)
        ? _ip.currentIPv4
        : null;
    final exit = _resolveExit();

    if (origin != _origin ||
        originalIp != _originalIp ||
        exitIp != _exitIp ||
        exit != _exit) {
      changed = true;
    }
    _origin = origin;
    _originalIp = originalIp;
    _exitIp = exitIp;
    _exit = exit;

    _updateLiveFeed();
    if (changed) notifyListeners();
  }

  void _onPhaseChange(VpnMapPhase from, VpnMapPhase to) {
    switch (to) {
      case VpnMapPhase.connecting:
        // Exit-node swap: the tunnel stays up while the exit is remapped.
        _connectingFromConnected = from == VpnMapPhase.connected ||
            (from == VpnMapPhase.connecting && _connectingFromConnected);
        if (!_connectingFromConnected) _resetSession();
        break;
      case VpnMapPhase.connected:
        if (_connectedSince == null) {
          if (from == VpnMapPhase.connecting && !_connectingFromConnected) {
            _connectedSince = _clock();
            _awaitingDaemonUptime = false;
          } else {
            // Tunnel was already up when the app (re)attached to it: take
            // the duration from the daemon's own uptime when it arrives.
            _awaitingDaemonUptime = true;
          }
        }
        _connectingFromConnected = false;
        break;
      case VpnMapPhase.disconnecting:
        // Keep the session numbers until the tunnel is really gone.
        break;
      case VpnMapPhase.disconnected:
      case VpnMapPhase.failed:
        _connectingFromConnected = false;
        _resetSession();
        break;
    }
  }

  void _resetSession() {
    _connectedSince = null;
    _awaitingDaemonUptime = false;
    _uploadBps = null;
    _downloadBps = null;
    _stats.value = VpnLiveStats.empty;
  }

  ExitServerInfo _resolveExit() {
    final selected = (_nodes.selectedExitNodeName ?? '').trim();
    final nodeName = selected.isEmpty ? kDefaultExitNodeName : selected;
    final isCustom = _intro.isCustomNode;
    // The exit IP's geolocation only describes the exit while the tunnel is
    // up; IpProvider clears it on disconnect. During an exit swap it still
    // describes the PREVIOUS exit until the swap completes, so ignore it.
    final swapping =
        _phase == VpnMapPhase.connecting && _connectingFromConnected;
    final ipGeo = swapping ? null : _ip.exitLocation;
    final nodeKey = nodeName.toLowerCase();
    var lastKnown = false;

    GeoLocation? location;
    if (!isCustom) {
      final meta =
          _nodes.findNodeMetadata(id: _nodes.selectedNodeId, name: nodeName);
      if (meta != null) {
        final lat = parseGeoDouble(meta['lat'] ?? meta['latitude']);
        final lon = parseGeoDouble(
            meta['long'] ?? meta['lng'] ?? meta['lon'] ?? meta['longitude']);
        if (lat != null && lon != null) {
          final candidate = GeoLocation(
            latitude: lat,
            longitude: lon,
            city: parseGeoString(meta['city']),
            country: parseGeoString(meta['country']) ??
                parseGeoString(_nodes.selectedExitNodeCountry),
            countryCode: parseGeoString(meta['country_code'] ?? meta['code'])
                ?.toUpperCase(),
            source: GeoLocationSource.nodeMetadata,
          );
          if (candidate.hasCoordinates) location = candidate;
        }
      }
      if (location == null &&
          nodeName.toLowerCase() == kDefaultExitNodeName) {
        location = kDefaultExitNodeLocation;
      }
    }

    if (ipGeo != null && ipGeo.hasCoordinates) {
      if (location == null) {
        // Custom exit (or a listed node without coordinates): the exit IP's
        // geolocation is the only position we have.
        location = ipGeo;
        if (_phase == VpnMapPhase.connected) _rememberExit(nodeKey, ipGeo);
      } else if (location.city == null && _sameCountry(location, ipGeo)) {
        location = location.copyWith(city: ipGeo.city, region: ipGeo.region);
      }
    }

    if (location == null && (isCustom || tunnelActive)) {
      final remembered = _lastKnownExit[nodeKey];
      if (remembered != null) {
        location = remembered;
        lastKnown = true;
      }
    }

    final country = location?.country ??
        (isCustom
            ? parseGeoString(_ip.customNodeCountry)
            : parseGeoString(_nodes.selectedExitNodeCountry));

    return ExitServerInfo(
      nodeName: nodeName,
      isCustom: isCustom,
      location: location,
      country: country,
      locationIsLastKnown: lastKnown,
    );
  }

  void _rememberExit(String nodeKey, GeoLocation geo) {
    if (_lastKnownExit[nodeKey] == geo) return;
    _lastKnownExit.remove(nodeKey); // re-insert as most recent
    _lastKnownExit[nodeKey] = geo;
    while (_lastKnownExit.length > _lastKnownExitLimit) {
      _lastKnownExit.remove(_lastKnownExit.keys.first);
    }
    unawaited(_saveLastKnownExits());
  }

  Future<void> _loadLastKnownExits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_lastKnownExitKey);
      if (raw == null || raw.isEmpty || _disposed) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      decoded.forEach((key, value) {
        final geo = GeoLocation.fromJson(value);
        if (geo != null && geo.hasCoordinates) {
          _lastKnownExit.putIfAbsent(key.toString(), () => geo);
        }
      });
      _sync(force: true);
    } catch (_) {
      // Corrupt cache: ignore, it is only an optimisation.
    }
  }

  Future<void> _saveLastKnownExits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _lastKnownExitKey,
        jsonEncode(_lastKnownExit.map((k, v) => MapEntry(k, v.toJson()))),
      );
    } catch (_) {}
  }

  static bool _sameCountry(GeoLocation a, GeoLocation b) {
    final ca = a.countryCode, cb = b.countryCode;
    if (ca != null && cb != null) return ca.toUpperCase() == cb.toUpperCase();
    final na = a.country, nb = b.country;
    if (na == null || nb == null) return false;
    return normalizeCountryKey(na) == normalizeCountryKey(nb);
  }

  // ---------------------------------------------------------------------
  // Live feed

  void _updateLiveFeed() {
    final want = _mapVisible && !_disposed && tunnelActive;
    if (want && _statusSub == null) {
      _statusSub = _statusStreamFactory().listen(
        _onStatus,
        onError: (Object _) {},
      );
      _durationTimer =
          Timer.periodic(const Duration(seconds: 1), (_) => _publishStats());
      _publishStats();
    } else if (!want && _statusSub != null) {
      _statusSub?.cancel();
      _statusSub = null;
      _durationTimer?.cancel();
      _durationTimer = null;
      if (!tunnelActive) _stats.value = VpnLiveStats.empty;
    }
  }

  void _onStatus(Map<String, dynamic> payload) {
    if (_disposed) return;
    if (_phase == VpnMapPhase.connected) {
      _uploadBps = _asInt(payload['upload']);
      _downloadBps = _asInt(payload['download']);
    }
    if (_awaitingDaemonUptime && _connectedSince == null) {
      final status = payload['status'];
      if (status is Map) {
        // Daemon uptime is reported in milliseconds.
        final uptimeMs = _asInt(status['uptime']);
        if (uptimeMs != null &&
            uptimeMs > 0 &&
            uptimeMs < const Duration(days: 365).inMilliseconds) {
          _connectedSince =
              _clock().subtract(Duration(milliseconds: uptimeMs));
          _awaitingDaemonUptime = false;
        }
      }
    }
    _publishStats();
  }

  void _publishStats() {
    if (_disposed) return;
    final since = _connectedSince;
    Duration? duration;
    if (since != null) {
      final d = _clock().difference(since);
      duration = d.isNegative ? Duration.zero : d;
    }
    _stats.value = VpnLiveStats(
      uploadBytesPerSec: _uploadBps,
      downloadBytesPerSec: _downloadBps,
      connectedFor: duration,
    );
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _loader.removeListener(_sync);
    _nodes.removeListener(_sync);
    _ip.removeListener(_sync);
    _intro.removeListener(_sync);
    _connectivity?.removeListener(_onConnectivityChanged);
    _failureTimer?.cancel();
    _statusSub?.cancel();
    _durationTimer?.cancel();
    _stats.dispose();
    super.dispose();
  }
}

/// "12.4 Mb/s" / "830.0 Kb/s" from bytes per second; null -> dash.
String formatBitRate(int? bytesPerSec) {
  if (bytesPerSec == null) return '—';
  final bits = bytesPerSec * 8.0;
  if (bits >= 1000000) return '${(bits / 1000000).toStringAsFixed(2)} Mb/s';
  if (bits >= 1000) return '${(bits / 1000).toStringAsFixed(1)} Kb/s';
  return '${bits.toStringAsFixed(0)} b/s';
}

/// "05:42" / "1:02:09" / "2d 03:10:00"; null -> dash.
String formatConnectionDuration(Duration? d) {
  if (d == null) return '—';
  String two(int n) => n.toString().padLeft(2, '0');
  final days = d.inDays;
  final h = d.inHours % 24;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (days > 0) return '${days}d ${two(h)}:${two(m)}:${two(s)}';
  if (d.inHours > 0) return '${d.inHours}:${two(m)}:${two(s)}';
  return '${two(m)}:${two(s)}';
}
