
import 'dart:math';

//import 'package:beldex_browser/src/utils/screen_secure_provider.dart';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/map/geo_location.dart';
import 'package:belnet_mobile/src/map/ip_geolocation_service.dart';
import 'package:belnet_mobile/src/providers/auto_connect_provider.dart';
 
import 'package:belnet_mobile/src/model/exitnodeCategoryModel.dart'
    as exitNodeModel;
class UserPosition {
  final double latitude;
  final double longitude;
  final String country;

  /// Full IP-geolocation result (public IP, city, region, ISO code) when
  /// the lookup succeeded; null for the (0, 0) "all APIs failed" fallback.
  final GeoLocation? location;

  UserPosition({
    required this.latitude,
    required this.longitude,
    required this.country,
    this.location,
  });
}

/// In-memory geolocation cache: the user's coarse location changes rarely,
/// while this lookup used to sit (serially) on the connect path every time.
UserPosition? _cachedPosition;
DateTime? _cachedPositionAt;
const _positionCacheTtl = Duration(hours: 24);
const _geoTimeout = Duration(seconds: 3);

/// Lookup currently in progress, shared by concurrent callers.
Future<UserPosition>? _inFlightLookup;

///  Get user location (lat, long, country) using free IP API
Future<UserPosition> getUserLocationFromAPI() async {
  // Serve from cache when fresh - keeps the connect path off the network.
  final cachedAt = _cachedPositionAt;
  if (_cachedPosition != null &&
      cachedAt != null &&
      DateTime.now().difference(cachedAt) < _positionCacheTtl) {
    return _cachedPosition!;
  }
  // Start-up asks for the location from several places at once (nearest
  // node selection and the map's original-location lookup): share one
  // request instead of geolocating the same IP twice.
  return _inFlightLookup ??= _lookupUserPosition().whenComplete(() {
    _inFlightLookup = null;
  });
}

Future<UserPosition> _lookupUserPosition() async {
  // ipwho.is first, ipapi.co as fallback (HTTPS only - this is a privacy
  // product, don't leak geolocation lookups over plain HTTP).
  final geo = await IpGeolocationService.lookup()
      .timeout(_geoTimeout * 3, onTimeout: () => null);
  if (geo != null) {
    final pos = UserPosition(
      latitude: geo.latitude,
      longitude: geo.longitude,
      country: normalizeCountryName(geo.country),
      location: geo,
    );
    // While the tunnel is up the lookup sees the EXIT's address, not the
    // user's: return it to the caller but never cache it as "user position".
    if (!BelnetLib.isConnected) _cachePosition(pos);
    return pos;
  }

  // Stale cache beats the (0,0) fallback.
  if (_cachedPosition != null) return _cachedPosition!;

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