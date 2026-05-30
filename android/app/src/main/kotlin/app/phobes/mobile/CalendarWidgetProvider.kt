package app.phobes.mobile

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.content.SharedPreferences

class CalendarWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val sharedPref = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, sharedPref)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, sharedPref: SharedPreferences) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout_calendar)

        val item1 = sharedPref.getString("calendar_item_1", "Bugün için yaklaşan etkinlik/görev yok.")
        val item2 = sharedPref.getString("calendar_item_2", "")
        val item3 = sharedPref.getString("calendar_item_3", "")

        views.setTextViewText(R.id.widget_calendar_item_1, item1)
        views.setTextViewText(R.id.widget_calendar_item_2, item2)
        views.setTextViewText(R.id.widget_calendar_item_3, item3)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
