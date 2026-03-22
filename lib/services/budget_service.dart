import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/budget_model.dart';
import 'currency_service.dart';
import 'notification_service.dart';

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CurrencyService _currencyService = CurrencyService();

  CurrencyService getCurrencyService() => _currencyService;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> addTransaction(BudgetTransaction tx) async {
    if (currentUserId == null) return;

    if (tx.accountId != null) {
      final accountDoc =
          await _db.collection('budget_accounts').doc(tx.accountId).get();
      if (accountDoc.exists) {
        final account = Account.fromFirestore(accountDoc);
        double newBalance = account.balance;
        if (tx.type == TransactionType.income) {
          newBalance += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          newBalance -= tx.amount;
        } else if (tx.type == TransactionType.transfer &&
            tx.toAccountId != null) {
          newBalance -= tx.amount;
          final toAccountDoc =
              await _db.collection('budget_accounts').doc(tx.toAccountId).get();
          if (toAccountDoc.exists) {
            final toAccount = Account.fromFirestore(toAccountDoc);
            await updateAccount(
                toAccount.copyWith(balance: toAccount.balance + tx.amount));
          }
        }
        await updateAccount(account.copyWith(balance: newBalance));
      }
    }

    await _db.collection('budget_transactions').add(tx.toMap());

    // Check budget limits for expense category
    if (tx.type == TransactionType.expense) {
      await _checkBudgetLimit(tx.category);
    }
  }

  Future<void> _checkBudgetLimit(String category) async {
    if (currentUserId == null) return;

    try {
      final limitsSnapshot = await _db
          .collection('budget_limits')
          .where('userId', isEqualTo: currentUserId)
          .where('category', isEqualTo: category)
          .get();

      if (limitsSnapshot.docs.isEmpty) return;

      final limit = BudgetLimit.fromFirestore(limitsSnapshot.docs.first);

      // Get this month's spending
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final txSnapshot = await _db
          .collection('budget_transactions')
          .where('userId', isEqualTo: currentUserId)
          .where('type', isEqualTo: TransactionType.expense.name)
          .where('category', isEqualTo: category)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .get();

      double totalSpent = 0;
      for (var doc in txSnapshot.docs) {
        totalSpent += (doc.data()['amount'] as num).toDouble();
      }

      final ratio =
          limit.limitAmount > 0 ? totalSpent / limit.limitAmount : 0.0;

      if (ratio >= 1.0) {
        await NotificationService().sendNotification(
          title: 'Bütçe Limiti Aşıldı! 🚨',
          body:
              '$category: ${totalSpent.toStringAsFixed(0)} / ${limit.limitAmount.toStringAsFixed(0)} TL',
          type: 'budget',
          icon: '🚨',
          color: 0xFFF44336,
          prefKey: 'notif_budget_limit',
        );
      } else if (ratio >= 0.8) {
        await NotificationService().sendNotification(
          title: 'Bütçe Limiti Yaklaşıyor! ⚠️',
          body:
              '$category: ${totalSpent.toStringAsFixed(0)} / ${limit.limitAmount.toStringAsFixed(0)} TL (%${(ratio * 100).toStringAsFixed(0)})',
          type: 'budget',
          icon: '⚠️',
          color: 0xFFFF9800,
          prefKey: 'notif_budget_limit',
        );
      }
    } catch (e) {
      // Silently fail for limit check
    }
  }

  Stream<List<BudgetTransaction>> getTransactionsStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BudgetTransaction.fromFirestore(doc))
            .toList());
  }

  Future<void> updateTransaction(BudgetTransaction tx) async {
    if (tx.id != null) {
      await _db.collection('budget_transactions').doc(tx.id).update(tx.toMap());
    }
  }

  Future<void> deleteTransaction(String txId) async {
    await _db.collection('budget_transactions').doc(txId).delete();
  }

  Future<void> repairCorruptedTitles() async {
    if (currentUserId == null) return;
    try {
      final snapshot = await _db
          .collection('budget_transactions')
          .where('userId', isEqualTo: currentUserId)
          .get();

      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = data['title'] as String?;
        if (title != null && title.contains('HarcamasÄ±')) {
          final newTitle = title.replaceAll('HarcamasÄ±', 'Harcaması');
          await doc.reference.update({'title': newTitle});
          count++;
        }
      }
      if (count > 0) {
        debugPrint('Repaired $count corrupted transaction titles.');
      }
    } catch (e) {
      debugPrint('Error repairing titles: $e');
    }
  }

  Stream<List<Account>> getAccountsStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('budget_accounts')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Account.fromFirestore(doc)).toList());
  }

  Future<void> addAccount(Account account) async {
    if (currentUserId == null) return;
    await _db.collection('budget_accounts').add(account.toMap());
  }

  Future<void> updateAccount(Account account) async {
    if (account.id != null) {
      await _db
          .collection('budget_accounts')
          .doc(account.id)
          .update(account.toMap());
    }
  }

  Future<void> deleteAccount(String accountId) async {
    await _db.collection('budget_accounts').doc(accountId).delete();
  }

  Stream<List<Debt>> getDebtsStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('budget_debts')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Debt.fromFirestore(doc)).toList());
  }

  Future<void> addDebt(Debt debt) async {
    if (currentUserId == null) return;
    await _db.collection('budget_debts').add(debt.toMap());
  }

  Future<void> updateDebt(Debt debt) async {
    if (debt.id != null) {
      await _db.collection('budget_debts').doc(debt.id).update(debt.toMap());
    }
  }

  Future<void> deleteDebt(String debtId) async {
    await _db.collection('budget_debts').doc(debtId).delete();
  }

  Future<Map<String, double>> getCategoryTotals(TransactionType type) async {
    if (currentUserId == null) return {};

    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: currentUserId)
        .where('type', isEqualTo: type.name)
        .get();

    final Map<String, double> totals = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'] ?? 'Genel';
      final amount = (data['amount'] as num).toDouble();
      totals[category] = (totals[category] ?? 0) + amount;
    }
    return totals;
  }

  Stream<List<BudgetLimit>> getLimitsStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('budget_limits')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BudgetLimit.fromFirestore(doc))
            .toList());
  }

  Future<void> addLimit(BudgetLimit limit) async {
    if (currentUserId == null) return;
    await _db.collection('budget_limits').add(limit.toMap());
  }

  Future<void> updateLimit(BudgetLimit limit) async {
    if (limit.id != null) {
      await _db.collection('budget_limits').doc(limit.id).update(limit.toMap());
    }
  }

  Future<void> deleteLimit(String id) async {
    await _db.collection('budget_limits').doc(id).delete();
  }

  Stream<List<SavingsGoal>> getGoalsStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('savings_goals')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavingsGoal.fromFirestore(doc))
            .toList());
  }

  Future<void> addGoal(SavingsGoal goal) async {
    if (currentUserId == null) return;
    await _db.collection('savings_goals').add(goal.toMap());
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    if (goal.id != null) {
      await _db.collection('savings_goals').doc(goal.id).update(goal.toMap());

      // Notify: savings goal progress
      final ratio =
          goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0.0;
      if (ratio >= 1.0) {
        await NotificationService().sendNotification(
          title: 'Tasarruf Hedefi Tamamlandı! 🎉',
          body: '${goal.title} hedefine ulaştın!',
          type: 'budget',
          icon: '🏆',
          color: 0xFF4CAF50,
          prefKey: 'notif_budget_goal',
        );
      } else if (ratio >= 0.75) {
        await NotificationService().sendNotification(
          title: 'Hedefe Çok Yaklaştın! 💪',
          body:
              '${goal.title} - %${(ratio * 100).toStringAsFixed(0)} tamamlandı',
          type: 'budget',
          icon: '💪',
          color: 0xFFFF9800,
          prefKey: 'notif_budget_goal',
        );
      } else if (ratio >= 0.5) {
        await NotificationService().sendNotification(
          title: 'Yarı Yoldasın! 🚀',
          body:
              '${goal.title} - %${(ratio * 100).toStringAsFixed(0)} tamamlandı',
          type: 'budget',
          icon: '🚀',
          color: 0xFF2196F3,
          prefKey: 'notif_budget_goal',
        );
      }
    }
  }

  Future<void> deleteGoal(String id) async {
    await _db.collection('savings_goals').doc(id).delete();
  }

  Future<List<Map<String, dynamic>>> getMonthlyTrend(int months) async {
    if (currentUserId == null) return [];

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months + 1, 1);

    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: currentUserId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();
    final txs = snapshot.docs
        .map((doc) => BudgetTransaction.fromFirestore(doc))
        .toList();

    final List<Map<String, dynamic>> trend = [];

    for (int i = 0; i < months; i++) {
      final monthDate = DateTime(startDate.year, startDate.month + i, 1);
      final monthTxs = txs.where((tx) =>
          tx.date.year == monthDate.year && tx.date.month == monthDate.month);

      double income = 0;
      double expense = 0;

      for (var tx in monthTxs) {
        if (tx.type == TransactionType.income) {
          income += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          expense += tx.amount;
        }
      }

      trend.add({
        'month': monthDate,
        'income': income,
        'expense': expense,
      });
    }

    return trend;
  }

  Future<Map<String, dynamic>> getBudgetVsActual() async {
    if (currentUserId == null) return {};

    final limits = await _db
        .collection('budget_limits')
        .where('userId', isEqualTo: currentUserId)
        .get();

    final txSnapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: currentUserId)
        .where('type', isEqualTo: TransactionType.expense.name)
        .get();

    final List<Map<String, dynamic>> analysis = [];
    final txs = txSnapshot.docs
        .map((doc) => BudgetTransaction.fromFirestore(doc))
        .toList();

    for (var doc in limits.docs) {
      final limit = BudgetLimit.fromFirestore(doc);
      final spent = txs
          .where((tx) => tx.category == limit.category)
          .fold(0.0, (total, tx) => total + tx.amount);

      analysis.add({
        'category': limit.category,
        'limit': limit.limitAmount,
        'actual': spent,
        'performance':
            limit.limitAmount > 0 ? (spent / limit.limitAmount) : 0.0,
      });
    }

    return {'items': analysis};
  }

  Future<Map<String, double>> getRecurringAnalytics() async {
    if (currentUserId == null) return {};

    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: currentUserId)
        .where('type', isEqualTo: TransactionType.expense.name)
        .get();

    double recurringTotal = 0;
    double oneTimeTotal = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num).toDouble();
      final isRecurring =
          data['recurrence'] != null && data['recurrence'] != 'none';

      if (isRecurring) {
        recurringTotal += amount;
      } else {
        oneTimeTotal += amount;
      }
    }

    return {
      'recurring': recurringTotal,
      'oneTime': oneTimeTotal,
    };
  }

  Future<void> generateUltimateTestData({int days = 90}) async {
    if (currentUserId == null) return;
    debugPrint(">> Budget Gen: Hesaplar oluşturuluyor...");

    final random = Random();

    final accounts = [
      Account(
          userId: currentUserId!,
          name: "Nakit Cüzdan",
          type: AccountType.cash,
          balance: 2500,
          icon: "money_rounded"),
      Account(
          userId: currentUserId!,
          name: "Banka Kartı",
          type: AccountType.bank,
          balance: 45000,
          icon: "account_balance_rounded"),
      Account(
          userId: currentUserId!,
          name: "Kredi Kartı",
          type: AccountType.creditCard,
          balance: -1200,
          icon: "credit_card_rounded"),
    ];

    List<String> accountIds = [];
    for (var acc in accounts) {
      final doc = await _db.collection('budget_accounts').add(acc.toMap());
      accountIds.add(doc.id);
    }

    final debts = [
      Debt(
          userId: currentUserId!,
          personName: "Ahmet Yılmaz",
          amount: 1500,
          type: DebtType.debt,
          date: DateTime.now().subtract(const Duration(days: 10))),
      Debt(
          userId: currentUserId!,
          personName: "Mehmet Demir",
          amount: 500,
          type: DebtType.credit,
          date: DateTime.now().subtract(const Duration(days: 5))),
    ];
    for (var d in debts) {
      await addDebt(d);
    }

    debugPrint(
        ">> Budget Gen: Geriye dönük işlemler döngüsü başlıyor ($days gün)...");
    final categories = {
      'Market': ['Bim', 'Migros', 'Kasap', 'Manav'],
      'Yemek': ['Burger King', 'Restoran', 'Kahve', 'Sipariş'],
      'Ulaşım': ['Benzin', 'Otobüs', 'Taksi', 'Bakım'],
      'Eğlence': ['Sinema', 'Netflix', 'Oyun', 'Konser'],
      'Fatura': ['Elektrik', 'Su', 'İnternet', 'Telefon'],
    };

    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));

      int dailyTxCount = random.nextInt(3);
      for (int k = 0; k < dailyTxCount; k++) {
        final category =
            categories.keys.toList()[random.nextInt(categories.length)];
        final subCategory =
            categories[category]![random.nextInt(categories[category]!.length)];
        final amount = (random.nextDouble() * 500) + 20;
        final accId = accountIds[random.nextInt(accountIds.length)];

        final tx = BudgetTransaction(
          userId: currentUserId!,
          title: "$subCategory Harcaması",
          amount: amount,
          type: TransactionType.expense,
          category: category,
          subCategory: subCategory,
          date: date.subtract(Duration(hours: random.nextInt(12))),
          accountId: accId,
        );
        await addTransaction(tx);
      }

      if (date.day == 1) {
        await addTransaction(BudgetTransaction(
          userId: currentUserId!,
          title: "Maaş Ödemesi",
          amount: (45000 + random.nextInt(5000)).toDouble(),
          type: TransactionType.income,
          category: "Maaş",
          date: DateTime(date.year, date.month, date.day, 9, 0),
          accountId: accountIds[1],
        ));
      }
    }
    debugPrint(">> Budget Gen: Geriye dönük işlemler döngüsü tamamlandı!");
  }

  Future<Map<String, double>> getCategoryBalanceData() async {
    if (currentUserId == null) return {};

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);

    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: currentUserId)
        .where('type', isEqualTo: TransactionType.expense.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();

    final Map<String, double> totals = {};
    double totalExpense = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'] ?? 'Genel';
      final amount = (data['amount'] as num).toDouble();
      totals[category] = (totals[category] ?? 0) + amount;
      totalExpense += amount;
    }

    if (totalExpense == 0) return {};

    final Map<String, double> balance = {};
    totals.forEach((key, value) {
      balance[key] = (value / totalExpense) * 100;
    });

    return balance;
  }

  Future<List<Map<String, dynamic>>> getStackedBarData(int months) async {
    if (currentUserId == null) return [];

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months + 1, 1);

    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: currentUserId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();
    final txs = snapshot.docs
        .map((doc) => BudgetTransaction.fromFirestore(doc))
        .toList();

    final List<Map<String, dynamic>> data = [];

    for (int i = 0; i < months; i++) {
      final monthDate = DateTime(startDate.year, startDate.month + i, 1);
      final monthTxs = txs.where((tx) =>
          tx.date.year == monthDate.year && tx.date.month == monthDate.month);

      double income = 0;
      double essential = 0;
      double lifestyle = 0;
      double other = 0;

      for (var tx in monthTxs) {
        if (tx.type == TransactionType.income) {
          income += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          if (['Fatura', 'Kira', 'Market'].contains(tx.category)) {
            essential += tx.amount;
          } else if (['Yemek', 'Eğlence'].contains(tx.category)) {
            lifestyle += tx.amount;
          } else {
            other += tx.amount;
          }
        }
      }

      data.add({
        'month': monthDate,
        'income': income,
        'essential': essential,
        'lifestyle': lifestyle,
        'other': other,
      });
    }

    return data;
  }

  Future<Map<int, double>> getHeatmapData(DateTime month) async {
    if (currentUserId == null) return {};

    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: currentUserId)
        .where('type', isEqualTo: TransactionType.expense.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final Map<int, double> dailyTotals = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final amount = (data['amount'] as num).toDouble();
      dailyTotals[date.day] = (dailyTotals[date.day] ?? 0) + amount;
    }

    return dailyTotals;
  }

  Stream<List<Asset>> getAssetsStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('budget_assets')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Asset.fromFirestore(doc)).toList());
  }

  Future<void> addAsset(Asset asset) async {
    if (currentUserId == null) return;
    await _db.collection('budget_assets').add(asset.toMap());
  }

  Future<void> updateAsset(Asset asset) async {
    if (asset.id != null) {
      await _db.collection('budget_assets').doc(asset.id).update(asset.toMap());
    }
  }

  Future<void> deleteAsset(String assetId) async {
    await _db.collection('budget_assets').doc(assetId).delete();
  }

  Future<void> refreshAssetValues() async {
    if (currentUserId == null) return;

    final snapshot = await _db
        .collection('budget_assets')
        .where('userId', isEqualTo: currentUserId)
        .get();

    for (var doc in snapshot.docs) {
      final asset = Asset.fromFirestore(doc);
      if (asset.symbol.isEmpty) continue;

      final livePrice = await _currencyService.getLivePrice(
        asset.symbol,
        asset.type.name,
      );

      if (livePrice != null) {
        final newValue = asset.amount * livePrice;
        await updateAsset(asset.copyWith(
          currentValue: newValue,
          lastUpdated: DateTime.now(),
        ));
      }
    }
  }

  Future<Map<String, dynamic>> getSankeyData() async {
    if (currentUserId == null) return {};

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);

    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: currentUserId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();

    double totalIncome = 0;
    Map<String, double> categoryExpenses = {};
    double totalExpense = 0;

    final txs = snapshot.docs
        .map((doc) => BudgetTransaction.fromFirestore(doc))
        .toList();

    for (var tx in txs) {
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
    if (currentUserId == null) return {};

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: currentUserId)
        .where('type', isEqualTo: TransactionType.expense.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();

    final txs = snapshot.docs
        .map((doc) => BudgetTransaction.fromFirestore(doc))
        .toList();

    Map<int, double> dailySpending = {};
    for (var tx in txs) {
      dailySpending[tx.date.day] =
          (dailySpending[tx.date.day] ?? 0) + tx.amount;
    }

    if (dailySpending.isEmpty) return {'forecast': 0, 'confidence': 0};

    double totalSpentSoFar = 0;
    for (var v in dailySpending.values) {
      totalSpentSoFar += v;
    }
    double avgDaily = totalSpentSoFar / now.day;
    double endOfMonthForecast = avgDaily * daysInMonth;

    return {
      'current': totalSpentSoFar,
      'forecast': endOfMonthForecast,
      'avgDaily': avgDaily,
    };
  }

  Future<List<Map<String, dynamic>>> getAnomalies() async {
    if (currentUserId == null) return [];

    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: currentUserId)
        .where('type', isEqualTo: TransactionType.expense.name)
        .get();

    final txs = snapshot.docs
        .map((doc) => BudgetTransaction.fromFirestore(doc))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (txs.length < 10) return [];

    Map<String, List<double>> categoryHistory = {};
    for (var tx in txs) {
      categoryHistory[tx.category] = (categoryHistory[tx.category] ?? [])
        ..add(tx.amount);
    }

    List<Map<String, dynamic>> anomalies = [];
    categoryHistory.forEach((cat, amounts) {
      if (amounts.length > 3) {
        double avg = amounts.reduce((a, b) => a + b) / amounts.length;
        if (amounts.first > avg * 2) {
          anomalies.add({
            'category': cat,
            'amount': amounts.first,
            'avg': avg,
            'date': txs
                .firstWhere(
                    (t) => t.category == cat && t.amount == amounts.first)
                .date,
          });
        }
      }
    });

    return anomalies;
  }

  Future<Map<String, double>> getAssetDistribution() async {
    if (currentUserId == null) return {};

    final snapshot = await _db
        .collection('budget_assets')
        .where('userId', isEqualTo: currentUserId)
        .get();

    Map<String, double> distribution = {};
    for (var doc in snapshot.docs) {
      final asset = Asset.fromFirestore(doc);
      distribution[asset.type.name] =
          (distribution[asset.type.name] ?? 0) + asset.currentValue;
    }

    return distribution;
  }

  List<Map<String, dynamic>> getMonthlyTrendLocal(
      List<BudgetTransaction> txs, int months) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months + 1, 1);
    final filtered = txs
        .where(
            (t) => t.date.isAfter(startDate.subtract(const Duration(days: 1))))
        .toList();

    final List<Map<String, dynamic>> trend = [];
    for (int i = 0; i < months; i++) {
      final monthDate = DateTime(startDate.year, startDate.month + i, 1);
      final monthTxs = filtered.where((tx) =>
          tx.date.year == monthDate.year && tx.date.month == monthDate.month);

      double income = 0;
      double expense = 0;
      for (var tx in monthTxs) {
        if (tx.type == TransactionType.income) {
          income += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          expense += tx.amount;
        }
      }
      trend.add({'month': monthDate, 'income': income, 'expense': expense});
    }
    return trend;
  }

  Map<String, double> getCategoryBalanceDataLocal(List<BudgetTransaction> txs) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final filtered = txs
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.isAfter(startDate.subtract(const Duration(days: 1))))
        .toList();

    final Map<String, double> totals = {};
    double totalExpense = 0;
    for (var tx in filtered) {
      final category = tx.category;
      totals[category] = (totals[category] ?? 0) + tx.amount;
      totalExpense += tx.amount;
    }
    if (totalExpense == 0) return {};
    final Map<String, double> balance = {};
    totals.forEach((key, value) {
      balance[key] = (value / totalExpense) * 100;
    });
    return balance;
  }

  Map<String, dynamic> getSankeyDataLocal(List<BudgetTransaction> txs) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final filtered = txs
        .where(
            (t) => t.date.isAfter(startDate.subtract(const Duration(days: 1))))
        .toList();

    double totalIncome = 0;
    Map<String, double> categoryExpenses = {};
    double totalExpense = 0;

    for (var tx in filtered) {
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

  Map<String, double> getForecastDataLocal(List<BudgetTransaction> txs) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final filtered = txs
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.isAfter(startDate.subtract(const Duration(days: 1))))
        .toList();

    Map<int, double> dailySpending = {};
    for (var tx in filtered) {
      dailySpending[tx.date.day] =
          (dailySpending[tx.date.day] ?? 0) + tx.amount;
    }
    if (dailySpending.isEmpty) return {'forecast': 0, 'confidence': 0};

    double totalSpentSoFar = 0;
    for (var v in dailySpending.values) {
      totalSpentSoFar += v;
    }
    double avgDaily = totalSpentSoFar / now.day;
    double endOfMonthForecast = avgDaily * daysInMonth;

    return {
      'current': totalSpentSoFar,
      'forecast': endOfMonthForecast,
      'avgDaily': avgDaily,
    };
  }

  List<Map<String, dynamic>> getAnomaliesLocal(List<BudgetTransaction> txs) {
    final filtered = txs
        .where((t) => t.type == TransactionType.expense)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (filtered.length < 10) return [];

    Map<String, List<double>> categoryHistory = {};
    for (var tx in filtered) {
      categoryHistory[tx.category] = (categoryHistory[tx.category] ?? [])
        ..add(tx.amount);
    }

    List<Map<String, dynamic>> anomalies = [];
    categoryHistory.forEach((cat, amounts) {
      if (amounts.length > 3) {
        double avg = amounts.reduce((a, b) => a + b) / amounts.length;
        if (amounts.first > avg * 2) {
          anomalies.add({
            'category': cat,
            'amount': amounts.first,
            'avg': avg,
            'date': filtered
                .firstWhere(
                    (t) => t.category == cat && t.amount == amounts.first)
                .date,
          });
        }
      }
    });
    return anomalies;
  }

  List<Map<String, dynamic>> getStackedBarDataLocal(
      List<BudgetTransaction> txs, int months) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months + 1, 1);
    final filtered = txs
        .where(
            (t) => t.date.isAfter(startDate.subtract(const Duration(days: 1))))
        .toList();

    final List<Map<String, dynamic>> data = [];
    for (int i = 0; i < months; i++) {
      final monthDate = DateTime(startDate.year, startDate.month + i, 1);
      final monthTxs = filtered.where((tx) =>
          tx.date.year == monthDate.year && tx.date.month == monthDate.month);

      double income = 0;
      double essential = 0;
      double lifestyle = 0;
      double other = 0;

      for (var tx in monthTxs) {
        if (tx.type == TransactionType.income) {
          income += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          if (['Fatura', 'Kira', 'Market'].contains(tx.category)) {
            essential += tx.amount;
          } else if (['Yemek', 'Eğlence'].contains(tx.category)) {
            lifestyle += tx.amount;
          } else {
            other += tx.amount;
          }
        }
      }
      data.add({
        'month': monthDate,
        'income': income,
        'essential': essential,
        'lifestyle': lifestyle,
        'other': other,
      });
    }
    return data;
  }

  Map<int, double> getHeatmapDataLocal(
      List<BudgetTransaction> txs, DateTime month) {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final filtered = txs
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            t.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    final Map<int, double> dailyTotals = {};
    for (var tx in filtered) {
      dailyTotals[tx.date.day] = (dailyTotals[tx.date.day] ?? 0) + tx.amount;
    }
    return dailyTotals;
  }

  Map<String, dynamic> getBudgetVsActualLocal(
      List<BudgetLimit> limits, List<BudgetTransaction> txs) {
    final List<Map<String, dynamic>> analysis = [];
    final expenses =
        txs.where((t) => t.type == TransactionType.expense).toList();

    for (var limit in limits) {
      final spent = expenses
          .where((tx) => tx.category == limit.category)
          .fold(0.0, (total, tx) => total + tx.amount);
      analysis.add({
        'category': limit.category,
        'limit': limit.limitAmount,
        'actual': spent,
        'performance':
            limit.limitAmount > 0 ? (spent / limit.limitAmount) : 0.0,
      });
    }
    return {'items': analysis};
  }

  Map<String, double> getRecurringAnalyticsLocal(List<BudgetTransaction> txs) {
    final expenses =
        txs.where((t) => t.type == TransactionType.expense).toList();
    double recurringTotal = 0;
    double oneTimeTotal = 0;

    for (var tx in expenses) {
      final isRecurring = tx.recurrence != 'none';
      if (isRecurring) {
        recurringTotal += tx.amount;
      } else {
        oneTimeTotal += tx.amount;
      }
    }
    return {
      'recurring': recurringTotal,
      'oneTime': oneTimeTotal,
    };
  }

  Map<String, double> getAssetDistributionLocal(List<Account> accounts) {
    double total =
        accounts.fold(0.0, (currentSum, acc) => currentSum + acc.balance);
    if (total == 0) {
      return {};
    }
    final Map<String, double> distribution = {};
    for (var acc in accounts) {
      distribution[acc.name] = (acc.balance / total) * 100;
    }
    return distribution;
  }
}
