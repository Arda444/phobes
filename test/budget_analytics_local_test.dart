import 'package:flutter_test/flutter_test.dart';
import 'package:phobes/core/budget_analytics_pure.dart';
import 'package:phobes/models/budget_model.dart';

BudgetTransaction _tx({
  required TransactionType type,
  required double amount,
  required String category,
  required DateTime date,
  String recurrence = 'none',
}) {
  return BudgetTransaction(
    userId: 'u1',
    title: 'T',
    amount: amount,
    type: type,
    category: category,
    date: date,
    recurrence: recurrence,
  );
}

void main() {
  group('monthOffset', () {
    test('steps backward across year boundary', () {
      final result = BudgetAnalyticsPure.monthOffset(
        DateTime(2026, 1, 15),
        -2,
      );
      expect(result.year, 2025);
      expect(result.month, 11);
    });

    test('steps forward within same year', () {
      final result = BudgetAnalyticsPure.monthOffset(
        DateTime(2026, 3),
        2,
      );
      expect(result.year, 2026);
      expect(result.month, 5);
    });
  });

  group('monthlyTrend', () {
    test('aggregates income and expense per month', () {
      final now = DateTime.now();
      final txs = [
        _tx(
          type: TransactionType.income,
          amount: 1000,
          category: 'Salary',
          date: DateTime(now.year, now.month, 5),
        ),
        _tx(
          type: TransactionType.expense,
          amount: 200,
          category: 'Food',
          date: DateTime(now.year, now.month, 10),
        ),
      ];
      final trend = BudgetAnalyticsPure.monthlyTrend(txs, 1);
      expect(trend.length, 1);
      expect(trend.first['income'], 1000);
      expect(trend.first['expense'], 200);
    });
  });

  group('categoryBalanceShares', () {
    test('returns percentage shares', () {
      final now = DateTime.now();
      final txs = [
        _tx(
          type: TransactionType.expense,
          amount: 75,
          category: 'Food',
          date: DateTime(now.year, now.month),
        ),
        _tx(
          type: TransactionType.expense,
          amount: 25,
          category: 'Transport',
          date: DateTime(now.year, now.month, 2),
        ),
      ];
      final shares = BudgetAnalyticsPure.categoryBalanceShares(txs);
      expect(shares['Food'], closeTo(75, 0.01));
      expect(shares['Transport'], closeTo(25, 0.01));
    });

    test('empty when no expenses this month', () {
      final txs = [
        _tx(
          type: TransactionType.income,
          amount: 100,
          category: 'Salary',
          date: DateTime.now(),
        ),
      ];
      expect(BudgetAnalyticsPure.categoryBalanceShares(txs), isEmpty);
    });
  });

  group('budgetVsActual', () {
    test('computes performance ratio', () {
      final limits = [
        BudgetLimit(
          userId: 'u1',
          category: 'Food',
          limitAmount: 500,
        ),
      ];
      final txs = [
        _tx(
          type: TransactionType.expense,
          amount: 250,
          category: 'Food',
          date: DateTime.now(),
        ),
      ];
      final result = BudgetAnalyticsPure.budgetVsActual(limits, txs);
      final items = result['items'] as List;
      expect(items.length, 1);
      expect(items.first['actual'], 250);
      expect(items.first['performance'], 0.5);
    });
  });

  group('recurringAnalytics', () {
    test('splits recurring vs one-time', () {
      final txs = [
        _tx(
          type: TransactionType.expense,
          amount: 100,
          category: 'Rent',
          date: DateTime.now(),
          recurrence: 'monthly',
        ),
        _tx(
          type: TransactionType.expense,
          amount: 30,
          category: 'Food',
          date: DateTime.now(),
        ),
      ];
      final r = BudgetAnalyticsPure.recurringAnalytics(txs);
      expect(r['recurring'], 100);
      expect(r['oneTime'], 30);
    });
  });

  group('anomalies', () {
    test('returns empty when fewer than 10 transactions', () {
      final txs = List.generate(
        5,
        (i) => _tx(
          type: TransactionType.expense,
          amount: 10,
          category: 'Food',
          date: DateTime.now().subtract(Duration(days: i)),
        ),
      );
      expect(BudgetAnalyticsPure.anomalies(txs), isEmpty);
    });
  });
}
