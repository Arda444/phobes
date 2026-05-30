import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/appointment_model.dart';
import '../models/book_model.dart';
import '../models/budget_model.dart';
import '../models/corkboard_connection_model.dart';
import '../models/corkboard_item_model.dart';
import '../models/medication_model.dart';
import '../models/note_model.dart';
import '../models/statistics_models.dart';
import '../models/task_model.dart';
import '../models/team_model.dart';
import 'book_service.dart';
import 'budget_account_service.dart';
import 'budget_service.dart';
import 'corkboard_service.dart';
import 'firebase_service.dart';

/// Loads raw data once and computes per-period statistics for all modules.
class StatisticsAggregator {
  StatisticsAggregator._();
  static final StatisticsAggregator instance = StatisticsAggregator._();

  final FirebaseService _fb = FirebaseService();
  final BudgetService _budget = BudgetService();
  final BudgetAccountService _accounts = BudgetAccountService();
  final BookService _books = BookService();
  final CorkboardService _corkboard = CorkboardService();

  List<Task>? _tasksCache;
  List<QueryDocumentSnapshot>? _habitDocsCache;
  List<BudgetTransaction>? _txCache;
  List<Account>? _accountsCache;
  List<Note>? _notesCache;
  List<Appointment>? _apptsCache;
  List<Medication>? _medsCache;
  List<UserBook>? _booksCache;
  List<Team>? _teamsCache;
  List<CorkboardItem>? _corkItemsCache;
  List<CorkboardConnection>? _corkConnsCache;

  Future<void> loadAll({void Function(String)? onProgress}) async {
    onProgress?.call('Veriler yükleniyor…');
    final results = await Future.wait([
      _loadTasks(),
      _loadHabits(),
      _loadBudget(),
      _loadNotes(),
      _loadAppointments(),
      _loadMedications(),
      _loadBooks(),
      _loadTeams(),
      _loadCorkboard(),
    ]);
    _tasksCache = results[0] as List<Task>;
    _habitDocsCache = results[1] as List<QueryDocumentSnapshot>;
    _txCache = (results[2] as _BudgetBundle).transactions;
    _accountsCache = (results[2] as _BudgetBundle).accounts;
    _notesCache = results[3] as List<Note>;
    _apptsCache = results[4] as List<Appointment>;
    _medsCache = results[5] as List<Medication>;
    _booksCache = results[6] as List<UserBook>;
    _teamsCache = results[7] as List<Team>;
    final cork = results[8] as _CorkBundle;
    _corkItemsCache = cork.items;
    _corkConnsCache = cork.connections;
    onProgress?.call('Analiz hazır');
  }

  void clearCache() {
    _tasksCache = null;
    _habitDocsCache = null;
    _txCache = null;
    _accountsCache = null;
    _notesCache = null;
    _apptsCache = null;
    _medsCache = null;
    _booksCache = null;
    _teamsCache = null;
    _corkItemsCache = null;
    _corkConnsCache = null;
  }

  StatisticsSnapshot compute(StatsPeriod period) {
    final now = DateTime.now();
    return StatisticsSnapshot(
      period: period,
      computedAt: now,
      globalActivityScore: _globalScore(period),
      tasks: _computeTasks(period),
      habits: _computeHabits(period),
      budget: _computeBudget(period),
      notes: _computeNotes(period),
      appointments: _computeAppointments(period),
      medications: _computeMedications(period),
      books: _computeBooks(period),
      teams: _computeTeams(),
      corkboard: _computeCorkboard(period),
    );
  }

  Future<List<Task>> _loadTasks() async {
    try {
      return await _fb.getTasksForStats();
    } catch (_) {
      return await _fb.getAllUserTasksStream().first;
    }
  }

  Future<List<QueryDocumentSnapshot>> _loadHabits() async {
    final snap = await _fb.getHabitsStream().first;
    return snap.docs;
  }

  Future<_BudgetBundle> _loadBudget() async {
    final tx = await _budget.getTransactionsStream().first;
    final acc = await _accounts.getAccountsStream().first;
    return _BudgetBundle(tx, acc);
  }

  Future<List<Note>> _loadNotes() async =>
      _fb.getNotesStream().first;

  Future<List<Appointment>> _loadAppointments() async =>
      _fb.getAppointmentsStream().first;

  Future<List<Medication>> _loadMedications() async =>
      _fb.getMedicationsStream().first;

  Future<List<UserBook>> _loadBooks() async =>
      _books.getBooksStream().first;

