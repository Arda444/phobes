import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/phobes_theme.dart';
import '../../../core/stats_module_palette.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/statistics_models.dart';
import '../../../models/statistics_models_l10n.dart';
import '../../../widgets/phobes_widgets.dart';

String statsPeriodChipLabel(StatsPeriod period, AppLocalizations l10n) {
  switch (period) {
    case StatsPeriod.day:
      return l10n.statsPeriodDay;
    case StatsPeriod.week:
      return l10n.statsPeriodWeek;
    case StatsPeriod.month:
      return l10n.statsPeriodMonth;
    case StatsPeriod.quarter:
      return l10n.statsPeriodYear;
  }
}

int statsOverviewColumns(double width) {
  if (width > 1500) return 5;
  if (width > 1100) return 4;
  if (width > 720) return 3;
  if (width > 400) return 2;
  return 1;
}

int statsMetricColumns(double width) {
  if (width > 1000) return 6;
  if (width > 800) return 5;
  if (width > 560) return 4;
  if (width > 380) return 3;
  return 2;
}

double statsMetricAspectRatio(double width) {
  if (width > 1000) return 2.75;
  if (width > 700) return 2.35;
  if (width > 480) return 1.9;
  return 1.55;
}

double statsOverviewAspectRatio(int columns, double width) {
  switch (columns) {
    case >= 5:
      return 0.76;
    case 4:
      return 0.78;
    case 3:
      return 0.72;
    case 2:
      if (width < 520) return 0.58;
      return 0.66;
    default:
      return width < 400 ? 0.88 : 1.05;
  }
}

/// Detay panelleri: mobil 1, tablet 2, geniş web 3 sütun (mevcut genişliğe göre).
int statsDetailColumns(double width) {
  if (width >= 1100) return 3;
  if (width >= 640) return 2;
  return 1;
}

class StatsPeriodSelector extends StatelessWidget {
  final StatsPeriod selected;
  final ValueChanged<StatsPeriod> onChanged;

