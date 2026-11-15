import 'package:flutter/services.dart';

/// Thin bridge to the Android-owned location foreground service and alarm.
/// iOS implementation is intentionally deferred; this class fails clearly there.
class NativeJourneyService {
  NativeJourneyService._();
  static final NativeJourneyService instance = NativeJourneyService._();

  static const MethodChannel _channel =
      MethodChannel('app.proximityalarm/journey');

  Future<void> startJourney({
    required String destinationName,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required int preparationMinutes,
  }) async {
    await _channel.invokeMethod<void>('startJourney', {
      'destinationName': destinationName,
      'destinationLatitude': latitude,
      'destinationLongitude': longitude,
      'radiusMeters': radiusMeters,
      'preparationMinutes': preparationMinutes,
    });
  }

  Future<void> stopJourney() => _channel.invokeMethod<void>('stopJourney');
  Future<void> dismissAlarm() =>
      _channel.invokeMethod<void>('dismissAlarm');

  Future<Map<String, dynamic>> getStatus() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('getStatus');
    return result ?? const <String, dynamic>{'state': 'UNKNOWN'};
  }

  Future<void> openBatterySettings() =>
      _channel.invokeMethod<void>('openBatterySettings');

  Future<void> openLocationSettings() =>
      _channel.invokeMethod<void>('openLocationSettings');
}
