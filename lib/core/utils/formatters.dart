import 'package:intl/intl.dart';

class Formatters {
  /// Formats distance with appropriate units (km or m).
  static String formatDistance(double meters) {
    if (meters >= 1000) {
      final double km = meters / 1000.0;
      return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
    } else {
      return '${meters.round()} m';
    }
  }

  /// Formats speed from m/s to km/h.
  static String formatSpeed(double metersPerSecond) {
    if (metersPerSecond < 0.5) return '0 km/h';
    final double kmh = metersPerSecond * 3.6;
    return '${kmh.round()} km/h';
  }

  /// Formats duration in minutes into a friendly string.
  static String formatDurationMinutes(int totalMinutes) {
    if (totalMinutes <= 0) return 'Arrived';
    if (totalMinutes < 60) return '$totalMinutes min';
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    if (minutes == 0) return '$hours hr';
    return '$hours hr $minutes min';
  }

  /// Formats ETA into clock time (e.g. 5:24 PM).
  static String formatEtaClockTime(int minutesRemaining) {
    if (minutesRemaining <= 0) return 'Now';
    final etaTime = DateTime.now().add(Duration(minutes: minutesRemaining));
    return DateFormat.jm().format(etaTime);
  }

  /// Formats date and time for journey history logs.
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y • h:mm a').format(dateTime);
  }
}

