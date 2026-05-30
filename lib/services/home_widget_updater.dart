import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:home_widget/home_widget.dart';
import 'firebase_service.dart';
import 'budget_service.dart';
import 'widget_service.dart';

/// Encapsulates all iOS/Android home-widget update logic.
/// Call [updateAll] after login or meaningful data changes.
class HomeWidgetUpdater {
  HomeWidgetUpdater._();
  static final HomeWidgetUpdater instance = HomeWidgetUpdater._();

  final _firebase = FirebaseService();
  final _budget = BudgetService();

  Future<void> updateAll() async {
    if (kIsWeb) return;
    try {
      await Future.wait([
        _updateTaskWidget(),
        _updateBudgetWidget(),
        _updateMedicationWidget(),
      ]);
    } catch (e) {
      debugPrint('[HomeWidgetUpdater] updateAll error: $e');
    }
  }

  Future<void> _updateTaskWidget() async {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final tasks = await _firebase.getTasksForDateRange(now, endOfDay).first;

    final pendingTasks =
        tasks.where((t) => !t.isCompleted && t.status != 'done').length;
    final message = pendingTasks > 0
        ? 'Bugün için $pendingTasks görev kaldı!'
        : 'Tüm görevler tamamlandı, harika!';

    await HomeWidget.saveWidgetData<String>('widget_message', message);
    await HomeWidget.updateWidget(
      name: 'HomeWidgetProvider',
      iOSName: 'PhobesWidget',
    );

    // Build calendar items for the widget
    final calendarItems = <String>[];
    int remainingTasks = 0;
    for (final t in tasks) {
      if (!t.isCompleted && t.status != 'done') {
        if (calendarItems.length < 3) calendarItems.add('• ${t.title}');
        remainingTasks++;
      }
    }
    if (remainingTasks > 3 && calendarItems.length >= 3) {
      calendarItems[2] = '... ve ${remainingTasks - 2} görev daha';
    } else if (remainingTasks > calendarItems.length) {
      calendarItems.add('... ve ${remainingTasks - calendarItems.length} görev daha');
    }
    await WidgetService.updateCalendarWidget(calendarItems);
  }

  Future<void> _updateBudgetWidget() async {
    final budgetData = await _budget.getSankeyData();
    await WidgetService.updateBudgetWidget(
      income: budgetData['income'] as double? ?? 0.0,
      expense: budgetData['expenseTotal'] as double? ?? 0.0,
      balance: budgetData['savings'] as double? ?? 0.0,
    );
  }

  Future<void> _updateMedicationWidget() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final medsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medications')
        .get();

    final medItems = <String>[];
    int remainingMeds = 0;

    for (final doc in medsSnapshot.docs) {
      final data = doc.data();
      if (data['isActive'] == false) continue;
      final times = (data['times'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final taken =
          (data['takenHistory'] as Map<String, dynamic>?)?[todayStr];
      final takenList = taken is List
          ? taken.map((e) => e.toString()).toList()
          : <String>[];
      final pending =
          times.where((t) => !takenList.contains(t)).toList();
      if (pending.isEmpty) continue;
      if (medItems.length < 3) {
        medItems.add(
          "• ${data['name']} (${data['dosage'] ?? ''}) — ${pending.first}",
        );
      }
      remainingMeds += pending.length;
    }

    if (remainingMeds > 3 && medItems.length >= 3) {
      medItems[2] = '... ve ${remainingMeds - 2} ilaç daha';
    } else if (remainingMeds > medItems.length) {
      medItems.add('... ve ${remainingMeds - medItems.length} ilaç daha');
    }

    await WidgetService.updateMedicationWidget(medItems);
  }
}
