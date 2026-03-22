import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:confetti/confetti.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../core/phobes_theme.dart';
import '../../widgets/phobes_widgets.dart';

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
    NotificationService().requestPermissions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _addHabitDialog() {
    final controller = TextEditingController();
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PhobesGlassCard(
        margin: EdgeInsets.zero,
        borderRadius: 24,
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text("Yeni Alışkanlık",
                style: GoogleFonts.outfit(
                    color: cs.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Kendine yeni bir meydan okuma ekle! 🚀",
                style: GoogleFonts.outfit(
                    color: cs.onSurface.withValues(alpha: 0.5), fontSize: 14)),
            const SizedBox(height: 24),
            PhobesTextFormField(
              controller: controller,
              labelText: "Alışkanlık Adı",
              hintText: "Örn: 2L Su İç",
              prefixIcon: Icons.local_fire_department_rounded,
              autofocus: true,
            ),
            const SizedBox(height: 24),
            PhobesButton(
              text: "Zinciri Başlat",
              width: double.infinity,
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _service.addHabit(controller.text.trim());
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDailyReminder() {
    NotificationService().scheduleDailyNotification(
      id: 999,
      title: "Alışkanlık Zamanı! 🔥",
      body: "Bugünkü hedeflerini tamamlamayı unutma. Zinciri kırma!",
      time: const TimeOfDay(hour: 9, minute: 0),
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Her sabah 09:00'a hatırlatıcı kuruldu!"),
      backgroundColor: PhobesTheme.successColor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primary.withValues(alpha: 0.15),
                          cs.surface,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(32)),
                      border: Border(
                          bottom: BorderSide(
                              color: cs.primary.withValues(alpha: 0.1))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Alışkanlıklar",
                                  style: GoogleFonts.outfit(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.flash_on_rounded,
                                            color: Colors.orange, size: 14),
                                        const SizedBox(width: 4),
                                        Text("ZİNCİRİ KIRMA!",
                                            style: GoogleFonts.outfit(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                                letterSpacing: 1)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text("Bugün harika görünüyorsun 🔥",
                                      style: GoogleFonts.outfit(
                                          color: cs.onSurface
                                              .withValues(alpha: 0.4),
                                          fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PhobesIconButton(
                          icon: Icons.notifications_active_rounded,
                          color: Colors.orangeAccent,
                          backgroundColor: Colors.orange.withValues(alpha: 0.1),
                          onTap: _toggleDailyReminder,
                        ),
                        const SizedBox(width: 12),
                        PhobesIconButton(
                          icon: Icons.add_rounded,
                          backgroundColor: cs.primary,
                          color: cs.onPrimary,
                          enableGlow: true,
                          onTap: _addHabitDialog,
                        ),
                      ],
                    ),
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _service.getHabitsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SliverFillRemaining(
                        child: Center(
                            child: CircularProgressIndicator(
                                color: PhobesTheme.primaryColor)),
                      );
                    }

                    final habits = snapshot.data!.docs;

                    if (habits.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PhobesGlassCard(
                                padding: const EdgeInsets.all(32),
                                borderRadius: 40,
                                child: Icon(
                                    Icons.local_fire_department_outlined,
                                    color: cs.primary.withValues(alpha: 0.5),
                                    size: 64),
                              ),
                              const SizedBox(height: 32),
                              Text("Henüz bir hedef yok",
                                  style: GoogleFonts.outfit(
                                      color: cs.onSurface,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 48),
                                child: Text(
                                    "Yeni bir alışkanlık edinerek zinciri başlatmaya ne dersin?",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                        color:
                                            cs.onSurface.withValues(alpha: 0.4),
                                        fontSize: 15)),
                              ),
                              const SizedBox(height: 32),
                              PhobesButton(
                                text: "Hadi Başlayalım",
                                onPressed: _addHabitDialog,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final habit = habits[index];
                            final data = habit.data() as Map<String, dynamic>;
                            final lastCompleted = data['lastCompleted'] != null
                                ? (data['lastCompleted'] as Timestamp).toDate()
                                : null;
                            final isDoneToday = lastCompleted != null &&
                                DateUtils.isSameDay(
                                    lastCompleted, DateTime.now());
                            final streak = data['streak'] ?? 0;

                            return FadeInUp(
                              duration:
                                  Duration(milliseconds: 300 + (index * 100)),
                              child: _buildHabitCard(
                                  habit.id, data['title'], streak, isDoneToday),
                            );
                          },
                          childCount: habits.length,
                        ),
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
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

  Widget _buildHabitCard(
      String id, String title, int streak, bool isDoneToday) {
    final cs = Theme.of(context).colorScheme;
    Color streakColor = streak >= 7
        ? Colors.orange
        : (streak >= 3 ? Colors.amber : Colors.grey);

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete_sweep_rounded, color: cs.error),
      ),
      onDismissed: (_) => _service.deleteHabit(id),
      child: PhobesCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: isDoneToday
                    ? LinearGradient(colors: [
                        Colors.green.withValues(alpha: 0.2),
                        Colors.green.withValues(alpha: 0.1)
                      ])
                    : LinearGradient(colors: [
                        streakColor.withValues(alpha: 0.1),
                        streakColor.withValues(alpha: 0.05)
                      ]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: isDoneToday ? Colors.green : streakColor,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: isDoneToday
                          ? cs.onSurface.withValues(alpha: 0.4)
                          : cs.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration:
                          isDoneToday ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: streakColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "$streak GÜN",
                          style: GoogleFonts.outfit(
                              color: streakColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isDoneToday ? "Harika gidiyorsun! 🎉" : "Zinciri Kırma",
                        style: GoogleFonts.outfit(
                            color: cs.onSurface.withValues(alpha: 0.3),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: isDoneToday
                  ? null
                  : () {
                      _service.toggleHabit(id, true);
                      _confettiController.play();
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isDoneToday ? PhobesTheme.successGradient : null,
                  color:
                      isDoneToday ? null : cs.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: isDoneToday
                      ? null
                      : Border.all(
                          color: cs.onSurface.withValues(alpha: 0.1), width: 2),
                  boxShadow: isDoneToday
                      ? [
                          BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ]
                      : null,
                ),
                child: isDoneToday
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 20)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
