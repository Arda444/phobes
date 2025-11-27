import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/activity_log_model.dart';
import '../models/team_model.dart';

class TeamActivityTab extends StatelessWidget {
  final Team team; // Artık ID değil, obje alıyor
  const TeamActivityTab({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final FirebaseService service = FirebaseService();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: StreamBuilder<List<ActivityLog>>(
        // team.id üzerinden sorgu yapılıyor
        stream: service.getTeamActivityLogs(team.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return const Center(
                child: Text("Henüz bir hareket yok.",
                    style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildActivityItem(log);
            },
          );
        },
      ),
    );
  }

  Widget _buildActivityItem(ActivityLog log) {
    IconData icon;
    Color color;
    String actionText;

    switch (log.action) {
      case 'task_created':
        icon = Icons.add_circle_outline;
        color = Colors.blue;
        actionText = "görev oluşturdu";
        break;
      case 'task_completed':
        icon = Icons.check_circle_outline;
        color = Colors.green;
        actionText = "tamamladı";
        break;
      case 'member_joined':
        icon = Icons.person_add_alt;
        color = Colors.purple;
        actionText = "ekibe katıldı";
        break;
      case 'added_link':
        icon = Icons.link;
        color = Colors.orange;
        actionText = "kaynak ekledi";
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
        actionText = "işlem yaptı";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Container(width: 2, height: 30, color: Colors.white10),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 13),
                    children: [
                      TextSpan(
                          text: log.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      TextSpan(text: " $actionText "),
                      TextSpan(
                          text: log.details,
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(DateFormat('dd MMM HH:mm').format(log.timestamp),
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
