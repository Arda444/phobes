import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Time window for all module statistics.
enum StatsPeriod {
  day,
  week,
  month,
  quarter,
}

extension StatsPeriodX on StatsPeriod {
  String get label {
    switch (this) {
      case StatsPeriod.day:
        return 'Günlük';
      case StatsPeriod.week:
        return 'Haftalık';
      case StatsPeriod.month:
        return 'Aylık';
      case StatsPeriod.quarter:
        return '3 Aylık';
    }
  }

  String get shortLabel {
    switch (this) {
      case StatsPeriod.day:
        return 'Bugün';
      case StatsPeriod.week:
        return '7 gün';
      case StatsPeriod.month:
        return '30 gün';
      case StatsPeriod.quarter:
        return '90 gün';
    }
  }

  int get days {
    switch (this) {
      case StatsPeriod.day:
        return 1;
      case StatsPeriod.week:
        return 7;
      case StatsPeriod.month:
        return 30;
      case StatsPeriod.quarter:
        return 90;
    }
  }

  DateTime get start {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case StatsPeriod.day:
        return today;
      case StatsPeriod.week:
        return today.subtract(const Duration(days: 6));
      case StatsPeriod.month:
        return today.subtract(const Duration(days: 29));
      case StatsPeriod.quarter:
        return today.subtract(const Duration(days: 89));
    }
  }

  bool contains(DateTime dt) {
    final end = DateTime.now().add(const Duration(minutes: 1));
    return !dt.isBefore(start) && !dt.isAfter(end);
  }
}

/// Single metric row for module detail panels.
class StatMetric {
  final String label;
  final String value;
  final String? hint;
  final Color? accent;

  const StatMetric({
    required this.label,
    required this.value,
    this.hint,
    this.accent,
  });
}

class TaskPeriodStats {
  final int created;
  final int completed;
  final int pending;
  final int overdue;
  final int postponed;
  final double completionRate;
  final int streakDays;
  final int focusMinutes;
  final double avgDurationMinutes;
  final String busiestDay;
  final String peakTimeSlot;
  final double productivityScore;
  final Map<String, double> tagDistribution;
  final Map<int, int> priorityBreakdown;
  final Map<int, int> hourlyBreakdown;
  final Map<DateTime, int> heatMap;
  final List<FlSpot> dailyTrend;
  final List<double> bucketTrend;
  final int withSubtasks;
  final int recurring;
  final Map<String, double> timeSlotBreakdown;
  final Map<int, double> weekdayBreakdown;

  const TaskPeriodStats({
    this.created = 0,
    this.completed = 0,
    this.pending = 0,
    this.overdue = 0,
    this.postponed = 0,
    this.completionRate = 0,
    this.streakDays = 0,
    this.focusMinutes = 0,
    this.avgDurationMinutes = 0,
    this.busiestDay = '-',
    this.peakTimeSlot = '-',
    this.productivityScore = 0,
    this.tagDistribution = const {},
    this.priorityBreakdown = const {},
    this.hourlyBreakdown = const {},
    this.heatMap = const {},
    this.dailyTrend = const [],
    this.bucketTrend = const [],
    this.withSubtasks = 0,
    this.recurring = 0,
    this.timeSlotBreakdown = const {},
    this.weekdayBreakdown = const {},
  });

  Map<String, double> get timeSlotPie => timeSlotBreakdown;

  Map<String, double> get weekdayPie => weekdayBreakdown.map(
        (k, v) => MapEntry(_weekdayLabel(k), v),
      );

  static String _weekdayLabel(int weekday) {
    const days = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    if (weekday >= 1 && weekday <= 7) return days[weekday];
    return '?';
  }

  Map<String, double> get priorityPie => priorityBreakdown.map(
        (k, v) => MapEntry(
          k >= 3
              ? 'Yüksek'
              : k == 2
                  ? 'Orta'
                  : 'Düşük',
          v.toDouble(),
        ),
      );

