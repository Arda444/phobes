import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'statistics_models.dart';

extension StatsPeriodL10n on StatsPeriod {
  String labelOf(AppLocalizations l10n) {
    switch (this) {
      case StatsPeriod.day:
        return l10n.statsPeriodDaily;
      case StatsPeriod.week:
        return l10n.statsPeriodWeek;
      case StatsPeriod.month:
        return l10n.statsPeriodMonth;
      case StatsPeriod.quarter:
        return l10n.statsPeriodQuarter;
    }
  }

  String shortLabelOf(AppLocalizations l10n) {
    switch (this) {
      case StatsPeriod.day:
        return l10n.statsPeriodToday;
      case StatsPeriod.week:
        return l10n.statsPeriod7Days;
      case StatsPeriod.month:
        return l10n.statsPeriod30Days;
      case StatsPeriod.quarter:
        return l10n.statsPeriod90Days;
    }
  }
}

String statsWeekdayLabel(int weekday, AppLocalizations l10n) {
  switch (weekday) {
    case 1:
      return l10n.statsWeekdayMon;
    case 2:
      return l10n.statsWeekdayTue;
    case 3:
      return l10n.statsWeekdayWed;
    case 4:
      return l10n.statsWeekdayThu;
    case 5:
      return l10n.statsWeekdayFri;
    case 6:
      return l10n.statsWeekdaySat;
    case 7:
      return l10n.statsWeekdaySun;
    default:
      return '?';
  }
}

String statsFmtMinutes(int m, AppLocalizations l10n) {
  if (m < 60) return l10n.statsMinutesShort(m);
  return l10n.statsHoursMinutesShort(m ~/ 60, m % 60);
}

extension TaskPeriodStatsL10n on TaskPeriodStats {
  Map<String, double> weekdayPieL10n(AppLocalizations l10n) =>
      weekdayBreakdown.map(
        (k, v) => MapEntry(statsWeekdayLabel(k, l10n), v),
      );

  Map<String, double> priorityPieL10n(AppLocalizations l10n) =>
      priorityBreakdown.map(
        (k, v) => MapEntry(
          k >= 3
              ? l10n.statsPriorityHigh
              : k == 2
                  ? l10n.statsPriorityMedium
                  : l10n.statsPriorityLow,
          v.toDouble(),
        ),
      );

  Map<String, double> statusPieL10n(AppLocalizations l10n) {
    final m = <String, double>{};
    if (completed > 0) m[l10n.statsCompleted] = completed.toDouble();
    if (pending > 0) m[l10n.statsPendingLabel] = pending.toDouble();
    if (overdue > 0) m[l10n.statsOverdue] = overdue.toDouble();
    return m;
  }

  List<StatMetric> primaryMetricsL10n(AppLocalizations l10n) => [
        StatMetric(
            label: l10n.statsCompleted, value: '$completed', accent: Colors.green),
        StatMetric(
            label: l10n.statsPendingLabel,
            value: '$pending',
            accent: Colors.orange),
        StatMetric(
          label: l10n.statsCompletionRate,
          value: '%${completionRate.toStringAsFixed(0)}',
          accent: Colors.blue,
        ),
        StatMetric(
            label: l10n.statsStreak,
            value: l10n.statsDaysUnit(streakDays),
            accent: Colors.deepOrange),
        StatMetric(
            label: l10n.statsOverdue, value: '$overdue', accent: Colors.red),
        StatMetric(
            label: l10n.statsFocusDuration,
            value: statsFmtMinutes(focusMinutes, l10n)),
        StatMetric(
          label: l10n.statsProductivity,
          value: '${productivityScore.toStringAsFixed(0)}/100',
        ),
        StatMetric(label: l10n.statsCreatedLabel, value: '$created'),
        StatMetric(label: l10n.statsPostponed, value: '$postponed'),
        StatMetric(
          label: l10n.statsAvgDuration,
          value: l10n.statsMinutesShort(avgDurationMinutes.round()),
        ),
        StatMetric(label: l10n.statsBusiestDay, value: busiestDay),
        StatMetric(label: l10n.statsPeakHour, value: peakTimeSlot),
        StatMetric(label: l10n.statsWithSubtasks, value: '$withSubtasks'),
        StatMetric(label: l10n.statsRecurring, value: '$recurring'),
      ];
}

