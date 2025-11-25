import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/activity_log_model.dart';
import '../l10n/app_localizations.dart';

class TeamActivityTab extends StatelessWidget {
  final String teamId;
  const TeamActivityTab({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final FirebaseService service = FirebaseService();
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<ActivityLog>>(
      stream: service.getTeamActivityLogs(teamId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Center(
              child: Text(l10n.noData,
                  style: const TextStyle(color: Colors.grey)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (ctx, i) => Divider(color: Colors.grey.shade800),
          itemBuilder: (context, index) {
            final log = logs[index];
            String actionText = "";
            IconData icon = Icons.info;
            Color color = Colors.grey;

            switch (log.action) {
              case 'task_created':
                actionText = "görev oluşturdu";
                icon = Icons.add_circle;
                color = Colors.blue;
                break;
              case 'task_completed':
                actionText = "görevi tamamladı";
                icon = Icons.check_circle;
                color = Colors.green;
                break;
              case 'member_joined':
                actionText = "ekibe katıldı";
                icon = Icons.person_add;
                color = Colors.purple;
                break;
              case 'member_left':
                actionText = "ekipten ayrıldı";
                icon = Icons.exit_to_app;
                color = Colors.red;
                break;
              default:
                actionText = log.action;
            }

            return ListTile(
              leading: Icon(icon, color: color),
              title: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(color: Colors.white),
                  children: [
                    TextSpan(
                        text: log.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: " $actionText "),
                    TextSpan(text: log.details, style: TextStyle(color: color)),
                  ],
                ),
              ),
              subtitle: Text(DateFormat('dd MMM HH:mm').format(log.timestamp),
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11)),
            );
          },
        );
      },
    );
  }
}
