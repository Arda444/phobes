package app.phobes.mobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class QuickActionsWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout_quick_actions)

        // Görev Ekleme Intent'i
        val taskIntent = Intent(Intent.ACTION_VIEW, Uri.parse("phobes://add_task"))
        val pendingTaskIntent = PendingIntent.getActivity(context, 0, taskIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        views.setOnClickPendingIntent(R.id.btn_add_task, pendingTaskIntent)

        // Gider Ekleme Intent'i
        val expenseIntent = Intent(Intent.ACTION_VIEW, Uri.parse("phobes://add_expense"))
        val pendingExpenseIntent = PendingIntent.getActivity(context, 1, expenseIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        views.setOnClickPendingIntent(R.id.btn_add_expense, pendingExpenseIntent)

        // İlaç Ekleme Intent'i
        val medIntent = Intent(Intent.ACTION_VIEW, Uri.parse("phobes://add_medication"))
        val pendingMedIntent = PendingIntent.getActivity(context, 2, medIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        views.setOnClickPendingIntent(R.id.btn_add_medication, pendingMedIntent)

        // Not Ekleme Intent'i
        val noteIntent = Intent(Intent.ACTION_VIEW, Uri.parse("phobes://add_note"))
        val pendingNoteIntent = PendingIntent.getActivity(context, 3, noteIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        views.setOnClickPendingIntent(R.id.btn_add_note, pendingNoteIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
