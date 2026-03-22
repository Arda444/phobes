import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../widgets/phobes_widgets.dart';
import '../../models/task_model.dart';
import '../../models/medication_model.dart';
import '../../services/firebase_service.dart';

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

class _UpcomingEventsScreenState extends State<UpcomingEventsScreen> {
  final _firebaseService = FirebaseService();
  String _filter = 'all';

  static const _filters = {
    'all': 'Tümü',
    'task': 'Görevler',
    'medication': 'İlaçlar',
    'appointment': 'Randevular',
    'habit': 'Alışkanlıklar',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: PhobesPremiumAppBar(
        title: 'Yaklaşan Olaylar',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 12,
              children: _filters.entries.map((e) {
                final isSelected = _filter == e.key;
                return PhobesChip(
                  label: e.value,
                  isSelected: isSelected,
                  onTap: () => setState(() => _filter = e.key),
                  color: isSelected ? const Color(0xFF8B5CF6) : null,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildEventsStream(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsStream(bool isDark) {
    return StreamBuilder<List<Task>>(
      stream: _firebaseService.getAllUserTasksStream(),
      builder: (context, taskSnap) {
        return StreamBuilder<List<Medication>>(
          stream: _firebaseService.getMedicationsStream(),
          builder: (context, medSnap) {
            if (taskSnap.connectionState == ConnectionState.waiting ||
                medSnap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              );
            }

            final tasks = taskSnap.data ?? [];
            final meds = (medSnap.data ?? []).where((m) => m.isActive).toList();

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final tomorrow = today.add(const Duration(days: 1));
            final weekEnd = today.add(const Duration(days: 7));

            final List<_UpcomingEvent> allEvents = [];

            for (final task in tasks) {
              if (task.status == 'completed') continue;
              final taskDate = task.startTime;
              if (taskDate.isBefore(today.subtract(const Duration(days: 1)))) {
                continue;
              }
              if (taskDate.isAfter(weekEnd)) continue;

              allEvents.add(_UpcomingEvent(
                title: task.title,
                subtitle: task.priority >= 3
                    ? '🔴 Yüksek Öncelik'
                    : task.priority == 2
                        ? '🟡 Orta Öncelik'
                        : '🟢 Düşük',
                time: DateFormat('HH:mm').format(taskDate),
                type: 'task',
                color: const Color(0xFF8B5CF6),
                icon: Icons.task_alt_rounded,
                dateTime: taskDate,
              ));
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

                  allEvents.add(_UpcomingEvent(
                    title: med.name,
                    subtitle: med.dosage.isNotEmpty ? med.dosage : 'Doz zamanı',
                    time: time,
                    type: 'medication',
                    color: Color(med.color),
                    icon: Icons.medication_rounded,
                    emoji: med.icon,
                    dateTime: dt,
                  ));
                }
              }
            }

            var events = allEvents;
            if (_filter != 'all') {
              events = events.where((e) => e.type == _filter).toList();
            }

            final todayEvents = events
                .where((e) =>
                    e.dateTime.year == today.year &&
                    e.dateTime.month == today.month &&
                    e.dateTime.day == today.day)
                .toList()
              ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

            final tomorrowEvents = events
                .where((e) =>
                    e.dateTime.year == tomorrow.year &&
                    e.dateTime.month == tomorrow.month &&
                    e.dateTime.day == tomorrow.day)
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
              return _buildEmptyState(isDark);
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (todayEvents.isNotEmpty) ...[
                  _buildSectionHeader(
                      'Bugün', '${todayEvents.length} olay', isDark),
                  ...todayEvents.asMap().entries.map((entry) => FadeInRight(
                        delay: Duration(milliseconds: entry.key * 50),
                        child: _buildEventCard(entry.value, isDark),
                      )),
                  const SizedBox(height: 16),
                ],
                if (tomorrowEvents.isNotEmpty) ...[
                  _buildSectionHeader(
                      'Yarın', '${tomorrowEvents.length} olay', isDark),
                  ...tomorrowEvents.asMap().entries.map((entry) => FadeInRight(
                        delay: Duration(milliseconds: entry.key * 50),
                        child: _buildEventCard(entry.value, isDark),
                      )),
                  const SizedBox(height: 16),
                ],
                if (laterEvents.isNotEmpty) ...[
                  _buildSectionHeader(
                      'Bu Hafta', '${laterEvents.length} olay', isDark),
                  ...laterEvents.asMap().entries.map((entry) => FadeInRight(
                        delay: Duration(milliseconds: entry.key * 50),
                        child: _buildEventCard(entry.value, isDark,
                            showDate: true),
                      )),
                ],
                const SizedBox(height: 80),
              ],
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
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
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

  Widget _buildEventCard(_UpcomingEvent event, bool isDark,
      {bool showDate = false}) {
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
                          color: event.color.withValues(alpha: 0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: cs.outline.withValues(alpha: 0.1),
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
                          color: event.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: event.emoji.isNotEmpty
                              ? Text(event.emoji,
                                  style: const TextStyle(fontSize: 20))
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
                                color: cs.onSurface.withValues(alpha: 0.5),
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
                                color: cs.onSurface.withValues(alpha: 0.3),
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

  Widget _buildEmptyState(bool isDark) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: FadeInUp(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calendar_today_rounded,
                    size: 64, color: cs.primary.withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 32),
              Text(
                'Yaklaşan olay yok',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Görevler, ilaçlar ve randevularınız burada kronolojik sırayla görünecek.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  height: 1.5,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
