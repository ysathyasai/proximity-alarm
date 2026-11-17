// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../core/utils/geo_utils.dart';
import '../core/utils/permission_utils.dart';
import '../data/models/app_settings.dart';
import '../data/models/destination.dart';
import '../data/models/journey.dart';
import '../data/repositories/local_storage_repository.dart';
import '../services/alarm_service.dart';
import '../services/background_monitoring_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/routing_service.dart';

enum JourneyStatus {
  idle,
  configuring,
  active,
  approaching,
  alarmActive,
  dismissed,
  cancelled,
}

class JourneyProvider with ChangeNotifier {
  final LocationService _locationService;
  final RoutingService _routingService;
  final AlarmService _alarmService;
  final NotificationService _notificationService;
  final BackgroundMonitoringService _backgroundService;
  final LocalStorageRepository _repository;

  JourneyStatus _status = JourneyStatus.idle;
  Destination? _selectedDestination;
  double _radiusMeters = AppConstants.defaultRadiusMeters;
  int _prepWindowMinutes = AppConstants.defaultPrepWindowMinutes;
  AlertMode _alertMode = AlertMode.combined;
  bool _useTimerAlert = true;
  bool _earlyWarningEnabled = true;
  MonitoringProfile _monitoringProfile = MonitoringProfile.balanced;
  DistanceUnit _distanceUnit = DistanceUnit.metric;
  int _snoozeDurationMinutes = 3;

  LatLng? _currentPosition;
  double _currentAccuracy = 0.0;
  double _currentSpeedMps = 0.0;
  double _currentHeading = 0.0;
  double _remainingDistanceMeters = 0.0;
  int _estimatedArrivalMinutes = 0;

  List<LatLng> _routePolyline = [];
  bool _isRoadRoute = false;

  bool _hasTriggeredAlarmThisJourney = false;
  bool _hasTriggeredEarlyWarning = false;
  DateTime? _journeyStartTime;
  double _initialDistanceMeters = 0.0;
  String? _warningMessage;

  StreamSubscription<LocationReading>? _locationSubscription;
  Timer? _notificationUpdateTimer;
  Timer? _simulationTimer;

  JourneyProvider({
    required LocationService locationService,
    required RoutingService routingService,
    required AlarmService alarmService,
    required NotificationService notificationService,
    required BackgroundMonitoringService backgroundService,
    required LocalStorageRepository repository,
  })  : _locationService = locationService,
        _routingService = routingService,
        _alarmService = alarmService,
        _notificationService = notificationService,
        _backgroundService = backgroundService,
        _repository = repository {
    _initListeners();
    _fetchInitialLocation();
  }

  // Getters
  JourneyStatus get status => _status;
  bool get isJourneyActive =>
      _status == JourneyStatus.active ||
      _status == JourneyStatus.approaching ||
      _status == JourneyStatus.alarmActive;
  bool get isAlarmActive => _status == JourneyStatus.alarmActive;
  Destination? get destination => _selectedDestination;
  double get radiusMeters => _radiusMeters;
  int get prepWindowMinutes => _prepWindowMinutes;
  AlertMode get alertMode => _alertMode;
  bool get useTimerAlert => _useTimerAlert;
  bool get earlyWarningEnabled => _earlyWarningEnabled;
  MonitoringProfile get monitoringProfile => _monitoringProfile;
  bool get batterySaverMode => _monitoringProfile == MonitoringProfile.batterySaver;
  DistanceUnit get distanceUnit => _distanceUnit;
  int get snoozeDurationMinutes => _snoozeDurationMinutes;
  LatLng? get currentPosition => _currentPosition;
  double get currentAccuracy => _currentAccuracy;
  double get currentSpeedMps => _currentSpeedMps;
  double get currentHeading => _currentHeading;
  double get remainingDistanceMeters => _remainingDistanceMeters;
  int get estimatedArrivalMinutes => _estimatedArrivalMinutes;
  List<LatLng> get routePolyline => List.unmodifiable(_routePolyline);
  bool get isRoadRoute => _isRoadRoute;
  String? get warningMessage => _warningMessage;
  DateTime? get journeyStartTime => _journeyStartTime;

