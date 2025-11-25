import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';
import '../l10n/app_localizations.dart';

class TeamDashboardTab extends StatelessWidget {
  final List<Task> tasks;
  const TeamDashboardTab({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = tasks.length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final progress = total == 0 ? 0.0 : completed / total;

    // Liderlik tablosu için hesaplama
    Map<String, int> leaderboard = {};
    for (var t in tasks.where((t) => t.isCompleted)) {
      // assignedTo ID'sini kullanıyoruz.
      final userId = t.assignedTo ?? "Ortak";
      leaderboard[userId] = (leaderboard[userId] ?? 0) + 1;
    }
    var sortedLeaderboard = leaderboard.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PROJE İLERLEMESİ
          Text(l10n.projectProgress,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${(progress * 100).toInt()}%",
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold)),
                    Text("$completed / $total ${l10n.completedTasks}",
                        style: GoogleFonts.poppins(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  color: Colors.blue,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // LİDERLİK TABLOSU
          Text("Liderlik Tablosu",
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 10),
          if (sortedLeaderboard.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  Text(l10n.noData, style: const TextStyle(color: Colors.grey)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedLeaderboard.length,
              itemBuilder: (context, index) {
                final entry = sortedLeaderboard[index];
                return Card(
                  color: Colors.grey.shade900,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: index == 0
                          ? Colors.amber
                          : (index == 1 ? Colors.grey : Colors.brown),
                      child: Text("${index + 1}",
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(
                        entry.key == "Ortak"
                            ? "Ortak Görevler"
                            : "Üye (ID: ...${entry.key.substring(0, 4)})",
                        style: GoogleFonts.poppins(color: Colors.white)),
                    trailing: Text("${entry.value} Görev",
                        style: GoogleFonts.poppins(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
