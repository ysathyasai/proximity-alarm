import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/destination.dart';
import '../models/tracking_state.dart';
import '../services/background_service.dart';
import '../services/local_store.dart';
import '../services/settings_service.dart';

/// Central state manager coordinating destination selection, live GPS streaming,
/// background service synchronisation, and trip history.
class JourneyProvider extends ChangeNotifier {
  JourneyProvider({
    TransitBackgroundService? backgroundService,
    LocalStore? localStore,
    SettingsService? settingsService,
  })  : _bg = backgroundService ?? TransitBackgroundService.instance,
        _store = localStore ?? LocalStore(),
        _settings = settingsService ?? SettingsService.instance;

  final TransitBackgroundService _bg;
  final LocalStore _store;
  final SettingsService _settings;

  Destination? _destination;
  double _radiusMeters = 1000.0;
  TrackingSnapshot _snapshot = const TrackingSnapshot();
  LatLng? _liveUserPosition;
  double _liveSpeedKmh = 0.0;
  List<Destination> _savedDestinations = [];
  List<Map<String, dynamic>> _tripHistory = [];
  bool _isInitialized = false;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<Map<String, dynamic>?>? _bgSub;

  // Getters
  Destination? get destination => _destination ?? _snapshot.destination;
  double get radiusMeters => _radiusMeters;
  TrackingSnapshot get snapshot => _snapshot;
  LatLng? get liveUserPosition => _liveUserPosition ?? _snapshot.currentPosition;
  double get currentSpeedKmh => _liveSpeedKmh > 0 ? _liveSpeedKmh : _snapshot.speedKmh;
  List<Destination> get savedDestinations => _savedDestinations;
  List<Map<String, dynamic>> get tripHistory => _tripHistory;
  bool get isTracking => _snapshot.status == TrackingStatus.active;
  bool get isAlarmRinging => _snapshot.alarmRinging || _snapshot.status == TrackingStatus.triggered;
  bool get isInitialized => _isInitialized;

  double get distanceMeters {
    if (_snapshot.status == TrackingStatus.active && _snapshot.distanceMeters.isFinite) {
      return _snapshot.distanceMeters;
    }
    if (_destination != null && liveUserPosition != null) {
      return _destination!.distanceTo(liveUserPosition!);
    }
    return double.infinity;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _radiusMeters = _settings.defaultRadiusMeters;

    _savedDestinations = await _store.loadSavedDestinations();
    _tripHistory = await _store.loadHistory();
    if (_destination == null && _savedDestinations.isNotEmpty) {
      _destination = _savedDestinations.first;
    }

    // Subscribe to background service updates
    _bgSub = _bg.onDataReceived().listen(_onBackgroundUpdate);

    // Start UI-side foreground GPS stream for responsive 60fps map & dashboard
    _startForegroundGpsStream();

    _isInitialized = true;
    notifyListeners();
  }

  void _onBackgroundUpdate(Map<String, dynamic>? data) {
    if (data == null) return;
    _snapshot = TrackingSnapshot.fromMap(data);

    if (_snapshot.currentPosition != null) {
      _liveUserPosition = _snapshot.currentPosition;
    }
    if (_snapshot.speedKmh > 0) {
      _liveSpeedKmh = _snapshot.speedKmh;
    }

    if (_snapshot.isTriggered && !_snapshot.alarmRinging) {
      // Record trigger in history
      _store.recordTriggerIfNew({
        'lastTriggeredAt': DateTime.now().toIso8601String(),
        'destinationName': _destination?.name ?? 'Destination',
        'triggerReason': _snapshot.triggerReason,
        'triggerDistanceMeters': _snapshot.distanceMeters,
      });
      _store.loadHistory().then((h) {
        _tripHistory = h;
        notifyListeners();
      });
    }

    notifyListeners();
  }

  void _startForegroundGpsStream() async {
    final hasPermission = await Geolocator.checkPermission();
    if (hasPermission == LocationPermission.denied ||
        hasPermission == LocationPermission.deniedForever) {
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((position) {
      _liveUserPosition = LatLng(position.latitude, position.longitude);
      _liveSpeedKmh = (position.speed * 3.6).clamp(0.0, 350.0);

      // Recalculate distance if tracking or destination selected
      if (_destination != null && !_snapshot.status.isActive) {
        final dist = _destination!.distanceTo(_liveUserPosition!);
        _snapshot = _snapshot.copyWith(
          currentPosition: _liveUserPosition,
          speedKmh: _liveSpeedKmh,
          distanceMeters: dist,
        );
      }
      notifyListeners();
    }, onError: (_) {});
  }

  void setDestination(Destination dest) {
    _destination = dest;
    if (_liveUserPosition != null) {
      final dist = dest.distanceTo(_liveUserPosition!);
      _snapshot = _snapshot.copyWith(
        destination: dest,
        distanceMeters: dist,
      );
    } else {
      _snapshot = _snapshot.copyWith(destination: dest);
    }
    notifyListeners();
  }

  void setRadius(double radiusMeters) {
    _radiusMeters = radiusMeters;
    _snapshot = _snapshot.copyWith(radiusMeters: radiusMeters);
    notifyListeners();
  }

  Future<bool> requestPermissions() async {
    final locStatus = await Permission.locationWhenInUse.request();
    if (!locStatus.isGranted) return false;

    // Notification permission for Android 13+
    await Permission.notification.request();
    return true;
  }

  Future<void> startJourney() async {
    if (_destination == null) return;
    final granted = await requestPermissions();
    if (!granted) {
      _snapshot = _snapshot.copyWith(
        status: TrackingStatus.error,
        lastError: 'Location permission is required for transit alarm.',
      );
      notifyListeners();
      return;
    }

    await _store.saveDestination(_destination!);
    _savedDestinations = await _store.loadSavedDestinations();

    _snapshot = _snapshot.copyWith(
      status: TrackingStatus.active,
      destination: _destination,
      radiusMeters: _radiusMeters,
      alarmRinging: false,
      lastError: '',
    );
    notifyListeners();

    await _bg.startTracking(
      destination: _destination!,
      radiusMeters: _radiusMeters,
      alarmSound: _settings.alarmSound,
      vibrate: _settings.vibrate,
      overrideSilent: _settings.overrideSilentMode,
    );
  }

  Future<void> stopJourney() async {
    await _bg.stopTracking();
    _snapshot = _snapshot.copyWith(
      status: TrackingStatus.idle,
      alarmRinging: false,
    );
    notifyListeners();
  }

  Future<void> dismissAlarm() async {
    await _bg.dismissAlarm();
    _snapshot = _snapshot.copyWith(
      status: TrackingStatus.idle,
      alarmRinging: false,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _bgSub?.cancel();
    super.dispose();
  }
}
