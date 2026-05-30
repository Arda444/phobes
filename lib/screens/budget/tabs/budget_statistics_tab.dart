import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:phobes/l10n/app_localizations.dart';

import '../../../models/budget_model.dart';
import '../../../services/budget_service.dart';
import '../../../utils/budget_currency_utils.dart';

class BudgetStatisticsTab extends StatefulWidget {
  final BudgetService budgetService;
  final ColorScheme cs;

  const BudgetStatisticsTab({
    super.key,
    required this.budgetService,
    required this.cs,
  });

  @override
  State<BudgetStatisticsTab> createState() => _BudgetStatisticsTabState();
}

class _BudgetStatisticsTabState extends State<BudgetStatisticsTab> {
  List<BudgetTransaction>? _cachedTxs;
  List<Account>? _cachedAccounts;
  late List<Map<String, dynamic>> _cachedTrend;
  late Map<String, dynamic> _cachedSankey;
  late Map<String, double> _cachedForecast;
  late List<Map<String, dynamic>> _cachedAnomalies;
  late Map<String, double> _cachedDistribution;
  late Map<String, double> _cachedRecurring;
  Widget? _cachedKpisWidget;
  String? _analyticsCachePeriod;

  // Period filter: 'month' | 'quarter' | 'year' | 'all'
  String _period = 'month';

  List<(String, String)> _periodOptions(AppLocalizations l10n) => [
        ('month', l10n.budgetPeriodMonth),
        ('quarter', l10n.budgetPeriodQuarter),
        ('year', l10n.budgetPeriodYear),
        ('all', l10n.budgetPeriodAll),
      ];

  late final Stream<List<BudgetTransaction>> _txStream;
  late final Stream<List<Account>> _accountsStream;

  @override
  void initState() {
    super.initState();
    widget.budgetService.baseCurrency.addListener(_onCurrencyChanged);
    _txStream = widget.budgetService.getTransactionsStream().asBroadcastStream();
    _accountsStream = widget.budgetService.getAccountsStream().asBroadcastStream();
  }

  @override
  void dispose() {
    widget.budgetService.baseCurrency.removeListener(_onCurrencyChanged);
    super.dispose();
  }

  void _onCurrencyChanged() {
    if (mounted) setState(() => _cachedKpisWidget = null);
  }

