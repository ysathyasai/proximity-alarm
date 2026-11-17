import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class AppSettings {
  final AppThemeStyle appThemeStyle;
  final String accentColorKey;
  final double defaultRadiusMeters;
  final int defaultPrepWindowMinutes;
  final AlertMode alertMode;
  final bool useTimerAlert;
  final bool earlyWarningEnabled;
  final DistanceUnit distanceUnit;
  final MonitoringProfile monitoringProfile;
  final bool batterySaverMode;
  final bool preferOfflineGoogleMaps;

  // Alarm & Audio
  final String alarmSoundId;
  final String? customSoundPath;
  final String? customSoundTitle;
  final VibrationPatternType vibrationPattern;
  final bool vibrationEnabled;
  final bool repeatAlarm;
  final int repeatIntervalMinutes;
  final int snoozeDurationMinutes;
  final bool volumeEscalation;
  final int volumeRampSeconds;
  final double alarmVolume;
  final int maxAlarmDurationMinutes;
  final bool requireSlideToDismiss;

  // Map & Presentation
  final bool showRadiusCircle;
  final bool showConnectingLine;
  final bool showRoutePolyline;
  final bool showSpeedMetric;
  final bool showEtaMetric;

  // Guidance & Notices
  final bool silentModeOverrideNoticeAcknowledged;
  final bool hasSeenBatteryGuidance;

  AppSettings({
    AppThemeStyle appThemeStyle = AppThemeStyle.system,
    ThemeMode? themeMode,
    this.accentColorKey = AppConstants.colorBlue,
    this.defaultRadiusMeters = AppConstants.defaultRadiusMeters,
    this.defaultPrepWindowMinutes = AppConstants.defaultPrepWindowMinutes,
    this.alertMode = AlertMode.combined,
    this.useTimerAlert = true,
    this.earlyWarningEnabled = true,
    this.distanceUnit = DistanceUnit.metric,
    this.monitoringProfile = MonitoringProfile.balanced,
    this.batterySaverMode = false,
    this.preferOfflineGoogleMaps = false,
    this.alarmSoundId = AppConstants.soundRadar,
    this.customSoundPath,
    this.customSoundTitle,
    this.vibrationPattern = VibrationPatternType.continuous,
    this.vibrationEnabled = true,
    this.repeatAlarm = true,
    this.repeatIntervalMinutes = 2,
    this.snoozeDurationMinutes = 5,
    this.volumeEscalation = true,
    this.volumeRampSeconds = 10,
    this.alarmVolume = 1.0,
    this.maxAlarmDurationMinutes = 5,
    this.requireSlideToDismiss = false,
    this.showRadiusCircle = true,
    this.showConnectingLine = true,
    this.showRoutePolyline = true,
    this.showSpeedMetric = true,
    this.showEtaMetric = true,
    this.silentModeOverrideNoticeAcknowledged = false,
    this.hasSeenBatteryGuidance = false,
  }) : appThemeStyle = (themeMode != null && appThemeStyle == AppThemeStyle.system)
            ? (themeMode == ThemeMode.light
                ? AppThemeStyle.light
                : (themeMode == ThemeMode.dark
                    ? AppThemeStyle.dark
                    : AppThemeStyle.system))
            : appThemeStyle;

  bool get isPitchBlack => appThemeStyle == AppThemeStyle.pitchBlack;

  ThemeMode get themeMode {
    switch (appThemeStyle) {
      case AppThemeStyle.light:
        return ThemeMode.light;
      case AppThemeStyle.dark:
      case AppThemeStyle.pitchBlack:
        return ThemeMode.dark;
      case AppThemeStyle.system:
        return ThemeMode.system;
    }
  }

  Color get accentColor =>
      AppConstants.accentColors[accentColorKey] ?? const Color(0xFF2563EB);

  AppSettings copyWith({
    AppThemeStyle? appThemeStyle,
    ThemeMode? themeMode,
    String? accentColorKey,
    double? defaultRadiusMeters,
    int? defaultPrepWindowMinutes,
    AlertMode? alertMode,
    bool? useTimerAlert,
    bool? earlyWarningEnabled,
    DistanceUnit? distanceUnit,
    MonitoringProfile? monitoringProfile,
    bool? batterySaverMode,
    bool? preferOfflineGoogleMaps,
    String? alarmSoundId,
    String? customSoundPath,
    String? customSoundTitle,
    bool clearCustomSound = false,
    VibrationPatternType? vibrationPattern,
    bool? vibrationEnabled,
    bool? repeatAlarm,
    int? repeatIntervalMinutes,
    int? snoozeDurationMinutes,
    bool? volumeEscalation,
    int? volumeRampSeconds,
    double? alarmVolume,
    int? maxAlarmDurationMinutes,
    bool? requireSlideToDismiss,
    bool? showRadiusCircle,
    bool? showConnectingLine,
    bool? showRoutePolyline,
    bool? showSpeedMetric,
    bool? showEtaMetric,
    bool? silentModeOverrideNoticeAcknowledged,
    bool? hasSeenBatteryGuidance,
  }) {
    AppThemeStyle effectiveStyle = appThemeStyle ?? this.appThemeStyle;
    if (themeMode != null && appThemeStyle == null) {
      if (themeMode == ThemeMode.light) {
        effectiveStyle = AppThemeStyle.light;
      } else if (themeMode == ThemeMode.dark) {
        effectiveStyle = isPitchBlack ? AppThemeStyle.pitchBlack : AppThemeStyle.dark;
      } else {
        effectiveStyle = AppThemeStyle.system;
      }
    }

    return AppSettings(
      appThemeStyle: effectiveStyle,
      accentColorKey: accentColorKey ?? this.accentColorKey,
      defaultRadiusMeters: defaultRadiusMeters ?? this.defaultRadiusMeters,
      defaultPrepWindowMinutes:
          defaultPrepWindowMinutes ?? this.defaultPrepWindowMinutes,
      alertMode: alertMode ?? this.alertMode,
      useTimerAlert: useTimerAlert ?? this.useTimerAlert,
      earlyWarningEnabled: earlyWarningEnabled ?? this.earlyWarningEnabled,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      monitoringProfile: monitoringProfile ?? this.monitoringProfile,
      batterySaverMode: batterySaverMode ?? this.batterySaverMode,
      preferOfflineGoogleMaps:
          preferOfflineGoogleMaps ?? this.preferOfflineGoogleMaps,
      alarmSoundId: alarmSoundId ?? this.alarmSoundId,
      customSoundPath: clearCustomSound
          ? null
          : (customSoundPath ?? this.customSoundPath),
      customSoundTitle: clearCustomSound
          ? null
          : (customSoundTitle ?? this.customSoundTitle),
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      repeatAlarm: repeatAlarm ?? this.repeatAlarm,
      repeatIntervalMinutes:
          repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      snoozeDurationMinutes:
          snoozeDurationMinutes ?? this.snoozeDurationMinutes,
      volumeEscalation: volumeEscalation ?? this.volumeEscalation,
      volumeRampSeconds: volumeRampSeconds ?? this.volumeRampSeconds,
      alarmVolume: alarmVolume ?? this.alarmVolume,
      maxAlarmDurationMinutes:
          maxAlarmDurationMinutes ?? this.maxAlarmDurationMinutes,
      requireSlideToDismiss:
          requireSlideToDismiss ?? this.requireSlideToDismiss,
      showRadiusCircle: showRadiusCircle ?? this.showRadiusCircle,
      showConnectingLine: showConnectingLine ?? this.showConnectingLine,
      showRoutePolyline: showRoutePolyline ?? this.showRoutePolyline,
      showSpeedMetric: showSpeedMetric ?? this.showSpeedMetric,
      showEtaMetric: showEtaMetric ?? this.showEtaMetric,
      silentModeOverrideNoticeAcknowledged:
          silentModeOverrideNoticeAcknowledged ??
              this.silentModeOverrideNoticeAcknowledged,
      hasSeenBatteryGuidance:
          hasSeenBatteryGuidance ?? this.hasSeenBatteryGuidance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appThemeStyle': appThemeStyle.name,
      'themeMode': appThemeStyle == AppThemeStyle.pitchBlack ? 'dark' : appThemeStyle.name,
      'accentColorKey': accentColorKey,
      'defaultRadiusMeters': defaultRadiusMeters,
      'defaultPrepWindowMinutes': defaultPrepWindowMinutes,
      'alertMode': alertMode.name,
      'useTimerAlert': useTimerAlert,
      'earlyWarningEnabled': earlyWarningEnabled,
      'distanceUnit': distanceUnit.name,
      'monitoringProfile': monitoringProfile.name,
      'batterySaverMode': batterySaverMode,
      'preferOfflineGoogleMaps': preferOfflineGoogleMaps,
      'alarmSoundId': alarmSoundId,
      'customSoundPath': customSoundPath,
      'customSoundTitle': customSoundTitle,
      'vibrationPattern': vibrationPattern.name,
      'vibrationEnabled': vibrationEnabled,
      'repeatAlarm': repeatAlarm,
      'repeatIntervalMinutes': repeatIntervalMinutes,
      'snoozeDurationMinutes': snoozeDurationMinutes,
      'volumeEscalation': volumeEscalation,
      'volumeRampSeconds': volumeRampSeconds,
      'alarmVolume': alarmVolume,
      'maxAlarmDurationMinutes': maxAlarmDurationMinutes,
      'requireSlideToDismiss': requireSlideToDismiss,
      'showRadiusCircle': showRadiusCircle,
      'showConnectingLine': showConnectingLine,
      'showRoutePolyline': showRoutePolyline,
      'showSpeedMetric': showSpeedMetric,
      'showEtaMetric': showEtaMetric,
      'silentModeOverrideNoticeAcknowledged':
          silentModeOverrideNoticeAcknowledged,
      'hasSeenBatteryGuidance': hasSeenBatteryGuidance,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    AppThemeStyle style = AppThemeStyle.system;
    if (json['appThemeStyle'] != null) {
      style = AppThemeStyle.values.firstWhere(
        (e) => e.name == json['appThemeStyle'],
        orElse: () => AppThemeStyle.system,
      );
    } else if (json['themeMode'] != null) {
      final modeStr = json['themeMode'] as String;
      if (modeStr == 'pitchBlack') {
        style = AppThemeStyle.pitchBlack;
      } else if (modeStr == 'light') {
        style = AppThemeStyle.light;
      } else if (modeStr == 'dark') {
        style = AppThemeStyle.dark;
      } else {
        style = AppThemeStyle.system;
      }
    }

    return AppSettings(
      appThemeStyle: style,
      accentColorKey:
          json['accentColorKey'] as String? ?? AppConstants.colorBlue,
      defaultRadiusMeters:
          (json['defaultRadiusMeters'] as num?)?.toDouble() ??
              AppConstants.defaultRadiusMeters,
      defaultPrepWindowMinutes:
          (json['defaultPrepWindowMinutes'] as num?)?.toInt() ??
              AppConstants.defaultPrepWindowMinutes,
      alertMode: AlertMode.values.firstWhere(
        (e) => e.name == json['alertMode'],
        orElse: () => AlertMode.combined,
      ),
      useTimerAlert: json['useTimerAlert'] as bool? ?? true,
      earlyWarningEnabled: json['earlyWarningEnabled'] as bool? ?? true,
      distanceUnit: DistanceUnit.values.firstWhere(
        (e) => e.name == json['distanceUnit'],
        orElse: () => DistanceUnit.metric,
      ),
      monitoringProfile: MonitoringProfile.values.firstWhere(
        (e) => e.name == json['monitoringProfile'],
        orElse: () => (json['batterySaverMode'] as bool? ?? false)
            ? MonitoringProfile.batterySaver
            : MonitoringProfile.balanced,
      ),
      batterySaverMode: json['batterySaverMode'] as bool? ?? false,
      preferOfflineGoogleMaps:
          json['preferOfflineGoogleMaps'] as bool? ?? false,
      alarmSoundId: json['alarmSoundId'] as String? ?? AppConstants.soundRadar,
      customSoundPath: json['customSoundPath'] as String?,
      customSoundTitle: json['customSoundTitle'] as String?,
      vibrationPattern: VibrationPatternType.values.firstWhere(
        (e) => e.name == json['vibrationPattern'],
        orElse: () => VibrationPatternType.continuous,
      ),
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      repeatAlarm: json['repeatAlarm'] as bool? ?? true,
      repeatIntervalMinutes:
          (json['repeatIntervalMinutes'] as num?)?.toInt() ?? 2,
      snoozeDurationMinutes:
          (json['snoozeDurationMinutes'] as num?)?.toInt() ?? 5,
      volumeEscalation: json['volumeEscalation'] as bool? ?? true,
      volumeRampSeconds:
          (json['volumeRampSeconds'] as num?)?.toInt() ?? 10,
      alarmVolume: (json['alarmVolume'] as num?)?.toDouble() ?? 1.0,
      maxAlarmDurationMinutes:
          (json['maxAlarmDurationMinutes'] as num?)?.toInt() ?? 5,
      requireSlideToDismiss: json['requireSlideToDismiss'] as bool? ?? false,
      showRadiusCircle: json['showRadiusCircle'] as bool? ?? true,
      showConnectingLine: json['showConnectingLine'] as bool? ?? true,
      showRoutePolyline: json['showRoutePolyline'] as bool? ?? true,
      showSpeedMetric: json['showSpeedMetric'] as bool? ?? true,
      showEtaMetric: json['showEtaMetric'] as bool? ?? true,
      silentModeOverrideNoticeAcknowledged:
          json['silentModeOverrideNoticeAcknowledged'] as bool? ?? false,
      hasSeenBatteryGuidance:
          json['hasSeenBatteryGuidance'] as bool? ?? false,
    );
  }
}