  Map<String, double> get statusPie => {
        if (completed > 0) 'Tamamlanan': completed.toDouble(),
        if (pending > 0) 'Bekleyen': pending.toDouble(),
        if (overdue > 0) 'Geciken': overdue.toDouble(),
      };

  List<StatMetric> get primaryMetrics => [
        StatMetric(label: 'Tamamlanan', value: '$completed', accent: Colors.green),
        StatMetric(label: 'Bekleyen', value: '$pending', accent: Colors.orange),
        StatMetric(
          label: 'Tamamlanma',
          value: '%${completionRate.toStringAsFixed(0)}',
          accent: Colors.blue,
        ),
        StatMetric(label: 'Seri', value: '$streakDays gün', accent: Colors.deepOrange),
        StatMetric(label: 'Geciken', value: '$overdue', accent: Colors.red),
        StatMetric(label: 'Odak süresi', value: _fmtMinutes(focusMinutes)),
        StatMetric(
          label: 'Verimlilik',
          value: '${productivityScore.toStringAsFixed(0)}/100',
        ),
        StatMetric(label: 'Oluşturulan', value: '$created'),
        StatMetric(label: 'Erteleme', value: '$postponed'),
        StatMetric(
          label: 'Ort. süre',
          value: '${avgDurationMinutes.toStringAsFixed(0)} dk',
        ),
        StatMetric(label: 'Yoğun gün', value: busiestDay),
        StatMetric(label: 'Yoğun saat', value: peakTimeSlot),
        StatMetric(label: 'Alt görevli', value: '$withSubtasks'),
        StatMetric(label: 'Tekrarlayan', value: '$recurring'),
      ];

  static String _fmtMinutes(int m) {
    if (m < 60) return '$m dk';
    return '${m ~/ 60} sa ${m % 60} dk';
  }
}

class HabitPeriodStats {
  final int totalHabits;
  final int completedInPeriod;
  final int maxStreak;
  final double periodCompletionRate;
  final int activeToday;
  final Map<String, double> activityBreakdown;

  const HabitPeriodStats({
    this.totalHabits = 0,
    this.completedInPeriod = 0,
    this.maxStreak = 0,
    this.periodCompletionRate = 0,
    this.activeToday = 0,
    this.activityBreakdown = const {},
  });

  Map<String, double> get activityPie => activityBreakdown;

  Map<String, double> get completionPie => {
        'Tamamlanan': periodCompletionRate,
        if (periodCompletionRate < 100)
          'Eksik': 100 - periodCompletionRate,
      };

  List<StatMetric> get metrics => [
        StatMetric(label: 'Toplam alışkanlık', value: '$totalHabits'),
        StatMetric(
          label: 'Dönemde tamamlanan',
          value: '$completedInPeriod',
          accent: Colors.green,
        ),
        StatMetric(
          label: 'Dönem uyumu',
          value: '%${periodCompletionRate.toStringAsFixed(0)}',
        ),
        StatMetric(label: 'En uzun seri', value: '$maxStreak gün'),
        StatMetric(label: 'Bugün aktif', value: '$activeToday'),
      ];
}

class BudgetPeriodStats {
  final double totalIncome;
  final double totalExpense;
  final double net;
  final int transactionCount;
  final int incomeCount;
  final int expenseCount;
  final double totalBalance;
  final int accountCount;
  final String topCategory;
  final double topCategoryAmount;
  final Map<String, double> categoryBreakdown;
  final List<FlSpot> dailyExpenseTrend;
  final List<FlSpot> dailyIncomeTrend;

  const BudgetPeriodStats({
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.net = 0,
    this.transactionCount = 0,
    this.incomeCount = 0,
    this.expenseCount = 0,
    this.totalBalance = 0,
    this.accountCount = 0,
    this.topCategory = '-',
    this.topCategoryAmount = 0,
    this.categoryBreakdown = const {},
    this.dailyExpenseTrend = const [],
    this.dailyIncomeTrend = const [],
  });

  Map<String, double> get transactionCountPie {
    final m = <String, double>{};
    if (incomeCount > 0) m['Gelir işlemi'] = incomeCount.toDouble();
    if (expenseCount > 0) m['Gider işlemi'] = expenseCount.toDouble();
    return m;
  }

