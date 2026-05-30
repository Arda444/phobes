import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../models/medication_model.dart';
import '../../models/appointment_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/phobes_widgets.dart';
import '../../core/module_info_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_module_header.dart';

class _UpcomingEvent {
  final String title;
  final String subtitle;
  final String time;
  final String type;
  final Color color;
  final IconData icon;
  final String emoji;
  final DateTime dateTime;

  _UpcomingEvent({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    required this.color,
    required this.icon,
    this.emoji = '',
    required this.dateTime,
  });
}

class UpcomingEventsScreen extends StatefulWidget {
  const UpcomingEventsScreen({super.key});

  @override
  State<UpcomingEventsScreen> createState() => _UpcomingEventsScreenState();
}

class _UpcomingEventsScreenState extends State<UpcomingEventsScreen>
    with SingleTickerProviderStateMixin {
  final _firebaseService = FirebaseService();
  late final TabController _tabController;
  late final Stream<List<Task>> _tasksStream;
  late final Stream<List<Medication>> _medsStream;
  late final Stream<List<Map<String, dynamic>>> _habitsStream;
  late final Stream<List<Appointment>> _providerApptsStream;
  late final Stream<List<Appointment>> _clientApptsStream;

  static const _filterKeys = [
    'all',
    'task',
    'medication',
    'appointment',
    'habit',
  ];

  String get _filter => _filterKeys[_tabController.index];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterKeys.length, vsync: this)
      ..addListener(_onTabChanged);
    _tasksStream = _firebaseService.getAllUserTasksStream().asBroadcastStream();
    _medsStream = _firebaseService.getMedicationsStream().asBroadcastStream();
    _habitsStream = _firebaseService
        .getHabitsStream()
        .map(
          (snap) => snap.docs
              .map(
                (d) => {
                  ...Map<String, dynamic>.from(d.data() as Map),
                  'id': d.id,
                },
              )
              .toList(),
        )
        .asBroadcastStream();
    _providerApptsStream =
        _firebaseService.getAppointmentsStream().asBroadcastStream();
    _clientApptsStream = _firebaseService
        .getMyAppointmentsAsClientStream()
        .asBroadcastStream();
  }

  List<Appointment> _mergeAppointments(
    List<Appointment> provider,
    List<Appointment> client,
  ) {
    final seen = <String>{};
    final merged = <Appointment>[];
    for (final a in [...provider, ...client]) {
      if (a.id != null && seen.add(a.id!)) merged.add(a);
    }
    merged.sort((a, b) => a.date.compareTo(b.date));
    return merged;
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging || !mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          PhobesModuleHeader(
            title: l10n.upcomingEventsTitle,
            icon: Icons.upcoming_rounded,
            onClose: () => Navigator.pop(context),
            info: ModuleInfoCatalog.forUpcoming(l10n),
            tabController: _tabController,
            tabs: [
              PhobesModuleTab(l10n.upcomingFilterAll),
              PhobesModuleTab(
                l10n.upcomingFilterTasks,
                Icons.task_alt_rounded,
              ),
              PhobesModuleTab(
                l10n.upcomingFilterMeds,
                Icons.medication_rounded,
              ),
              PhobesModuleTab(
                l10n.upcomingFilterAppts,
                Icons.event_rounded,
              ),
              PhobesModuleTab(
                l10n.upcomingFilterHabits,
                Icons.repeat_rounded,
              ),
            ],
          ),
        ],
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width >= 900
                  ? 2000
                  : double.infinity,
            ),
            child: Builder(
              builder: (context) => _buildEventsStream(context, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventsStream(BuildContext nestedContext, bool isDark) {
    return StreamBuilder<List<Task>>(
      stream: _tasksStream,
      builder: (context, taskSnap) {
        return StreamBuilder<List<Medication>>(
          stream: _medsStream,
          builder: (context, medSnap) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _habitsStream,
              builder: (context, habitSnap) {
            return StreamBuilder<List<Appointment>>(
              stream: _providerApptsStream,
              builder: (context, providerApptSnap) {
            return StreamBuilder<List<Appointment>>(
              stream: _clientApptsStream,
              builder: (context, clientApptSnap) {
            if (taskSnap.connectionState == ConnectionState.waiting ||
                medSnap.connectionState == ConnectionState.waiting ||
                habitSnap.connectionState == ConnectionState.waiting ||
                providerApptSnap.connectionState == ConnectionState.waiting ||
                clientApptSnap.connectionState == ConnectionState.waiting) {
              return ModuleNestedScroll.centered(
                context: nestedContext,
                child: const CircularProgressIndicator(
                  color: Color(0xFF8B5CF6),
                ),
              );
            }

            final tasks = taskSnap.data ?? [];
            final meds = (medSnap.data ?? []).where((m) => m.isActive).toList();
            final habits = habitSnap.data ?? [];
            final appointments = _mergeAppointments(
              providerApptSnap.data ?? [],
              clientApptSnap.data ?? [],
            );

            final l10n = AppLocalizations.of(context)!;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final tomorrow = today.add(const Duration(days: 1));
            final weekEnd = today.add(const Duration(days: 7));

            final List<_UpcomingEvent> allEvents = [];

            for (final habit in habits) {
              final title = habit['title'] as String? ?? l10n.upcomingHabitDefault;
              final last = habit['lastCompleted'];
              final today = DateTime(now.year, now.month, now.day);
              if (last is Timestamp) {
                final d = last.toDate();
                if (d.year == today.year &&
                    d.month == today.month &&
                    d.day == today.day) {
                  continue;
                }
              }
              allEvents.add(
                _UpcomingEvent(
                  title: title,
                  subtitle: l10n.upcomingHabitNotDoneToday,
                  time: '',
                  type: 'habit',
                  color: Colors.orange,
                  icon: Icons.local_fire_department_rounded,
                  dateTime: today.add(const Duration(hours: 20)),
                ),
              );
            }

            for (final task in tasks) {
              if (task.isCompleted || task.status == 'done') continue;
              final taskDate = task.startTime;
              if (taskDate.isBefore(today.subtract(const Duration(days: 1)))) {
                continue;
              }
              if (taskDate.isAfter(weekEnd)) continue;

              allEvents.add(
                _UpcomingEvent(
                  title: task.title,
                  subtitle: task.priority >= 3
                      ? l10n.upcomingPriorityHigh
                      : task.priority == 2
                          ? l10n.upcomingPriorityMedium
                          : l10n.upcomingPriorityLow,
                  time: DateFormat('HH:mm').format(taskDate),
                  type: 'task',
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.task_alt_rounded,
                  dateTime: taskDate,
                ),
              );
            }

            for (final appt in appointments) {
              if (appt.status == 'cancelled') continue;
              if (appt.date.isBefore(now.subtract(const Duration(hours: 1)))) {
                continue;
              }
              if (appt.date.isAfter(weekEnd)) continue;
              allEvents.add(
                _UpcomingEvent(
                  title: appt.title,
                  subtitle: appt.clientId != null
                      ? l10n.upcomingClientAppointment
                      : l10n.upcomingAppointment,
                  time: DateFormat('HH:mm').format(appt.date),
                  type: 'appointment',
                  color: const Color(0xFF2196F3),
                  icon: Icons.event_rounded,
                  dateTime: appt.date,
                ),
              );
            }

            for (final med in meds) {
              for (final time in med.times) {
                final parts = time.split(':');
                final doseTime = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                );
                for (int dayOffset = 0; dayOffset <= 1; dayOffset++) {
                  final dt = doseTime.add(Duration(days: dayOffset));
                  final key = DateFormat('yyyy-MM-dd').format(dt);
                  final taken = med.takenHistory[key]?.contains(time) ?? false;
                  if (taken && dayOffset == 0) {
                    continue;
                  }

                  allEvents.add(
                    _UpcomingEvent(
                      title: med.name,
                      subtitle:
                          med.dosage.isNotEmpty ? med.dosage : l10n.upcomingDoseTime,
                      time: time,
                      type: 'medication',
                      color: Color(med.color),
                      icon: Icons.medication_rounded,
                      emoji: med.icon,
                      dateTime: dt,
                    ),
                  );
                }
              }
            }

            var events = allEvents;
            if (_filter != 'all') {
              events = events.where((e) => e.type == _filter).toList();
            }

            final todayEvents = events
                .where(
                  (e) =>
                      e.dateTime.year == today.year &&
                      e.dateTime.month == today.month &&
                      e.dateTime.day == today.day,
                )
                .toList()
              ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

            final tomorrowEvents = events
                .where(
                  (e) =>
                      e.dateTime.year == tomorrow.year &&
                      e.dateTime.month == tomorrow.month &&
                      e.dateTime.day == tomorrow.day,
                )
                .toList()
              ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

            final laterEvents = events.where((e) {
              final d =
                  DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
              return d.isAfter(tomorrow);
            }).toList()
              ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

            if (todayEvents.isEmpty &&
                tomorrowEvents.isEmpty &&
                laterEvents.isEmpty) {
              return ModuleNestedScroll.scrollView(
                context: nestedContext,
                slivers: [
                  SliverFillRemaining(
                      child: _buildEmptyState(context, isDark)),
                ],
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                if (!isWide) {
                  return ModuleNestedScroll.scrollView(
                    context: nestedContext,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                      if (todayEvents.isNotEmpty) ...[
                        _buildSectionHeader(
                            l10n.upcomingToday,
                            l10n.upcomingEventCount(todayEvents.length),
                            isDark),
                        ...todayEvents.asMap().entries.map((e) => FadeInRight(
                              delay: Duration(milliseconds: e.key * 50),
                              child: _buildEventCard(e.value, isDark),
                            )),
                        const SizedBox(height: 16),
                      ],
                      if (tomorrowEvents.isNotEmpty) ...[
                        _buildSectionHeader(
                            l10n.upcomingTomorrow,
                            l10n.upcomingEventCount(tomorrowEvents.length),
                            isDark),
                        ...tomorrowEvents
                            .asMap()
                            .entries
                            .map((e) => FadeInRight(
                                  delay: Duration(milliseconds: e.key * 50),
                                  child: _buildEventCard(e.value, isDark),
                                )),
                        const SizedBox(height: 16),
                      ],
                      if (laterEvents.isNotEmpty) ...[
                        _buildSectionHeader(
                            l10n.upcomingThisWeek,
                            l10n.upcomingEventCount(laterEvents.length),
                            isDark),
                        ...laterEvents.asMap().entries.map((e) => FadeInRight(
                              delay: Duration(milliseconds: e.key * 50),
                              child: _buildEventCard(e.value, isDark,
                                  showDate: true),
                            )),
                      ],
                            const SizedBox(height: 80),
                          ]),
                        ),
                      ),
                    ],
                  );
                }

                // Web / Geniş ekran: bölüm başlıkları + 2/3/4 kolonlu kart ızgarası
                final w = constraints.maxWidth;
                final colCount = w >= 1500
                    ? 4
                    : w >= 1100
                        ? 3
                        : 2;
                Widget buildGrid(List<_UpcomingEvent> evs,
                    {bool showDate = false}) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: colCount,
                      mainAxisExtent: 104,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: evs.length,
                    itemBuilder: (context, i) => FadeInUp(
                      delay: Duration(milliseconds: i * 40),
                      child: _buildEventGridCard(evs[i], isDark,
                          showDate: showDate),
                    ),
                  );
                }

                return ModuleNestedScroll.scrollView(
                  context: nestedContext,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 80),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (todayEvents.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 8, 20, 12),
                              child: _buildSectionHeader(
                                  l10n.upcomingToday,
                                  l10n.upcomingEventCount(todayEvents.length),
                                  isDark),
                            ),
                            buildGrid(todayEvents),
                            const SizedBox(height: 24),
                          ],
                          if (tomorrowEvents.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: _buildSectionHeader(
                                  l10n.upcomingTomorrow,
                                  l10n.upcomingEventCount(tomorrowEvents.length),
                                  isDark),
                            ),
                            buildGrid(tomorrowEvents),
                            const SizedBox(height: 24),
                          ],
                          if (laterEvents.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: _buildSectionHeader(
                                  l10n.upcomingThisWeek,
                                  l10n.upcomingEventCount(laterEvents.length),
                                  isDark),
                            ),
                            buildGrid(laterEvents, showDate: true),
                          ],
                        ]),
                      ),
                    ),
                  ],
                );
              },
            );
              },
            );
              },
            );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    _UpcomingEvent event,
    bool isDark, {
    bool showDate = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: event.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: event.color.withOpacity(0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: cs.outline.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 12),
                child: PhobesCard(
                  padding: const EdgeInsets.all(12),
                  margin: EdgeInsets.zero,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: event.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: event.emoji.isNotEmpty
                              ? Text(
                                  event.emoji,
                                  style: const TextStyle(fontSize: 20),
                                )
                              : Icon(event.icon, size: 20, color: event.color),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              event.title,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              event.subtitle,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (event.time.isNotEmpty)
                            Text(
                              event.time,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: event.color,
                              ),
                            ),
                          if (showDate)
                            Text(
                              '${event.dateTime.day}.${event.dateTime.month}',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withOpacity(0.3),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Web / geniş ekran için timeline olmayan kompakt grid kartı
  Widget _buildEventGridCard(_UpcomingEvent event, bool isDark,
      {bool showDate = false}) {
    final cs = Theme.of(context).colorScheme;

    return PhobesCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Sol renk şeridi
            Container(width: 4, color: event.color),
            const SizedBox(width: 12),
            // İkon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: event.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: event.emoji.isNotEmpty
                    ? Text(event.emoji, style: const TextStyle(fontSize: 18))
                    : Icon(event.icon, size: 18, color: event.color),
              ),
            ),
            const SizedBox(width: 12),
            // Başlık + alt başlık
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    event.subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Saat + isteğe bağlı tarih
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (event.time.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: event.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.time,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: event.color,
                        ),
                      ),
                    ),
                  if (showDate)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        DateFormat(
                          'd MMM',
                          Localizations.localeOf(context).languageCode,
                        ).format(event.dateTime),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return PhobesEmptyState(
      icon: Icons.calendar_today_rounded,
      title: l10n.upcomingNoEvents,
      description: l10n.moduleInfoUpcomingIntro,
    );
  }
}