  double get destinationBearing =>
      (_currentPosition != null && _selectedDestination != null)
          ? GeoUtils.calculateBearing(
              _currentPosition!, _selectedDestination!.latLng)
          : 0.0;

  double get journeyProgressPercent {
    if (_initialDistanceMeters <= 0 || _remainingDistanceMeters <= 0) return 0.0;
    final progress = 1.0 - (_remainingDistanceMeters / _initialDistanceMeters);
    return progress.clamp(0.0, 1.0);
  }

  void _initListeners() {
    _backgroundService.addDataCallback((data) {
      if (data is Map<String, dynamic>) {
        if (data['type'] == 'NOTIFICATION_BUTTON') {
          final action = data['actionId'] as String?;
          if (action == 'BTN_CANCEL') {
            stopJourney(outcome: JourneyOutcome.cancelledByUser);
          }
        }
      }
    });

    _notificationService.actionStream.listen((action) {
      if (action == 'DISMISS_ALARM') {
        dismissAlarm();
      }
    });
  }

  Future<void> _fetchInitialLocation() async {
    final fix = await _locationService.getCurrentLocation();
    if (fix != null) {
      _currentPosition = fix.position;
      _currentAccuracy = fix.accuracy;
      _currentSpeedMps = fix.speedMetersPerSec;
      notifyListeners();
    }
  }

  void selectDestination(Destination dest) {
    _selectedDestination = dest;
    _radiusMeters = dest.radiusMeters;
    _status = JourneyStatus.configuring;
    _warningMessage = null;

    if (_currentPosition != null) {
      _calculateInitialRoute();
    }
    notifyListeners();
  }

  void setRadius(double meters) {
    _radiusMeters = meters;
    if (_selectedDestination != null) {
      _selectedDestination = _selectedDestination!.copyWith(radiusMeters: meters);
    }
    notifyListeners();
  }

  void setPrepWindow(int minutes) {
    _prepWindowMinutes = minutes;
    notifyListeners();
  }

  void setAlertMode(AlertMode mode) {
    _alertMode = mode;
    _useTimerAlert = mode != AlertMode.fixedRadius;
    notifyListeners();
  }

  void setUseTimerAlert(bool enabled) {
    _useTimerAlert = enabled;
    _alertMode = enabled ? AlertMode.combined : AlertMode.fixedRadius;
    notifyListeners();
  }

  void setMonitoringProfile(MonitoringProfile profile) {
    _monitoringProfile = profile;
    if (_remainingDistanceMeters > 0) {
      _locationService.updateDistanceFilter(_getAdaptiveDistanceFilter(_remainingDistanceMeters));
    }
    notifyListeners();
  }

  void setBatterySaverMode(bool enabled) {
    setMonitoringProfile(
        enabled ? MonitoringProfile.batterySaver : MonitoringProfile.balanced);
  }

  void setDistanceUnit(DistanceUnit unit) {
    _distanceUnit = unit;
    notifyListeners();
  }

  Future<void> _calculateInitialRoute() async {
    if (_currentPosition == null || _selectedDestination == null) return;

    final destLatLng = _selectedDestination!.latLng;
    final directDist =
        GeoUtils.calculateDistanceMeters(_currentPosition!, destLatLng);
    _remainingDistanceMeters = directDist;
    _initialDistanceMeters = directDist;

    final routeResult =
        await _routingService.getRoute(_currentPosition!, destLatLng);
    _routePolyline = routeResult.polylinePoints;
    _isRoadRoute = routeResult.isRoadRoute;
    _remainingDistanceMeters = routeResult.distanceMeters;
    _estimatedArrivalMinutes = routeResult.durationMinutes;

    notifyListeners();
  }

