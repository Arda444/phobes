import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/team_model.dart';
import '../services/firebase_service.dart';
import '../l10n/app_localizations.dart';

class TeamDashboardTab extends StatelessWidget {
  final Team team;
  const TeamDashboardTab({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Task>>(
      stream: service.getTeamTasksStream(team.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!;
        final total = tasks.length;

        final completed =
            tasks.where((t) => t.isCompleted || t.status == 'done').length;
        final inProgress = tasks.where((t) => t.status == 'in_progress').length;
        final todo =
            tasks.where((t) => !t.isCompleted && t.status == 'todo').length;

        final lowPriority =
            tasks.where((t) => !t.isCompleted && t.priority == 0).length;
        final medPriority =
            tasks.where((t) => !t.isCompleted && t.priority == 1).length;
        final highPriority =
            tasks.where((t) => !t.isCompleted && t.priority == 2).length;

        final completionRate = total == 0 ? 0.0 : (completed / total);

        Map<String, int> memberPerformance = {};
        for (var t in tasks) {
          if (t.isCompleted || t.status == 'done') {
            if (t.assignedTo.isNotEmpty) {
              for (var uid in t.assignedTo) {
                memberPerformance[uid] = (memberPerformance[uid] ?? 0) + 1;
              }
            }
          }
        }

        var sortedMembers = memberPerformance.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressCard(completed, total, completionRate, l10n),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard(
                              l10n.priorityLow,
                              "$lowPriority",
                              Colors.green,
                              Icons.arrow_downward_rounded)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildStatCard(
                              l10n.priorityMedium,
                              "$medPriority",
                              Colors.orange,
                              Icons.remove_rounded)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildStatCard(
                              l10n.priorityHigh,
                              "$highPriority",
                              Colors.redAccent,
                              Icons.priority_high_rounded)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.taskStatus,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 30,
                              sections: [
                                PieChartSectionData(
                                    value: todo.toDouble(),
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.7),
                                    radius: 40,
                                    showTitle: false),
                                PieChartSectionData(
                                    value: inProgress.toDouble(),
                                    color: Colors.orangeAccent,
                                    radius: 40,
                                    showTitle: false),
                                PieChartSectionData(
                                    value: completed.toDouble(),
                                    color: Colors.greenAccent,
                                    radius: 45,
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
                              _buildChartLegend(
                                  l10n.statusTodo,
                                  Colors.redAccent.withValues(alpha: 0.7),
                                  todo),
                              const SizedBox(height: 8),
                              _buildChartLegend(l10n.statusInProgress,
                                  Colors.orangeAccent, inProgress),
                              const SizedBox(height: 8),
                              _buildChartLegend(l10n.completed,
                                  Colors.greenAccent, completed),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.teamLeaderboard,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 10),
                  if (sortedMembers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16)),
                      child: Text(l10n.noCompletedTasksYet,
                          style: const TextStyle(color: Colors.grey)),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedMembers.length,
                      itemBuilder: (context, index) {
                        final entry = sortedMembers[index];
                        return _UserLeaderboardTile(
                            userId: entry.key,
                            score: entry.value,
                            rank: index + 1);
                      },
                    ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(
      int completed, int total, double rate, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.purple.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.projectProgress,
                  style:
                      GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text("%${(rate * 100).toInt()}",
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("$completed / $total ${l10n.completed}",
                  style:
                      GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
            ],
          ),
          SizedBox(
            height: 70,
            width: 70,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: rate,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.tealAccent),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                    child: Icon(Icons.analytics_rounded,
                        color: Colors.white.withValues(alpha: 0.8), size: 30)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(title,
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const Spacer(),
        Text("$count",
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ],
    );
  }
}

class _UserLeaderboardTile extends StatelessWidget {
  final String userId;
  final int score;
  final int rank;

  const _UserLeaderboardTile({
    required this.userId,
    required this.score,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Color rankColor = Colors.grey.shade800;
    IconData? rankIcon;
    Color iconColor = Colors.transparent;

    if (rank == 1) {
      rankColor = const Color(0xFF3E3118);
      rankIcon = Icons.emoji_events;
      iconColor = Colors.amber;
    } else if (rank == 2) {
      rankIcon = Icons.star;
      iconColor = Colors.grey.shade400;
    } else if (rank == 3) {
      rankIcon = Icons.star_half;
      iconColor = Colors.brown.shade300;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: rank == 1 ? rankColor : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: rank == 1
            ? Border.all(color: Colors.amber.withValues(alpha: 0.3))
            : null,
      ),
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

          return ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  child: Text("#$rank",
                      style: const TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.indigo,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(shortName,
                          style: const TextStyle(color: Colors.white))
                      : null,
                ),
              ],
            ),
            title: Text(name,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (rankIcon != null)
                  Icon(rankIcon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text("$score ${l10n.taskCount}",
                      style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
