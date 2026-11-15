import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/geo_utils.dart';

class RouteResult {
  final List<LatLng> polylinePoints;
  final double distanceMeters;
  final int durationMinutes;
  final bool isRoadRoute; // true if from OSRM, false if straight line fallback

  RouteResult({
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationMinutes,
    required this.isRoadRoute,
  });
}

class RoutingService {
  final http.Client _client;
  final Map<String, RouteResult> _cache = {};

  RoutingService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches road route between [origin] and [destination] via OSRM.
  /// Falls back smoothly to direct geodesic line if network is unavailable.
  Future<RouteResult> getRoute(LatLng origin, LatLng destination) async {
    final double directDistance =
        GeoUtils.calculateDistanceMeters(origin, destination);

    final cacheKey =
        '${origin.latitude.toStringAsFixed(3)},${origin.longitude.toStringAsFixed(3)}->${destination.latitude.toStringAsFixed(3)},${destination.longitude.toStringAsFixed(3)}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final String url =
          '${AppConstants.osrmRoutingUrl}/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson';

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': AppConstants.userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes.first as Map<String, dynamic>;
          final double distance =
              (firstRoute['distance'] as num?)?.toDouble() ?? directDistance;
          final double durationSeconds =
              (firstRoute['duration'] as num?)?.toDouble() ?? (distance / 8.33);

          final geometry =
              firstRoute['geometry'] as Map<String, dynamic>?;
          final coordinates =
              geometry?['coordinates'] as List<dynamic>?;

          final List<LatLng> points = [];
          if (coordinates != null) {
            for (final coord in coordinates) {
              if (coord is List && coord.length >= 2) {
                final lon = (coord[0] as num).toDouble();
                final lat = (coord[1] as num).toDouble();
                points.add(LatLng(lat, lon));
              }
            }
          }

          if (points.isNotEmpty) {
            final result = RouteResult(
              polylinePoints: points,
              distanceMeters: distance,
              durationMinutes: (durationSeconds / 60).ceil(),
              isRoadRoute: true,
            );
            _cache[cacheKey] = result;
            return result;
          }
        }
      }
    } catch (_) {
      // Fallback on network or timeout failure
    }

    // Direct geodesic line fallback
    final fallbackEta = GeoUtils.estimateEtaMinutes(
      distanceMeters: directDistance,
      currentSpeedMetersPerSec: 0,
    );
    final fallbackResult = RouteResult(
      polylinePoints: [origin, destination],
      distanceMeters: directDistance,
      durationMinutes: fallbackEta,
      isRoadRoute: false,
    );
    _cache[cacheKey] = fallbackResult;
    return fallbackResult;
  }
}

