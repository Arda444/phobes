import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/team_model.dart';
import '../services/firebase_service.dart';
import 'task_add_edit_screen.dart';
import 'task_detail_screen.dart';
import '../l10n/app_localizations.dart';

class TeamKanbanTab extends StatefulWidget {
  final Team team;
  const TeamKanbanTab({super.key, required this.team});

  @override
  State<TeamKanbanTab> createState() => _TeamKanbanTabState();
}

class _TeamKanbanTabState extends State<TeamKanbanTab> {
  final FirebaseService _service = FirebaseService();
  bool _showMyTasksOnly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Masaüstü kontrolü (Genişlik > 800px ise Masaüstü modu)
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      floatingActionButton: FloatingActionButton(
        heroTag: 'kanban_add_task',
        backgroundColor: const Color(0xFF7B1FA2),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TaskAddEditScreen(
                    selectedDate: DateTime.now(), groupId: widget.team.id))),
      ),
      body: Column(
        children: [
          _buildFilterHeader(l10n),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _service.getTeamTasksStream(widget.team.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var tasks = snapshot.data!;

                if (_showMyTasksOnly) {
                  final currentUserId = _service.currentUserId;
                  tasks = tasks.where((t) {
                    return t.assignedTo.contains(currentUserId);
                  }).toList();
                }

                final todoTasks = tasks
                    .where((t) => !t.isCompleted && t.status == 'todo')
                    .toList();
                final progressTasks = tasks
                    .where((t) => !t.isCompleted && t.status == 'in_progress')
                    .toList();
                final doneTasks = tasks
                    .where((t) => t.isCompleted || t.status == 'done')
                    .toList();

                // RESPONSIVE LAYOUT
                // Masaüstü -> Row (Yan Yana)
                // Mobil -> Column (Alt Alta)
                if (isDesktop) {
                  return Row(
                    children: [
                      Expanded(
                          child: _buildDragTargetSection(
                              title: l10n.statusTodo,
                              color: Colors.redAccent,
                              tasks: todoTasks,
                              statusId: 'todo',
                              icon: Icons.assignment_outlined,
                              l10n: l10n)),
                      Expanded(
                          child: _buildDragTargetSection(
                              title: l10n.statusInProgress,
                              color: Colors.orangeAccent,
                              tasks: progressTasks,
                              statusId: 'in_progress',
                              icon: Icons.pending_actions_outlined,
                              l10n: l10n)),
                      Expanded(
                          child: _buildDragTargetSection(
                              title: l10n.statusDone,
                              color: Colors.greenAccent,
                              tasks: doneTasks,
                              statusId: 'done',
                              icon: Icons.check_circle_outline,
                              l10n: l10n)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Expanded(
                          child: _buildDragTargetSection(
                              title: l10n.statusTodo,
                              color: Colors.redAccent,
                              tasks: todoTasks,
                              statusId: 'todo',
                              icon: Icons.assignment_outlined,
                              l10n: l10n)),
                      Expanded(
                          child: _buildDragTargetSection(
                              title: l10n.statusInProgress,
                              color: Colors.orangeAccent,
                              tasks: progressTasks,
                              statusId: 'in_progress',
                              icon: Icons.pending_actions_outlined,
                              l10n: l10n)),
                      Expanded(
                          child: _buildDragTargetSection(
                              title: l10n.statusDone,
                              color: Colors.greenAccent,
                              tasks: doneTasks,
                              statusId: 'done',
                              icon: Icons.check_circle_outline,
                              l10n: l10n)),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF151515),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showMyTasksOnly ? l10n.filterMyTasks : l10n.filterAllTeamTasks,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _showMyTasksOnly,
                  activeTrackColor: Colors.purpleAccent,
                  inactiveThumbColor: Colors.grey,
                  activeThumbColor: Colors.white,
                  onChanged: (val) => setState(() => _showMyTasksOnly = val),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragTargetSection({
    required String title,
    required Color color,
    required List<Task> tasks,
    required String statusId,
    required IconData icon,
    required AppLocalizations l10n,
  }) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final task = details.data;
        if (task.status != statusId ||
            (statusId == 'done' && !task.isCompleted)) {
          _service.updateTaskStatus(task.id!, statusId);
          String actionCode = 'status_change';
          if (statusId == 'in_progress') {
            actionCode = 'moved_to_progress';
          } else if (statusId == 'done') {
            actionCode = 'task_completed';
          } else if (statusId == 'todo') {
            actionCode = 'moved_to_todo';
          }
          _service.logTeamActivity(widget.team.id, actionCode, task.title);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHovered
                ? color.withValues(alpha: 0.1)
                : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? color : Colors.white10,
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 8),
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 14)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text("${tasks.length}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    )
                  ],
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          l10n.empty,
                          style: GoogleFonts.poppins(
                              color: Colors.white24, fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: tasks.length,
                        itemBuilder: (ctx, i) =>
                            _buildDraggableCard(context, tasks[i], color),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableCard(
      BuildContext context, Task task, Color accentColor) {
    // Mobilde tam genişlik, masaüstünde biraz daha dar olabilir ama Column içinde olduğu için
    // parent genişliğini alacaktır. Bu yüzden width ayarı çok kritik değil.
    return LongPressDraggable<Task>(
      data: task,
      feedback: Transform.rotate(
        angle: 0.05,
        child: SizedBox(
          width: 300,
          child: Opacity(
            opacity: 0.9,
            child: Card(
              color: const Color(0xFF2C2C2C),
              elevation: 10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.drag_indicator, color: Colors.white54),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(task.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _TaskCard(task: task, accentColor: accentColor),
      ),
      child: _TaskCard(task: task, accentColor: accentColor),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final Color accentColor;

  const _TaskCard({required this.task, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: accentColor, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
                if (task.priority == 2)
                  const Icon(Icons.priority_high,
                      color: Colors.redAccent, size: 14)
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _AvatarStack(userIds: task.assignedTo),
                Text(DateFormat('d MMM').format(task.startTime),
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<String> userIds;
  const _AvatarStack({required this.userIds});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (userIds.isEmpty) {
      return Text(l10n.unassigned,
          style: const TextStyle(color: Colors.grey, fontSize: 10));
    }

    return SizedBox(
      height: 20,
      width: 15.0 * userIds.length + 10,
      child: Stack(
        children: userIds.asMap().entries.map((entry) {
          final index = entry.key;
          final uid = entry.value;

          return Positioned(
            left: index * 12.0,
            child: FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance.collection('users').doc(uid).get(),
              builder: (context, snapshot) {
                String letter = "?";
                String? photoUrl;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  letter = data['name']?[0] ?? "?";
                  photoUrl = data['photoUrl'];
                }
                return CircleAvatar(
                  radius: 10,
                  backgroundColor:
                      Colors.primaries[index % Colors.primaries.length],
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(letter,
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold))
                      : null,
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