  /// Starts live journey monitoring with Foreground Service & GPS tracking.
  Future<bool> startJourney({AppSettings? settings}) async {
    if (_selectedDestination == null) return false;

    // 1. Permission verification
    final permResult = await PermissionUtils.checkAllPermissions();
    if (!permResult.isReadyForMonitoring) {
      _warningMessage = permResult.errorMessage ?? 'Required permissions not granted.';
      notifyListeners();
      return false;
    }

    _status = JourneyStatus.active;
    _hasTriggeredAlarmThisJourney = false;
    _hasTriggeredEarlyWarning = false;
    _journeyStartTime = DateTime.now();
    _warningMessage = null;

    if (settings != null) {
      _alertMode = settings.alertMode;
      _useTimerAlert = settings.useTimerAlert;
      _monitoringProfile = settings.monitoringProfile;
      _distanceUnit = settings.distanceUnit;
      _earlyWarningEnabled = settings.earlyWarningEnabled;
      _snoozeDurationMinutes = settings.snoozeDurationMinutes;
    }

    // Check if starting inside alert radius
    if (_currentPosition != null) {
      final double dist = GeoUtils.calculateDistanceMeters(
          _currentPosition!, _selectedDestination!.latLng);
      if (dist <= _radiusMeters) {
        _warningMessage =
            'Notice: You are currently already within the ${Formatters.formatDistance(_radiusMeters, _distanceUnit)} alert radius!';
      }
    }

    // 2. Start Foreground Service for uninterrupted background tracking
    await _backgroundService.startForegroundMonitoring(
      destinationName: _selectedDestination!.name,
      destinationLat: _selectedDestination!.latitude,
      destinationLng: _selectedDestination!.longitude,
      radiusMeters: _radiusMeters,
      prepWindowMinutes: _prepWindowMinutes,
      initialStatusText:
          'Tracking to ${_selectedDestination!.name} (${Formatters.formatDistance(_remainingDistanceMeters, _distanceUnit)})',
    );

    // 3. Start Location Service Stream
    _locationService.startTracking(
      distanceFilterMeters: _getAdaptiveDistanceFilter(_remainingDistanceMeters),
    );

    _locationSubscription?.cancel();
    _locationSubscription =
        _locationService.locationStream.listen(_onLocationUpdate);

    // 4. Start periodic background notification updater
    _notificationUpdateTimer?.cancel();
    _notificationUpdateTimer =
        Timer.periodic(const Duration(seconds: 45), (_) => _refreshNotification());

    // Save active state to storage for recovery
    await _saveActiveState();
    notifyListeners();
    return true;
  }

  void _onLocationUpdate(LocationReading reading) {
    if (!isJourneyActive) return;

    _currentPosition = reading.position;
    _currentAccuracy = reading.accuracy;
    _currentSpeedMps = reading.speedMetersPerSec;
    _currentHeading = reading.heading;

    if (_selectedDestination == null) return;

    final destLatLng = _selectedDestination!.latLng;
    final dist = GeoUtils.calculateDistanceMeters(_currentPosition!, destLatLng);
    _remainingDistanceMeters = dist;

    // Update ETA
    _estimatedArrivalMinutes = GeoUtils.estimateEtaMinutes(
      distanceMeters: dist,
      currentSpeedMetersPerSec: _currentSpeedMps,
    );

    // Adaptive polling: adjust GPS distance filter based on proximity and profile
    final newFilter = _getAdaptiveDistanceFilter(dist);
    _locationService.updateDistanceFilter(newFilter);

    // Check early warning
    if (_earlyWarningEnabled &&
        !_hasTriggeredEarlyWarning &&
        _status == JourneyStatus.active) {
      final isEarly = GeoUtils.shouldTriggerEarlyWarning(
        distanceMeters: dist,
        radiusMeters: _radiusMeters,
        etaMinutes: _estimatedArrivalMinutes,
        prepWindowMinutes: _prepWindowMinutes,
      );
      if (isEarly) {
        _hasTriggeredEarlyWarning = true;
        _status = JourneyStatus.approaching;
      }
    }

    // Check Trigger Condition
    if (!_hasTriggeredAlarmThisJourney) {
      final bool shouldTrigger = GeoUtils.shouldTriggerAlarm(
        distanceMeters: dist,
        radiusMeters: _radiusMeters,
        etaMinutes: _estimatedArrivalMinutes,
        prepWindowMinutes: _prepWindowMinutes,
        alertMode: _alertMode,
        useTimerAlert: _useTimerAlert,
      );

      if (shouldTrigger) {
        _triggerAlarm();
      }
    }

    notifyListeners();
  }

