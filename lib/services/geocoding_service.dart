import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../core/constants/app_constants.dart';
import '../data/models/destination.dart';

class GeocodingService {
  final http.Client _client;
  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  // In-memory cache: query -> list of destinations
  final Map<String, List<Destination>> _searchCache = {};
  // Reverse geocoding cache: LatLng -> Destination
  final Map<String, Destination> _reverseCache = {};

  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  /// Enforces Nominatim rate limit: at least 1000ms between requests.
  Future<void> _rateLimit() async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRequestTime).inMilliseconds;
    if (elapsed < 1050) {
      await Future.delayed(Duration(milliseconds: 1050 - elapsed));
    }
    _lastRequestTime = DateTime.now();
  }

  /// Searches for places/addresses using OpenStreetMap Nominatim.
  /// If [userLocation] is provided, prioritizes results in that geographical area.
  Future<List<Destination>> searchPlaces(
    String query, {
    LatLng? userLocation,
    int limit = 8,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty || trimmedQuery.length < 2) {
      return [];
    }

    final cacheKey =
        '${trimmedQuery.toLowerCase()}_${userLocation?.latitude.toStringAsFixed(2)}_${userLocation?.longitude.toStringAsFixed(2)}';
    if (_searchCache.containsKey(cacheKey)) {
      return _searchCache[cacheKey]!;
    }

    await _rateLimit();

    try {
      final queryParams = {
        'q': trimmedQuery,
        'format': 'json',
        'addressdetails': '1',
        'limit': limit.toString(),
      };

      // Biasing search to current user region if coordinates are available
      if (userLocation != null) {
        // Create an approximate 1.5 degree bounding viewbox around user
        final minLat = userLocation.latitude - 0.75;
        final maxLat = userLocation.latitude + 0.75;
        final minLon = userLocation.longitude - 0.75;
        final maxLon = userLocation.longitude + 0.75;

        queryParams['viewbox'] = '$minLon,$maxLat,$maxLon,$minLat';
        queryParams['bounded'] = '0'; // Prioritize viewbox without strictly excluding others
      }

      final uri = Uri.parse(AppConstants.nominatimSearchUrl)
          .replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': AppConstants.userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final List<Destination> results = [];

        for (final item in jsonList) {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat == null || lon == null) continue;

          final displayName = item['display_name'] as String? ?? 'Location';
          final nameParts = displayName.split(',');
          final shortName = nameParts.first.trim();
          final secondary = nameParts.length > 1
              ? nameParts.sublist(1).take(3).join(',').trim()
              : displayName;

          results.add(
            Destination(
              name: shortName.isNotEmpty ? shortName : displayName,
              address: secondary.isNotEmpty ? secondary : displayName,
              latitude: lat,
              longitude: lon,
              category: 'search',
            ),
          );
        }

        _searchCache[cacheKey] = results;
        return results;
      }
      return [];
    } catch (_) {
      // Graceful offline fallback
      return [];
    }
  }

  /// Reverse geocodes coordinates to a human-readable destination name.
  Future<Destination> reverseGeocode(LatLng coordinates) async {
    final cacheKey =
        '${coordinates.latitude.toStringAsFixed(4)},${coordinates.longitude.toStringAsFixed(4)}';
    if (_reverseCache.containsKey(cacheKey)) {
      return _reverseCache[cacheKey]!;
    }

    await _rateLimit();

    try {
      final uri = Uri.parse(AppConstants.nominatimReverseUrl).replace(
        queryParameters: {
          'lat': coordinates.latitude.toString(),
          'lon': coordinates.longitude.toString(),
          'format': 'json',
          'addressdetails': '1',
        },
      );

      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': AppConstants.userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final displayName = data['display_name'] as String? ?? 'Pinned Location';
        final nameParts = displayName.split(',');
        final shortName = nameParts.first.trim();
        final address = nameParts.length > 1
            ? nameParts.sublist(1).take(3).join(',').trim()
            : displayName;

        final destination = Destination(
          name: shortName.isNotEmpty ? shortName : 'Pinned Location',
          address: address,
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
          category: 'pinned',
        );

        _reverseCache[cacheKey] = destination;
        return destination;
      }
    } catch (_) {
      // Ignore network errors and return basic coordinates label
    }

    final fallback = Destination(
      name: 'Pinned Location',
      address:
          '${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)}',
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      category: 'pinned',
    );
    return fallback;
  }
}

