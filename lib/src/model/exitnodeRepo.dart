import 'package:belnet_mobile/src/model/exitnodeCategoryModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exitnodeModel.dart';
import 'package:http/http.dart' as http;

class DataRepo {
  static const _cacheKey = 'exitnode_list_cache_body';
  static const _cacheEtagKey = 'exitnode_list_cache_etag';
  static const _cacheAtKey = 'exitnode_list_cache_at';
  static const _cacheTtl = Duration(hours: 12);
  static const _fetchTimeout = Duration(seconds: 8);

  static const _listUrl =
      'https://belnet-exitnode.s3.ap-south-1.amazonaws.com/exitnode-bns-list/exitnode_info_list.json';

  Future<List<ExitnodeList>> getDataFromNet() async {
    var response = await http
        .get(Uri.parse(
            'https://deb.beldex.io/Beldex-projects/Belnet/exitlist.json'))
        .timeout(_fetchTimeout);
    return exitnodeListFromJson(response.body);
  }

  /// Exit-node list with a 12-hour cache.
  ///
  /// The list used to be downloaded fresh on every connect / node selection,
  /// serializing the connect path behind an S3 round trip. Now: serve from
  /// cache when fresh; refresh in the background when stale (so a slow or
  /// unreachable S3 never blocks connecting); fall back to any cached copy
  /// when offline.
  Future<List<ExitNodeDataList>> getListData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedBody = prefs.getString(_cacheKey);
    final cachedAtMs = prefs.getInt(_cacheAtKey) ?? 0;
    final age = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(cachedAtMs));

    if (cachedBody != null && cachedBody.isNotEmpty) {
      if (age > _cacheTtl) {
        // Stale: use it now, refresh for next time (fire-and-forget).
        // ignore: unawaited_futures
        _refreshCache(prefs);
      }
      try {
        return exitNodeDataListFromJson(cachedBody);
      } catch (_) {
        // Corrupt cache: fall through to a network fetch.
      }
    }

    final body = await _refreshCache(prefs);
    if (body == null) {
      throw Exception('Could not download the exit node list');
    }
    return exitNodeDataListFromJson(body);
  }

  /// Fetch the list (sending If-None-Match when an ETag is cached), update
  /// the cache, and return the freshest body. Returns the previous cached
  /// body (or null) on network failure.
  Future<String?> _refreshCache(SharedPreferences prefs) async {
    try {
      final headers = <String, String>{};
      final etag = prefs.getString(_cacheEtagKey);
      final cachedBody = prefs.getString(_cacheKey);
      if (etag != null && cachedBody != null) {
        headers['If-None-Match'] = etag;
      }
      final response = await http
          .get(Uri.parse(_listUrl), headers: headers)
          .timeout(_fetchTimeout);
      if (response.statusCode == 304 && cachedBody != null) {
        await prefs.setInt(_cacheAtKey, DateTime.now().millisecondsSinceEpoch);
        return cachedBody;
      }
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        // Validate before caching so a bad payload can't poison the cache.
        exitNodeDataListFromJson(response.body);
        await prefs.setString(_cacheKey, response.body);
        await prefs.setInt(_cacheAtKey, DateTime.now().millisecondsSinceEpoch);
        final newEtag = response.headers['etag'];
        if (newEtag != null) await prefs.setString(_cacheEtagKey, newEtag);
        return response.body;
      }
    } catch (e) {
      print('exit node list refresh failed: $e');
    }
    return prefs.getString(_cacheKey);
  }
}
