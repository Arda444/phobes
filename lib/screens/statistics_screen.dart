import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'dart:math';
import '../services/firebase_service.dart';
import '../services/nova_service.dart';
import '../models/task_model.dart';
import '../l10n/app_localizations.dart';

// --- DATA MODEL ---
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

  // --- NOVA TÜKENMİŞLİK ANALİZİ ---
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
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          // DÜZELTME: Icons.health_style -> Icons.monitor_heart olarak değiştirildi
          icon: const Icon(Icons.monitor_heart,
              color: Colors.pinkAccent, size: 40),
          title: const Text("Nova Sağlık Raporu",
              style: TextStyle(color: Colors.white)),
          content: Text(advice ?? "Şu an analiz yapamıyorum.",
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text("Tamam"))
          ],
        ),
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
        debugPrint("Hata: $e");
        tasks = await _firebaseService.getTasksStream().first;
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
        if (sortedTimes.isNotEmpty && sortedTimes.last.value > 0) {
          mostProductiveTime = sortedTimes.last.key;
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
          (min(streak, 10) * 3) +
          (min(totalCompleted, 50));
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                      child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade700,
                              borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Text("İstatistik Rehberi",
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 20),
                  _buildInfoItem(
                      icon: Icons.speed,
                      color: Colors.blue,
                      title: "Verimlilik Puanı",
                      desc:
                          "Tamamlanan görevler, seri ve düzenliliğe göre hesaplanan 100 üzerinden puanınız."),
                  _buildInfoItem(
                      icon: Icons.pie_chart,
                      color: Colors.teal,
                      title: "Kategori Analizi",
                      desc:
                          "Görevlerinizi hangi etiketler altında topladığınızı gösterir."),
                  _buildInfoItem(
                      icon: Icons.access_time_filled,
                      color: Colors.pinkAccent,
                      title: "Saatlik Odak",
                      desc:
                          "Günün hangi saatlerinde daha aktif görev tamamladığınızı gösterir."),
                ],
              ),
            );
          }),
    );
  }

  Widget _buildInfoItem(
      {required IconData icon,
      required Color color,
      required String title,
      required String desc}) {
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
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(desc,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60))
        ]))
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.statistics,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: Colors.white)),
        actions: [
          IconButton(
              icon: const Icon(Icons.psychology, color: Colors.pinkAccent),
              onPressed: _askNovaAnalysis),
          IconButton(
              icon:
                  const Icon(Icons.info_outline_rounded, color: Colors.white70),
              onPressed: _showInfoSheet),
          IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _refreshStats),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  const CircularProgressIndicator(color: Colors.purple),
                  const SizedBox(height: 16),
                  Text(_statusMessage,
                      style: GoogleFonts.poppins(color: Colors.white70))
                ]))
          : _currentStats == null
              ? Center(
                  child: Text(l10n.noData,
                      style: const TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKpiGrid(_currentStats!, l10n, width),
                      const SizedBox(height: 24),
                      _buildChartContainer(
                        title: l10n.activityHeatmapTitle,
                        height: 320,
                        child: HeatMap(
                          datasets: _currentStats!.heatMapDataSet,
                          colorMode: ColorMode.opacity,
                          showText: false,
                          scrollable: true,
                          colorsets: {
                            1: Colors.purple.shade200,
                            3: Colors.purple.shade400,
                            5: Colors.purple.shade600,
                            7: Colors.purple.shade800,
                            10: Colors.white
                          },
                          onClick: (value) {},
                          defaultColor: Colors.white10,
                          textColor: Colors.white,
                          startDate:
                              DateTime.now().subtract(const Duration(days: 85)),
                          endDate: DateTime.now(),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(builder: (context, constraints) {
                        int columns = isDesktop ? 3 : 1;
                        double itemWidth =
                            (constraints.maxWidth - (columns - 1) * 16) /
                                columns;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildChartContainer(
                                width: itemWidth,
                                title: "Günlük Aktivite",
                                child: _buildLineChart(
                                    _currentStats!.dailyActivityLine)),
                            _buildChartContainer(
                                width: itemWidth,
                                title: "Haftalık Trend",
                                child:
                                    _buildBarChart(_currentStats!.weeklyTrend)),
                            _buildChartContainer(
                                width: isDesktop
                                    ? itemWidth
                                    : constraints.maxWidth,
                                height: 300,
                                title: "Kategori Analizi",
                                child: _buildPieChart(
                                    _currentStats!.tagDistribution)),
                            _buildChartContainer(
                                width: itemWidth,
                                title: "Öncelik Dağılımı",
                                child: _buildPriorityChart(
                                    _currentStats!.priorityBreakdown)),
                            _buildChartContainer(
                                width: isDesktop
                                    ? itemWidth * 2 + 16
                                    : constraints.maxWidth,
                                height: 300,
                                title: "Günün Saatlerine Göre Odaklanma",
                                child: _buildHourlyChart(
                                    _currentStats!.hourlyBreakdown)),
                          ],
                        );
                      }),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
    );
  }

  Widget _buildKpiGrid(
      AppStats stats, AppLocalizations l10n, double screenWidth) {
    String focusTimeText = "";
    if (stats.totalFocusMinutes < 60) {
      focusTimeText = "${stats.totalFocusMinutes} dk";
    } else {
      focusTimeText =
          "${(stats.totalFocusMinutes / 60).floor()}s ${stats.totalFocusMinutes % 60}dk";
    }

    final cards = [
      _buildDetailCard(
          title: "Verimlilik",
          value: stats.productivityScore.toInt().toString(),
          unit: "/100",
          icon: Icons.speed,
          color: Colors.blue),
      _buildDetailCard(
          title: "Seri",
          value: stats.streak.toString(),
          unit: "Gün",
          icon: Icons.local_fire_department,
          color: Colors.orange),
      _buildDetailCard(
          title: "Tamamlanan",
          value: stats.totalCompleted.toString(),
          unit: "Görev",
          icon: Icons.check_circle,
          color: Colors.green),
      _buildDetailCard(
          title: "Bekleyen",
          value: stats.totalPending.toString(),
          unit: "Görev",
          icon: Icons.hourglass_empty,
          color: Colors.redAccent),
      _buildDetailCard(
          title: "Toplam Odak",
          value: focusTimeText,
          unit: "",
          icon: Icons.timelapse,
          color: Colors.purpleAccent),
      _buildDetailCard(
          title: "En Yoğun Gün",
          value: stats.busiestDayOfWeek,
          unit: "",
          icon: Icons.calendar_today,
          color: Colors.teal),
      _buildDetailCard(
          title: "Ort. Süre",
          value: "${stats.avgTaskDurationMinutes.toInt()}",
          unit: "dk/görev",
          icon: Icons.av_timer,
          color: Colors.pinkAccent),
      _buildDetailCard(
          title: "Tamamlanma",
          value: "%${stats.completionRate.toInt()}",
          unit: "Oran",
          icon: Icons.pie_chart,
          color: Colors.indigoAccent),
    ];

    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth > 1200) {
      crossAxisCount = 4;
      childAspectRatio = 2.4;
    } else if (screenWidth > 800) {
      crossAxisCount = 4;
      childAspectRatio = 1.8;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 1.4;
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildDetailCard(
      {required String title,
      required String value,
      required String unit,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Text(title,
                  style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
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
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ),
              if (unit.isNotEmpty)
                Text(unit,
                    style: GoogleFonts.poppins(
                        color: Colors.grey.shade600, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChartContainer(
      {required Widget child,
      required String title,
      double height = 280,
      double width = double.infinity}) {
    return Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 20),
          Expanded(child: child)
        ]));
  }

  Widget _buildLineChart(List<FlSpot> spots) {
    if (spots.isEmpty || spots.every((s) => s.y == 0)) {
      return _noDataWidget();
    }
    return LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(colors: [
                    Colors.blueAccent.withValues(alpha: 0.3),
                    Colors.transparent
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter)))
        ]));
  }

  Widget _buildBarChart(List<double> data) {
    if (data.every((d) => d == 0)) {
      return _noDataWidget();
    }
    return BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black,
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
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 9)));
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
                          ? Colors.purpleAccent
                          : Colors.purpleAccent.withValues(alpha: 0.5),
                      width: 18,
                      borderRadius: BorderRadius.circular(4))
                ]))
            .toList()));
  }

  Widget _buildHourlyChart(Map<int, int> data) {
    if (data.isEmpty || data.values.every((element) => element == 0)) {
      return _noDataWidget();
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
                              style: const TextStyle(
                                  color: Colors.white54,
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
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: data.entries
            .map((e) => BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                      toY: e.value.toDouble(),
                      color: Colors.pinkAccent.withValues(alpha: 0.8),
                      width: 8,
                      borderRadius: BorderRadius.circular(2))
                ]))
            .toList()));
  }

  Widget _buildPieChart(Map<String, double> data) {
    if (data.isEmpty) {
      return _noDataWidget();
    }
    int i = 0;
    List<Color> colors = [
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.indigo
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
                style:
                    GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
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

  Widget _buildPriorityChart(Map<int, int> data) {
    final total = (data[0] ?? 0) + (data[1] ?? 0) + (data[2] ?? 0);
    if (total == 0) {
      return _noDataWidget();
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
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
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

  Widget _noDataWidget() => Center(
      child: Text("Veri Yok",
          style: GoogleFonts.poppins(color: Colors.white24, fontSize: 12)));
}
