package com.watercherry.conquestofkorea

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class ConquestWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFERENCES = "HomeWidgetPreferences"

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.conquest_widget)
            views.setTextViewText(
                R.id.widget_territory,
                prefs.getInt("territory", 0).toString()
            )
            views.setTextViewText(
                R.id.widget_daily_moved,
                prefs.getInt("dailyMoved", 0).toString()
            )
            views.setTextViewText(
                R.id.widget_steps,
                prefs.getInt("steps", 0).toString()
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
