import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/team_model.dart';
import '../models/task_model.dart';
import '../services/firebase_service.dart';
import 'task_add_edit_screen.dart';
import 'task_detail_screen.dart'; // Hata burada veriyordu, importu kontrol ettik.
import '../l10n/app_localizations.dart';
import 'team_dashboard_tab.dart';
import 'team_activity_tab.dart';

class TeamDetailScreen extends StatefulWidget {
  final Team team;
  final int initialIndex; // 0: Görevler, 1: Pano, 2: Aktivite

  const TeamDetailScreen(
      {super.key, required this.team, this.initialIndex = 0});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final FirebaseService _service = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String title = "";
    Widget content = const SizedBox();
    bool showAddButton = false;

    // Hangi sayfayı göstereceğimize karar ver (Sekmesiz)
    switch (widget.initialIndex) {
      case 1:
        title = l10n.tabDashboard; // Pano
        content = _buildDashboardView();
        break;
      case 2:
        title = l10n.tabActivity; // Aktivite
        content = TeamActivityTab(teamId: widget.team.id);
        break;
      case 0:
      default:
        title = l10n.tabTasks; // Görevler
        content = _buildTasksView(l10n);
        showAddButton = true;
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white)),
        actions: showAddButton
            ? [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TaskAddEditScreen(
                              selectedDate: DateTime.now(),
                              groupId: widget.team.id))),
                )
              ]
            : null,
      ),
      body: content,
    );
  }

  // GÖREVLER LİSTESİ
  Widget _buildTasksView(AppLocalizations l10n) {
    return StreamBuilder<List<Task>>(
      stream: _service.getTeamTasksStream(widget.team.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return Center(
              child: Text(l10n.noEvents,
                  style: GoogleFonts.poppins(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: tasks.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (ctx, index) {
            final task = tasks[index];
            return Card(
              color: Colors.grey.shade900,
              child: ListTile(
                leading: Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: Color(task.color)),
                title: Text(task.title,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null)),
                subtitle: Text(
                    task.assignedTo != null
                        ? "Atanan: ..."
                        : DateFormat('d MMM HH:mm').format(task.startTime),
                    style: const TextStyle(color: Colors.grey)),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(task: task))),
              ),
            );
          },
        );
      },
    );
  }

  // PANO GÖRÜNÜMÜ
  Widget _buildDashboardView() {
    return StreamBuilder<List<Task>>(
      stream: _service.getTeamTasksStream(widget.team.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = snapshot.data ?? [];
        return TeamDashboardTab(tasks: tasks);
      },
    );
  }
}
