import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'package:confetti/confetti.dart'; // Konfeti için

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final FirebaseService _service = FirebaseService();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _addHabitDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Yeni Alışkanlık",
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: "Örn: 2L Su İç",
              hintStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _service.addHabit(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text("Ekle"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("Alışkanlıklar",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.add, color: Colors.tealAccent),
              onPressed: _addHabitDialog)
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _service.getHabitsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final habits = snapshot.data!.docs;

              if (habits.isEmpty) {
                return const Center(
                    child: Text("Henüz alışkanlık eklemedin.",
                        style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: habits.length,
                itemBuilder: (context, index) {
                  final habit = habits[index];
                  final data = habit.data() as Map<String, dynamic>;
                  final lastCompleted = data['lastCompleted'] != null
                      ? (data['lastCompleted'] as Timestamp).toDate()
                      : null;
                  final isDoneToday = lastCompleted != null &&
                      DateUtils.isSameDay(lastCompleted, DateTime.now());

                  return Card(
                    color: Colors.grey.shade900,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: isDoneToday
                                ? Colors.green
                                : Colors.grey.shade800,
                            shape: BoxShape.circle),
                        child: Icon(Icons.local_fire_department,
                            color: isDoneToday ? Colors.white : Colors.grey),
                      ),
                      title: Text(data['title'],
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              decoration: isDoneToday
                                  ? TextDecoration.lineThrough
                                  : null)),
                      subtitle: Text("${data['streak']} Günlük Seri",
                          style: const TextStyle(color: Colors.orangeAccent)),
                      trailing: Checkbox(
                        value: isDoneToday,
                        activeColor: Colors.teal,
                        onChanged: isDoneToday
                            ? null
                            : (v) {
                                if (v == true) {
                                  _service.toggleHabit(habit.id, true);
                                  _confettiController.play(); // Konfeti patlat
                                }
                              },
                      ),
                      onLongPress: () => _service.deleteHabit(habit.id),
                    ),
                  );
                },
              );
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }
}
