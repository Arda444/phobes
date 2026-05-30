import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/admin_ui_system.dart';
import '../admin_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _stats;
  List<int> _loginCounts = List.filled(7, 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await AdminService.getDashboardStats();
    final logins = await AdminService.getLoginCountsLast7Days();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loginCounts = logins;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pad = AdminUISystem.horizontalPadding(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(pad),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sistem Analitiği',
              style: AdminUISystem.titleStyle.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Firestore verilerine dayalı gerçek metrikler',
              style: AdminUISystem.subtitleStyle(context),
            ),
            if (_loading) ...[
              const SizedBox(height: 48),
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              const SizedBox(height: 24),
              _buildStatsRow(context, cs),
              const SizedBox(height: 24),
              _buildLoginChart(context, cs),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, ColorScheme cs) {
    final s = _stats ?? {};
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w > 900 ? 4 : (w > 500 ? 2 : 1);
        final itemW = (w - (cols - 1) * 16) / cols;
        final cards = [
          ('Toplam kullanıcı', '${s['totalUsers'] ?? 0}', Icons.people_rounded, AdminUISystem.kElectricBlue(context)),
          ('Aktif (7 gün)', '${s['activeUsers7d'] ?? 0}', Icons.bolt_rounded, Colors.green),
          ('Yeni (7 gün)', '${s['newUsers7d'] ?? 0}', Icons.person_add_rounded, Colors.teal),
          ('Yasaklı', '${s['bannedUsers'] ?? 0}', Icons.block_rounded, Colors.red),
          ('Yeni (30 gün)', '${s['newUsers30d'] ?? 0}', Icons.calendar_month_rounded, Colors.indigo),
          ('Açık geri bildirim', '${s['openFeedback'] ?? 0}', Icons.feedback_rounded, Colors.orange),
          ('Aktif anket', '${s['activeSurveys'] ?? 0}', Icons.poll_rounded, Colors.amber),
        ];
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map(
                (c) => SizedBox(
                  width: itemW,
                  child: AdminUISystem.buildStatCard(
                    context: context,
                    title: c.$1,
                    value: c.$2,
                    icon: c.$3,
                    color: c.$4,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildLoginChart(BuildContext context, ColorScheme cs) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final maxY = _loginCounts.reduce((a, b) => a > b ? a : b);
    final spots = List.generate(
      7,
      (i) => FlSpot(i.toDouble(), _loginCounts[i].toDouble()),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      height: 320,
      decoration: AdminUISystem.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Günlük giriş (son 7 gün)',
            style: AdminUISystem.cardTitle.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY > 0 ? maxY * 1.2 : 5,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: cs.outline.withOpacity(0.06),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.outfit(fontSize: 10, color: cs.onSurface.withOpacity(0.4)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= 7) return const SizedBox();
                        return Text(days[i], style: GoogleFonts.outfit(fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AdminUISystem.kElectricBlue(context),
                    barWidth: 3,
                    dotData: FlDotData(show: maxY > 0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
