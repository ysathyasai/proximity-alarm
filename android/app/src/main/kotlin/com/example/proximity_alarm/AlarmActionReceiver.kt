package com.example.proximity_alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.NotificationManager

class AlarmActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == ProximityTrackingService.ACTION_DISMISS) {
            dismiss(context)
        }
    }

    companion object {
        fun dismiss(context: Context) {
            val appContext = context.applicationContext
            val store = JourneyPreferences(appContext)
            store.putBool("alarmRinging", false)
            store.putString("state", "DISMISSED")
            appContext.stopService(Intent(appContext, ProximityTrackingService::class.java))
            val notifications = appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notifications.cancel(ProximityTrackingService.SERVICE_NOTIFICATION_ID)
            notifications.cancel(ProximityTrackingService.ALARM_NOTIFICATION_ID)
        }
    }
}
