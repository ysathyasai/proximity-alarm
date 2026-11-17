import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:proximity_alarm/core/utils/geo_utils.dart';
import 'package:proximity_alarm/data/models/destination.dart';
import 'package:proximity_alarm/data/models/journey.dart';
import 'package:proximity_alarm/services/routing_service.dart';

void main() {
  group('Routing & Arrival Engine Tests', () {
    test('Routing fallback produces geodesic line when offline or failed', () async {
      // RoutingService with a mock or default client that falls back on bad host
      final routingService = RoutingService();
      const origin = LatLng(13.0827, 80.2754);
      const dest = LatLng(13.0784, 80.2606);

      final result = await routingService.getRoute(origin, dest);

      // Verify that RouteResult is returned regardless of internet availability
      expect(result.distanceMeters, greaterThan(0));
      expect(result.polylinePoints.length, greaterThanOrEqualTo(2));
      expect(result.durationMinutes, greaterThan(0));
    });

    test('Single-trigger invariant: alarm only fires at most once per journey', () {
      // Simulating the state transition machine of JourneyProvider
      bool hasTriggeredAlarm = false;
      int alarmTriggerCount = 0;

      void onLocationTick({
        required double distanceMeters,
        required double radiusMeters,
        required int etaMinutes,
        required int prepWindowMinutes,
      }) {
        if (!hasTriggeredAlarm) {
          final shouldTrigger = GeoUtils.shouldTriggerAlarm(
            distanceMeters: distanceMeters,
            radiusMeters: radiusMeters,
            etaMinutes: etaMinutes,
            prepWindowMinutes: prepWindowMinutes,
          );

          if (shouldTrigger) {
            hasTriggeredAlarm = true;
            alarmTriggerCount++;
          }
        }
      }

      // Tick 1: Far away (5 km, ETA 15m) -> No alarm
      onLocationTick(
        distanceMeters: 5000,
        radiusMeters: 2000,
        etaMinutes: 15,
        prepWindowMinutes: 5,
      );
      expect(alarmTriggerCount, equals(0));
      expect(hasTriggeredAlarm, isFalse);

      // Tick 2: Approaching (3 km, ETA 8m) -> No alarm
      onLocationTick(
        distanceMeters: 3000,
        radiusMeters: 2000,
        etaMinutes: 8,
        prepWindowMinutes: 5,
      );
      expect(alarmTriggerCount, equals(0));

      // Tick 3: Inside Alert Zone (1.8 km, ETA 4m) -> Alarm triggers!
      onLocationTick(
        distanceMeters: 1800,
        radiusMeters: 2000,
        etaMinutes: 4,
        prepWindowMinutes: 5,
      );
      expect(alarmTriggerCount, equals(1));
      expect(hasTriggeredAlarm, isTrue);

      // Tick 4: Getting even closer (1.2 km, ETA 2m) -> MUST NOT trigger duplicate alarm!
      onLocationTick(
        distanceMeters: 1200,
        radiusMeters: 2000,
        etaMinutes: 2,
        prepWindowMinutes: 5,
      );
      expect(alarmTriggerCount, equals(1));

      // Tick 5: Arrived at stop (200m, ETA 0m) -> MUST NOT trigger duplicate alarm!
      onLocationTick(
        distanceMeters: 200,
        radiusMeters: 2000,
        etaMinutes: 0,
        prepWindowMinutes: 5,
      );
      expect(alarmTriggerCount, equals(1));
    });

    test('Dismissal lifecycle cleanly transitions journey outcome', () {
      final dest = Destination(
        name: 'Airport Station',
        address: 'Terminal 1',
        latitude: 12.9856,
        longitude: 80.1693,
        radiusMeters: 2000,
      );

      // Initial Journey
      var journey = Journey(
        destination: dest,
        startTime: DateTime.now().subtract(const Duration(minutes: 40)),
        startLatitude: 13.0827,
        startLongitude: 80.2707,
        initialDistanceMeters: 18000,
        alertRadiusMeters: 2000,
        prepWindowMinutes: 5,
        outcome: JourneyOutcome.inProgress,
      );
      expect(journey.outcome, equals(JourneyOutcome.inProgress));

      // Alarm triggers
      journey = journey.copyWith(
        alarmTriggered: true,
        alarmTriggeredAt: DateTime.now(),
        finalDistanceMeters: 1500,
      );
      expect(journey.alarmTriggered, isTrue);

      // User taps Dismiss
      journey = journey.copyWith(
        outcome: JourneyOutcome.alarmTriggeredAndDismissed,
        endTime: DateTime.now(),
      );
      expect(journey.outcome, equals(JourneyOutcome.alarmTriggeredAndDismissed));
      expect(journey.endTime, isNotNull);
      expect(journey.durationMinutes, greaterThanOrEqualTo(40));
    });
  });
}
