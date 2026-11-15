package com.example.proximity_alarm

/** Pure arrival rule shared by the foreground service and unit tests. */
internal object ArrivalPolicy {
    fun shouldTrigger(
        distanceMeters: Double,
        accuracyMeters: Double,
        radiusMeters: Double,
        routeEtaSeconds: Long?,
        preparationMinutes: Int,
    ): Boolean {
        if (!distanceMeters.isFinite() || distanceMeters < 0.0) return false
        val accuracyAllowance = if (accuracyMeters in 0.0..100.0) accuracyMeters else 0.0
        val radiusReached = distanceMeters <= radiusMeters + accuracyAllowance
        val etaReached = routeEtaSeconds != null &&
            routeEtaSeconds >= 0L &&
            routeEtaSeconds <= preparationMinutes.coerceAtLeast(1) * 60L
        return radiusReached || etaReached
    }
}