  Future<List<Team>> _loadTeams() async =>
      _fb.getUserTeamsStream().first;

  Future<_CorkBundle> _loadCorkboard() async {
    final items = await _corkboard.getItemsStream().first;
    final conns = await _corkboard.getConnectionsStream().first;
    return _CorkBundle(items, conns);
  }

  int _globalScore(StatsPeriod period) {
    final t = _computeTasks(period);
    final h = _computeHabits(period);
    final n = _computeNotes(period);
    final a = _computeAppointments(period);
    final m = _computeMedications(period);
    final raw = t.productivityScore * 0.35 +
        h.periodCompletionRate * 0.2 +
        m.adherenceRate * 0.15 +
        (n.created * 2).clamp(0, 20).toDouble() +
        (a.completed * 3).clamp(0, 25).toDouble();
    return raw.clamp(0, 100).round();
  }

  TaskPeriodStats _computeTasks(StatsPeriod period) {
    final tasks = _tasksCache ?? [];
    if (tasks.isEmpty) return const TaskPeriodStats();

    final expanded = _expandTasksForAnalysis(tasks, period);
    final inPeriod = expanded
        .where((t) => period.contains(t.startTime))
        .toList();
    final now = DateTime.now();

    final completed = inPeriod.where((t) => t.isCompleted).toList();
    final pending = inPeriod
        .where((t) => !t.isCompleted && !t.startTime.isAfter(now))
        .toList();
    final overdue = pending
        .where((t) => t.endTime.isBefore(now) && !t.isAllDay)
        .length;

    final completionRate = inPeriod.isEmpty
        ? 0.0
        : (completed.length / inPeriod.length) * 100;

    int focusMinutes = 0;
    final hourly = {for (var i = 0; i < 24; i++) i: 0};
    final weekday = {for (var i = 1; i <= 7; i++) i: 0};
    final timeSlots = {'Sabah': 0, 'Öğle': 0, 'Akşam': 0, 'Gece': 0};

    for (final t in completed) {
      final dur =
          t.isAllDay ? 60 : t.endTime.difference(t.startTime).inMinutes.abs();
      focusMinutes += dur;
      weekday[t.startTime.weekday] = (weekday[t.startTime.weekday] ?? 0) + 1;
      if (!t.isAllDay) {
        final h = t.startTime.hour;
        hourly[h] = (hourly[h] ?? 0) + 1;
        if (h >= 5 && h < 12) {
          timeSlots['Sabah'] = (timeSlots['Sabah'] ?? 0) + 1;
        } else if (h >= 12 && h < 17) {
          timeSlots['Öğle'] = (timeSlots['Öğle'] ?? 0) + 1;
        } else if (h >= 17 && h < 22) {
          timeSlots['Akşam'] = (timeSlots['Akşam'] ?? 0) + 1;
        } else {
          timeSlots['Gece'] = (timeSlots['Gece'] ?? 0) + 1;
        }
      }
    }

    final today = DateTime(now.year, now.month, now.day);
    final completionDays = {
      for (final t in completed) DateUtils.dateOnly(t.startTime): true,
    };
    var streak = 0;
    for (var i = 0; i < 365; i++) {
      if (completionDays.containsKey(today.subtract(Duration(days: i)))) {
        streak++;
      } else if (i == 0 && !completionDays.containsKey(today)) {
        continue;
      } else {
        break;
      }
    }

    final tagCount = <String, double>{};
    for (final t in completed) {
      if (t.tags.isEmpty) {
        tagCount['Genel'] = (tagCount['Genel'] ?? 0) + 1;
      } else {
        for (final tag in t.tags) {
          if (tag.isNotEmpty) tagCount[tag] = (tagCount[tag] ?? 0) + 1;
        }
      }
    }
    final tagDist = <String, double>{};
    final tagTotal = tagCount.values.fold<double>(0, (a, b) => a + b);
    if (tagTotal > 0) {
      tagCount.forEach((k, v) => tagDist[k] = (v / tagTotal) * 100);
    }

    final priority = {0: 0, 1: 0, 2: 0};
    for (final t in completed) {
      priority[t.priority] = (priority[t.priority] ?? 0) + 1;
    }

    final heatMap = <DateTime, int>{};
    for (final t in completed) {
      final d = DateUtils.dateOnly(t.startTime);
      heatMap[d] = (heatMap[d] ?? 0) + 1;
    }

    final days = period.days.clamp(1, 90);
    final dailyTrend = <FlSpot>[];
    for (var i = days - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final c = completed
          .where((t) => DateUtils.isSameDay(t.startTime, d))
          .length;
      dailyTrend.add(FlSpot((days - 1 - i).toDouble(), c.toDouble()));
    }

    final bucketCount = period == StatsPeriod.quarter ? 12 : 4;
    final bucketTrend = List<double>.filled(bucketCount, 0);
    final span = period.days;
    for (final t in completed) {
      final diff = today.difference(DateUtils.dateOnly(t.startTime)).inDays;
      if (diff >= 0 && diff < span) {
        final idx =
            ((diff / span) * bucketCount).floor().clamp(0, bucketCount - 1);
        bucketTrend[bucketCount - 1 - idx]++;
      }
    }

    var score = completionRate * 0.5 +
        math.min(streak, 10) * 3 +
        math.min(completed.length, 50).toDouble();
    score = score.clamp(0, 100);
    if (score.isNaN) score = 0;

    String busiest = '-';
    if (completed.isNotEmpty) {
      final sorted = weekday.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (sorted.first.value > 0) busiest = _dayName(sorted.first.key);
    }

    String peak = '-';
    final sortedSlots = timeSlots.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sortedSlots.isNotEmpty && sortedSlots.first.value > 0) {
      peak = sortedSlots.first.key;
    }

