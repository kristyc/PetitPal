package com.petitpal.app  // make sure this matches your applicationId

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class MicWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val primary   = widgetData.getInt("pp_primary",   0xFF2196F3.toInt())
        val onPrimary = widgetData.getInt("pp_onPrimary", 0xFFFFFFFF.toInt())
        val secondary = widgetData.getInt("pp_secondary", 0xFF4CAF50.toInt())
        val state = widgetData.getString("mic_widget_state", "idle") ?: "idle"

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.mic_widget)

            val bgColor = if (state == "listening") secondary else primary
            views.setInt(R.id.circle_bg, "setColorFilter", bgColor)

            val iconRes = when (state) {
                "listening" -> R.drawable.ic_stop_24
                "thinking"  -> R.drawable.ic_close_24
                else        -> R.drawable.ic_mic_24
            }
            views.setImageViewResource(R.id.mic_button, iconRes)
            views.setInt(R.id.mic_button, "setColorFilter", onPrimary)

            val intent = Intent(context, MicForegroundService::class.java).apply {
                action = "com.petitpal.app.ACTION_TOGGLE"
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

            // ⬇️ start as a Foreground Service (Android 8+)
            val pi = PendingIntent.getForegroundService(context, 0, intent, flags)

            views.setOnClickPendingIntent(R.id.mic_root, pi)
            views.setOnClickPendingIntent(R.id.mic_button, pi)

            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
