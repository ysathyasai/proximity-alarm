import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/destination.dart';
import '../models/journey.dart';

class LocalStorageRepository {
  static const String _keySettings = 'proximity_alarm_settings';
  static const String _keySavedDestinations = 'proximity_alarm_saved_destinations';
  static const String _keyJourneyHistory = 'proximity_alarm_journey_history';
  static const String _keyActiveJourney = 'proximity_alarm_active_journey';
  static const String _keyRecentSearches = 'proximity_alarm_recent_searches';

  final SharedPreferences _prefs;

  LocalStorageRepository(this._prefs);

  static Future<LocalStorageRepository> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageRepository(prefs);
  }

  // Settings
  Future<AppSettings> loadSettings() async {
    final String? jsonStr = _prefs.getString(_keySettings);
    if (jsonStr == null) {
      return AppSettings();
    }
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return AppSettings.fromJson(map);
    } catch (_) {
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final String jsonStr = jsonEncode(settings.toJson());
    await _prefs.setString(_keySettings, jsonStr);
  }

  /// Resets user settings to factory defaults without deleting saved destinations or journey history.
  Future<void> resetSettingsToDefault() async {
    await _prefs.remove(_keySettings);
  }

  // Saved Destinations
  Future<List<Destination>> loadSavedDestinations() async {
    final String? jsonStr = _prefs.getString(_keySavedDestinations);
    if (jsonStr == null) {
      // Default sample destinations for first run
      return [
        Destination(
          name: 'Home',
          address: 'Default Home Address',
          latitude: 13.0827,
          longitude: 80.2707,
          radiusMeters: 1500,
          category: 'home',
        ),
        Destination(
          name: 'Central Station',
          address: 'Main Transit Terminal',
          latitude: 13.0839,
          longitude: 80.2754,
          radiusMeters: 2000,
          category: 'station',
        ),
      ];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((item) => Destination.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSavedDestinations(List<Destination> destinations) async {
    final String jsonStr =
        jsonEncode(destinations.map((d) => d.toJson()).toList());
    await _prefs.setString(_keySavedDestinations, jsonStr);
  }

  Future<void> clearSavedDestinations() async {
    await _prefs.remove(_keySavedDestinations);
  }

  // Journey History
  Future<List<Journey>> loadJourneyHistory() async {
    final String? jsonStr = _prefs.getString(_keyJourneyHistory);
    if (jsonStr == null) {
      return [];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((item) => Journey.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveJourneyHistory(List<Journey> history) async {
    final String jsonStr =
        jsonEncode(history.map((j) => j.toJson()).toList());
    await _prefs.setString(_keyJourneyHistory, jsonStr);
  }

  Future<void> clearJourneyHistory() async {
    await _prefs.remove(_keyJourneyHistory);
  }

  Future<void> addJourneyToHistory(Journey journey) async {
    final List<Journey> history = await loadJourneyHistory();
    // Keep max 50 recent journeys
    history.insert(0, journey);
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    await saveJourneyHistory(history);
  }

  // Active Journey Persistence (for process recovery)
  Future<Journey?> loadActiveJourney() async {
    final String? jsonStr = _prefs.getString(_keyActiveJourney);
    if (jsonStr == null) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return Journey.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveJourney(Journey? journey) async {
    if (journey == null) {
      await _prefs.remove(_keyActiveJourney);
    } else {
      final String jsonStr = jsonEncode(journey.toJson());
      await _prefs.setString(_keyActiveJourney, jsonStr);
    }
  }

  // Recent Searches (for instant offline suggestions)
  Future<List<Destination>> loadRecentSearches() async {
    final String? jsonStr = _prefs.getString(_keyRecentSearches);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((item) => Destination.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addRecentSearch(Destination destination) async {
    final List<Destination> recents = await loadRecentSearches();
    recents.removeWhere((d) =>
        d.name.toLowerCase() == destination.name.toLowerCase() ||
        (d.latitude == destination.latitude &&
            d.longitude == destination.longitude));
    recents.insert(0, destination);
    if (recents.length > 10) {
      recents.removeRange(10, recents.length);
    }
    await _prefs.setString(
      _keyRecentSearches,
      jsonEncode(recents.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(_keyRecentSearches);
  }
}
