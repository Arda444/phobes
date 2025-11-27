import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:table_calendar/table_calendar.dart';
import '../l10n/app_localizations.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';
import '../services/firebase_service.dart';
import '../services/nova_service.dart';
import 'task_add_edit_screen.dart';
import 'note_add_edit_screen.dart';
import 'task_detail_screen.dart';

// Görünüm Modları
enum CalendarViewMode { weekly, monthly, daily }

enum CalendarFilter { all, personal, team }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  // Takvim Durumları
  CalendarViewMode _viewMode = CalendarViewMode.weekly;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  final FirebaseService _firebaseService = FirebaseService();
  late Stream<List<Note>> _notesStream;

  CalendarFilter _currentFilter = CalendarFilter.all;
  String? _weeklyNote;

  // Günlük görünümde genişleyen kart takibi
  int? _expandedDailyTaskIndex;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _notesStream = _firebaseService.getNotesStream();
  }

  // --- Veri İşleme ---
  Map<DateTime, List<Task>> _processTasksForCalendar(List<Task> tasks) {
    final map = <DateTime, List<Task>>{};
    final DateTime endDate = DateTime.now().add(const Duration(days: 365));

    for (final t in tasks) {
      bool show = true;
      if (_currentFilter == CalendarFilter.personal && t.groupId != null) {
        show = false;
      }
      if (_currentFilter == CalendarFilter.team && t.groupId == null) {
        show = false;
      }
      if (!show) continue;

      if (t.repeatRule == 'none') {
        final dateOnly = DateUtils.dateOnly(t.startTime);
        map[dateOnly] = [...?map[dateOnly], t];
        continue;
      }

      // Tekrarlayan görev mantığı
      DateTime nextDate = t.startTime;
      while (nextDate.isBefore(endDate)) {
        final dateOnly = DateUtils.dateOnly(nextDate);
        final virtualTask = t.copyWith(
          startTime: DateTime(nextDate.year, nextDate.month, nextDate.day,
              t.startTime.hour, t.startTime.minute),
          endTime: DateTime(nextDate.year, nextDate.month, nextDate.day,
              t.endTime.hour, t.endTime.minute),
        );
        map[dateOnly] = [...?map[dateOnly], virtualTask];

        if (t.repeatRule == 'daily') {
          nextDate = nextDate.add(const Duration(days: 1));
        } else if (t.repeatRule == 'weekly') {
          nextDate = nextDate.add(const Duration(days: 7));
        } else if (t.repeatRule == 'monthly') {
          var newYear = nextDate.year;
          var newMonth = nextDate.month + 1;
          if (newMonth > 12) {
            newMonth = 1;
            newYear++;
          }
          var daysInNewMonth = DateUtils.getDaysInMonth(newYear, newMonth);
          var newDay = t.startTime.day > daysInNewMonth
              ? daysInNewMonth
              : t.startTime.day;
          nextDate = DateTime(
              newYear, newMonth, newDay, t.startTime.hour, t.startTime.minute);
        } else {
          break;
        }
      }
    }
    return map;
  }

  Map<DateTime, List<Note>> _processNotesForCalendar(List<Note> notes) {
    final map = <DateTime, List<Note>>{};
    for (final n in notes) {
      final day = DateUtils.dateOnly(n.date);
      map[day] = [...?map[day], n];
    }
    return map;
  }

  // --- Navigasyon ---
  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
    });
  }

  List<DateTime> _getWeekDays(DateTime focused) {
    DateTime startOfWeek =
        focused.subtract(Duration(days: focused.weekday - 1));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  // --- UI Widgetları ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _weeklyNote ??= l10n.writeYourNotes;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: _buildAppBar(l10n),
      body: StreamBuilder<List<Task>>(
        stream: _firebaseService.getAllUserTasksStream(),
        builder: (context, taskSnapshot) {
          return StreamBuilder<List<Note>>(
            stream: _notesStream,
            builder: (context, noteSnapshot) {
              if (taskSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.purple));
              }

              final tasks = taskSnapshot.data ?? [];
              final notes = noteSnapshot.data ?? [];
              final eventsMap = _processTasksForCalendar(tasks);
              final notesMap = _processNotesForCalendar(notes);

              return Column(
                children: [
                  // Sadece Tarih Navigasyonu (Butonlar AppBar'a taşındı)
                  _buildDateNavigator(l10n),

                  // Ana İçerik
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildBodyContent(l10n, eventsMap, notesMap),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.appTitle,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white)),
          Text(
            _currentFilter == CalendarFilter.all
                ? l10n.filterAll
                : (_currentFilter == CalendarFilter.personal
                    ? l10n.filterPersonal
                    : l10n.filterTeam),
            style: GoogleFonts.poppins(
                fontSize: 10, color: Colors.tealAccent, letterSpacing: 1),
          ),
        ],
      ),
      actions: [
        _buildViewModeButton(l10n),
        _buildFilterMenu(l10n),
        IconButton(
          icon: const Icon(Icons.description_rounded, color: Colors.white),
          tooltip: l10n.allNotes,
          onPressed: _showAllNotes,
        ),
        _buildAddMenu(l10n),
        IconButton(
          icon: const Icon(Icons.today_rounded, color: Colors.white),
          onPressed: _goToToday,
          tooltip: l10n.today,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildViewModeButton(AppLocalizations l10n) {
    IconData icon;
    switch (_viewMode) {
      case CalendarViewMode.weekly:
        icon = Icons.view_week_rounded;
        break;
      case CalendarViewMode.monthly:
        icon = Icons.calendar_view_month_rounded;
        break;
      case CalendarViewMode.daily:
        icon = Icons.view_day_rounded;
        break;
    }

    return PopupMenuButton<CalendarViewMode>(
      icon: Icon(icon, color: Colors.white),
      tooltip: l10n.viewWeekly,
      color: Colors.grey.shade900,
      onSelected: (mode) => setState(() => _viewMode = mode),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: CalendarViewMode.weekly,
          child: Row(children: [
            const Icon(Icons.view_week_rounded, color: Colors.purpleAccent),
            const SizedBox(width: 8),
            Text(l10n.viewWeekly,
                style: GoogleFonts.poppins(color: Colors.white))
          ]),
        ),
        PopupMenuItem(
          value: CalendarViewMode.monthly,
          child: Row(children: [
            const Icon(Icons.calendar_view_month_rounded,
                color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text(l10n.viewMonthly,
                style: GoogleFonts.poppins(color: Colors.white))
          ]),
        ),
        PopupMenuItem(
          value: CalendarViewMode.daily,
          child: Row(children: [
            const Icon(Icons.view_day_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Text(l10n.viewDaily,
                style: GoogleFonts.poppins(color: Colors.white))
          ]),
        ),
      ],
    );
  }

  Widget _buildFilterMenu(AppLocalizations l10n) {
    return PopupMenuButton<CalendarFilter>(
      icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
      tooltip: l10n.filterAll,
      color: Colors.grey.shade900,
      onSelected: (result) => setState(() => _currentFilter = result),
      itemBuilder: (context) => [
        PopupMenuItem(
            value: CalendarFilter.all,
            child: Text(l10n.filterAll,
                style: const TextStyle(color: Colors.white))),
        PopupMenuItem(
            value: CalendarFilter.personal,
            child: Text(l10n.filterPersonal,
                style: const TextStyle(color: Colors.white))),
        PopupMenuItem(
            value: CalendarFilter.team,
            child: Text(l10n.filterTeam,
                style: const TextStyle(color: Colors.white))),
      ],
    );
  }

  Widget _buildAddMenu(AppLocalizations l10n) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xFF7B1FA2), // Techluna Moru
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
      tooltip: l10n.addEvent,
      offset: const Offset(0, 40),
      color: Colors.grey.shade900,
      onSelected: (value) {
        if (value == 'ai') {
          _showNovaWizard();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskAddEditScreen(
                selectedDate: _selectedDay ?? DateTime.now(),
              ),
            ),
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'ai',
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.tealAccent),
              const SizedBox(width: 8),
              Text(l10n.addSmart,
                  style: GoogleFonts.poppins(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'manual',
          child: Row(
            children: [
              const Icon(Icons.edit_calendar, color: Colors.white),
              const SizedBox(width: 8),
              Text(l10n.addManual,
                  style: GoogleFonts.poppins(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateNavigator(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_viewMode == CalendarViewMode.weekly) {
                  _focusedDay = _focusedDay.subtract(const Duration(days: 7));
                } else if (_viewMode == CalendarViewMode.monthly) {
                  _focusedDay = DateTime(
                      _focusedDay.year, _focusedDay.month - 1, _focusedDay.day);
                } else {
                  _focusedDay = _focusedDay.subtract(const Duration(days: 1));
                }
              });
            },
          ),
          Text(
            _viewMode == CalendarViewMode.daily
                ? DateFormat('d MMMM EEEE', l10n.localeName).format(_focusedDay)
                : DateFormat('MMMM yyyy', l10n.localeName).format(_focusedDay),
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_viewMode == CalendarViewMode.weekly) {
                  _focusedDay = _focusedDay.add(const Duration(days: 7));
                } else if (_viewMode == CalendarViewMode.monthly) {
                  _focusedDay = DateTime(
                      _focusedDay.year, _focusedDay.month + 1, _focusedDay.day);
                } else {
                  _focusedDay = _focusedDay.add(const Duration(days: 1));
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(AppLocalizations l10n,
      Map<DateTime, List<Task>> events, Map<DateTime, List<Note>> notes) {
    switch (_viewMode) {
      case CalendarViewMode.weekly:
        return _buildWeeklyView(l10n, events, notes);
      case CalendarViewMode.monthly:
        return _buildMonthlyView(l10n, events, notes);
      case CalendarViewMode.daily:
        return _buildDailyView(l10n, events, notes);
    }
  }

  Widget _buildWeeklyView(AppLocalizations l10n,
      Map<DateTime, List<Task>> eventsMap, Map<DateTime, List<Note>> notesMap) {
    final weekDays = _getWeekDays(_focusedDay);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Expanded(
              flex: 1,
              child: _buildRow(weekDays.sublist(0, 3), eventsMap, notesMap)),
          Expanded(
              flex: 1,
              child: _buildRow(weekDays.sublist(3, 6), eventsMap, notesMap)),
          Expanded(
              flex: 1,
              child: _buildThirdRow(weekDays[6], l10n, eventsMap, notesMap)),
        ],
      ),
    );
  }

  Widget _buildRow(List<DateTime> days, Map<DateTime, List<Task>> eventsMap,
      Map<DateTime, List<Note>> notesMap) {
    return Row(
        children:
            days.map((day) => _buildDayBox(day, eventsMap, notesMap)).toList());
  }

  Widget _buildThirdRow(DateTime sunday, AppLocalizations l10n,
      Map<DateTime, List<Task>> eventsMap, Map<DateTime, List<Note>> notesMap) {
    return Row(children: [
      _buildDayBox(sunday, eventsMap, notesMap),
      Expanded(flex: 2, child: _buildWeeklyNoteBox(l10n)),
    ]);
  }

  Widget _buildMonthlyView(AppLocalizations l10n,
      Map<DateTime, List<Task>> eventsMap, Map<DateTime, List<Note>> notesMap) {
    return TableCalendar(
      locale: l10n.localeName,
      firstDay: DateTime(2020),
      lastDay: DateTime(2030),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerVisible: false,
      shouldFillViewport: true,
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: GoogleFonts.poppins(color: Colors.white70),
        weekendStyle:
            GoogleFonts.poppins(color: Colors.redAccent.withValues(alpha: 0.7)),
      ),
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: false,
      ),
      onPageChanged: (focusedDay) {
        setState(() => _focusedDay = focusedDay);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        _showDayMenu(selectedDay);
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) => _buildMonthlyCell(
            day, eventsMap[DateUtils.dateOnly(day)] ?? [], false),
        todayBuilder: (context, day, focusedDay) => _buildMonthlyCell(
            day, eventsMap[DateUtils.dateOnly(day)] ?? [], true),
        selectedBuilder: (context, day, focusedDay) => Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              color: Colors.purple.shade700,
              borderRadius: BorderRadius.circular(8)),
          child: _buildMonthlyCellContent(
              day, eventsMap[DateUtils.dateOnly(day)] ?? [], true, true),
        ),
      ),
    );
  }

  Widget _buildMonthlyCell(DateTime day, List<Task> dailyEvents, bool isToday) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isToday ? Colors.orange.shade800 : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: _buildMonthlyCellContent(day, dailyEvents, isToday, false),
    );
  }

  Widget _buildMonthlyCellContent(
      DateTime day, List<Task> dailyEvents, bool isToday, bool isSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, top: 4),
          child: Text(
            '${day.day}',
            style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dailyEvents.length,
              itemBuilder: (context, index) {
                final task = dailyEvents[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(task.color),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyView(AppLocalizations l10n,
      Map<DateTime, List<Task>> eventsMap, Map<DateTime, List<Note>> notesMap) {
    final dateKey = DateUtils.dateOnly(_focusedDay);
    final dailyTasks = eventsMap[dateKey] ?? [];
    dailyTasks.sort((a, b) => a.startTime.compareTo(b.startTime));

    if (dailyTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.noEvents, style: GoogleFonts.poppins(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B1FA2)),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          TaskAddEditScreen(selectedDate: _focusedDay))),
              child: Text(l10n.newTask,
                  style: const TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dailyTasks.length,
      itemBuilder: (context, i) {
        final task = dailyTasks[i];
        final bool isExpanded = _expandedDailyTaskIndex == i;

        return FadeInUp(
          delay: Duration(milliseconds: i * 50),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isExpanded
                      ? Colors.purpleAccent
                      : Color(task.color).withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedDailyTaskIndex = isExpanded ? null : i;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text(DateFormat('HH:mm').format(task.startTime),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            Container(height: 20, width: 1, color: Colors.grey),
                            Text(DateFormat('HH:mm').format(task.endTime),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.title,
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null)),
                              if (task.tags.isNotEmpty)
                                Wrap(
                                  spacing: 4,
                                  children: task.tags
                                      .map((t) => Chip(
                                            label: Text(t,
                                                style: const TextStyle(
                                                    fontSize: 9)),
                                            padding: EdgeInsets.zero,
                                            backgroundColor: Colors.black26,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ))
                                      .toList(),
                                )
                            ],
                          ),
                        ),
                        Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white54),
                      ],
                    ),
                  ),
                ),
                if (isExpanded)
                  Column(
                    children: [
                      const Divider(color: Colors.white10, height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _actionButton(
                                icon: task.isCompleted
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: Colors.green,
                                label: l10n.complete,
                                onTap: () => _firebaseService.updateTask(task
                                    .copyWith(isCompleted: !task.isCompleted))),
                            _actionButton(
                                icon: Icons.info_outline,
                                color: Colors.blueGrey,
                                label: l10n.sectionDetails,
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            TaskDetailScreen(task: task)))),
                            _actionButton(
                                icon: Icons.edit,
                                color: Colors.blue,
                                label: l10n.edit,
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => TaskAddEditScreen(
                                            selectedDate: task.startTime,
                                            task: task)))),
                            _actionButton(
                                icon: Icons.update,
                                color: Colors.orange,
                                label: l10n.postpone,
                                onTap: () => _showPostponeMenu(context, task)),
                            _actionButton(
                                icon: Icons.delete,
                                color: Colors.red,
                                label: l10n.delete,
                                onTap: () => _confirmDelete(task)),
                          ],
                        ),
                      ),
                    ],
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton(
      {required IconData icon,
      required Color color,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10))
        ]),
      ),
    );
  }

  Widget _buildWeeklyNoteBox(AppLocalizations l10n) {
    return FadeInUp(
      child: GestureDetector(
        onTap: _editWeeklyNote,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.purple.shade600.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.1), blurRadius: 8)
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.weeklyNotesTitle,
                      style: GoogleFonts.poppins(
                          color: Colors.purple.shade300,
                          fontWeight: FontWeight.w600)),
                  const Icon(Icons.edit_note, color: Colors.white54, size: 16)
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                  child: Text(_weeklyNote!,
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 12),
                      maxLines: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayBox(DateTime day, Map<DateTime, List<Task>> eventsMap,
      Map<DateTime, List<Note>> notesMap) {
    final l10n = AppLocalizations.of(context)!;
    final dateKey = DateUtils.dateOnly(day);
    final events = eventsMap[dateKey] ?? [];
    final notes = notesMap[dateKey] ?? [];
    final isToday = DateUtils.isSameDay(day, DateTime.now());

    const int maxItems = 3;
    final int notesToShow = (maxItems - events.length).clamp(0, maxItems);
    final int totalItems = events.length + notes.length;
    final int hiddenCount = totalItems > maxItems ? totalItems - maxItems : 0;

    return Expanded(
      child: FadeInUp(
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedDay = day);
            _showDayMenu(day);
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: isToday
                      ? [const Color(0xFFE65100), const Color(0xFFEF6C00)]
                      : [const Color(0xFF212121), const Color(0xFF181818)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isToday ? Colors.orangeAccent : Colors.white10,
                  width: isToday ? 1.5 : 0.5),
              boxShadow: isToday
                  ? [
                      BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 10)
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        DateFormat('EEE', l10n.localeName)
                            .format(day)
                            .toUpperCase(),
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white54,
                            fontWeight: FontWeight.bold))),
                Text('${day.day}',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...events.take(maxItems).map((e) => _buildItemChip(
                            e.title, Color(e.color), e.isCompleted)),
                        ...notes.take(notesToShow).map((n) => _buildItemChip(
                            n.title.isEmpty ? l10n.untitledNote : n.title,
                            Colors.orange.shade700,
                            false)),
                      ],
                    ),
                  ),
                ),
                if (hiddenCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(l10n.hiddenItemsCount(hiddenCount),
                        style: GoogleFonts.poppins(
                            fontSize: 8, color: Colors.white70)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemChip(String title, Color color, bool isCompleted) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
          color: isCompleted
              ? color.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4)),
      child: Text(title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 8,
              color: isCompleted ? Colors.white38 : Colors.white,
              decoration: isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }

  void _editWeeklyNote() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
        text: _weeklyNote == l10n.writeYourNotes ? "" : _weeklyNote);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.weeklyNotesTitle,
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
              hintText: l10n.writeYourNotes,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B1FA2)),
              onPressed: () {
                setState(() => _weeklyNote = controller.text);
                Navigator.pop(context);
              },
              child:
                  Text(l10n.save, style: const TextStyle(color: Colors.white)))
        ],
      ),
    );
  }

  void _showDayMenu(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _EventListSheet(day: day, currentFilter: _currentFilter),
    );
  }

  void _showAllNotes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AllNotesSheet(),
    );
  }

  void _showNovaWizard() {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController promptController = TextEditingController();
    bool isLoading = false;
    bool isListening = false;
    stt.SpeechToText speech = stt.SpeechToText();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          const Icon(Icons.auto_fix_high, color: Colors.teal),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.novaAssistant,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.novaPrompt,
                  style:
                      GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: promptController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  maxLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.novaInputHint,
                    hintStyle: GoogleFonts.poppins(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.black38,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isListening ? Icons.mic : Icons.mic_none,
                        color:
                            isListening ? Colors.redAccent : Colors.tealAccent,
                      ),
                      onPressed: () async {
                        if (!isListening) {
                          bool available = await speech.initialize();
                          if (available) {
                            setModalState(() => isListening = true);
                            speech.listen(onResult: (result) {
                              promptController.text = result.recognizedWords;
                              if (result.finalResult) {
                                setModalState(() => isListening = false);
                              }
                            });
                          } else {
                            if (modalContext.mounted) {
                              ScaffoldMessenger.of(modalContext).showSnackBar(
                                  SnackBar(
                                      content: Text(l10n.micPermissionError)));
                            }
                          }
                        } else {
                          setModalState(() => isListening = false);
                          speech.stop();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            final text = promptController.text.trim();
                            if (text.isEmpty) return;

                            setModalState(() => isLoading = true);

                            try {
                              final novaService = NovaService();
                              final generatedTask =
                                  await novaService.createTaskFromText(text);

                              if (modalContext.mounted) {
                                Navigator.pop(modalContext);
                              }

                              if (generatedTask != null) {
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TaskAddEditScreen(
                                        selectedDate: generatedTask.startTime,
                                        task: generatedTask,
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text(l10n.novaUnderstandError)));
                                }
                              }
                            } catch (e) {
                              setModalState(() => isLoading = false);
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.white),
                              const SizedBox(width: 8),
                              Text(l10n.create,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPostponeMenu(BuildContext context, Task task) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) => Wrap(
        children: [
          _buildPostponeItem(
              ctx, task, l10n.postpone15Min, const Duration(minutes: 15)),
          _buildPostponeItem(
              ctx, task, l10n.postpone1Hour, const Duration(hours: 1)),
          _buildPostponeItem(
              ctx, task, l10n.postponeTomorrow, const Duration(days: 1)),
        ],
      ),
    );
  }

  Widget _buildPostponeItem(
      BuildContext ctx, Task task, String label, Duration duration) {
    return ListTile(
      leading: const Icon(Icons.update, color: Colors.white70),
      title: Text(label, style: GoogleFonts.poppins(color: Colors.white)),
      onTap: () async {
        final navigator = Navigator.of(ctx);
        await _firebaseService.updateTask(task.copyWith(
          startTime: task.startTime.add(duration),
          endTime: task.endTime.add(duration),
          postponeCount: task.postponeCount + 1,
        ));
        if (navigator.mounted) navigator.pop();
      },
    );
  }

  void _confirmDelete(Task task) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
        content: Text(l10n.deleteNoteWarning,
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _firebaseService.deleteTask(task.id!);
              Navigator.pop(ctx);
            },
            child: Text(l10n.delete),
          )
        ],
      ),
    );
  }
}

