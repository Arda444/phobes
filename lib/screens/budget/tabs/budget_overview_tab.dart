import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../../../core/budget_period_utils.dart';
import '../../../models/budget_model.dart';
import '../../../core/firebase_errors.dart';
import '../../../services/budget_service.dart';
import '../../../widgets/phobes_form_wrapper.dart';
import '../../../widgets/phobes_widgets.dart';
import '../../../utils/budget_currency_utils.dart';
import 'package:phobes/l10n/app_localizations.dart';

class BudgetOverviewTab extends StatefulWidget {
  final BudgetService budgetService;
  final String? selectedAccountId;
  final VoidCallback? onAccountClear;

  const BudgetOverviewTab({
    super.key,
    required this.budgetService,
    this.selectedAccountId,
    this.onAccountClear,
  });

  @override
  State<BudgetOverviewTab> createState() => BudgetOverviewTabState();
}

class BudgetOverviewTabState extends State<BudgetOverviewTab> {
  BudgetService get _budgetService => widget.budgetService;

  String _selectedFilter = 'all';
  int _touchedIndex = -1;
  String? _selectedCategory;
  String _searchQuery = '';
  DateTime? _filterDateStart;
  DateTime? _filterDateEnd;

  // Streams — initState'te bir kez oluşturulur, 7 ayrı bağlantı yerine 3 paylaşımlı abonelik
  late final Stream<List<BudgetTransaction>> _txStream;
  late final Stream<List<Account>> _accountsStream;
  late final Stream<List<BudgetLimit>> _limitsStream;
  // Döviz kurları — her build'de API çağrısı yapmak yerine bir kez çekilir
  late final Future<List<double?>> _liveRatesFuture;