  List<BudgetTransaction> _filterByPeriod(List<BudgetTransaction> all) {
    final now = DateTime.now();
    return all.where((t) {
      switch (_period) {
        case 'month':
          return t.date.year == now.year && t.date.month == now.month;
        case 'quarter':
          final qStart = DateTime(now.year,
              ((now.month - 1) ~/ 3) * 3 + 1);
          return !t.date.isBefore(qStart);
        case 'year':
          return t.date.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BudgetTransaction>>(
      stream: _txStream,
      builder: (context, txSnap) {
        return StreamBuilder<List<Account>>(
          stream: _accountsStream,
          builder: (context, accSnap) {
            if (!txSnap.hasData || !accSnap.hasData) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 200, 20, 20),
                child: Column(
                  children: List.generate(
                    3,
                    (_) => Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      height: 160,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.06),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              );
            }

            final allTxs = txSnap.data!;
            final accounts = accSnap.data!;
            final txs = _filterByPeriod(allTxs);

            if (!identical(allTxs, _cachedTxs) ||
                !identical(accounts, _cachedAccounts) ||
                _analyticsCachePeriod != _period) {
              _cachedTxs = allTxs;
              _cachedAccounts = accounts;
              _analyticsCachePeriod = _period;
              final periodTxs = _filterByPeriod(allTxs);
              _cachedTrend =
                  widget.budgetService.getMonthlyTrendLocal(periodTxs, 6);
              _cachedSankey =
                  widget.budgetService.getSankeyDataLocal(periodTxs);
              final periodStart = _periodReference();
              final periodDays = _period == 'year'
                  ? (DateTime.now().difference(DateTime(DateTime.now().year)).inDays + 1)
                  : (_period == 'quarter'
                      ? (DateTime.now().difference(periodStart).inDays + 1)
                      : DateTime.now().day);
              _cachedForecast = widget.budgetService.getForecastDataLocal(
                periodTxs,
                periodStart: periodStart,
                periodDays: periodDays,
              );
              _cachedAnomalies =
                  widget.budgetService.getAnomaliesLocal(periodTxs);
              _cachedDistribution =
                  widget.budgetService.getAssetDistributionLocal(accounts);
              _cachedRecurring =
                  widget.budgetService.getRecurringAnalyticsLocal(periodTxs);
              _cachedKpisWidget = null;
            }

            final trend = _cachedTrend;
            final sankey = _cachedSankey;
            final forecast = _cachedForecast;
            final anomalies = _cachedAnomalies;
            final distribution = _cachedDistribution;
            final recurring = _cachedRecurring;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;
                final l10n = AppLocalizations.of(context)!;

                final charts = [
                  _buildChartContainer(
                      title: l10n.gaugeBudgetHiz,
                      cs: widget.cs,
                      child: _buildForecastGaugeLocal(widget.cs, forecast)),
                  _buildChartContainer(
                      title: l10n.moneyJourney,
                      cs: widget.cs,
                      child: _buildSankeySectionLocal(
                          widget.cs, sankey, l10n)),
                  _buildChartContainer(
                      title: l10n.incomeVsExpenseTrend,
                      cs: widget.cs,
                      child:
                          _buildTrendChartLocal(widget.cs, trend)),
                  _buildChartContainer(
                      title: l10n.anomalyTracking,
                      cs: widget.cs,
                      child: _buildAnomalySectionLocal(
                          widget.cs, anomalies, l10n)),
                  _buildChartContainer(
                      title: l10n.assetTreemap,
                      cs: widget.cs,
                      child: _buildAssetTreemapLocal(
                          widget.cs, distribution)),
                  _buildChartContainer(
                      title: l10n.dailyHeatmap,
                      cs: widget.cs,
                      child: _buildDailyHeatmapLocal(widget.cs, allTxs)),
                  _buildChartContainer(
                      title: l10n.recurringAnalysis,
                      cs: widget.cs,
                      child: _buildRecurringSectionLocal(
                          widget.cs, recurring)),
                ];

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          height:
                              MediaQuery.of(context).padding.top + 190),
                      // Period selector
                      _buildPeriodSelector(),
                      const SizedBox(height: 20),
                      Text(l10n.financialAnalysis,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      const SizedBox(height: 16),
                      _cachedKpisWidget ??=
                          _buildProfessionalKpisLocal(widget.cs, txs, allTxs),
                      const SizedBox(height: 24),
                      if (isWide)
                        ...List.generate((charts.length / 2).ceil(),
                            (row) {
                          final left = charts[row * 2];
                          final right = row * 2 + 1 < charts.length
                              ? charts[row * 2 + 1]
                              : null;
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: 20),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(child: left),
                                if (right != null) ...[
                                  const SizedBox(width: 16),
                                  Expanded(child: right),
                                ] else
                                  const Expanded(child: SizedBox()),
                              ],
                            ),
                          );
                        })
                      else
                        ...charts
                            .expand((c) => [c, const SizedBox(height: 20)])
                            .toList()
                          ..removeLast(),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    final l10n = AppLocalizations.of(context)!;
    final cs = widget.cs;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.07),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: _periodOptions(l10n).map((p) {
          final isSelected = _period == p.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _period = p.$1;
                _cachedKpisWidget = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    p.$2,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : cs.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<BudgetTransaction> _previousPeriodTxs(List<BudgetTransaction> all) {
    final now = DateTime.now();
    switch (_period) {
      case 'quarter':
        final qStart =
            DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1);
        final prevStart = DateTime(qStart.year, qStart.month - 3);
        final prevEnd = qStart.subtract(const Duration(days: 1));
        return all
            .where(
              (t) =>
                  !t.date.isBefore(prevStart) &&
                  !t.date.isAfter(
                    DateTime(prevEnd.year, prevEnd.month, prevEnd.day, 23, 59),
                  ),
            )
            .toList();
      case 'year':
        return all.where((t) => t.date.year == now.year - 1).toList();
      default:
        final prevMonth = DateTime(
          now.month == 1 ? now.year - 1 : now.year,
          now.month == 1 ? 12 : now.month - 1,
        );
        return all
            .where(
              (t) =>
                  t.date.year == prevMonth.year &&
                  t.date.month == prevMonth.month,
            )
            .toList();
    }
  }

  DateTime _periodReference() {
    final now = DateTime.now();
    switch (_period) {
      case 'year':
        return DateTime(now.year);
      case 'quarter':
        return DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1);
      default:
        return DateTime(now.year, now.month);
    }
  }

  Widget _buildProfessionalKpisLocal(
    ColorScheme cs,
    List<BudgetTransaction> txs,
    List<BudgetTransaction> allTxs,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final prevTxs = _previousPeriodTxs(allTxs);

    final thisMonthExp = txs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final thisMonthInc = txs
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);

    final prevMonthExp = prevTxs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final prevMonthInc = prevTxs
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);

