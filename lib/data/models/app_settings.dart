import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class AppSettings {
  final ThemeMode themeMode;
  final double defaultRadiusMeters;
  final int defaultPrepWindowMinutes;
  final String alarmSoundId;
  final bool vibrationEnabled;
  final bool repeatAlarm;
  final int repeatIntervalMinutes;
  final bool silentModeOverrideNoticeAcknowledged;
  final bool hasSeenBatteryGuidance;

  AppSettings({
    this.themeMode = ThemeMode.system,
    this.defaultRadiusMeters = AppConstants.defaultRadiusMeters,
    this.defaultPrepWindowMinutes = AppConstants.defaultPrepWindowMinutes,
    this.alarmSoundId = AppConstants.soundRadar,
    this.vibrationEnabled = true,
    this.repeatAlarm = true,
    this.repeatIntervalMinutes = 2,
    this.silentModeOverrideNoticeAcknowledged = false,
    this.hasSeenBatteryGuidance = false,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? defaultRadiusMeters,
    int? defaultPrepWindowMinutes,
    String? alarmSoundId,
    bool? vibrationEnabled,
    bool? repeatAlarm,
    int? repeatIntervalMinutes,
    bool? silentModeOverrideNoticeAcknowledged,
    bool? hasSeenBatteryGuidance,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultRadiusMeters: defaultRadiusMeters ?? this.defaultRadiusMeters,
      defaultPrepWindowMinutes:
          defaultPrepWindowMinutes ?? this.defaultPrepWindowMinutes,
      alarmSoundId: alarmSoundId ?? this.alarmSoundId,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      repeatAlarm: repeatAlarm ?? this.repeatAlarm,
      repeatIntervalMinutes:
          repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      silentModeOverrideNoticeAcknowledged:
          silentModeOverrideNoticeAcknowledged ??
              this.silentModeOverrideNoticeAcknowledged,
      hasSeenBatteryGuidance:
          hasSeenBatteryGuidance ?? this.hasSeenBatteryGuidance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'defaultRadiusMeters': defaultRadiusMeters,
      'defaultPrepWindowMinutes': defaultPrepWindowMinutes,
      'alarmSoundId': alarmSoundId,
      'vibrationEnabled': vibrationEnabled,
      'repeatAlarm': repeatAlarm,
      'repeatIntervalMinutes': repeatIntervalMinutes,
      'silentModeOverrideNoticeAcknowledged':
          silentModeOverrideNoticeAcknowledged,
      'hasSeenBatteryGuidance': hasSeenBatteryGuidance,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      defaultRadiusMeters:
          (json['defaultRadiusMeters'] as num?)?.toDouble() ??
              AppConstants.defaultRadiusMeters,
      defaultPrepWindowMinutes:
          (json['defaultPrepWindowMinutes'] as num?)?.toInt() ??
              AppConstants.defaultPrepWindowMinutes,
      alarmSoundId: json['alarmSoundId'] as String? ?? AppConstants.soundRadar,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      repeatAlarm: json['repeatAlarm'] as bool? ?? true,
      repeatIntervalMinutes:
          (json['repeatIntervalMinutes'] as num?)?.toInt() ?? 2,
      silentModeOverrideNoticeAcknowledged:
          json['silentModeOverrideNoticeAcknowledged'] as bool? ?? false,
      hasSeenBatteryGuidance:
          json['hasSeenBatteryGuidance'] as bool? ?? false,
    );
  }
}
