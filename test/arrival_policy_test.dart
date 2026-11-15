import 'package:flutter_test/flutter_test.dart';
import 'package:proximity_alarm/domain_arrival_policy.dart';

void main() {
  group('ArrivalPolicy', () {
    test('triggers on radius fallback', () {
      expect(
        ArrivalPolicy.shouldTrigger(
          distanceMeters: 1900,
          accuracyMeters: 20,
          radiusMeters: 2000,
          routeEtaSeconds: null,
          preparationMinutes: 5,
        ),
        isTrue,
      );
    });

    test('triggers when road ETA is within preparation window', () {
      expect(
        ArrivalPolicy.shouldTrigger(
          distanceMeters: 7000,
          accuracyMeters: 10,
          radiusMeters: 2000,
          routeEtaSeconds: 240,
          preparationMinutes: 5,
        ),
        isTrue,
      );
    });

    test('continues safely without route service', () {
      expect(
        ArrivalPolicy.shouldTrigger(
          distanceMeters: 2300,
          accuracyMeters: 25,
          radiusMeters: 2000,
          routeEtaSeconds: null,
          preparationMinutes: 5,
        ),
        isFalse,
      );
    });

    test('does not trigger when neither rule is satisfied', () {
      expect(
        ArrivalPolicy.shouldTrigger(
          distanceMeters: 9000,
          accuracyMeters: 10,
          radiusMeters: 2000,
          routeEtaSeconds: 900,
          preparationMinutes: 5,
        ),
        isFalse,
      );
    });

    test('does not use low-quality accuracy to expand the radius', () {
      expect(
        ArrivalPolicy.shouldTrigger(
          distanceMeters: 2100,
          accuracyMeters: 150,
          radiusMeters: 2000,
          routeEtaSeconds: null,
          preparationMinutes: 5,
        ),
        isFalse,
      );
    });
  });
}
