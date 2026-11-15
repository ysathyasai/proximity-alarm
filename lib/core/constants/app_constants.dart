import 'package:flutter/material.dart';

enum AlertMode {
  combined, // Triggers on distance radius OR ETA preparation window (Recommended)
  fixedRadius, // Triggers strictly on physical distance radius
  adaptiveEta, // Triggers on estimated travel time window (with radius fallback)
}

enum DistanceUnit {
  metric, // km, m, km/h
  imperial, // mi, ft, mph
}

enum MonitoringProfile {
  balanced, // 100m/50m/15m/5m adaptive GPS (Best blend of battery & accuracy)
  responsive, // 50m/25m/10m/3m high-frequency GPS (Express trains & highway transit)
  batterySaver, // 250m/100m/35m/10m relaxed GPS (Overnight long-haul journeys)
}

enum VibrationPatternType {
  continuous,
  pulse,
  heartbeat,
  urgent,
  none,
}

class AppConstants {
  // App Info
  static const String appName = 'Proximity Alarm';
  static const String appVersion = '1.1.0';
  static const String userAgent =
      'ProximityAlarmApp/1.1 (transit.safety.proximity.alarm@example.com)';

  // Default Monitoring Values
  static const double defaultRadiusMeters = 2000.0; // 2 km
  static const int defaultPrepWindowMinutes = 5; // 5 min before ETA
  static const double minRadiusMeters = 200.0;
  static const double maxRadiusMeters = 10000.0; // 10 km

  // Standard Presets
  static const List<double> radiusPresets = [500.0, 1000.0, 2000.0, 3000.0, 5000.0];
  static const List<int> prepWindowPresets = [2, 5, 10, 15];
  static const List<int> snoozePresets = [2, 3, 5, 10];

  // Accent Colors
  static const String colorBlue = 'blue';
  static const String colorGreen = 'green';
  static const String colorAmber = 'amber';
  static const String colorPurple = 'purple';
  static const String colorRed = 'red';
  static const String colorCyan = 'cyan';

  static const Map<String, Color> accentColors = {
    colorBlue: Color(0xFF2563EB), // Sapphire Blue
    colorGreen: Color(0xFF059669), // Emerald Green
    colorAmber: Color(0xFFD97706), // Sunset Amber
    colorPurple: Color(0xFF7C3AED), // Electric Violet
    colorRed: Color(0xFFDC2626), // Crimson Red
    colorCyan: Color(0xFF0891B2), // Ocean Cyan
  };

  static const Map<String, String> accentColorNames = {
    colorBlue: 'Sapphire Blue',
    colorGreen: 'Emerald Green',
    colorAmber: 'Sunset Amber',
    colorPurple: 'Electric Violet',
    colorRed: 'Crimson Red',
    colorCyan: 'Ocean Cyan',
  };

  // GPS & Accuracy Filtering
  static const double maxAcceptableGpsAccuracyMeters = 65.0; // reject poor fixes
  static const double maxPlausibleTransitSpeedMetersPerSec = 70.0; // ~252 km/h max
  static const double averageCityTransitSpeedKmh = 30.0; // Fallback speed for ETA

  // Adaptive Polling Intervals
  static const int farDistanceThresholdMeters = 10000; // >10km
  static const int mediumDistanceThresholdMeters = 3000; // 3-10km
  static const int closeDistanceThresholdMeters = 1000; // 1-3km

  // OpenStreetMap Tile Configuration
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmAttribution =
      '© OpenStreetMap contributors';

  // Geocoding & Routing APIs
  static const String nominatimSearchUrl =
      'https://nominatim.openstreetmap.org/search';
  static const String nominatimReverseUrl =
      'https://nominatim.openstreetmap.org/reverse';
  static const String osrmRoutingUrl =
      'https://router.project-osrm.org/route/v1/driving';

  // Sound IDs
  static const String soundRadar = 'radar';
  static const String soundTransit = 'transit';
  static const String soundSiren = 'siren';
  static const String soundBell = 'bell';

  static const Map<String, String> soundNames = {
    soundRadar: 'Radar Pulse (Urgent)',
    soundTransit: 'Transit Arrival Chime',
    soundSiren: 'Emergency Siren',
    soundBell: 'Piercing Bell',
  };

  static const Map<String, String> soundAssetPaths = {
    soundRadar: 'assets/sounds/alarm_radar.wav',
    soundTransit: 'assets/sounds/alarm_transit.wav',
    soundSiren: 'assets/sounds/alarm_siren.wav',
    soundBell: 'assets/sounds/alarm_bell.wav',
  };
}

