import 'package:latlong2/latlong.dart';
import 'destination.dart';

enum TrackingStatus {
  idle,
  active,
  triggered,
  error;

  String get label {
    switch (this) {
      case TrackingStatus.idle:
        return 'IDLE';
      case TrackingStatus.active:
        return 'TRACKING ACTIVE';
      case TrackingStatus.triggered:
        return 'ALARM RINGING';
      case TrackingStatus.error:
        return 'ERROR';
    }
  }

  bool get isActive => this == TrackingStatus.active;
  bool get isTriggered => this == TrackingStatus.triggered;
}

class TrackingSnapshot {
  const TrackingSnapshot({
    this.status = TrackingStatus.idle,
    this.destination,
    this.currentPosition,
    this.speedKmh = 0.0,
    this.distanceMeters = double.infinity,
    this.radiusMeters = 1000.0,
    this.alarmRinging = false,
    this.triggerReason = '',
    this.lastError = '',
    this.lastUpdated,
  });

  final TrackingStatus status;
  final Destination? destination;
  final LatLng? currentPosition;
  final double speedKmh;
  final double distanceMeters;
  final double radiusMeters;
  final bool alarmRinging;
  final String triggerReason;
  final String lastError;
  final DateTime? lastUpdated;

  bool get isWithinRadius =>
      distanceMeters.isFinite && distanceMeters <= radiusMeters;

  bool get isTriggered => status == TrackingStatus.triggered;
  bool get isActive => status == TrackingStatus.active;

  String get formattedDistance => Destination.formatDistance(distanceMeters);

  String get formattedSpeed {
    if (speedKmh <= 0.5) return '0 km/h';
    return '${speedKmh.toStringAsFixed(0)} km/h';
  }

  TrackingSnapshot copyWith({
    TrackingStatus? status,
    Destination? destination,
    LatLng? currentPosition,
    double? speedKmh,
    double? distanceMeters,
    double? radiusMeters,
    bool? alarmRinging,
    String? triggerReason,
    String? lastError,
    DateTime? lastUpdated,
  }) {
    return TrackingSnapshot(
      status: status ?? this.status,
      destination: destination ?? this.destination,
      currentPosition: currentPosition ?? this.currentPosition,
      speedKmh: speedKmh ?? this.speedKmh,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      alarmRinging: alarmRinging ?? this.alarmRinging,
      triggerReason: triggerReason ?? this.triggerReason,
      lastError: lastError ?? this.lastError,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'destination': destination?.toJson(),
      'currentLatitude': currentPosition?.latitude,
      'currentLongitude': currentPosition?.longitude,
      'speedKmh': speedKmh,
      'distanceMeters': distanceMeters,
      'radiusMeters': radiusMeters,
      'alarmRinging': alarmRinging,
      'triggerReason': triggerReason,
      'lastError': lastError,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory TrackingSnapshot.fromMap(Map<String, dynamic> map) {
    TrackingStatus parseStatus(dynamic val) {
      if (val == null) return TrackingStatus.idle;
      final s = val.toString().toLowerCase();
      if (s.contains('trigger')) return TrackingStatus.triggered;
      if (s.contains('active')) return TrackingStatus.active;
      if (s.contains('error')) return TrackingStatus.error;
      return TrackingStatus.idle;
    }

    final lat = (map['currentLatitude'] as num?)?.toDouble();
    final lon = (map['currentLongitude'] as num?)?.toDouble();

    return TrackingSnapshot(
      status: parseStatus(map['status'] ?? map['state']),
      destination: map['destination'] != null
          ? Destination.fromJson(Map<String, dynamic>.from(map['destination'] as Map))
          : (map['destinationName'] != null && map['destinationLatitude'] != null
              ? Destination(
                  name: map['destinationName'].toString(),
                  latitude: (map['destinationLatitude'] as num).toDouble(),
                  longitude: (map['destinationLongitude'] as num).toDouble(),
                )
              : null),
      currentPosition: (lat != null && lon != null) ? LatLng(lat, lon) : null,
      speedKmh: (map['speedKmh'] as num?)?.toDouble() ?? 0.0,
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? double.infinity,
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 1000.0,
      alarmRinging: map['alarmRinging'] == true,
      triggerReason: (map['triggerReason'] ?? '').toString(),
      lastError: (map['lastError'] ?? '').toString(),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated'].toString())
          : null,
    );
  }
}
