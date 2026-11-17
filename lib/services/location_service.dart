import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/geo_utils.dart';

class LocationReading {
  final LatLng position;
  final double accuracy;
  final double speedMetersPerSec;
  final double heading;
  final DateTime timestamp;
  final bool isAccurate;

  LocationReading({
    required this.position,
    required this.accuracy,
    required this.speedMetersPerSec,
    required this.heading,
    required this.timestamp,
    required this.isAccurate,
  });

  factory LocationReading.fromPosition(Position pos) {
    final latLng = LatLng(pos.latitude, pos.longitude);
    final bool accurate = pos.accuracy <= AppConstants.maxAcceptableGpsAccuracyMeters;
    return LocationReading(
      position: latLng,
      accuracy: pos.accuracy,
      speedMetersPerSec: pos.speed >= 0 ? pos.speed : 0.0,
      heading: pos.heading >= 0 ? pos.heading : 0.0,
      timestamp: pos.timestamp,
      isAccurate: accurate,
    );
  }
}

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<LocationReading>.broadcast();

  LocationReading? _lastValidReading;
  int _currentDistanceFilter = 15;

  Stream<LocationReading> get locationStream => _locationController.stream;
  Stream<ServiceStatus> get serviceStatusStream => Geolocator.getServiceStatusStream();
  LocationReading? get lastValidReading => _lastValidReading;
  int get currentDistanceFilter => _currentDistanceFilter;

  /// Gets immediate current location fix.
  Future<LocationReading?> getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final reading = LocationReading.fromPosition(position);
      if (reading.isAccurate) {
        _lastValidReading = reading;
      }
      return reading;
    } catch (_) {
      // Fallback to last known position if immediate fix times out
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final reading = LocationReading.fromPosition(lastKnown);
        _lastValidReading = reading;
        return reading;
      }
      return null;
    }
  }

  /// Starts listening to location updates with adaptive distance filter.
  void startTracking({int distanceFilterMeters = 15}) {
    _currentDistanceFilter = distanceFilterMeters;
    _positionSubscription?.cancel();

    // Use Android-optimized settings with appropriate interval duration
    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: distanceFilterMeters,
      intervalDuration: Duration(
        seconds: distanceFilterMeters >= 100
            ? 15
            : distanceFilterMeters >= 35
                ? 8
                : 3,
      ),
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        final newLatLng = LatLng(position.latitude, position.longitude);

        // Check GPS accuracy and detect teleportation / improbable jumps
        final isValid = GeoUtils.isValidLocationUpdate(
          newPosition: newLatLng,
          accuracyMeters: position.accuracy,
          previousPosition: _lastValidReading?.position,
          previousTime: _lastValidReading?.timestamp,
          newTime: position.timestamp,
        );

        if (isValid) {
          final reading = LocationReading.fromPosition(position);
          _lastValidReading = reading;
          _locationController.add(reading);
        }
      },
      onError: (error) {
        // Stream error handling
      },
    );
  }

  /// Updates distance filter dynamically only when the threshold has actually changed.
  /// Prevents restarting the native GPS position stream needlessly on every location tick.
  void updateDistanceFilter(int meters) {
    if (_currentDistanceFilter != meters && _positionSubscription != null) {
      startTracking(distanceFilterMeters: meters);
    }
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
