import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/task_model.dart';
import '../../models/team_model.dart';
import '../../models/project_model.dart';
import '../../services/firebase_service.dart';
import '../../l10n/app_localizations.dart';

import '../../widgets/phobes_widgets.dart';

class TeamDashboardTab extends StatelessWidget {
  final Team team;
  const TeamDashboardTab({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<List<Task>>(
      stream: service.getTeamTasksStream(team.id),
      builder: (context, taskSnapshot) {
        return StreamBuilder<List<Project>>(
          stream: service.getProjectsStream(team.id),
          builder: (context, projectSnapshot) {
            if (!taskSnapshot.hasData) {
              return Center(child: PhobesLoadingIndicator(color: cs.primary));
            }

            final tasks = taskSnapshot.data!;
            final projects = projectSnapshot.data ?? [];
            final total = tasks.length;

            final completed =
                tasks.where((t) => t.isCompleted || t.status == 'done').length;
            final inProgress =
                tasks.where((t) => t.status == 'in_progress').length;
            final review = tasks.where((t) => t.status == 'review').length;
            final todo =
                tasks.where((t) => !t.isCompleted && t.status == 'todo').length;

            final highPriority =
                tasks.where((t) => !t.isCompleted && t.priority == 2).length;

            final now = DateTime.now();
            final overdue = tasks
                .where((t) =>
                    !t.isCompleted &&
                    t.endTime.isBefore(now) &&
                    t.status != 'done')
                .length;

            final completionRate = total == 0 ? 0.0 : (completed / total);

            Map<String, int> memberCompleted = {};
            Map<String, int> memberActiveLoad = {};
            for (var t in tasks) {
              if (t.assignedTo.isNotEmpty) {
                for (var uid in t.assignedTo) {
                  if (t.isCompleted || t.status == 'done') {
                    memberCompleted[uid] = (memberCompleted[uid] ?? 0) + 1;
                  } else {
                    memberActiveLoad[uid] = (memberActiveLoad[uid] ?? 0) + 1;
                  }
                }
              }
            }
            var sortedLeaders = memberCompleted.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            var sortedLoad = memberActiveLoad.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final weeklyData = _getWeeklyActivity(tasks);

            final activeProjects =
                projects.where((p) => p.status == 'active').length;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainProgressCard(
                      completed, total, completionRate, isDark, l10n, cs),
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (context, box) {
                    final isSmall = box.maxWidth < 600;
                    return Column(
                      children: [
                        if (isSmall)
                          GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.3,
                                children: [
                                  _buildMiniStat(
                                      'Üye',
                                      '${team.memberIds.length}',
                                      Icons.people_rounded,
                                      Colors.cyanAccent,
                                      cs),
                                  _buildMiniStat(
                                      'Proje',
                                      '$activeProjects',
                                      Icons.folder_rounded,
                                      Colors.amberAccent,
                                      cs),
                                  _buildMiniStat(
                                      'Geciken',
                                      '$overdue',
                                      Icons.warning_rounded,
                                      Colors.redAccent,
                                      cs),
                                  _buildMiniStat(
                                      'Yüksek',
                                      '$highPriority',
                                      Icons.priority_high_rounded,
                                      Colors.orangeAccent,
                                      cs),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildMiniStat(
                                          'Üye',
                                          '${team.memberIds.length}',
                                          Icons.people_rounded,
                                          Colors.cyanAccent,
                                          cs)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: _buildMiniStat(
                                          'Proje',
                                          '$activeProjects',
                                          Icons.folder_rounded,
                                          Colors.amberAccent,
                                          cs)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: _buildMiniStat(
                                          'Geciken',
                                          '$overdue',
                                          Icons.warning_rounded,
                                          Colors.redAccent,
                                          cs)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: _buildMiniStat(
                                          'Yüksek',
                                          '$highPriority',
                                          Icons.priority_high_rounded,
                                          Colors.orangeAccent,
                                          cs)),
                                ],
                              ),
                            const SizedBox(height: 16),
                            if (isSmall)
                              Column(
                                children: [
                                  _buildTaskDistributionCard(todo, inProgress,
                                      review, completed, l10n, cs),
                                  const SizedBox(height: 16),
                                  _buildWeeklyActivityCard(weeklyData, cs),
                                ],
                              )
                            else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildTaskDistributionCard(
                                        todo,
                                        inProgress,
                                        review,
                                        completed,
                                        l10n,
                                        cs),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildWeeklyActivityCard(
                                        weeklyData, cs),
                                  ),
                                ],
                              ),
                          ],
                        );
                      }),
                      const SizedBox(height: 24),
                      if (sortedLoad.isNotEmpty) ...[
                        Text("Üye İş Yükü (Aktif Görevler)",
                            style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface)),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: sortedLoad.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _WorkloadAvatar(
                                    userId: entry.key,
                                    activeTasks: entry.value,
                                    isDark: isDark),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text(l10n.teamLeaderboard,
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface)),
                      const SizedBox(height: 8),
                      if (sortedLeaders.isEmpty)
                        PhobesCard(
                          padding: const EdgeInsets.all(24),
                          width: double.infinity,
                          child: Column(
                            children: [
                              Icon(Icons.emoji_events_outlined,
                                  color: cs.onSurface.withValues(alpha: 0.2),
                                  size: 36),
                              const SizedBox(height: 8),
                              Text(l10n.noCompletedTasksYet,
                                  style: GoogleFonts.outfit(
                                      color:
                                          cs.onSurface.withValues(alpha: 0.5))),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sortedLeaders.length,
                          itemBuilder: (context, index) {
                            final entry = sortedLeaders[index];
                            return _UserLeaderboardTile(
                                userId: entry.key,
                                score: entry.value,
                                rank: index + 1,
                                isDark: isDark);
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
        );
      }

  List<double> _getWeeklyActivity(List<Task> tasks) {
    final now = DateTime.now();
    final data = List<double>.filled(7, 0);
    for (var t in tasks) {
      if ((t.isCompleted || t.status == 'done') && t.completionTime != null) {
        final diff = now.difference(t.completionTime!).inDays;
        if (diff >= 0 && diff < 7) {
          data[6 - diff] += 1;
        }
      }
    }
    return data;
  }

  Widget _buildMainProgressCard(int completed, int total, double rate,
      bool isDark, AppLocalizations l10n, ColorScheme cs) {
    return PhobesCard(
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        colors: [
          isDark ? const Color(0xFF1A1A2E) : cs.primary.withValues(alpha: 0.8),
          cs.primary.withValues(alpha: 0.3),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.projectProgress,
                    style: GoogleFonts.outfit(
                        color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 4),
                Text("%${(rate * 100).toInt()}",
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("$completed / $total ${l10n.completed}",
                    style: GoogleFonts.outfit(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          SizedBox(
            height: 64,
            width: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: rate == 0 ? 1 : rate,
                  strokeWidth: 6,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      rate == 0 ? Colors.white10 : Colors.tealAccent),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Icon(Icons.analytics_rounded,
                      color: Colors.white.withValues(alpha: 0.8), size: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
      String label, String value, IconData icon, Color color, ColorScheme cs) {
    return PhobesCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.outfit(
                  color: cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: GoogleFonts.outfit(
                  color: cs.onSurface.withValues(alpha: 0.4), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTaskDistributionCard(int todo, int inProgress, int review,
      int completed, AppLocalizations l10n, ColorScheme cs) {
    return PhobesCard(
      height: 180,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.taskStatus,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 18,
                      sections: [
                        PieChartSectionData(
                            value: todo == 0 ? 0.001 : todo.toDouble(),
                            color: Colors.blueAccent.withValues(alpha: 0.7),
                            radius: 24,
                            showTitle: false),
                        PieChartSectionData(
                            value:
                                inProgress == 0 ? 0.001 : inProgress.toDouble(),
                            color: Colors.orangeAccent,
                            radius: 24,
                            showTitle: false),
                        PieChartSectionData(
                            value: review == 0 ? 0.001 : review.toDouble(),
                            color: Colors.purpleAccent,
                            radius: 24,
                            showTitle: false),
                        PieChartSectionData(
                            value:
                                completed == 0 ? 0.001 : completed.toDouble(),
                            color: Colors.greenAccent,
                            radius: 28,
                            showTitle: false),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(l10n.statusTodo,
                          Colors.blueAccent.withValues(alpha: 0.7), todo, cs),
                      const SizedBox(height: 4),
                      _buildLegendItem(l10n.statusInProgress,
                          Colors.orangeAccent, inProgress, cs),
                      const SizedBox(height: 4),
                      _buildLegendItem(
                          'İnceleme', Colors.purpleAccent, review, cs),
                      const SizedBox(height: 4),
                      _buildLegendItem(
                          l10n.completed, Colors.greenAccent, completed, cs),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityCard(List<double> data, ColorScheme cs) {
    final dayLabels = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];
    final now = DateTime.now();
    final labels = List.generate(
        7, (i) => dayLabels[(now.subtract(Duration(days: 6 - i)).weekday - 1)]);

    final maxVal = data.isEmpty
        ? 1.0
        : (data.reduce((a, b) => a > b ? a : b)).clamp(1.0, double.infinity);

    return PhobesCard(
      height: 180,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Haftalık Aktivite',
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 6),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal + 1,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Text(labels[idx],
                              style: GoogleFonts.outfit(
                                  color: cs.onSurface.withValues(alpha: 0.3),
                                  fontSize: 10));
                        }
                        return const SizedBox();
                      },
                      reservedSize: 20,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  7,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i],
                        color: cs.primary,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal + 1,
                          color: cs.onSurface.withValues(alpha: 0.03),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      String label, Color color, int count, ColorScheme cs) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: GoogleFonts.outfit(
                  color: cs.onSurface.withValues(alpha: 0.5), fontSize: 10),
              overflow: TextOverflow.ellipsis),
        ),
        Text("$count",
            style: GoogleFonts.outfit(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 11)),
      ],
    );
  }
}

class _UserLeaderboardTile extends StatelessWidget {
  final String userId;
  final int score;
  final int rank;
  final bool isDark;

  const _UserLeaderboardTile({
    required this.userId,
    required this.score,
    required this.rank,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    IconData? rankIcon;
    Color iconColor = Colors.transparent;

    if (rank == 1) {
      rankIcon = Icons.emoji_events;
      iconColor = Colors.amber;
    } else if (rank == 2) {
      rankIcon = Icons.star;
      iconColor = Colors.grey.shade400;
    } else if (rank == 3) {
      rankIcon = Icons.star_half;
      iconColor = Colors.brown.shade300;
    }

    return PhobesCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      gradient: rank == 1
          ? LinearGradient(
              colors: [
                Colors.amber.withValues(alpha: 0.15),
                Colors.amber.withValues(alpha: 0.05),
              ],
            )
          : null,
      child: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          String name = l10n.loading;
          String shortName = "?";
          String? photoUrl;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            name = "${data['name']} ${data['surname']}";
            if (data['name'] != null && data['name'].isNotEmpty) {
              shortName = data['name'][0].toUpperCase();
            }
            photoUrl = data['photoUrl'];
          }

          return Row(
            children: [
              SizedBox(
                width: 26,
                child: Text("#$rank",
                    style: GoogleFonts.outfit(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.indigo,
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(shortName,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name,
                    style: GoogleFonts.outfit(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              if (rankIcon != null) ...[
                Icon(rankIcon, color: iconColor, size: 18),
                const SizedBox(width: 6),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Text("$score ${l10n.taskCount}",
                    style: GoogleFonts.outfit(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WorkloadAvatar extends StatelessWidget {
  final String userId;
  final int activeTasks;
  final bool isDark;

  const _WorkloadAvatar({
    required this.userId,
    required this.activeTasks,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          String shortName = "?";
          String? photoUrl;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            if (data['name'] != null && data['name'].isNotEmpty) {
              shortName = data['name'][0].toUpperCase();
            }
            photoUrl = data['photoUrl'];
          }

          // Generate dynamic color based on active tasks (red if high load)
          Color badgeColor = Colors.greenAccent;
          if (activeTasks > 3) badgeColor = Colors.orangeAccent;
          if (activeTasks > 6) badgeColor = Colors.redAccent;

          return SizedBox(
            width: 72,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: cs.primary.withValues(alpha: 0.3), width: 2),
                        image: photoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover)
                            : null,
                        color:
                            photoUrl == null ? cs.surfaceContainerHigh : null,
                      ),
                      child: photoUrl == null
                          ? Center(
                              child: Text(shortName,
                                  style: GoogleFonts.outfit(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)))
                          : null,
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: badgeColor.withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Text(
                          "$activeTasks",
                          style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (snapshot.hasData && snapshot.data!.exists)
                  Text(
                    (snapshot.data!.data() as Map<String, dynamic>)['name'] ??
                        '',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          );
        });
  }
}
