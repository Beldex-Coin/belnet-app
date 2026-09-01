
import 'dart:convert';
import 'dart:math';

//import 'package:beldex_browser/src/utils/screen_secure_provider.dart';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/providers/auto_connect_provider.dart';
import 'package:http/http.dart' as http;
 
import 'package:belnet_mobile/src/model/exitnodeCategoryModel.dart'
    as exitNodeModel;
class UserPosition {
  final double latitude;
  final double longitude;
  final String country;

  UserPosition({
    required this.latitude,
    required this.longitude,
    required this.country,
  });
}

///  Get user location (lat, long, country) using free IP API
// Future<UserPosition> getUserLocationFromAPI() async {
//   final response = await http.get(Uri.parse('https://ipapi.co/json/'));

//   if (response.statusCode == 200) {
//     final data = jsonDecode(response.body);
//     return UserPosition(
//       latitude: (data['latitude'] ?? 0).toDouble(),
//       longitude: (data['longitude'] ?? 0).toDouble(),
//       country: data['country_name'] ?? 'Unknown',
//     );
//   } else {
//     throw Exception('Failed to fetch location from IP');
//   }
// }
/// In-memory geolocation cache: the user's coarse location changes rarely,
/// while this lookup used to sit (serially) on the connect path every time.
UserPosition? _cachedPosition;
DateTime? _cachedPositionAt;
const _positionCacheTtl = Duration(hours: 24);
const _geoTimeout = Duration(seconds: 3);

Future<UserPosition> getUserLocationFromAPI() async {
  // Serve from cache when fresh - keeps the connect path off the network.
  final cachedAt = _cachedPositionAt;
  if (_cachedPosition != null &&
      cachedAt != null &&
      DateTime.now().difference(cachedAt) < _positionCacheTtl) {
    return _cachedPosition!;
  }

  try {
    // Try ipwho.is
    final res1 =
        await http.get(Uri.parse('https://ipwho.is/')).timeout(_geoTimeout);
    if (res1.statusCode == 200) {
      final data = jsonDecode(res1.body);
      return _cachePosition(UserPosition(
        latitude: (data['latitude'] ?? 0).toDouble(),
        longitude: (data['longitude'] ?? 0).toDouble(),
        country: normalizeCountryName(data['country']),
      ));
    }
  } catch (_) {}

  try {
    //  Fallback: ipapi.co (supports HTTPS on the free tier, unlike
    //  ip-api.com which is HTTP-only - this is a privacy product, don't
    //  leak geolocation lookups over plain HTTP).
    final res2 = await http
        .get(Uri.parse('https://ipapi.co/json/'))
        .timeout(_geoTimeout);
    if (res2.statusCode == 200) {
      final data = jsonDecode(res2.body);
      return _cachePosition(UserPosition(
        latitude: (data['latitude'] ?? 0).toDouble(),
        longitude: (data['longitude'] ?? 0).toDouble(),
        country: normalizeCountryName(data['country_name']),
      ));
    }
  } catch (_) {}

  // Stale cache beats the (0,0) fallback.
  if (_cachedPosition != null) return _cachedPosition!;

  // try {
  //   // Try ipinfo.io
  //   final res3 = await http.get(Uri.parse('https://ipinfo.io/json'));
  //   if (res3.statusCode == 200) {
  //     final data = jsonDecode(res3.body);
  //     List<String> loc = (data['loc'] ?? "0,0").split(",");
  //     return UserPosition(
  //       latitude: double.tryParse(loc[0]) ?? 0,
  //       longitude: double.tryParse(loc[1]) ?? 0,
  //       country: data['country'] ?? "Unknown",
  //     );
  //   }
  // } catch (_) {}

  // All failed → return a safe fallback, do NOT throw
  print("All IP-Location APIs failed, using default values.");
  return UserPosition(latitude: 0, longitude: 0, country: "Unknown");
}

UserPosition _cachePosition(UserPosition pos) {
  _cachedPosition = pos;
  _cachedPositionAt = DateTime.now();
  return pos;
}

/// Haversine formula to calculate distance in km
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371; // Earth radius in km
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}


String normalizeCountryName(String? country) {
  if (country == null || country.trim().isEmpty) return "Unknown";
  country = country.trim();

  final replacements = {
    "The Netherlands": "Netherlands",
    "Republic of Lithuania": "Lithuania",
    "United States": "USA",
    "United Kingdom": "UK",
    "Republic of Korea": "South Korea",
    "Russian Federation": "Russia",
  };

  for (final entry in replacements.entries) {
    if (country.toLowerCase().contains(entry.key.toLowerCase())) {
      return entry.value;
    }
  }

  return country;
}


