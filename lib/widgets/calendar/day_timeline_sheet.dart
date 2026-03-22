import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../core/page_transitions.dart';
import '../../models/task_model.dart';
import '../../models/appointment_model.dart';
import '../../models/note_model.dart';
import '../../models/medication_model.dart';
import '../../screens/tasks/task_detail_screen.dart';
import '../../screens/tasks/task_add_edit_screen.dart';
import '../../screens/notes/note_detail_screen.dart';
import '../../screens/appointments/appointment_detail_screen.dart';
import '../../screens/medication/medication_detail_screen.dart';
import '../../services/firebase_service.dart';
import '../../widgets/phobes_widgets.dart';

// ──────────────────────────────────────────────
// Unified timeline item model
// ──────────────────────────────────────────────

enum TimelineItemType { task, appointment, note, medication, habit }

class TimelineItem implements Comparable<TimelineItem> {
  final TimelineItemType type;
  final String title;
  final String? subtitle;
  final DateTime? time;
  final DateTime? endTime;
  final Color color;
  final IconData icon;
  final String? emoji;
  final bool isCompleted;
  final dynamic originalData;

  const TimelineItem({
    required this.type,
    required this.title,
    this.subtitle,
    this.time,
    this.endTime,
    required this.color,
    required this.icon,
    this.emoji,
    this.isCompleted = false,
    this.originalData,
  });

  bool get isAllDay => time == null;

  String get typeLabel {
    switch (type) {
      case TimelineItemType.task:
        return 'Görev';
      case TimelineItemType.appointment:
        return 'Randevu';
      case TimelineItemType.medication:
        return 'İlaç';
      case TimelineItemType.habit:
        return 'Alışkanlık';
      case TimelineItemType.note:
        return 'Not';
    }
  }

  @override
  int compareTo(TimelineItem other) {
    if (isAllDay && other.isAllDay) return title.compareTo(other.title);
    if (isAllDay) return -1;
    if (other.isAllDay) return 1;
    return time!.compareTo(other.time!);
  }
}

// ──────────────────────────────────────────────
// Day Timeline Sheet — the main widget
// ──────────────────────────────────────────────

class DayTimelineSheet extends StatefulWidget {
  final DateTime day;
  final List<dynamic> events;
  final List<Note> notes;
  final List<Medication> medications;
  final List<Map<String, dynamic>> habits;
  final bool isEmbedded;
  final Function(Task task)? onTaskUpdate;
  final Function(Task task)? onTaskDelete;

  const DayTimelineSheet({
    super.key,
    required this.day,
    required this.events,
    required this.notes,
    this.medications = const [],
    this.habits = const [],
    this.isEmbedded = false,
    this.onTaskUpdate,
    this.onTaskDelete,
  });

  @override
  State<DayTimelineSheet> createState() => _DayTimelineSheetState();
}

class _DayTimelineSheetState extends State<DayTimelineSheet> {
  List<TimelineItem> _timelineItems = [];

  @override
  void initState() {
    super.initState();
    _buildTimeline();
  }

  @override
  void didUpdateWidget(covariant DayTimelineSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh if any collection changes or any task completion status might have changed
    _buildTimeline();
  }

