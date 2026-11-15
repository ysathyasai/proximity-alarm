import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../domain_arrival_policy.dart';
import '../models/destination.dart';

const String kNotificationChannelId = 'proximity_transit_tracking';
const String kAlarmChannelId = 'proximity_transit_alarm';
const int kForegroundNotificationId = 999;
const int kAlarmNotificationId = 1000;

/// Production-ready background service manager for live transit tracking,
/// battery-efficient adaptive polling, and dynamic Google Maps-like notifications.
class TransitBackgroundService {
  TransitBackgroundService._();
  static final TransitBackgroundService instance = TransitBackgroundService._();

  final FlutterBackgroundService _service = FlutterBackgroundService();

  Future<void> initialize() async {
    final androidConfig = AndroidConfiguration(
      onStart: onBackgroundServiceStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: kNotificationChannelId,
      initialNotificationTitle: 'Transit Alarm Active',
      initialNotificationContent: 'Connecting to GPS...',
      foregroundServiceNotificationId: kForegroundNotificationId,
      foregroundServiceTypes: [AndroidForegroundType.location],
    );

    final iosConfig = IosConfiguration(
      autoStart: false,
      onForeground: onBackgroundServiceStart,
      onBackground: onIosBackground,
    );

    await _service.configure(
      androidConfiguration: androidConfig,
      iosConfiguration: iosConfig,
    );
  }

  Future<bool> isRunning() => _service.isRunning();

  Future<void> startTracking({
    required Destination destination,
    required double radiusMeters,
    required String alarmSound,
    required bool vibrate,
    required bool overrideSilent,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bg_dest_name', destination.name);
    await prefs.setDouble('bg_dest_lat', destination.latitude);
    await prefs.setDouble('bg_dest_lon', destination.longitude);
    await prefs.setString('bg_dest_addr', destination.address);
    await prefs.setDouble('bg_radius_meters', radiusMeters);
    await prefs.setString('bg_alarm_sound', alarmSound);
    await prefs.setBool('bg_vibrate', vibrate);
    await prefs.setBool('bg_override_silent', overrideSilent);
    await prefs.setString('bg_state', 'ACTIVE');
    await prefs.setBool('bg_alarm_ringing', false);

    final running = await _service.isRunning();
    if (!running) {
      await _service.startService();
    }

    _service.invoke('start', {
      'destinationName': destination.name,
      'destinationLatitude': destination.latitude,
      'destinationLongitude': destination.longitude,
      'destinationAddress': destination.address,
      'radiusMeters': radiusMeters,
      'alarmSound': alarmSound,
      'vibrate': vibrate,
      'overrideSilent': overrideSilent,
    });
  }

  Future<void> stopTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bg_state', 'IDLE');
    await prefs.setBool('bg_alarm_ringing', false);

    _service.invoke('stop');
  }

  Future<void> dismissAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bg_alarm_ringing', false);
    await prefs.setString('bg_state', 'IDLE');

