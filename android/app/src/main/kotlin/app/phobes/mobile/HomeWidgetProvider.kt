package app.phobes.mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            
            val message = widgetData.getString("widget_message", "Bugün için bekleyen görev yok!")
            views.setTextViewText(R.id.widget_message, message)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