  Map<String, double> get incomeExpensePie {
    final m = <String, double>{};
    if (totalIncome > 0) m['Gelir'] = totalIncome;
    if (totalExpense > 0) m['Gider'] = totalExpense;
    return m;
  }

  List<StatMetric> get metrics => [
        StatMetric(
          label: 'Gelir',
          value: '₺${totalIncome.toStringAsFixed(0)}',
          accent: Colors.green,
        ),
        StatMetric(
          label: 'Gider',
          value: '₺${totalExpense.toStringAsFixed(0)}',
          accent: Colors.red,
        ),
        StatMetric(
          label: 'Net',
          value: '₺${net.toStringAsFixed(0)}',
          accent: net >= 0 ? Colors.green : Colors.red,
        ),
        StatMetric(label: 'İşlem sayısı', value: '$transactionCount'),
        StatMetric(label: 'Gelir işlemi', value: '$incomeCount'),
        StatMetric(label: 'Gider işlemi', value: '$expenseCount'),
        StatMetric(
          label: 'Toplam bakiye',
          value: '₺${totalBalance.toStringAsFixed(0)}',
        ),
        StatMetric(label: 'Hesap', value: '$accountCount'),
        StatMetric(
          label: 'En çok harcama',
          value: topCategory == '-' ? '-' : '$topCategory (₺${topCategoryAmount.toStringAsFixed(0)})',
        ),
      ];
}

class NotesPeriodStats {
  final int created;
  final int updated;
  final int favorites;
  final int pinned;
  final int archived;
  final int withTasks;
  final int teamNotes;
  final Map<String, int> categoryBreakdown;

  const NotesPeriodStats({
    this.created = 0,
    this.updated = 0,
    this.favorites = 0,
    this.pinned = 0,
    this.archived = 0,
    this.withTasks = 0,
    this.teamNotes = 0,
    this.categoryBreakdown = const {},
  });

  Map<String, double> get categoryPie => categoryBreakdown.map(
        (k, v) => MapEntry(k.isEmpty ? 'Genel' : k, v.toDouble()),
      );

  Map<String, double> get engagementPie {
    final m = <String, double>{};
    if (created > 0) m['Yeni'] = created.toDouble();
    if (updated > 0) m['Güncellenen'] = updated.toDouble();
    if (favorites > 0) m['Favori'] = favorites.toDouble();
    if (pinned > 0) m['Sabit'] = pinned.toDouble();
    return m;
  }

  List<StatMetric> get metrics => [
        StatMetric(label: 'Oluşturulan', value: '$created'),
        StatMetric(label: 'Güncellenen', value: '$updated'),
        StatMetric(label: 'Favori', value: '$favorites', accent: Colors.pink),
        StatMetric(label: 'Sabitlenmiş', value: '$pinned'),
        StatMetric(label: 'Arşiv', value: '$archived'),
        StatMetric(label: 'Görev bağlantılı', value: '$withTasks'),
        StatMetric(label: 'Ekip notu', value: '$teamNotes'),
      ];
}

class AppointmentsPeriodStats {
  final int scheduled;
  final int completed;
  final int cancelled;
  final int pending;
  final double totalRevenue;
  final int totalMinutes;
  final double avgDuration;

  const AppointmentsPeriodStats({
    this.scheduled = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.pending = 0,
    this.totalRevenue = 0,
    this.totalMinutes = 0,
    this.avgDuration = 0,
  });

  Map<String, double> get statusPie {
    final m = <String, double>{};
    if (completed > 0) m['Tamamlanan'] = completed.toDouble();
    if (pending > 0) m['Bekleyen'] = pending.toDouble();
    if (cancelled > 0) m['İptal'] = cancelled.toDouble();
    return m;
  }

