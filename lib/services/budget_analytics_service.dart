import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/budget_analytics_pure.dart';
import '../core/budget_period_utils.dart';
import '../models/budget_model.dart';

/// Pure analytics: no mutations, only reads and computations.
/// Provides both async (Firestore) and local (pre-fetched list) variants.
class BudgetAnalyticsService {
  static final BudgetAnalyticsService _instance =
      BudgetAnalyticsService._internal();
  factory BudgetAnalyticsService() => _instance;
  BudgetAnalyticsService._internal();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Date helper ──────────────────────────────────────────────────────────────

  static DateTime monthOffset(DateTime base, int monthOffset) =>
      BudgetAnalyticsPure.monthOffset(base, monthOffset);

  // ── Async (Firestore) analytics ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMonthlyTrend(int months) async {
    if (_uid == null) return [];
    final now = DateTime.now();
    final startDate = monthOffset(now, -months + 1);

    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: _uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();
    final txs =
        snapshot.docs.map((d) => BudgetTransaction.fromFirestore(d)).toList();

    final trend = <Map<String, dynamic>>[];
    for (int i = 0; i < months; i++) {
      final monthDate = DateTime(startDate.year, startDate.month + i);
      final monthTxs = txs.where((tx) =>
          tx.date.year == monthDate.year && tx.date.month == monthDate.month,);
      double income = 0, expense = 0;
      for (final tx in monthTxs) {
        if (tx.type == TransactionType.income) income += tx.amount;
        if (tx.type == TransactionType.expense) expense += tx.amount;
      }
      trend.add({'month': monthDate, 'income': income, 'expense': expense});
    }
    return trend;
  }

  Future<Map<String, dynamic>> getBudgetVsActual() async {
    if (_uid == null) return {};
    final limits =
        await _db.collection('budget_limits').where('userId', isEqualTo: _uid).get();
    final txSnap = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: _uid)
        .where('type', isEqualTo: TransactionType.expense.name)
        .get();
    final txs = txSnap.docs.map((d) => BudgetTransaction.fromFirestore(d)).toList();

    final analysis = <Map<String, dynamic>>[];
    for (final doc in limits.docs) {
      final limit = BudgetLimit.fromFirestore(doc);
      final spent = BudgetPeriodUtils.spentInCategory(
        txs,
        limit.category,
        limit.period,
      );
      analysis.add({
        'category': limit.category,
        'limit': limit.limitAmount,
        'actual': spent,
        'performance': limit.limitAmount > 0 ? spent / limit.limitAmount : 0.0,
      });
    }
    return {'items': analysis};
  }

  Future<Map<String, double>> getRecurringAnalytics() async {
    if (_uid == null) return {};
    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: _uid)
        .where('type', isEqualTo: TransactionType.expense.name)
        .get();
    double recurringTotal = 0, oneTimeTotal = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num).toDouble();
      final isRecurring = data['recurrence'] != null && data['recurrence'] != 'none';
      if (isRecurring) { recurringTotal += amount; }
      else { oneTimeTotal += amount; }
    }
    return {'recurring': recurringTotal, 'oneTime': oneTimeTotal};
  }

  Future<Map<String, double>> getCategoryBalanceData() async {
    if (_uid == null) return {};
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month);
    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: _uid)
        .where('type', isEqualTo: TransactionType.expense.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();
    final totals = <String, double>{};
    double totalExpense = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final cat = data['category'] ?? 'Genel';
      final amt = (data['amount'] as num).toDouble();
      totals[cat] = (totals[cat] ?? 0) + amt;
      totalExpense += amt;
    }
    if (totalExpense == 0) return {};
    return totals.map((k, v) => MapEntry(k, v / totalExpense * 100));
  }

  Future<Map<String, dynamic>> getSankeyData() async {
    if (_uid == null) return {};
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month);
    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: _uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();
    double totalIncome = 0, totalExpense = 0;
    final categoryExpenses = <String, double>{};
    for (final doc in snapshot.docs) {
      final tx = BudgetTransaction.fromFirestore(doc);
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        categoryExpenses[tx.category] =
            (categoryExpenses[tx.category] ?? 0) + tx.amount;
        totalExpense += tx.amount;
      }
    }
    double savings = totalIncome - totalExpense;
    if (savings < 0) savings = 0;
    return {
      'income': totalIncome,
      'categories': categoryExpenses,
      'expenseTotal': totalExpense,
      'savings': savings,
    };
  }

  Future<Map<String, double>> getForecastData() async {
    if (_uid == null) return {};
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: _uid)
        .where('type', isEqualTo: TransactionType.expense.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();
    final txs = snapshot.docs.map((d) => BudgetTransaction.fromFirestore(d)).toList();
    final dailySpending = <int, double>{};
    for (final tx in txs) {
      dailySpending[tx.date.day] = (dailySpending[tx.date.day] ?? 0) + tx.amount;
    }
    if (dailySpending.isEmpty) return {'forecast': 0, 'confidence': 0};
    final totalSpentSoFar = dailySpending.values.fold(0.0, (a, b) => a + b);
    final daysElapsed = now.difference(startDate).inDays + 1;
    final avgDaily = daysElapsed > 0 ? totalSpentSoFar / daysElapsed : 0.0;
    return {
      'current': totalSpentSoFar,
      'forecast': avgDaily * daysInMonth,
      'avgDaily': avgDaily,
    };
  }

  Future<List<Map<String, dynamic>>> getAnomalies() async {
    if (_uid == null) return [];
    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: _uid)
        .where('type', isEqualTo: TransactionType.expense.name)
        .get();
    final txs = snapshot.docs
        .map((d) => BudgetTransaction.fromFirestore(d))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return BudgetAnalyticsPure.anomalies(txs);
  }

  Future<Map<String, double>> getAssetDistribution() async {
    if (_uid == null) return {};
    final snapshot = await _db
        .collection('budget_assets')
        .where('userId', isEqualTo: _uid)
        .get();
    final dist = <String, double>{};
    for (final doc in snapshot.docs) {
      final asset = Asset.fromFirestore(doc);
      dist[asset.type.name] = (dist[asset.type.name] ?? 0) + asset.currentValue;
    }
    return dist;
  }

  // ── Local (pre-fetched) analytics ────────────────────────────────────────────

  List<Map<String, dynamic>> getMonthlyTrendLocal(
          List<BudgetTransaction> txs, int months,) =>
      BudgetAnalyticsPure.monthlyTrend(txs, months);

  Map<String, double> getCategoryBalanceDataLocal(List<BudgetTransaction> txs) =>
      BudgetAnalyticsPure.categoryBalanceShares(txs);

  Map<String, dynamic> getSankeyDataLocal(List<BudgetTransaction> txs) {
    final filtered = txs;
    double totalIncome = 0, totalExpense = 0;
    final catExp = <String, double>{};
    for (final tx in filtered) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        catExp[tx.category] = (catExp[tx.category] ?? 0) + tx.amount;
        totalExpense += tx.amount;
      }
    }
    double savings = totalIncome - totalExpense;
    if (savings < 0) savings = 0;
    return {'income': totalIncome, 'categories': catExp, 'expenseTotal': totalExpense, 'savings': savings};
  }

  Map<String, double> getForecastDataLocal(
    List<BudgetTransaction> txs, {
    DateTime? periodStart,
    int? periodDays,
  }) {
    final now = DateTime.now();
    final startDate = periodStart ?? DateTime(now.year, now.month);
    final daysInMonth = periodDays ??
        DateTime(startDate.year, startDate.month + 1, 0).day;
    final filtered = txs
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final daily = <int, double>{};
    for (final tx in filtered) {
      daily[tx.date.day] = (daily[tx.date.day] ?? 0) + tx.amount;
    }
    if (daily.isEmpty) return {'forecast': 0, 'confidence': 0};
    final total = daily.values.fold(0.0, (a, b) => a + b);
    final daysElapsed = now.difference(startDate).inDays + 1;
    final avg = daysElapsed > 0 ? total / daysElapsed : 0.0;
    return {'current': total, 'forecast': avg * daysInMonth, 'avgDaily': avg};
  }

  List<Map<String, dynamic>> getAnomaliesLocal(List<BudgetTransaction> txs) =>
      BudgetAnalyticsPure.anomalies(txs);

  List<Map<String, dynamic>> getStackedBarDataLocal(
      List<BudgetTransaction> txs, int months,) {
    final now = DateTime.now();
    final startDate = monthOffset(now, -months + 1);
    final filtered = txs.where((t) =>
        t.date.isAfter(startDate.subtract(const Duration(days: 1))),).toList();
    final data = <Map<String, dynamic>>[];
    for (int i = 0; i < months; i++) {
      final d = DateTime(startDate.year, startDate.month + i);
      final month = filtered.where((tx) => tx.date.year == d.year && tx.date.month == d.month);
      double income = 0, essential = 0, lifestyle = 0, other = 0;
      for (final tx in month) {
        if (tx.type == TransactionType.income) {
          income += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          if (['Fatura', 'Kira', 'Market'].contains(tx.category)) { essential += tx.amount; }
          else if (['Yemek', 'Eğlence'].contains(tx.category)) { lifestyle += tx.amount; }
          else { other += tx.amount; }
        }
      }
      data.add({'month': d, 'income': income, 'essential': essential, 'lifestyle': lifestyle, 'other': other});
    }
    return data;
  }

  Map<int, double> getHeatmapDataLocal(List<BudgetTransaction> txs, DateTime month) {
    final startDate = DateTime(month.year, month.month);
    final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final filtered = txs.where((t) =>
        t.type == TransactionType.expense &&
        t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.date.isBefore(endDate.add(const Duration(days: 1))),).toList();
    final dailyTotals = <int, double>{};
    for (final tx in filtered) {
      dailyTotals[tx.date.day] = (dailyTotals[tx.date.day] ?? 0) + tx.amount;
    }
    return dailyTotals;
  }

  Map<String, dynamic> getBudgetVsActualLocal(
          List<BudgetLimit> limits, List<BudgetTransaction> txs,) =>
      BudgetAnalyticsPure.budgetVsActual(limits, txs);

  Map<String, double> getRecurringAnalyticsLocal(List<BudgetTransaction> txs) =>
      BudgetAnalyticsPure.recurringAnalytics(txs);

  Map<String, double> getAssetDistributionLocal(List<Account> accounts) {
    final total = accounts.fold(0.0, (s, a) => s + a.balance);
    if (total == 0) return {};
    return {for (final a in accounts) a.name: a.balance / total * 100};
  }

}