extension HabitPeriodStatsL10n on HabitPeriodStats {
  Map<String, double> completionPieL10n(AppLocalizations l10n) => {
        l10n.statsCompleted: periodCompletionRate,
        if (periodCompletionRate < 100)
          l10n.statsMissing: 100 - periodCompletionRate,
      };

  List<StatMetric> metricsL10n(AppLocalizations l10n) => [
        StatMetric(label: l10n.statsTotalHabits, value: '$totalHabits'),
        StatMetric(
          label: l10n.statsCompletedInPeriod,
          value: '$completedInPeriod',
          accent: Colors.green,
        ),
        StatMetric(
          label: l10n.statsPeriodAdherence,
          value: '%${periodCompletionRate.toStringAsFixed(0)}',
        ),
        StatMetric(
            label: l10n.statsLongestStreak,
            value: l10n.statsDaysUnit(maxStreak)),
        StatMetric(label: l10n.statsActiveToday, value: '$activeToday'),
      ];
}

extension BudgetPeriodStatsL10n on BudgetPeriodStats {
  Map<String, double> transactionCountPieL10n(AppLocalizations l10n) {
    final m = <String, double>{};
    if (incomeCount > 0) m[l10n.statsIncomeTxn] = incomeCount.toDouble();
    if (expenseCount > 0) m[l10n.statsExpenseTxn] = expenseCount.toDouble();
    return m;
  }

  Map<String, double> incomeExpensePieL10n(AppLocalizations l10n) {
    final m = <String, double>{};
    if (totalIncome > 0) m[l10n.statsIncomeLabel] = totalIncome;
    if (totalExpense > 0) m[l10n.statsExpenseLabel] = totalExpense;
    return m;
  }

  List<StatMetric> metricsL10n(AppLocalizations l10n) => [
        StatMetric(
          label: l10n.statsIncomeLabel,
          value: '₺${totalIncome.toStringAsFixed(0)}',
          accent: Colors.green,
        ),
        StatMetric(
          label: l10n.statsExpenseLabel,
          value: '₺${totalExpense.toStringAsFixed(0)}',
          accent: Colors.red,
        ),
        StatMetric(
          label: l10n.statsNetLabel,
          value: '₺${net.toStringAsFixed(0)}',
          accent: net >= 0 ? Colors.green : Colors.red,
        ),
        StatMetric(label: l10n.statsTxnCount, value: '$transactionCount'),
        StatMetric(label: l10n.statsIncomeTxn, value: '$incomeCount'),
        StatMetric(label: l10n.statsExpenseTxn, value: '$expenseCount'),
        StatMetric(
          label: l10n.statsTotalBalance,
          value: '₺${totalBalance.toStringAsFixed(0)}',
        ),
        StatMetric(label: l10n.statsAccountLabel, value: '$accountCount'),
        StatMetric(
          label: l10n.statsTopSpending,
          value: topCategory == '-'
              ? '-'
              : '$topCategory (₺${topCategoryAmount.toStringAsFixed(0)})',
        ),
      ];
}

extension NotesPeriodStatsL10n on NotesPeriodStats {
  Map<String, double> categoryPieL10n(AppLocalizations l10n) =>
      categoryBreakdown.map(
        (k, v) => MapEntry(
            k.isEmpty ? l10n.statsCategoryGeneral : k, v.toDouble()),
      );

