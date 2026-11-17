import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:proximity_alarm/core/constants/app_constants.dart';
import 'package:proximity_alarm/core/utils/formatters.dart';
import 'package:proximity_alarm/core/utils/geo_utils.dart';

void main() {
  group('GeoUtils Unit Tests', () {
    test('calculateDistanceMeters calculates accurate Haversine distance', () {
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
      const insidePoint = LatLng(13.0827, 80.2800);
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

      final bool invalid = GeoUtils.isValidLocationUpdate(
        newPosition: pos,
        accuracyMeters: 95.0,
      );
      expect(invalid, isFalse);

      final bool valid = GeoUtils.isValidLocationUpdate(
        newPosition: pos,
        accuracyMeters: 15.0,
      );
      expect(valid, isTrue);
    });

    test('isValidLocationUpdate rejects impossible teleportation jumps', () {
      const pos1 = LatLng(13.0827, 80.2754);
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
      final etaStopped = GeoUtils.estimateEtaMinutes(
        distanceMeters: 10000,
        currentSpeedMetersPerSec: 0,
        defaultSpeedKmh: 30.0,
      );
      expect(etaStopped, equals(20));

      final etaMoving = GeoUtils.estimateEtaMinutes(
        distanceMeters: 6000,
        currentSpeedMetersPerSec: 16.67,
      );
      expect(etaMoving, equals(6));
    });

    test('shouldTriggerAlarm triggers when distance is within radius regardless of timer', () {
      final shouldTrigger = GeoUtils.shouldTriggerAlarm(
        distanceMeters: 850.0,
        radiusMeters: 1000.0,
        etaMinutes: 12,
        prepWindowMinutes: 5,
        useTimerAlert: false,
      );
      expect(shouldTrigger, isTrue);
    });

    test('shouldTriggerAlarm evaluates timer ONLY when useTimerAlert is true in combined mode', () {
      final noTimerTrigger = GeoUtils.shouldTriggerAlarm(
        distanceMeters: 3500.0,
        radiusMeters: 2000.0,
        etaMinutes: 4,
        prepWindowMinutes: 5,
        alertMode: AlertMode.combined,
        useTimerAlert: false,
      );
      expect(noTimerTrigger, isFalse);

      final timerTrigger = GeoUtils.shouldTriggerAlarm(
        distanceMeters: 3500.0,
        radiusMeters: 2000.0,
        etaMinutes: 4,
        prepWindowMinutes: 5,
        alertMode: AlertMode.combined,
        useTimerAlert: true,
      );
      expect(timerTrigger, isTrue);
    });

    test('shouldTriggerAlarm in fixedRadius mode ignores ETA completely', () {
      final fixedRadiusNoTrigger = GeoUtils.shouldTriggerAlarm(
        distanceMeters: 2500.0,
        radiusMeters: 2000.0,
        etaMinutes: 2,
        prepWindowMinutes: 5,
        alertMode: AlertMode.fixedRadius,
        useTimerAlert: true,
      );
      expect(fixedRadiusNoTrigger, isFalse);

      final fixedRadiusTrigger = GeoUtils.shouldTriggerAlarm(
        distanceMeters: 1800.0,
        radiusMeters: 2000.0,
        etaMinutes: 10,
        prepWindowMinutes: 5,
        alertMode: AlertMode.fixedRadius,
      );
      expect(fixedRadiusTrigger, isTrue);
    });

    test('shouldTriggerAlarm in adaptiveEta mode triggers on ETA window or safety radius', () {
      final etaTrigger = GeoUtils.shouldTriggerAlarm(
        distanceMeters: 4000.0,
        radiusMeters: 2000.0,
        etaMinutes: 4,
        prepWindowMinutes: 5,
        alertMode: AlertMode.adaptiveEta,
      );
      expect(etaTrigger, isTrue);

      final safetyFallback = GeoUtils.shouldTriggerAlarm(
        distanceMeters: 450.0,
        radiusMeters: 2000.0,
        etaMinutes: 0, // ETA unknown or signal lost
        prepWindowMinutes: 5,
        alertMode: AlertMode.adaptiveEta,
      );
      expect(safetyFallback, isTrue);
    });

    test('shouldTriggerEarlyWarning detects approach at 2x radius or 2x prep window', () {
      // 3.5 km away with 2 km radius -> inside 2x radius (4 km)
      final earlyRadius = GeoUtils.shouldTriggerEarlyWarning(
        distanceMeters: 3500.0,
        radiusMeters: 2000.0,
        etaMinutes: 15,
        prepWindowMinutes: 5,
      );
      expect(earlyRadius, isTrue);

      // 8 km away, 15 min ETA with 10 min 2x window -> false
      final notYet = GeoUtils.shouldTriggerEarlyWarning(
        distanceMeters: 8000.0,
        radiusMeters: 2000.0,
        etaMinutes: 15,
        prepWindowMinutes: 5,
      );
      expect(notYet, isFalse);
    });

    test('getCardinalDirection converts bearing degrees accurately to compass points', () {
      expect(GeoUtils.getCardinalDirection(0), equals('N'));
      expect(GeoUtils.getCardinalDirection(45), equals('NE'));
      expect(GeoUtils.getCardinalDirection(90), equals('E'));
      expect(GeoUtils.getCardinalDirection(135), equals('SE'));
      expect(GeoUtils.getCardinalDirection(180), equals('S'));
      expect(GeoUtils.getCardinalDirection(225), equals('SW'));
      expect(GeoUtils.getCardinalDirection(270), equals('W'));
      expect(GeoUtils.getCardinalDirection(315), equals('NW'));
      expect(GeoUtils.getCardinalDirection(355), equals('N'));
    });
  });

  group('Formatters Unit Tests', () {
    test('formatDistance handles Metric and Imperial units accurately', () {
      // 2000m in Metric -> '2.0 km'
      expect(
        Formatters.formatDistance(2000.0, DistanceUnit.metric),
        equals('2.0 km'),
      );
      // 450m in Metric -> '450 m'
      expect(
        Formatters.formatDistance(450.0, DistanceUnit.metric),
        equals('450 m'),
      );

      // 2000m (~1.24 miles) in Imperial -> '1.2 mi'
      expect(
        Formatters.formatDistance(2000.0, DistanceUnit.imperial),
        equals('1.2 mi'),
      );
      // 100m (~328 feet) in Imperial -> '328 ft'
      expect(
        Formatters.formatDistance(100.0, DistanceUnit.imperial),
        equals('328 ft'),
      );
    });

    test('formatSpeed handles Metric and Imperial units', () {
      // 15 m/s = 54 km/h
      expect(
        Formatters.formatSpeed(15.0, DistanceUnit.metric),
        equals('54 km/h'),
      );
      // 15 m/s = ~34 mph
      expect(
        Formatters.formatSpeed(15.0, DistanceUnit.imperial),
        equals('34 mph'),
      );
      // Stopped
      expect(
        Formatters.formatSpeed(0.0, DistanceUnit.metric),
        equals('0 km/h'),
      );
      expect(
        Formatters.formatSpeed(0.0, DistanceUnit.imperial),
        equals('0 mph'),
      );
    });

    test('formatEtaClockTime and formatDurationMinutes formats arrival time cleanly', () {
      expect(Formatters.formatDurationMinutes(0), equals('Arrived'));
      expect(Formatters.formatDurationMinutes(25), equals('25 min'));
      expect(Formatters.formatDurationMinutes(60), equals('1 hr'));
      expect(Formatters.formatDurationMinutes(75), equals('1 hr 15 min'));

      expect(Formatters.formatEtaClockTime(0), equals('Now'));
      final clockTime = Formatters.formatEtaClockTime(30);
      expect(clockTime.isNotEmpty, isTrue);
      expect(clockTime, isNot(equals('Now')));
    });
  });
}
