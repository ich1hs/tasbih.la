package com.ich1hs.tasbih_la

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerWidgetProvider : HomeWidgetProvider() {
    
    companion object {
        private const val TAG = "PrayerWidget"
    }
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.prayer_widget)
                
                // Safely get prayer data with fallbacks
                val nextName = safeGetString(widgetData, "nextPrayerName", "---")
                val nextTime = safeGetString(widgetData, "nextPrayerTime", "--:--")
                val nextIcon = safeGetString(widgetData, "nextPrayerIcon", "☪")
                val remaining = safeGetString(widgetData, "nextPrayerRemaining", "")
                
                // Get all prayer times
                val fajr = safeGetString(widgetData, "fajr", "--:--")
                val sunrise = safeGetString(widgetData, "sunrise", "--:--")
                val dhuhr = safeGetString(widgetData, "dhuhr", "--:--")
                val asr = safeGetString(widgetData, "asr", "--:--")
                val maghrib = safeGetString(widgetData, "maghrib", "--:--")
                val isha = safeGetString(widgetData, "isha", "--:--")
                
                // Set next prayer header
                views.setTextViewText(R.id.widget_next_icon, nextIcon)
                views.setTextViewText(R.id.widget_next_name, nextName)
                views.setTextViewText(R.id.widget_next_time, nextTime)
                views.setTextViewText(R.id.widget_remaining, if (remaining.isNotEmpty()) "in $remaining" else "")
                
                // Set all prayer times with labels
                views.setTextViewText(R.id.widget_fajr, "Fajr  $fajr")
                views.setTextViewText(R.id.widget_sunrise, "Sunrise  $sunrise")
                views.setTextViewText(R.id.widget_dhuhr, "Dhuhr  $dhuhr")
                views.setTextViewText(R.id.widget_asr, "Asr  $asr")
                views.setTextViewText(R.id.widget_maghrib, "Maghrib  $maghrib")
                views.setTextViewText(R.id.widget_isha, "Isha  $isha")
                
                // Click to open app - use simple intent as fallback
                try {
                    val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("tasbihla://prayerwidget/prayer_times")
                    )
                    views.setOnClickPendingIntent(R.id.prayer_widget_root, pendingIntent)
                } catch (e: Exception) {
                    // Fallback to simple intent
                    val intent = Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        widgetId,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.prayer_widget_root, pendingIntent)
                }
                
                appWidgetManager.updateAppWidget(widgetId, views)
                Log.d(TAG, "Widget $widgetId updated successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error updating widget $widgetId: ${e.message}", e)
                // Try to show a basic fallback widget
                try {
                    val fallbackViews = RemoteViews(context.packageName, R.layout.prayer_widget)
                    fallbackViews.setTextViewText(R.id.widget_next_name, "---")
                    fallbackViews.setTextViewText(R.id.widget_next_time, "--:--")
                    fallbackViews.setTextViewText(R.id.widget_next_icon, "☪")
                    fallbackViews.setTextViewText(R.id.widget_remaining, "")
                    fallbackViews.setTextViewText(R.id.widget_fajr, "Fajr  --:--")
                    fallbackViews.setTextViewText(R.id.widget_sunrise, "Sunrise  --:--")
                    fallbackViews.setTextViewText(R.id.widget_dhuhr, "Dhuhr  --:--")
                    fallbackViews.setTextViewText(R.id.widget_asr, "Asr  --:--")
                    fallbackViews.setTextViewText(R.id.widget_maghrib, "Maghrib  --:--")
                    fallbackViews.setTextViewText(R.id.widget_isha, "Isha  --:--")
                    appWidgetManager.updateAppWidget(widgetId, fallbackViews)
                } catch (fallbackError: Exception) {
                    Log.e(TAG, "Fallback also failed: ${fallbackError.message}")
                }
            }
        }
    }
    
    private fun safeGetString(prefs: SharedPreferences, key: String, default: String): String {
        return try {
            prefs.getString(key, default) ?: default
        } catch (e: Exception) {
            default
        }
    }
    
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        Log.d(TAG, "Widget enabled")
    }
    
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        Log.d(TAG, "Widget disabled")
    }
}