  Map<String, double> engagementPieL10n(AppLocalizations l10n) {
    final m = <String, double>{};
    if (created > 0) m[l10n.statsNewLabel] = created.toDouble();
    if (updated > 0) m[l10n.statsUpdatedLabel] = updated.toDouble();
    if (favorites > 0) m[l10n.statsFavoriteLabel] = favorites.toDouble();
    if (pinned > 0) m[l10n.statsPinnedLabel] = pinned.toDouble();
    return m;
  }

  List<StatMetric> metricsL10n(AppLocalizations l10n) => [
        StatMetric(label: l10n.statsCreatedLabel, value: '$created'),
        StatMetric(label: l10n.statsUpdatedLabel, value: '$updated'),
        StatMetric(
            label: l10n.statsFavoriteLabel,
            value: '$favorites',
            accent: Colors.pink),
        StatMetric(label: l10n.statsPinnedLabel, value: '$pinned'),
        StatMetric(label: l10n.statsArchivedLabel, value: '$archived'),
        StatMetric(label: l10n.statsTaskLinked, value: '$withTasks'),
        StatMetric(label: l10n.statsTeamNote, value: '$teamNotes'),
      ];
}

extension AppointmentsPeriodStatsL10n on AppointmentsPeriodStats {
  Map<String, double> statusPieL10n(AppLocalizations l10n) {
    final m = <String, double>{};
    if (completed > 0) m[l10n.statsCompleted] = completed.toDouble();
    if (pending > 0) m[l10n.statsPendingLabel] = pending.toDouble();
    if (cancelled > 0) m[l10n.statsCancelled] = cancelled.toDouble();
    return m;
  }

  Map<String, double> countBarL10n(AppLocalizations l10n) => {
        if (scheduled > 0) l10n.statsScheduled: scheduled.toDouble(),
        if (completed > 0) l10n.statsCompleted: completed.toDouble(),
        if (pending > 0) l10n.statsPendingLabel: pending.toDouble(),
        if (cancelled > 0) l10n.statsCancelled: cancelled.toDouble(),
      };

  List<StatMetric> metricsL10n(AppLocalizations l10n) => [
        StatMetric(label: l10n.statsScheduled, value: '$scheduled'),
        StatMetric(
            label: l10n.statsCompleted,
            value: '$completed',
            accent: Colors.green),
        StatMetric(
            label: l10n.statsCancelled,
            value: '$cancelled',
            accent: Colors.red),
        StatMetric(
            label: l10n.statsPendingLabel,
            value: '$pending',
            accent: Colors.orange),
        StatMetric(
          label: l10n.statsIncomeLabel,
          value: '₺${totalRevenue.toStringAsFixed(0)}',
        ),
        StatMetric(
          label: l10n.statsFocusDuration,
          value: '${(totalMinutes / 60).toStringAsFixed(1)} h',
        ),
        StatMetric(
          label: l10n.statsAvgDuration,
          value: l10n.statsMinutesShort(avgDuration.round()),
        ),
      ];
}

extension MedicationsPeriodStatsL10n on MedicationsPeriodStats {
  Map<String, double> stockPieL10n(AppLocalizations l10n) {
    final m = <String, double>{};
    if (normalStock > 0) {
      m[l10n.statsSufficientStock] = normalStock.toDouble();
    }
    if (lowStock > 0) m[l10n.statsLowStock] = lowStock.toDouble();
    return m;
  }

  Map<String, double> adherencePieL10n(AppLocalizations l10n) {
    final missed = (dosesScheduled - dosesTaken).clamp(0, dosesScheduled);
    return {
      if (dosesTaken > 0) l10n.statsTaken: dosesTaken.toDouble(),
      if (missed > 0) l10n.statsMissed: missed.toDouble(),
    };
  }

  List<StatMetric> metricsL10n(AppLocalizations l10n) => [
        StatMetric(label: l10n.statsActiveMeds, value: '$activeMeds'),
        StatMetric(label: l10n.statsDosesScheduled, value: '$dosesScheduled'),
        StatMetric(
          label: l10n.statsDosesTaken,
          value: '$dosesTaken',
          accent: Colors.green,
        ),
        StatMetric(
          label: l10n.statsAdherence,
          value: '%${adherenceRate.toStringAsFixed(0)}',
        ),
        if (lowStock > 0)
          StatMetric(
            label: l10n.statsLowStock,
            value: '$lowStock',
            accent: Colors.red,
          ),
      ];
}

