import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';

class GeoUtils {
  static const double earthRadiusMeters = 6371000.0;

  /// Calculates the great-circle distance between two points in meters using the Haversine formula.
  static double calculateDistanceMeters(LatLng start, LatLng end) {
    final double lat1Rad = start.latitude * pi / 180.0;
    final double lat2Rad = end.latitude * pi / 180.0;
    final double deltaLatRad = (end.latitude - start.latitude) * pi / 180.0;
    final double deltaLngRad = (end.longitude - start.longitude) * pi / 180.0;

    final double a = sin(deltaLatRad / 2.0) * sin(deltaLatRad / 2.0) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLngRad / 2.0) * sin(deltaLngRad / 2.0);
    final double c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a));

    return earthRadiusMeters * c;
  }

  /// Calculates initial bearing from start to destination in degrees (0..360).
  static double calculateBearing(LatLng start, LatLng end) {
    final double lat1Rad = start.latitude * pi / 180.0;
    final double lat2Rad = end.latitude * pi / 180.0;
    final double deltaLngRad = (end.longitude - start.longitude) * pi / 180.0;

    final double y = sin(deltaLngRad) * cos(lat2Rad);
    final double x = cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(deltaLngRad);

    final double radians = atan2(y, x);
    final double degrees = radians * 180.0 / pi;
    return (degrees + 360.0) % 360.0;
  }

  /// Evaluates whether a new location reading is physically plausible or an inaccurate GPS jump.
  static bool isValidLocationUpdate({
    required LatLng newPosition,
    required double accuracyMeters,
    LatLng? previousPosition,
    DateTime? previousTime,
    DateTime? newTime,
    double maxAccuracyThreshold = AppConstants.maxAcceptableGpsAccuracyMeters,
    double maxSpeedThresholdMetersPerSec = AppConstants.maxPlausibleTransitSpeedMetersPerSec,
  }) {
    // 1. Accuracy check: ignore inaccurate readings
    if (accuracyMeters > maxAccuracyThreshold) {
      return false;
    }

    // If no previous location, this initial fix is acceptable
    if (previousPosition == null || previousTime == null || newTime == null) {
      return true;
    }

    final double timeDiffSeconds =
        newTime.difference(previousTime).inMilliseconds / 1000.0;

    // Reject negative or zero time delta
    if (timeDiffSeconds <= 0.1) {
      return false;
    }

    final double distanceMeters =
        calculateDistanceMeters(previousPosition, newPosition);
    final double impliedSpeed = distanceMeters / timeDiffSeconds;

    // 2. Teleportation / jump check: reject impossible speed jump
    if (impliedSpeed > maxSpeedThresholdMetersPerSec) {
      return false;
    }

    return true;
  }

  /// Determines ETA in minutes based on distance and speed.
  /// Falls back to standard average transit speed if current speed is near 0 (e.g. stopped at a signal).
  static int estimateEtaMinutes({
    required double distanceMeters,
    required double currentSpeedMetersPerSec,
    double defaultSpeedKmh = AppConstants.averageCityTransitSpeedKmh,
  }) {
    if (distanceMeters <= 0) return 0;

    // Convert fallback speed to m/s
    final double defaultSpeedMps = defaultSpeedKmh * (1000.0 / 3600.0);

    // If moving at plausible transit speed (> 2 m/s or 7.2 km/h), use current speed;
    // otherwise use default average city transit speed.
    final double effectiveSpeed =
        (currentSpeedMetersPerSec > 2.0 && currentSpeedMetersPerSec < 70.0)
            ? currentSpeedMetersPerSec
            : defaultSpeedMps;

    final double seconds = distanceMeters / effectiveSpeed;
    return (seconds / 60.0).ceil();
  }

  /// Determines if current location has entered the alert radius.
  static bool isInsideAlertRadius({
    required LatLng currentPosition,
    required LatLng destination,
    required double radiusMeters,
  }) {
    final double distance = calculateDistanceMeters(currentPosition, destination);
    return distance <= radiusMeters;
  }

  /// Determines if alarm should be triggered based on:
  /// 1. Distance <= radiusMeters (Physical geofence - always checked)
  /// 2. ETA <= prepWindowMinutes (Timer - ONLY evaluated if [useTimerAlert] is toggled on)
  static bool shouldTriggerAlarm({
    required double distanceMeters,
    required double radiusMeters,
    required int etaMinutes,
    required int prepWindowMinutes,
    bool useTimerAlert = false,
  }) {
    // Always trigger when entering the physical destination radius
    if (distanceMeters <= radiusMeters) {
      return true;
    }

    // Trigger on timer only when explicitly enabled by user
    if (useTimerAlert && etaMinutes > 0 && etaMinutes <= prepWindowMinutes) {
      return true;
    }

    return false;
  }
}

