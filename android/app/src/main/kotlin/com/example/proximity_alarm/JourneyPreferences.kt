package com.example.proximity_alarm

import android.content.Context
import android.os.PowerManager
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

internal class JourneyPreferences(context: Context) {
    private val appContext = context.applicationContext
    private val prefs = appContext.getSharedPreferences(FILE_NAME, Context.MODE_PRIVATE)

    fun string(key: String, default: String = ""): String = prefs.getString(key, default) ?: default
    fun double(key: String, default: Double = 0.0): Double = java.lang.Double.longBitsToDouble(prefs.getLong(key, java.lang.Double.doubleToRawLongBits(default)))
    fun long(key: String, default: Long = 0L): Long = prefs.getLong(key, default)
    fun int(key: String, default: Int = 0): Int = prefs.getInt(key, default)
    fun bool(key: String, default: Boolean = false): Boolean = prefs.getBoolean(key, default)

    fun putString(key: String, value: String) { prefs.edit().putString(key, value).apply() }
    fun putDouble(key: String, value: Double) { prefs.edit().putLong(key, java.lang.Double.doubleToRawLongBits(value)).apply() }
    fun putLong(key: String, value: Long) { prefs.edit().putLong(key, value).apply() }
    fun putInt(key: String, value: Int) { prefs.edit().putInt(key, value).apply() }
    fun putBool(key: String, value: Boolean) { prefs.edit().putBoolean(key, value).apply() }

    fun saveJourney(
        name: String,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double,
        preparationMinutes: Int,
    ) {
        prefs.edit()
            .putString("state", "ACTIVE")
            .putBoolean("alarmRinging", false)
            .putLong("monitoringStartedAt", System.currentTimeMillis())
            .putBoolean("locationStaleWarningShown", false)
            .putString("destinationName", name)
            .putLong("destinationLatitude", java.lang.Double.doubleToRawLongBits(latitude))
            .putLong("destinationLongitude", java.lang.Double.doubleToRawLongBits(longitude))
            .putLong("radiusMeters", java.lang.Double.doubleToRawLongBits(radiusMeters))
            .putInt("preparationMinutes", preparationMinutes)
            .putLong("routeEtaSeconds", -1L)
            .putLong("routeEtaUpdatedAt", 0L)
            .putLong("locationUpdatedAt", 0L)
            .putLong("distanceMeters", java.lang.Double.doubleToRawLongBits(Double.NaN))
            .putLong("locationAccuracyMeters", java.lang.Double.doubleToRawLongBits(Double.NaN))
            .putLong("currentLatitude", java.lang.Double.doubleToRawLongBits(Double.NaN))
            .putLong("currentLongitude", java.lang.Double.doubleToRawLongBits(Double.NaN))
            .putLong("triggerDistanceMeters", java.lang.Double.doubleToRawLongBits(Double.NaN))
            .putString("triggerReason", "")
            .putString("lastTriggeredAt", "")
            .putLong("routeRequestAt", 0L)
            .putLong("routeRequestLatitude", java.lang.Double.doubleToRawLongBits(Double.NaN))
            .putLong("routeRequestLongitude", java.lang.Double.doubleToRawLongBits(Double.NaN))
            .putString("lastError", "")
            .apply()
    }

    fun snapshot(): Map<String, Any?> {
        val now = System.currentTimeMillis()
        val locationUpdatedAt = long("locationUpdatedAt")
        val routeEta = long("routeEtaSeconds", -1L)
        val routeEtaUpdatedAt = long("routeEtaUpdatedAt")
        val powerManager = appContext.getSystemService(Context.POWER_SERVICE) as PowerManager
        val batteryOptimizationIgnored = try {
            powerManager.isIgnoringBatteryOptimizations(appContext.packageName)
        } catch (_: Exception) {
            false
        }
        return mapOf(
            "state" to string("state", "IDLE"),
            "alarmRinging" to bool("alarmRinging", false),
            "destinationName" to string("destinationName"),
            "destinationLatitude" to double("destinationLatitude", Double.NaN).takeIf { it.isFinite() },
            "destinationLongitude" to double("destinationLongitude", Double.NaN).takeIf { it.isFinite() },
            "radiusMeters" to double("radiusMeters", 2000.0),
            "preparationMinutes" to int("preparationMinutes", 5),
            "distanceMeters" to double("distanceMeters", Double.NaN).takeIf { it.isFinite() },
            "locationAccuracyMeters" to double("locationAccuracyMeters", Double.NaN).takeIf { it.isFinite() },
            "currentLatitude" to double("currentLatitude", Double.NaN).takeIf { it.isFinite() },
            "currentLongitude" to double("currentLongitude", Double.NaN).takeIf { it.isFinite() },
            "locationUpdatedAt" to locationUpdatedAt.takeIf { it > 0L }?.let { formatTimestamp(it) },
            "locationAgeSeconds" to if (locationUpdatedAt > 0L) ((now - locationUpdatedAt).coerceAtLeast(0L) / 1000L).toInt() else null,
            "routeEtaSeconds" to routeEta.takeIf { it >= 0L && routeEtaUpdatedAt > 0L && now - routeEtaUpdatedAt <= ROUTE_ETA_MAX_AGE_MS },
            "routeEtaUpdatedAt" to routeEtaUpdatedAt.takeIf { it > 0L }?.let { formatTimestamp(it) },
            "lastError" to string("lastError"),
            "triggerReason" to string("triggerReason"),
            "lastTriggeredAt" to string("lastTriggeredAt"),
            "triggerDistanceMeters" to double("triggerDistanceMeters", Double.NaN).takeIf { it.isFinite() },
            "batteryOptimizationIgnored" to batteryOptimizationIgnored,
        )
    }

    private fun formatTimestamp(milliseconds: Long): String = SimpleDateFormat(
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        Locale.US,
    ).apply { timeZone = TimeZone.getTimeZone("UTC") }.format(Date(milliseconds))

    companion object {
        const val FILE_NAME = "proximity_journey"
        const val ROUTE_ETA_MAX_AGE_MS = 90_000L
    }
}
