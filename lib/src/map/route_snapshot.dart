import 'dart:convert';

import 'package:belnet_mobile/src/map/ip_country_db.dart';
import 'package:flutter/foundation.dart';

/// One BelNet masternode on an onion path, as reported by the daemon.
@immutable
class RouteHop {
  const RouteHop({required this.router, this.ip, this.country});

  /// Router public key (hex) - the masternode's identity.
  final String router;

  /// Public IPv4 address of the masternode, when the daemon reports one.
  final String? ip;

  /// Country of [ip] from the offline database; null when unknown.
  final IpCountry? country;

  bool get hasLocation => country != null;

  @override
  bool operator ==(Object other) =>
      other is RouteHop &&
      other.router == router &&
      other.ip == ip &&
      other.country == country;

  @override
  int get hashCode => Object.hash(router, ip, country);
}

/// What the daemon's full status says about the onion route, reduced to
/// what the map needs.
@immutable
class RouteSnapshot {
  const RouteSnapshot({
    required this.activeHops,
    required this.knownHops,
    required this.routeReady,
    required this.activePathEstablished,
  });

  static const RouteSnapshot empty = RouteSnapshot(
    activeHops: [],
    knownHops: [],
    routeReady: false,
    activePathEstablished: false,
  );

  /// Hops of the path that carries (or will carry) traffic to the exit,
  /// first hop first.
  final List<RouteHop> activeHops;

  /// Every distinct masternode currently used by any path (includes
  /// [activeHops]).
  final List<RouteHop> knownHops;

  /// A session to the exit is established and ready to send.
  final bool routeReady;

  /// The active path finished building.
  final bool activePathEstablished;

  bool get hasHops => activeHops.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is RouteSnapshot &&
      other.routeReady == routeReady &&
      other.activePathEstablished == activePathEstablished &&
      listEquals(other.activeHops, activeHops) &&
      listEquals(other.knownHops, knownHops);

  @override
  int get hashCode => Object.hash(routeReady, activePathEstablished,
      Object.hashAll(activeHops), Object.hashAll(knownHops));

  /// Parses the JSON returned by `BelnetLib.getStatus()` (the daemon's
  /// `DumpStatus`, i.e. llarp Router::ExtractStatus):
  ///
  /// ```
  /// services.default.paths[]                 client paths
  /// services.default.remoteSessions[].paths[]  paths to the exit (.bdx)
  /// services.default.mnodeSessions[].paths[]
  ///   path: { status: building|established|..., hops: [{router, ip}] }
  /// ```
  ///
  /// Anything missing or malformed yields [empty]; nothing is invented.
  static RouteSnapshot fromStatus(Object? status, {IpCountryDb? db}) {
    if (status is! Map) return empty;
    final services = status['services'];
    if (services is! Map || services.isEmpty) return empty;
    Object? endpoint = services['default'];
    endpoint ??= services.values.firstWhere((v) => v is Map, orElse: () => null);
    if (endpoint is! Map) return empty;

    final exitPaths = <Map>[];
    var routeReady = false;
    for (final session in _list(endpoint['remoteSessions'])) {
      if (session is! Map) continue;
      if (session['readyToSend'] == true) routeReady = true;
      for (final p in _list(session['paths'])) {
        if (p is Map) exitPaths.add(p);
      }
    }
    final otherPaths = <Map>[
      for (final p in _list(endpoint['paths']))
        if (p is Map) p,
      for (final session in _list(endpoint['mnodeSessions']))
        if (session is Map)
          for (final p in _list(session['paths']))
            if (p is Map) p,
    ];

    Map? pick(List<Map> paths, String state) {
      for (final p in paths) {
        if (p['status'] == state && _list(p['hops']).isNotEmpty) return p;
      }
      return null;
    }

    final exitActive =
        pick(exitPaths, 'established') ?? pick(exitPaths, 'building');
    final active = exitActive ??
        pick(otherPaths, 'established') ??
        pick(otherPaths, 'building');

    final cache = <String, RouteHop>{};
    RouteHop? hopOf(Object? raw) {
      if (raw is! Map) return null;
      final router = raw['router']?.toString() ?? '';
      if (router.isEmpty) return null;
      final ipRaw = raw['ip']?.toString();
      final ip = (ipRaw == null || ipRaw.isEmpty) ? null : ipRaw;
      return cache.putIfAbsent(
        router,
        () => RouteHop(router: router, ip: ip, country: db?.lookup(ip)),
      );
    }

    final activeHops = <RouteHop>[];
    if (active != null) {
      for (final h in _list(active['hops'])) {
        final hop = hopOf(h);
        if (hop != null) activeHops.add(hop);
      }
    }
    final known = <String, RouteHop>{};
    for (final p in [...exitPaths, ...otherPaths]) {
      final state = p['status'];
      if (state != 'building' && state != 'established') continue;
      for (final h in _list(p['hops'])) {
        final hop = hopOf(h);
        if (hop != null) known.putIfAbsent(hop.router, () => hop);
      }
    }
    for (final h in activeHops) {
      known.putIfAbsent(h.router, () => h);
    }

    final established = active?['status'] == 'established';
    return RouteSnapshot(
      activeHops: List.unmodifiable(activeHops),
      knownHops: List.unmodifiable(known.values),
      // A finished path towards the exit counts as a found route even
      // before the session reports readyToSend.
      routeReady: routeReady || (established && exitActive != null),
      activePathEstablished: established,
    );
  }

  static List _list(Object? v) => v is List ? v : const [];
}

/// Decodes the daemon's full status JSON and keeps only what
/// [RouteSnapshot.fromStatus] reads (paths, their status and hops, and
/// whether exit sessions are ready). Top-level so it can run in `compute`:
/// the full dump can be large, and decoding it on the UI isolate every
/// second would make the globe stutter.
Map<String, dynamic>? pruneRouteStatus(String raw) {
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    return null;
  }
  if (decoded is! Map) return null;
  final services = decoded['services'];
  if (services is! Map) return null;
  Object? endpoint = services['default'];
  endpoint ??= services.values.firstWhere((v) => v is Map, orElse: () => null);
  if (endpoint is! Map) return null;

  List<Map<String, dynamic>> paths(Object? list) => [
        if (list is List)
          for (final p in list)
            if (p is Map)
              {
                'status': p['status']?.toString(),
                'hops': [
                  if (p['hops'] is List)
                    for (final h in p['hops'] as List)
                      if (h is Map)
                        {
                          'router': h['router']?.toString(),
                          'ip': h['ip']?.toString(),
                        },
                ],
              },
      ];

  List<Map<String, dynamic>> sessions(Object? list) => [
        if (list is List)
          for (final s in list)
            if (s is Map)
              {
                'readyToSend': s['readyToSend'] == true,
                'paths': paths(s['paths']),
              },
      ];

  return {
    'services': {
      'default': {
        'paths': paths(endpoint['paths']),
        'remoteSessions': sessions(endpoint['remoteSessions']),
        'mnodeSessions': sessions(endpoint['mnodeSessions']),
      },
    },
  };
}
