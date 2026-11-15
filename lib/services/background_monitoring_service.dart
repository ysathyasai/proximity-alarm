import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// The callback function must always be a top-level function.
@pragma('vm:entry-point')
void startBackgroundMonitoringCallback() {
  FlutterForegroundTask.setTaskHandler(MonitoringTaskHandler());
}

class MonitoringTaskHandler extends TaskHandler {
  Map<String, dynamic>? _taskConfig;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initialized background monitoring task
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Send heartbeat to main isolate requesting location update
    FlutterForegroundTask.sendDataToMain({
      'type': 'HEARTBEAT',
      'timestamp': timestamp.millisecondsSinceEpoch,
      'config': _taskConfig,
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // Cleaned up task
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map<String, dynamic>) {
      if (data['type'] == 'CONFIG') {
        _taskConfig = data;
      }
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    FlutterForegroundTask.sendDataToMain({
      'type': 'NOTIFICATION_BUTTON',
      'actionId': id,
    });
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.sendDataToMain({
      'type': 'NOTIFICATION_CLICKED',
    });
  }

  @override
  void onNotificationDismissed() {
    FlutterForegroundTask.sendDataToMain({
      'type': 'NOTIFICATION_DISMISSED',
    });
  }
}

class BackgroundMonitoringService {
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  static void initCommunication() {
    FlutterForegroundTask.initCommunicationPort();
  }

  /// Configures and starts the Android Foreground Service for uninterrupted background monitoring.
  Future<bool> startForegroundMonitoring({
    required String destinationName,
    required double destinationLat,
    required double destinationLng,
    required double radiusMeters,
    required int prepWindowMinutes,
    required String initialStatusText,
  }) async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'proximity_monitoring_service_channel',
        channelName: 'Proximity Journey Tracking Service',
        channelDescription:
            'Continuous location monitoring for public transit arrival alert.',
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(), // Battery optimized: avoid busy looping
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    final serviceResult = await FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: 'Proximity Alarm: $destinationName',
      notificationText: initialStatusText,
      notificationIcon: null,
      notificationButtons: const [
        NotificationButton(id: 'BTN_OPEN', text: 'Open App'),
        NotificationButton(id: 'BTN_CANCEL', text: 'Stop Journey'),
      ],
      callback: startBackgroundMonitoringCallback,
    );

    _isRunning = serviceResult is ServiceRequestSuccess;

    if (_isRunning) {
      FlutterForegroundTask.sendDataToTask({
        'type': 'CONFIG',
        'destLat': destinationLat,
        'destLng': destinationLng,
        'radiusMeters': radiusMeters,
        'prepWindowMinutes': prepWindowMinutes,
        'destName': destinationName,
      });
    }

    return _isRunning;
  }

  /// Updates the ongoing tracking notification content with distance and ETA.
  Future<void> updateNotification({
    required String destinationName,
    required String distanceRemaining,
    required String etaText,
    required String monitoringStatus,
  }) async {
    if (!_isRunning) return;

    await FlutterForegroundTask.updateService(
      notificationTitle: 'Proximity Alarm: $destinationName',
      notificationText: '$distanceRemaining • $etaText • $monitoringStatus',
    );
  }

  /// Stops foreground monitoring service cleanly.
  Future<void> stopForegroundMonitoring() async {
    if (_isRunning) {
      await FlutterForegroundTask.stopService();
      _isRunning = false;
    }
  }

  /// Listens for messages sent from background TaskHandler to main isolate.
  void addDataCallback(Function(Object data) callback) {
    FlutterForegroundTask.addTaskDataCallback(callback);
  }

  void removeDataCallback(Function(Object data) callback) {
    FlutterForegroundTask.removeTaskDataCallback(callback);
  }
}
