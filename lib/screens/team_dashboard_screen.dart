import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/team_model.dart';
import '../models/task_model.dart';
import '../services/firebase_service.dart';
import '../l10n/app_localizations.dart';
import 'team_dashboard_tab.dart'; // Pano widget'ını kullanıyoruz

class TeamDashboardScreen extends StatelessWidget {
  final Team team;
  const TeamDashboardScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final FirebaseService service = FirebaseService();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.tabDashboard,
            style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: StreamBuilder<List<Task>>(
        stream: service.getTeamTasksStream(team.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return Center(
                child: Text(l10n.noData,
                    style: const TextStyle(color: Colors.grey)));
          }

          // Mevcut Dashboard Widget'ını kullanıyoruz
          return TeamDashboardTab(tasks: tasks);
        },
      ),
    );
  }
}
