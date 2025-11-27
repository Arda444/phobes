import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/team_model.dart';
import '../services/firebase_service.dart';
import 'task_add_edit_screen.dart';
import 'task_detail_screen.dart';

class TeamKanbanTab extends StatelessWidget {
  final Team team;
  const TeamKanbanTab({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final FirebaseService service = FirebaseService();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      // FAB SADELEŞTİRİLDİ (Sadece + ikonu)
      floatingActionButton: FloatingActionButton(
        heroTag: 'kanban_add_task',
        backgroundColor: const Color(0xFF7B1FA2),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TaskAddEditScreen(
                    selectedDate: DateTime.now(), groupId: team.id))),
      ),
      body: StreamBuilder<List<Task>>(
        stream: service.getTeamTasksStream(team.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!;

          final todoTasks =
              tasks.where((t) => !t.isCompleted && t.status == 'todo').toList();
          final progressTasks = tasks
              .where((t) => !t.isCompleted && t.status == 'in_progress')
              .toList();
          final doneTasks =
              tasks.where((t) => t.isCompleted || t.status == 'done').toList();

          return ListView(
            padding:
                const EdgeInsets.only(top: 16, bottom: 80, left: 16, right: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _buildDragTargetColumn(
                  context, "Yapılacak", Colors.redAccent, todoTasks, 'todo'),
              const SizedBox(width: 16),
              _buildDragTargetColumn(context, "Sürüyor", Colors.orangeAccent,
                  progressTasks, 'in_progress'),
              const SizedBox(width: 16),
              _buildDragTargetColumn(
                  context, "Bitti", Colors.greenAccent, doneTasks, 'done'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDragTargetColumn(BuildContext context, String title, Color color,
      List<Task> tasks, String statusId) {
    final width = MediaQuery.of(context).size.width * 0.85;
    final service = FirebaseService();

    return DragTarget<Task>(
      // Sürüklenen veri geldiğinde kabul et
      onWillAcceptWithDetails: (details) => true,

      // HATA ÇÖZÜMÜ BURADA: onAcceptWithDetails kullanıyoruz
      onAcceptWithDetails: (details) {
        // details.data bize asıl Task objesini verir
        final task = details.data;
        service.updateTaskStatus(task.id!, statusId);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: width,
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: candidateData.isNotEmpty
                    ? color
                    : Colors.white10, // Sürüklerken parlar
                width: candidateData.isNotEmpty ? 2 : 1),
          ),
          child: Column(
            children: [
              // Başlık Alanı
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text("${tasks.length}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    )
                  ],
                ),
              ),

              // Kart Listesi
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
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
    return LongPressDraggable<Task>(
      data: task,
      feedback: Transform.rotate(
        angle: 0.05,
        child: SizedBox(
          width: 280, // Sürüklenirken görünen genişlik
          child: Opacity(
            opacity: 0.9,
            child: Card(
              // Sürüklenirken daha basit bir görünüm
              color: const Color(0xFF252525),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(task.title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ETIKETLER
            if (task.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Wrap(
                  spacing: 4,
                  children: task.tags
                      .take(2)
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(t,
                                style: TextStyle(
                                    color: accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ))
                      .toList(),
                ),
              ),

            Text(task.title,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),

            const SizedBox(height: 12),

            // ALT BİLGİLER: AVATAR STACK
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // AVATAR STACK (Birden fazla kişi)
                _AvatarStack(userIds: task.assignedTo),

                Row(children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(DateFormat('dd MMM').format(task.startTime),
                      style: const TextStyle(fontSize: 12, color: Colors.grey))
                ]),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Birden fazla kişiyi gösteren Avatar Stack
class _AvatarStack extends StatelessWidget {
  final List<String> userIds;
  const _AvatarStack({required this.userIds});

  @override
  Widget build(BuildContext context) {
    if (userIds.isEmpty) {
      return const Text("Atanmadı",
          style: TextStyle(color: Colors.grey, fontSize: 12));
    }

    return SizedBox(
      height: 24,
      width: 20.0 * userIds.length + 10,
      child: Stack(
        children: userIds.asMap().entries.map((entry) {
          final index = entry.key;
          final uid = entry.value;

          return Positioned(
            left: index * 15.0,
            child: FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance.collection('users').doc(uid).get(),
              builder: (context, snapshot) {
                // Basit bir placeholder veya gerçek resim
                String letter = "?";
                String? photoUrl;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  letter = data['name']?[0] ?? "?";
                  photoUrl = data['photoUrl'];
                }
                return CircleAvatar(
                  radius: 12,
                  backgroundColor:
                      Colors.primaries[index % Colors.primaries.length],
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(letter,
                          style: const TextStyle(
                              fontSize: 10,
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

// Model Yaması
extension TaskStatus on Task {
  String? get status {
    return null;
  }
}
