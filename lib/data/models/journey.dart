import 'package:uuid/uuid.dart';
import 'destination.dart';

enum JourneyOutcome {
  inProgress,
  alarmTriggeredAndDismissed,
  completedNormally,
  cancelledByUser,
}

class Journey {
  final String id;
  final Destination destination;
  final DateTime startTime;
  final DateTime? endTime;
  final double startLatitude;
  final double startLongitude;
  final double initialDistanceMeters;
  final double finalDistanceMeters;
  final double alertRadiusMeters;
  final int prepWindowMinutes;
  final JourneyOutcome outcome;
  final bool alarmTriggered;
  final DateTime? alarmTriggeredAt;

  Journey({
    String? id,
    required this.destination,
    DateTime? startTime,
    this.endTime,
    required this.startLatitude,
    required this.startLongitude,
    required this.initialDistanceMeters,
    this.finalDistanceMeters = 0.0,
    required this.alertRadiusMeters,
    required this.prepWindowMinutes,
    this.outcome = JourneyOutcome.inProgress,
    this.alarmTriggered = false,
    this.alarmTriggeredAt,
  })  : id = id ?? const Uuid().v4(),
        startTime = startTime ?? DateTime.now();

  int get durationMinutes {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes;
  }

  Journey copyWith({
    String? id,
    Destination? destination,
    DateTime? startTime,
    DateTime? endTime,
    double? startLatitude,
    double? startLongitude,
    double? initialDistanceMeters,
    double? finalDistanceMeters,
    double? alertRadiusMeters,
    int? prepWindowMinutes,
    JourneyOutcome? outcome,
    bool? alarmTriggered,
    DateTime? alarmTriggeredAt,
  }) {
    return Journey(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude: startLongitude ?? this.startLongitude,
      initialDistanceMeters:
          initialDistanceMeters ?? this.initialDistanceMeters,
      finalDistanceMeters: finalDistanceMeters ?? this.finalDistanceMeters,
      alertRadiusMeters: alertRadiusMeters ?? this.alertRadiusMeters,
      prepWindowMinutes: prepWindowMinutes ?? this.prepWindowMinutes,
      outcome: outcome ?? this.outcome,
      alarmTriggered: alarmTriggered ?? this.alarmTriggered,
      alarmTriggeredAt: alarmTriggeredAt ?? this.alarmTriggeredAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destination': destination.toJson(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'initialDistanceMeters': initialDistanceMeters,
      'finalDistanceMeters': finalDistanceMeters,
      'alertRadiusMeters': alertRadiusMeters,
      'prepWindowMinutes': prepWindowMinutes,
      'outcome': outcome.name,
      'alarmTriggered': alarmTriggered,
      'alarmTriggeredAt': alarmTriggeredAt?.toIso8601String(),
    };
  }

  factory Journey.fromJson(Map<String, dynamic> json) {
    return Journey(
      id: json['id'] as String?,
      destination:
          Destination.fromJson(json['destination'] as Map<String, dynamic>),
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ??
          DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'] as String)
          : null,
      startLatitude: (json['startLatitude'] as num?)?.toDouble() ?? 0.0,
      startLongitude: (json['startLongitude'] as num?)?.toDouble() ?? 0.0,
      initialDistanceMeters:
          (json['initialDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      finalDistanceMeters:
          (json['finalDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      alertRadiusMeters:
          (json['alertRadiusMeters'] as num?)?.toDouble() ?? 2000.0,
      prepWindowMinutes:
          (json['prepWindowMinutes'] as num?)?.toInt() ?? 5,
      outcome: JourneyOutcome.values.firstWhere(
        (e) => e.name == json['outcome'],
        orElse: () => JourneyOutcome.completedNormally,
      ),
      alarmTriggered: json['alarmTriggered'] as bool? ?? false,
      alarmTriggeredAt: json['alarmTriggeredAt'] != null
          ? DateTime.tryParse(json['alarmTriggeredAt'] as String)
          : null,
    );
  }
}

