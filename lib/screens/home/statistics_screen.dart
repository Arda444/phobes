import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../../services/firebase_service.dart';
import '../../services/nova_service.dart';
import '../../models/task_model.dart';
import '../../l10n/app_localizations.dart';
import '../../core/phobes_theme.dart';
import '../../widgets/phobes_widgets.dart';

class AppStats {
  final double completionRate;
  final int streak;
  final int totalCompleted;
  final int totalPending;
  final double productivityScore;
  final int totalFocusMinutes;
  final String mostProductiveTimeOfDay;
  final Map<int, int> hourlyBreakdown;
  final Map<String, double> tagDistribution;
  final List<double> weeklyTrend;
  final List<FlSpot> dailyActivityLine;
  final Map<DateTime, int> heatMapDataSet;
  final Map<int, int> priorityBreakdown;
  final String busiestDayOfWeek;
  final double avgTaskDurationMinutes;

  AppStats({
    required this.completionRate,
    required this.streak,
    required this.totalCompleted,
    required this.totalPending,
    required this.productivityScore,
    required this.totalFocusMinutes,
    required this.mostProductiveTimeOfDay,
    required this.hourlyBreakdown,
    required this.tagDistribution,
    required this.weeklyTrend,
    required this.dailyActivityLine,
    required this.heatMapDataSet,
    required this.priorityBreakdown,
    required this.busiestDayOfWeek,
    required this.avgTaskDurationMinutes,
  });
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  AppStats? _currentStats;
  bool _isLoading = true;
  String _statusMessage = "";
  final FirebaseService _firebaseService = FirebaseService();
  final NovaService _novaService = NovaService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStats();
    });
  }

  void _refreshStats() {
    _loadAndAnalyzeData();
  }

  Future<void> _askNovaAnalysis() async {
    if (_currentStats == null) return;

    final summary = """
    Tamamlanan: ${_currentStats!.totalCompleted}, 
    Verimlilik: ${_currentStats!.productivityScore.toInt()}, 
    Seri: ${_currentStats!.streak} gün,
    Odak Süresi: ${_currentStats!.totalFocusMinutes} dk.
    """;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.teal)),
    );

    final advice = await _novaService.analyzeBurnout(summary);

    if (mounted) {
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (ctx) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            backgroundColor: cs.surfaceContainerHigh,
            icon: Icon(Icons.monitor_heart, color: cs.primary, size: 40),
            title: Text("Nova Sağlık Raporu",
                style: GoogleFonts.outfit(
                    color: cs.onSurface, fontWeight: FontWeight.bold)),
            content: Text(advice ?? "Şu an analiz yapamıyorum.",
                style: GoogleFonts.outfit(
                    color: cs.onSurface.withValues(alpha: 0.8))),
            actions: [
              PhobesButton(
                text: "Tamam",
                onPressed: () => Navigator.pop(ctx),
              )
            ],
          );
        },
      );
    }
  }

  Future<void> _loadAndAnalyzeData() async {
    final l10n = AppLocalizations.of(context)!;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _statusMessage = l10n.fetchingData;
    });

    try {
      List<Task> tasks;
      try {
        tasks = await _firebaseService.getTasksForStats();
      } catch (e) {
        debugPrint("Hata (Stats): $e");
        tasks = await _firebaseService.getAllUserTasksStream().first;
      }

      if (tasks.isEmpty) {
        if (mounted) {
          setState(() {
            _currentStats = _getEmptyStats();
            _isLoading = false;
          });
        }
        return;
      }

      if (!mounted) return;
      setState(() => _statusMessage = l10n.analyzingData(tasks.length));
      await Future.delayed(const Duration(milliseconds: 50));

      final DateTime today = DateUtils.dateOnly(DateTime.now());
      final DateTime analysisStartDate =
          DateUtils.addMonthsToMonthDate(today, -12);
      final DateTime analysisEndDate = DateUtils.addDaysToDate(today, 30);

      List<Task> processedTasks = [];

      for (int i = 0; i < tasks.length; i++) {
        if (i % 50 == 0) await Future.delayed(Duration.zero);

        final task = tasks[i];

        if (task.repeatRule == 'none') {
          if (!task.startTime.isAfter(analysisEndDate) &&
              !task.startTime.isBefore(analysisStartDate)) {
            processedTasks.add(task);
          }
        } else {
          DateTime nextDate = task.startTime;
          int safety = 0;
          while (nextDate.isBefore(analysisEndDate)) {
            safety++;
            if (safety > 400) break;

            if (!nextDate.isBefore(analysisStartDate)) {
              processedTasks.add(task.copyWith(
                startTime: DateTime(nextDate.year, nextDate.month, nextDate.day,
                    task.startTime.hour, task.startTime.minute),
                endTime: DateTime(nextDate.year, nextDate.month, nextDate.day,
                    task.endTime.hour, task.endTime.minute),
              ));
            }

            if (task.repeatRule == 'daily') {
              nextDate = nextDate.add(const Duration(days: 1));
            } else if (task.repeatRule == 'weekly') {
              nextDate = nextDate.add(const Duration(days: 7));
            } else if (task.repeatRule == 'monthly') {
              int newMonth = nextDate.month + 1;
              int newYear = nextDate.year;
              if (newMonth > 12) {
                newMonth = 1;
                newYear++;
              }
              int day = task.startTime.day;
              int daysInNextMonth = DateUtils.getDaysInMonth(newYear, newMonth);
              if (day > daysInNextMonth) day = daysInNextMonth;
              nextDate = DateTime(newYear, newMonth, day, task.startTime.hour,
                  task.startTime.minute);
            } else {
              break;
            }
          }
        }
      }

      if (!mounted) return;
      setState(() => _statusMessage = l10n.generatingCharts);
      await Future.delayed(Duration.zero);

      final pastTasks =
          processedTasks.where((t) => !t.startTime.isAfter(today)).toList();
      final completedTasks = pastTasks.where((t) => t.isCompleted).toList();

      final totalCompleted = completedTasks.length;
      final totalPending = pastTasks.length - totalCompleted;
      final completionRate =
          (pastTasks.isEmpty) ? 0.0 : (totalCompleted / pastTasks.length) * 100;

      final completionDays = {
        for (var t in completedTasks) DateUtils.dateOnly(t.startTime): true
      };
      int streak = 0;
      for (int i = 0; i < 365; i++) {
        if (completionDays.containsKey(today.subtract(Duration(days: i)))) {
          streak++;
        } else if (i == 0 && !completionDays.containsKey(today)) {
          continue;
        } else {
          break;
        }
      }

      int totalFocusMinutes = 0;
      Map<String, int> timeOfDayCount = {
        "Sabah": 0,
        "Öğle": 0,
        "Akşam": 0,
        "Gece": 0
      };
      Map<int, int> hourlyBreakdown = {for (var i = 0; i < 24; i++) i: 0};
      Map<int, int> weekdayCount = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

      for (var t in completedTasks) {
        int duration =
            t.isAllDay ? 60 : t.endTime.difference(t.startTime).inMinutes.abs();
        totalFocusMinutes += duration;
        weekdayCount[t.startTime.weekday] =
            (weekdayCount[t.startTime.weekday] ?? 0) + 1;

        if (!t.isAllDay) {
          int hour = t.startTime.hour;
          if (hour >= 0 && hour < 24) {
            hourlyBreakdown[hour] = (hourlyBreakdown[hour] ?? 0) + 1;
          }
          if (hour >= 5 && hour < 12) {
            timeOfDayCount["Sabah"] = (timeOfDayCount["Sabah"] ?? 0) + 1;
          } else if (hour >= 12 && hour < 17) {
            timeOfDayCount["Öğle"] = (timeOfDayCount["Öğle"] ?? 0) + 1;
          } else if (hour >= 17 && hour < 22) {
            timeOfDayCount["Akşam"] = (timeOfDayCount["Akşam"] ?? 0) + 1;
          } else {
            timeOfDayCount["Gece"] = (timeOfDayCount["Gece"] ?? 0) + 1;
          }
        }
      }

      String mostProductiveTime = "-";
      if (completedTasks.isNotEmpty) {
        var sortedTimes = timeOfDayCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        if (sortedTimes.isNotEmpty && sortedTimes.first.value > 0) {
          mostProductiveTime = sortedTimes.first.key;
        }
      }

      String busiestDay = "-";
      if (completedTasks.isNotEmpty) {
        var sortedDays = weekdayCount.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        if (sortedDays.last.value > 0) {
          busiestDay = _getDayName(sortedDays.last.key);
        }
      }

      double avgDuration =
          totalCompleted > 0 ? totalFocusMinutes / totalCompleted : 0;

      Map<String, double> tagCount = {};
      for (var t in completedTasks) {
        if (t.tags.isEmpty) {
          tagCount["Genel"] = (tagCount["Genel"] ?? 0) + 1;
        } else {
          for (var tag in t.tags) {
            if (tag.isNotEmpty) {
              tagCount[tag] = (tagCount[tag] ?? 0) + 1;
            }
          }
        }
      }

      Map<String, double> tagDistribution = {};
      int totalTags = tagCount.values.fold(0, (a, b) => a + b.toInt());
      if (totalTags > 0) {
        tagCount.forEach((key, value) {
          tagDistribution[key] = (value / totalTags) * 100;
        });
      }

      List<double> weeklyTrend = [0, 0, 0, 0];
      for (var t in completedTasks) {
        final diff = today.difference(t.startTime).inDays;
        if (diff >= 0) {
          if (diff < 7) {
            weeklyTrend[3]++;
          } else if (diff < 14) {
            weeklyTrend[2]++;
          } else if (diff < 21) {
            weeklyTrend[1]++;
          } else if (diff < 28) {
            weeklyTrend[0]++;
          }
        }
      }

      List<FlSpot> dailyActivityLine = [];
      for (int i = 13; i >= 0; i--) {
        final d = today.subtract(Duration(days: i));
        final count = completedTasks
            .where((t) => DateUtils.isSameDay(t.startTime, d))
            .length;
        dailyActivityLine.add(FlSpot(13.0 - i, count.toDouble()));
      }

      final Map<DateTime, int> heatMapDataSet = {};
      for (var t in completedTasks) {
        final dateKey = DateUtils.dateOnly(t.startTime);
        heatMapDataSet[dateKey] = (heatMapDataSet[dateKey] ?? 0) + 1;
      }

      final Map<int, int> priorityBreakdown = {0: 0, 1: 0, 2: 0};
      for (var t in completedTasks) {
        priorityBreakdown[t.priority] =
            (priorityBreakdown[t.priority] ?? 0) + 1;
      }

      double score = (completionRate * 0.5) +
          (math.min(streak, 10) * 3) +
          (math.min(totalCompleted, 50));
      score = score.clamp(0, 100);
      if (score.isNaN) {
        score = 0;
      }

      if (mounted) {
        setState(() {
          _currentStats = AppStats(
            completionRate: completionRate,
            streak: streak,
            totalCompleted: totalCompleted,
            totalPending: totalPending,
            productivityScore: score,
            totalFocusMinutes: totalFocusMinutes,
            mostProductiveTimeOfDay: mostProductiveTime,
            hourlyBreakdown: hourlyBreakdown,
            tagDistribution: tagDistribution,
            weeklyTrend: weeklyTrend,
            dailyActivityLine: dailyActivityLine,
            heatMapDataSet: heatMapDataSet,
            priorityBreakdown: priorityBreakdown,
            busiestDayOfWeek: busiestDay,
            avgTaskDurationMinutes: avgDuration,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("İstatistik Hatası: $e");
      if (mounted) {
        setState(() {
          _currentStats = _getEmptyStats();
          _isLoading = false;
        });
      }
    }
  }

  String _getDayName(int weekday) {
    const days = ["", "Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
    if (weekday >= 1 && weekday <= 7) {
      return days[weekday];
    }
    return "-";
  }

  AppStats _getEmptyStats() {
    return AppStats(
        completionRate: 0,
        streak: 0,
        totalCompleted: 0,
        totalPending: 0,
        productivityScore: 0,
        totalFocusMinutes: 0,
        mostProductiveTimeOfDay: "-",
        hourlyBreakdown: {},
        tagDistribution: {},
        weeklyTrend: [],
        dailyActivityLine: [],
        heatMapDataSet: {},
        priorityBreakdown: {},
        busiestDayOfWeek: "-",
        avgTaskDurationMinutes: 0);
  }

  void _showInfoSheet() {
    final cs = Theme.of(context).colorScheme;
    PhobesBottomSheet.show(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "İstatistik Rehberi",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoItem(
                icon: Icons.speed,
                color: Colors.blue,
                title: "Verimlilik Puanı",
                desc:
                    "Tamamlanan görevler, seri ve düzenliliğe göre hesaplanan 100 üzerinden puanınız.",
                cs: cs),
            _buildInfoItem(
                icon: Icons.pie_chart,
                color: Colors.teal,
                title: "Kategori Analizi",
                desc:
                    "Görevlerinizi hangi etiketler altında topladığınızı gösterir.",
                cs: cs),
            _buildInfoItem(
                icon: Icons.access_time_filled,
                color: Colors.pinkAccent,
                title: "Saatlik Odak",
                desc:
                    "Günün hangi saatlerinde daha aktif görev tamamladığınızı gösterir.",
                cs: cs),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
      {required IconData icon,
      required Color color,
      required String title,
      required String desc,
      required ColorScheme cs}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24)),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 4),
          Text(desc,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)))
        ]))
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;

    return Scaffold(
      backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    PhobesLoadingIndicator(color: cs.primary),
                    const SizedBox(height: 16),
                    Text(_statusMessage,
                        style: GoogleFonts.outfit(
                            color: cs.onSurface.withValues(alpha: 0.7)))
                  ]))
            : _currentStats == null
                ? Center(
                    child: Text(l10n.noData,
                        style: GoogleFonts.outfit(color: cs.onSurface)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.statistics,
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
                                      color: cs.onSurface)),
                              Row(children: [
                                PhobesIconButton(
                                  icon: Icons.psychology,
                                  color: cs.onPrimary,
                                  backgroundColor: cs.primary,
                                  enableGlow: true,
                                  onTap: _askNovaAnalysis,
                                ),
                                const SizedBox(width: 8),
                                PhobesIconButton(
                                  icon: Icons.info_outline_rounded,
                                  onTap: _showInfoSheet,
                                ),
                                const SizedBox(width: 8),
                                PhobesIconButton(
                                  icon: Icons.refresh_rounded,
                                  onTap: _refreshStats,
                                ),
                                const SizedBox(width: 48),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildKpiGrid(_currentStats!, l10n, width, cs),
                        const SizedBox(height: 24),
                        _buildChartContainer(
                          title: l10n.activityHeatmapTitle,
                          height: 320,
                          cs: cs,
                          child: HeatMap(
                            datasets: _currentStats!.heatMapDataSet,
                            colorMode: ColorMode.opacity,
                            showText: false,
                            scrollable: true,
                            colorsets: {
                              1: cs.primary.withValues(alpha: 0.2),
                              3: cs.primary.withValues(alpha: 0.4),
                              5: cs.primary.withValues(alpha: 0.6),
                              7: cs.primary.withValues(alpha: 0.8),
                              10: cs.primary,
                            },
                            onClick: (value) {},
                            defaultColor: cs.onSurface.withValues(alpha: 0.05),
                            textColor: cs.onSurface,
                            startDate: DateTime.now()
                                .subtract(const Duration(days: 85)),
                            endDate: DateTime.now(),
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(builder: (context, constraints) {
                          final itemWidth = isDesktop
                              ? (constraints.maxWidth - 16) / 2
                              : constraints.maxWidth;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildChartContainer(
                                  width: itemWidth,
                                  title: "Günlük Aktivite",
                                  cs: cs,
                                  child: _buildLineChart(
                                      _currentStats!.dailyActivityLine, cs)),
                              _buildChartContainer(
                                  width: itemWidth,
                                  title: "Haftalık Trend",
                                  cs: cs,
                                  child: _buildBarChart(
                                      _currentStats!.weeklyTrend, cs)),
                              _buildChartContainer(
                                  width: isDesktop
                                      ? itemWidth
                                      : constraints.maxWidth,
                                  height: 300,
                                  title: "Kategori Analizi",
                                  cs: cs,
                                  child: _buildPieChart(
                                      _currentStats!.tagDistribution, cs)),
                              _buildChartContainer(
                                  width: itemWidth,
                                  title: "Öncelik Dağılımı",
                                  cs: cs,
                                  child: _buildPriorityChart(
                                      _currentStats!.priorityBreakdown, cs)),
                              _buildChartContainer(
                                  width: isDesktop
                                      ? itemWidth * 2 + 16
                                      : constraints.maxWidth,
                                  height: 300,
                                  title: "Günün Saatlerine Göre Odaklanma",
                                  cs: cs,
                                  child: _buildHourlyChart(
                                      _currentStats!.hourlyBreakdown, cs)),
                            ],
                          );
                        }),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildKpiGrid(AppStats stats, AppLocalizations l10n,
      double screenWidth, ColorScheme cs) {
    String focusTimeText = "";
    if (stats.totalFocusMinutes < 60) {
      focusTimeText = "${stats.totalFocusMinutes} dk";
    } else {
      int h = stats.totalFocusMinutes ~/ 60;
      int m = stats.totalFocusMinutes % 60;
      focusTimeText = "${h}sa ${m}dk";
    }

    final List<Widget> cards = [
      _buildDetailCard(
          title: "Verimlilik",
          value: stats.productivityScore.toInt().toString(),
          unit: "/100",
          icon: Icons.speed,
          color: Colors.blue,
          cs: cs),
      _buildDetailCard(
          title: "Seri",
          value: stats.streak.toString(),
          unit: "Gün",
          icon: Icons.local_fire_department,
          color: Colors.orange,
          cs: cs),
      _buildDetailCard(
          title: "Tamamlanan",
          value: stats.totalCompleted.toString(),
          unit: "Görev",
          icon: Icons.check_circle,
          color: Colors.green,
          cs: cs),
      _buildDetailCard(
          title: "Bekleyen",
          value: stats.totalPending.toString(),
          unit: "Görev",
          icon: Icons.hourglass_empty,
          color: Colors.redAccent,
          cs: cs),
      _buildDetailCard(
          title: "Toplam Odak",
          value: focusTimeText,
          unit: "",
          icon: Icons.timelapse,
          color: Colors.purpleAccent,
          cs: cs),
      _buildDetailCard(
          title: "En Yoğun Gün",
          value: stats.busiestDayOfWeek,
          unit: "",
          icon: Icons.calendar_today,
          color: Colors.teal,
          cs: cs),
      _buildDetailCard(
          title: "Ort. Süre",
          value: "${stats.avgTaskDurationMinutes.toInt()}",
          unit: "dk/görev",
          icon: Icons.av_timer,
          color: Colors.pinkAccent,
          cs: cs),
      _buildDetailCard(
          title: "Tamamlanma",
          value: "%${stats.completionRate.toInt()}",
          unit: "Oran",
          icon: Icons.pie_chart,
          color: Colors.indigoAccent,
          cs: cs),
    ];

    int crossAxisCount;
    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 600) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: 1.4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: cards,
    );
  }

  Widget _buildDetailCard(
      {required String title,
      required String value,
      required String unit,
      required IconData icon,
      required Color color,
      required ColorScheme cs}) {
    return PhobesCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Text(title,
                  style: GoogleFonts.outfit(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    style: GoogleFonts.outfit(
                        color: cs.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ),
              if (unit.isNotEmpty)
                Text(unit,
                    style: GoogleFonts.outfit(
                        color: cs.onSurface.withValues(alpha: 0.4),
                        fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer(
      {required String title,
      required Widget child,
      required ColorScheme cs,
      double height = 260,
      double? width}) {
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
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<FlSpot> spots, ColorScheme cs) {
    if (spots.isEmpty || spots.every((s) => s.y == 0)) {
      return _noDataWidget(cs);
    }
    return LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
              spots: spots,
              isCurved: true,
              color: cs.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(colors: [
                    cs.primary.withValues(alpha: 0.3),
                    cs.primary.withValues(alpha: 0)
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter)))
        ]));
  }

  Widget _buildBarChart(List<double> data, ColorScheme cs) {
    if (data.every((d) => d == 0)) {
      return _noDataWidget(cs);
    }
    return BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => cs.surfaceContainerHigh,
                tooltipPadding: const EdgeInsets.all(8))),
        titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const labels = [
                        "3 Hf Önce",
                        "2 Hf Önce",
                        "Geçen Hf",
                        "Bu Hafta"
                      ];
                      if (value.toInt() < labels.length) {
                        return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(labels[value.toInt()],
                                style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.4),
                                    fontSize: 9)));
                      }
                      return const SizedBox.shrink();
                    })),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false))),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: data
            .asMap()
            .entries
            .map((e) => BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                      toY: e.value,
                      color: e.key == 3
                          ? cs.primary
                          : cs.primary.withValues(alpha: 0.5),
                      width: 18,
                      borderRadius: BorderRadius.circular(4))
                ]))
            .toList()));
  }

  Widget _buildHourlyChart(Map<int, int> data, ColorScheme cs) {
    if (data.isEmpty || data.values.every((element) => element == 0)) {
      return _noDataWidget(cs);
    }
    return BarChart(BarChartData(
        titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final int hour = value.toInt();
                      if (hour % 6 == 0) {
                        return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text("$hour:00",
                                style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)));
                      }
                      return const SizedBox.shrink();
                    })),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false))),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: data.entries
            .map((e) => BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                      toY: e.value.toDouble(),
                      color: cs.secondary.withValues(alpha: 0.8),
                      width: 8,
                      borderRadius: BorderRadius.circular(2))
                ]))
            .toList()));
  }

  Widget _buildPieChart(Map<String, double> data, ColorScheme cs) {
    if (data.isEmpty) {
      return _noDataWidget(cs);
    }
    int i = 0;
    List<Color> colors = [
      cs.primary,
      cs.secondary,
      cs.tertiary,
      cs.primaryContainer,
      cs.secondaryContainer
    ];

    List<Widget> legendItems = data.entries.map((e) {
      final index = data.keys.toList().indexOf(e.key);
      final color = colors[index % colors.length];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text("${e.key} (%${e.value.toInt()})",
                style: GoogleFonts.outfit(
                    color: cs.onSurface.withValues(alpha: 0.7), fontSize: 12)),
          ],
        ),
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 20,
              sections: data.entries.map((e) {
                final color = colors[i++ % colors.length];
                return PieChartSectionData(
                  value: e.value,
                  color: color,
                  radius: 50,
                  showTitle: false,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          children: legendItems,
        )
      ],
    );
  }

  Widget _buildPriorityChart(Map<int, int> data, ColorScheme cs) {
    final total = (data[0] ?? 0) + (data[1] ?? 0) + (data[2] ?? 0);
    if (total == 0) {
      return _noDataWidget(cs);
    }

    Widget legendItem(Color color, String label, int count) {
      if (count == 0) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6), fontSize: 10)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: PieChart(
              PieChartData(sectionsSpace: 2, centerSpaceRadius: 20, sections: [
            if ((data[0] ?? 0) > 0)
              PieChartSectionData(
                  value: data[0]!.toDouble(),
                  color: Colors.green,
                  radius: 50,
                  title: "${((data[0]! / total) * 100).toInt()}%",
                  titleStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            if ((data[1] ?? 0) > 0)
              PieChartSectionData(
                  value: data[1]!.toDouble(),
                  color: Colors.orange,
                  radius: 50,
                  title: "${((data[1]! / total) * 100).toInt()}%",
                  titleStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            if ((data[2] ?? 0) > 0)
              PieChartSectionData(
                  value: data[2]!.toDouble(),
                  color: Colors.red,
                  radius: 50,
                  title: "${((data[2]! / total) * 100).toInt()}%",
                  titleStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold))
          ])),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            legendItem(Colors.green, "Düşük", data[0] ?? 0),
            legendItem(Colors.orange, "Orta", data[1] ?? 0),
            legendItem(Colors.red, "Yüksek", data[2] ?? 0),
          ],
        )
      ],
    );
  }

  Widget _noDataWidget(ColorScheme cs) => Center(
      child: Text("Veri Yok",
          style: GoogleFonts.outfit(
              color: cs.onSurface.withValues(alpha: 0.2), fontSize: 12)));
}
