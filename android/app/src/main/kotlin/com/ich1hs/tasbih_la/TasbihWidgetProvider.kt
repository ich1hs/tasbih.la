package com.ich1hs.tasbih_la

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TasbihWidgetProvider : HomeWidgetProvider() {
    
    companion object {
        private const val TAG = "TasbihWidget"
    }
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.tasbih_widget)
                
                // Safely get count with fallback
                val count = try {
                    widgetData.getString("globalTotal", "0") ?: "0"
                } catch (e: Exception) {
                    "0"
                }
                views.setTextViewText(R.id.widget_count, count)
                
                // Open app on click
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 
                    widgetId, 
                    intent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                
                appWidgetManager.updateAppWidget(widgetId, views)
                Log.d(TAG, "Widget $widgetId updated successfully with count: $count")
            } catch (e: Exception) {
                Log.e(TAG, "Error updating widget $widgetId: ${e.message}", e)
                // Try to show a basic fallback widget
                try {
                    val fallbackViews = RemoteViews(context.packageName, R.layout.tasbih_widget)
                    fallbackViews.setTextViewText(R.id.widget_count, "0")
                    appWidgetManager.updateAppWidget(widgetId, fallbackViews)
                } catch (fallbackError: Exception) {
                    Log.e(TAG, "Fallback also failed: ${fallbackError.message}")
                }
            }
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