    final thisMonthSavings = thisMonthInc - thisMonthExp;
    final periodDays = _period == 'year'
        ? (now.difference(DateTime(now.year)).inDays + 1)
        : (_period == 'quarter'
            ? (now.difference(_periodReference()).inDays + 1)
            : now.day);
    final avgDaily = periodDays > 0 ? thisMonthExp / periodDays : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: l10n.kpiMonthlyExpense,
                value: formatCurrency(thisMonthExp,
                    widget.budgetService.baseCurrency.value),
                subtitle: prevMonthExp == 0
                    ? l10n.apptTagNew
                    : '${((thisMonthExp / prevMonthExp - 1) * 100).toStringAsFixed(1)}%',
                isExpenseIncrease: thisMonthExp > prevMonthExp,
                cs: cs,
                icon: Icons.arrow_upward_rounded,
                iconColor: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: l10n.kpiMonthlyIncome,
                value: formatCurrency(thisMonthInc,
                    widget.budgetService.baseCurrency.value),
                subtitle: prevMonthInc == 0
                    ? l10n.apptTagNew
                    : '${((thisMonthInc / prevMonthInc - 1) * 100).toStringAsFixed(1)}%',
                isExpenseIncrease: thisMonthInc < prevMonthInc,
                cs: cs,
                icon: Icons.arrow_downward_rounded,
                iconColor: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: l10n.kpiNetSavings,
                value: formatCurrency(thisMonthSavings,
                    widget.budgetService.baseCurrency.value),
                subtitle: _period == 'year'
                    ? l10n.budgetPeriodYear
                    : (_period == 'quarter'
                        ? l10n.budgetPeriodQuarter
                        : l10n.budgetPeriodMonth),
                isExpenseIncrease: thisMonthSavings < 0,
                cs: cs,
                icon: Icons.savings_rounded,
                iconColor: cs.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: l10n.kpiDailyAvg,
                value: formatCurrency(
                    avgDaily, widget.budgetService.baseCurrency.value),
                subtitle: l10n.kpiDailyAvg,
                isExpenseIncrease: false,
                cs: cs,
                icon: Icons.today_rounded,
                iconColor: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required bool isExpenseIncrease,
    required ColorScheme cs,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: cs.onSurface.withOpacity(0.55))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isExpenseIncrease
                    ? Icons.trending_up
                    : Icons.trending_down,
                size: 13,
                color: isExpenseIncrease ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(subtitle,
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: isExpenseIncrease
                          ? Colors.red
                          : Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChartLocal(
      ColorScheme cs, List<Map<String, dynamic>> trend) {
    if (trend.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: cs.outline.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  String text = '';
                  if (value >= 1000) {
                    text = '${(value / 1000).toStringAsFixed(0)}K';
                  } else if (value <= -1000) {
                    text = '${(value / 1000).toStringAsFixed(0)}K';
                  } else {
                    text = value.toStringAsFixed(0);
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(text,
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: cs.onSurface.withOpacity(0.5))),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 ||
                      value.toInt() >= trend.length) {
                    return const SizedBox();
                  }
                  final month =
                      trend[value.toInt()]['month'] as DateTime;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(DateFormat('MMM').format(month),
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: cs.onSurface.withOpacity(0.5))),
                  );
                },
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: trend.asMap().entries.map((e) {
                return FlSpot(
                    e.key.toDouble(), e.value['income']);
              }).toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withOpacity(0.2),
                    Colors.green.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            LineChartBarData(
              spots: trend.asMap().entries.map((e) {
                return FlSpot(
                    e.key.toDouble(), e.value['expense']);
              }).toList(),
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.15),
                    Colors.red.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastGaugeLocal(
      ColorScheme cs, Map<String, double> data) {
    final l10n = AppLocalizations.of(context)!;
    if (data.isEmpty) return const SizedBox.shrink();

    final current = data['current'] ?? 0;
    final forecast = data['forecast'] ?? 0;
    final avgDaily = data['avgDaily'] ?? 0;

    return Column(
      children: [
        CircularPercentIndicator(
          radius: 80.0,
          lineWidth: 12.0,
          percent: (current / (forecast > 0 ? forecast : 1)).clamp(0, 1),
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  formatCurrency(forecast - current,
                      widget.budgetService.baseCurrency.value),
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 22)),
              Text(l10n.kpiRemainingLimit,
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: cs.onSurface.withOpacity(0.5))),
            ],
          ),
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: cs.primary.withOpacity(0.05),
          progressColor:
              (current > forecast) ? Colors.red : cs.primary,
          animation: true,
          animationDuration: 1000,
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildGaugeStat(
                formatCurrency(avgDaily,
                    widget.budgetService.baseCurrency.value),
                l10n.kpiDailyAvg,
                cs.primary),
            Container(
                width: 1,
                height: 30,
                color: cs.outline.withOpacity(0.1)),
            _buildGaugeStat(
                formatCurrency(forecast,
                    widget.budgetService.baseCurrency.value),
                l10n.kpiEndOfMonthForecast,
                Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildGaugeStat(
      String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color)),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 10,
                color:
                    widget.cs.onSurface.withOpacity(0.5))),
      ],
    );
  }

  Widget _buildSankeySectionLocal(
      ColorScheme cs, Map<String, dynamic> data, AppLocalizations l10n) {
    if (data.isEmpty) return const SizedBox.shrink();

    final income = data['income'] as double;
    final categories = data['categories'] as Map<String, double>;
    final savings = data['savings'] as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSankeyBarLocal(
            l10n.kpiMonthlyIncome, income, Colors.green, income > 0 ? 1 : 0),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                  child: Divider(
                      color: cs.outline.withOpacity(0.1))),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_downward_rounded,
                    color: cs.onSurface.withOpacity(0.3),
                    size: 14),
              ),
              Expanded(
                  child: Divider(
                      color: cs.outline.withOpacity(0.1))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...categories.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildSankeyBarLocal(
                  budgetCategoryLabel(l10n, e.key),
                  e.value,
                  cs.primary,
                  e.value / (income > 0 ? income : 1)),
            )),
        _buildSankeyBarLocal(l10n.kpiNetSavings, savings, Colors.amber,
            savings / (income > 0 ? income : 1)),
      ],
    );
  }

  Widget _buildSankeyBarLocal(
      String label, double value, Color color, double percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7))),
            Text(
                formatCurrency(
                    value, widget.budgetService.baseCurrency.value),
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildAnomalySectionLocal(
      ColorScheme cs, List<Map<String, dynamic>> anomalies, AppLocalizations l10n) {
    final l10n = AppLocalizations.of(context)!;
    if (anomalies.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(l10n.budgetNoAnomalies,
              style: GoogleFonts.outfit(
                  color: Colors.green, fontWeight: FontWeight.w500)),
        ],
      );
    }
    return Column(
      children: anomalies
          .map((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(budgetCategoryLabel(l10n, a['category'] as String),
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text(
                              '${l10n.categoryExpenses}: ${formatCurrency(a['amount'] as double, widget.budgetService.baseCurrency.value)}',
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: cs.onSurface
                                      .withOpacity(0.55))),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildAssetTreemapLocal(
      ColorScheme cs, Map<String, double> distribution) {
    if (distribution.isEmpty) return const SizedBox.shrink();

    return Column(
      children: distribution.entries.map((e) {
        final index = distribution.keys.toList().indexOf(e.key);
        final colors = [
          cs.primary,
          Colors.indigo,
          Colors.cyan,
          Colors.teal,
          Colors.purple,
        ];
        final color = colors[index % colors.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(e.key,
                    style: GoogleFonts.outfit(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('%${e.value.toStringAsFixed(1)}',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDailyHeatmapLocal(
      ColorScheme cs, List<BudgetTransaction> txs) {
    final heatmap =
        widget.budgetService.getHeatmapDataLocal(txs, _periodReference());
    final maxAmount = heatmap.values.isEmpty
        ? 1.0
        : heatmap.values.reduce((a, b) => a > b ? a : b);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(31, (index) {
        final day = index + 1;
        final amount = heatmap[day] ?? 0.0;
        final intensity = maxAmount > 0 ? amount / maxAmount : 0.0;
        return Tooltip(
          message: '$day: ${formatCurrency(amount, widget.budgetService.baseCurrency.value)}',
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: amount > 0
                  ? cs.primary.withOpacity(0.15 + intensity * 0.75)
                  : cs.onSurface.withOpacity(0.06),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '$day',
                style: GoogleFonts.outfit(
                  fontSize: 7,
                  fontWeight: FontWeight.w600,
                  color: amount > 0
                      ? Colors.white.withOpacity(0.85)
                      : cs.onSurface.withOpacity(0.3),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRecurringSectionLocal(
      ColorScheme cs, Map<String, double> recurring) {
    final l10n = AppLocalizations.of(context)!;
    final recurringAmount = (recurring['recurring'] ?? 0.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.repeat_rounded, color: cs.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.budgetFixedExpenses,
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.55))),
              Text(
                  formatCurrency(recurringAmount,
                      widget.budgetService.baseCurrency.value),
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer({
    required String title,
    required Widget child,
    required ColorScheme cs,
    double? height,
    double? width,
  }) {
    return Container(
      width: width,
      height: height,
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
                height: 16,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          height != null ? Expanded(child: child) : child,
        ],
      ),
    );
  }
}
