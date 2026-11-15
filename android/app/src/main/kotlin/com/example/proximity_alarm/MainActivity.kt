package com.example.proximity_alarm

import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startJourney" -> {
                    val arguments = call.arguments as? Map<*, *>
                    if (arguments == null) {
                        result.error("INVALID_ARGUMENTS", "Journey configuration is missing.", null)
                        return@setMethodCallHandler
                    }
                    val fine = ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    val coarse = ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    if (!fine && !coarse) {
                        result.error("LOCATION_PERMISSION_MISSING", "Grant location permission before starting a journey.", null)
                        return@setMethodCallHandler
                    }
                    val name = arguments["destinationName"] as? String ?: "Destination"
                    val latitude = (arguments["destinationLatitude"] as? Number)?.toDouble()
                    val longitude = (arguments["destinationLongitude"] as? Number)?.toDouble()
                    val radius = (arguments["radiusMeters"] as? Number)?.toDouble() ?: 2000.0
                    val prep = (arguments["preparationMinutes"] as? Number)?.toInt() ?: 5
                    if (latitude == null || longitude == null || !latitude.isFinite() || !longitude.isFinite() || abs(latitude) > 90 || abs(longitude) > 180) {
                        result.error("INVALID_DESTINATION", "Destination coordinates are invalid.", null)
                        return@setMethodCallHandler
                    }
                    if (radius !in 100.0..50_000.0) {
                        result.error("INVALID_RADIUS", "The radius must be between 100 m and 50 km.", null)
                        return@setMethodCallHandler
                    }
                    JourneyPreferences(this).saveJourney(name, latitude, longitude, radius, prep.coerceIn(1, 60))
                    val serviceIntent = Intent(this, ProximityTrackingService::class.java).setAction(ProximityTrackingService.ACTION_START)
                    try {
                        ContextCompat.startForegroundService(this, serviceIntent)
                        result.success(null)
                    } catch (error: Exception) {
                        val store = JourneyPreferences(this)
                        store.putString("state", "ERROR")
                        store.putString("lastError", error.localizedMessage ?: "Could not start the location service.")
                        result.error("SERVICE_START_FAILED", error.localizedMessage ?: "Could not start the location service.", null)
                    }
                }
                "stopJourney" -> {
                    val store = JourneyPreferences(this)
                    store.putBool("alarmRinging", false)
                    store.putString("state", "IDLE")
                    stopService(Intent(this, ProximityTrackingService::class.java))
                    result.success(null)
                }
                "dismissAlarm" -> {
                    AlarmActionReceiver.dismiss(this)
                    result.success(null)
                }
                "getStatus" -> result.success(JourneyPreferences(this).snapshot())
                "openBatterySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        startActivity(intent)
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("SETTINGS_UNAVAILABLE", error.localizedMessage ?: "Could not open settings.", null)
                    }
                }
                "openLocationSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("SETTINGS_UNAVAILABLE", error.localizedMessage ?: "Could not open settings.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    companion object {
        private const val CHANNEL = "app.proximityalarm/journey"
    }
}
