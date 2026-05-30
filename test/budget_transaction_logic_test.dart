import 'package:flutter_test/flutter_test.dart';
import 'package:phobes/models/budget_model.dart';

void main() {
  group('BudgetTransaction', () {
    test('toMap includes userId and type', () {
      final tx = BudgetTransaction(
        userId: 'u1',
        title: 'Lunch',
        amount: 100,
        category: 'Food',
        type: TransactionType.expense,
        date: DateTime(2026, 1, 15),
        accountId: 'acc1',
      );
      final map = tx.toMap();
      expect(map['userId'], 'u1');
      expect(map['type'], 'expense');
      expect(map['amount'], 100);
    });

    test('copyWith preserves id', () {
      final tx = BudgetTransaction(
        id: 'tx1',
        userId: 'u1',
        title: 'Salary',
        amount: 50,
        category: 'X',
        type: TransactionType.income,
        date: DateTime.now(),
      );
      final copy = tx.copyWith(amount: 75);
      expect(copy.id, 'tx1');
      expect(copy.amount, 75);
    });
  });
}
