/// Pure Dart mirror of the Android decision rule, useful for UI-side previews
/// and unit tests. The Android service makes the final trigger decision.
class ArrivalPolicy {
  const ArrivalPolicy._();

  static bool shouldTrigger({
    required double distanceMeters,
    required double accuracyMeters,
    required double radiusMeters,
    required int? routeEtaSeconds,
    required int preparationMinutes,
  }) {
    if (distanceMeters.isNaN || distanceMeters.isInfinite || distanceMeters < 0) {
      return false;
    }
    final usableAccuracy = accuracyMeters >= 0 && accuracyMeters <= 100
        ? accuracyMeters
        : 0.0;
    final radiusReached = distanceMeters <= radiusMeters + usableAccuracy;
    final etaReached = routeEtaSeconds != null &&
        routeEtaSeconds >= 0 &&
        routeEtaSeconds <= preparationMinutes * 60;
    return radiusReached || etaReached;
  }
}
