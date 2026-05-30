import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/activity_log_model.dart';
import '../../../../models/project_model.dart';
import '../../../../services/firebase_service.dart';
import '../../../../widgets/phobes_widgets.dart';

class ProjectActivityTab extends StatelessWidget {
  final Project project;
  final String teamId;

  const ProjectActivityTab({
    super.key,
    required this.project,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final service = FirebaseService();
    final projectName = project.name.toLowerCase();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.projectActivityTitle,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<ActivityLog>>(
              stream: service.getTeamActivityLogs(teamId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: PhobesLoadingIndicator(color: cs.primary),
                  );
                }
                final logs = (snapshot.data ?? []).where((log) {
                  final details = log.details.toLowerCase();
                  return details.contains(projectName) ||
                      log.action.contains('project');
                }).toList();

                if (logs.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.projectActivityEmpty,
                      style: GoogleFonts.outfit(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.history_rounded,
                              size: 16,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.details,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${log.userName} · ${DateFormat('d MMM HH:mm', locale).format(log.timestamp)}',
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
