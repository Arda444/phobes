import '../models/budget_model.dart';

/// Shared period filtering for budget limits (UI, analytics, pre-checks).
class BudgetPeriodUtils {
  BudgetPeriodUtils._();

  static DateTime periodStart(String period, [DateTime? reference]) {
    final now = reference ?? DateTime.now();
    switch (period) {
      case 'yearly':
        return DateTime(now.year);
      case 'quarterly':
        final qMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTime(now.year, qMonth);
      case 'monthly':
      default:
        return DateTime(now.year, now.month);
    }
  }

  static bool transactionInPeriod(
    BudgetTransaction tx,
    String period, [
    DateTime? reference,
  ]) {
    final start = periodStart(period, reference);
    return !tx.date.isBefore(start);
  }

  static double spentInCategory(
    List<BudgetTransaction> txs,
    String category,
    String period, [
    DateTime? reference,
  ]) {
    return txs
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              tx.category == category &&
              transactionInPeriod(tx, period, reference),
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }
}