  Map<String, double> get countBar => {
        if (scheduled > 0) 'Planlanan': scheduled.toDouble(),
        if (completed > 0) 'Tamamlanan': completed.toDouble(),
        if (pending > 0) 'Bekleyen': pending.toDouble(),
        if (cancelled > 0) 'İptal': cancelled.toDouble(),
      };

  List<StatMetric> get metrics => [
        StatMetric(label: 'Planlanan', value: '$scheduled'),
        StatMetric(label: 'Tamamlanan', value: '$completed', accent: Colors.green),
        StatMetric(label: 'İptal', value: '$cancelled', accent: Colors.red),
        StatMetric(label: 'Bekleyen', value: '$pending', accent: Colors.orange),
        StatMetric(
          label: 'Gelir',
          value: '₺${totalRevenue.toStringAsFixed(0)}',
        ),
        StatMetric(label: 'Toplam süre', value: '${(totalMinutes / 60).toStringAsFixed(1)} sa'),
        StatMetric(
          label: 'Ort. süre',
          value: '${avgDuration.toStringAsFixed(0)} dk',
        ),
      ];
}

class MedicationsPeriodStats {
  final int activeMeds;
  final int dosesScheduled;
  final int dosesTaken;
  final double adherenceRate;
  final int lowStock;
  final int normalStock;

  const MedicationsPeriodStats({
    this.activeMeds = 0,
    this.dosesScheduled = 0,
    this.dosesTaken = 0,
    this.adherenceRate = 0,
    this.lowStock = 0,
    this.normalStock = 0,
  });

  Map<String, double> get stockPie {
    final m = <String, double>{};
    if (normalStock > 0) m['Yeterli stok'] = normalStock.toDouble();
    if (lowStock > 0) m['Düşük stok'] = lowStock.toDouble();
    return m;
  }

  Map<String, double> get adherencePie {
    final missed = (dosesScheduled - dosesTaken).clamp(0, dosesScheduled);
    return {
      if (dosesTaken > 0) 'Alınan': dosesTaken.toDouble(),
      if (missed > 0) 'Kaçırılan': missed.toDouble(),
    };
  }

  List<StatMetric> get metrics => [
        StatMetric(label: 'Aktif ilaç', value: '$activeMeds'),
        StatMetric(label: 'Planlanan doz', value: '$dosesScheduled'),
        StatMetric(
          label: 'Alınan doz',
          value: '$dosesTaken',
          accent: Colors.green,
        ),
        StatMetric(
          label: 'Uyum',
          value: '%${adherenceRate.toStringAsFixed(0)}',
        ),
        if (lowStock > 0)
          StatMetric(
            label: 'Düşük stok',
            value: '$lowStock',
            accent: Colors.red,
          ),
      ];
}

class BooksPeriodStats {
  final int total;
  final int reading;
  final int finishedInPeriod;
  final int startedInPeriod;
  final int pagesRead;
  final double avgRating;
  final Map<String, double> statusBreakdown;

  const BooksPeriodStats({
    this.total = 0,
    this.reading = 0,
    this.finishedInPeriod = 0,
    this.startedInPeriod = 0,
    this.pagesRead = 0,
    this.avgRating = 0,
    this.statusBreakdown = const {},
  });

  List<StatMetric> get metrics => [
        StatMetric(label: 'Kütüphanede', value: '$total'),
        StatMetric(label: 'Okunuyor', value: '$reading'),
        StatMetric(
          label: 'Dönemde biten',
          value: '$finishedInPeriod',
          accent: Colors.green,
        ),
        StatMetric(label: 'Dönemde başlanan', value: '$startedInPeriod'),
        StatMetric(label: 'Okunan sayfa', value: '$pagesRead'),
        StatMetric(
          label: 'Ort. puan',
          value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '-',
        ),
      ];
}

class TeamsPeriodStats {
  final int teamCount;
  final int totalMembers;
  final int ownedTeams;
  final Map<String, double> memberByTeam;

  const TeamsPeriodStats({
    this.teamCount = 0,
    this.totalMembers = 0,
    this.ownedTeams = 0,
    this.memberByTeam = const {},
  });

