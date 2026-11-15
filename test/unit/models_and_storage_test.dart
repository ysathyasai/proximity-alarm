import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proximity_alarm/core/constants/app_constants.dart';
import 'package:proximity_alarm/data/models/app_settings.dart';
import 'package:proximity_alarm/data/models/destination.dart';
import 'package:proximity_alarm/data/models/journey.dart';
import 'package:proximity_alarm/data/repositories/local_storage_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Models Serialization Tests', () {
    test('Destination JSON serialization & deserialization', () {
      final dest = Destination(
        id: 'dest_test_1',
        name: 'Work Office',
        address: '123 Tech Park',
        latitude: 12.9716,
        longitude: 77.5946,
        radiusMeters: 1500.0,
        category: 'work',
        createdAt: DateTime(2026, 11, 1, 8, 30),
      );

      final json = dest.toJson();
      final fromJson = Destination.fromJson(json);

      expect(fromJson.id, equals(dest.id));
      expect(fromJson.name, equals('Work Office'));
      expect(fromJson.address, equals('123 Tech Park'));
      expect(fromJson.latitude, equals(12.9716));
      expect(fromJson.longitude, equals(77.5946));
      expect(fromJson.radiusMeters, equals(1500.0));
      expect(fromJson.category, equals('work'));
    });

    test('Journey JSON serialization & deserialization', () {
      final dest = Destination(
        name: 'Metro Terminal',
        address: 'Platform 2',
        latitude: 13.0827,
        longitude: 80.2707,
      );

      final startTime = DateTime(2026, 11, 1, 9, 0);
      final endTime = DateTime(2026, 11, 1, 10, 15);

      final journey = Journey(
        id: 'journey_test_1',
        destination: dest,
        startTime: startTime,
        endTime: endTime,
        startLatitude: 12.9800,
        startLongitude: 80.2200,
        initialDistanceMeters: 14500.0,
        finalDistanceMeters: 450.0,
        alertRadiusMeters: 1000.0,
        prepWindowMinutes: 5,
        outcome: JourneyOutcome.alarmTriggeredAndDismissed,
        alarmTriggered: true,
        alarmTriggeredAt: DateTime(2026, 11, 1, 10, 10),
      );

      final json = journey.toJson();
      final fromJson = Journey.fromJson(json);

      expect(fromJson.id, equals('journey_test_1'));
      expect(fromJson.destination.name, equals('Metro Terminal'));
      expect(fromJson.outcome, equals(JourneyOutcome.alarmTriggeredAndDismissed));
      expect(fromJson.alarmTriggered, isTrue);
      expect(fromJson.durationMinutes, equals(75));
    });

    test('AppSettings V3 JSON serialization & copyWith', () {
      final defaultSettings = AppSettings();
      expect(defaultSettings.themeMode, equals(ThemeMode.system));
      expect(defaultSettings.accentColorKey, equals(AppConstants.colorBlue));
      expect(defaultSettings.alertMode, equals(AlertMode.combined));
      expect(defaultSettings.distanceUnit, equals(DistanceUnit.metric));
      expect(defaultSettings.monitoringProfile, equals(MonitoringProfile.balanced));
      expect(defaultSettings.snoozeDurationMinutes, equals(3));
      expect(defaultSettings.volumeEscalation, isTrue);
      expect(defaultSettings.requireSlideToDismiss, isFalse);

      final updated = defaultSettings.copyWith(
        themeMode: ThemeMode.dark,
        accentColorKey: AppConstants.colorGreen,
        alertMode: AlertMode.fixedRadius,
        distanceUnit: DistanceUnit.imperial,
        monitoringProfile: MonitoringProfile.responsive,
        snoozeDurationMinutes: 5,
        volumeEscalation: false,
        requireSlideToDismiss: true,
        vibrationPattern: VibrationPatternType.pulse,
      );

      final json = updated.toJson();
      final fromJson = AppSettings.fromJson(json);

      expect(fromJson.themeMode, equals(ThemeMode.dark));
      expect(fromJson.accentColorKey, equals(AppConstants.colorGreen));
      expect(fromJson.alertMode, equals(AlertMode.fixedRadius));
      expect(fromJson.distanceUnit, equals(DistanceUnit.imperial));
      expect(fromJson.monitoringProfile, equals(MonitoringProfile.responsive));
      expect(fromJson.snoozeDurationMinutes, equals(5));
      expect(fromJson.volumeEscalation, isFalse);
      expect(fromJson.requireSlideToDismiss, isTrue);
      expect(fromJson.vibrationPattern, equals(VibrationPatternType.pulse));
    });
  });

  group('LocalStorageRepository Tests', () {
    test('resetSettingsToDefault restores settings without deleting history or destinations', () async {
      SharedPreferences.setMockInitialValues({
        'proximity_alarm_settings': '{"themeMode":"dark","defaultRadiusMeters":5000.0}',
        'proximity_alarm_saved_destinations': '[{"id":"d1","name":"Test Dest","address":"123 St","latitude":10.0,"longitude":20.0,"radiusMeters":2000.0,"category":"home","createdAt":"2026-11-01T00:00:00.000"}]',
        'proximity_alarm_journey_history': '[{"id":"j1","destination":{"id":"d1","name":"Test Dest","address":"123 St","latitude":10.0,"longitude":20.0,"radiusMeters":2000.0,"category":"home","createdAt":"2026-11-01T00:00:00.000"},"startTime":"2026-11-01T08:00:00.000","startLatitude":10.0,"startLongitude":20.0,"initialDistanceMeters":5000.0,"finalDistanceMeters":100.0,"alertRadiusMeters":2000.0,"prepWindowMinutes":5,"outcome":"completedNormally","alarmTriggered":false}]',
      });

      final repo = await LocalStorageRepository.getInstance();

      // Verify custom settings loaded
      final loadedSettings = await repo.loadSettings();
      expect(loadedSettings.themeMode, equals(ThemeMode.dark));
      expect(loadedSettings.defaultRadiusMeters, equals(5000.0));

      // Reset settings to default
      await repo.resetSettingsToDefault();

      // Settings should now be default
      final resetSettings = await repo.loadSettings();
      expect(resetSettings.themeMode, equals(ThemeMode.system));
      expect(resetSettings.defaultRadiusMeters, equals(AppConstants.defaultRadiusMeters));

      // CRITICAL: Destinations and history must remain intact!
      final destinations = await repo.loadSavedDestinations();
      expect(destinations.length, equals(1));
      expect(destinations.first.name, equals('Test Dest'));

      final history = await repo.loadJourneyHistory();
      expect(history.length, equals(1));
      expect(history.first.destination.name, equals('Test Dest'));
    });
  });
}
