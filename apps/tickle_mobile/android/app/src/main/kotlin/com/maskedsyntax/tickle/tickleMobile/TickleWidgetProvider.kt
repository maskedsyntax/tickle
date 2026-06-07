package com.maskedsyntax.tickle.tickleMobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import org.json.JSONArray
import org.json.JSONObject

class TickleWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                removeAllViews(R.id.counters_container)
                
                val jsonString = widgetData.getString("top_counters", null)
                if (jsonString != null) {
                    try {
                        val jsonArray = JSONArray(jsonString)
                        for (i in 0 until Math.min(jsonArray.length(), 3)) {
                            val counter = jsonArray.getJSONObject(i)
                            val id = counter.getString("id")
                            val title = counter.getString("title")
                            val count = counter.getInt("currentCount")
                            val emoji = counter.getString("emoji")
                            
                            val row = RemoteViews(context.packageName, android.R.layout.simple_list_item_1).apply {
                                setTextViewText(android.R.id.text1, "$emoji $title: $count")
                                // Set up click intent for background Dart execution
                                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                                    context, 
                                    Uri.parse("homeWidgetExample://increment?id=$id")
                                )
                                setOnClickPendingIntent(android.R.id.text1, backgroundIntent)
                            }
                            addView(R.id.counters_container, row)
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}