  List<StatMetric> get metrics => [
        StatMetric(label: 'Ekip sayısı', value: '$teamCount'),
        StatMetric(label: 'Toplam üye', value: '$totalMembers'),
        StatMetric(label: 'Yönettiğim', value: '$ownedTeams'),
      ];
}

class CorkboardPeriodStats {
  final int notes;
  final int connections;
  final int notesInPeriod;
  final Map<String, double> typeBreakdown;

  const CorkboardPeriodStats({
    this.notes = 0,
    this.connections = 0,
    this.notesInPeriod = 0,
    this.typeBreakdown = const {},
  });

  Map<String, double> get typePie => typeBreakdown;

  Map<String, double> get compositionPie => {
        if (notes > 0) 'Kartlar': notes.toDouble(),
        if (connections > 0) 'Bağlantılar': connections.toDouble(),
      };

  List<StatMetric> get metrics => [
        StatMetric(label: 'Toplam kart', value: '$notes'),
        StatMetric(label: 'Bağlantı', value: '$connections'),
        StatMetric(label: 'Dönemde eklenen', value: '$notesInPeriod'),
      ];
}

/// Full snapshot for one selected period.
class StatisticsSnapshot {
  final StatsPeriod period;
  final DateTime computedAt;
  final int globalActivityScore;
  final TaskPeriodStats tasks;
  final HabitPeriodStats habits;
  final BudgetPeriodStats budget;
  final NotesPeriodStats notes;
  final AppointmentsPeriodStats appointments;
  final MedicationsPeriodStats medications;
  final BooksPeriodStats books;
  final TeamsPeriodStats teams;
  final CorkboardPeriodStats corkboard;

  const StatisticsSnapshot({
    required this.period,
    required this.computedAt,
    this.globalActivityScore = 0,
    this.tasks = const TaskPeriodStats(),
    this.habits = const HabitPeriodStats(),
    this.budget = const BudgetPeriodStats(),
    this.notes = const NotesPeriodStats(),
    this.appointments = const AppointmentsPeriodStats(),
    this.medications = const MedicationsPeriodStats(),
    this.books = const BooksPeriodStats(),
    this.teams = const TeamsPeriodStats(),
    this.corkboard = const CorkboardPeriodStats(),
  });

  int get totalActions =>
      tasks.completed +
      habits.completedInPeriod +
      notes.created +
      appointments.completed +
      medications.dosesTaken +
      books.finishedInPeriod;

  /// Normalized 0–100 scores per module for overview bar chart.
  List<({String label, double score, Color color, String hint})>
      get moduleScores => [
        (
          label: 'Görev',
          score: tasks.productivityScore,
          color: Colors.blue,
          hint: 'Tamamlama + seri + hacim',
        ),
        (
          label: 'Alışkanlık',
          score: habits.periodCompletionRate,
          color: const Color(0xFF22C55E),
          hint: 'Günlük uyum oranı',
        ),
        (
          label: 'Bütçe',
          score: budget.net >= 0 ? 72 : 38,
          color: const Color(0xFFF59E0B),
          hint: budget.net >= 0 ? 'Net pozitif' : 'Net negatif',
        ),
        (
          label: 'Not',
          score: (notes.created * 8.0).clamp(0, 100),
          color: const Color(0xFF6366F1),
          hint: 'Dönemde oluşturulan',
        ),
        (
          label: 'Randevu',
          score: appointments.scheduled == 0
              ? 0
              : (appointments.completed / appointments.scheduled * 100)
                  .clamp(0, 100),
          color: const Color(0xFF06B6D4),
          hint: 'Tamamlanan / planlanan',
        ),
        (
          label: 'İlaç',
          score: medications.adherenceRate,
          color: const Color(0xFFEC4899),
          hint: 'Doz uyumu',
        ),
        (
          label: 'Kitap',
          score: books.total == 0
              ? 0
              : (books.finishedInPeriod / books.total * 100).clamp(0, 100),
          color: const Color(0xFF8B5CF6),
          hint: 'Biten / kütüphane',
        ),
      ];
}