  void _onCurrencyChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _budgetService.baseCurrency.addListener(_onCurrencyChanged);
    _txStream = _budgetService.getTransactionsStream().asBroadcastStream();
    _accountsStream = _budgetService.getAccountsStream().asBroadcastStream();
    _limitsStream = _budgetService.getLimitsStream().asBroadcastStream();
    _liveRatesFuture = Future.wait([
      _budgetService.getCurrencyService().getLivePrice('USD', 'currency'),
      _budgetService.getCurrencyService().getLivePrice('EUR', 'currency'),
      _budgetService.getCurrencyService().getLivePrice('GBP', 'currency'),
    ]);
  }

  @override
  void dispose() {
    _budgetService.baseCurrency.removeListener(_onCurrencyChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Builder(
      builder: (context) => CustomScrollView(
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          _buildHeroCard(cs),
          _buildQuickActions(cs),
          _buildLiveRatesRow(cs),
          _buildSummaryCards(cs),
          _buildAnalysisSection(cs),
          _buildLimitsSection(cs),
          _buildTransactionsFilter(cs),
          _buildTransactionList(cs),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ─── Hero Card ─────────────────────────────────────────────────────────────

  Widget _buildHeroCard(ColorScheme cs) {
    return SliverToBoxAdapter(
      child: StreamBuilder<List<Account>>(
        stream: _accountsStream,
        builder: (context, accSnap) {
          return StreamBuilder<List<BudgetTransaction>>(
            stream: _txStream,
            builder: (context, txSnap) {
              final accounts = accSnap.data ?? [];
              final txs = txSnap.data ?? [];
              final baseCcy = _budgetService.baseCurrency.value;

              final netWorth = accounts.fold(0.0, (s, a) => s + a.balance);
              final totalAssets = accounts
                  .where((a) => a.balance > 0)
                  .fold(0.0, (s, a) => s + a.balance);
              final totalLiabilities = accounts
                  .where((a) => a.balance < 0)
                  .fold(0.0, (s, a) => s + a.balance.abs());

              final now = DateTime.now();
              final thisMonthIncome = txs
                  .where((t) =>
                      t.date.year == now.year &&
                      t.date.month == now.month &&
                      t.type == TransactionType.income)
                  .fold(0.0, (s, t) => s + t.amount);
              final thisMonthExpense = txs
                  .where((t) =>
                      t.date.year == now.year &&
                      t.date.month == now.month &&
                      t.type == TransactionType.expense)
                  .fold(0.0, (s, t) => s + t.amount);

              // Savings rate this month
              final savingsRate = thisMonthIncome > 0
                  ? ((thisMonthIncome - thisMonthExpense) / thisMonthIncome * 100)
                      .clamp(-999.0, 100.0)
                  : 0.0;
              final l10n = AppLocalizations.of(context)!;

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary,
                        Color.lerp(cs.primary, Colors.indigo.shade900, 0.55)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.45),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative background circles
                      Positioned(
                        top: -30,
                        right: -20,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -50,
                        right: 60,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.netWorth,
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (savingsRate != 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        savingsRate >= 0
                                            ? Icons.trending_up_rounded
                                            : Icons.trending_down_rounded,
                                        color: savingsRate >= 0
                                            ? Colors.greenAccent.shade100
                                            : Colors.redAccent.shade100,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${savingsRate >= 0 ? '+' : ''}${savingsRate.toStringAsFixed(1)}% ${l10n.kpiNetSavings.toLowerCase()}',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: netWorth),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => Text(
                              formatCurrency(v, baseCcy),
                              style: GoogleFonts.outfit(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // This-month stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildHeroStatBox(
                                  '↓ ${l10n.kpiMonthlyIncome}',
                                  thisMonthIncome,
                                  Colors.greenAccent.shade100,
                                  baseCcy,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildHeroStatBox(
                                  '↑ ${l10n.kpiMonthlyExpense}',
                                  thisMonthExpense,
                                  Colors.redAccent.shade100,
                                  baseCcy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Assets / Liabilities chips
                          Row(
                            children: [
                              _buildHeroChip(
                                  l10n.totalAssets,
                                  totalAssets,
                                  Colors.greenAccent.shade100,
                                  baseCcy),
                              const SizedBox(width: 8),
                              _buildHeroChip(
                                  l10n.totalLiabilities,
                                  totalLiabilities,
                                  Colors.redAccent.shade100,
                                  baseCcy),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeroStatBox(
      String label, double amount, Color color, String? ccy) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          Text(
            formatCurrency(amount, ccy),
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(
      String label, double amount, Color color, String? ccy) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$label  ${formatCurrency(amount, ccy)}',
                style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Quick Actions ──────────────────────────────────────────────────────────

  Widget _buildQuickActions(ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            Expanded(
              child: _buildQuickActionBtn(
                cs,
                Icons.add_circle_outline_rounded,
                l10n.aiLabelAddIncome,
                Colors.green,
                () => showAddTransactionSheet(context,
                    initialType: TransactionType.income),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionBtn(
                cs,
                Icons.remove_circle_outline_rounded,
                l10n.aiLabelAddExpense,
                Colors.red,
                () => showAddTransactionSheet(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionBtn(
                cs,
                Icons.swap_horiz_rounded,
                'Transfer',
                cs.primary,
                () => showAddTransactionSheet(context,
                    initialType: TransactionType.transfer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(ColorScheme cs, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.18), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Live Rates ─────────────────────────────────────────────────────────────

  Widget _buildLiveRatesRow(ColorScheme cs) {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<double?>>(
        future: _liveRatesFuture,
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          final labels = ['USD', 'EUR', 'GBP'];
          final icons = ['🇺🇸', '🇪🇺', '🇬🇧'];
          final validRates = snap.data!
              .asMap()
              .entries
              .where((e) => e.value != null)
              .toList();
          if (validRates.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 0, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...validRates.map((e) {
                    final rate = e.value!;
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: cs.outline.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(icons[e.key],
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            '1 ${labels[e.key]} = ₺${rate.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Summary Cards ──────────────────────────────────────────────────────────

  Widget _buildSummaryCards(ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return SliverToBoxAdapter(
      child: StreamBuilder<List<BudgetTransaction>>(
        stream: _txStream,
        builder: (context, snapshot) {
          double totalIncome = 0;
          double totalExpense = 0;
          double prevIncome = 0;
          double prevExpense = 0;
          final now = DateTime.now();
          final prevMonth =
              DateTime(now.month == 1 ? now.year - 1 : now.year,
                  now.month == 1 ? 12 : now.month - 1);

          if (snapshot.hasData) {
            for (final tx in snapshot.data!) {
              final isThisMonth =
                  tx.date.year == now.year && tx.date.month == now.month;
              final isPrevMonth = tx.date.year == prevMonth.year &&
                  tx.date.month == prevMonth.month;
              if (tx.type == TransactionType.income) {
                if (isThisMonth) totalIncome += tx.amount;
                if (isPrevMonth) prevIncome += tx.amount;
              } else if (tx.type == TransactionType.expense) {
                if (isThisMonth) totalExpense += tx.amount;
                if (isPrevMonth) prevExpense += tx.amount;
              }
            }
          }

          final baseCcy = _budgetService.baseCurrency.value;
          final incomeChange = prevIncome > 0
              ? ((totalIncome - prevIncome) / prevIncome * 100)
              : null;
          final expenseChange = prevExpense > 0
              ? ((totalExpense - prevExpense) / prevExpense * 100)
              : null;
          final balance = totalIncome - totalExpense;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        cs,
                        label: l10n.kpiMonthlyIncome,
                        amount: totalIncome,
                        change: incomeChange,
                        isExpense: false,
                        currency: baseCcy,
                        isSelected: _selectedFilter == 'income',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedFilter =
                              _selectedFilter == 'income' ? 'all' : 'income');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        cs,
                        label: l10n.kpiMonthlyExpense,
                        amount: totalExpense,
                        change: expenseChange,
                        isExpense: true,
                        currency: baseCcy,
                        isSelected: _selectedFilter == 'expense',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedFilter =
                              _selectedFilter == 'expense' ? 'all' : 'expense');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBalanceBar(cs, totalIncome, totalExpense, balance, baseCcy),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    ColorScheme cs, {
    required String label,
    required double amount,
    required double? change,
    required bool isExpense,
    required String? currency,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = isExpense ? Colors.redAccent : Colors.green;
    final gradient = isSelected
        ? LinearGradient(
            colors: isExpense
                ? [Colors.redAccent.shade400, Colors.red.shade700]
                : [Colors.green.shade400, Colors.green.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          color: isSelected ? null : cs.onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : activeColor.withOpacity(0.15),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : activeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isExpense
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: isSelected ? Colors.white : activeColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: isSelected
                          ? Colors.white.withOpacity(0.85)
                          : cs.onSurface.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: amount),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(
                formatCurrency(v, currency),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isSelected ? Colors.white : cs.onSurface,
                ),
              ),
            ),
            if (change != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    change >= 0
                        ? Icons.arrow_drop_up_rounded
                        : Icons.arrow_drop_down_rounded,
                    size: 16,
                    color: isSelected
                        ? Colors.white.withOpacity(0.7)
                        : (isExpense
                            ? (change >= 0 ? Colors.red : Colors.green)
                            : (change >= 0 ? Colors.green : Colors.red)),
                  ),
                  Text(
                    '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white.withOpacity(0.7)
                          : cs.onSurface.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceBar(ColorScheme cs, double income, double expense,
      double balance, String? currency) {
    final l10n = AppLocalizations.of(context)!;
    if (income == 0 && expense == 0) return const SizedBox.shrink();
    final total = income + expense;
    final incomeRatio = total > 0 ? income / total : 0.5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.budgetCashFlow,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.7))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: balance >= 0
                      ? Colors.green.withOpacity(0.12)
                      : Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${balance >= 0 ? '+' : ''}${formatCurrency(balance, currency)}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: incomeRatio.toDouble()),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, ratio, __) => Row(
                children: [
                  Expanded(
                    flex: (ratio * 100).round(),
                    child: Container(height: 8, color: Colors.green),
                  ),
                  Expanded(
                    flex: ((1 - ratio) * 100).round().clamp(1, 99),
                    child: Container(height: 8, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBarLegend(l10n.budgetIncomeLegend, Colors.green),
              const SizedBox(width: 16),
              _buildBarLegend(l10n.budgetExpenseLegend, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      ],
    );
  }

  // ─── Analysis Section ────────────────────────────────────────────────────────

  Widget _buildAnalysisSection(ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return SliverToBoxAdapter(
      child: StreamBuilder<List<BudgetTransaction>>(
        stream: _txStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }

          final expenses = snapshot.data!
              .where((tx) => tx.type == TransactionType.expense)
              .toList();
          if (expenses.isEmpty) return const SizedBox.shrink();

          final Map<String, double> categoryMap = {};
          double totalExpense = 0;
          for (final tx in expenses) {
            categoryMap[tx.category] =
                (categoryMap[tx.category] ?? 0) + tx.amount;
            totalExpense += tx.amount;
          }

          final categories = categoryMap.keys.toList()
            ..sort((a, b) => categoryMap[b]!.compareTo(categoryMap[a]!));
          final baseCcy = _budgetService.baseCurrency.value;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.outline.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(2),
                          )),
                      const SizedBox(width: 10),
                      Text(l10n.expenseDistribution,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback:
                                    (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    final idx = pieTouchResponse
                                        .touchedSection!.touchedSectionIndex;
                                    if (_touchedIndex == idx) {
                                      _touchedIndex = -1;
                                      _selectedCategory = null;
                                    } else {
                                      _touchedIndex = idx;
                                      if (idx >= 0 &&
                                          idx < categories.length) {
                                        _selectedCategory = categories[idx];
                                      }
                                    }
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 3,
                              centerSpaceRadius: 44,
                              sections: List.generate(categories.length, (i) {
                                final isTouched = i == _touchedIndex;
                                final cat = categories[i];
                                final amount = categoryMap[cat]!;
                                final percentage =
                                    (amount / totalExpense * 100)
                                        .toStringAsFixed(0);
                                final color = Colors
                                    .primaries[i % Colors.primaries.length];

                                return PieChartSectionData(
                                  color: color,
                                  value: amount,
                                  title: isTouched ? '$percentage%' : '',
                                  radius: isTouched ? 62.0 : 50.0,
                                  titleStyle: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  badgeWidget: isTouched
                                      ? null
                                      : null,
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...categories.take(5).map((cat) {
                                final i = categories.indexOf(cat);
                                final amount = categoryMap[cat]!;
                                final pct = amount / totalExpense * 100;
                                final color = Colors
                                    .primaries[i % Colors.primaries.length];
                                final isSelected = _selectedCategory == cat;
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedCategory =
                                        _selectedCategory == cat ? null : cat;
                                    _touchedIndex = isSelected ? -1 : i;
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color.withOpacity(0.12)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            cat,
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${pct.toStringAsFixed(0)}%',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                cs.onSurface.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              if (categories.length > 5)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4, left: 8),
                                  child: Text(
                                    '+${categories.length - 5} daha',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: cs.onSurface.withOpacity(0.4),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Selected category detail
                  if (_selectedCategory != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.category_rounded,
                              size: 16, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            '$_selectedCategory: ${formatCurrency(categoryMap[_selectedCategory]!, baseCcy)}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Limits Section ──────────────────────────────────────────────────────────

  Widget _buildLimitsSection(ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return SliverToBoxAdapter(
      child: StreamBuilder<List<BudgetLimit>>(
        stream: _limitsStream,
        builder: (context, limitSnapshot) {
          return StreamBuilder<List<BudgetTransaction>>(
            stream: _txStream,
            builder: (context, txSnapshot) {
              if (!limitSnapshot.hasData || limitSnapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: GestureDetector(
                    onTap: () => _showAddLimitSheet(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded,
                              color: cs.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l10n.budgetAddLimit,
                            style: GoogleFonts.outfit(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final limits = limitSnapshot.data!;
              final expenses = (txSnapshot.data ?? [])
                  .where((tx) => tx.type == TransactionType.expense)
                  .toList();

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(2),
                                )),
                            const SizedBox(width: 10),
                            Text(l10n.budgetLimitsTitle,
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        PhobesIconButton(
                          icon: Icons.add_rounded,
                          onTap: () => _showAddLimitSheet(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final columns = width >= 1100
                            ? 3
                            : width >= 700
                                ? 2
                                : 1;
                        const spacing = 10.0;
                        final cardWidth = columns == 1
                            ? width
                            : (width - spacing * (columns - 1)) / columns;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: limits
                              .map(
                                (limit) => SizedBox(
                                  width: cardWidth,
                                  child: _buildLimitCard(
                                    cs: cs,
                                    l10n: l10n,
                                    limit: limit,
                                    expenses: expenses,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLimitCard({
    required ColorScheme cs,
    required AppLocalizations l10n,
    required BudgetLimit limit,
    required List<BudgetTransaction> expenses,
  }) {
    final spent = BudgetPeriodUtils.spentInCategory(
      expenses,
      limit.category,
      limit.period,
    );
    final percent = (spent / limit.limitAmount).clamp(0.0, 1.0);
    final isOver = spent > limit.limitAmount;
    final isWarning = spent > limit.limitAmount * 0.8;
    final progressColor = isOver
        ? Colors.red
        : isWarning
            ? Colors.orange
            : cs.primary;

    return GestureDetector(
      onLongPress: () async {
        final confirmed = await PhobesBottomSheet.confirm(
          context: context,
          title: l10n.budgetDeleteLimitTitle,
          message: l10n.budgetDeleteLimitMessage(limit.category),
        );
        if (confirmed == true) {
          await _budgetService.deleteLimit(limit.id!);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOver
                ? Colors.red.withOpacity(0.3)
                : cs.outline.withOpacity(0.06),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: progressColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.price_change_rounded,
                          size: 14,
                          color: progressColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          limit.category,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(
                        spent,
                        _budgetService.baseCurrency.value,
                      ),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: progressColor,
                      ),
                    ),
                    Text(
                      '/ ${formatCurrency(limit.limitAmount, _budgetService.baseCurrency.value)}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: cs.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearPercentIndicator(
                lineHeight: 8.0,
                percent: percent,
                padding: EdgeInsets.zero,
                barRadius: const Radius.circular(4),
                backgroundColor: cs.outline.withOpacity(0.08),
                linearGradient: LinearGradient(
                  colors: [
                    progressColor.withOpacity(0.7),
                    progressColor,
                  ],
                ),
                animation: true,
              ),
            ),
            if (isOver) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 12,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      l10n.budgetLimitExceeded(
                        formatCurrency(
                          spent - limit.limitAmount,
                          _budgetService.baseCurrency.value,
                        ),
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddLimitSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController();
    String selectedCategory = 'Yemek';

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => PhobesBottomSheet(
          title: l10n.budgetAddLimit,
          child: Column(
            children: [
              _buildCategorySelector(setModalState, selectedCategory,
                  (val) => selectedCategory = val),
              const SizedBox(height: 12),
              PhobesTextField(
                controller: amountController,
                hintText: l10n.budgetLimitAmountHint(
                    getCurrencySymbol(_budgetService.baseCurrency.value)),
                prefixIcon: Icons.money_off_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              PhobesButton(
                text: l10n.budgetSaveLimit,
                width: double.infinity,
                onPressed: () async {
                  if (amountController.text.isEmpty) return;
                  final limitAmount = double.tryParse(amountController.text);
                  if (limitAmount == null || limitAmount <= 0) return;
                  final limit = BudgetLimit(
                    userId: _budgetService.currentUserId!,
                    category: selectedCategory,
                    limitAmount: limitAmount,
                  );
                  await _budgetService.addLimit(limit);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => amountController.dispose());
  }

  // ─── Transactions Filter ─────────────────────────────────────────────────────

  Widget _buildTransactionsFilter(ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(2),
                        )),
                    const SizedBox(width: 10),
                    Text(l10n.transactionHistory,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate:
                              DateTime.now().add(const Duration(days: 1)),
                          initialDateRange:
                              _filterDateStart != null && _filterDateEnd != null
                                  ? DateTimeRange(
                                      start: _filterDateStart!,
                                      end: _filterDateEnd!)
                                  : null,
                        );
                        if (range != null) {
                          setState(() {
                            _filterDateStart = range.start;
                            _filterDateEnd = range.end;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (_filterDateStart != null)
                              ? cs.primary.withOpacity(0.12)
                              : cs.onSurface.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: (_filterDateStart != null)
                                  ? cs.primary.withOpacity(0.3)
                                  : Colors.transparent),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.date_range_rounded,
                                size: 14,
                                color: (_filterDateStart != null)
                                    ? cs.primary
                                    : cs.onSurface.withOpacity(0.5)),
                            if (_filterDateStart != null) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _filterDateStart = null;
                                  _filterDateEnd = null;
                                }),
                                child: Icon(Icons.close_rounded,
                                    size: 12, color: cs.primary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (widget.selectedAccountId != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => widget.onAccountClear?.call(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: cs.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.filter_alt_off_rounded,
                                  size: 14, color: cs.primary),
                              const SizedBox(width: 4),
                              Text(l10n.clearAccount,
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            PhobesTextField(
              hintText: l10n.budgetSearchTransactionsHint,
              prefixIcon: Icons.search_rounded,
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(cs, l10n.categoryAll, 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip(cs, l10n.categoryIncomes, 'income',
                      icon: Icons.arrow_downward_rounded, color: Colors.green),
                  const SizedBox(width: 8),
                  _buildFilterChip(cs, l10n.categoryExpenses, 'expense',
                      icon: Icons.arrow_upward_rounded,
                      color: Colors.redAccent),
                  if (_selectedCategory != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedCategory = null;
                        _touchedIndex = -1;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.tertiary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: cs.tertiary.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.category_rounded,
                                size: 14, color: cs.tertiary),
                            const SizedBox(width: 4),
                            Text(_selectedCategory!,
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cs.tertiary)),
                            const SizedBox(width: 4),
                            Icon(Icons.close_rounded,
                                size: 12, color: cs.tertiary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(ColorScheme cs, String label, String value,
      {IconData? icon, Color? color}) {
    final isSelected = _selectedFilter == value;
    final activeColor = color ?? cs.primary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.15)
              : cs.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor.withOpacity(0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: isSelected
                      ? activeColor
                      : cs.onSurface.withOpacity(0.5)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? activeColor
                    : cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Transaction List ────────────────────────────────────────────────────────

  Widget _buildTransactionList(ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      sliver: StreamBuilder<List<BudgetTransaction>>(
        stream: _txStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return SliverToBoxAdapter(
              child: Center(
                  child: Text(l10n.budgetErrorWithDetail(
                      snapshot.error.toString()),
                      style:
                          GoogleFonts.outfit(color: Colors.red))),
            );
          }
          if (!snapshot.hasData) {
            return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()));
          }

          final allTxs = snapshot.data!;
          final txs = allTxs.where((tx) {
            if (widget.selectedAccountId != null &&
                tx.accountId != widget.selectedAccountId) {
              return false;
            }
            if (_selectedCategory != null &&
                tx.category != _selectedCategory) {
              return false;
            }
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              if (!tx.title.toLowerCase().contains(q) &&
                  !tx.category.toLowerCase().contains(q) &&
                  !tx.description.toLowerCase().contains(q)) {
                return false;
              }
            }
            if (_filterDateStart != null &&
                tx.date.isBefore(_filterDateStart!)) {
              return false;
            }
            if (_filterDateEnd != null) {
              final end = DateTime(_filterDateEnd!.year, _filterDateEnd!.month,
                  _filterDateEnd!.day, 23, 59, 59);
              if (tx.date.isAfter(end)) return false;
            }
            if (_selectedFilter == 'income') {
              return tx.type == TransactionType.income;
            }
            if (_selectedFilter == 'expense') {
              return tx.type == TransactionType.expense;
            }
            return true;
          }).toList();

          if (txs.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          size: 40,
                          color: cs.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFilter == 'all'
                            ? l10n.noTransactionsYet
                            : l10n.noTransactionsYet,
                        style: GoogleFonts.outfit(
                            color: cs.onSurface.withOpacity(0.4),
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return SliverLayoutBuilder(
            builder: (context, sliverConstraints) {
              final width = sliverConstraints.crossAxisExtent;
              final isWide = width >= 700;

              if (isWide) {
                final crossAxisCount = width >= 1500
                    ? 4
                    : width >= 1100
                        ? 3
                        : 2;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildTransactionCard(cs, txs[index], l10n),
                    childCount: txs.length,
                  ),
                );
              }

              // Group by date for mobile
              final grouped = _groupByDate(txs);
              final items = <_TxListItem>[];
              for (final entry in grouped.entries) {
                items.add(_TxListItem(isHeader: true, dateLabel: entry.key));
                for (final tx in entry.value) {
                  items.add(_TxListItem(isHeader: false, tx: tx));
                }
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    if (item.isHeader) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
                        child: Row(
                          children: [
                            Text(
                              item.dateLabel!,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface.withOpacity(0.45),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Divider(
                                  color: cs.outline.withOpacity(0.1)),
                            ),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildTransactionCard(cs, item.tx!, l10n),
                    );
                  },
                  childCount: items.length,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Map<String, List<BudgetTransaction>> _groupByDate(
      List<BudgetTransaction> txs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final result = <String, List<BudgetTransaction>>{};

    for (final tx in txs) {
      final d = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String label;
      final l10n = AppLocalizations.of(context)!;
      if (d == today) {
        label = l10n.budgetToday;
      } else if (d == yesterday) {
        label = l10n.budgetYesterday;
      } else {
        label = DateFormat(
                'd MMM yyyy', Localizations.localeOf(context).languageCode)
            .format(tx.date)
            .toUpperCase();
      }
      result.putIfAbsent(label, () => []).add(tx);
    }
    return result;
  }

  Widget _buildTransactionCard(
      ColorScheme cs, BudgetTransaction tx, AppLocalizations l10n) {
    final isExpense = tx.type == TransactionType.expense;
    final isTransfer = tx.type == TransactionType.transfer;
    final color = isTransfer
        ? cs.primary
        : isExpense
            ? Colors.red
            : Colors.green;
    final icon = isTransfer
        ? Icons.swap_horiz_rounded
        : isExpense
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded;

    return GestureDetector(
      onLongPress: () async {
        final action = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => PhobesBottomSheet(
            title: tx.title,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.edit_rounded, color: cs.primary),
                  title: Text(l10n.edit, style: GoogleFonts.outfit()),
                  onTap: () => Navigator.pop(context, 'edit'),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.delete_rounded, color: Colors.red),
                  title: Text(l10n.delete,
                      style: GoogleFonts.outfit(color: Colors.red)),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
              ],
            ),
          ),
        );
        if (!mounted) return;
        if (action == 'edit') {
          showAddTransactionSheet(context, existing: tx);
        } else if (action == 'delete' && tx.id != null) {
          final confirmed = await PhobesBottomSheet.confirm(
            context: context,
            title: l10n.deleteTransaction,
            message: l10n.deleteTransactionConfirm,
            confirmText: l10n.btnDelete,
            confirmColor: Colors.red,
          );
          if (confirmed == true && tx.id != null) {
            await _budgetService.deleteTransaction(tx.id!);
            if (!mounted) return;
            PhobesSnackbar.show(context,
                message: l10n.transactionDeleted,
                type: PhobesSnackbarType.success);
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            // Colored left accent bar
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tx.title,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tx.category,
                          style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: cs.onSurface.withOpacity(0.55),
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('d MMM',
                                Localizations.localeOf(context).languageCode)
                            .format(tx.date),
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: cs.onSurface.withOpacity(0.35)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${isExpense ? '−' : isTransfer ? '↔' : '+'}${formatCurrency(tx.amount, tx.currency ?? _budgetService.baseCurrency.value)}',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 14),
                  ),
                  if (tx.currency != null &&
                      tx.currency != _budgetService.baseCurrency.value)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(tx.currency!,
                          style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: cs.primary)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Public Sheet ─────────────────────────────────────────────────────────

  void showAddTransactionSheet(BuildContext context,
      {BudgetTransaction? existing,
      TransactionType initialType = TransactionType.expense}) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = existing != null;
    final titleController =
        TextEditingController(text: existing?.title ?? '');
    final amountController = TextEditingController(
        text: existing != null ? existing.amount.toStringAsFixed(0) : '');
    final descController =
        TextEditingController(text: existing?.description ?? '');
    TransactionType selectedType = existing?.type ?? initialType;
    String selectedCategory = existing?.category ?? 'Genel';
    String? selectedSubCategory = existing?.subCategory;
    String selectedRecurrence = existing?.recurrence ?? 'none';
    String selectedMethod = existing?.paymentMethod ?? 'cash';
    String? selectedAccountId = existing?.accountId;
    String? selectedToAccountId = existing?.toAccountId;
    DateTime selectedDate = existing?.date ?? DateTime.now();
    String selectedCurrency =
        existing?.currency ?? _budgetService.baseCurrency.value;

    PhobesFormWrapper.show(
      context,
      title: isEditing ? l10n.editTransaction : l10n.addNewTransaction,
      form: StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                Row(
                  children: [
                    Expanded(
                      child: PhobesButton(
                        text: l10n.categoryExpenses,
                        isOutlined: selectedType != TransactionType.expense,
                        onPressed: () => setModalState(
                            () => selectedType = TransactionType.expense),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PhobesButton(
                        text: l10n.categoryIncomes,
                        isOutlined: selectedType != TransactionType.income,
                        onPressed: () => setModalState(
                            () => selectedType = TransactionType.income),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PhobesButton(
                        text: 'Transfer',
                        isOutlined: selectedType != TransactionType.transfer,
                        onPressed: () => setModalState(
                            () => selectedType = TransactionType.transfer),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PhobesTextField(
                  controller: titleController,
                  hintText: l10n.hintTransactionTitle,
                  prefixIcon: Icons.title_rounded,
                ),
                const SizedBox(height: 12),
                PhobesTextField(
                  controller: amountController,
                  hintText:
                      l10n.hintAmount(getCurrencySymbol(selectedCurrency)),
                  prefixIcon: Icons.money_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = DateTime(
                          picked.year, picked.month, picked.day));
                    }
                  },
                  child: PhobesCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 18,
                            color:
                                Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('d MMM yyyy').format(selectedDate),
                          style: GoogleFonts.outfit(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PhobesTextField(
                  controller: descController,
                  hintText: l10n.hintDescription,
                  prefixIcon: Icons.description_rounded,
                ),
                const SizedBox(height: 12),
                _buildCategorySelector(setModalState, selectedCategory,
                    (val) => selectedCategory = val),
                const SizedBox(height: 12),
                PhobesTextField(
                  controller:
                      TextEditingController(text: selectedSubCategory),
                  hintText: l10n.hintSubCategory,
                  prefixIcon: Icons.subdirectory_arrow_right_rounded,
                  onChanged: (val) => selectedSubCategory = val,
                ),
                const SizedBox(height: 12),
                _buildAccountDropdown(setModalState, selectedAccountId,
                    (val) => selectedAccountId = val),
                if (selectedType == TransactionType.transfer) ...[
                  const SizedBox(height: 12),
                  _buildAccountDropdown(
                    setModalState,
                    selectedToAccountId,
                    (val) => selectedToAccountId = val,
                    label: l10n.budgetTargetAccount,
                  ),
                ],
                const SizedBox(height: 12),
                _buildCurrencySelector(setModalState, selectedCurrency,
                    (val) => selectedCurrency = val),
                const SizedBox(height: 12),
                _buildRecurrenceSelector(setModalState, selectedRecurrence,
                    (val) => selectedRecurrence = val),
                const SizedBox(height: 12),
                _buildMethodSelector(setModalState, selectedMethod,
                    (val) => selectedMethod = val),
                const SizedBox(height: 24),
                PhobesButton(
                  text: l10n.save,
                  width: double.infinity,
                  onPressed: () async {
                    if (titleController.text.isEmpty ||
                        amountController.text.isEmpty) {
                      return;
                    }
                    final amount =
                        double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) { return; }

                    final tx = BudgetTransaction(
                      userId: _budgetService.currentUserId!,
                      title: titleController.text,
                      amount: amount,
                      type: selectedType,
                      category: selectedCategory,
                      subCategory: selectedSubCategory,
                      date: selectedDate,
                      description: descController.text,
                      recurrence: selectedRecurrence,
                      paymentMethod: selectedMethod,
                      accountId: selectedAccountId,
                      toAccountId:
                          selectedType == TransactionType.transfer
                              ? selectedToAccountId
                              : null,
                      currency: selectedCurrency,
                    );

                    try {
                      if (isEditing) {
                        await _budgetService.replaceTransaction(existing, tx);
                      } else {
                        await _budgetService.addTransaction(tx);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        FirebaseErrors.showSnackBar(context, e);
                      }
                      return;
                    }

                    if (context.mounted) Navigator.pop(context);
                    if (context.mounted) {
                      PhobesSnackbar.show(context,
                          message: isEditing
                              ? l10n.budgetTransactionUpdated
                              : l10n.budgetTransactionAdded,
                          type: PhobesSnackbarType.success);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
    ).whenComplete(() {
      titleController.dispose();
      amountController.dispose();
      descController.dispose();
    });
  }

  // ─── Helper Selectors (unchanged) ───────────────────────────────────────────

  Widget _buildCurrencySelector(
      StateSetter setModalState, String current, Function(String) onSelect) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.budgetCurrency,
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6))),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: kSupportedCurrencies.map((code) {
              final isSelected = current == code;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${getCurrencySymbol(code)} $code',
                      style:
                          GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  selected: isSelected,
                  onSelected: (_) => setModalState(() => onSelect(code)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecurrenceSelector(
      StateSetter setModalState, String current, Function(String) onSelect) {
    final l10n = AppLocalizations.of(context)!;
    final recurrences = {
      'none': l10n.budgetRecurrenceNone,
      'daily': l10n.budgetRecurrenceDaily,
      'weekly': l10n.budgetRecurrenceWeekly,
      'monthly': l10n.budgetRecurrenceMonthly,
      'yearly': l10n.budgetRecurrenceYearly,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.budgetRecurrence,
            style: GoogleFonts.outfit(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6))),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: recurrences.entries.map((e) {
              final isSelected = current == e.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label:
                      Text(e.value, style: GoogleFonts.outfit(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (val) =>
                      setModalState(() => onSelect(e.key)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodSelector(
      StateSetter setModalState, String current, Function(String) onSelect) {
    final l10n = AppLocalizations.of(context)!;
    final methods = {
      'cash': l10n.budgetMethodCash,
      'credit_card': l10n.budgetMethodCreditCard,
      'bank_transfer': l10n.budgetMethodBankTransfer,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.budgetPaymentMethod,
            style: GoogleFonts.outfit(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6))),
        const SizedBox(height: 8),
        Row(
          children: methods.entries.map((e) {
            final isSelected = current == e.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label:
                    Text(e.value, style: GoogleFonts.outfit(fontSize: 12)),
                selected: isSelected,
                onSelected: (val) => setModalState(() => onSelect(e.key)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.money_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      case AccountType.investment:
        return Icons.trending_up_rounded;
    }
  }

  String _budgetCategoryLabel(AppLocalizations l10n, String category) {
    switch (category) {
      case 'Genel':
        return l10n.budgetCatGeneral;
      case 'Yemek':
        return l10n.budgetCatFood;
      case 'Market':
        return l10n.budgetCatGroceries;
      case 'Ulaşım':
        return l10n.budgetCatTransport;
      case 'Eğlence':
        return l10n.budgetCatEntertainment;
      case 'Kira':
        return l10n.budgetCatRent;
      case 'Fatura':
        return l10n.budgetCatBills;
      case 'Sağlık':
        return l10n.budgetCatHealth;
      case 'Maaş':
        return l10n.budgetCatSalary;
      case 'Diğer':
        return l10n.budgetCatOther;
      default:
        return category;
    }
  }

  Widget _buildCategorySelector(
      StateSetter setModalState, String current, Function(String) onSelect) {
    final l10n = AppLocalizations.of(context)!;
    const categories = kBudgetCategoryStorageKeys;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(l10n.budgetCategory,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.7),
              )),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSelected = current == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_budgetCategoryLabel(l10n, cat),
                      style: GoogleFonts.outfit(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    if (selected) setModalState(() => onSelect(cat));
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountDropdown(
      StateSetter setModalState, String? current, Function(String?) onSelect,
      {String? label}) {
    return StreamBuilder<List<Account>>(
      stream: _accountsStream,
      builder: (context, snapshot) {
        final accounts = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label ?? AppLocalizations.of(context)!.budgetPaymentAccount,
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6))),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...accounts.map((acc) {
                    final isSelected = current == acc.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(_getAccountIcon(acc.type), size: 14),
                        label: Text(acc.name,
                            style: GoogleFonts.outfit(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (val) => setModalState(
                            () => onSelect(val ? acc.id : null)),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Helper class for grouped transaction list
class _TxListItem {
  final bool isHeader;
  final String? dateLabel;
  final BudgetTransaction? tx;
  const _TxListItem({required this.isHeader, this.dateLabel, this.tx});
}
