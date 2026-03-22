import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/budget_model.dart';
import '../../services/budget_service.dart';
import '../../widgets/phobes_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter/services.dart';

class BudgetScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const BudgetScreen({super.key, this.onClose});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BudgetService _budgetService = BudgetService();
  String _selectedFilter = 'all'; // 'all', 'income', 'expense'
  int _touchedIndex = -1;
  String? _selectedAccountId; // Seçili hesap filtresi
  // Ultimate Intelligence Verileri (Now reactive)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Increased to 5
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Padding(
      padding: EdgeInsets.only(bottom: isWide ? 0 : 80),
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverOverlapAbsorber(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: _buildHeader(cs),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(cs),
                _buildLocalStatisticsTab(cs),
                _buildAccountsTab(cs), // New Accounts Tab
                _buildDebtsTab(cs),
                _buildGoalsTab(cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      height: 48,
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.08), // Softer pill background
        borderRadius: BorderRadius.circular(24),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(
            4), // Add padding so the indicator floats inside
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              cs.primary.withValues(alpha: 0.9),
              cs.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.3), // Softer shadow
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
        labelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 14), // Slightly larger active font
        unselectedLabelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            fontSize: 13), // Keep unselected readable
        tabs: const [
          Tab(text: "Genel"),
          Tab(text: "İstatistik"),
          Tab(text: "Hesaplar"), // New tab
          Tab(text: "Borçlar"),
          Tab(text: "Hedefler"),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ColorScheme cs) {
    return Builder(
      builder: (context) => CustomScrollView(
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
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

  Widget _buildHeader(ColorScheme cs) {
    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: cs.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 90,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      flexibleSpace: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(32)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withValues(alpha: 0.15),
              cs.surface,
            ],
          ),
        ),
        padding: EdgeInsets.fromLTRB(
            24,
            MediaQuery.of(context).padding.top + 16,
            24,
            60 + 12), // 60 for tabbar
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    PhobesIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Cüzdan",
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            PhobesIconButton(
              icon: Icons.add_rounded,
              onTap: () => _showAddTransactionSheet(context),
              backgroundColor: cs.primary,
              color: Colors.white,
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: _buildCustomTabBar(cs),
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(ColorScheme cs) {
    return SliverToBoxAdapter(
      child: StreamBuilder<List<BudgetTransaction>>(
        stream: _budgetService.getTransactionsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }

          final expenses = snapshot.data!
              .where((tx) => tx.type == TransactionType.expense)
              .toList();
          if (expenses.isEmpty) {
            return const SizedBox.shrink();
          }

          // Kategori bazlı toplamlar
          final Map<String, double> categoryMap = {};
          double totalExpense = 0;
          for (var tx in expenses) {
            categoryMap[tx.category] =
                (categoryMap[tx.category] ?? 0) + tx.amount;
            totalExpense += tx.amount;
          }

          final categories = categoryMap.keys.toList();

          return PhobesGlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Harcama Dağılımı",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 16)),
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
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse
                                      .touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 4,
                            centerSpaceRadius: 40,
                            sections: List.generate(categories.length, (i) {
                              final isTouched = i == _touchedIndex;
                              final fontSize = isTouched ? 16.0 : 12.0;
                              final radius = isTouched ? 60.0 : 50.0;
                              final cat = categories[i];
                              final amount = categoryMap[cat]!;
                              final percentage = (amount / totalExpense * 100)
                                  .toStringAsFixed(0);

                              return PieChartSectionData(
                                color: Colors
                                    .primaries[i % Colors.primaries.length],
                                value: amount,
                                title: '$percentage%',
                                radius: radius,
                                titleStyle: GoogleFonts.outfit(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: categories.take(5).map((cat) {
                          final i = categories.indexOf(cat);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .primaries[i % Colors.primaries.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(cat,
                                    style: GoogleFonts.outfit(fontSize: 12)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocalStatisticsTab(ColorScheme cs) {
    return StreamBuilder<List<BudgetTransaction>>(
      stream: _budgetService.getTransactionsStream(),
      builder: (context, txSnap) {
        return StreamBuilder<List<Account>>(
          stream: _budgetService.getAccountsStream(),
          builder: (context, accSnap) {
            if (!txSnap.hasData || !accSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final txs = txSnap.data!;
            final accounts = accSnap.data!;

            // Compute all analytics locally using the txs list
            final trend = _budgetService.getMonthlyTrendLocal(txs, 6);
            final sankey = _budgetService.getSankeyDataLocal(txs);
            final forecast = _budgetService.getForecastDataLocal(txs);
            final anomalies = _budgetService.getAnomaliesLocal(txs);
            final distribution =
                _budgetService.getAssetDistributionLocal(accounts);
            final recurring = _budgetService.getRecurringAnalyticsLocal(txs);

            return Builder(
              builder: (context) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).padding.top + 190,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Finansal Analiz",
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildProfessionalKpisLocal(cs, txs),
                    const SizedBox(height: 24),
                    _buildChartContainer(
                      title: "Bütçe Hız Göstergesi",
                      cs: cs,
                      child: _buildForecastGaugeLocal(cs, forecast),
                    ),
                    const SizedBox(height: 24),
                    _buildChartContainer(
                      title: "Paranın Yolculuğu",
                      cs: cs,
                      child: _buildSankeySectionLocal(cs, sankey),
                    ),
                    const SizedBox(height: 24),
                    _buildChartContainer(
                      title: "Gelir vs Gider Trendi",
                      cs: cs,
                      child: _buildTrendChartLocal(cs, trend),
                    ),
                    const SizedBox(height: 24),
                    _buildChartContainer(
                      title: "Akıllı Anomali Takibi",
                      cs: cs,
                      child: _buildAnomalySectionLocal(cs, anomalies),
                    ),
                    const SizedBox(height: 24),
                    _buildChartContainer(
                      title: "Varlık Dağılım Map'i",
                      cs: cs,
                      child: _buildAssetTreemapLocal(cs, distribution),
                    ),
                    const SizedBox(height: 24),
                    _buildChartContainer(
                      title: "Günlük Harcama Isı Haritası",
                      cs: cs,
                      child: _buildDailyHeatmapLocal(cs, txs),
                    ),
                    const SizedBox(height: 24),
                    _buildChartContainer(
                      title: "Sabit Gider Analizi",
                      cs: cs,
                      child: _buildRecurringSectionLocal(cs, recurring),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfessionalKpisLocal(
      ColorScheme cs, List<BudgetTransaction> txs) {
    final now = DateTime.now();
    final thisMonthExp = txs.where((t) =>
        t.date.year == now.year &&
        t.date.month == now.month &&
        t.type == TransactionType.expense);
    final thisMonthInc = txs.where((t) =>
        t.date.year == now.year &&
        t.date.month == now.month &&
        t.type == TransactionType.income);

    final prevMonthExp = txs.where((t) =>
        t.date.year == (now.month == 1 ? now.year - 1 : now.year) &&
        t.date.month == (now.month == 1 ? 12 : now.month - 1) &&
        t.type == TransactionType.expense);
    final prevMonthInc = txs.where((t) =>
        t.date.year == (now.month == 1 ? now.year - 1 : now.year) &&
        t.date.month == (now.month == 1 ? 12 : now.month - 1) &&
        t.type == TransactionType.income);

    double thisMonthExpTotal =
        thisMonthExp.fold(0.0, (sum, t) => sum + t.amount);
    double thisMonthIncTotal =
        thisMonthInc.fold(0.0, (sum, t) => sum + t.amount);
    double prevMonthExpTotal =
        prevMonthExp.fold(0.0, (sum, t) => sum + t.amount);
    double prevMonthIncTotal =
        prevMonthInc.fold(0.0, (sum, t) => sum + t.amount);

    double thisMonthSavings = thisMonthIncTotal - thisMonthExpTotal;
    double avgDaily = thisMonthExpTotal / now.day;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: "Aylık Gider",
                value: "₺${thisMonthExpTotal.toStringAsFixed(0)}",
                subtitle: prevMonthExpTotal == 0
                    ? "Yeni"
                    : "${((thisMonthExpTotal / prevMonthExpTotal - 1) * 100).toStringAsFixed(1)}%",
                isIncrease: thisMonthExpTotal > prevMonthExpTotal,
                cs: cs,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: "Aylık Gelir",
                value: "₺${thisMonthIncTotal.toStringAsFixed(0)}",
                subtitle: prevMonthIncTotal == 0
                    ? "Yeni"
                    : "${((thisMonthIncTotal / prevMonthIncTotal - 1) * 100).toStringAsFixed(1)}%",
                isIncrease: thisMonthIncTotal > prevMonthIncTotal,
                cs: cs,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: "Net Tasarruf",
                value: "₺${thisMonthSavings.toStringAsFixed(0)}",
                subtitle: "Bu Ay",
                isIncrease: thisMonthSavings < 0,
                cs: cs,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: "Günlük Ort.",
                value: "₺${avgDaily.toStringAsFixed(0)}",
                subtitle: "Harcama",
                isIncrease: false,
                cs: cs,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendChartLocal(
      ColorScheme cs, List<Map<String, dynamic>> trend) {
    if (trend.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: cs.outline.withValues(alpha: 0.1),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      String text = "";
                      if (value >= 1000) {
                        text = "${(value / 1000).toStringAsFixed(0)}K";
                      } else if (value <= -1000) {
                        text = "${(value / 1000).toStringAsFixed(0)}K";
                      } else {
                        text = value.toStringAsFixed(0);
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(text,
                            style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: cs.onSurface.withValues(alpha: 0.5))),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < 0 || value.toInt() >= trend.length) {
                        return const SizedBox();
                      }
                      final month = trend[value.toInt()]['month'] as DateTime;
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8,
                        child: Text(DateFormat('MMM').format(month),
                            style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: cs.onSurface.withValues(alpha: 0.5))),
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
                    return FlSpot(e.key.toDouble(), e.value['income']);
                  }).toList(),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withValues(alpha: 0.1),
                  ),
                ),
                LineChartBarData(
                  spots: trend.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value['expense']);
                  }).toList(),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.red.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastGaugeLocal(ColorScheme cs, Map<String, double> data) {
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
              Text("₺${(forecast - current).toStringAsFixed(0)}",
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 24)),
              Text("Kalan Limit",
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5))),
            ],
          ),
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: cs.primary.withValues(alpha: 0.05),
          progressColor: (current > forecast) ? Colors.red : cs.primary,
          animation: true,
          animationDuration: 1000,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text("₺${avgDaily.toStringAsFixed(0)}",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: cs.primary)),
                Text("Günlük Ort.",
                    style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ),
            Container(
                width: 1, height: 30, color: cs.outline.withValues(alpha: 0.1)),
            Column(
              children: [
                Text("₺${forecast.toStringAsFixed(0)}",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: cs.primary)),
                Text("Ay Sonu Tahmin",
                    style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSankeySectionLocal(ColorScheme cs, Map<String, dynamic> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final income = data['income'] as double;
    final categories = data['categories'] as Map<String, double>;
    final savings = data['savings'] as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSankeyBarLocal(
            "Toplam Gelir", income, Colors.green, income > 0 ? 1 : 0),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                  child: Divider(color: cs.outline.withValues(alpha: 0.1))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_downward_rounded,
                    color: cs.onSurface.withValues(alpha: 0.3), size: 16),
              ),
              Expanded(
                  child: Divider(color: cs.outline.withValues(alpha: 0.1))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...categories.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSankeyBarLocal(e.key, e.value, cs.primary,
                  e.value / (income > 0 ? income : 1)),
            )),
        _buildSankeyBarLocal("Tasarruf", savings, Colors.amber,
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
                        .withValues(alpha: 0.7))),
            Text("₺${value.toStringAsFixed(0)}",
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        LinearPercentIndicator(
          padding: EdgeInsets.zero,
          lineHeight: 8.0,
          percent: percent.clamp(0, 1),
          backgroundColor: color.withValues(alpha: 0.1),
          progressColor: color,
          barRadius: const Radius.circular(4),
          animation: true,
        ),
      ],
    );
  }

  Widget _buildAnomalySectionLocal(
      ColorScheme cs, List<Map<String, dynamic>> anomalies) {
    if (anomalies.isEmpty) return const Text("Anomali saptanmadı.");
    return Column(
      children: anomalies
          .map((a) => ListTile(
                title: Text(a['category']),
                subtitle: Text(
                    "Harcama: ₺${(a['amount'] as double).toStringAsFixed(0)}"),
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
        // Varying blue tones for a premium map look
        final color =
            cs.primary.withValues(alpha: 1.0 - (index * 0.2).clamp(0.0, 0.7));

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
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
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(e.key,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("%${e.value.toStringAsFixed(1)}",
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cs.primary)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDailyHeatmapLocal(ColorScheme cs, List<BudgetTransaction> txs) {
    final now = DateTime.now();
    final heatmap = _budgetService.getHeatmapDataLocal(txs, now);
    return Wrap(
      children: List.generate(31, (index) {
        final amount = heatmap[index + 1] ?? 0.0;
        return Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.all(2),
          color: Colors.green.withValues(alpha: amount > 0 ? 0.5 : 0.1),
        );
      }),
    );
  }

  Widget _buildRecurringSectionLocal(
      ColorScheme cs, Map<String, double> recurring) {
    return Text(
        "Sabit Giderler: ₺${(recurring['recurring'] ?? 0).toStringAsFixed(0)}");
  }

  Widget _buildGoalsTab(ColorScheme cs) {
    return StreamBuilder<List<SavingsGoal>>(
      stream: _budgetService.getGoalsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text("Hata: ${snapshot.error}",
                  style: GoogleFonts.outfit(color: Colors.red)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final goals = snapshot.data!;

        return Builder(
          builder: (context) => CustomScrollView(
            slivers: [
              SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Tasarruf Hedefleri",
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      PhobesIconButton(
                        icon: Icons.add_rounded,
                        onTap: () => _showAddGoalSheet(context),
                      ),
                    ],
                  ),
                ),
              ),
              if (goals.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text("Henüz bir hedef eklemediniz",
                        style: GoogleFonts.outfit(
                            color: cs.onSurface.withValues(alpha: 0.5))),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final goal = goals[index];
                      final percent = (goal.currentAmount / goal.targetAmount)
                          .clamp(0.0, 1.0);
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: PhobesGlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        cs.primary.withValues(alpha: 0.1),
                                    child: Icon(Icons.savings_rounded,
                                        color: cs.primary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(goal.title,
                                            style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        Text(
                                            "Hedef: ₺${goal.targetAmount.toStringAsFixed(0)}",
                                            style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: cs.onSurface
                                                    .withValues(alpha: 0.5))),
                                      ],
                                    ),
                                  ),
                                  PhobesIconButton(
                                    icon: Icons.edit_rounded,
                                    onTap: () =>
                                        _showUpdateGoalAmount(context, goal),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      "₺${goal.currentAmount.toStringAsFixed(0)}",
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: cs.primary)),
                                  Text("${(percent * 100).toStringAsFixed(0)}%",
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearPercentIndicator(
                                lineHeight: 10.0,
                                percent: percent,
                                padding: EdgeInsets.zero,
                                barRadius: const Radius.circular(5),
                                backgroundColor:
                                    cs.outline.withValues(alpha: 0.1),
                                progressColor: cs.primary,
                                animation: true,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: goals.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  void _showAddGoalSheet(BuildContext context) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: "Yeni Hedef Oluştur",
        child: Column(
          children: [
            PhobesTextField(
              controller: titleController,
              hintText: "Hedef Başlığı (Örn: Tatil)",
              prefixIcon: Icons.flag_rounded,
            ),
            const SizedBox(height: 12),
            PhobesTextField(
              controller: targetController,
              hintText: "Hedef Tutar (₺)",
              prefixIcon: Icons.money_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            PhobesButton(
              text: "Hedefi Başlat",
              width: double.infinity,
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    targetController.text.isEmpty) {
                  return;
                }
                final goal = SavingsGoal(
                  userId: _budgetService.currentUserId!,
                  title: titleController.text,
                  targetAmount: double.parse(targetController.text),
                );
                await _budgetService.addGoal(goal);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  PhobesSnackbar.show(context, message: "Hedef oluşturuldu!");
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateGoalAmount(BuildContext context, SavingsGoal goal) {
    final amountController =
        TextEditingController(text: goal.currentAmount.toStringAsFixed(0));
    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: "Para Ekle / Düzenle",
        child: Column(
          children: [
            PhobesTextField(
              controller: amountController,
              hintText: "Mevcut Para (₺)",
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PhobesButton(
                    text: "Sil",
                    isOutlined: true,
                    onPressed: () async {
                      final confirmed = await PhobesBottomSheet.confirm(
                        context: context,
                        title: "Hedefi Sil",
                        message:
                            "${goal.title} hedefini silmek istiyor musunuz?",
                      );
                      if (confirmed == true) {
                        await _budgetService.deleteGoal(goal.id!);
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PhobesButton(
                    text: "Güncelle",
                    onPressed: () async {
                      final amount =
                          double.tryParse(amountController.text) ?? 0;
                      await _budgetService
                          .updateGoal(goal.copyWith(currentAmount: amount));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(ColorScheme cs) {
    return SliverToBoxAdapter(
      child: StreamBuilder<List<BudgetTransaction>>(
        stream: _budgetService.getTransactionsStream(),
        builder: (context, snapshot) {
          double totalIncome = 0;
          double totalExpense = 0;

          if (snapshot.hasData) {
            for (var tx in snapshot.data!) {
              if (tx.type == TransactionType.income) {
                totalIncome += tx.amount;
              } else {
                totalExpense += tx.amount;
              }
            }
          }

          final currencyFormat = NumberFormat.currency(
              locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: PhobesGlassCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedFilter =
                            _selectedFilter == 'income' ? 'all' : 'income';
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: _selectedFilter == 'income'
                            ? LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade700
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _selectedFilter == 'income'
                            ? null
                            : cs.onSurface.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _selectedFilter == 'income'
                            ? [
                                BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8))
                              ]
                            : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _selectedFilter == 'income'
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: _selectedFilter == 'income'
                                        ? Colors.white
                                        : Colors.green),
                              ),
                              const SizedBox(width: 8),
                              Text("Gelir",
                                  style: GoogleFonts.outfit(
                                      color: _selectedFilter == 'income'
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : cs.onSurface.withValues(alpha: 0.6),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(currencyFormat.format(totalIncome),
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: _selectedFilter == 'income'
                                      ? Colors.white
                                      : cs.onSurface)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PhobesGlassCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedFilter =
                            _selectedFilter == 'expense' ? 'all' : 'expense';
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: _selectedFilter == 'expense'
                            ? LinearGradient(
                                colors: [
                                  Colors.redAccent.shade400,
                                  Colors.redAccent.shade700
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _selectedFilter == 'expense'
                            ? null
                            : cs.onSurface.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _selectedFilter == 'expense'
                            ? [
                                BoxShadow(
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8))
                              ]
                            : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _selectedFilter == 'expense'
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.redAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.arrow_upward_rounded,
                                    size: 16,
                                    color: _selectedFilter == 'expense'
                                        ? Colors.white
                                        : Colors.redAccent),
                              ),
                              const SizedBox(width: 8),
                              Text("Gider",
                                  style: GoogleFonts.outfit(
                                      color: _selectedFilter == 'expense'
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : cs.onSurface.withValues(alpha: 0.6),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(currencyFormat.format(totalExpense),
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: _selectedFilter == 'expense'
                                      ? Colors.white
                                      : cs.onSurface)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLimitsSection(ColorScheme cs) {
    return SliverToBoxAdapter(
      child: StreamBuilder<List<BudgetLimit>>(
        stream: _budgetService.getLimitsStream(),
        builder: (context, limitSnapshot) {
          return StreamBuilder<List<BudgetTransaction>>(
            stream: _budgetService.getTransactionsStream(),
            builder: (context, txSnapshot) {
              if (!limitSnapshot.hasData || limitSnapshot.data!.isEmpty) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: PhobesCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () => _showAddLimitSheet(context),
                    child: Center(
                      child: Text("+ Bütçe Limiti Ekle",
                          style: GoogleFonts.outfit(
                              color: cs.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }

              final limits = limitSnapshot.data!;
              final expenses = (txSnapshot.data ?? [])
                  .where((tx) => tx.type == TransactionType.expense)
                  .toList();

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Bütçe Limitleri",
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        PhobesIconButton(
                          icon: Icons.add_rounded,
                          onTap: () => _showAddLimitSheet(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...limits.map((limit) {
                      final spent = expenses
                          .where((tx) => tx.category == limit.category)
                          .fold(0.0, (sum, tx) => sum + tx.amount);
                      final percent = spent / limit.limitAmount;
                      final displayPercent = percent > 1.0 ? 1.0 : percent;
                      bool isOver = false;
                      if (spent > limit.limitAmount) {
                        isOver = true;
                      }

                      return PhobesCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        onLongPress: () async {
                          final confirmed = await PhobesBottomSheet.confirm(
                            context: context,
                            title: "Limiti Sil",
                            message:
                                "${limit.category} limitini silmek istiyor musunuz?",
                          );
                          if (confirmed == true) {
                            await _budgetService.deleteLimit(limit.id!);
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(limit.category,
                                    style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    "₺${spent.toStringAsFixed(0)} / ₺${limit.limitAmount.toStringAsFixed(0)}",
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: spent > limit.limitAmount
                                            ? Colors.red
                                            : cs.onSurface
                                                .withValues(alpha: 0.6))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearPercentIndicator(
                              lineHeight: 8.0,
                              percent: displayPercent,
                              padding: EdgeInsets.zero,
                              barRadius: const Radius.circular(4),
                              backgroundColor:
                                  cs.outline.withValues(alpha: 0.1),
                              progressColor: isOver
                                  ? Colors.red
                                  : spent > limit.limitAmount * 0.8
                                      ? Colors.orange
                                      : cs.primary,
                              animation: true,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddLimitSheet(BuildContext context) {
    final amountController = TextEditingController();
    String selectedCategory = 'Yemek';

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => PhobesBottomSheet(
          title: "Bütçe Limiti Ekle",
          child: Column(
            children: [
              _buildCategorySelector(setModalState, selectedCategory,
                  (val) => selectedCategory = val),
              const SizedBox(height: 12),
              PhobesTextField(
                controller: amountController,
                hintText: "Limit Tutarı (₺)",
                prefixIcon: Icons.money_off_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              PhobesButton(
                text: "Limiti Kaydet",
                width: double.infinity,
                onPressed: () async {
                  if (amountController.text.isEmpty) return;
                  final limit = BudgetLimit(
                    userId: _budgetService.currentUserId!,
                    category: selectedCategory,
                    limitAmount: double.parse(amountController.text),
                  );
                  await _budgetService.addLimit(limit);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsFilter(ColorScheme cs) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("İşlem Geçmişi",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                if (_selectedAccountId != null)
                  GestureDetector(
                    onTap: () => setState(() => _selectedAccountId = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: cs.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_alt_off_rounded,
                              size: 14, color: cs.primary),
                          const SizedBox(width: 4),
                          Text("Hesabı Temizle",
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(cs, "Tümü", "all"),
                  const SizedBox(width: 8),
                  _buildFilterChip(cs, "Gelirler", "income",
                      icon: Icons.arrow_downward_rounded, color: Colors.green),
                  const SizedBox(width: 8),
                  _buildFilterChip(cs, "Giderler", "expense",
                      icon: Icons.arrow_upward_rounded,
                      color: Colors.redAccent),
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
              ? activeColor.withValues(alpha: 0.15)
              : cs.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.5)
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
                      : cs.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? activeColor
                    : cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(ColorScheme cs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: StreamBuilder<List<BudgetTransaction>>(
        stream: _budgetService.getTransactionsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return SliverToBoxAdapter(
              child: Center(
                  child: Text("Hata: ${snapshot.error}",
                      style: GoogleFonts.outfit(color: Colors.red))),
            );
          }
          if (!snapshot.hasData) {
            return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()));
          }
          final allTxs = snapshot.data!;
          final txs = allTxs.where((tx) {
            // Hesap filtresi
            if (_selectedAccountId != null &&
                tx.accountId != _selectedAccountId) {
              return false;
            }
            // Tip filtresi
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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                      _selectedFilter == 'all'
                          ? "Henüz işlem yok"
                          : "${_selectedFilter == 'income' ? 'Gelir' : 'Gider'} işlemi bulunamadı",
                      style: GoogleFonts.outfit(
                          color: cs.onSurface.withValues(alpha: 0.5))),
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tx = txs[index];
                final isExpense = tx.type == TransactionType.expense;
                return PhobesCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isExpense ? Colors.red : Colors.green)
                          .withValues(alpha: 0.1),
                      child: Icon(
                        isExpense ? Icons.remove_rounded : Icons.add_rounded,
                        color: isExpense ? Colors.red : Colors.green,
                      ),
                    ),
                    title: Text(tx.title,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    subtitle: Text(tx.category,
                        style: GoogleFonts.outfit(fontSize: 12)),
                    trailing: Text(
                      "${isExpense ? '-' : '+'}₺${tx.amount.toStringAsFixed(0)}",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: isExpense ? Colors.red : Colors.green,
                      ),
                    ),
                    onLongPress: () async {
                      final confirmed = await PhobesBottomSheet.confirm(
                        context: context,
                        title: "İşlemi Sil",
                        message:
                            "Bu işlemi silmek istediğinizden emin misiniz?",
                        confirmText: "Sil",
                        confirmColor: Colors.red,
                      );
                      if (confirmed == true && tx.id != null) {
                        await _budgetService.deleteTransaction(tx.id!);
                        if (context.mounted) {
                          PhobesSnackbar.show(context,
                              message: "İşlem silindi",
                              type: PhobesSnackbarType.success);
                        }
                      }
                    },
                  ),
                );
              },
              childCount: txs.length,
            ),
          );
        },
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    TransactionType selectedType = TransactionType.expense;
    String selectedCategory = 'Genel';
    String? selectedSubCategory;
    String selectedRecurrence = 'none';
    String selectedMethod = 'cash';
    String? selectedAccountId;

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => PhobesBottomSheet(
          title: "Yeni İşlem Ekle",
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: PhobesButton(
                        text: "Gider",
                        isOutlined: selectedType != TransactionType.expense,
                        onPressed: () => setModalState(
                            () => selectedType = TransactionType.expense),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PhobesButton(
                        text: "Gelir",
                        isOutlined: selectedType != TransactionType.income,
                        onPressed: () => setModalState(
                            () => selectedType = TransactionType.income),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PhobesTextField(
                  controller: titleController,
                  hintText: "İşlem Başlığı (Örn: Market)",
                  prefixIcon: Icons.title_rounded,
                ),
                const SizedBox(height: 12),
                PhobesTextField(
                  controller: amountController,
                  hintText: "Tutar (₺)",
                  prefixIcon: Icons.money_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                PhobesTextField(
                  controller: descController,
                  hintText: "Açıklama (İsteğe bağlı)",
                  prefixIcon: Icons.description_rounded,
                ),
                const SizedBox(height: 12),
                _buildCategorySelector(setModalState, selectedCategory,
                    (val) => selectedCategory = val),
                const SizedBox(height: 12),
                PhobesTextField(
                  controller: TextEditingController(text: selectedSubCategory),
                  hintText: "Alt Kategori (Örn: Gıda)",
                  prefixIcon: Icons.subdirectory_arrow_right_rounded,
                  onChanged: (val) => selectedSubCategory = val,
                ),
                const SizedBox(height: 12),
                _buildAccountDropdown(setModalState, selectedAccountId,
                    (val) => selectedAccountId = val),
                const SizedBox(height: 12),
                _buildRecurrenceSelector(setModalState, selectedRecurrence,
                    (val) => selectedRecurrence = val),
                const SizedBox(height: 12),
                _buildMethodSelector(setModalState, selectedMethod,
                    (val) => selectedMethod = val),
                const SizedBox(height: 24),
                PhobesButton(
                  text: "Kaydet",
                  width: double.infinity,
                  onPressed: () async {
                    if (titleController.text.isEmpty ||
                        amountController.text.isEmpty) {
                      return;
                    }
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) {
                      return;
                    }

                    final tx = BudgetTransaction(
                      userId: _budgetService.currentUserId!,
                      title: titleController.text,
                      amount: amount,
                      type: selectedType,
                      category: selectedCategory,
                      subCategory: selectedSubCategory,
                      date: DateTime.now(),
                      description: descController.text,
                      recurrence: selectedRecurrence,
                      paymentMethod: selectedMethod,
                      accountId: selectedAccountId,
                    );

                    await _budgetService.addTransaction(tx);
                    // UI is reactive, no manual reload needed
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      PhobesSnackbar.show(context,
                          message: "İşlem başarıyla eklendi!",
                          type: PhobesSnackbarType.success);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecurrenceSelector(
      StateSetter setModalState, String current, Function(String) onSelect) {
    final recurrences = {
      'none': 'Yok',
      'daily': 'Günlük',
      'weekly': 'Haftalık',
      'monthly': 'Aylık',
      'yearly': 'Yıllık',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tekrarla",
            style: GoogleFonts.outfit(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6))),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: recurrences.entries.map((e) {
              final isSelected = current == e.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e.value, style: GoogleFonts.outfit(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (val) => setModalState(() => onSelect(e.key)),
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
    final methods = {
      'cash': 'Nakit',
      'credit_card': 'Kredi Kartı',
      'bank_transfer': 'Banka/EFT',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Ödeme Yöntemi",
            style: GoogleFonts.outfit(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6))),
        const SizedBox(height: 8),
        Row(
          children: methods.entries.map((e) {
            final isSelected = current == e.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(e.value, style: GoogleFonts.outfit(fontSize: 12)),
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

  void _showAddAccountSheet(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    AccountType selectedType = AccountType.cash;

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => PhobesBottomSheet(
          title: "Yeni Hesap / Cüzdan",
          child: Column(
            children: [
              PhobesTextField(
                controller: nameController,
                hintText: "Hesap Adı (Örn: Maaş Hesabı)",
                prefixIcon: Icons.edit_rounded,
              ),
              const SizedBox(height: 12),
              PhobesTextField(
                controller: balanceController,
                hintText: "Mevcut Bakiye (₺)",
                prefixIcon: Icons.account_balance_wallet_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: AccountType.values.map((type) {
                  final isSelected = selectedType == type;
                  return IconButton(
                    icon: Icon(_getAccountIcon(type),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    onPressed: () {
                      setModalState(() {
                        selectedType = type;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              PhobesButton(
                text: "Hesabı Oluştur",
                width: double.infinity,
                onPressed: () async {
                  if (nameController.text.isEmpty) return;
                  final account = Account(
                    userId: _budgetService.currentUserId!,
                    name: nameController.text,
                    type: selectedType,
                    balance: double.tryParse(balanceController.text) ?? 0.0,
                  );
                  await _budgetService.addAccount(account);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsTab(ColorScheme cs) {
    return Builder(
      builder: (context) => CustomScrollView(
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: StreamBuilder<List<Account>>(
              stream: _budgetService.getAccountsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()));
                }
                final accounts = snapshot.data ?? [];

                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // Add Account Button Box
                      if (index == accounts.length) {
                        return LayoutBuilder(builder: (context, constraints) {
                          return PhobesGlassCard(
                            padding: const EdgeInsets.all(16),
                            onTap: () => _showAddAccountSheet(context),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_card_rounded,
                                    color: cs.primary, size: 36),
                                const SizedBox(height: 12),
                                Text(
                                  "Yeni Hesap Ekle",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
                      }

                      // Native Account Cards
                      final account = accounts[index];
                      return PhobesGlassCard(
                        padding: const EdgeInsets.all(16),
                        onTap: () {
                          setState(() {
                            _selectedAccountId = account.id;
                            _tabController
                                .animateTo(0); // Go back to overview filtered
                          });
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getAccountIcon(account.type),
                                    color: cs.primary,
                                    size: 20,
                                  ),
                                ),
                                Icon(Icons.more_horiz_rounded,
                                    color: cs.onSurface.withValues(alpha: 0.4)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "₺${account.balance.toStringAsFixed(0)}",
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: account.balance >= 0
                                        ? cs.onSurface
                                        : Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: accounts.length + 1,
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildDebtsTab(ColorScheme cs) {
    return Builder(
      builder: (context) => CustomScrollView(
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Borç & Alacak Takibi",
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  PhobesIconButton(
                    icon: Icons.add_rounded,
                    onTap: () => _showAddDebtSheet(context),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<Debt>>(
            stream: _budgetService.getDebtsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                    child: Center(child: Text("Hata: ${snapshot.error}")));
              }
              if (!snapshot.hasData) {
                return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()));
              }
              final debts = snapshot.data!;
              if (debts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text("Henüz borç kaydı yok",
                        style: GoogleFonts.outfit(
                            color: cs.onSurface.withValues(alpha: 0.5))),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final debt = debts[index];
                    final isDebt = debt.type ==
                        DebtType.debt; // Alacak (başkasından alacağın)
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: PhobesGlassCard(
                        onTap: () => _toggleDebtStatus(debt),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                (isDebt ? Colors.green : Colors.red)
                                    .withValues(alpha: 0.1),
                            child: Icon(
                                isDebt
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: isDebt ? Colors.green : Colors.red),
                          ),
                          title: Text(debt.personName,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              isDebt ? "Sana borcu var" : "Borcun var",
                              style: GoogleFonts.outfit(fontSize: 12)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("₺${debt.amount.toStringAsFixed(0)}",
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDebt ? Colors.green : Colors.red)),
                              if (debt.isPaid)
                                Text("ÖDENDİ",
                                    style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: debts.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Future<void> _toggleDebtStatus(Debt debt) async {
    final confirmed = await PhobesBottomSheet.confirm(
      context: context,
      title:
          debt.isPaid ? "Ödenmedi olarak işaretle?" : "Ödendi olarak işaretle?",
      message:
          "${debt.personName} kişisine ait bu borç durumunu değiştirmek istiyor musunuz?",
    );
    if (confirmed == true) {
      await _budgetService.updateDebt(debt.copyWith(isPaid: !debt.isPaid));
    }
  }

  void _showAddDebtSheet(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DebtType selectedType = DebtType.debt;

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => PhobesBottomSheet(
          title: "Borç / Alacak Kaydı",
          child: Column(
            children: [
              PhobesTextField(
                controller: nameController,
                hintText: "Kişi Adı",
                prefixIcon: Icons.person_rounded,
              ),
              const SizedBox(height: 12),
              PhobesTextField(
                controller: amountController,
                hintText: "Tutar (₺)",
                prefixIcon: Icons.money_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PhobesButton(
                      text: "Alacaklıyım",
                      isOutlined: selectedType != DebtType.debt,
                      onPressed: () =>
                          setModalState(() => selectedType = DebtType.debt),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PhobesButton(
                      text: "Borçluyum",
                      isOutlined: selectedType != DebtType.credit,
                      onPressed: () =>
                          setModalState(() => selectedType = DebtType.credit),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PhobesButton(
                text: "Kaydet",
                width: double.infinity,
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      amountController.text.isEmpty) {
                    return;
                  }
                  final debt = Debt(
                    userId: _budgetService.currentUserId!,
                    personName: nameController.text,
                    amount: double.parse(amountController.text),
                    type: selectedType,
                    date: DateTime.now(),
                  );
                  await _budgetService.addDebt(debt);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(
      StateSetter setModalState, String current, Function(String) onSelect) {
    final categories = [
      'Genel',
      'Yemek',
      'Market',
      'Ulaşım',
      'Eğlence',
      'Kira',
      'Fatura',
      'Sağlık',
      'Maaş',
      'Diğer'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text("Kategori",
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
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
                  label: Text(cat, style: GoogleFonts.outfit(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    if (selected) {
                      setModalState(() => onSelect(cat));
                    }
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
      StateSetter setModalState, String? current, Function(String?) onSelect) {
    return StreamBuilder<List<Account>>(
      stream: _budgetService.getAccountsStream(),
      builder: (context, snapshot) {
        final accounts = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ödeme Hesabı",
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6))),
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
                        onSelected: (val) =>
                            setModalState(() => onSelect(val ? acc.id : null)),
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
        color: cs.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
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
              Text(title,
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 20),
          height != null ? Expanded(child: child) : child,
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required bool isIncrease,
    required ColorScheme cs,
  }) {
    return PhobesCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.outfit(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isIncrease ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: isIncrease ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(subtitle,
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: isIncrease ? Colors.red : Colors.green)),
            ],
          ),
        ],
      ),
    );
  }
}