class _EventListSheet extends StatefulWidget {
  final DateTime day;
  final CalendarFilter currentFilter;
  const _EventListSheet({required this.day, required this.currentFilter});
  @override
  State<_EventListSheet> createState() => _EventListSheetState();
}

class _EventListSheetState extends State<_EventListSheet> {
  final FirebaseService _firebaseService = FirebaseService();
  int? _expandedTaskIndex;

  void _showPostponeMenu(BuildContext context, Task task) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) => Wrap(
        children: [
          _buildPostponeItem(
              ctx, task, l10n.postpone15Min, const Duration(minutes: 15)),
          _buildPostponeItem(
              ctx, task, l10n.postpone1Hour, const Duration(hours: 1)),
          _buildPostponeItem(
              ctx, task, l10n.postponeTomorrow, const Duration(days: 1)),
        ],
      ),
    );
  }

  Widget _buildPostponeItem(
      BuildContext ctx, Task task, String label, Duration duration) {
    return ListTile(
      leading: const Icon(Icons.update, color: Colors.white70),
      title: Text(label, style: GoogleFonts.poppins(color: Colors.white)),
      onTap: () async {
        final navigator = Navigator.of(ctx);
        await _firebaseService.updateTask(task.copyWith(
          startTime: task.startTime.add(duration),
          endTime: task.endTime.add(duration),
          postponeCount: task.postponeCount + 1,
        ));
        if (navigator.mounted) navigator.pop();
      },
    );
  }

  void _confirmDelete(Task task) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
        content: Text(l10n.deleteNoteWarning,
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _firebaseService.deleteTask(task.id!);
              Navigator.pop(ctx);
            },
            child: Text(l10n.delete),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(
            width: 60,
            height: 6,
            decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(3))),
        const SizedBox(height: 16),
        Text(DateFormat('d MMMM yyyy', l10n.localeName).format(widget.day),
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
                child: _buildQuickActionBtn(
                    icon: Icons.event,
                    label: l10n.addEvent,
                    color: const Color(0xFF7B1FA2),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  TaskAddEditScreen(selectedDate: widget.day)));
                    })),
            const SizedBox(width: 12),
            Expanded(
                child: _buildQuickActionBtn(
                    icon: Icons.note_add,
                    label: l10n.addNote,
                    color: Colors.green.shade700,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  NoteAddEditScreen(selectedDate: widget.day)));
                    })),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: Colors.white10),
        Expanded(
            child: StreamBuilder<List<Task>>(
                stream: _firebaseService.getAllUserTasksStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final tasks = snapshot.data ?? [];
                  final dailyTasks = tasks.where((t) {
                    bool isSameDay = false;
                    if (t.repeatRule == 'none') {
                      isSameDay = DateUtils.isSameDay(t.startTime, widget.day);
                    } else if (t.startTime.isAfter(widget.day)) {
                      isSameDay = false;
                    } else if (t.repeatRule == 'daily') {
                      isSameDay = true;
                    } else if (t.repeatRule == 'weekly') {
                      isSameDay = t.startTime.weekday == widget.day.weekday;
                    } else if (t.repeatRule == 'monthly') {
                      isSameDay = t.startTime.day == widget.day.day;
                    }

                    if (!isSameDay) return false;
                    if (widget.currentFilter == CalendarFilter.personal &&
                        t.groupId != null) {
                      return false;
                    }
                    if (widget.currentFilter == CalendarFilter.team &&
                        t.groupId == null) {
                      return false;
                    }
                    return true;
                  }).toList();

                  if (dailyTasks.isEmpty) {
                    return Center(
                        child: Text(l10n.noEvents,
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade500)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: dailyTasks.length,
                    itemBuilder: (context, i) {
                      final e = dailyTasks[i];
                      final isTeamTask = e.groupId != null;
                      final bool isExpanded = _expandedTaskIndex == i;

                      return FadeInUp(
                        delay: Duration(milliseconds: i * 50),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(16),
                              border: isExpanded
                                  ? Border.all(color: const Color(0xFF7B1FA2))
                                  : Border.all(color: Colors.white10)),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                onTap: () => setState(() =>
                                    _expandedTaskIndex = isExpanded ? null : i),
                                leading: Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                        color: Color(e.color),
                                        borderRadius:
                                            BorderRadius.circular(2))),
                                title: Text(e.title,
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        decoration: e.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null)),
                                subtitle: Row(
                                  children: [
                                    Text(
                                        DateFormat('HH:mm').format(e.startTime),
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                    if (isTeamTask) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: Colors.indigo.shade900,
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                          child: Text(l10n.team,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white)))
                                    ]
                                  ],
                                ),
                                trailing: Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.white54),
                              ),
                              if (isExpanded)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                  child: Column(
                                    children: [
                                      const Divider(
                                          color: Colors.white10, height: 1),
                                      const SizedBox(height: 8),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _actionButton(
                                                icon: e.isCompleted
                                                    ? Icons.check_circle
                                                    : Icons
                                                        .check_circle_outline,
                                                color: Colors.green,
                                                label: l10n.complete,
                                                onTap: () => _firebaseService
                                                    .updateTask(e.copyWith(
                                                        isCompleted:
                                                            !e.isCompleted))),
                                            _actionButton(
                                                icon: Icons.info_outline,
                                                color: Colors.blueGrey,
                                                label: l10n.sectionDetails,
                                                onTap: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            TaskDetailScreen(
                                                                task: e)))),
                                            _actionButton(
                                                icon: Icons.edit,
                                                color: Colors.blue,
                                                label: l10n.edit,
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (_) =>
                                                              TaskAddEditScreen(
                                                                  selectedDate:
                                                                      e.startTime,
                                                                  task: e)));
                                                }),
                                            _actionButton(
                                                icon: Icons.update,
                                                color: Colors.orange,
                                                label: l10n.postpone,
                                                onTap: () => _showPostponeMenu(
                                                    context, e)),
                                            _actionButton(
                                                icon: Icons.delete,
                                                color: Colors.red,
                                                label: l10n.delete,
                                                onTap: () => _confirmDelete(e)),
                                          ]),
                                    ],
                                  ),
                                )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }))
      ]),
    );
  }

  Widget _buildQuickActionBtn(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center)
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
      {required IconData icon,
      required Color color,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10))
        ]),
      ),
    );
  }
}

class _AllNotesSheet extends StatelessWidget {
  const _AllNotesSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final FirebaseService firebaseService = FirebaseService();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        const SizedBox(height: 20),
        Text(l10n.allNotes,
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
        Expanded(
            child: StreamBuilder<List<Note>>(
                stream: firebaseService.getNotesStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final notes = snapshot.data!;
                  if (notes.isEmpty) {
                    return Center(
                        child: Text(l10n.noNotesAtAll,
                            style: const TextStyle(color: Colors.grey)));
                  }
                  return ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (context, i) {
                        final note = notes[i];
                        return ListTile(
                            leading: const Icon(Icons.description,
                                color: Colors.blueGrey),
                            title: Text(
                                note.title.isEmpty
                                    ? l10n.untitledNote
                                    : note.title,
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                                DateFormat('d MMM yyyy').format(note.date),
                                style: const TextStyle(color: Colors.grey)),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => NoteAddEditScreen(
                                        selectedDate: note.date, note: note))));
                      });
                }))
      ]),
    );
  }
}
