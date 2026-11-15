import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelIdTracking = 'proximity_tracking_channel';
  static const String channelNameTracking = 'Proximity Journey Tracking';
  static const String channelDescTracking =
      'Live journey status, distance remaining, and estimated arrival time.';

  static const String channelIdAlarm = 'proximity_alarm_channel';
  static const String channelNameAlarm = 'Proximity Arrival Alarm';
  static const String channelDescAlarm =
      'High-priority urgent alarm when approaching your destination.';

  static const int trackingNotificationId = 8888;
  static const int alarmNotificationId = 9999;

  final StreamController<String?> _actionController =
      StreamController<String?>.broadcast();
  Stream<String?> get actionStream => _actionController.stream;

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId != null) {
          _actionController.add(response.actionId);
        } else {
          _actionController.add('OPEN_APP');
        }
      },
    );

    // Create high-importance alarm notification channel
    const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      channelIdAlarm,
      channelNameAlarm,
      description: channelDescAlarm,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmChannel);
  }

  /// Shows urgent high-priority alarm notification with Full Screen Intent and Dismiss action.
  Future<void> showAlarmNotification({
    required String destinationName,
    required String distanceFormatted,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelIdAlarm,
      channelNameAlarm,
      channelDescription: channelDescAlarm,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'DISMISS_ALARM',
          'DISMISS ALARM',
          cancelNotification: true,
          showsUserInterface: true,
        ),
      ],
    );

    final NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: alarmNotificationId,
      title: '🚨 WAKE UP! Approaching Destination',
      body: '$destinationName is within $distanceFormatted! Get ready to disembark.',
      notificationDetails: details,
      payload: 'ALARM_ACTIVE',
    );
  }

  /// Cancels the alarm notification when dismissed.
  Future<void> cancelAlarmNotification() async {
    await _notificationsPlugin.cancel(id: alarmNotificationId);
  }

  /// Cancels tracking notification when journey finishes.
  Future<void> cancelTrackingNotification() async {
    await _notificationsPlugin.cancel(id: trackingNotificationId);
  }

  void dispose() {
    _actionController.close();
  }
}

