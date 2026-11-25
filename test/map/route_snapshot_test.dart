import 'dart:convert';

import 'package:belnet_mobile/src/map/ip_country_db.dart';
import 'package:belnet_mobile/src/map/route_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ip_country_db_test.dart' show buildTable;

/// A DumpStatus-shaped map (llarp Router::ExtractStatus).
Map<String, dynamic> dumpStatus({
  List<Map<String, dynamic>> paths = const [],
  List<Map<String, dynamic>> remoteSessions = const [],
}) =>
    {
      'running': true,
      'numNodesKnown': 412,
      'services': {
        'default': {
          'numHops': 4,
          'paths': paths,
          'remoteSessions': remoteSessions,
          'mnodeSessions': <Object>[],
        },
      },
    };

Map<String, dynamic> path(String status, List<(String, String)> hops) => {
      'status': status,
      'ready': status == 'established',
      'hops': [
        for (final h in hops) {'router': h.$1, 'ip': h.$2, 'lifetime': 600000},
      ],
    };

IpCountryDb testDb() => IpCountryDb.parse(buildTable(
      [
        ('DE', 51.2, 10.4, 'Germany'),
        ('NL', 52.1, 5.3, 'Netherlands'),
        ('FI', 61.9, 25.7, 'Finland'),
        ('US', 37.1, -95.7, 'United States'),
      ],
      [
        (0, 255),
        (0x05000000, 0), // 5.x DE
        (0x06000000, 255),
        (0x08000000, 3), // 8.x US
        (0x09000000, 255),
        (0x33000000, 1), // 51.x NL
        (0x34000000, 255),
        (0x5F000000, 2), // 95.x FI
        (0x60000000, 255),
      ],
    ));

void main() {
  final db = testDb();

  test('empty / malformed status gives no route', () {
    for (final s in <Object?>[
      null,
      'x',
      <String, dynamic>{},
      {'running': false},
      {'services': 'nope'},
      {'services': <String, dynamic>{}},
      dumpStatus(),
    ]) {
      final r = RouteSnapshot.fromStatus(s, db: db);
      expect(r.hasHops, isFalse, reason: '$s');
      expect(r.routeReady, isFalse);
    }
  });

  test('building client path: hops in order, located offline', () {
    final r = RouteSnapshot.fromStatus(
      dumpStatus(paths: [
        path('building', [
          ('aa', '::ffff:5.9.10.10'),
          ('bb', '51.15.0.1'),
          ('cc', '95.216.0.1'),
          ('dd', '10.0.0.1'), // unknown location
        ]),
      ]),
      db: db,
    );
    expect(r.hasHops, isTrue);
    expect(r.routeReady, isFalse);
    expect(r.activePathEstablished, isFalse);
    expect(r.activeHops.map((h) => h.router), ['aa', 'bb', 'cc', 'dd']);
    expect(r.activeHops.map((h) => h.country?.code), ['DE', 'NL', 'FI', null]);
    expect(r.knownHops.length, 4);
  });

  test('path to the exit is preferred and marks the route found', () {
    final r = RouteSnapshot.fromStatus(
      dumpStatus(
        paths: [
          path('established', [('aa', '5.1.1.1'), ('bb', '51.1.1.1')]),
          path('timeout', [('zz', '8.8.8.8')]),
        ],
        remoteSessions: [
          {
            'readyToSend': true,
            'remoteIdentity': 'exit.bdx',
            'paths': [
              path('established', [
                ('cc', '95.1.1.1'),
                ('dd', '8.8.8.8'),
                ('ee', '5.2.2.2'),
                ('ff', '51.2.2.2'),
              ]),
            ],
          },
        ],
      ),
      db: db,
    );
    expect(r.routeReady, isTrue);
    expect(r.activePathEstablished, isTrue);
    expect(r.activeHops.map((h) => h.router), ['cc', 'dd', 'ee', 'ff']);
    // Timed-out paths are not "in use".
    expect(r.knownHops.map((h) => h.router).toSet(),
        {'aa', 'bb', 'cc', 'dd', 'ee', 'ff'});
  });

  test('an established exit path counts even before readyToSend', () {
    final r = RouteSnapshot.fromStatus(
      dumpStatus(remoteSessions: [
        {
          'readyToSend': false,
          'paths': [
            path('established', [('aa', '5.1.1.1')]),
          ],
        },
      ]),
      db: db,
    );
    expect(r.routeReady, isTrue);
  });

  test('a building exit path is not a found route', () {
    final r = RouteSnapshot.fromStatus(
      dumpStatus(remoteSessions: [
        {
          'readyToSend': false,
          'paths': [
            path('building', [('aa', '5.1.1.1')]),
          ],
        },
      ]),
      db: db,
    );
    expect(r.hasHops, isTrue);
    expect(r.routeReady, isFalse);
  });

  test('works without the database (no locations)', () {
    final r = RouteSnapshot.fromStatus(
      dumpStatus(paths: [
        path('building', [('aa', '5.1.1.1')]),
      ]),
    );
    expect(r.hasHops, isTrue);
    expect(r.activeHops.single.country, isNull);
  });

  test('value equality', () {
    Map<String, dynamic> s() => dumpStatus(paths: [
          path('building', [('aa', '5.1.1.1'), ('bb', '51.1.1.1')]),
        ]);
    expect(RouteSnapshot.fromStatus(s(), db: db),
        RouteSnapshot.fromStatus(s(), db: db));
  });

  test('pruned status (background isolate) parses the same', () {
    final full = dumpStatus(
      paths: [
        path('building', [('aa', '5.1.1.1'), ('bb', '51.1.1.1')]),
      ],
      remoteSessions: [
        {
          'readyToSend': true,
          'estimatedRTT': 120,
          'paths': [
            path('established', [('cc', '95.1.1.1'), ('dd', '8.8.8.8')]),
          ],
        },
      ],
    )
      ..['dht'] = {'nodes': List.filled(50, 'x')}
      ..['links'] = [
        {'sessions': <Object>[]}
      ];
    final pruned = pruneRouteStatus(jsonEncode(full));
    expect(pruned, isNotNull);
    expect(pruned!.containsKey('dht'), isFalse);
    expect(RouteSnapshot.fromStatus(pruned, db: db),
        RouteSnapshot.fromStatus(full, db: db));
    expect(pruneRouteStatus('not json'), isNull);
    expect(pruneRouteStatus('{"running":false}'), isNull);
  });
}