    return TaskPeriodStats(
      created: inPeriod.length,
      completed: completed.length,
      pending: pending.length,
      overdue: overdue,
      postponed: inPeriod.where((t) => t.postponeCount > 0).length,
      completionRate: completionRate,
      streakDays: streak,
      focusMinutes: focusMinutes,
      avgDurationMinutes:
          completed.isEmpty ? 0 : focusMinutes / completed.length,
      busiestDay: busiest,
      peakTimeSlot: peak,
      productivityScore: score,
      tagDistribution: tagDist,
      priorityBreakdown: priority,
      hourlyBreakdown: hourly,
      heatMap: heatMap,
      dailyTrend: dailyTrend,
      bucketTrend: bucketTrend,
      withSubtasks: inPeriod.where((t) => t.subtasks.isNotEmpty).length,
      recurring: inPeriod.where((t) => t.repeatRule != 'none').length,
      timeSlotBreakdown: timeSlots.map(
        (k, v) => MapEntry(k, v.toDouble()),
      ),
      weekdayBreakdown: weekday.map((k, v) => MapEntry(k, v.toDouble())),
    );
  }

  List<Task> _expandTasksForAnalysis(List<Task> tasks, StatsPeriod period) {
    final end = DateTime.now().add(const Duration(days: 1));
    final start = period.start.subtract(const Duration(days: 30));
    final out = <Task>[];

    for (final task in tasks) {
      if (task.repeatRule == 'none') {
        if (!task.startTime.isAfter(end) && !task.startTime.isBefore(start)) {
          out.add(task);
        }
      } else {
        var next = task.startTime;
        var safety = 0;
        while (next.isBefore(end) && safety < 400) {
          safety++;
          if (!next.isBefore(start)) {
            out.add(task.copyWith(
              startTime: DateTime(next.year, next.month, next.day,
                  task.startTime.hour, task.startTime.minute),
              endTime: DateTime(next.year, next.month, next.day,
                  task.endTime.hour, task.endTime.minute),
            ));
          }
          if (task.repeatRule == 'daily') {
            next = next.add(const Duration(days: 1));
          } else if (task.repeatRule == 'weekly') {
            next = next.add(const Duration(days: 7));
          } else if (task.repeatRule == 'monthly') {
            var m = next.month + 1;
            var y = next.year;
            if (m > 12) {
              m = 1;
              y++;
            }
            final dim = DateUtils.getDaysInMonth(y, m);
            final day = task.startTime.day.clamp(1, dim);
            next = DateTime(y, m, day, task.startTime.hour, task.startTime.minute);
          } else {
            break;
          }
        }
      }
    }
    return out;
  }

  HabitPeriodStats _computeHabits(StatsPeriod period) {
    final docs = _habitDocsCache ?? [];
    if (docs.isEmpty) return const HabitPeriodStats();

    var completedInPeriod = 0;
    var maxStreak = 0;
    var activeToday = 0;
    final now = DateTime.now();
    final todayStr = _dateKey(now);

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final streak = (data['streak'] as num?)?.toInt() ?? 0;
      if (streak > maxStreak) maxStreak = streak;

      final last = data['lastCompleted'];
      if (last is Timestamp) {
        final d = last.toDate();
        if (period.contains(d)) completedInPeriod++;
        if (_dateKey(d) == todayStr) activeToday++;
      }
    }

    final possible = docs.length * period.days;
    final rate =
        possible == 0 ? 0.0 : (completedInPeriod / possible) * 100;
    final missed = (possible - completedInPeriod).clamp(0, possible);

    return HabitPeriodStats(
      totalHabits: docs.length,
      completedInPeriod: completedInPeriod,
      maxStreak: maxStreak,
      periodCompletionRate: rate.clamp(0, 100),
      activeToday: activeToday,
      activityBreakdown: {
        if (completedInPeriod > 0) 'Tamamlanan': completedInPeriod.toDouble(),
        if (missed > 0) 'Kaçırılan': missed.toDouble(),
        if (activeToday > 0) 'Bugün': activeToday.toDouble(),
      },
    );
  }

  BudgetPeriodStats _computeBudget(StatsPeriod period) {
    final txs = (_txCache ?? [])
        .where((t) => period.contains(t.date))
        .toList();
    final accounts = _accountsCache ?? [];

    var income = 0.0;
    var expense = 0.0;
    var incomeCount = 0;
    var expenseCount = 0;
    final catMap = <String, double>{};

    for (final t in txs) {
      if (t.type == TransactionType.income) {
        income += t.amount;
        incomeCount++;
      } else if (t.type == TransactionType.expense) {
        expense += t.amount;
        expenseCount++;
        catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
      }
    }

    var topCat = '-';
    var topAmt = 0.0;
    catMap.forEach((k, v) {
      if (v > topAmt) {
        topAmt = v;
        topCat = k;
      }
    });

    final balance = accounts.fold<double>(0, (s, a) => s + a.balance);

    final today = DateTime.now();
    final days = period.days.clamp(1, 90);
    final dailyExpense = <FlSpot>[];
    final dailyIncome = <FlSpot>[];
    for (var i = days - 1; i >= 0; i--) {
      final d = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      var exp = 0.0;
      var inc = 0.0;
      for (final t in txs) {
        if (!DateUtils.isSameDay(t.date, d)) continue;
        if (t.type == TransactionType.expense) {
          exp += t.amount;
        } else if (t.type == TransactionType.income) {
          inc += t.amount;
        }
      }
      final x = (days - 1 - i).toDouble();
      dailyExpense.add(FlSpot(x, exp));
      dailyIncome.add(FlSpot(x, inc));
    }

    return BudgetPeriodStats(
      totalIncome: income,
      totalExpense: expense,
      net: income - expense,
      transactionCount: txs.length,
      incomeCount: incomeCount,
      expenseCount: expenseCount,
      totalBalance: balance,
      accountCount: accounts.length,
      topCategory: topCat,
      topCategoryAmount: topAmt,
      categoryBreakdown: catMap,
      dailyExpenseTrend: dailyExpense,
      dailyIncomeTrend: dailyIncome,
    );
  }

  NotesPeriodStats _computeNotes(StatsPeriod period) {
    final all = (_notesCache ?? [])
        .where((n) => n.deletedAt == null)
        .toList();

    final created = all.where((n) => period.contains(n.date)).length;
    final updated = all
        .where((n) =>
            n.updatedAt != null && period.contains(n.updatedAt!))
        .length;

    final cats = <String, int>{};
    for (final n in all.where((n) => period.contains(n.date))) {
      cats[n.category] = (cats[n.category] ?? 0) + 1;
    }

    return NotesPeriodStats(
      created: created,
      updated: updated,
      favorites: all.where((n) => n.isFavorite).length,
      pinned: all.where((n) => n.isPinned).length,
      archived: all.where((n) => n.isArchived).length,
      withTasks: all.where((n) => n.linkedTaskIds.isNotEmpty).length,
      teamNotes: all.where((n) => n.teamId != null).length,
      categoryBreakdown: cats,
    );
  }

  AppointmentsPeriodStats _computeAppointments(StatsPeriod period) {
    final inPeriod = (_apptsCache ?? [])
        .where((a) => period.contains(a.date))
        .toList();

    final completed =
        inPeriod.where((a) => a.status == 'completed').toList();
    final cancelled =
        inPeriod.where((a) => a.status == 'cancelled').length;
    final pending = inPeriod
        .where((a) => a.status != 'completed' && a.status != 'cancelled')
        .length;

    final revenue = completed.fold<double>(0, (s, a) => s + a.price);
    final minutes =
        inPeriod.fold<int>(0, (s, a) => s + a.durationMinutes);

    return AppointmentsPeriodStats(
      scheduled: inPeriod.length,
      completed: completed.length,
      cancelled: cancelled,
      pending: pending,
      totalRevenue: revenue,
      totalMinutes: minutes,
      avgDuration:
          inPeriod.isEmpty ? 0 : minutes / inPeriod.length.toDouble(),
    );
  }

  MedicationsPeriodStats _computeMedications(StatsPeriod period) {
    final active = (_medsCache ?? []).where((m) => m.isActive).toList();
    if (active.isEmpty) return const MedicationsPeriodStats();

    var scheduled = 0;
    var taken = 0;
    final start = period.start;
    final end = DateTime.now();

    for (var d = start;
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      final key = _dateKey(d);
      for (final med in active) {
        scheduled += med.times.length;
        taken += med.takenHistory[key]?.length ?? 0;
      }
    }

    final low = active
        .where((m) => m.stockTracking && m.stock <= m.stockThreshold)
        .length;
    final tracked = active.where((m) => m.stockTracking).length;
    final normal = (tracked - low).clamp(0, tracked);

    return MedicationsPeriodStats(
      activeMeds: active.length,
      dosesScheduled: scheduled,
      dosesTaken: taken,
      adherenceRate: scheduled == 0 ? 0 : (taken / scheduled) * 100,
      lowStock: low,
      normalStock: normal,
    );
  }

  BooksPeriodStats _computeBooks(StatsPeriod period) {
    final books = _booksCache ?? [];
    if (books.isEmpty) return const BooksPeriodStats();

    final finished = books
        .where((b) =>
            b.finishDate != null && period.contains(b.finishDate!))
        .length;
    final started = books
        .where((b) =>
            b.startDate != null && period.contains(b.startDate!))
        .length;

    var pages = 0;
    var ratingSum = 0;
    var rated = 0;
    for (final b in books) {
      pages += b.currentPage;
      if (b.rating > 0) {
        ratingSum += b.rating;
        rated++;
      }
    }

    final statusMap = <String, double>{};
    for (final b in books) {
      final label = switch (b.status) {
        'reading' => 'Okunuyor',
        'read' => 'Okundu',
        'to_read' => 'Okunacak',
        _ => 'Diğer',
      };
      statusMap[label] = (statusMap[label] ?? 0) + 1;
    }

    return BooksPeriodStats(
      total: books.length,
      reading: books.where((b) => b.status == 'reading').length,
      finishedInPeriod: finished,
      startedInPeriod: started,
      pagesRead: pages,
      avgRating: rated == 0 ? 0 : ratingSum / rated,
      statusBreakdown: statusMap,
    );
  }

  TeamsPeriodStats _computeTeams() {
    final teams = _teamsCache ?? [];
    final uid = _fb.currentUserId;
    var members = 0;
    var owned = 0;
    final byTeam = <String, double>{};
    for (final t in teams) {
      members += t.memberIds.length;
      if (uid != null && t.ownerId == uid) owned++;
      final name = t.name.length > 14 ? '${t.name.substring(0, 12)}…' : t.name;
      byTeam[name] = t.memberIds.length.toDouble();
    }
    return TeamsPeriodStats(
      teamCount: teams.length,
      totalMembers: members,
      ownedTeams: owned,
      memberByTeam: byTeam,
    );
  }

  CorkboardPeriodStats _computeCorkboard(StatsPeriod period) {
    final items = _corkItemsCache ?? [];
    final conns = _corkConnsCache ?? [];
    final types = <String, double>{};
    for (final item in items) {
      final label = switch (item.type.name) {
        'note' => 'Not',
        'taskRef' => 'Görev',
        'noteRef' => 'Not ref',
        'image' => 'Görsel',
        'link' => 'Bağlantı',
        _ => 'Diğer',
      };
      types[label] = (types[label] ?? 0) + 1;
    }
    return CorkboardPeriodStats(
      notes: items.length,
      connections: conns.length,
      notesInPeriod:
          items.where((i) => period.contains(i.createdAt)).length,
      typeBreakdown: types,
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dayName(int weekday) {
    const days = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    if (weekday >= 1 && weekday <= 7) return days[weekday];
    return '-';
  }
}

class _BudgetBundle {
  final List<BudgetTransaction> transactions;
  final List<Account> accounts;
  _BudgetBundle(this.transactions, this.accounts);
}

class _CorkBundle {
  final List<CorkboardItem> items;
  final List<CorkboardConnection> connections;
  _CorkBundle(this.items, this.connections);
}