  void _buildTimeline() {
    final items = <TimelineItem>[];

    // ───── Tasks ─────
    for (final e in widget.events) {
      if (e is Task) {
        items.add(TimelineItem(
          type: TimelineItemType.task,
          title: e.title,
          subtitle: e.description,
          time: e.startTime,
          endTime: e.endTime,
          color: Color(e.color),
          icon: Icons.task_alt_rounded,
          isCompleted: e.isCompleted,
          originalData: e,
        ));
      } else if (e is Appointment) {
        items.add(TimelineItem(
          type: TimelineItemType.appointment,
          title: e.title,
          subtitle: e.clientName,
          time: e.date,
          endTime: e.endTime,
          color: Colors.purpleAccent,
          icon: Icons.event_rounded,
          emoji: '📅',
          isCompleted: e.status == 'completed',
          originalData: e,
        ));
      }
    }

    // ───── Medications ─────
    final dayStr = DateFormat('yyyy-MM-dd').format(widget.day);
    for (final med in widget.medications) {
      if (!med.isActive) continue;
      if (med.startDate.isAfter(widget.day)) continue;
      if (med.endDate != null && med.endDate!.isBefore(widget.day)) continue;

      final takenTimes = med.takenHistory[dayStr] ?? [];

      for (final t in med.times) {
        final parts = t.split(':');
        final h = int.tryParse(parts[0]) ?? 8;
        final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        final medTime =
            DateTime(widget.day.year, widget.day.month, widget.day.day, h, m);

        items.add(TimelineItem(
          type: TimelineItemType.medication,
          title: med.name,
          subtitle: '${med.dosage} • $t',
          time: medTime,
          color: Color(med.color),
          icon: Icons.medication_rounded,
          emoji: med.icon,
          isCompleted: takenTimes.contains(t),
          originalData: med,
        ));
      }
    }

    // ───── Habits (all-day) ─────
    for (final hab in widget.habits) {
      final lastCompleted = hab['lastCompleted'] != null
          ? (hab['lastCompleted'] as dynamic).toDate()
          : null;
      final isDone = lastCompleted != null &&
          DateUtils.isSameDay(lastCompleted, widget.day);

      items.add(TimelineItem(
        type: TimelineItemType.habit,
        title: hab['title'] ?? 'Alışkanlık',
        subtitle: '${hab['streak'] ?? 0} gün seri',
        time: null,
        color: Colors.orange,
        icon: Icons.local_fire_department_rounded,
        emoji: '🔥',
        isCompleted: isDone,
        originalData: hab,
      ));
    }

    // ───── Notes (all-day) ─────
    for (final note in widget.notes) {
      items.add(TimelineItem(
        type: TimelineItemType.note,
        title: note.title,
        subtitle: note.content.length > 80
            ? '${note.content.substring(0, 80)}...'
            : note.content,
        time: null,
        color: Colors.amber,
        icon: Icons.note_rounded,
        emoji: '📝',
        isCompleted: false,
        originalData: note,
      ));
    }

    items.sort();
    setState(() => _timelineItems = items);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();

    final allDayItems = _timelineItems.where((i) => i.isAllDay).toList();
    final timedItems = _timelineItems.where((i) => !i.isAllDay).toList();

    if (_timelineItems.isEmpty) {
      return _buildEmptyState(cs);
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        children: [
          // ── Summary header ──
          _buildDaySummary(cs, locale),
          const SizedBox(height: 16),

          // ── All-Day Section ──
          if (allDayItems.isNotEmpty) ...[
            _buildSectionHeader('TÜM GÜN', Icons.view_day_rounded, cs),
            const SizedBox(height: 8),
            ...allDayItems.asMap().entries.map((entry) => FadeInLeft(
                  duration: const Duration(milliseconds: 300),
                  delay: Duration(milliseconds: entry.key * 50),
                  child: _buildAllDayCard(entry.value, cs),
                )),
            const SizedBox(height: 20),
          ],

          // ── Timed Events Timeline ──
          if (timedItems.isNotEmpty) ...[
            _buildSectionHeader('PROGRAM', Icons.schedule_rounded, cs),
            const SizedBox(height: 12),
            ...timedItems.asMap().entries.map((entry) {
              final isFirst = entry.key == 0;
              final isLast = entry.key == timedItems.length - 1;
              return FadeInUp(
                duration: const Duration(milliseconds: 350),
                delay: Duration(
                    milliseconds: (entry.key + allDayItems.length) * 60),
                child: _buildConnectedTimelineRow(
                  entry.value,
                  cs,
                  isFirst: isFirst,
                  isLast: isLast,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Day Summary Bar
  // ──────────────────────────────────────────

  Widget _buildDaySummary(ColorScheme cs, String locale) {
    final taskCount =
        _timelineItems.where((i) => i.type == TimelineItemType.task).length;
    final apptCount = _timelineItems
        .where((i) => i.type == TimelineItemType.appointment)
        .length;
    final medCount = _timelineItems
        .where((i) => i.type == TimelineItemType.medication)
        .length;
    final completedCount = _timelineItems.where((i) => i.isCompleted).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.08),
            cs.tertiary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Date block
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(widget.day),
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    height: 1,
                  ),
                ),
                Text(
                  DateFormat('MMM', locale).format(widget.day),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Day name + stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE', locale).format(widget.day),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (taskCount > 0)
                      _statChip('$taskCount görev', cs.primary, cs),
                    if (apptCount > 0)
                      _statChip('$apptCount randevu', Colors.purpleAccent, cs),
                    if (medCount > 0)
                      _statChip('$medCount ilaç', Colors.teal, cs),
                  ],
                ),
              ],
            ),
          ),

          // Progress ring
          if (_timelineItems.isNotEmpty)
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _timelineItems.isEmpty
                        ? 0
                        : completedCount / _timelineItems.length,
                    strokeWidth: 3,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(cs.primary),
                  ),
                  Text(
                    '$completedCount/${_timelineItems.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statChip(String text, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Section Header
  // ──────────────────────────────────────────

  Widget _buildSectionHeader(String text, IconData icon, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.onSurface.withValues(alpha: 0.25)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cs.onSurface.withValues(alpha: 0.3),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: cs.onSurface.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // All-Day Card
  // ──────────────────────────────────────────

  Widget _buildAllDayCard(TimelineItem item, ColorScheme cs) {
    return GestureDetector(
      onTap: () => _onItemTap(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: item.color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            if (item.emoji != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(item.emoji!, style: const TextStyle(fontSize: 18)),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(item.icon, color: item.color, size: 18),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: item.isCompleted
                          ? cs.onSurface.withValues(alpha: 0.35)
                          : cs.onSurface,
                      decoration:
                          item.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null && item.subtitle!.isNotEmpty)
                    Text(
                      item.subtitle!,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.3),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            _buildTypeBadge(item, cs),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Connected Timeline Row
  // ──────────────────────────────────────────

  Widget _buildConnectedTimelineRow(
    TimelineItem item,
    ColorScheme cs, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Time Label ──
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                item.time != null ? DateFormat('HH:mm').format(item.time!) : '',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: item.isCompleted
                      ? cs.onSurface.withValues(alpha: 0.2)
                      : cs.primary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // ── Connected vertical line + node ──
          SizedBox(
            width: 24,
            child: Column(
              children: [
                // Top connector
                Container(
                  width: 2,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isFirst
                        ? Colors.transparent
                        : item.color.withValues(alpha: 0.2),
                    borderRadius: isFirst
                        ? const BorderRadius.vertical(top: Radius.circular(2))
                        : null,
                  ),
                ),
                // Node dot
                GestureDetector(
                  onTap: item.type == TimelineItemType.task
                      ? () async {
                          final task = item.originalData as Task;
                          final updatedTask =
                              task.copyWith(isCompleted: !task.isCompleted);
                          await FirebaseService().updateTask(updatedTask);
                          widget.onTaskUpdate?.call(updatedTask);
                        }
                      : null,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: item.isCompleted
                          ? item.color.withValues(alpha: 0.2)
                          : item.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: item.isCompleted
                            ? item.color.withValues(alpha: 0.3)
                            : item.color.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: item.isCompleted
                          ? null
                          : [
                              BoxShadow(
                                color: item.color.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                    ),
                    child: item.isCompleted
                        ? const Icon(Icons.check, size: 10, color: Colors.white)
                        : null,
                  ),
                ),
                // Bottom connector
                Expanded(
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: isLast
                          ? Colors.transparent
                          : item.color.withValues(alpha: 0.12),
                      borderRadius: isLast
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(2))
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // ── Event Card ──
          Expanded(
            child: _buildDetailCard(item, cs),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Detail Card (rich)
  // ──────────────────────────────────────────

  Widget _buildDetailCard(TimelineItem item, ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _onItemTap(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: item.color, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Icon + Title + Badge
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: item.emoji != null
                        ? Text(item.emoji!,
                            style: const TextStyle(fontSize: 16))
                        : Icon(item.icon, color: item.color, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      if (item.isCompleted)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.check_circle_rounded,
                              size: 16, color: Colors.green),
                        ),
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: item.isCompleted
                                ? cs.onSurface.withValues(alpha: 0.35)
                                : cs.onSurface,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.green.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            "TAMAMLANDI",
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildTypeBadge(item, cs),
                if (item.type == TimelineItemType.task)
                  _buildTaskOptionsMenu(item, cs),
              ],
            ),

            // Row 2: Subtitle / Description
            if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Text(
                  item.subtitle!,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.4),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // Row 3: Time range + duration
            if (item.time != null && item.endTime != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('HH:mm').format(item.time!)} – ${DateFormat('HH:mm').format(item.endTime!)}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.endTime!.difference(item.time!).inMinutes} dk',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (item.isCompleted) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 13, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        'TAMAMLANDI',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Type Badge
  // ──────────────────────────────────────────
  // Task Options Menu
  // ──────────────────────────────────────────

  Widget _buildTaskOptionsMenu(TimelineItem item, ColorScheme cs) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => _handleMenuAction(value, item),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: cs.onSurface),
              const SizedBox(width: 10),
              Text('Düzenle', style: GoogleFonts.outfit(fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'complete',
          child: Row(
            children: [
              Icon(
                  item.isCompleted
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: item.isCompleted ? Colors.orange : Colors.green),
              const SizedBox(width: 10),
              Text(item.isCompleted ? 'Geri Al' : 'Tamamla',
                  style: GoogleFonts.outfit(fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'postpone',
          child: Row(
            children: [
              Icon(Icons.update_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 10),
              Text('Ertele', style: GoogleFonts.outfit(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
              const SizedBox(width: 10),
              Text('Sil',
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, TimelineItem item) async {
    final task = item.originalData as Task;
    final firebaseService = FirebaseService();

    switch (action) {
      case 'edit':
        PhobesPageRoute.pushResponsive(
          context,
          TaskAddEditScreen(
            task: task,
            selectedDate: task.startTime,
          ),
        );
        break;
      case 'complete':
        final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
        await firebaseService.updateTask(updatedTask);
        widget.onTaskUpdate?.call(updatedTask);
        break;
      case 'postpone':
        _showPostponeOptions(context, task, firebaseService);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Görevi Sil', style: GoogleFonts.outfit()),
            content: Text('Bu görevi silmek istediğine emin misin?',
                style: GoogleFonts.outfit()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Vazgeç', style: GoogleFonts.outfit()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    Text('Sil', style: GoogleFonts.outfit(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm == true && task.id != null) {
          await firebaseService.deleteTask(task.id!);
          widget.onTaskDelete?.call(task);
        }
        break;
    }
  }

  void _showPostponeOptions(
      BuildContext context, Task task, FirebaseService firebaseService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Görevi Ertele',
                style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildPostponeItem(context, '15 Dakika',
                const Duration(minutes: 15), task, firebaseService),
            _buildPostponeItem(context, '1 Saat', const Duration(hours: 1),
                task, firebaseService),
            _buildPostponeItem(context, 'Yarına', const Duration(days: 1), task,
                firebaseService),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPostponeItem(BuildContext context, String label,
      Duration duration, Task task, FirebaseService firebaseService) {
    return ListTile(
      title: Text(label, style: GoogleFonts.outfit()),
      leading: const Icon(Icons.access_time_rounded),
      onTap: () async {
        final updatedTask = task.copyWith(
          startTime: task.startTime.add(duration),
          endTime: task.endTime.add(duration),
          postponeCount: task.postponeCount + 1,
        );
        await firebaseService.updateTask(updatedTask);
        widget.onTaskUpdate?.call(updatedTask);
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          PhobesSnackbar.show(context,
              message: "Görev $label ertelendi",
              type: PhobesSnackbarType.success);
        }
      },
    );
  }

  // ──────────────────────────────────────────

  Widget _buildTypeBadge(TimelineItem item, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        item.typeLabel,
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: item.color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Empty State
  // ──────────────────────────────────────────

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wb_sunny_rounded,
                  color: cs.primary.withValues(alpha: 0.4), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              "Bu gün bomboş ☀️",
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Planlamaya başlamak için + butonuna dokun",
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Item Tap Handler
  // ──────────────────────────────────────────

  void _onItemTap(TimelineItem item) {
    switch (item.type) {
      case TimelineItemType.task:
        final task = item.originalData as Task;
        PhobesPageRoute.pushResponsive(context, TaskDetailScreen(task: task));
        break;
      case TimelineItemType.appointment:
        final appt = item.originalData as Appointment;
        PhobesPageRoute.pushResponsive(
            context, AppointmentDetailScreen(appointment: appt));
        break;
      case TimelineItemType.medication:
        final med = item.originalData as Medication;
        PhobesPageRoute.pushResponsive(
            context, MedicationDetailScreen(medication: med));
        break;
      case TimelineItemType.note:
        final note = item.originalData as Note;
        PhobesPageRoute.pushResponsive(context, NoteDetailScreen(note: note));
        break;
      case TimelineItemType.habit:
        break; // Habits don't have a detail screen
    }
  }
}
