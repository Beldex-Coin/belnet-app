import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Thrown when the bootstrap router snapshot cannot be downloaded from any
/// seed URL. Surfaced to the UI so users get a clear message instead of a
/// silent connect failure.
class BootstrapException implements Exception {
  final String message;
  BootstrapException(this.message);

  @override
  String toString() => 'BootstrapException: $message';
}

class BelnetLib {
  static const MethodChannel _methodChannel =
      const MethodChannel('belnet_lib_method_channel');

  static const EventChannel _isConnectedEventChannel =
      const EventChannel('belnet_lib_is_connected_event_channel');


static const EventChannel disconnectEventChannel = EventChannel('belnet_lib_notification_disconnect_event_channel');

  static const EventChannel _networkChangeEventChannel =
      EventChannel('belnet_lib_network_change_event_channel');

  static Stream<void>? _networkChangeStream;

  /// Fires when the underlying (non-VPN) network changes, e.g. a
  /// Wi-Fi <-> mobile handover. Consumers should re-verify tunnel health.
  static Stream<void> get networkChangeStream =>
      _networkChangeStream ??= _networkChangeEventChannel
          .receiveBroadcastStream()
          .map((dynamic _) {});

  static const EventChannel _statusEventChannel =
      EventChannel('belnet_lib_status_event_channel');

  static Stream<Map<String, dynamic>>? _statusStreamBroadcast;
  static StreamSubscription<Map<String, dynamic>>? _statusFeedSub;
  static Map<String, dynamic>? _latestStatus;
  static DateTime? _latestStatusAt;
  static int _latestUploadBps = 0;
  static int _latestDownloadBps = 0;

  /// Consolidated 1 Hz status feed pushed from the native side. Payload:
  /// { "status": Map|null (daemon GetStatus JSON),
  ///   "upload": int, "download": int (bytes/sec),
  ///   "isRunning": bool }
  static Stream<Map<String, dynamic>> get statusStream {
    _statusStreamBroadcast ??= _statusEventChannel
        .receiveBroadcastStream()
        .map<Map<String, dynamic>>((dynamic event) =>
            (jsonDecode(event as String) as Map).cast<String, dynamic>())
        .asBroadcastStream();
    return _statusStreamBroadcast!;
  }

  /// Latest device throughput in bytes/sec from the native feed.
  static int get uploadBytesPerSec => _latestUploadBps;
  static int get downloadBytesPerSec => _latestDownloadBps;

  static void _ensureStatusFeed() {
    _statusFeedSub ??= statusStream.listen((payload) {
      final s = payload['status'];
      _latestStatus =
          s is Map ? s.cast<String, dynamic>() : null;
      _latestStatusAt = DateTime.now();
      _latestUploadBps = (payload['upload'] as num?)?.toInt() ?? 0;
      _latestDownloadBps = (payload['download'] as num?)?.toInt() ?? 0;
    }, onError: (Object _) {});
  }

  static bool _isConnected = false;

  static bool get isConnected => _isConnected;

  static Stream<bool> _isConnectedEventStream = _isConnectedEventChannel
      .receiveBroadcastStream()
      .cast<bool>()
    ..listen((dynamic newIsConnected) => _isConnected = newIsConnected);

  static Stream<bool> get isConnectedEventStream => _isConnectedEventStream;

  /// Seed URLs for the bootstrap router snapshot, tried in order.
  static const List<String> _bootstrapUrls = [
    'https://belnet-exitnode.s3.ap-south-1.amazonaws.com/bootstrap-files/bootstrap.signed',
    'https://deb.beldex.io/Beldex-projects/Belnet/bootstrap-files/bootstrap.signed',
  ];

  static const Duration _bootstrapFetchTimeout = Duration(seconds: 10);

  /// A bootstrap older than this is refreshed in the background: a stale
  /// router snapshot makes initial path building slow (dead routers must
  /// time out first) and can make first connects fail outright.
  static const Duration bootstrapMaxAge = Duration(days: 7);

  static Future<String> get _filesDir async {
    final path = await getApplicationDocumentsDirectory();
    return '${path.parent.path}/files';
  }

  /// Download the bootstrap file. Tries each seed URL with a timeout,
  /// downloads to a temp file and atomically renames over the live one, and
  /// records a freshness stamp. Throws [BootstrapException] if every URL
  /// fails - callers must surface this instead of failing silently.
  static Future<void> bootstrapBelnet() async {
    final dir = await _filesDir;
    final target = File('$dir/bootstrap.signed');
    final tmp = File('$dir/bootstrap.signed.tmp');
    Object? lastError;
    for (final url in _bootstrapUrls) {
      final client = HttpClient()..connectionTimeout = _bootstrapFetchTimeout;
      try {
        final request =
            await client.getUrl(Uri.parse(url)).timeout(_bootstrapFetchTimeout);
        final response = await request.close().timeout(_bootstrapFetchTimeout);
        if (response.statusCode != 200) {
          lastError = 'HTTP ${response.statusCode} from $url';
          continue;
        }
        await response.pipe(tmp.openWrite());
        if (tmp.lengthSync() == 0) {
          lastError = 'empty bootstrap from $url';
          continue;
        }
        tmp.renameSync(target.path);
        File('$dir/bootstrap.stamp')
            .writeAsStringSync('${DateTime.now().millisecondsSinceEpoch}');
        print('Successfully bootstrapped from $url');
        return;
      } catch (e) {
        lastError = e;
      } finally {
        client.close(force: true);
        if (tmp.existsSync()) {
          try {
            tmp.deleteSync();
          } catch (_) {}
        }
      }
    }
    throw BootstrapException('could not download bootstrap: $lastError');
  }

