import 'package:flutter/material.dart';
import '../data/models/app_settings.dart';
import '../data/repositories/local_storage_repository.dart';

class SettingsProvider with ChangeNotifier {
  final LocalStorageRepository _repository;
  AppSettings _settings = AppSettings();

  SettingsProvider(this._repository) {
    _loadSettings();
  }

  AppSettings get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;
  double get defaultRadiusMeters => _settings.defaultRadiusMeters;
  int get defaultPrepWindowMinutes => _settings.defaultPrepWindowMinutes;
  String get alarmSoundId => _settings.alarmSoundId;
  bool get vibrationEnabled => _settings.vibrationEnabled;
  bool get repeatAlarm => _settings.repeatAlarm;
  int get repeatIntervalMinutes => _settings.repeatIntervalMinutes;
  bool get hasSeenBatteryGuidance => _settings.hasSeenBatteryGuidance;

  Future<void> _loadSettings() async {
    _settings = await _repository.loadSettings();
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateDefaultRadius(double radiusMeters) async {
    _settings = _settings.copyWith(defaultRadiusMeters: radiusMeters);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateDefaultPrepWindow(int minutes) async {
    _settings = _settings.copyWith(defaultPrepWindowMinutes: minutes);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateAlarmSound(String soundId) async {
    _settings = _settings.copyWith(alarmSoundId: soundId);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateVibration(bool enabled) async {
    _settings = _settings.copyWith(vibrationEnabled: enabled);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateRepeatAlarm(bool repeat, {int? intervalMinutes}) async {
    _settings = _settings.copyWith(
      repeatAlarm: repeat,
      repeatIntervalMinutes: intervalMinutes ?? _settings.repeatIntervalMinutes,
    );
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> markBatteryGuidanceSeen() async {
    _settings = _settings.copyWith(hasSeenBatteryGuidance: true);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }
}
