import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../models/task_model.dart';
import '../models/team_model.dart';
import '../services/firebase_service.dart';

class TeamDashboardTab extends StatelessWidget {
  final Team team;
  const TeamDashboardTab({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();

    return StreamBuilder<List<Task>>(
        stream: service.getTeamTasksStream(team.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!;
          final total = tasks.length;
          final completed = tasks.where((t) => t.isCompleted).length;
          final progress = total == 0 ? 0.0 : completed / total;

          // İstatistik Değişkenleri
          Map<String, int> mvpScores = {};
          Map<String, int> workloadScores = {};

          // YENİ MANTIK: Çoklu Atama Desteği
          for (var t in tasks) {
            // Eğer kimse atanmamışsa "Ortak" say
            if (t.assignedTo.isEmpty) {
              if (t.isCompleted) {
                mvpScores["Ortak"] = (mvpScores["Ortak"] ?? 0) + 1;
              } else {
                workloadScores["Ortak"] = (workloadScores["Ortak"] ?? 0) + 1;
              }
            } else {
              // Atanan herkesi döngüye al
              for (var userId in t.assignedTo) {
                if (t.isCompleted) {
                  mvpScores[userId] = (mvpScores[userId] ?? 0) + 1;
                } else {
                  workloadScores[userId] = (workloadScores[userId] ?? 0) + 1;
                }
              }
            }
          }

          String mvpName = "Henüz Yok";
          int mvpCount = 0;
          if (mvpScores.isNotEmpty) {
            final entry =
                mvpScores.entries.reduce((a, b) => a.value > b.value ? a : b);
            // Not: Burada User ID görünüyor. İsim çekmek için extra işlem gerekir
            // Şimdilik ID'nin ilk 5 hanesini gösteriyoruz.
            mvpName = entry.key == "Ortak"
                ? "Ortak"
                : "Üye (${entry.key.substring(0, 3)}..)";
            mvpCount = entry.value;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HAFTANIN MVP'Sİ KARTI
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5))
                      ]),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.emoji_events,
                            color: Colors.orange, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Haftanın Yıldızı",
                              style: GoogleFonts.poppins(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold)),
                          Text("$mvpName ($mvpCount)",
                              style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900)),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. İŞ YÜKÜ GRAFİĞİ (Pie Chart)
                Text("İş Yükü Dağılımı",
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: workloadScores.isEmpty
                      ? const Center(
                          child: Text("Veri yok",
                              style: TextStyle(color: Colors.grey)))
                      : PieChart(
                          PieChartData(
                            sections: workloadScores.entries.map((e) {
                              final color = Colors.primaries[
                                  e.key.hashCode % Colors.primaries.length];
                              final label = e.key == "Ortak"
                                  ? "Ortak"
                                  : e.key.substring(0, min(3, e.key.length));
                              return PieChartSectionData(
                                  color: color,
                                  value: e.value.toDouble(),
                                  title: label,
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white));
                            }).toList(),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // 3. Proje İlerlemesi
                Text("Proje İlerlemesi",
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    color: Colors.teal,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: 8),
                Align(
                    alignment: Alignment.centerRight,
                    child: Text("%${(progress * 100).toInt()} Tamamlandı",
                        style: const TextStyle(color: Colors.grey))),
              ],
            ),
          );
        });
  }
}
