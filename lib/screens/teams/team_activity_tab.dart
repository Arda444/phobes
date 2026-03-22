import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../models/activity_log_model.dart';
import '../../models/team_model.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_widgets.dart';

class TeamActivityTab extends StatelessWidget {
  final Team team;
  const TeamActivityTab({super.key, required this.team});

  @override
  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<List<ActivityLog>>(
      stream: service.getTeamActivityLogs(team.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: PhobesLoadingIndicator(color: cs.primary));
        }
        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded,
                    size: 64, color: cs.onSurface.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                Text(l10n.noData,
                    style: GoogleFonts.outfit(
                        color: cs.onSurface.withValues(alpha: 0.5),
                        fontSize: 16)),
              ],
            ),
          );
        }

        // Group logs by date
        Map<String, List<ActivityLog>> groupedLogs = {};
        for (var log in logs) {
          String dateKey = _formatDateGroup(log.timestamp);
          if (!groupedLogs.containsKey(dateKey)) {
            groupedLogs[dateKey] = [];
          }
          groupedLogs[dateKey]!.add(log);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
          itemCount: groupedLogs.keys.length,
          itemBuilder: (context, groupIndex) {
            String dateKey = groupedLogs.keys.elementAt(groupIndex);
            List<ActivityLog> dayLogs = groupedLogs[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, left: 40),
                  child: Text(
                    dateKey,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...List.generate(dayLogs.length, (index) {
                  return _buildActivityItem(
                      dayLogs[index],
                      l10n,
                      cs,
                      isDark,
                      index == dayLogs.length - 1 &&
                          groupIndex == groupedLogs.length - 1);
                }),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(date.year, date.month, date.day);

    if (logDate == today) {
      return "BUGÜN";
    } else if (logDate == yesterday) {
      return "DÜN";
    } else {
      return DateFormat('d MMM yyyy').format(date).toUpperCase();
    }
  }

  Widget _buildActivityItem(ActivityLog log, AppLocalizations l10n,
      ColorScheme cs, bool isDark, bool isLast) {
    Color actionColor;
    String actionText;
    IconData smallIcon;

    switch (log.action) {
      case 'task_created':
        actionColor = Colors.blueAccent;
        actionText = "oluşturdu";
        smallIcon = Icons.add_rounded;
        break;
      case 'task_completed':
        actionColor = Colors.greenAccent;
        actionText = "tamamladı";
        smallIcon = Icons.check_rounded;
        break;
      case 'moved_to_progress':
        actionColor = Colors.orangeAccent;
        actionText = "işleme aldı";
        smallIcon = Icons.arrow_forward_rounded;
        break;
      case 'moved_to_todo':
        actionColor = cs.onSurface.withValues(alpha: 0.4);
        actionText = "yapılacaklara taşıdı";
        smallIcon = Icons.replay_rounded;
        break;
      case 'member_joined':
        actionColor = Colors.purpleAccent;
        actionText = "katıldı";
        smallIcon = Icons.person_add_rounded;
        break;
      default:
        actionColor = cs.onSurface.withValues(alpha: 0.3);
        actionText = "güncelledi";
        smallIcon = Icons.edit_rounded;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: actionColor.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    log.userName.isNotEmpty
                        ? log.userName[0].toUpperCase()
                        : "?",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: actionColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: cs.outline.withValues(alpha: 0.1),
                  ),
                )
              else
                const SizedBox(height: 16),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                        color: cs.onSurface, fontSize: 14, height: 1.4),
                    children: [
                      TextSpan(
                        text: log.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: " bir görevi $actionText:",
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? cs.surfaceContainerHighest.withValues(alpha: 0.3)
                        : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: cs.outline.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(smallIcon, size: 14, color: actionColor),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          log.details,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('HH:mm').format(log.timestamp),
                  style: GoogleFonts.outfit(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
