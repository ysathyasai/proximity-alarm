class AppConstants {
  // App Info
  static const String appName = 'Proximity Alarm';
  static const String appVersion = '1.0.0';
  static const String userAgent =
      'ProximityAlarmApp/1.0 (transit.safety.proximity.alarm@example.com)';

  // Default Monitoring Values
  static const double defaultRadiusMeters = 2000.0; // 2 km
  static const int defaultPrepWindowMinutes = 5; // 5 min before ETA
  static const double minRadiusMeters = 200.0;
  static const double maxRadiusMeters = 10000.0; // 10 km

  // Standard Presets
  static const List<double> radiusPresets = [500.0, 1000.0, 2000.0, 3000.0, 5000.0];
  static const List<int> prepWindowPresets = [2, 5, 10, 15];

  // GPS & Accuracy Filtering
  static const double maxAcceptableGpsAccuracyMeters = 65.0; // reject poor fixes
  static const double maxPlausibleTransitSpeedMetersPerSec = 70.0; // ~252 km/h max
  static const double averageCityTransitSpeedKmh = 30.0; // Fallback speed for ETA

  // Adaptive Polling Intervals
  static const int farDistanceThresholdMeters = 10000; // >10km: check every 30s
  static const int mediumDistanceThresholdMeters = 3000; // 3-10km: check every 15s
  static const int closeDistanceThresholdMeters = 1000; // 1-3km: check every 7s
  // <1km: check every 3s

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