extension BooksPeriodStatsL10n on BooksPeriodStats {
  List<StatMetric> metricsL10n(AppLocalizations l10n) => [
        StatMetric(label: l10n.statsInLibrary, value: '$total'),
        StatMetric(label: l10n.statsBookReading, value: '$reading'),
        StatMetric(
          label: l10n.statsFinishedInPeriod,
          value: '$finishedInPeriod',
          accent: Colors.green,
        ),
        StatMetric(
            label: l10n.statsStartedInPeriod, value: '$startedInPeriod'),
        StatMetric(label: l10n.statsPagesRead, value: '$pagesRead'),
        StatMetric(
          label: l10n.statsAvgRating,
          value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '-',
        ),
      ];
}

extension TeamsPeriodStatsL10n on TeamsPeriodStats {
  List<StatMetric> metricsL10n(AppLocalizations l10n) => [
        StatMetric(label: l10n.statsTeamCount, value: '$teamCount'),
        StatMetric(label: l10n.statsTotalMembers, value: '$totalMembers'),
        StatMetric(label: l10n.statsOwnedTeams, value: '$ownedTeams'),
      ];
}

extension CorkboardPeriodStatsL10n on CorkboardPeriodStats {
  Map<String, double> compositionPieL10n(AppLocalizations l10n) => {
        if (notes > 0) l10n.statsCardsLabel: notes.toDouble(),
        if (connections > 0) l10n.statsLinksLabel: connections.toDouble(),
      };

  List<StatMetric> metricsL10n(AppLocalizations l10n) => [
        StatMetric(label: l10n.statsTotalCards, value: '$notes'),
        StatMetric(label: l10n.statsConnections, value: '$connections'),
        StatMetric(label: l10n.statsAddedInPeriod, value: '$notesInPeriod'),
      ];
}

extension StatisticsSnapshotL10n on StatisticsSnapshot {
  List<({String label, double score, Color color, String hint})>
      moduleScoresL10n(AppLocalizations l10n) => [
        (
          label: l10n.statsModuleTasks,
          score: tasks.productivityScore,
          color: Colors.blue,
          hint: l10n.statsModuleTaskHint,
        ),
        (
          label: l10n.statsModuleHabits,
          score: habits.periodCompletionRate,
          color: const Color(0xFF22C55E),
          hint: l10n.statsModuleHabitHint,
        ),
        (
          label: l10n.statsModuleBudget,
          score: budget.net >= 0 ? 72 : 38,
          color: const Color(0xFFF59E0B),
          hint: budget.net >= 0
              ? l10n.statsNetPositive
              : l10n.statsNetNegative,
        ),
        (
          label: l10n.statsModuleNotes,
          score: (notes.created * 8.0).clamp(0, 100),
          color: const Color(0xFF6366F1),
          hint: l10n.statsModuleNotesHint,
        ),
        (
          label: l10n.statsModuleAppointments,
          score: appointments.scheduled == 0
              ? 0
              : (appointments.completed / appointments.scheduled * 100)
                  .clamp(0, 100),
          color: const Color(0xFF06B6D4),
          hint: l10n.statsModuleApptHint,
        ),
        (
          label: l10n.statsModuleMedications,
          score: medications.adherenceRate,
          color: const Color(0xFFEC4899),
          hint: l10n.statsModuleMedHint,
        ),
        (
          label: l10n.statsModuleBooks,
          score: books.total == 0
              ? 0
              : (books.finishedInPeriod / books.total * 100).clamp(0, 100),
          color: const Color(0xFF8B5CF6),
          hint: l10n.statsModuleBookHint,
        ),
      ];
}
