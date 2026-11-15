package com.example.proximity_alarm

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.os.Handler
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.Executors

/**
 * Native Android owner of journey monitoring. The service is started explicitly
 * while MainActivity is visible and keeps an ongoing location-service notification.
 */
class ProximityTrackingService : Service() {
    private lateinit var store: JourneyPreferences
    private val fused by lazy { LocationServices.getFusedLocationProviderClient(this) }
    private val routeExecutor = Executors.newSingleThreadExecutor()
    private var mediaPlayer: MediaPlayer? = null
    private var lastLocation: Location? = null
    private var updatesRequested = false
    private var locationProfile: String? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val healthCheckRunnable = object : Runnable {
        override fun run() {
            if (store.string("state") != "ACTIVE") return
            val now = System.currentTimeMillis()
            val lastFix = store.long("locationUpdatedAt")
            val monitoringStarted = store.long("monitoringStartedAt", now)
            val baseline = if (lastFix > 0L) lastFix else monitoringStarted
            if (now - baseline > LOCATION_STALE_AFTER_MS && !store.bool("locationStaleWarningShown", false)) {
                val message = if (lastFix > 0L) {
                    "No fresh location update for over a minute. Check Location and battery settings."
                } else {
                    "No location fix received yet. Move to an open-sky area and check Location settings."
                }
                store.putBool("locationStaleWarningShown", true)
                store.putString("lastError", message)
                showMonitoringWarning(message)
                updateTrackingNotification()
            }
            mainHandler.postDelayed(this, HEALTH_CHECK_INTERVAL_MS)
        }
    }

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            result.lastLocation?.let(::onLocation)
        }
    }

    override fun onCreate() {
        super.onCreate()
        store = JourneyPreferences(this)
        createNotificationChannels()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                store.putString("state", "IDLE")
                store.putBool("alarmRinging", false)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_DISMISS -> {
                AlarmActionReceiver.dismiss(this)
                return START_NOT_STICKY
            }
            ACTION_START, null -> {
                val savedState = store.string("state", "IDLE")
                if (store.bool("alarmRinging", false) || savedState == "TRIGGERED") {
                    store.putBool("alarmRinging", true)
                    store.putString("state", "TRIGGERED")
                    startForegroundCompat(ALARM_NOTIFICATION_ID, buildAlarmNotification(), includeMediaPlayback = true)
                    startAlarmSound()
                    return START_STICKY
                }
                if (intent == null && savedState != "ACTIVE") {
                    // A sticky restart after a dismissed/ended trip must not revive an old journey.
                    stopSelf()
                    return START_NOT_STICKY
                }
                store.putString("state", "ACTIVE")
                getSystemService(NotificationManager::class.java).cancel(WARNING_NOTIFICATION_ID)
                startForegroundCompat(SERVICE_NOTIFICATION_ID, buildTrackingNotification())
                startLocationUpdates()
                scheduleHealthChecks()
                return START_STICKY
            }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Do not stop on removal from Recents; the user explicitly armed a journey.
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        try { fused.removeLocationUpdates(locationCallback) } catch (_: Exception) { }
        updatesRequested = false
        locationProfile = null
        mainHandler.removeCallbacks(healthCheckRunnable)
        releaseAlarmSound()
        routeExecutor.shutdownNow()
        if (store.string("state") != "ERROR") {
            getSystemService(NotificationManager::class.java).cancel(WARNING_NOTIFICATION_ID)
        }
        if (store.string("state") == "ACTIVE") {
            store.putString("state", "IDLE")
        }
        super.onDestroy()
    }

    private fun startLocationUpdates() {
        val fine = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (!fine) {
            store.putString("state", "ERROR")
            store.putString("lastError", "Precise location permission is missing. Reopen the app and enable precise location.")
            showMonitoringWarning(store.string("lastError"))
            stopSelf()
            return
        }
        // Begin with a low-power request until the first acceptable fix tells us how far away we are.
        configureLocationUpdates(null)
    }

    /** Adapt frequency/priority to distance: save power when far away, sample faster near arrival. */
    private fun configureLocationUpdates(distanceMeters: Double?) {
        if (store.string("state") != "ACTIVE") return
        val profile = when {
            distanceMeters == null -> LocationProfile("initial", Priority.PRIORITY_BALANCED_POWER_ACCURACY, 30_000L, 15_000L, 50f)
            distanceMeters > 10_000.0 -> LocationProfile("far", Priority.PRIORITY_BALANCED_POWER_ACCURACY, 60_000L, 30_000L, 75f)
            distanceMeters > 3_000.0 -> LocationProfile("approach", Priority.PRIORITY_HIGH_ACCURACY, 20_000L, 10_000L, 30f)
            else -> LocationProfile("near", Priority.PRIORITY_HIGH_ACCURACY, 7_000L, 3_000L, 10f)
        }
        if (locationProfile == profile.name) return
        if (updatesRequested || locationProfile != null) {
            try { fused.removeLocationUpdates(locationCallback) } catch (_: Exception) { }
        }
        updatesRequested = false
        locationProfile = profile.name
        val request = LocationRequest.Builder(profile.priority, profile.intervalMs)
            .setMinUpdateIntervalMillis(profile.fastestIntervalMs)
            .setMinUpdateDistanceMeters(profile.minDistanceMeters)
            .build()
        try {
            fused.requestLocationUpdates(request, locationCallback, Looper.getMainLooper())
                .addOnSuccessListener {
                    // A profile may have changed while registration was pending. The newer
                    // configureLocationUpdates call already removes/replaces this callback.
                    if (locationProfile == profile.name && store.string("state") == "ACTIVE") {
                        updatesRequested = true
                    }
                }
                .addOnFailureListener { error ->
                    if (locationProfile != profile.name) return@addOnFailureListener
                    store.putString("state", "ERROR")
                    store.putString("lastError", "Unable to start location updates: ${error.localizedMessage ?: error.javaClass.simpleName}")
                    showMonitoringWarning(store.string("lastError"))
                    stopSelf()
                }
        } catch (error: SecurityException) {
            store.putString("state", "ERROR")
            store.putString("lastError", "Android denied location access: ${error.localizedMessage ?: "permission missing"}")
            showMonitoringWarning(store.string("lastError"))
            stopSelf()
        }
    }

    private fun onLocation(location: Location) {
        if (store.string("state") != "ACTIVE") return
        if (!location.latitude.isFinite() || !location.longitude.isFinite()) return
        // Do not make a proximity decision on a very poor fix. Keep monitoring for a better one.
        if (!location.accuracy.isFinite() || location.accuracy > MAX_ACCEPTED_ACCURACY_METERS) {
            store.putString("lastError", "Waiting for a more accurate location fix (current accuracy ${location.accuracy.toInt()} m).")
            updateTrackingNotification()
            return
        }

        lastLocation = location
        if (store.bool("locationStaleWarningShown", false)) {
            store.putBool("locationStaleWarningShown", false)
            getSystemService(NotificationManager::class.java).cancel(WARNING_NOTIFICATION_ID)
        }
        val destination = Location("destination").apply {
            latitude = store.double("destinationLatitude", Double.NaN)
            longitude = store.double("destinationLongitude", Double.NaN)
        }
        if (!destination.latitude.isFinite() || !destination.longitude.isFinite()) {
            store.putString("state", "ERROR")
            store.putString("lastError", "Destination coordinates are missing. Stop and set the journey again.")
            stopSelf()
            return
        }

        val distance = location.distanceTo(destination).toDouble()
        configureLocationUpdates(distance)
        store.putDouble("distanceMeters", distance)
        store.putDouble("locationAccuracyMeters", location.accuracy.toDouble())
        store.putDouble("currentLatitude", location.latitude)
        store.putDouble("currentLongitude", location.longitude)
        store.putLong("locationUpdatedAt", System.currentTimeMillis())
        store.putString("lastError", "")

        maybeRequestRoute(location)
        val eta = store.long("routeEtaSeconds", -1L).takeIf {
            it >= 0L && System.currentTimeMillis() - store.long("routeEtaUpdatedAt") <= JourneyPreferences.ROUTE_ETA_MAX_AGE_MS
        }
        val radius = store.double("radiusMeters", 2000.0)
        val preparationMinutes = store.int("preparationMinutes", 5)
        val shouldRing = ArrivalPolicy.shouldTrigger(
            distanceMeters = distance,
            accuracyMeters = location.accuracy.toDouble(),
            radiusMeters = radius,
            routeEtaSeconds = eta,
            preparationMinutes = preparationMinutes,
        )
        if (shouldRing) {
            val reason = if (eta != null && eta <= preparationMinutes.coerceAtLeast(1) * 60L) {
                "Road ETA reached the preparation window"
            } else {
                "Destination radius reached"
            }
            triggerAlarm(reason, distance)
        } else {
            updateTrackingNotification()
        }
    }

    private fun maybeRequestRoute(location: Location) {
        val now = System.currentTimeMillis()
        val lastRequestAt = store.long("routeRequestAt")
        val lastLat = store.double("routeRequestLatitude", Double.NaN)
        val lastLon = store.double("routeRequestLongitude", Double.NaN)
        val movedMeters = if (lastLat.isFinite() && lastLon.isFinite()) {
            val old = Location("previous route query").apply { latitude = lastLat; longitude = lastLon }
            old.distanceTo(location).toDouble()
        } else Double.POSITIVE_INFINITY
        if (lastRequestAt > 0L && now - lastRequestAt < ROUTE_REQUEST_INTERVAL_MS && movedMeters < ROUTE_REFRESH_DISTANCE_METERS) return

        store.putLong("routeRequestAt", now)
        store.putDouble("routeRequestLatitude", location.latitude)
        store.putDouble("routeRequestLongitude", location.longitude)
        val destinationLat = store.double("destinationLatitude", Double.NaN)
        val destinationLon = store.double("destinationLongitude", Double.NaN)
        routeExecutor.execute {
            var connection: HttpURLConnection? = null
            try {
                // Public OSRM demo endpoint: good for development only, no traffic model/SLA.
                val url = URL("$ROUTING_BASE_URL/${location.longitude},${location.latitude};${destinationLon},${destinationLat}?overview=false&alternatives=false&steps=false")
                connection = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "GET"
                    connectTimeout = 6000
                    readTimeout = 6000
                    setRequestProperty("User-Agent", "ProximityAlarm/0.1 Android prototype")
                }
                if (connection.responseCode != HttpURLConnection.HTTP_OK) {
                    throw IllegalStateException("Routing service HTTP ${connection.responseCode}")
                }
                val payload = connection.inputStream.bufferedReader().use { it.readText() }
                val root = JSONObject(payload)
                val routes = root.optJSONArray("routes")
                if (routes == null || routes.length() == 0) throw IllegalStateException("No road route found")
                val eta = routes.getJSONObject(0).optDouble("duration", Double.NaN)
                if (!eta.isFinite() || eta < 0) throw IllegalStateException("Invalid route ETA")
                val etaSeconds = eta.toLong()
                store.putLong("routeEtaSeconds", etaSeconds)
                store.putLong("routeEtaUpdatedAt", System.currentTimeMillis())
                store.putString("lastError", "")
                // The latest location can satisfy the ETA threshold even between GPS callbacks.
                val latest = lastLocation
                val fixIsFresh = System.currentTimeMillis() - store.long("locationUpdatedAt") <= MAX_LOCATION_AGE_FOR_ETA_MS
                if (latest != null && fixIsFresh && store.string("state") == "ACTIVE") {
                    val destination = Location("destination").apply {
                        latitude = destinationLat
                        longitude = destinationLon
                    }
                    val distance = latest.distanceTo(destination).toDouble()
                    val radius = store.double("radiusMeters", 2000.0)
                    val preparation = store.int("preparationMinutes", 5)
                    if (ArrivalPolicy.shouldTrigger(distance, latest.accuracy.toDouble(), radius, etaSeconds, preparation)) {
                        val reason = if (etaSeconds <= preparation.coerceAtLeast(1) * 60L) "Road ETA reached the preparation window" else "Destination radius reached"
                        triggerAlarm(reason, distance)
                    } else {
                        updateTrackingNotification()
                    }
                }
            } catch (error: Exception) {
                Log.w(TAG, "Road ETA request failed; fixed-radius fallback remains active", error)
                store.putString("lastError", "Road ETA unavailable; fixed-radius fallback is active.")
                updateTrackingNotification()
            } finally {
                connection?.disconnect()
            }
        }
    }

    private fun triggerAlarm(reason: String, distanceMeters: Double) {
        // Foreground-service and MediaPlayer changes are serialized on Android's main thread.
        if (Looper.myLooper() != Looper.getMainLooper()) {
            mainHandler.post { triggerAlarm(reason, distanceMeters) }
            return
        }
        if (store.bool("alarmRinging", false) || store.string("state") != "ACTIVE") return
        store.putString("state", "TRIGGERED")
        store.putBool("alarmRinging", true)
        store.putString("triggerReason", reason)
        store.putString("lastError", "")
        store.putBool("locationStaleWarningShown", false)
        getSystemService(NotificationManager::class.java).cancel(WARNING_NOTIFICATION_ID)
        store.putString("lastTriggeredAt", formatTimestamp(System.currentTimeMillis()))
        store.putDouble("triggerDistanceMeters", distanceMeters)
        try { fused.removeLocationUpdates(locationCallback) } catch (_: Exception) { }
        updatesRequested = false
        locationProfile = null
        startForegroundCompat(ALARM_NOTIFICATION_ID, buildAlarmNotification(), includeMediaPlayback = true)
        startAlarmSound()
    }

    private fun startAlarmSound() {
        if (mediaPlayer?.isPlaying == true) return
        releaseAlarmSound()
        try {
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                ?: run {
                    store.putString("lastError", "No default alarm sound is configured on this device.")
                    updateAlarmNotification()
                    return
                }
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                setDataSource(this@ProximityTrackingService, alarmUri)
                isLooping = true
                setWakeMode(this@ProximityTrackingService, PowerManager.PARTIAL_WAKE_LOCK)
                setOnErrorListener { _, _, _ ->
                    store.putString("lastError", "Alarm audio failed to play. Check alarm volume and device audio settings.")
                    true
                }
                prepare()
                start()
            }
        } catch (error: Exception) {
            Log.e(TAG, "Unable to play alarm", error)
            store.putString("lastError", "Alarm audio could not start: ${error.localizedMessage ?: "unknown audio error"}")
            updateAlarmNotification()
        }
    }

    private fun releaseAlarmSound() {
        try { mediaPlayer?.stop() } catch (_: Exception) { }
        try { mediaPlayer?.release() } catch (_: Exception) { }
        mediaPlayer = null
    }

    private fun updateTrackingNotification() {
        if (store.string("state") != "ACTIVE") return
        getSystemService(NotificationManager::class.java).notify(SERVICE_NOTIFICATION_ID, buildTrackingNotification())
    }

    private fun scheduleHealthChecks() {
        mainHandler.removeCallbacks(healthCheckRunnable)
        mainHandler.postDelayed(healthCheckRunnable, HEALTH_CHECK_INTERVAL_MS)
    }

    private fun showMonitoringWarning(message: String) {
        val notification = NotificationCompat.Builder(this, CHANNEL_WARNINGS)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("Location monitoring needs attention")
            .setContentText(message)
            .setContentIntent(openAppPendingIntent())
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .build()
        getSystemService(NotificationManager::class.java).notify(WARNING_NOTIFICATION_ID, notification)
    }

    private fun updateAlarmNotification() {
        getSystemService(NotificationManager::class.java).notify(ALARM_NOTIFICATION_ID, buildAlarmNotification())
    }

    private fun buildTrackingNotification(): Notification {
        val distance = store.double("distanceMeters", Double.NaN)
        val statusMessage = store.string("lastError")
        val details = if (statusMessage.isNotBlank()) statusMessage else if (distance.isFinite()) "${(distance / 1000.0).let { String.format(java.util.Locale.getDefault(), "%.1f", it) }} km to ${store.string("destinationName", "destination")}" else "Waiting for a usable GPS fix"
        return NotificationCompat.Builder(this, CHANNEL_TRACKING)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentTitle("Destination alarm is active")
            .setContentText(details)
            .setContentIntent(openAppPendingIntent())
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .build()
    }

    private fun buildAlarmNotification(): Notification {
        val stopIntent = PendingIntent.getBroadcast(
            this,
            DISMISS_REQUEST_CODE,
            Intent(this, AlarmActionReceiver::class.java).setAction(ACTION_DISMISS),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ALARM)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("You are approaching ${store.string("destinationName", "your destination")}")
            .setContentText(store.string("lastError").ifBlank { store.string("triggerReason", "Your destination condition was met") })
            .setContentIntent(openAppPendingIntent())
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .addAction(android.R.drawable.ic_media_pause, "Dismiss alarm", stopIntent)
            .build()
    }

    private fun openAppPendingIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(this, OPEN_APP_REQUEST_CODE, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_TRACKING, "Journey monitoring", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Shows when a destination alarm is monitoring a journey."
                setShowBadge(false)
            },
        )
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_WARNINGS, "Journey health warnings", NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = "Warns when location updates stop or become stale during a journey."
                setSound(null, null)
                enableVibration(true)
            },
        )
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ALARM, "Destination alarms", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "A loud alarm when a configured arrival condition is met."
                setSound(null, null) // Alarm audio is played by the foreground service to avoid double sound.
                enableVibration(true)
                setShowBadge(true)
            },
        )
    }

    private fun startForegroundCompat(
        notificationId: Int,
        notification: Notification,
        includeMediaPlayback: Boolean = false,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val serviceTypes = if (includeMediaPlayback) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION or ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            } else {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            }
            startForeground(notificationId, notification, serviceTypes)
        } else {
            startForeground(notificationId, notification)
        }
    }

    private fun formatTimestamp(milliseconds: Long): String = SimpleDateFormat(
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        Locale.US,
    ).apply { timeZone = TimeZone.getTimeZone("UTC") }.format(Date(milliseconds))

    companion object {
        const val ACTION_START = "com.example.proximity_alarm.START"
        const val ACTION_STOP = "com.example.proximity_alarm.STOP"
        const val ACTION_DISMISS = "com.example.proximity_alarm.DISMISS"
        const val CHANNEL_TRACKING = "journey_monitoring"
        const val CHANNEL_ALARM = "destination_alarm"
        const val CHANNEL_WARNINGS = "journey_health_warnings"
        const val SERVICE_NOTIFICATION_ID = 7101
        const val ALARM_NOTIFICATION_ID = 7102
        const val WARNING_NOTIFICATION_ID = 7103
        private const val OPEN_APP_REQUEST_CODE = 7201
        private const val DISMISS_REQUEST_CODE = 7202
        private const val MAX_LOCATION_AGE_FOR_ETA_MS = 60_000L
        private const val LOCATION_STALE_AFTER_MS = 60_000L
        private const val HEALTH_CHECK_INTERVAL_MS = 30_000L
        private const val MAX_ACCEPTED_ACCURACY_METERS = 100f
        private const val ROUTE_REQUEST_INTERVAL_MS = 60_000L
        private const val ROUTE_REFRESH_DISTANCE_METERS = 800.0
        private const val ROUTING_BASE_URL = "https://router.project-osrm.org/route/v1/driving"
        private const val TAG = "ProximityAlarmService"
    }

    private data class LocationProfile(
        val name: String,
        val priority: Int,
        val intervalMs: Long,
        val fastestIntervalMs: Long,
        val minDistanceMeters: Float,
    )
}
