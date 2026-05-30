import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/task_model.dart';
import '../../models/team_model.dart';
import '../../models/project_model.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../widgets/phobes_widgets.dart';

class TeamDashboardTab extends StatelessWidget {
  final Team team;
  final Function(Project)? onProjectSelected;
  const TeamDashboardTab(
      {super.key, required this.team, this.onProjectSelected});

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
            if (taskSnapshot.hasError || projectSnapshot.hasError) {
              return _buildLoadIssue(
                cs,
                l10n.statsLoadFailed,
              );
            }
            final tasksLoading = taskSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !taskSnapshot.hasData;
            final projectsLoading = projectSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !projectSnapshot.hasData;
            if (tasksLoading || projectsLoading) {
              return Center(child: PhobesLoadingIndicator(color: cs.primary));
            }

            final tasks = taskSnapshot.data ?? [];
            final projects = projectSnapshot.data ?? [];
            final uid = service.currentUserId;
            final canManageProjects = uid != null &&
                (team.ownerId == uid || team.adminIds.contains(uid));
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
                .where(
                  (t) =>
                      !t.isCompleted &&
                      t.endTime.isBefore(now) &&
                      t.status != 'done',
                )
                .length;

            final completionRate = total == 0 ? 0.0 : (completed / total);

            final Map<String, int> memberCompleted = {};
            final Map<String, int> memberActiveLoad = {};
            for (final t in tasks) {
              if (t.assignedTo.isNotEmpty) {
                for (final uid in t.assignedTo) {
                  if (t.isCompleted || t.status == 'done') {
                    memberCompleted[uid] = (memberCompleted[uid] ?? 0) + 1;
                  } else {
                    memberActiveLoad[uid] = (memberActiveLoad[uid] ?? 0) + 1;
                  }
                }
              }
            }
            final sortedLeaders = memberCompleted.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final sortedLoad = memberActiveLoad.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final weeklyData = _getWeeklyActivity(tasks);

            final activeProjects =
                projects.where((p) => p.status == 'active').length;