  int _getAdaptiveDistanceFilter(double distanceMeters) {
    switch (_monitoringProfile) {
      case MonitoringProfile.responsive:
        if (distanceMeters > AppConstants.farDistanceThresholdMeters) {
          return 50; // 50m filter when far
        } else if (distanceMeters > AppConstants.mediumDistanceThresholdMeters) {
          return 25; // 25m filter
        } else if (distanceMeters > AppConstants.closeDistanceThresholdMeters) {
          return 10; // 10m filter
        } else {
          return 3; // 3m precision near stop
        }

      case MonitoringProfile.batterySaver:
        if (distanceMeters > AppConstants.farDistanceThresholdMeters) {
          return 250; // Relaxed 250m polling when far
        } else if (distanceMeters > AppConstants.mediumDistanceThresholdMeters) {
          return 100; // 100m polling
        } else if (distanceMeters > AppConstants.closeDistanceThresholdMeters) {
          return 35; // 35m polling
        } else {
          return 10; // 10m polling in alert zone
        }

      case MonitoringProfile.balanced:
        if (distanceMeters > AppConstants.farDistanceThresholdMeters) {
          return 100; // Far: 100m filter
        } else if (distanceMeters > AppConstants.mediumDistanceThresholdMeters) {
          return 50; // Medium: 50m filter
        } else if (distanceMeters > AppConstants.closeDistanceThresholdMeters) {
          return 15; // Close: 15m filter
        } else {
          return 5; // Very close: 5m filter for maximum precision
        }
    }
  }

  Future<void> _refreshNotification() async {
    if (!isJourneyActive || _selectedDestination == null) return;

    final distStr = Formatters.formatDistance(_remainingDistanceMeters, _distanceUnit);
    final etaStr = 'ETA: ~${_estimatedArrivalMinutes}m';
    final statusStr = _status == JourneyStatus.alarmActive
        ? '🚨 ALARM TRIGGERED'
        : _status == JourneyStatus.approaching
            ? 'Approaching Alert Zone'
            : 'Monitoring Active';

    await _backgroundService.updateNotification(
      destinationName: _selectedDestination!.name,
      distanceRemaining: distStr,
      etaText: etaStr,
      monitoringStatus: statusStr,
    );
  }

  /// Triggers the persistent, loud alarm and emergency notification.
  Future<void> _triggerAlarm() async {
    if (_hasTriggeredAlarmThisJourney) return;
    _hasTriggeredAlarmThisJourney = true;
    _status = JourneyStatus.alarmActive;

    final appSettings = await _repository.loadSettings();

    // 1. Start loud looping audio and vibration with user preferences
    await _alarmService.startAlarm(
      soundId: appSettings.alarmSoundId,
      vibrationEnabled: appSettings.vibrationEnabled,
      vibrationPattern: appSettings.vibrationPattern,
      volumeEscalation: appSettings.volumeEscalation,
    );

    // 2. Display urgent full screen alarm notification
    final distStr = Formatters.formatDistance(_remainingDistanceMeters, _distanceUnit);
    await _notificationService.showAlarmNotification(
      destinationName: _selectedDestination?.name ?? 'Destination',
      distanceFormatted: distStr,
    );

    // 3. Update background ongoing service notification
    await _refreshNotification();

    notifyListeners();
  }

  /// Dismisses active alarm and records journey completion.
  Future<void> dismissAlarm() async {
    await _alarmService.stopAlarm();
    await _notificationService.cancelAlarmNotification();

    _status = JourneyStatus.dismissed;
    await _finishJourney(outcome: JourneyOutcome.alarmTriggeredAndDismissed);
    notifyListeners();
  }

  /// Snoozes alarm for [minutes] then triggers again.
  Future<void> snoozeAlarm([int? minutes]) async {
    final int duration = minutes ?? _snoozeDurationMinutes;
    await _alarmService.stopAlarm();
    await _notificationService.cancelAlarmNotification();

    _status = JourneyStatus.approaching;
    _hasTriggeredAlarmThisJourney = false; // Allow trigger again after snooze
    notifyListeners();

    Timer(Duration(minutes: duration), () {
      if (isJourneyActive && !_hasTriggeredAlarmThisJourney) {
        _triggerAlarm();
      }
    });
  }

