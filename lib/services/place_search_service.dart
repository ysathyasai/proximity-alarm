import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/destination.dart';

/// Geocoder leveraging the free OpenStreetMap Nominatim API with strict
/// location and country biasing to return relevant local transit stops.
class PlaceSearchService {
  PlaceSearchService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _cachedCountryCode;

  void dispose() {
    _client.close();
  }

  void disposeIfPossible() => dispose();

  /// Reverse-geocode the user's coordinates to fetch their ISO2 country code.
  Future<String?> getCountryCode(LatLng position) async {
    if (_cachedCountryCode != null) return _cachedCountryCode;

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'json',
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'addressdetails': '1',
      });

      final response = await _client.get(
        uri,
        headers: const {
          'User-Agent': 'TransitProximityAlarm/2.0 (contact: support@proximitytransit.app)',
          'Accept-Language': 'en',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        final code = address?['country_code']?.toString().toLowerCase();
        if (code != null && code.isNotEmpty) {
          _cachedCountryCode = code;
          return code;
        }
      }
    } catch (_) {
      // Fallback below
    }

    // Fallback to platform locale country code if available
    final localeCode = ui.PlatformDispatcher.instance.locale.countryCode?.toLowerCase();
    if (localeCode != null && localeCode.isNotEmpty) {
      _cachedCountryCode = localeCode;
      return localeCode;
    }
    return null;
  }

  /// Search OpenStreetMap Nominatim strictly biased to user location & country.
  Future<List<Destination>> search(
    String query, {
    LatLng? userLocation,
  }) async {
    final cleaned = query.trim();
    if (cleaned.length < 2) return const [];

    final queryParams = <String, String>{
      'q': cleaned,
      'format': 'json',
      'addressdetails': '1',
      'extratags': '1',
      'limit': '15',
    };

    // Strict location biasing
    if (userLocation != null) {
      // 1. Compute viewbox around current location (~60km radius box)
      final latRad = userLocation.latitude * (math.pi / 180.0);
      final latDelta = 0.5; // ~55 km
      final lonDelta = 0.5 / (math.cos(latRad).abs().clamp(0.1, 1.0));

      final minLon = (userLocation.longitude - lonDelta).clamp(-180.0, 180.0);
      final maxLon = (userLocation.longitude + lonDelta).clamp(-180.0, 180.0);
      final minLat = (userLocation.latitude - latDelta).clamp(-90.0, 90.0);
      final maxLat = (userLocation.latitude + latDelta).clamp(-90.0, 90.0);

      queryParams['viewbox'] = '$minLon,$maxLat,$maxLon,$minLat';
      queryParams['bounded'] = '0'; // Prioritize viewbox heavily without hard cutoff

      // 2. Strict country restriction to stop queries jumping across the world
      final country = await getCountryCode(userLocation);
      if (country != null && country.isNotEmpty) {
        queryParams['countrycodes'] = country;
      }
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', queryParams);

    final response = await _client.get(
      uri,
      headers: const {
        'User-Agent': 'TransitProximityAlarm/2.0 (contact: support@proximitytransit.app)',
        'Accept-Language': 'en',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Nominatim returned HTTP ${response.statusCode}.');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    final output = <Destination>[];

    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;

      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lon = double.tryParse(item['lon']?.toString() ?? '');
      if (lat == null || lon == null) continue;

      final address = (item['address'] as Map<String, dynamic>?) ?? {};
      final type = item['type']?.toString().toLowerCase() ?? '';
      final itemClass = item['class']?.toString().toLowerCase() ?? '';

      // Determine clean, high-clarity title
      final name = (item['name'] ??
              address['railway'] ??
              address['station'] ??
              address['bus_stop'] ??
              address['subway'] ??
              address['amenity'] ??
              address['road'] ??
              item['display_name']?.toString().split(',').first ??
              'Selected Location')
          .toString();

      // Format readable locality details
      final localityParts = [
        address['suburb'],
        address['neighbourhood'],
        address['city_district'],
        address['city'] ?? address['town'] ?? address['village'],
        address['state'],
      ].where((s) => s != null && s.toString().trim().isNotEmpty).toList();

      final readableAddress = localityParts.isNotEmpty
          ? localityParts.join(', ')
          : (item['display_name'] ?? '');

      // Infer transit category for appropriate icon
      String category = 'place';
      if (itemClass == 'railway' || type.contains('station') || type.contains('subway')) {
        category = 'station';
      } else if (itemClass == 'highway' && type.contains('bus')) {
        category = 'bus';
      } else if (itemClass == 'aeroway' || type.contains('airport')) {
        category = 'airport';
      } else if (itemClass == 'amenity') {
        category = 'amenity';
      }

      output.add(Destination(
        name: name,
        latitude: lat,
        longitude: lon,
        address: readableAddress,
        category: category,
      ));
    }

    // Sort strictly by distance to user location so closest stops show first
    if (userLocation != null) {
      output.sort((a, b) {
        final distA = a.distanceTo(userLocation);
        final distB = b.distanceTo(userLocation);
        return distA.compareTo(distB);
      });
    }

    return output;
  }
}
