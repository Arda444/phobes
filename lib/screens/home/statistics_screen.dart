import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/module_info_catalog.dart';
import '../../core/stats_module_palette.dart';
import '../../core/module_ui_tokens.dart';
import '../../core/phobes_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/statistics_models.dart';
import '../../models/statistics_models_l10n.dart';
import '../../services/statistics_aggregator.dart';
import '../../services/statistics_export_service.dart';
import '../../widgets/phobes_module_header.dart';
import '../../widgets/phobes_widgets.dart';
import 'statistics/statistics_widgets.dart';

class StatisticsScreen extends StatefulWidget {
  /// Optional period to show when the screen opens (e.g. coming from the
  /// calendar's weekly summary card).
  final StatsPeriod? initialPeriod;

  const StatisticsScreen({super.key, this.initialPeriod});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsAggregator _aggregator = StatisticsAggregator.instance;

  late StatsPeriod _period;
  StatisticsSnapshot? _snapshot;
  bool _isLoading = true;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod ?? StatsPeriod.week;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
      _statusMessage = l10n?.statsLoading ?? 'Loading data…';
    });

    try {
      if (force) _aggregator.clearCache();
      await _aggregator.loadAll(
        onProgress: (msg) {
          if (mounted) setState(() => _statusMessage = msg);
        },
      );
      if (!mounted) return;
      setState(() {
        _snapshot = _aggregator.compute(_period);
        _isLoading = false;
        _statusMessage = '';
      });
    } catch (e) {
      debugPrint('Statistics load error: $e');
      if (mounted) {
        setState(() {
          _snapshot = null;
          _isLoading = false;
          _statusMessage = l10n?.statsLoadFailed ?? 'Could not load statistics.';
        });
      }
    }
  }

  void _onPeriodChanged(StatsPeriod p) {
    setState(() {
      _period = p;
      _snapshot = _aggregator.compute(p);
    });
  }

  Future<void> _runExport({
    required bool pdf,
    required bool share,
  }) async {
    final snap = _snapshot;
    if (snap == null || !mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    // Paylaşımda SnackBar gösterme: native sheet ile üst üste binince bazı
    // cihazlarda modal bariyeri / açık gri ekranda kalma sorununa yol açıyor.
    if (!share) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.statsExporting),
          duration: const Duration(seconds: 30),
        ),
      );
    }

    try {
      final exporter = StatisticsExportService.instance;
      if (share) {
        if (pdf) {
          await exporter.sharePdf(snap, appTitle: l10n.appTitle);
        } else {
          await exporter.shareExcel(snap, appTitle: l10n.appTitle);
        }
      } else {
        if (pdf) {
          await exporter.downloadPdf(snap, appTitle: l10n.appTitle);
        } else {
          await exporter.downloadExcel(snap, appTitle: l10n.appTitle);
        }
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.statsDownloadSuccess)),
          );
        }
      }
    } catch (e, st) {
      debugPrint('Statistics export error: $e\n$st');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.statsExportFailed}\n${e.toString()}',
              style: GoogleFonts.outfit(fontSize: 13),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (!share) {
        messenger.hideCurrentSnackBar();
      }
    }
  }

  /// Alt sayfa kapanmadan paylaşım açılırsa modal bariyeri takılabiliyor.
  Future<void> _closeSheetAndExport({
    required BuildContext sheetContext,
    required bool pdf,
    required bool share,
  }) async {
    if (Navigator.canPop(sheetContext)) {
      Navigator.pop(sheetContext);
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await _runExport(pdf: pdf, share: share);
  }

  void _showShareSheet() => _showFormatSheet(share: true);

  void _showDownloadSheet() => _showFormatSheet(share: false);

  void _showFormatSheet({required bool share}) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final period = _snapshot?.period.labelOf(l10n) ?? '';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    share ? l10n.statsShareReport : l10n.statsDownloadReport,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                _exportFormatTile(
                  ctx: ctx,
                  cs: cs,
                  share: share,
                  icon: Icons.description_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: share ? l10n.statsSharePdf : l10n.statsDownloadPdf,
                  subtitle: '$period · ${l10n.statsExportPdf}',
                  onTap: () => _closeSheetAndExport(
                    sheetContext: ctx,
                    pdf: true,
                    share: share,
                  ),
                ),
                _exportFormatTile(
                  ctx: ctx,
                  cs: cs,
                  share: share,
                  icon: Icons.table_chart_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: share ? l10n.statsShareExcel : l10n.statsDownloadExcel,
                  subtitle: '$period · ${l10n.statsExportExcel}',
                  onTap: () => _closeSheetAndExport(
                    sheetContext: ctx,
                    pdf: false,
                    share: share,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _exportFormatTile({
    required BuildContext ctx,
    required ColorScheme cs,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool share,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: iconColor.withOpacity(0.35)),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                share ? Icons.share_rounded : Icons.arrow_downward_rounded,
                color: cs.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 900;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value && isDark;

    final headerSubtitle = _isLoading
        ? _statusMessage
        : _snapshot == null
            ? l10n.noData
            : l10n.statsPeriodSummarySubtitle(
                _snapshot!.period.shortLabelOf(l10n),
                _snapshot!.totalActions,
              );

    return Scaffold(
      backgroundColor: isAmoled ? Colors.black : cs.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhobesModuleHeaderBar(
            title: l10n.statistics,
            icon: Icons.analytics_rounded,
            subtitle: headerSubtitle,
            info: ModuleInfoCatalog.forStatistics(l10n),
            extraActions: [
              Tooltip(
                message: l10n.statsShare,
                child: PhobesModuleHeaderIconButton(
                  icon: Icons.share_rounded,
                  onTap: _snapshot == null ? () {} : _showShareSheet,
                ),
              ),
              Tooltip(
                message: l10n.statsDownload,
                child: PhobesModuleHeaderIconButton(
                  icon: Icons.arrow_downward_rounded,
                  onTap: _snapshot == null ? () {} : _showDownloadSheet,
                ),
              ),
              PhobesModuleHeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: () => _load(force: true),
              ),
            ],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PhobesLoadingIndicator(color: cs.primary),
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage,
                            style: GoogleFonts.outfit(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _snapshot == null
                      ? Center(child: Text(l10n.noData))
                      : RefreshIndicator(
                          onRefresh: () => _load(force: true),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 32 : 16,
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final contentW = constraints.maxWidth;
                                final cols = statsOverviewColumns(contentW);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 16),
                                    StatsPeriodSelector(
                                      selected: _period,
                                      onChanged: _onPeriodChanged,
                                    ),
                                    const SizedBox(height: 16),
                                    StatsGlobalSummary(
                                      snapshot: _snapshot!,
                                      contentWidth: contentW,
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      l10n.statsModuleSummary,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    StatsModuleOverviewGrid(
                                      snapshot: _snapshot!,
                                      crossAxisCount: cols,
                                    ),
                                    const SizedBox(height: 28),
                                    Text(
                                      l10n.statsDetailedStats,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.statsAllModulesPeriod(
                                          _snapshot!.period.labelOf(l10n),),
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: cs.onSurface.withOpacity(0.45),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildAllModuleSections(_snapshot!, cs, l10n),
                                    SizedBox(
                                      height: ModuleUiTokens.bottomNavInset(
                                        context,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllModuleSections(
    StatisticsSnapshot snap,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    final t = snap.tasks;
    final bucketLabels = snap.period == StatsPeriod.quarter
        ? List.generate(12, (i) => '${i + 1}')
        : const ['D1', 'D2', 'D3', 'D4'];
    final catPie = _normalizeCategoryPie(snap.budget.categoryBreakdown);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatsModuleSection(
          title: l10n.statsModuleTasks,
          icon: Icons.task_alt_rounded,
          color: StatsModulePalette.tasks,
          metrics: t.primaryMetricsL10n(l10n),
          panels: StatsModuleCharts.tasks(snap, cs, bucketLabels, l10n),
        ),
        StatsModuleSection(
          title: l10n.statsModuleHabits,
          icon: Icons.spa_rounded,
          color: StatsModulePalette.habits,
          metrics: snap.habits.metricsL10n(l10n),
          panels: StatsModuleCharts.habits(snap, cs, l10n),
        ),
        StatsModuleSection(
          title: l10n.statsModuleBudget,
          icon: Icons.account_balance_wallet_rounded,
          color: StatsModulePalette.budget,
          metrics: snap.budget.metricsL10n(l10n),
          panels: StatsModuleCharts.budget(snap, cs, catPie, l10n),
        ),
        StatsModuleSection(
          title: l10n.statsModuleNotes,
          icon: Icons.note_alt_rounded,
          color: StatsModulePalette.notes,
          metrics: snap.notes.metricsL10n(l10n),
          panels: StatsModuleCharts.notes(snap, cs, l10n),
        ),
        StatsModuleSection(
          title: l10n.statsModuleAppointments,
          icon: Icons.event_available_rounded,
          color: StatsModulePalette.appointments,
          metrics: snap.appointments.metricsL10n(l10n),
          panels: StatsModuleCharts.appointments(snap, cs, l10n),
        ),
        StatsModuleSection(
          title: l10n.statsModuleMedications,
          icon: Icons.medication_rounded,
          color: StatsModulePalette.medications,
          metrics: snap.medications.metricsL10n(l10n),
          panels: StatsModuleCharts.medications(snap, cs, l10n),
        ),
        StatsModuleSection(
          title: l10n.statsModuleBooks,
          icon: Icons.menu_book_rounded,
          color: StatsModulePalette.books,
          metrics: snap.books.metricsL10n(l10n),
          panels: StatsModuleCharts.books(snap, cs, l10n),
        ),
        StatsModuleSection(
          title: l10n.statsModuleTeams,
          icon: Icons.groups_rounded,
          color: StatsModulePalette.teams,
          metrics: snap.teams.metricsL10n(l10n),
          panels: snap.teams.memberByTeam.isNotEmpty
              ? StatsModuleCharts.teams(snap, cs, l10n)
              : const [],
        ),
        StatsModuleSection(
          title: l10n.statsCorkboardLabel,
          icon: Icons.dashboard_customize_rounded,
          color: StatsModulePalette.corkboard,
          metrics: snap.corkboard.metricsL10n(l10n),
          panels: snap.corkboard.compositionPieL10n(l10n).isNotEmpty
              ? StatsModuleCharts.corkboard(snap, cs, l10n)
              : const [],
        ),
      ],
    );
  }

  Map<String, double> _normalizeCategoryPie(Map<String, double> raw) {
    if (raw.isEmpty) return {};
    final total = raw.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return {};
    return raw.map((k, v) => MapEntry(k, (v / total) * 100));
  }
}