    _service.invoke('dismiss_alarm');
  }

  Stream<Map<String, dynamic>?> onDataReceived() {
    return _service.on('update');
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final audioPlayer = AudioPlayer();

  // Create high-visibility tracking channel & alarm channel
  const trackingChannel = AndroidNotificationChannel(
    kNotificationChannelId,
    'Transit Live Tracking',
    description: 'Dynamic Google Maps-like remaining distance notification',
    importance: Importance.low,
    showBadge: false,
    playSound: false,
    enableVibration: false,
  );

  const alarmChannel = AndroidNotificationChannel(
    kAlarmChannelId,
    'Transit Arrival Alarm',
    description: 'Critical alarm when reaching destination proximity',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(trackingChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(alarmChannel);

  // Load journey parameters from disk
  final prefs = await SharedPreferences.getInstance();
  String destName = prefs.getString('bg_dest_name') ?? 'Destination';
  double destLat = prefs.getDouble('bg_dest_lat') ?? 0.0;
  double destLon = prefs.getDouble('bg_dest_lon') ?? 0.0;
  double radiusMeters = prefs.getDouble('bg_radius_meters') ?? 1000.0;
  String alarmSound = prefs.getString('bg_alarm_sound') ?? 'Radar Pulse';
  bool vibrate = prefs.getBool('bg_vibrate') ?? true;
  bool overrideSilent = prefs.getBool('bg_override_silent') ?? true;

  bool isTracking = true;
  bool isAlarmRinging = false;
  double lastDistanceMeters = double.infinity;
  double currentSpeedKmh = 0.0;
  double currentLat = 0.0;
  double currentLon = 0.0;
  Timer? adaptiveTimer;
  Timer? minuteHeartbeatTimer;

  const soundFiles = {
    'Radar Pulse': 'sounds/radar.wav',
    'Transit Chime': 'sounds/chime.wav',
    'Digital Alarm': 'sounds/digital.wav',
    'Echo Bell': 'sounds/bell.wav',
    'Warning Siren': 'sounds/siren.wav',
  };

  void updateGoogleMapsStyleNotification({
    required double distanceMeters,
    required double speedKmh,
    required String destinationTitle,
  }) {
    if (isAlarmRinging) return;

    final distanceStr = Destination.formatDistance(distanceMeters);
    final speedStr = speedKmh > 1.0 ? '${speedKmh.toStringAsFixed(0)} km/h' : null;

    final content = speedStr != null
        ? '$distanceStr remaining to $destinationTitle • $speedStr'
        : '$distanceStr remaining to $destinationTitle';

    final subtext = 'Alert at ${(radiusMeters / 1000).toStringAsFixed(1)} km';

    final androidDetails = AndroidNotificationDetails(
      kNotificationChannelId,
      'Transit Live Tracking',
      channelDescription: 'Dynamic live transit tracking',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: true,
      subText: subtext,
      styleInformation: BigTextStyleInformation(
        content,
        contentTitle: 'Transit Alarm • $destinationTitle',
        summaryText: subtext,
      ),
    );

    flutterLocalNotificationsPlugin.show(
      id: kForegroundNotificationId,
      title: 'Transit Alarm • $destinationTitle',
      body: content,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  void triggerArrivalAlarm(String reason) async {
    if (isAlarmRinging) return;
    isAlarmRinging = true;
    isTracking = false;

    await prefs.setString('bg_state', 'TRIGGERED');
    await prefs.setBool('bg_alarm_ringing', true);

    // Cancel ongoing tracking notification
    await flutterLocalNotificationsPlugin.cancel(id: kForegroundNotificationId);

    // Show loud, high-priority arrival alarm notification
    final androidAlarmDetails = AndroidNotificationDetails(
      kAlarmChannelId,
      'Transit Arrival Alarm',
      channelDescription: 'Destination reached alert',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      styleInformation: BigTextStyleInformation(
        'You have arrived within ${(radiusMeters / 1000).toStringAsFixed(1)} km of $destName. Wake up and prepare to alight!',
        contentTitle: '🚨 DESTINATION REACHED!',
        summaryText: 'Arrival Alert',
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      id: kAlarmNotificationId,
      title: '🚨 DESTINATION REACHED!',
      body: 'You are near $destName. Time to alight!',
      notificationDetails: NotificationDetails(android: androidAlarmDetails),
    );

    // Loop Vibration
    if (vibrate) {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib == true) {
        Vibration.vibrate(
          pattern: [0, 800, 400, 800, 400, 1000],
          repeat: 0, // repeat indefinitely until cancelled
        );
      }
    }

    // Play Sound
    try {
      final assetPath = soundFiles[alarmSound] ?? 'sounds/radar.wav';
      if (overrideSilent) {
        await audioPlayer.setAudioContext(AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientExclusive,
          ),
        ));
      }
      await audioPlayer.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.play(AssetSource(assetPath), volume: 1.0);
    } catch (e) {
      if (kDebugMode) print('Audio playback error: $e');
    }

    // Notify UI
    service.invoke('update', {
      'status': 'TRIGGERED',
      'alarmRinging': true,
      'triggerReason': reason,
      'distanceMeters': lastDistanceMeters,
      'currentLatitude': currentLat,
      'currentLongitude': currentLon,
      'speedKmh': currentSpeedKmh,
      'destinationName': destName,
      'radiusMeters': radiusMeters,
    });
  }

  void stopAlarmAndReset() async {
    isAlarmRinging = false;
    isTracking = false;
    adaptiveTimer?.cancel();
    minuteHeartbeatTimer?.cancel();

    try {
      await audioPlayer.stop();
    } catch (_) {}

    try {
      Vibration.cancel();
    } catch (_) {}

    await flutterLocalNotificationsPlugin.cancel(id: kAlarmNotificationId);
    await flutterLocalNotificationsPlugin.cancel(id: kForegroundNotificationId);

    await prefs.setString('bg_state', 'IDLE');
    await prefs.setBool('bg_alarm_ringing', false);

    service.invoke('update', {
      'status': 'IDLE',
      'alarmRinging': false,
      'distanceMeters': lastDistanceMeters,
      'destinationName': destName,
    });

    if (service is AndroidServiceInstance) {
      service.stopSelf();
    }
  }

  // Adaptive GPS polling worker
  Future<void> pollLocation() async {
    if (!isTracking || isAlarmRinging) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: lastDistanceMeters > 5000.0
              ? LocationAccuracy.medium
              : LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        ),
      );

      currentLat = position.latitude;
      currentLon = position.longitude;
      // speed in m/s -> km/h
      currentSpeedKmh = (position.speed * 3.6).clamp(0.0, 350.0);

      // Distance calculation
      const earthRadius = 6371000.0;
      final dLat = (destLat - currentLat) * (math.pi / 180.0);
      final dLon = (destLon - currentLon) * (math.pi / 180.0);
      final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(currentLat * (math.pi / 180.0)) *
              math.cos(destLat * (math.pi / 180.0)) *
              math.sin(dLon / 2) *
              math.sin(dLon / 2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      final distance = earthRadius * c;
      lastDistanceMeters = distance;

      // Update Foreground Notification immediately
      updateGoogleMapsStyleNotification(
        distanceMeters: distance,
        speedKmh: currentSpeedKmh,
        destinationTitle: destName,
      );

      // Check arrival policy
      final shouldTrigger = ArrivalPolicy.shouldTrigger(
        distanceMeters: distance,
        accuracyMeters: position.accuracy,
        radiusMeters: radiusMeters,
        routeEtaSeconds: null,
        preparationMinutes: 5,
      );

      if (shouldTrigger) {
        triggerArrivalAlarm('Destination radius (${radiusMeters.round()}m) reached');
        return;
      }

      // Broadcast update to Flutter UI
      service.invoke('update', {
        'status': 'ACTIVE',
        'alarmRinging': false,
        'distanceMeters': distance,
        'currentLatitude': currentLat,
        'currentLongitude': currentLon,
        'speedKmh': currentSpeedKmh,
        'radiusMeters': radiusMeters,
        'destinationName': destName,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) print('Background GPS poll error: $e');
    }
  }

  // Reschedules adaptive location timer according to distance
  void scheduleAdaptiveCycle() {
    adaptiveTimer?.cancel();
    if (!isTracking || isAlarmRinging) return;

    // Battery-efficient adaptive intervals:
    // > 10 km away: check every 60s
    // 3 km to 10 km: check every 25s
    // < 3 km: check every 8s
    final intervalSeconds = lastDistanceMeters > 10000.0
        ? 60
        : (lastDistanceMeters > 3000.0 ? 25 : 8);

    adaptiveTimer = Timer(Duration(seconds: intervalSeconds), () async {
      await pollLocation();
      scheduleAdaptiveCycle();
    });
  }

  // Independent 1-minute ticker to guarantee periodic notification refresh
  minuteHeartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
    if (isTracking && !isAlarmRinging && lastDistanceMeters.isFinite) {
      updateGoogleMapsStyleNotification(
        distanceMeters: lastDistanceMeters,
        speedKmh: currentSpeedKmh,
        destinationTitle: destName,
      );
    }
  });

  // Handle incoming control signals from UI
  service.on('start').listen((event) async {
    if (event != null) {
      destName = event['destinationName']?.toString() ?? destName;
      destLat = (event['destinationLatitude'] as num?)?.toDouble() ?? destLat;
      destLon = (event['destinationLongitude'] as num?)?.toDouble() ?? destLon;
      radiusMeters = (event['radiusMeters'] as num?)?.toDouble() ?? radiusMeters;
      alarmSound = event['alarmSound']?.toString() ?? alarmSound;
      vibrate = event['vibrate'] == true;
      overrideSilent = event['overrideSilent'] == true;
    }
    isTracking = true;
    isAlarmRinging = false;
    await pollLocation();
    scheduleAdaptiveCycle();
  });

  service.on('stop').listen((_) {
    stopAlarmAndReset();
  });

  service.on('dismiss_alarm').listen((_) {
    stopAlarmAndReset();
  });

  // Initial trigger if started with active parameters
  pollLocation().then((_) {
    scheduleAdaptiveCycle();
  });
}
