import 'package:home_widget/home_widget.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class WidgetService {
  static const String budgetWidgetName = 'BudgetWidgetProvider';
  static const String quickActionsWidgetName = 'QuickActionsWidgetProvider';
  static const String calendarWidgetName = 'CalendarWidgetProvider';
  static const String medicationsWidgetName = 'MedicationWidgetProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId('group.phobes');
  }

  static Future<void> updateBudgetWidget({
    required double income,
    required double expense,
    required double balance,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>(
          'budget_income', '₺${income.toStringAsFixed(1)}');
      await HomeWidget.saveWidgetData<String>(
          'budget_expense', '₺${expense.toStringAsFixed(1)}');
      await HomeWidget.saveWidgetData<String>(
          'budget_balance', '₺${balance.toStringAsFixed(1)}');

      await HomeWidget.updateWidget(
        name: budgetWidgetName,
        iOSName: budgetWidgetName,
      );
    } on PlatformException catch (e) {
      debugPrint('Error updating budget widget: $e');
    }
  }

  // Quick Actions widget'ı statik butonlar içerdiği için şu an için veri güncellemesine
  // ihtiyaç duymuyor. Ancak genel widget güncellemeleri için yardımcı metod konulabilir.
  static Future<void> updateQuickActionsWidget() async {
    try {
      await HomeWidget.updateWidget(
        name: quickActionsWidgetName,
        iOSName: quickActionsWidgetName,
      );
    } on PlatformException catch (e) {
      debugPrint('Error updating quick actions widget: $e');
    }
  }

  static Future<void> updateCalendarWidget(List<String> items) async {
    try {
      if (items.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>(
            'calendar_item_1', items.isNotEmpty ? items[0] : "");
        await HomeWidget.saveWidgetData<String>(
            'calendar_item_2', items.length > 1 ? items[1] : "");
        await HomeWidget.saveWidgetData<String>(
            'calendar_item_3', items.length > 2 ? items[2] : "");
      } else {
        await HomeWidget.saveWidgetData<String>(
            'calendar_item_1', "Bugün için yaklaşan etkinlik/görev yok.");
        await HomeWidget.saveWidgetData<String>('calendar_item_2', "");
        await HomeWidget.saveWidgetData<String>('calendar_item_3', "");
      }

      await HomeWidget.updateWidget(
        name: calendarWidgetName,
        iOSName: calendarWidgetName,
      );
    } on PlatformException catch (e) {
      debugPrint('Error updating calendar widget: $e');
    }
  }

  static Future<void> updateMedicationWidget(List<String> items) async {
    try {
      if (items.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>(
            'med_item_1', items.isNotEmpty ? items[0] : "");
        await HomeWidget.saveWidgetData<String>(
            'med_item_2', items.length > 1 ? items[1] : "");
        await HomeWidget.saveWidgetData<String>(
            'med_item_3', items.length > 2 ? items[2] : "");
      } else {
        await HomeWidget.saveWidgetData<String>(
            'med_item_1', "Bugün için ilaç verisi yok.");
        await HomeWidget.saveWidgetData<String>('med_item_2', "");
        await HomeWidget.saveWidgetData<String>('med_item_3', "");
      }

      await HomeWidget.updateWidget(
        name: medicationsWidgetName,
        iOSName: medicationsWidgetName,
      );
    } on PlatformException catch (e) {
      debugPrint('Error updating medications widget: $e');
    }
  }
}
