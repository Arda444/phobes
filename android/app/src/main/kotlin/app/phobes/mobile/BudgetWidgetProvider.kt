package app.phobes.mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class BudgetWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout_budget)
            
            val income = widgetData.getString("widget_income", "₺0.0")
            val expense = widgetData.getString("widget_expense", "₺0.0")
            val balance = widgetData.getString("widget_balance", "₺0.0")
            
            views.setTextViewText(R.id.widget_income, income)
            views.setTextViewText(R.id.widget_expense, expense)
            views.setTextViewText(R.id.widget_balance, balance)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
