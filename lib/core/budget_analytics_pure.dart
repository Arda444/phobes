import '../models/budget_model.dart';
import 'budget_period_utils.dart';

/// Pure budget analytics (no Firebase). Used by [BudgetAnalyticsService] and tests.
class BudgetAnalyticsPure {
  BudgetAnalyticsPure._();

  static DateTime monthOffset(DateTime base, int monthOffset) {
    final totalMonths = base.year * 12 + (base.month - 1) + monthOffset;
    return DateTime(totalMonths ~/ 12, totalMonths % 12 + 1);
  }

  static List<Map<String, dynamic>> monthlyTrend(
    List<BudgetTransaction> txs,
    int months,
  ) {
    final now = DateTime.now();
    final startDate = monthOffset(now, -months + 1);
    final filtered = txs
        .where((t) => t.date.isAfter(startDate.subtract(const Duration(days: 1))))
        .toList();
    final trend = <Map<String, dynamic>>[];
    for (int i = 0; i < months; i++) {
      final d = DateTime(startDate.year, startDate.month + i);
      final month =
          filtered.where((tx) => tx.date.year == d.year && tx.date.month == d.month);
      double income = 0, expense = 0;
      for (final tx in month) {
        if (tx.type == TransactionType.income) income += tx.amount;
        if (tx.type == TransactionType.expense) expense += tx.amount;
      }
      trend.add({'month': d, 'income': income, 'expense': expense});
    }
    return trend;
  }

  static Map<String, double> categoryBalanceShares(List<BudgetTransaction> txs) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month);
    final filtered = txs
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.isAfter(startDate.subtract(const Duration(days: 1))),)
        .toList();
    final totals = <String, double>{};
    double totalExpense = 0;
    for (final tx in filtered) {
      totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
      totalExpense += tx.amount;
    }
    if (totalExpense == 0) return {};
    return totals.map((k, v) => MapEntry(k, v / totalExpense * 100));
  }

  static Map<String, dynamic> budgetVsActual(
    List<BudgetLimit> limits,
    List<BudgetTransaction> txs,
  ) {
    final analysis = limits.map((limit) {
      final spent = BudgetPeriodUtils.spentInCategory(
        txs,
        limit.category,
        limit.period,
      );
      return {
        'category': limit.category,
        'limit': limit.limitAmount,
        'actual': spent,
        'performance': limit.limitAmount > 0 ? spent / limit.limitAmount : 0.0,
      };
    }).toList();
    return {'items': analysis};
  }

  static Map<String, double> recurringAnalytics(List<BudgetTransaction> txs) {
    double recurring = 0, oneTime = 0;
    for (final tx in txs.where((t) => t.type == TransactionType.expense)) {
      if (tx.recurrence != 'none') {
        recurring += tx.amount;
      } else {
        oneTime += tx.amount;
      }
    }
    return {'recurring': recurring, 'oneTime': oneTime};
  }

  static List<Map<String, dynamic>> anomalies(List<BudgetTransaction> txs) {
    final filtered = txs.where((t) => t.type == TransactionType.expense).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (filtered.length < 10) return [];
    final categoryHistory = <String, List<double>>{};
    for (final tx in filtered) {
      (categoryHistory[tx.category] ??= []).add(tx.amount);
    }
    final result = <Map<String, dynamic>>[];
    categoryHistory.forEach((cat, amounts) {
      if (amounts.length > 3) {
        final avg = amounts.reduce((a, b) => a + b) / amounts.length;
        if (amounts.first > avg * 2) {
          result.add({
            'category': cat,
            'amount': amounts.first,
            'avg': avg,
            'date': filtered
                .firstWhere((t) => t.category == cat && t.amount == amounts.first)
                .date,
          });
        }
      }
    });
    return result;
  }
}