  /// Stops and completes journey cleanly.
  Future<void> stopJourney({
    JourneyOutcome outcome = JourneyOutcome.completedNormally,
  }) async {
    await _alarmService.stopAlarm();
    await _notificationService.cancelAlarmNotification();
    _simulationTimer?.cancel();

    _status = outcome == JourneyOutcome.cancelledByUser
        ? JourneyStatus.cancelled
        : JourneyStatus.idle;

    await _finishJourney(outcome: outcome);
    notifyListeners();
  }

  Future<void> _finishJourney({required JourneyOutcome outcome}) async {
    _locationSubscription?.cancel();
    _notificationUpdateTimer?.cancel();
    _locationService.stopTracking();
    await _backgroundService.stopForegroundMonitoring();

    if (_selectedDestination != null) {
      final journey = Journey(
        destination: _selectedDestination!,
        startTime: _journeyStartTime ?? DateTime.now(),
        endTime: DateTime.now(),
        startLatitude: _currentPosition?.latitude ?? 0.0,
        startLongitude: _currentPosition?.longitude ?? 0.0,
        initialDistanceMeters: _initialDistanceMeters,
        finalDistanceMeters: _remainingDistanceMeters,
        alertRadiusMeters: _radiusMeters,
        prepWindowMinutes: _prepWindowMinutes,
        outcome: outcome,
        alarmTriggered: _hasTriggeredAlarmThisJourney,
        alarmTriggeredAt: _hasTriggeredAlarmThisJourney ? DateTime.now() : null,
      );

      await _repository.addJourneyToHistory(journey);
    }

    await _repository.saveActiveJourney(null);
  }

  Future<void> _saveActiveState() async {
    if (_selectedDestination == null) return;
    final active = Journey(
      destination: _selectedDestination!,
      startTime: _journeyStartTime ?? DateTime.now(),
      startLatitude: _currentPosition?.latitude ?? 0.0,
      startLongitude: _currentPosition?.longitude ?? 0.0,
      initialDistanceMeters: _initialDistanceMeters,
      alertRadiusMeters: _radiusMeters,
      prepWindowMinutes: _prepWindowMinutes,
      outcome: JourneyOutcome.inProgress,
    );
    await _repository.saveActiveJourney(active);
  }

  /// Interactive Simulation:
  /// Gradually teleports/interpolates user position closer to the destination
  void simulateApproachStep() {
    if (_selectedDestination == null || _currentPosition == null) return;

    final dest = _selectedDestination!.latLng;
    final currentLat = _currentPosition!.latitude;
    final currentLng = _currentPosition!.longitude;

    // Position just inside the configured radius
    final targetLat = currentLat + (dest.latitude - currentLat) * 0.85;
    final targetLng = currentLng + (dest.longitude - currentLng) * 0.85;

    final simulatedPosition = LatLng(targetLat, targetLng);
    _onLocationUpdate(
      LocationReading(
        position: simulatedPosition,
        accuracy: 10.0,
        speedMetersPerSec: 15.0, // 54 km/h transit speed
        heading: GeoUtils.calculateBearing(simulatedPosition, dest),
        timestamp: DateTime.now(),
        isAccurate: true,
      ),
    );
  }

  /// Triggers alarm immediately for testing / preview.
  void testAlarmImmediately({Destination? testDestination}) {
    if (_selectedDestination == null) {
      _selectedDestination = testDestination ??
          Destination(
            name: 'Central Station (Test Alert)',
            address: 'Alarm Test Preview',
            latitude: _currentPosition?.latitude ?? 13.0839,
            longitude: _currentPosition?.longitude ?? 80.2754,
            radiusMeters: _radiusMeters,
          );
      _remainingDistanceMeters = 350;
      _estimatedArrivalMinutes = 1;
    }
    _triggerAlarm();
  }

  void resetToIdle() {
    _status = JourneyStatus.idle;
    _selectedDestination = null;
    _hasTriggeredAlarmThisJourney = false;
    _hasTriggeredEarlyWarning = false;
    _warningMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _notificationUpdateTimer?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }
}