///  Main logic to find nearest node
Future<Map<String, dynamic>> findNearestNode({
  required List<exitNodeModel.ExitNodeDataList> nodeLists,
  required AutoConnectProvider autoConnectProvider,
}) async {
  final userPos = await getUserLocationFromAPI();
  print("User Country: ${userPos.country}");

  // Flatten all nodes from all nodeLists
  final allNodes = nodeLists.expand((list) => list.node).toList();

  // Exclude user’s own country
  final filteredNodes = allNodes.where((n) => n.country != userPos.country
  ).toList();

  if (filteredNodes.isEmpty) {
    throw Exception("No nodes available outside your current country (${userPos.country}).");
  }

  exitNodeModel.Node finalNode;

  if (autoConnectProvider.autoConnect && BelnetLib.isConnected == false) {
    // Step 1: Keep only nodes with non-zero speedScore
    List<exitNodeModel.Node> nonZeroNodes = filteredNodes.where((n) => n.speedScore > 0).toList();

    //  If no non-zero nodes, fallback to all nodes
    if (nonZeroNodes.isEmpty) nonZeroNodes = filteredNodes;

    // Find nearest node from this filtered list
    exitNodeModel.Node nearestNode = nonZeroNodes.first;
    double minDistance = double.infinity;

    for (var node in nonZeroNodes) {
      double dist = calculateDistance(
       // 45.424721, -75.695000,
        userPos.latitude,
        userPos.longitude,
        node.lat,
        node.long,
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearestNode = node;
      }
    }

    //  Get all nodes in that nearest node’s country
    List<exitNodeModel.Node> sameCountryNodes =
        nonZeroNodes.where((n) => n.country == nearestNode.country).toList();

    // speedScore is a RANK, not a score: 1 = fastest node, 2 = second
    // fastest, ...; 0 = unranked (already filtered out above when possible).
    // Verified against exitnode_info_list.json where ranked nodes carry
    // unique values 1..N. Ascending sort therefore puts the BEST node
    // first — do not invert this comparison.
    sameCountryNodes.sort((a, b) {
      int speedCompare = a.speedScore.compareTo(b.speedScore);
      if (speedCompare != 0) return speedCompare;

      double distA = calculateDistance(userPos.latitude, userPos.longitude, a.lat, a.long);
      double distB = calculateDistance(userPos.latitude, userPos.longitude, b.lat, b.long);
      return distA.compareTo(distB);
    });

    finalNode = sameCountryNodes.first;
    print('User changed country after autoconnect is ${finalNode.name} SpeedScore is ${finalNode.speedScore} country ${finalNode.country}');
  } else {
    // AutoConnect disabled → just find absolutely nearest node
    exitNodeModel.Node nearestNode = filteredNodes.first;
    double minDistance = double.infinity;

    for (var node in filteredNodes) {
      double dist = calculateDistance(
        //45.424721, -75.695000,
        userPos.latitude,
        userPos.longitude,
        node.lat,
        node.long,
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearestNode = node;
      }
    }

//  Find all nodes within 20% distance margin of nearest
    double range = minDistance * 1.2; // 20% margin
    List<exitNodeModel.Node> nearbyNodes = filteredNodes.where((node) {
      double dist = calculateDistance(
        userPos.latitude,
        userPos.longitude,
        node.lat,
        node.long,
      );
      return dist <= range;
    }).toList();

    // Step 3: Randomly pick one
    final random = Random();
    finalNode = nearbyNodes[random.nextInt(nearbyNodes.length)];

    print(
        'AutoConnect OFF → randomly picked ${finalNode.name} (Country: ${finalNode.country}, Distance: ${minDistance.toStringAsFixed(2)} km)');







   // finalNode = nearestNode;
  //  print('User changed country without autoconnect is ${finalNode.name} SpeedScore is ${finalNode.speedScore} country ${finalNode.country}');
  }

  return {
    "id": finalNode.id,
    "name": finalNode.name,
    "icon": finalNode.icon,
    "country": finalNode.country,
    "lat": finalNode.lat,
    "long": finalNode.long,
    "speedScore": finalNode.speedScore,
  };
}