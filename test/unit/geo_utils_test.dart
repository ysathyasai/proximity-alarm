import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:proximity_alarm/core/utils/geo_utils.dart';

void main() {
  group('GeoUtils Unit Tests', () {
    test('calculateDistanceMeters calculates accurate Haversine distance', () {
      // Chennai Central (13.0827, 80.2754) to Chennai Egmore (13.0784, 80.2606)
      // Actual straight-line distance is ~1.67 km
      const start = LatLng(13.0827, 80.2754);
      const end = LatLng(13.0784, 80.2606);

      final distance = GeoUtils.calculateDistanceMeters(start, end);

      expect(distance, greaterThan(1550));
      expect(distance, lessThan(1750));
    });

    test('calculateDistanceMeters returns 0 for identical points', () {
      const point = LatLng(13.0827, 80.2754);
      final distance = GeoUtils.calculateDistanceMeters(point, point);
      expect(distance, closeTo(0.0, 0.001));
    });

    test('isInsideAlertRadius correctly tests geofence boundary', () {
      const center = LatLng(13.0827, 80.2754);
      // Close point: ~500m away
      const insidePoint = LatLng(13.0827, 80.2800);
      // Far point: ~6km away
      const outsidePoint = LatLng(13.1300, 80.2754);

      expect(
        GeoUtils.isInsideAlertRadius(
          currentPosition: insidePoint,
          destination: center,
          radiusMeters: 1000.0,
        ),
        isTrue,
      );

      expect(
        GeoUtils.isInsideAlertRadius(
          currentPosition: outsidePoint,
          destination: center,
          radiusMeters: 1000.0,
        ),
        isFalse,
      );
    });

    test('isValidLocationUpdate rejects inaccurate GPS readings (>65m)', () {
      const pos = LatLng(13.0827, 80.2754);

      // Inaccurate reading (e.g. 95m error)
      final bool invalid = GeoUtils.isValidLocationUpdate(
        newPosition: pos,
        accuracyMeters: 95.0,
      );
      expect(invalid, isFalse);

      // Accurate reading (15m error)
      final bool valid = GeoUtils.isValidLocationUpdate(
        newPosition: pos,
        accuracyMeters: 15.0,
      );
      expect(valid, isTrue);
    });

    test('isValidLocationUpdate rejects impossible teleportation jumps', () {
      const pos1 = LatLng(13.0827, 80.2754);
      // Teleport 20 km away in 2 seconds (implied speed = 10,000 m/s = 36,000 km/h!)
      const pos2 = LatLng(13.2500, 80.2754);

      final time1 = DateTime.now();
      final time2 = time1.add(const Duration(seconds: 2));

      final bool isPlausible = GeoUtils.isValidLocationUpdate(
        newPosition: pos2,
        accuracyMeters: 10.0,
        previousPosition: pos1,
        previousTime: time1,
        newTime: time2,
      );

      expect(isPlausible, isFalse);
    });

    test('isValidLocationUpdate accepts normal moving transit updates', () {
      const pos1 = LatLng(13.0827, 80.2754);
      // Move 80 meters in 5 seconds (16 m/s = ~57 km/h bus speed)
      const pos2 = LatLng(13.0834, 80.2754);

      final time1 = DateTime.now();
      final time2 = time1.add(const Duration(seconds: 5));

      final bool isPlausible = GeoUtils.isValidLocationUpdate(
        newPosition: pos2,
        accuracyMeters: 12.0,
        previousPosition: pos1,
        previousTime: time1,
        newTime: time2,
      );

      expect(isPlausible, isTrue);
    });

    test('estimateEtaMinutes handles transit speed and stationary signal fallback', () {
      // 10 km distance at 30 km/h fallback (when stationary, speed = 0)
      final etaStopped = GeoUtils.estimateEtaMinutes(
        distanceMeters: 10000,
        currentSpeedMetersPerSec: 0,
        defaultSpeedKmh: 30.0,
      );
      expect(etaStopped, equals(20)); // 10 km at 30 km/h = 20 mins

      // 6 km distance moving at 60 km/h (16.67 m/s)
      final etaMoving = GeoUtils.estimateEtaMinutes(
        distanceMeters: 6000,
        currentSpeedMetersPerSec: 16.67,
      );
      expect(etaMoving, equals(6)); // 6 km at 60 km/h = 6 mins
    });

    test('shouldTriggerAlarm triggers when distance is within radius', () {
      final shouldTrigger = GeoUtils.shouldTriggerAlarm(
        distanceMeters: 850.0,
        radiusMeters: 1000.0,
        etaMinutes: 12,
        prepWindowMinutes: 5,
      );
      expect(shouldTrigger, isTrue);
    });

    test('shouldTriggerAlarm triggers when ETA is within prep window', () {
      final shouldTrigger = GeoUtils.shouldTriggerAlarm(
        distanceMeters: 3500.0,
        radiusMeters: 2000.0,
        etaMinutes: 4,
        prepWindowMinutes: 5,
      );
      expect(shouldTrigger, isTrue);
    });

    test('shouldTriggerAlarm does NOT trigger when far outside radius and prep window', () {
      final shouldTrigger = GeoUtils.shouldTriggerAlarm(
        distanceMeters: 8000.0,
        radiusMeters: 2000.0,
        etaMinutes: 18,
        prepWindowMinutes: 5,
      );
      expect(shouldTrigger, isFalse);
    });
  });
}
