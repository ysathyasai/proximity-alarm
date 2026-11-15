import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
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
  String get accentColorKey => _settings.accentColorKey;
  Color get accentColor => _settings.accentColor;
  double get defaultRadiusMeters => _settings.defaultRadiusMeters;
  int get defaultPrepWindowMinutes => _settings.defaultPrepWindowMinutes;
  AlertMode get alertMode => _settings.alertMode;
  bool get useTimerAlert => _settings.useTimerAlert;
  bool get earlyWarningEnabled => _settings.earlyWarningEnabled;
  DistanceUnit get distanceUnit => _settings.distanceUnit;
  MonitoringProfile get monitoringProfile => _settings.monitoringProfile;
  bool get batterySaverMode => _settings.batterySaverMode;
  bool get preferOfflineGoogleMaps => _settings.preferOfflineGoogleMaps;

  String get alarmSoundId => _settings.alarmSoundId;
  VibrationPatternType get vibrationPattern => _settings.vibrationPattern;
  bool get vibrationEnabled => _settings.vibrationEnabled;
  bool get repeatAlarm => _settings.repeatAlarm;
  int get repeatIntervalMinutes => _settings.repeatIntervalMinutes;
  int get snoozeDurationMinutes => _settings.snoozeDurationMinutes;
  bool get volumeEscalation => _settings.volumeEscalation;
  bool get requireSlideToDismiss => _settings.requireSlideToDismiss;

  bool get showRadiusCircle => _settings.showRadiusCircle;
  bool get showConnectingLine => _settings.showConnectingLine;
  bool get showRoutePolyline => _settings.showRoutePolyline;
  bool get showSpeedMetric => _settings.showSpeedMetric;
  bool get showEtaMetric => _settings.showEtaMetric;

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

  Future<void> updateAccentColor(String colorKey) async {
    _settings = _settings.copyWith(accentColorKey: colorKey);
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

  Future<void> updateAlertMode(AlertMode mode) async {
    final bool timerActive = mode != AlertMode.fixedRadius;
    _settings = _settings.copyWith(
      alertMode: mode,
      useTimerAlert: timerActive,
    );
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateUseTimerAlert(bool enabled) async {
    _settings = _settings.copyWith(
      useTimerAlert: enabled,
      alertMode: enabled ? AlertMode.combined : AlertMode.fixedRadius,
    );
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateEarlyWarning(bool enabled) async {
    _settings = _settings.copyWith(earlyWarningEnabled: enabled);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateDistanceUnit(DistanceUnit unit) async {
    _settings = _settings.copyWith(distanceUnit: unit);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateMonitoringProfile(MonitoringProfile profile) async {
    _settings = _settings.copyWith(
      monitoringProfile: profile,
      batterySaverMode: profile == MonitoringProfile.batterySaver,
    );
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateBatterySaverMode(bool enabled) async {
    _settings = _settings.copyWith(
      batterySaverMode: enabled,
      monitoringProfile:
          enabled ? MonitoringProfile.batterySaver : MonitoringProfile.balanced,
    );
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updatePreferOfflineGoogleMaps(bool enabled) async {
    _settings = _settings.copyWith(preferOfflineGoogleMaps: enabled);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateAlarmSound(String soundId) async {
    _settings = _settings.copyWith(alarmSoundId: soundId);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateVibrationPattern(VibrationPatternType pattern) async {
    _settings = _settings.copyWith(
      vibrationPattern: pattern,
      vibrationEnabled: pattern != VibrationPatternType.none,
    );
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateVibration(bool enabled) async {
    _settings = _settings.copyWith(
      vibrationEnabled: enabled,
      vibrationPattern:
          enabled ? VibrationPatternType.continuous : VibrationPatternType.none,
    );
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

  Future<void> updateSnoozeDuration(int minutes) async {
    _settings = _settings.copyWith(snoozeDurationMinutes: minutes);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateVolumeEscalation(bool enabled) async {
    _settings = _settings.copyWith(volumeEscalation: enabled);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateRequireSlideToDismiss(bool enabled) async {
    _settings = _settings.copyWith(requireSlideToDismiss: enabled);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateMapOverlays({
    bool? showRadiusCircle,
    bool? showConnectingLine,
    bool? showRoutePolyline,
  }) async {
    _settings = _settings.copyWith(
      showRadiusCircle: showRadiusCircle ?? _settings.showRadiusCircle,
      showConnectingLine: showConnectingLine ?? _settings.showConnectingLine,
      showRoutePolyline: showRoutePolyline ?? _settings.showRoutePolyline,
    );
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> updateMetricVisibility({
    bool? showSpeedMetric,
    bool? showEtaMetric,
  }) async {
    _settings = _settings.copyWith(
      showSpeedMetric: showSpeedMetric ?? _settings.showSpeedMetric,
      showEtaMetric: showEtaMetric ?? _settings.showEtaMetric,
    );
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> markBatteryGuidanceSeen() async {
    _settings = _settings.copyWith(hasSeenBatteryGuidance: true);
    notifyListeners();
    await _repository.saveSettings(_settings);
  }

  Future<void> resetToDefaults() async {
    await _repository.resetSettingsToDefault();
    _settings = AppSettings();
    notifyListeners();
  }
}
