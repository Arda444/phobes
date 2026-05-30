import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:confetti/confetti.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../core/phobes_theme.dart';
import '../../widgets/phobes_widgets.dart';
import '../../core/module_info_catalog.dart';
import '../../widgets/phobes_form_wrapper.dart';
import '../../widgets/phobes_module_header.dart';
import '../../l10n/app_localizations.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final FirebaseService _service = FirebaseService();
  late ConfettiController _confettiController;
  late final Stream<QuerySnapshot> _habitsStream;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _habitsStream = _service.getHabitsStream();
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
    final l10n = AppLocalizations.of(context)!;
    TimeOfDay? reminderTime;

    PhobesFormWrapper.show(
      context,
      title: l10n.habitNew,
      form: StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhobesTextFormField(
                controller: controller,
                labelText: l10n.habitNameLabel,
                hintText: l10n.habitNameHint,
                prefixIcon: Icons.local_fire_department_rounded,
                autofocus: true,
              ),
              const SizedBox(height: 16),

              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (picked != null) setSheet(() => reminderTime = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        reminderTime != null
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        color: reminderTime != null ? cs.primary : cs.onSurface.withOpacity(0.4),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reminderTime != null
                              ? l10n.habitReminderDaily(reminderTime!.format(ctx))
                              : l10n.habitReminderOptional,
                          style: GoogleFonts.outfit(
                            color: reminderTime != null
                                ? cs.onSurface
                                : cs.onSurface.withOpacity(0.4),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (reminderTime != null)
                        GestureDetector(
                          onTap: () => setSheet(() => reminderTime = null),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: cs.onSurface.withOpacity(0.4),),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PhobesButton(
                text: AppLocalizations.of(ctx)!.habitStartChain,
                width: double.infinity,
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    final habitId = await _service.addHabit(controller.text.trim());
                    if (reminderTime != null && habitId != null) {
                      await NotificationService().scheduleDailyHabitReminder(
                        habitId: habitId,
                        habitName: controller.text.trim(),
                        time: reminderTime!,
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => controller.dispose());
  }

  Future<void> _toggleDailyReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: AppLocalizations.of(context)!.habitReminderTimeHelp,
    );
    if (picked == null || !mounted) return;
    await NotificationService().scheduleDailyNotification(
      id: 999,
      title: AppLocalizations.of(context)!.habitNotifTitle,
      body: AppLocalizations.of(context)!.habitNotifBody,
      time: picked,
    );
    if (mounted) {
      PhobesSnackbar.show(
        context,
        message: AppLocalizations.of(context)?.habitReminderSet(picked.format(context)) ??
            "Her gün ${picked.format(context)}'de hatırlatıcı kuruldu!",
        type: PhobesSnackbarType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    PhobesModuleHeader(
                      title: l10n.habitScreenTitle,
                      icon: Icons.spa_rounded,
                      onAdd: _addHabitDialog,
                      addTooltip: l10n.habitAddTooltip,
                      info: ModuleInfoCatalog.forHabits(l10n),
                      extraActions: [
                        PhobesModuleHeaderIconButton(
                          icon: Icons.notifications_active_rounded,
                          iconColor: Colors.orangeAccent.shade100,
                          onTap: _toggleDailyReminder,
                        ),
                      ],
                      subtitle: l10n.habitSubtitle,
                    ),
                  ],
                  body: StreamBuilder<QuerySnapshot>(
                    stream: _habitsStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return ModuleNestedScroll.centered(
                          context: context,
                          child: const CircularProgressIndicator(
                            color: PhobesTheme.primaryColor,
                          ),
                        );
                      }

                      final habits = snapshot.data!.docs;

                      if (habits.isEmpty) {
                        return ModuleNestedScroll.centered(
                          context: context,
                          child: PhobesEmptyState(
                            icon: Icons.local_fire_department_outlined,
                            title: l10n.habitEmptyTitle,
                            description: l10n.habitEmptyDesc,
                            buttonText: l10n.habitGetStarted,
                            buttonIcon: Icons.add_rounded,
                            onButtonTap: _addHabitDialog,
                          ),
                        );
                      }

                      SliverChildBuilderDelegate itemDelegate(bool grid) =>
                          SliverChildBuilderDelegate(
                            (context, index) {
                              final habit = habits[index];
                              final data = habit.data() as Map<String, dynamic>;
                              final lastCompleted = data['lastCompleted'] != null
                                  ? (data['lastCompleted'] as Timestamp).toDate()
                                  : null;
                              final isDoneToday = lastCompleted != null &&
                                  DateUtils.isSameDay(lastCompleted, DateTime.now());
                              final streak = data['streak'] ?? 0;
                              return FadeInUp(
                                duration: Duration(milliseconds: 200 + (index * 60)),
                                child: _buildHabitCard(
                                  habit.id, data['title'], streak, isDoneToday,
                                  isGrid: grid,
                                ),
                              );
                            },
                            childCount: habits.length,
                          );

                      return Builder(
                        builder: (context) {
                          return CustomScrollView(
                            slivers: ModuleNestedScroll.slivers(
                              context,
                              [
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 20 : 24,
                                  vertical: isWide ? 8 : 12,
                                ),
                                sliver: isWide
                                    ? SliverLayoutBuilder(
                                        builder: (context, sliverConstraints) {
                                          final w =
                                              sliverConstraints.crossAxisExtent;
                                          final cols = w >= 1500
                                              ? 4
                                              : w >= 1100
                                                  ? 3
                                                  : w >= 700
                                                      ? 2
                                                      : 1;
                                          return SliverGrid(
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: cols,
                                              mainAxisExtent: 96,
                                              crossAxisSpacing: 16,
                                              mainAxisSpacing: 16,
                                            ),
                                            delegate: itemDelegate(true),
                                          );
                                        },
                                      )
                                    : SliverList(delegate: itemDelegate(false)),
                              ),
                              const SliverToBoxAdapter(child: SizedBox(height: 80)),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(
    String id, String title, int streak, bool isDoneToday, {
    bool isGrid = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final Color streakColor = streak >= 7
        ? Colors.orange
        : (streak >= 3 ? Colors.amber : Colors.grey);

    final cardContent = PhobesCard(
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isDoneToday
                  ? LinearGradient(colors: [
                      Colors.green.withOpacity(0.2),
                      Colors.green.withOpacity(0.1),
                    ])
                  : LinearGradient(colors: [
                      streakColor.withOpacity(0.1),
                      streakColor.withOpacity(0.05),
                    ]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                Icons.local_fire_department_rounded,
                color: isDoneToday ? Colors.green : streakColor,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: isDoneToday
                        ? cs.onSurface.withOpacity(0.4)
                        : cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    decoration: isDoneToday ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: streakColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.habitStreakDays(streak),
                        style: GoogleFonts.outfit(
                          color: streakColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isDoneToday
                            ? AppLocalizations.of(context)!.habitGreatGoing
                            : AppLocalizations.of(context)!.habitDontBreakChain,
                        style: GoogleFonts.outfit(
                          color: cs.onSurface.withOpacity(0.3),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Tamamla butonu
          GestureDetector(
            onTap: isDoneToday
                ? null
                : () {
                    _service.toggleHabit(id, true);
                    _confettiController.play();
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: isDoneToday ? PhobesTheme.successGradient : null,
                color: isDoneToday ? null : cs.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: isDoneToday
                    ? null
                    : Border.all(color: cs.onSurface.withOpacity(0.1), width: 2),
                boxShadow: isDoneToday
                    ? [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                    : null,
              ),
              child: isDoneToday
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                  : null,
            ),
          ),
          // Grid modda silme butonu (swipe yerine)
          if (isGrid) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(AppLocalizations.of(ctx)!.habitDeleteTitle),
                    content: Text(AppLocalizations.of(ctx)!.habitDeleteWarning),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(ctx)!.cancel)),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(ctx)!.delete)),
                    ],
                  ),
                );
                if (confirmed == true) await _service.deleteHabit(id);
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete_outline_rounded, size: 16, color: cs.error.withOpacity(0.6)),
              ),
            ),
          ],
        ],
      ),
    );

    if (isGrid) return cardContent;

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete_sweep_rounded, color: cs.error),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(ctx)!.habitDeleteTitle),
            content: Text(AppLocalizations.of(ctx)!.habitDeleteWarning),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(ctx)!.cancel)),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(ctx)!.delete)),
            ],
          ),
        );
        if (confirmed == true) await _service.deleteHabit(id);
        return confirmed ?? false;
      },
      child: cardContent,
    );
  }
}
