import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

class PermissionStatusResult {
  final bool hasLocationPermission;
  final bool isLocationServiceEnabled;
  final bool hasNotificationPermission;
  final bool isBatteryOptimizationIgnored;
  final String? errorMessage;

  PermissionStatusResult({
    required this.hasLocationPermission,
    required this.isLocationServiceEnabled,
    required this.hasNotificationPermission,
    required this.isBatteryOptimizationIgnored,
    this.errorMessage,
  });

  bool get isReadyForMonitoring =>
      hasLocationPermission && isLocationServiceEnabled && hasNotificationPermission;
}

class PermissionUtils {
  /// Checks all critical permissions needed for background proximity monitoring.
  static Future<PermissionStatusResult> checkAllPermissions() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    final hasLocation = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    final NotificationPermission notificationStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    final bool hasNotification =
        notificationStatus == NotificationPermission.granted;

    final bool batteryIgnored =
        await FlutterForegroundTask.isIgnoringBatteryOptimizations;

    String? error;
    if (!serviceEnabled) {
      error = 'Location services (GPS) are turned off on your device.';
    } else if (permission == LocationPermission.denied) {
      error = 'Location permission is required to track your proximity to the stop.';
    } else if (permission == LocationPermission.deniedForever) {
      error = 'Location permission is permanently denied. Please enable it in device settings.';
    } else if (!hasNotification) {
      error = 'Notification permission is required for ongoing tracking and loud alarm alerts.';
    }

    return PermissionStatusResult(
      hasLocationPermission: hasLocation,
      isLocationServiceEnabled: serviceEnabled,
      hasNotificationPermission: hasNotification,
      isBatteryOptimizationIgnored: batteryIgnored,
      errorMessage: error,
    );
  }

  /// Requests location and notification permissions.
  static Future<PermissionStatusResult> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final NotificationPermission notificationStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    final hasLocation = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    final NotificationPermission updatedNotification =
        await FlutterForegroundTask.checkNotificationPermission();

    final bool batteryIgnored =
        await FlutterForegroundTask.isIgnoringBatteryOptimizations;

    return PermissionStatusResult(
      hasLocationPermission: hasLocation,
      isLocationServiceEnabled: serviceEnabled,
      hasNotificationPermission: updatedNotification == NotificationPermission.granted,
      isBatteryOptimizationIgnored: batteryIgnored,
    );
  }

  /// Opens system settings for battery optimization.
  static Future<bool> requestIgnoreBatteryOptimization() async {
    return await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
  }

  /// Opens app settings if permissions were denied forever.
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Opens device location settings.
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
