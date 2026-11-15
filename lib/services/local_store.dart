import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/destination.dart';

class LocalStore {
  static const _savedKey = 'saved_destinations_v1';
  static const _historyKey = 'journey_history_v1';
  static const _recordedEventIdsKey = 'recorded_trigger_ids_v1';

  Future<List<Destination>> loadSavedDestinations() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_savedKey) ?? const [];
    return values
        .map((item) => Destination.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveDestination(Destination destination) async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_savedKey) ?? <String>[];
    final alreadyExists = values.any((item) {
      final saved = Destination.fromJson(jsonDecode(item) as Map<String, dynamic>);
      return (saved.latitude - destination.latitude).abs() < 0.0005 &&
          (saved.longitude - destination.longitude).abs() < 0.0005;
    });
    if (!alreadyExists) {
      values.insert(0, jsonEncode(destination.toJson()));
      await prefs.setStringList(_savedKey, values.take(30).toList());
    }
  }

  Future<List<Map<String, dynamic>>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_historyKey) ?? const [])
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }

  Future<void> recordTriggerIfNew(Map<String, dynamic> nativeStatus) async {
    final eventId = (nativeStatus['lastTriggeredAt'] ?? '').toString();
    if (eventId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_recordedEventIdsKey) ?? <String>[];
    if (seen.contains(eventId)) return;

    final entry = <String, dynamic>{
      'id': eventId,
      'destinationName': nativeStatus['destinationName'] ?? 'Destination',
      'triggerReason': nativeStatus['triggerReason'] ?? 'Arrival condition met',
      'triggeredAt': eventId,
      'distanceMeters': nativeStatus['triggerDistanceMeters'],
    };
    final history = prefs.getStringList(_historyKey) ?? <String>[];
    history.insert(0, jsonEncode(entry));
    await prefs.setStringList(_historyKey, history.take(100).toList());
    seen.insert(0, eventId);
    await prefs.setStringList(_recordedEventIdsKey, seen.take(150).toList());
  }
}