            return SingleChildScrollView(
              primary: false,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainProgressCard(
                    completed,
                    total,
                    completionRate,
                    isDark,
                    l10n,
                    cs,
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, box) {
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
                                  l10n.teamMemberCountLabel,
                                  '${team.memberIds.length}',
                                  Icons.people_rounded,
                                  Colors.cyanAccent,
                                  cs,
                                ),
                                _buildMiniStat(
                                  l10n.teamProjectCountLabel,
                                  '$activeProjects',
                                  Icons.folder_rounded,
                                  Colors.amberAccent,
                                  cs,
                                  onTap: canManageProjects
                                      ? () =>
                                          _showCreateProjectDialog(context)
                                      : null,
                                ),
                                _buildMiniStat(
                                  l10n.teamOverdueCountLabel,
                                  '$overdue',
                                  Icons.warning_rounded,
                                  Colors.redAccent,
                                  cs,
                                ),
                                _buildMiniStat(
                                  l10n.priorityHigh,
                                  '$highPriority',
                                  Icons.priority_high_rounded,
                                  Colors.orangeAccent,
                                  cs,
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMiniStat(
                                    l10n.teamMemberCountLabel,
                                    '${team.memberIds.length}',
                                    Icons.people_rounded,
                                    Colors.cyanAccent,
                                    cs,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMiniStat(
                                    l10n.teamProjectCountLabel,
                                    '$activeProjects',
                                    Icons.folder_rounded,
                                    Colors.amberAccent,
                                    cs,
                                    onTap: canManageProjects
                                        ? () =>
                                            _showCreateProjectDialog(context)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMiniStat(
                                    l10n.teamOverdueCountLabel,
                                    '$overdue',
                                    Icons.warning_rounded,
                                    Colors.redAccent,
                                    cs,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMiniStat(
                                    l10n.priorityHigh,
                                    '$highPriority',
                                    Icons.priority_high_rounded,
                                    Colors.orangeAccent,
                                    cs,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          if (isSmall)
                            Column(
                              children: [
                                _buildTaskDistributionCard(
                                  todo,
                                  inProgress,
                                  review,
                                  completed,
                                  l10n,
                                  cs,
                                ),
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
                                    cs,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildWeeklyActivityCard(
                                    weeklyData,
                                    cs,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  if (sortedLoad.isNotEmpty) ...[
                    Text(
                      l10n.memberWorkloadTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: sortedLoad.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _WorkloadAvatar(
                              teamId: team.id,
                              userId: entry.key,
                              activeTasks: entry.value,
                              isDark: isDark,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    l10n.teamLeaderboard,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (sortedLeaders.isEmpty)
                    PhobesCard(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      child: Column(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            color: cs.onSurface.withOpacity(0.2),
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noCompletedTasksYet,
                            style: GoogleFonts.outfit(
                              color: cs.onSurface.withOpacity(0.5),
                            ),
                          ),
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
                          teamId: team.id,
                          userId: entry.key,
                          score: entry.value,
                          rank: index + 1,
                          isDark: isDark,
                        );
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

  static Widget _buildLoadIssue(ColorScheme cs, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: cs.error.withOpacity(0.85),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _getWeeklyActivity(List<Task> tasks) {
    final now = DateTime.now();
    final data = List<double>.filled(7, 0);
    for (final t in tasks) {
      if ((t.isCompleted || t.status == 'done') && t.completionTime != null) {
        final diff = now.difference(t.completionTime!).inDays;
        if (diff >= 0 && diff < 7) {
          data[6 - diff] += 1;
        }
      }
    }
    return data;
  }

  Widget _buildMainProgressCard(
    int completed,
    int total,
    double rate,
    bool isDark,
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    return PhobesCard(
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        colors: [
          isDark ? const Color(0xFF1A1A2E) : cs.primary.withOpacity(0.8),
          cs.primary.withOpacity(0.3),
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
                Text(
                  l10n.projectProgress,
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '%${(rate * 100).toInt()}',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed / $total ${l10n.completed}',
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
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
                    rate == 0 ? Colors.white10 : Colors.tealAccent,
                  ),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Icon(
                    Icons.analytics_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    IconData icon,
    Color color,
    ColorScheme cs, {
    VoidCallback? onTap,
  }) {
    return PhobesCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: cs.onSurface.withOpacity(0.4),
                  fontSize: 10,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 10,
                  color: color.withOpacity(0.5),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final cs = Theme.of(context).colorScheme;
    int selectedColor = 0xFF6366F1;
    DateTime? deadline;
    final service = FirebaseService();

    final colors = [
      0xFF6366F1,
      0xFF3B82F6,
      0xFF10B981,
      0xFFF59E0B,
      0xFFEF4444,
      0xFF8B5CF6,
      0xFFEC4899,
      0xFF06B6D4,
    ];

    final l10n = AppLocalizations.of(context)!;
    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => PhobesBottomSheet(
          title: l10n.newProjectTitle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhobesTextFormField(
                controller: nameController,
                hintText: l10n.projectNameHint,
                prefixIcon: Icons.folder_rounded,
              ),
              const SizedBox(height: 16),
              PhobesTextFormField(
                controller: descController,
                hintText: l10n.projectDescriptionHint,
                prefixIcon: Icons.description_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.colorSelectionLabel,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface.withOpacity(0.4),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 45,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: colors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final c = colors[index];
                    final isSelected = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedColor = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Color(c).withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.deadlineLabel,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface.withOpacity(0.4),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setSheetState(() => deadline = picked);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        deadline != null
                            ? DateFormat.yMMMd(
                                    Localizations.localeOf(context).toString())
                                .format(deadline!)
                            : l10n.noDateSelected,
                        style: GoogleFonts.outfit(
                          color: deadline != null
                              ? cs.onSurface
                              : cs.onSurface.withOpacity(0.4),
                          fontWeight: deadline != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: PhobesButton(
                  text: l10n.createProjectButton,
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    final project = Project(
                      id: '',
                      teamId: team.id,
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      managerId: service.currentUserId ?? '',
                      color: selectedColor,
                      deadline: deadline,
                    );

                    await service.createProject(team.id, project);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskDistributionCard(
    int todo,
    int inProgress,
    int review,
    int completed,
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    return PhobesCard(
      height: 180,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.taskStatus,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
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
                          color: Colors.blueAccent.withOpacity(0.7),
                          radius: 24,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value:
                              inProgress == 0 ? 0.001 : inProgress.toDouble(),
                          color: Colors.orangeAccent,
                          radius: 24,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: review == 0 ? 0.001 : review.toDouble(),
                          color: Colors.purpleAccent,
                          radius: 24,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: completed == 0 ? 0.001 : completed.toDouble(),
                          color: Colors.greenAccent,
                          radius: 28,
                          showTitle: false,
                        ),
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
                      _buildLegendItem(
                        l10n.statusTodo,
                        Colors.blueAccent.withOpacity(0.7),
                        todo,
                        cs,
                      ),
                      const SizedBox(height: 4),
                      _buildLegendItem(
                        l10n.statusInProgress,
                        Colors.orangeAccent,
                        inProgress,
                        cs,
                      ),
                      const SizedBox(height: 4),
                      _buildLegendItem(
                        l10n.statusReview,
                        Colors.purpleAccent,
                        review,
                        cs,
                      ),
                      const SizedBox(height: 4),
                      _buildLegendItem(
                        l10n.completed,
                        Colors.greenAccent,
                        completed,
                        cs,
                      ),
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
    return PhobesCard(
      height: 180,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          final now = DateTime.now();
          final locale = Localizations.localeOf(context).toString();

          final labels = List.generate(7, (i) {
            final day = now.subtract(Duration(days: 6 - i));
            return DateFormat.E(locale)
                .format(day)
                .substring(0, 1)
                .toUpperCase();
          });

          final maxVal = data.isEmpty
              ? 1.0
              : (data.reduce((a, b) => a > b ? a : b))
                  .clamp(1.0, double.infinity);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.weeklyActivity,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxVal + 1,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < labels.length) {
                              return Text(
                                labels[idx],
                                style: GoogleFonts.outfit(
                                  color: cs.onSurface.withOpacity(0.3),
                                  fontSize: 10,
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 20,
                        ),
                      ),
                      leftTitles: const AxisTitles(),
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
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
                              top: Radius.circular(4),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxVal + 1,
                              color: cs.onSurface.withOpacity(0.03),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(
    String label,
    Color color,
    int count,
    ColorScheme cs,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: cs.onSurface.withOpacity(0.5),
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$count',
          style: GoogleFonts.outfit(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _UserLeaderboardTile extends StatelessWidget {
  final String teamId;
  final String userId;
  final int score;
  final int rank;
  final bool isDark;

  const _UserLeaderboardTile({
    required this.teamId,
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
                Colors.amber.withOpacity(0.15),
                Colors.amber.withOpacity(0.05),
              ],
            )
          : null,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: AuthService()
            .getUsersByIds([userId], teamId: teamId),
        builder: (context, snapshot) {
          String name = l10n.loading;
          String shortName = '?';
          String? photoUrl;

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final data = snapshot.data!.first;
            name = '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim();
            final first = (data['name'] as String?) ?? '';
            if (first.isNotEmpty) {
              shortName = first[0].toUpperCase();
            }
            photoUrl = data['photoUrl'] as String?;
          }

          return Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '#$rank',
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.indigo,
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(
                        shortName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (rankIcon != null) ...[
                Icon(rankIcon, color: iconColor, size: 18),
                const SizedBox(width: 6),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$score ${l10n.taskCount}',
                  style: GoogleFonts.outfit(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WorkloadAvatar extends StatelessWidget {
  final String teamId;
  final String userId;
  final int activeTasks;
  final bool isDark;

  const _WorkloadAvatar({
    required this.teamId,
    required this.userId,
    required this.activeTasks,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AuthService().getUsersByIds([userId], teamId: teamId),
      builder: (context, snapshot) {
        String shortName = '?';
        String? photoUrl;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final data = snapshot.data!.first;
          final first = (data['name'] as String?) ?? '';
          if (first.isNotEmpty) {
            shortName = first[0].toUpperCase();
          }
          photoUrl = data['photoUrl'] as String?;
        }

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
                        color: cs.primary.withOpacity(0.3),
                        width: 2,
                      ),
                      image: photoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(photoUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: photoUrl == null ? cs.surfaceVariant : null,
                    ),
                    child: photoUrl == null
                        ? Center(
                            child: Text(
                              shortName,
                              style: GoogleFonts.outfit(
                                color: cs.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          )
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
                            color: badgeColor.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$activeTasks',
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
              if (snapshot.hasData && snapshot.data!.isNotEmpty)
                Text(
                  (snapshot.data!.first['name'] as String?) ?? '',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        );
      },
    );
  }
}
