import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/budget_model.dart';
import 'currency_service.dart';
import 'budget_transaction_service.dart';
import 'budget_account_service.dart';
import 'budget_debt_service.dart';
import 'budget_analytics_service.dart';

/// Thin facade that coordinates the four budget sub-services and holds
/// shared state (base currency) used across all budget UI.
class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  // ── Sub-services ─────────────────────────────────────────────────────────────
  final _tx   = BudgetTransactionService();
  final _acc  = BudgetAccountService();
  final _debt = BudgetDebtService();
  final _ana  = BudgetAnalyticsService();

  final _currencyService = CurrencyService();
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  CurrencyService getCurrencyService() => _currencyService;

  // ── Currency preference ───────────────────────────────────────────────────────
  static const _kBaseCurrency = 'budget_base_currency';
  final ValueNotifier<String> baseCurrency = ValueNotifier('TRY');

  Future<void> loadBaseCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    baseCurrency.value = prefs.getString(_kBaseCurrency) ?? 'TRY';
  }

  Future<void> setBaseCurrency(String code) async {
    baseCurrency.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseCurrency, code);
  }

  // ── Transactions ──────────────────────────────────────────────────────────────
  Future<void> addTransaction(BudgetTransaction tx,
          {String? limitExceededTitle,
          String? limitApproachingTitle,
          String? currencyLabel,}) =>
      _tx.addTransaction(tx,
          limitExceededTitle: limitExceededTitle,
          limitApproachingTitle: limitApproachingTitle,
          currencyLabel: currencyLabel,);

  Stream<List<BudgetTransaction>> getTransactionsStream() =>
      _tx.getTransactionsStream();
  Future<void> updateTransaction(BudgetTransaction tx) =>
      _tx.updateTransaction(tx);
  Future<void> deleteTransaction(String txId) => _tx.deleteTransaction(txId);
  Future<void> replaceTransaction(BudgetTransaction old, BudgetTransaction updated,
          {String? limitExceededTitle,
          String? limitApproachingTitle,
          String? currencyLabel,}) =>
      _tx.replaceTransaction(old, updated,
          limitExceededTitle: limitExceededTitle,
          limitApproachingTitle: limitApproachingTitle,
          currencyLabel: currencyLabel,);
  Future<Map<String, double>> getCategoryTotals(TransactionType type) =>
      _tx.getCategoryTotals(type);

  // ── Accounts ──────────────────────────────────────────────────────────────────
  Stream<List<Account>> getAccountsStream() => _acc.getAccountsStream();
  Future<void> addAccount(Account account) => _acc.addAccount(account);
  Future<void> updateAccount(Account account) => _acc.updateAccount(account);
  Future<void> deleteAccount(String id) => _acc.deleteAccount(id);

  // ── Assets ────────────────────────────────────────────────────────────────────
  Stream<List<Asset>> getAssetsStream() => _acc.getAssetsStream();
  Future<void> addAsset(Asset asset) => _acc.addAsset(asset);
  Future<void> updateAsset(Asset asset) => _acc.updateAsset(asset);
  Future<void> deleteAsset(String id) => _acc.deleteAsset(id);
  Future<void> refreshAssetValues() => _acc.refreshAssetValues();

  // ── Debts ─────────────────────────────────────────────────────────────────────
  Stream<List<Debt>> getDebtsStream() => _debt.getDebtsStream();
  Future<void> addDebt(Debt debt) => _debt.addDebt(debt);
  Future<void> updateDebt(Debt debt) => _debt.updateDebt(debt);
  Future<void> deleteDebt(String id) => _debt.deleteDebt(id);

  // ── Limits ────────────────────────────────────────────────────────────────────
  Stream<List<BudgetLimit>> getLimitsStream() => _debt.getLimitsStream();
  Future<void> addLimit(BudgetLimit limit) => _debt.addLimit(limit);
  Future<void> updateLimit(BudgetLimit limit) => _debt.updateLimit(limit);
  Future<void> deleteLimit(String id) => _debt.deleteLimit(id);

  // ── Goals ─────────────────────────────────────────────────────────────────────
  Stream<List<SavingsGoal>> getGoalsStream() => _debt.getGoalsStream();
  Future<void> addGoal(SavingsGoal goal) => _debt.addGoal(goal);
  Future<void> updateGoal(SavingsGoal goal) => _debt.updateGoal(goal);
  Future<void> deleteGoal(String id) => _debt.deleteGoal(id);

  // ── Analytics (async) ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getMonthlyTrend(int months) =>
      _ana.getMonthlyTrend(months);
  Future<Map<String, dynamic>> getBudgetVsActual() => _ana.getBudgetVsActual();
  Future<Map<String, double>> getRecurringAnalytics() =>
      _ana.getRecurringAnalytics();
  Future<Map<String, double>> getCategoryBalanceData() =>
      _ana.getCategoryBalanceData();
  Future<Map<String, dynamic>> getSankeyData() => _ana.getSankeyData();
  Future<Map<String, double>> getForecastData() => _ana.getForecastData();
  Future<List<Map<String, dynamic>>> getAnomalies() => _ana.getAnomalies();
  Future<Map<String, double>> getAssetDistribution() =>
      _ana.getAssetDistribution();

  // ── Analytics (local / pre-fetched) ──────────────────────────────────────────
  List<Map<String, dynamic>> getMonthlyTrendLocal(
          List<BudgetTransaction> txs, int months,) =>
      _ana.getMonthlyTrendLocal(txs, months);
  Map<String, double> getCategoryBalanceDataLocal(
          List<BudgetTransaction> txs,) =>
      _ana.getCategoryBalanceDataLocal(txs);
  Map<String, dynamic> getSankeyDataLocal(List<BudgetTransaction> txs) =>
      _ana.getSankeyDataLocal(txs);
  Map<String, double> getForecastDataLocal(
    List<BudgetTransaction> txs, {
    DateTime? periodStart,
    int? periodDays,
  }) =>
      _ana.getForecastDataLocal(
        txs,
        periodStart: periodStart,
        periodDays: periodDays,
      );
  List<Map<String, dynamic>> getAnomaliesLocal(List<BudgetTransaction> txs) =>
      _ana.getAnomaliesLocal(txs);
  List<Map<String, dynamic>> getStackedBarDataLocal(
          List<BudgetTransaction> txs, int months,) =>
      _ana.getStackedBarDataLocal(txs, months);
  Map<int, double> getHeatmapDataLocal(
          List<BudgetTransaction> txs, DateTime month,) =>
      _ana.getHeatmapDataLocal(txs, month);
  Map<String, dynamic> getBudgetVsActualLocal(
          List<BudgetLimit> limits, List<BudgetTransaction> txs,) =>
      _ana.getBudgetVsActualLocal(limits, txs);
  Map<String, double> getRecurringAnalyticsLocal(
          List<BudgetTransaction> txs,) =>
      _ana.getRecurringAnalyticsLocal(txs);
  Map<String, double> getAssetDistributionLocal(List<Account> accounts) =>
      _ana.getAssetDistributionLocal(accounts);

  // ── Dev / Test data ───────────────────────────────────────────────────────────
  Future<void> generateUltimateTestData({int days = 90, Function(double)? onProgress}) async {
    if (currentUserId == null) return;
    debugPrint('>> Budget Gen: Hesaplar oluşturuluyor...');

    final random = Random();
    final uid = currentUserId!;

    final accounts = [
      Account(userId: uid, name: 'Nakit Cüzdan', type: AccountType.cash, balance: 2500, icon: 'money_rounded'),
      Account(userId: uid, name: 'Banka Kartı', type: AccountType.bank, balance: 45000, icon: 'account_balance_rounded'),
      Account(userId: uid, name: 'Kredi Kartı', type: AccountType.creditCard, balance: -1200, icon: 'credit_card_rounded'),
    ];

    final accountIds = <String>[];
    for (final acc in accounts) {
      final doc = await _db.collection('budget_accounts').add(acc.toMap());
      accountIds.add(doc.id);
    }

    for (final d in [
      Debt(userId: uid, personName: 'Ahmet Yılmaz', amount: 1500, type: DebtType.debt, date: DateTime.now().subtract(const Duration(days: 10))),
      Debt(userId: uid, personName: 'Mehmet Demir', amount: 500, type: DebtType.credit, date: DateTime.now().subtract(const Duration(days: 5))),
    ]) {
      await addDebt(d);
    }

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
      for (int k = 0; k < random.nextInt(3); k++) {
        final category = categories.keys.toList()[random.nextInt(categories.length)];
        final subCategory = categories[category]![random.nextInt(categories[category]!.length)];
        await addTransaction(BudgetTransaction(
          userId: uid,
          title: '$subCategory Harcaması',
          amount: (random.nextDouble() * 500) + 20,
          type: TransactionType.expense,
          category: category,
          subCategory: subCategory,
          date: date.subtract(Duration(hours: random.nextInt(12))),
          accountId: accountIds[random.nextInt(accountIds.length)],
        ),);
      }
      if (date.day == 1) {
        await addTransaction(BudgetTransaction(
          userId: uid,
          title: 'Maaş Ödemesi',
          amount: (45000 + random.nextInt(5000)).toDouble(),
          type: TransactionType.income,
          category: 'Maaş',
          date: DateTime(date.year, date.month, date.day, 9),
          accountId: accountIds[1],
        ),);
      }
      onProgress?.call(i / days);
    }
    debugPrint('>> Budget Gen: Tamamlandı!');
  }
}