  const StatsPeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: StatsPeriod.values.map((p) {
          final isSel = p == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: PhobesTheme.animFast,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? cs.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  statsPeriodChipLabel(p, l10n),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isSel ? Colors.white : cs.onSurface.withOpacity(0.55),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class StatsGlobalSummary extends StatelessWidget {
  final StatisticsSnapshot snapshot;
  final double? contentWidth;

  const StatsGlobalSummary({
    super.key,
    required this.snapshot,
    this.contentWidth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final scores = snapshot.moduleScoresL10n(l10n);
    final w = contentWidth ?? MediaQuery.sizeOf(context).width;
    final chartHeight = w > 1100 ? 200.0 : (w > 700 ? 170.0 : 140.0);

    return PhobesCard(
      padding: const EdgeInsets.all(20),
      enableGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: snapshot.globalActivityScore / 100,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.butt,
                      backgroundColor: cs.primary.withOpacity(0.12),
                      color: cs.primary,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${snapshot.globalActivityScore}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            'skor',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              height: 1.0,
                              color: cs.onSurface.withOpacity(0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.statsGeneralActivity,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.statsPeriodSummarySubtitle(
                        snapshot.period.shortLabelOf(l10n),
                        snapshot.totalActions,
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.statsModulePerformance,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.statsModulePerformanceHint,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: chartHeight,
            width: double.infinity,
            child: StatsCharts.moduleBars(scores, cs, noDataLabel: l10n.statsNoDataForPeriod),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: scores.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: s.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: s.color.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: s.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${s.label}: ${s.score.toStringAsFixed(0)} — ${s.hint}',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: cs.onSurface.withOpacity(0.72),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class StatsModuleOverviewGrid extends StatelessWidget {
  final StatisticsSnapshot snapshot;
  final int crossAxisCount;

  const StatsModuleOverviewGrid({
    super.key,
    required this.snapshot,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      _OverviewData(
        l10n.statsModuleTasks,
        Icons.task_alt_rounded,
        StatsModulePalette.tasks,
        '${snapshot.tasks.completed}',
        '%${snapshot.tasks.completionRate.toStringAsFixed(0)} tamamlanma',
        snapshot.tasks.statusPieL10n(l10n),
        snapshot.tasks.completionRate,
      ),
      _OverviewData(
        l10n.statsHabitLabel,
        Icons.spa_rounded,
        StatsModulePalette.habits,
        '${snapshot.habits.completedInPeriod}',
        '${snapshot.habits.maxStreak} gün seri',
        snapshot.habits.completionPieL10n(l10n),
        snapshot.habits.periodCompletionRate,
      ),
      _OverviewData(
        l10n.statsModuleBudget,
        Icons.account_balance_wallet_rounded,
        StatsModulePalette.budget,
        '₺${snapshot.budget.net.toStringAsFixed(0)}',
        '${snapshot.budget.transactionCount} işlem',
        snapshot.budget.incomeExpensePieL10n(l10n),
        null,
      ),
      _OverviewData(
        l10n.statsModuleNotes,
        Icons.note_alt_rounded,
        StatsModulePalette.notes,
        '${snapshot.notes.created}',
        '${snapshot.notes.favorites} favori',
        snapshot.notes.categoryPieL10n(l10n),
        null,
      ),
      _OverviewData(
        l10n.statsModuleAppointments,
        Icons.event_available_rounded,
        StatsModulePalette.appointments,
        '${snapshot.appointments.completed}',
        '₺${snapshot.appointments.totalRevenue.toStringAsFixed(0)}',
        snapshot.appointments.statusPieL10n(l10n),
        null,
      ),
      _OverviewData(
        l10n.statsModuleMedications,
        Icons.medication_rounded,
        StatsModulePalette.medications,
        '%${snapshot.medications.adherenceRate.toStringAsFixed(0)}',
        '${snapshot.medications.dosesTaken} doz',
        snapshot.medications.adherencePieL10n(l10n),
        snapshot.medications.adherenceRate,
      ),
      _OverviewData(
        l10n.statsModuleBooks,
        Icons.menu_book_rounded,
        StatsModulePalette.books,
        '${snapshot.books.reading}',
        '${snapshot.books.finishedInPeriod} biten',
        snapshot.books.statusBreakdown,
        null,
      ),
      _OverviewData(
        l10n.statsModuleTeams,
        Icons.groups_rounded,
        StatsModulePalette.teams,
        '${snapshot.teams.teamCount}',
        '${snapshot.teams.totalMembers} üye',
        snapshot.teams.memberByTeam,
        null,
      ),
      _OverviewData(
        l10n.statsCorkboardLabel,
        Icons.dashboard_customize_rounded,
        StatsModulePalette.corkboard,
        '${snapshot.corkboard.notes}',
        '${snapshot.corkboard.connections} bağ',
        snapshot.corkboard.compositionPieL10n(l10n),
        null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridW = constraints.maxWidth;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: statsOverviewAspectRatio(crossAxisCount, gridW),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _OverviewCard(data: items[i]),
        );
      },
    );
  }
}

class _OverviewData {
  final String title;
  final IconData icon;
  final Color color;
  final String headline;
  final String subtitle;
  final Map<String, double> pieData;
  final double? ringPercent;

  _OverviewData(
    this.title,
    this.icon,
    this.color,
    this.headline,
    this.subtitle,
    this.pieData,
    this.ringPercent,
  );
}

class _OverviewCard extends StatelessWidget {
  final _OverviewData data;
  const _OverviewCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data.color.withOpacity(0.14),
            cs.surfaceVariant.withOpacity(0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: data.color.withOpacity(0.28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 150;
          final headlineSize = compact ? 16.0 : 20.0;
          final padH = compact ? 10.0 : 14.0;
          final padV = compact ? 10.0 : 12.0;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: compact ? 28 : 32,
                    height: compact ? 28 : 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: data.color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(data.icon, color: data.color, size: 17),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.title,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                data.headline,
                style: GoogleFonts.outfit(
                  fontSize: headlineSize,
                  fontWeight: FontWeight.bold,
                  color: data.color,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                data.subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: cs.onSurface.withOpacity(0.55),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Expanded(
                child: data.pieData.isNotEmpty
                    ? StatsCharts.pieOverviewLayout(
                        data.pieData,
                        data.color,
                        cs,
                      )
                    : data.ringPercent != null
                        ? StatsCharts.ringOverviewLayout(
                            data.ringPercent!,
                            data.color,
                            cs,
                          )
                        : Center(child: StatsCharts.noDataCompact(cs)),
              ),
            ],
            ),
          );
        },
      ),
    );
  }
}

/// Modül renginde dış kart; içinde responsive detay panelleri.
class StatsModuleSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<StatMetric> metrics;
  final List<Widget> panels;

  const StatsModuleSection({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.metrics,
    this.panels = const [],
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final children = <Widget>[
      if (metrics.isNotEmpty)
        StatsFullWidthPanel(
          child: StatsInnerPanel(
            moduleColor: color,
            title: l10n.statsSummaryMetrics,
            child: StatsMetricGrid(metrics: metrics, moduleColor: color),
          ),
        ),
      ...panels,
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(isDark ? 0.22 : 0.16),
            color.withOpacity(isDark ? 0.08 : 0.05),
            cs.surface.withOpacity(isDark ? 0.35 : 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.32)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        '${metrics.length} metrik · ${panels.length} grafik',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: StatsDetailGrid(children: children),
            ),
        ],
      ),
    );
  }
}

