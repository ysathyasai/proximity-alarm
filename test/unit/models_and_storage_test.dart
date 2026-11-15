import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proximity_alarm/data/models/app_settings.dart';
import 'package:proximity_alarm/data/models/destination.dart';
import 'package:proximity_alarm/data/models/journey.dart';

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

    test('AppSettings JSON serialization & copyWith', () {
      final defaultSettings = AppSettings();
      expect(defaultSettings.themeMode, equals(ThemeMode.system));
      expect(defaultSettings.defaultRadiusMeters, equals(2000.0));

      final updated = defaultSettings.copyWith(
        themeMode: ThemeMode.dark,
        defaultRadiusMeters: 3000.0,
        vibrationEnabled: false,
      );

      final json = updated.toJson();
      final fromJson = AppSettings.fromJson(json);

      expect(fromJson.themeMode, equals(ThemeMode.dark));
      expect(fromJson.defaultRadiusMeters, equals(3000.0));
      expect(fromJson.vibrationEnabled, isFalse);
    });
  });
}

