import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/project_model.dart';
import '../../../../models/task_model.dart';
import '../../../../services/firebase_service.dart';
import '../../../../widgets/phobes_widgets.dart';

class ProjectStatisticsTab extends StatelessWidget {
  final Project project;
  final String teamId;

  const ProjectStatisticsTab({
    super.key,
    required this.project,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final fb = FirebaseService();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<List<Task>>(
        stream: fb.getProjectTasksStream(teamId, project.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data ?? [];
          final total = tasks.length;
          final completed =
              tasks.where((t) => t.isCompleted).length;
          final overdue = tasks.where((t) {
            if (t.isCompleted) return false;
            return t.endTime.isBefore(DateTime.now());
          }).length;
          final open = total - completed;
          final completionRate =
              total > 0 ? (completed / total * 100).round() : 0;

          return ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.projectStatisticsTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          title: l10n.projectStatTotal,
                          value: '$total',
                          icon: Icons.task_alt_rounded,
                          color: Colors.blueAccent,
                          cs: cs,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          title: l10n.projectStatCompleted,
                          value: '$completed',
                          icon: Icons.check_circle_rounded,
                          color: Colors.greenAccent,
                          cs: cs,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          title: l10n.projectStatOpen,
                          value: '$open',
                          icon: Icons.pending_actions_rounded,
                          color: Colors.orangeAccent,
                          cs: cs,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          title: l10n.projectStatOverdue,
                          value: '$overdue',
                          icon: Icons.warning_rounded,
                          color: Colors.redAccent,
                          cs: cs,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PhobesCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.projectCompletionRate(completionRate),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 180,
                          child: total == 0
                              ? Center(
                                  child: Text(
                                    l10n.projectNoTasksYet,
                                    style: GoogleFonts.outfit(
                                      color: cs.onSurface.withOpacity(0.45),
                                    ),
                                  ),
                                )
                              : PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 36,
                                    sections: [
                                      if (completed > 0)
                                        PieChartSectionData(
                                          value: completed.toDouble(),
                                          color: Colors.greenAccent,
                                          title: '$completed',
                                          radius: 48,
                                          titleStyle: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      if (open > 0)
                                        PieChartSectionData(
                                          value: open.toDouble(),
                                          color: cs.primary,
                                          title: '$open',
                                          radius: 48,
                                          titleStyle: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ColorScheme cs,
  }) {
    return PhobesCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.55),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