/// İçerik paneli (metrik / grafik) — modül kartının üzerinde yüzey rengi.
class StatsInnerPanel extends StatelessWidget {
  final Color moduleColor;
  final String? title;
  final Widget child;
  final bool fullWidth;

  const StatsInnerPanel({
    super.key,
    required this.moduleColor,
    required this.child,
    this.title,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surface.withOpacity(0.88)
            : cs.surface.withOpacity(0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: moduleColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: moduleColor,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Tam genişlik panel sarmalayıcı (ısı haritası vb.).
class StatsFullWidthPanel extends StatelessWidget {
  final Widget child;
  const StatsFullWidthPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

/// Mobilde alt alta; webde 2–3 sütun (sığdığı kadar).
class StatsDetailGrid extends StatelessWidget {
  final List<Widget> children;

  const StatsDetailGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = statsDetailColumns(constraints.maxWidth);
        const gap = 12.0;

        if (cols == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: gap),
                children[i],
              ],
            ],
          );
        }

        final itemWidth =
            (constraints.maxWidth - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children.map((child) {
            final full = child is StatsFullWidthPanel ||
                (child is StatsInnerPanel && child.fullWidth);
            return SizedBox(
              width: full ? constraints.maxWidth : itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

class StatsMetricGrid extends StatelessWidget {
  final List<StatMetric> metrics;
  final Color? moduleColor;

  const StatsMetricGrid({
    super.key,
    required this.metrics,
    this.moduleColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = statsMetricColumns(w);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: statsMetricAspectRatio(w),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: metrics.length,
          itemBuilder: (_, i) => _MetricTile(
                metric: metrics[i],
                moduleColor: moduleColor,
              ),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final StatMetric metric;
  final Color? moduleColor;
  const _MetricTile({required this.metric, this.moduleColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 130;
        final labelSize = compact ? 11.0 : 12.5;
        final valueSize = compact ? 17.0 : 21.0;
        final hintSize = compact ? 10.0 : 11.0;
        final pad = compact ? 10.0 : 14.0;

        final tint = moduleColor;
        return Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: tint != null
                ? tint.withOpacity(0.1)
                : cs.surfaceVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: tint != null
                  ? tint.withOpacity(0.18)
                  : cs.outline.withOpacity(0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                metric.label,
                style: GoogleFonts.outfit(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withOpacity(0.62),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: compact ? 4 : 8),
              Text(
                metric.value,
                style: GoogleFonts.outfit(
                  fontSize: valueSize,
                  fontWeight: FontWeight.bold,
                  color: metric.accent ?? cs.onSurface,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (metric.hint != null) ...[
                const SizedBox(height: 4),
                Text(
                  metric.hint!,
                  style: GoogleFonts.outfit(
                    fontSize: hintSize,
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class StatsChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;
  final Color? moduleColor;
  final bool fullWidth;

  const StatsChartCard({
    super.key,
    required this.title,
    required this.child,
    this.height = 240,
    this.moduleColor,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final panel = StatsInnerPanel(
      moduleColor: moduleColor ?? Theme.of(context).colorScheme.primary,
      title: title,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: child,
      ),
    );
    if (fullWidth) {
      return StatsFullWidthPanel(child: panel);
    }
    return panel;
  }
}

/// Modül detay grafik panelleri (responsive grid'e yerleştirilir).
class StatsModuleCharts {
  StatsModuleCharts._();

  static List<Widget> tasks(
    StatisticsSnapshot snap,
    ColorScheme cs,
    List<String> bucketLabels,
    AppLocalizations l10n,
  ) {
    final t = snap.tasks;
    const c = StatsModulePalette.tasks;
    return [
      if (t.statusPieL10n(l10n).isNotEmpty)
        StatsChartCard(
          title: l10n.statsStatusDistribution,
          moduleColor: c,
          child: StatsCharts.pieWithLegend(t.statusPieL10n(l10n), cs, accent: c),
        ),
      if (t.priorityPieL10n(l10n).isNotEmpty)
        StatsChartCard(
          title: l10n.statsPriority,
          moduleColor: c,
          child: StatsCharts.pieWithLegend(
            t.priorityPieL10n(l10n),
            cs,
            colors: [Colors.green, Colors.orange, Colors.red],
          ),
        ),
      if (snap.period.days <= 31)
        StatsChartCard(
          title: l10n.statsDailyCompleted,
          moduleColor: c,
          child: StatsCharts.line(t.dailyTrend, cs),
        ),
      StatsChartCard(
        title: l10n.statsPeriodTrend,
        moduleColor: c,
        child: StatsCharts.bar(t.bucketTrend, cs, labels: bucketLabels),
      ),
      StatsChartCard(
        title: l10n.statsActivityHeatmap,
        moduleColor: c,
        height: 260,
        fullWidth: true,
        child: StatsCharts.heatMap(
          t.heatMap,
          cs,
          snap.period.days.clamp(14, 90),
        ),
      ),
      if (t.tagDistribution.isNotEmpty)
        StatsChartCard(
          title: l10n.statsTagDistribution,
          moduleColor: c,
          child: StatsCharts.pieWithLegend(t.tagDistribution, cs),
        ),
      StatsChartCard(
        title: l10n.statsHourlyDensity,
        moduleColor: c,
        height: 200,
        child: StatsCharts.hourly(t.hourlyBreakdown, cs),
      ),
      if (t.timeSlotPie.isNotEmpty)
        StatsChartCard(
          title: l10n.statsIntradayDistribution,
          moduleColor: c,
          child: StatsCharts.pieWithLegend(t.timeSlotPie, cs, accent: c),
        ),
      if (t.weekdayPieL10n(l10n).isNotEmpty)
        StatsChartCard(
          title: l10n.statsWeekdayDistribution,
          moduleColor: c,
          height: 200,
          child: StatsCharts.bar(
            t.weekdayBreakdown.values.map((e) => e.toDouble()).toList(),
            cs,
            labels: t.weekdayPieL10n(l10n).keys.toList(),
          ),
        ),
    ];
  }

  static List<Widget> habits(
    StatisticsSnapshot snap,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    final h = snap.habits;
    const c = StatsModulePalette.habits;
    return [
      StatsChartCard(
        title: l10n.statsComplianceRate,
        moduleColor: c,
        height: 200,
        child: StatsCharts.pieWithLegend(h.completionPieL10n(l10n), cs, accent: c),
      ),
      StatsChartCard(
        title: l10n.statsPeriodCompliance,
        moduleColor: c,
        height: 180,
        child: StatsCharts.ring(h.periodCompletionRate, c, cs),
      ),
      if (h.activityPie.isNotEmpty)
        StatsChartCard(
          title: l10n.statsActivitySummary,
          moduleColor: c,
          child: StatsCharts.pieWithLegend(h.activityPie, cs, accent: c),
        ),
    ];
  }

  static List<Widget> budget(
    StatisticsSnapshot snap,
    ColorScheme cs,
    Map<String, double> catPie,
    AppLocalizations l10n,
  ) {
    const c = StatsModulePalette.budget;
    return [
      StatsChartCard(
        title: l10n.statsIncomeExpense,
        moduleColor: c,
        child: StatsCharts.pieWithLegend(
          snap.budget.incomeExpensePieL10n(l10n),
          cs,
          colors: [Colors.green, Colors.red],
        ),
      ),
      if (catPie.isNotEmpty)
        StatsChartCard(
          title: l10n.statsExpenseCategories,
          moduleColor: c,
          child: StatsCharts.pieWithLegend(catPie, cs),
        ),
      if (snap.budget.transactionCountPieL10n(l10n).isNotEmpty)
        StatsChartCard(
          title: l10n.statsTransactionCount,
          moduleColor: c,
          child: StatsCharts.pieWithLegend(
            snap.budget.transactionCountPieL10n(l10n),
            cs,
            accent: c,
          ),
        ),
      StatsChartCard(
        title: l10n.statsCashFlow,
        moduleColor: c,
        height: 200,
        fullWidth: true,
        child: StatsCharts.incomeExpenseBar(snap.budget, cs),
      ),
      if (snap.period.days <= 31 &&
          snap.budget.dailyExpenseTrend.isNotEmpty)
        StatsChartCard(
          title: l10n.statsDailyExpense,
          moduleColor: c,
          height: 180,
          child: StatsCharts.line(snap.budget.dailyExpenseTrend, cs),
        ),
      if (snap.period.days <= 31 &&
          snap.budget.dailyIncomeTrend.isNotEmpty)
        StatsChartCard(
          title: l10n.statsDailyIncome,
          moduleColor: c,
          height: 180,
          child: StatsCharts.line(
            snap.budget.dailyIncomeTrend,
            cs,
            lineColor: Colors.green,
          ),
        ),
    ];
  }

  static List<Widget> notes(
    StatisticsSnapshot snap,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    final n = snap.notes;
    const c = StatsModulePalette.notes;
    return [
      if (n.categoryPieL10n(l10n).isNotEmpty)
        StatsChartCard(
          title: l10n.statsCategoryDistribution,
          moduleColor: c,
          child: StatsCharts.pieWithLegend(n.categoryPieL10n(l10n), cs, accent: c),
        ),
      StatsChartCard(
        title: l10n.statsNoteActivity,
        moduleColor: c,
        height: 180,
        child: StatsCharts.notesActivityBar(n, cs),
      ),
      if (n.engagementPieL10n(l10n).isNotEmpty)
        StatsChartCard(
          title: l10n.statsEngagementDistribution,
          moduleColor: c,
          child: StatsCharts.pieWithLegend(n.engagementPieL10n(l10n), cs, accent: c),
        ),
    ];
  }

  static List<Widget> appointments(
    StatisticsSnapshot snap,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    final a = snap.appointments;
    const c = StatsModulePalette.appointments;
    return [
      StatsChartCard(
        title: l10n.statsAppointmentStatuses,
        moduleColor: c,
        child: StatsCharts.pieWithLegend(
          a.statusPieL10n(l10n),
          cs,
          accent: c,
        ),
      ),
      if (a.countBarL10n(l10n).isNotEmpty)
        StatsChartCard(
          title: l10n.statsAppointmentCounts,
          moduleColor: c,
          height: 200,
          child: StatsCharts.bar(
            a.countBarL10n(l10n).values.toList(),
            cs,
            labels: a.countBarL10n(l10n).keys.toList(),
          ),
        ),
      if (a.totalRevenue > 0)
        StatsChartCard(
          title: l10n.statsRevenueSummary,
          moduleColor: c,
          height: 160,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '₺${a.totalRevenue.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: c,
                  ),
                ),
                Text(
                  l10n.statsFromCompletedAppointments,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  static List<Widget> medications(
    StatisticsSnapshot snap,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    final m = snap.medications;
    const c = StatsModulePalette.medications;
    return [
      StatsChartCard(
        title: l10n.statsDoseCompliance,
        moduleColor: c,
        child: StatsCharts.pieWithLegend(m.adherencePie, cs, accent: c),
      ),
      StatsChartCard(
        title: l10n.statsCompliancePercent,
        moduleColor: c,
        height: 200,
        child: StatsCharts.ring(m.adherenceRate, c, cs),
      ),
      if (m.stockPie.isNotEmpty)
        StatsChartCard(
          title: l10n.statsStatusDistribution,
          moduleColor: c,
          child: StatsCharts.pieWithLegend(m.stockPie, cs, accent: c),
        ),
    ];
  }

  static List<Widget> books(
    StatisticsSnapshot snap,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    final b = snap.books;
    const c = StatsModulePalette.books;
    return [
      StatsChartCard(
        title: l10n.statsModuleBooks,
        moduleColor: c,
        child: StatsCharts.pieWithLegend(
          b.statusBreakdown,
          cs,
          accent: c,
        ),
      ),
      if (b.pagesRead > 0 || b.finishedInPeriod > 0)
        StatsChartCard(
          title: l10n.statsActivitySummary,
          moduleColor: c,
          height: 180,
          child: StatsCharts.bar(
            [
              b.reading.toDouble(),
              b.finishedInPeriod.toDouble(),
              b.startedInPeriod.toDouble(),
            ],
            cs,
            labels: [
              l10n.statsBookReading,
              l10n.statsBookFinished,
              l10n.statsBookNew,
            ],
          ),
        ),
    ];
  }

  static List<Widget> teams(
    StatisticsSnapshot snap,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    const c = StatsModulePalette.teams;
    return [
      StatsChartCard(
        title: l10n.statsModuleTeams,
        moduleColor: c,
        child: StatsCharts.pieWithLegend(
          snap.teams.memberByTeam,
          cs,
          accent: c,
        ),
      ),
    ];
  }

  static List<Widget> corkboard(
    StatisticsSnapshot snap,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    final cb = snap.corkboard;
    const c = StatsModulePalette.corkboard;
    return [
      StatsChartCard(
        title: l10n.statsCorkboardLabel,
        moduleColor: c,
        child: StatsCharts.pieWithLegend(
          cb.compositionPieL10n(l10n),
          cs,
          accent: c,
        ),
      ),
      if (cb.typePie.isNotEmpty)
        StatsChartCard(
          title: l10n.statsCategoryDistribution,
          moduleColor: c,
          child: StatsCharts.pieWithLegend(cb.typePie, cs, accent: c),
        ),
    ];
  }
}

class StatsCharts {
  static Widget noData(ColorScheme cs) => _noData(cs);

  static Widget ring(
    double percent,
    Color color,
    ColorScheme cs, {
    String label = '',
  }) {
    final v = (percent / 100).clamp(0.0, 1.0);
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: v,
              strokeWidth: 10,
              strokeCap: StrokeCap.butt,
              backgroundColor: color.withOpacity(0.15),
              color: color,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${percent.toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                      color: cs.onSurface,
                    ),
                  ),
                  if (label.isNotEmpty)
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        height: 1.0,
                        color: cs.onSurface.withOpacity(0.45),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modül özeti kartı: pasta üstte ortalı, legend altta (çakışma yok).
  static Widget pieOverviewLayout(
    Map<String, double> dist,
    Color accent,
    ColorScheme cs,
  ) {
    if (dist.isEmpty) return _noData(cs);
    final total = dist.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return _noData(cs);

    final entries = dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final legendRows = entries.take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 150;
        final lineHeight = compact ? 13.0 : 16.0;
        final legendFontSize = compact ? 9.0 : 11.0;
        final legendH = legendRows.length * lineHeight + 4;
        final chartH =
            (constraints.maxHeight - legendH).clamp(0.0, double.infinity);
        final pieSide = math
            .min(constraints.maxWidth * 0.9, chartH)
            .clamp(compact ? 36.0 : 48.0, 160.0);

        if (pieSide < 32 || chartH < 28) {
          return _noData(cs);
        }

        final showSliceLabels = pieSide >= 68;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: pieSide,
                  height: pieSide,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: pieSide < 56 ? 1 : 2,
                      centerSpaceRadius: pieSide * 0.24,
                      sections: entries.asMap().entries.map((e) {
                        final c = Color.lerp(
                          accent,
                          accent.withOpacity(0.45),
                          e.key * 0.2,
                        )!;
                        final pct = e.value.value / total * 100;
                        return PieChartSectionData(
                          value: e.value.value,
                          color: c,
                          radius: pieSide * 0.38,
                          showTitle: showSliceLabels && pct >= 8,
                          title: '${pct.toStringAsFixed(0)}%',
                          titleStyle: GoogleFonts.outfit(
                            fontSize: (pieSide * 0.1).clamp(8.0, 14.0),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: legendH,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final e in legendRows)
                    SizedBox(
                      height: lineHeight,
                      child: Text(
                        '${e.key} · ${(e.value / total * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.outfit(
                          fontSize: legendFontSize,
                          height: 1.0,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.72),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Modül özeti kartı: halka üstte ortalı, etiket altta.
  static Widget ringOverviewLayout(
    double percent,
    Color color,
    ColorScheme cs, {
    String label = 'uyum',
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const legendH = 14.0;
        final chartH =
            (constraints.maxHeight - legendH).clamp(0.0, double.infinity);
        final side = math
            .min(constraints.maxWidth * 0.85, chartH)
            .clamp(32.0, 88.0);
        final stroke = (side * 0.1).clamp(5.0, 10.0);
        final v = (percent / 100).clamp(0.0, 1.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: side,
                  height: side,
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: v,
                        strokeWidth: stroke,
                        strokeCap: StrokeCap.butt,
                        backgroundColor: color.withOpacity(0.15),
                        color: color,
                      ),
                      Center(
                        child: Text(
                          '${percent.toStringAsFixed(0)}%',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: (side * 0.22).clamp(14.0, 20.0),
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (label.isNotEmpty)
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: cs.onSurface.withOpacity(0.55),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Özet kartları: dilim + kategori adı (yüzde tek başına değil).
  static Widget pieCompactWithLegend(
    Map<String, double> dist,
    Color accent,
    ColorScheme cs, {
    bool stacked = false,
    double? chartSize,
  }) {
    if (dist.isEmpty) return _noData(cs);
    final total = dist.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return _noData(cs);

    final entries = dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Widget pie(double size, double radius) {
      return SizedBox(
        width: size,
        height: size,
        child: PieChart(
          PieChartData(
            sectionsSpace: 1,
            centerSpaceRadius: size * 0.27,
            sections: entries.asMap().entries.map((e) {
              final c = Color.lerp(
                accent,
                accent.withOpacity(0.45),
                e.key * 0.2,
              )!;
              return PieChartSectionData(
                value: e.value.value,
                color: c,
                radius: radius,
                showTitle: false,
              );
            }).toList(),
          ),
        ),
      );
    }

    Widget legendLine(String text, {double? fontSize}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: fontSize ?? (stacked ? 10 : 9),
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withOpacity(0.75),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: stacked ? TextAlign.center : TextAlign.start,
        ),
      );
    }

    final legendItems = entries.take(3).map((e) {
      final pct = e.value / total * 100;
      return legendLine('${e.key} · ${pct.toStringAsFixed(0)}%');
    }).toList();

    if (stacked) {
      final size = chartSize ?? 72;
      final radius = size * 0.38;
      final legendSize = (size * 0.14).clamp(10.0, 12.0);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: pie(size, radius)),
          SizedBox(height: size > 80 ? 8 : 6),
          for (final e in entries.take(3))
            legendLine(
              '${e.key} · ${(e.value / total * 100).toStringAsFixed(0)}%',
              fontSize: legendSize,
            ),
        ],
      );
    }

    final rowSize = chartSize ?? 52;
    return Row(
      children: [
        pie(rowSize, rowSize * 0.38),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: legendItems,
          ),
        ),
      ],
    );
  }

  static Widget pieCompact(
    Map<String, double> dist,
    Color accent,
    ColorScheme cs,
  ) {
    if (dist.isEmpty) return _noData(cs);
    final total = dist.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return _noData(cs);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side =
            (constraints.maxWidth < constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight)
                .clamp(48.0, 160.0);
        final radius = side * 0.38;
        final centerSpace = side * 0.28;
        final titleSize = (side * 0.12).clamp(9.0, 12.0);

        return PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: centerSpace,
            sections: dist.entries.toList().asMap().entries.map((e) {
              final c =
                  Color.lerp(accent, accent.withOpacity(0.45), e.key * 0.2)!;
              final pct = e.value.value / total * 100;
              return PieChartSectionData(
                value: e.value.value,
                color: c,
                radius: radius,
                showTitle: pct >= 14 && side >= 72,
                title: '${pct.toStringAsFixed(0)}%',
                titleStyle: GoogleFonts.outfit(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  static Widget ringCompact(
    double percent,
    Color color,
    ColorScheme cs, {
    String label = '',
    double? size,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = size ??
            (constraints.maxWidth < constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight)
                .clamp(48.0, 160.0);
        final stroke = (side * 0.1).clamp(6.0, 11.0);
        final v = (percent / 100).clamp(0.0, 1.0);
        final fontSize = (side * 0.2).clamp(14.0, 22.0);

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: side,
              height: side,
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: stroke,
                strokeCap: StrokeCap.butt,
                backgroundColor: color.withOpacity(0.15),
                color: color,
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${percent.toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                      color: cs.onSurface,
                    ),
                  ),
                  if (label.isNotEmpty)
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 8,
                        height: 1.0,
                        color: cs.onSurface.withOpacity(0.45),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget noDataCompact(ColorScheme cs) {
    return Center(
      child: Icon(
        Icons.pie_chart_outline_rounded,
        size: 28,
        color: cs.onSurface.withOpacity(0.2),
      ),
    );
  }

  static Widget pieWithLegend(
    Map<String, double> dist,
    ColorScheme cs, {
    Color? accent,
    List<Color>? colors,
  }) {
    if (dist.isEmpty) return _noData(cs);
    final palette = colors ??
        [
          accent ?? cs.primary,
          Colors.orange,
          Colors.green,
          Colors.purple,
          Colors.cyan,
          Colors.pink,
          Colors.amber,
        ];
    final total = dist.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return _noData(cs);

    var i = 0;
    final entries = dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                sections: entries.map((e) {
                  final c = palette[i % palette.length];
                  i++;
                  final pct = e.value / total * 100;
                  return PieChartSectionData(
                    value: e.value,
                    color: c,
                    radius: 52,
                    title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                    titleStyle: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.take(5).map((e) {
              final idx = entries.indexOf(e);
              final c = palette[idx % palette.length];
              final pct = e.value / total * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${e.key} ${pct.toStringAsFixed(0)}%',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  static Widget moduleBars(
    List<({String label, double score, Color color, String hint})> items,
    ColorScheme cs, {
    String? noDataLabel,
  }) {
    if (items.isEmpty) return _noData(cs, noDataLabel);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (v) => FlLine(
            color: cs.outline.withOpacity(0.08),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i >= 0 && i < items.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      items[i].label,
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 25,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  color: cs.onSurface.withOpacity(0.4),
                ),
              ),
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i >= 0 && i < items.length) {
                  return Text(
                    items[i].score.toStringAsFixed(0),
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: items[i].color,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(),
        ),
        barGroups: items.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.score.clamp(0, 100),
                color: e.value.color.withOpacity(0.85),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  static Widget incomeExpenseBar(BudgetPeriodStats b, ColorScheme cs) {
    final max = [b.totalIncome, b.totalExpense].reduce((a, c) => a > c ? a : c);
    if (max <= 0) return _noData(cs);
    return BarChart(
      BarChartData(
        maxY: max * 1.15,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                const labels = ['Gelir', 'Gider', 'Net'];
                final i = v.toInt();
                if (i >= 0 && i < labels.length) {
                  return Text(
                    labels[i],
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: cs.onSurface.withOpacity(0.55),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: b.totalIncome,
                color: Colors.green,
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: b.totalExpense,
                color: Colors.red,
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: b.net.abs(),
                color: b.net >= 0 ? cs.primary : Colors.orange,
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget notesActivityBar(NotesPeriodStats n, ColorScheme cs) {
    final data = [
      n.created.toDouble(),
      n.updated.toDouble(),
      n.favorites.toDouble(),
      n.pinned.toDouble(),
    ];
    if (data.every((d) => d == 0)) return _noData(cs);
    const labels = ['Yeni', 'Güncel', 'Favori', 'Sabit'];
    return bar(data, cs, labels: labels);
  }

  static Widget line(
    List<FlSpot> spots,
    ColorScheme cs, {
    Color? lineColor,
  }) {
    if (spots.isEmpty || spots.every((s) => s.y == 0)) {
      return _noData(cs);
    }
    final color = lineColor ?? cs.primary;
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: cs.primary.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  static Widget bar(List<double> data, ColorScheme cs, {List<String>? labels}) {
    if (data.every((d) => d == 0)) return _noData(cs);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: labels != null
              ? AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i >= 0 && i < labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 8,
                              color: cs.onSurface.withOpacity(0.4),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                )
              : const AxisTitles(),
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        barGroups: data
            .asMap()
            .entries
            .map(
              (e) => BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value,
                    color: cs.primary,
                    width: 14,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  static Widget pie(Map<String, double> dist, ColorScheme cs) =>
      pieWithLegend(dist, cs);

  static Widget heatMap(Map<DateTime, int> data, ColorScheme cs, int days) {
    return HeatMap(
      datasets: data,
      scrollable: true,
      colorsets: {
        1: cs.primary.withOpacity(0.2),
        3: cs.primary.withOpacity(0.45),
        5: cs.primary.withOpacity(0.65),
        8: cs.primary,
      },
      defaultColor: cs.onSurface.withOpacity(0.05),
      textColor: cs.onSurface,
      startDate: DateTime.now().subtract(Duration(days: days - 1)),
      endDate: DateTime.now(),
    );
  }

  static Widget hourly(Map<int, int> data, ColorScheme cs) {
    final max = data.values.fold(0, (a, b) => a > b ? a : b);
    if (max == 0) return _noData(cs);
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 4,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}',
                style: TextStyle(
                  fontSize: 8,
                  color: cs.onSurface.withOpacity(0.35),
                ),
              ),
            ),
          ),
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        barGroups: List.generate(24, (h) {
          return BarChartGroupData(
            x: h,
            barRods: [
              BarChartRodData(
                toY: (data[h] ?? 0).toDouble(),
                color: cs.primary.withOpacity(0.75),
                width: 6,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  static Widget _noData(ColorScheme cs, [String? message]) {
    return Center(
      child: Text(
        message ?? 'No data for this period',
        style: GoogleFonts.outfit(
          color: cs.onSurface.withOpacity(0.35),
          fontSize: 13,
        ),
      ),
    );
  }
}