  /// True when the bootstrap file is younger than [bootstrapMaxAge].
  static Future<bool> get isBootstrapFresh async {
    final dir = await _filesDir;
    final stamp = File('$dir/bootstrap.stamp');
    if (!await isBootstrapped) return false;
    if (!stamp.existsSync()) return false;
    final ms = int.tryParse(stamp.readAsStringSync().trim()) ?? 0;
    return DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(ms)) <
        bootstrapMaxAge;
  }

  /// Best-effort refresh used at app startup and when the bootstrap is
  /// merely stale (not missing): never throws.
  static Future<void> refreshBootstrapIfStale() async {
    try {
      if (!(await isBootstrapFresh)) await bootstrapBelnet();
    } catch (e) {
      print('background bootstrap refresh failed: $e');
    }
  }

  static Future<bool> prepareConnection() async {
    if (!(await isBootstrapped)) {
      // Missing entirely: must succeed before connecting; errors propagate
      // (BootstrapException) so the UI can tell the user what went wrong.
      await bootstrapBelnet();
    } else if (!(await isBootstrapFresh)) {
      // Present but old: refresh in the background, connect with what we have.
      unawaited(refreshBootstrapIfStale());
    }
    final bool prepare = await _methodChannel.invokeMethod('prepare');
    return prepare;
  }

//conncting belnet
  static Future<bool> connectToBelnet(
      //"9.9.9.9"
      List<String> packageNames,
      {String exitNode =
          "exit.bdx",
      String upstreamDNS = "9.9.9.9",
      // Daemon log level. "warn" keeps logging off the packet path in
      // release; pass "info"/"debug" for troubleshooting.
      String logLevel = "warn",
      // TUN device MTU. 1500 is the historical value; lower values (1280 to
      // 1400) may avoid in-tunnel fragmentation - kept configurable for
      // benchmarking.
      int mtu = 1500,
      // Whether to claim the ::/0 route. Keeping it true prevents IPv6
      // leaks; the daemon logs whether IPv6 is actually carried.
      bool routeIpv6 = true}) async {
    final bool connect = await _methodChannel.invokeMethod('connect', {
      "exit_node": exitNode,
      "upstream_dns": upstreamDNS,
      "package_names": packageNames,
      "log_level": logLevel,
      "mtu": mtu,
      "route_ipv6": routeIpv6,
    });

    return connect;
  }

  static Future<bool> disconnectFromBelnet() async {
    final bool disconnect = await _methodChannel.invokeMethod('disconnect');

    return disconnect;
  }

// is prepared function
  static Future<bool> get isPrepared async {
    final bool prepared = await _methodChannel.invokeMethod('isPrepared');

    return prepared;
  }

  static Future<bool> get isRunning async {
    final bool isRunning = await _methodChannel.invokeMethod('isRunning');
    return isRunning;
  }

//isbootstrap function
  static Future<bool> get isBootstrapped async {
    final dir = await _filesDir;
    final f = File('$dir/bootstrap.signed');
    // Existence alone is not enough: a 0-byte file from an interrupted
    // download used to pass this check forever.
    return f.existsSync() && f.lengthSync() > 0;
  }

  static Future<dynamic> get status async {
    var status = await _methodChannel.invokeMethod('getStatus') as String;
    if (status.isNotEmpty) return jsonDecode(status);
    return null;
  }

  static Future<Map<String, dynamic>?> getStatus() async {
    var status = await _methodChannel.invokeMethod('getStatus') as String?;
    if (status != null && status.isNotEmpty) return jsonDecode(status);
    return null;
  }

  static Future<dynamic> get upload async {
    var uploadStatus = await _methodChannel.invokeMethod('getUploadSpeed');
    return uploadStatus;
  }

  static Future<dynamic> get download async {
    var downloadStatus = await _methodChannel.invokeMethod('getDownloadSpeed');
    return downloadStatus;
  }

  static Future<String> get logDetails async {
    var logD;
    // try{
    logD = await _methodChannel.invokeMethod("logData");

    print("this is from log data $logD");

    return logD;
  }

  static Future<Map<String, dynamic>?> get getSpeedStatus async {
    // Served from the consolidated 1 Hz native status feed when fresh, so
    // the many periodic consumers (charts, speed displays, connection
    // polling) share ONE platform-channel/JNI crossing per second instead
    // of one each. Falls back to a direct method call when the feed has no
    // recent data (e.g. right at startup).
    _ensureStatusFeed();
    final at = _latestStatusAt;
    if (at != null &&
        DateTime.now().difference(at) < const Duration(milliseconds: 1500)) {
      return _latestStatus;
    }
    // The native side returns null while the service is not bound yet
    // (e.g. during the first seconds of a connect), so never cast blindly.
    final status = await _methodChannel.invokeMethod('getDataStatus');
    if (status is String && status.isNotEmpty) {
      final decoded = jsonDecode(status);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    return null;
  }
static Future<dynamic>  unmapExitNode(String swapNode) async {
    final dynamic isUnmap = await _methodChannel.invokeMethod('getMap',{"swap_node": swapNode});
    return isUnmap;
  }

static Future<bool> isDisconnectForBelnetNotification() async {
    final bool disconnect = await _methodChannel.invokeMethod('disconnectForNotification');

    return disconnect;
  }

static Future<dynamic> getInstalledApps()async{
    final List<dynamic> result = await _methodChannel.invokeMethod('getInstalledAppsWithInternetPermission');
    return result;
}

}
