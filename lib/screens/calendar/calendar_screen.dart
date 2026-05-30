import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phobes/l10n/app_localizations.dart';
import '../../models/task_model.dart';
import '../../models/note_model.dart';
import '../../models/appointment_model.dart';
import '../../models/medication_model.dart';
import '../../models/team_model.dart';
import '../../models/project_model.dart';
import '../../services/firebase_service.dart';
import '../../services/calendar_sync_service.dart';
import '../../core/phobes_theme.dart';
import '../../core/safe_date_format.dart';
import '../../core/page_transitions.dart';
import '../tasks/task_add_edit_screen.dart';
import '../../widgets/calendar/calendar_day_card.dart';
import '../../widgets/calendar/day_timeline_sheet.dart';
import '../../widgets/phobes_widgets.dart';
import '../../core/module_info_catalog.dart';
import '../../widgets/phobes_form_wrapper.dart';
import '../../widgets/phobes_module_header.dart';
import '../notifications/notifications_screen.dart';
import '../home/statistics_screen.dart';
import '../../models/statistics_models.dart';
import 'calendar_controller.dart';

enum CalendarViewMode { weekly, monthly, daily }

class CalendarFilters {
  bool showPersonalTasks = true;
  bool showClientAppointments = true;
  bool showProviderAppointments = true;
  bool showMedications = true;
  bool showHabits = true;
  bool showNotes = true;
  Set<String> hiddenGroupIds = {};

  bool showOnlyMyTasks = false;
  Set<String> selectedTeamIds = {};
  Set<String> selectedProjectIds = {};
}

class _WeeklySummaryStats {
  const _WeeklySummaryStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.providerAppts,
    required this.personalAppts,
    required this.notes,
    required this.habitDone,
    required this.habitTotal,
    required this.medTaken,
    required this.medScheduled,
    required this.busiestDay,
    required this.busiestCount,
  });

  final int totalTasks;
  final int completedTasks;
  final int providerAppts;
  final int personalAppts;
  final int notes;
  final int habitDone;
  final int habitTotal;
  final int medTaken;
  final int medScheduled;
  final DateTime? busiestDay;
  final int busiestCount;

  int get totalAppointments => providerAppts + personalAppts;

  int get totalItems =>
      totalTasks +
      totalAppointments +
      notes +
      habitTotal +
      medScheduled;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  CalendarViewMode _viewMode = CalendarViewMode.weekly;
  CalendarViewMode? _previousViewMode;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  final FirebaseService _firebaseService = FirebaseService();
  final CalendarSyncService _calendarSyncService = CalendarSyncService();
  late final CalendarController _calendarController;
  late final Stream<int> _unreadCountStream;

  List<Task> _deviceTasks = [];

  List<Task> _cachedTasks = [];
  List<Appointment> _cachedAppointments = [];
  List<Medication> _cachedMedications = [];
  List<Map<String, dynamic>> _cachedHabits = [];
  List<Note> _cachedNotes = [];

  // Memoization for _processAllEvents
  int? _lastTasksSignature;
  int? _lastClientApptsSignature;
  int? _lastProviderApptsSignature;
  DateTime? _lastVisibleStart;
  DateTime? _lastVisibleEnd;
  Map<DateTime, List<dynamic>>? _cachedEventsMap;
  int? _lastNotesSignature;
  Map<DateTime, List<Note>>? _cachedNotesMap;
  int? _lastFiltersSignature;

  final Map<String, String> _groupNamesCache = {};

  final CalendarFilters _filters = CalendarFilters();
  StreamSubscription<CalendarData>? _calendarDataSub;

  DateTime get _startRange =>
      DateTime(_focusedDay.year, _focusedDay.month - 3);
  DateTime get _endRange =>
      DateTime(_focusedDay.year, _focusedDay.month + 3, 0);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _unreadCountStream =
        _firebaseService.getUnreadNotificationCount().asBroadcastStream();
    _calendarController = CalendarController(_firebaseService);
    _calendarController.start(
      startRange: _startRange,
      endRange: _endRange,
    );
    _calendarDataSub = _calendarController.stream.listen((data) {
      if (!mounted) return;
      setState(() {
        _cachedTasks = [...data.tasks, ..._deviceTasks];
        _cachedAppointments = [
          ...data.clientAppointments,
          ...data.providerAppointments,
        ];
        _cachedMedications = data.medications;
        _cachedHabits = data.habits;
        _cachedNotes = data.notes;
      });
    });
    _loadDeviceCalendar();
  }

  void _syncCalendarRange() {
    _calendarController.updateRange(
      startRange: _startRange,
      endRange: _endRange,
    );
  }

  @override
  void dispose() {
    _calendarDataSub?.cancel();
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceCalendar() async {
    final tasks = await _calendarSyncService.fetchDeviceEvents();
    if (mounted) {
      setState(() => _deviceTasks = tasks);
    }
  }

  Future<void> _handleTaskUpdate(Task task) async {
    if (task.userId == 'device') {
      setState(() {
        final index = _deviceTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) _deviceTasks[index] = task;
      });
      await _calendarSyncService.updateDeviceEvent(task);
    } else {
      if (task.id != null) {
        await _firebaseService.setTaskCompleted(task.id!, task.isCompleted);
      }
    }
  }

  List<Map<String, dynamic>> _habitsForDay(
    DateTime day,
    List<Map<String, dynamic>> habits,
  ) {
    final dayOnly = DateUtils.dateOnly(day);
    return habits.where((hab) {
      if (hab['isActive'] == false) return false;
      final created = hab['createdAt'];
      if (created is Timestamp) {
        final c = DateUtils.dateOnly(created.toDate());
        if (dayOnly.isBefore(c)) return false;
      }
      return true;
    }).toList();
  }

  String _habitDateKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  bool _habitDoneOnDay(Map<String, dynamic> hab, DateTime day) {
    final key = _habitDateKey(day);
    final completed = hab['completedDates'];
    if (completed is List) {
      for (final entry in completed) {
        if (entry.toString() == key) return true;
      }
    }
    final last = hab['lastCompleted'];
    if (last is Timestamp) {
      return DateUtils.isSameDay(last.toDate(), day);
    }
    return false;
  }

  _WeeklySummaryStats _computeWeeklySummary(
    List<DateTime> weekDays,
    Map<DateTime, List<dynamic>> eventsMap,
    Map<DateTime, List<Note>> notesMap,
  ) {
    var totalTasks = 0;
    var completedTasks = 0;
    var providerAppts = 0;
    var personalAppts = 0;
    var notes = 0;
    var habitDone = 0;
    var habitTotal = 0;
    var medTaken = 0;
    var medScheduled = 0;
    DateTime? busiestDay;
    var busiestCount = 0;

    for (final day in weekDays) {
      final dateKey = DateUtils.dateOnly(day);
      var dayCount = 0;

      if (_filters.showNotes) {
        final dayNotes = notesMap[dateKey] ?? [];
        notes += dayNotes.length;
        dayCount += dayNotes.length;
      }

      if (_filters.showHabits) {
        for (final hab in _habitsForDay(day, _cachedHabits)) {
          habitTotal++;
          if (_habitDoneOnDay(hab, day)) habitDone++;
          dayCount++;
        }
      }

      if (_filters.showMedications) {
        final dayStr = _habitDateKey(day);
        for (final med in _cachedMedications) {
          if (!med.isActive) continue;
          final dayOnly = DateUtils.dateOnly(day);
          if (DateUtils.dateOnly(med.startDate).isAfter(dayOnly)) continue;
          if (med.endDate != null &&
              DateUtils.dateOnly(med.endDate!).isBefore(dayOnly)) {
            continue;
          }
          for (final slot in med.times) {
            medScheduled++;
            dayCount++;
            if ((med.takenHistory[dayStr] ?? []).contains(slot)) {
              medTaken++;
            }
          }
        }
      }

      final events = eventsMap[dateKey];
      if (events != null) {
        for (final event in events) {
          if (event is Task) {
            totalTasks++;
            dayCount++;
            if (event.isCompleted || event.status == 'done') {
              completedTasks++;
            }
          } else if (event is Appointment) {
            dayCount++;
            final gid = event.groupId;
            if (gid != null && gid.isNotEmpty) {
              providerAppts++;
            } else {
              personalAppts++;
            }
          }
        }
      }

      if (dayCount > busiestCount) {
        busiestCount = dayCount;
        busiestDay = day;
      }
    }

    return _WeeklySummaryStats(
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      providerAppts: providerAppts,
      personalAppts: personalAppts,
      notes: notes,
      habitDone: habitDone,
      habitTotal: habitTotal,
      medTaken: medTaken,
      medScheduled: medScheduled,
      busiestDay: busiestDay,
      busiestCount: busiestCount,
    );
  }

  int _filtersSignature() => Object.hash(
        _filters.showPersonalTasks,
        _filters.showClientAppointments,
        _filters.showProviderAppointments,
        _filters.showMedications,
        _filters.showHabits,
        _filters.showNotes,
        _filters.showOnlyMyTasks,
        Object.hashAll(_filters.selectedTeamIds),
        Object.hashAll(_filters.selectedProjectIds),
        Object.hashAll(_filters.hiddenGroupIds),
      );

  Map<DateTime, List<dynamic>> _processAllEvents(
    List<Task> tasks,
    List<Appointment> clientAppts,
    List<Appointment> providerAppts, {
    required DateTime visibleStart,
    required DateTime visibleEnd,
  }) {
    final map = <DateTime, List<dynamic>>{};

    if (_filters.showPersonalTasks) {
      final currentUserId = _firebaseService.currentUserId;
      for (final t in tasks) {

        if (_filters.showOnlyMyTasks) {
          final isMine =
              t.userId == currentUserId || t.assignedTo.contains(currentUserId);
          if (!isMine) continue;
        }

        if (_filters.selectedTeamIds.isNotEmpty) {
          final allowed = _filters.selectedTeamIds;
          final taskTeamId = t.teamId;
          final taskGroupId = t.groupId;
          final inTeam =
              (taskTeamId != null && allowed.contains(taskTeamId)) ||
                  (taskGroupId != null && allowed.contains(taskGroupId));
          if (!inTeam) continue;
        }

        if (_filters.selectedProjectIds.isNotEmpty) {
          final taskGroupId = t.groupId;
          if (taskGroupId == null ||
              !_filters.selectedProjectIds.contains(taskGroupId)) {
            continue;
          }
        }

        if (t.groupId != null && _filters.hiddenGroupIds.contains(t.groupId)) {
          continue;
        }

        if (t.repeatRule == 'none' ||
            (t.recurrenceGroupId != null && t.recurrenceGroupId!.isNotEmpty)) {
          final dateOnly = DateUtils.dateOnly(t.startTime);

          if (dateOnly
                  .isAfter(visibleStart.subtract(const Duration(days: 1))) &&
              dateOnly.isBefore(visibleEnd.add(const Duration(days: 1)))) {
            map[dateOnly] = [...?map[dateOnly], t];
          }
        } else {

          DateTime nextDate = t.startTime;

          if (nextDate.isBefore(visibleStart)) {
            if (t.repeatRule == 'daily') {
              final diff = visibleStart.difference(nextDate).inDays;
              nextDate = nextDate.add(Duration(days: diff - 1));
            } else if (t.repeatRule == 'weekly') {
              final diff = visibleStart.difference(nextDate).inDays;
              nextDate = nextDate.add(Duration(days: (diff ~/ 7) * 7));
            } else if (t.repeatRule == 'monthly') {

              final int monthsDiff = (visibleStart.year - nextDate.year) * 12 +
                  (visibleStart.month - nextDate.month);
              if (monthsDiff > 1) {
                nextDate = DateTime(
                    nextDate.year,
                    nextDate.month + monthsDiff - 1,
                    nextDate.day,
                    nextDate.hour,
                    nextDate.minute,);
              }
            }
          }

          int safeGuard = 0;
          while (nextDate.isBefore(visibleEnd) && safeGuard < 100) {
            safeGuard++;
            final dateOnly = DateUtils.dateOnly(nextDate);

            if (dateOnly
                    .isAfter(visibleStart.subtract(const Duration(days: 1))) &&
                dateOnly.isBefore(visibleEnd.add(const Duration(days: 1)))) {
              final virtualTask = t.copyWith(
                startTime: DateTime(nextDate.year, nextDate.month, nextDate.day,
                    t.startTime.hour, t.startTime.minute,),
                endTime: DateTime(nextDate.year, nextDate.month, nextDate.day,
                    t.endTime.hour, t.endTime.minute,),
              );
              map[dateOnly] = [...?map[dateOnly], virtualTask];
            }

            if (t.repeatRule == 'daily') {
              nextDate = nextDate.add(const Duration(days: 1));
            } else if (t.repeatRule == 'weekly') {
              nextDate = nextDate.add(const Duration(days: 7));
            } else if (t.repeatRule == 'monthly') {
              nextDate = DateTime(nextDate.year, nextDate.month + 1,
                  t.startTime.day, t.startTime.hour, t.startTime.minute,);
            } else {
              break;
            }
          }
        }
      }
    }

    if (_filters.showClientAppointments) {
      for (final appt in clientAppts) {
        final dateOnly = DateUtils.dateOnly(appt.date);
        if (dateOnly.isAfter(visibleStart.subtract(const Duration(days: 1))) &&
            dateOnly.isBefore(visibleEnd.add(const Duration(days: 1)))) {
          map[dateOnly] = [...?map[dateOnly], appt];
        }
      }
    }

    if (_filters.showProviderAppointments) {
      for (final appt in providerAppts) {
        if (appt.groupId != null &&
            _filters.hiddenGroupIds.contains(appt.groupId)) {
          continue;
        }
        final dateOnly = DateUtils.dateOnly(appt.date);
        if (dateOnly.isAfter(visibleStart.subtract(const Duration(days: 1))) &&
            dateOnly.isBefore(visibleEnd.add(const Duration(days: 1)))) {
          map[dateOnly] = [...?map[dateOnly], appt];
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

  int _taskSignature(List<Task> tasks) =>
      Object.hashAll(tasks.map((t) => Object.hash(t.id, t.startTime, t.endTime, t.status, t.groupId)));

  int _appointmentSignature(List<Appointment> appts) =>
      Object.hashAll(appts.map((a) => Object.hash(a.id, a.date, a.status, a.groupId, a.userId, a.clientId)));

  int _noteSignature(List<Note> notes) =>
      Object.hashAll(notes.map((n) => Object.hash(n.id, n.date, n.updatedAt, n.isPinned, n.isFavorite)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: StreamBuilder<CalendarData>(
        stream: _calendarController.stream,
        initialData: _calendarController.current,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const CalendarData();

          final allTasks = [...data.tasks, ..._deviceTasks];
          final clientAppts = data.clientAppointments;
          final providerAppts = data.providerAppointments;
          final notes = data.notes;

          final visibleStart = _focusedDay.subtract(const Duration(days: 35));
          final visibleEnd = _focusedDay.add(const Duration(days: 35));

          final tasksSignature = _taskSignature(allTasks);
          final tasksChanged = _lastTasksSignature != tasksSignature;
          final clientSignature = _appointmentSignature(clientAppts);
          final providerSignature = _appointmentSignature(providerAppts);
          final apptsChanged =
              _lastClientApptsSignature != clientSignature ||
              _lastProviderApptsSignature != providerSignature;
          final windowChanged = _lastVisibleStart != visibleStart ||
              _lastVisibleEnd != visibleEnd;
          final filtersSignature = _filtersSignature();
          final filtersChanged = _lastFiltersSignature != filtersSignature;
          if (tasksChanged ||
              apptsChanged ||
              windowChanged ||
              filtersChanged ||
              _cachedEventsMap == null) {
            _cachedEventsMap = _processAllEvents(
              allTasks, clientAppts, providerAppts,
              visibleStart: visibleStart, visibleEnd: visibleEnd,
            );
            _lastTasksSignature = tasksSignature;
            _lastClientApptsSignature = clientSignature;
            _lastProviderApptsSignature = providerSignature;
            _lastVisibleStart = visibleStart;
            _lastVisibleEnd = visibleEnd;
            _lastFiltersSignature = filtersSignature;
          }
          final eventsMap = _cachedEventsMap!;

          final notesSignature = _noteSignature(notes);
          final notesChanged = _lastNotesSignature != notesSignature;
          if (notesChanged || _cachedNotesMap == null) {
            _cachedNotesMap = _processNotesForCalendar(notes);
            _lastNotesSignature = notesSignature;
          }
          final notesMap = _cachedNotesMap!;

          return RepaintBoundary(
            child: Column(
              children: [
                _buildHeader(l10n),
                _buildDateNavigator(l10n),
                Expanded(
                    child: _buildBodyContent(l10n, eventsMap, notesMap)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return PhobesModuleHeaderBar(
      title: l10n.appTitle,
      icon: Icons.calendar_month_rounded,
      subtitle: formatDateSafe('MMMM yyyy', _focusedDay, l10n.localeName),
      info: ModuleInfoCatalog.forCalendar(l10n),
      onAdd: () {
        PhobesFormWrapper.show(
          context,
          title: l10n.calendarAddTask,
          form: TaskAddEditScreen(selectedDate: _focusedDay),
        );
      },
      extraActions: [
        if (_viewMode == CalendarViewMode.daily && _previousViewMode != null)
          PhobesModuleHeaderIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () {
              setState(() {
                _viewMode = _previousViewMode!;
                _previousViewMode = null;
              });
            },
          ),
        PhobesModuleHeaderIconButton(
          icon: _viewMode == CalendarViewMode.weekly
              ? Icons.view_week_rounded
              : (_viewMode == CalendarViewMode.monthly
                  ? Icons.calendar_view_month_rounded
                  : Icons.view_day_rounded),
          onTap: () {
            setState(() {
              if (_viewMode == CalendarViewMode.weekly) {
                _viewMode = CalendarViewMode.monthly;
              } else if (_viewMode == CalendarViewMode.monthly) {
                _viewMode = CalendarViewMode.daily;
              } else {
                _viewMode = CalendarViewMode.weekly;
              }
            });
          },
        ),
        StreamBuilder<int>(
          stream: _unreadCountStream,
          builder: (context, snap) {
            final count = snap.data ?? 0;
            return PhobesModuleHeaderIconButton(
              icon: count > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              badgeCount: count,
              onTap: () => PhobesPageRoute.pushResponsive(
                context,
                const NotificationsScreen(),
              ),
            );
          },
        ),
        PhobesModuleHeaderIconButton(
          icon: Icons.filter_list_rounded,
          onTap: () => _showFilterDialog(_cachedTasks, _cachedAppointments),
        ),
        if (!isSameDay(_focusedDay, DateTime.now()))
          PhobesModuleHeaderIconButton(
            icon: Icons.calendar_today_rounded,
            onTap: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
              _syncCalendarRange();
            },
          ),
        PhobesModuleHeaderIconButton(
          icon: Icons.search_rounded,
          onTap: () =>
              _showSearchSheet(_cachedTasks, _cachedAppointments, _cachedNotes),
        ),
      ],
    );
  }

  void _showFilterDialog(List<Task> tasks, List<Appointment> appointments) {
    final Set<String> groupIds = {};
    for (final t in tasks) {
      if (t.groupId != null) groupIds.add(t.groupId!);
    }
    for (final a in appointments) {
      if (a.groupId != null) groupIds.add(a.groupId!);
    }

    final width = MediaQuery.of(context).size.width;
    final useSidePanel = kIsWeb && width >= 900;

    if (useSidePanel) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Filter',
        barrierColor: Colors.black.withOpacity(0.45),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => const SizedBox.shrink(),
        transitionBuilder: (ctx, anim, __, ___) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return Align(
            alignment: Alignment.centerRight,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(curved),
              child: _FilterSheet(
                filters: _filters,
                groupIds: groupIds,
                namesCache: _groupNamesCache,
                service: _firebaseService,
                onUpdate: () => setState(() {}),
                isSidePanel: true,
              ),
            ),
          );
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        filters: _filters,
        groupIds: groupIds,
        namesCache: _groupNamesCache,
        service: _firebaseService,
        onUpdate: () => setState(() {}),
      ),
    );
  }

  void _showSearchSheet(
      List<Task> tasks, List<Appointment> appointments, List<Note> notes,) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => _SearchSheet(
        tasks: tasks,
        appointments: appointments,
        notes: notes,
        onSelectDate: (DateTime date) {
          setState(() {
            _focusedDay = date;
            _selectedDay = date;
            _viewMode = CalendarViewMode.daily;
          });
          _syncCalendarRange();
        },
      ),
    );
  }

  Widget _buildDateNavigator(AppLocalizations l10n) {
    if (_viewMode == CalendarViewMode.monthly) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;

    String dateText;
    if (_viewMode == CalendarViewMode.daily) {
      dateText = DateFormat('d MMMM yyyy', l10n.localeName).format(_focusedDay);
    } else {
      final weekDays = _getWeekDays(_focusedDay);
      dateText =
          "${DateFormat('d', l10n.localeName).format(weekDays.first)} - ${DateFormat('d MMMM', l10n.localeName).format(weekDays.last)}";
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cs.onSurface.withOpacity(0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              iconSize: 22,
              color: cs.primary,
              onPressed: () => setState(() {
                if (_viewMode == CalendarViewMode.daily) {
                  _focusedDay = _focusedDay.subtract(const Duration(days: 1));
                } else {
                  _focusedDay = _focusedDay.subtract(const Duration(days: 7));
                }
                _syncCalendarRange();
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                dateText,
                style: GoogleFonts.outfit(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              iconSize: 22,
              color: cs.primary,
              onPressed: () => setState(() {
                if (_viewMode == CalendarViewMode.daily) {
                  _focusedDay = _focusedDay.add(const Duration(days: 1));
                } else {
                  _focusedDay = _focusedDay.add(const Duration(days: 7));
                }
                _syncCalendarRange();
              }),
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _getWeekDays(DateTime focused) {
    final DateTime startOfWeek =
        focused.subtract(Duration(days: focused.weekday - 1));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  Widget _buildBodyContent(AppLocalizations l10n,
      Map<DateTime, List<dynamic>> events, Map<DateTime, List<Note>> notes,) {
    switch (_viewMode) {
      case CalendarViewMode.weekly:
        return _buildWeeklyView(l10n, events, notes);
      case CalendarViewMode.monthly:
        return _buildMonthlyView(l10n, events, notes);
      case CalendarViewMode.daily:
        return _buildDailyView(l10n, events, notes);
    }
  }

  Widget _buildWeeklyView(
      AppLocalizations l10n,
      Map<DateTime, List<dynamic>> eventsMap,
      Map<DateTime, List<Note>> notesMap,) {
    final weekDays = _getWeekDays(_focusedDay);
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;
    final bottomReserve = isWide ? 0.0 : 100.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, bottomReserve),
      child: Column(
        children: [
          Expanded(
              child: _buildRow(weekDays.sublist(0, 3), eventsMap, notesMap),),
          Expanded(
              child: _buildRow(weekDays.sublist(3, 6), eventsMap, notesMap),),
          Expanded(
              child:
                  _buildThirdRow(weekDays[6], l10n, eventsMap, notesMap),),
        ],
      ),
    );
  }

  Widget _buildRow(List<DateTime> days, Map<DateTime, List<dynamic>> eventsMap,
      Map<DateTime, List<Note>> notesMap,) {
    return Row(
        children:
            days.map((day) => _buildDayBox(day, eventsMap, notesMap)).toList(),);
  }

  Widget _buildThirdRow(
      DateTime sunday,
      AppLocalizations l10n,
      Map<DateTime, List<dynamic>> eventsMap,
      Map<DateTime, List<Note>> notesMap,) {
    return Row(children: [
      _buildDayBox(sunday, eventsMap, notesMap),
      Expanded(
          flex: 2,
          child: _buildWeeklySummaryBox(l10n, eventsMap, notesMap),),
    ],);
  }

  Widget _weeklySummaryStatRow({
    required String label,
    required String value,
    required ColorScheme cs,
    Color? valueColor,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: cs.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null)
            trailing
          else
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: valueColor ?? cs.onSurface,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryBox(
    AppLocalizations l10n,
    Map<DateTime, List<dynamic>> eventsMap,
    Map<DateTime, List<Note>> notesMap,
  ) {
    final weekDays = _getWeekDays(_focusedDay);
    final stats = _computeWeeklySummary(weekDays, eventsMap, notesMap);
    final cs = Theme.of(context).colorScheme;
    final locale = l10n.localeName;

    final rangeText = l10n.calendarWeeklyRange(
      DateFormat('d MMM', locale).format(weekDays.first),
      DateFormat('d MMM', locale).format(weekDays.last),
    );

    final taskProgress =
        stats.totalTasks > 0 ? stats.completedTasks / stats.totalTasks : 0.0;

    final rows = <Widget>[];

    if (_filters.showPersonalTasks) {
      rows.add(_weeklySummaryStatRow(
        label: l10n.calendarTasksLabel,
        value: '${stats.completedTasks}/${stats.totalTasks}',
        cs: cs,
        trailing: stats.totalTasks > 0
            ? SizedBox(
                width: 56,
                child: LinearProgressIndicator(
                  value: taskProgress,
                  minHeight: 4,
                  backgroundColor: cs.onSurface.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : Text(
                '${stats.completedTasks}/${stats.totalTasks}',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
      ));
    }

    if (_filters.showClientAppointments ||
        _filters.showProviderAppointments) {
      if (_filters.showClientAppointments && stats.personalAppts > 0) {
        rows.add(_weeklySummaryStatRow(
          label: l10n.filterClient,
          value: '${stats.personalAppts}',
          cs: cs,
          valueColor: cs.secondary,
        ));
      }
      if (_filters.showProviderAppointments && stats.providerAppts > 0) {
        rows.add(_weeklySummaryStatRow(
          label: l10n.filterProvider,
          value: '${stats.providerAppts}',
          cs: cs,
          valueColor: cs.secondary,
        ));
      }
      if (stats.totalAppointments > 0 &&
          !(_filters.showClientAppointments &&
              _filters.showProviderAppointments)) {
        rows.add(_weeklySummaryStatRow(
          label: l10n.calendarAppointmentsLabel,
          value: '${stats.totalAppointments}',
          cs: cs,
          valueColor: cs.secondary,
        ));
      } else if (stats.totalAppointments > 0 &&
          _filters.showClientAppointments &&
          _filters.showProviderAppointments &&
          stats.personalAppts == 0 &&
          stats.providerAppts == 0) {
        rows.add(_weeklySummaryStatRow(
          label: l10n.calendarAppointmentsLabel,
          value: '0',
          cs: cs,
        ));
      }
    }

    if (_filters.showMedications && stats.medScheduled > 0) {
      rows.add(_weeklySummaryStatRow(
        label: l10n.calendarTypeMedication,
        value: l10n.calendarMedsDoses(stats.medTaken, stats.medScheduled),
        cs: cs,
        valueColor: Colors.tealAccent.shade200,
      ));
    }

    if (_filters.showHabits && stats.habitTotal > 0) {
      rows.add(_weeklySummaryStatRow(
        label: l10n.calendarTypeHabit,
        value: l10n.calendarHabitsWeek(stats.habitDone, stats.habitTotal),
        cs: cs,
        valueColor: Colors.lightGreenAccent.shade200,
      ));
    }

    if (_filters.showNotes && stats.notes > 0) {
      rows.add(_weeklySummaryStatRow(
        label: l10n.calendarTypeNote,
        value: '${stats.notes}',
        cs: cs,
        valueColor: Colors.amber.shade200,
      ));
    }

    String? busiestLabel;
    if (stats.busiestDay != null && stats.busiestCount > 0) {
      busiestLabel = l10n.calendarBusiestDay(
        DateFormat('EEEE', locale).format(stats.busiestDay!),
      );
    }

    return PhobesCard(
      margin: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
      padding: const EdgeInsets.all(10),
      gradient: LinearGradient(
        colors: [
          cs.primary.withOpacity(0.2),
          cs.secondary.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: () => PhobesPageRoute.pushResponsive(
        context,
        const StatisticsScreen(initialPeriod: StatsPeriod.week),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: cs.primary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.calendarWeeklySummary,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: cs.onSurface.withOpacity(0.4),),
            ],
          ),
          Text(
            rangeText,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 6),
          if (rows.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  l10n.calendarWeekTotalItems(0),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rows,
                ),
              ),
            ),
          if (busiestLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              busiestLabel,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: cs.primary.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          Text(
            l10n.calendarWeekTotalItems(stats.totalItems),
            style: GoogleFonts.outfit(
              fontSize: 9,
              color: cs.onSurface.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBox(DateTime day, Map<DateTime, List<dynamic>> eventsMap,
      Map<DateTime, List<Note>> notesMap,) {
    final dateKey = DateUtils.dateOnly(day);
    final events = eventsMap[dateKey] ?? [];
    final notes = notesMap[dateKey] ?? [];
    final isSelected = isSameDay(_selectedDay, day);

    return CalendarDayCard(
      day: day,
      events: events,
      notes: notes,
      isSelected: isSelected,
      onTap: () {
        setState(() => _selectedDay = day);
        _showDayMenu(day, events, notes);
      },
    );
  }

  Widget _buildMonthlyView(
      AppLocalizations l10n,
      Map<DateTime, List<dynamic>> eventsMap,
      Map<DateTime, List<Note>> notesMap,) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: TableCalendar(
            locale: l10n.localeName,
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            shouldFillViewport: true,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: GoogleFonts.outfit(
                  color: cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,),
              leftChevronIcon:
                  Icon(Icons.chevron_left_rounded, color: cs.primary, size: 22),
              rightChevronIcon: Icon(Icons.chevron_right_rounded,
                  color: cs.primary, size: 22,),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.outfit(
                  color: cs.onSurface.withOpacity(0.6), fontSize: 13,),
              weekendStyle: GoogleFonts.outfit(
                  color: Colors.redAccent.withOpacity(0.8), fontSize: 13,),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              todayDecoration: BoxDecoration(
                color: cs.primary.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: cs.primary, width: 1.5),
              ),
              defaultTextStyle: GoogleFonts.outfit(color: cs.onSurface),
              weekendTextStyle: GoogleFonts.outfit(
                  color: Colors.redAccent.withOpacity(0.8),),
            ),
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
              _syncCalendarRange();
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              final dateKey = DateUtils.dateOnly(selectedDay);
              _showDayMenu(selectedDay, eventsMap[dateKey] ?? [],
                  notesMap[dateKey] ?? [],);
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) => _buildMonthlyCell(
                  day, eventsMap[DateUtils.dateOnly(day)] ?? [], false, false,),
              todayBuilder: (context, day, focusedDay) => _buildMonthlyCell(
                  day, eventsMap[DateUtils.dateOnly(day)] ?? [], true, false,),
              selectedBuilder: (context, day, focusedDay) => _buildMonthlyCell(
                  day, eventsMap[DateUtils.dateOnly(day)] ?? [], false, true,),
            ),
          ),
        ),
        const SizedBox(height: 87),
      ],
    );
  }

  Widget _buildMonthlyCell(
      DateTime day, List<dynamic> dailyEvents, bool isToday, bool isSelected,) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: isSelected
            ? PhobesTheme.primaryGradient
            : (isToday
                ? PhobesTheme.todayGradient
                : PhobesTheme.cardGradient(isDark)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? cs.primary
              : (isToday
                  ? Colors.orangeAccent.withOpacity(0.5)
                  : cs.outline.withOpacity(isDark ? 0.1 : 0.05)),
          width: isSelected || isToday ? 1 : 0.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: cs.primary.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: _buildMonthlyCellContent(day, dailyEvents, isToday, isSelected),
    );
  }

  Widget _buildMonthlyCellContent(
      DateTime day, List<dynamic> dailyEvents, bool isToday, bool isSelected,) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${day.day}',
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: isSelected ? Colors.white : cs.onSurface,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,),),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dailyEvents.length,
              itemBuilder: (context, index) {
                final e = dailyEvents[index];
                Color c = Colors.grey;
                if (e is Task) {
                  c = Color(e.color);
                } else if (e is Appointment) {
                  c = e.clientId != null ? Colors.teal : Colors.purple;
                }

                return Center(
                  child: Container(
                    width: 24,
                    margin: const EdgeInsets.only(bottom: 3),
                    height: 4,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyView(
      AppLocalizations l10n,
      Map<DateTime, List<dynamic>> eventsMap,
      Map<DateTime, List<Note>> notesMap,) {
    final dateKey = DateUtils.dateOnly(_focusedDay);
    final events = eventsMap[dateKey] ?? [];
    final notes = notesMap[dateKey] ?? [];

    return DayTimelineSheet(
      day: _focusedDay,
      events: events,
      notes: _filters.showNotes ? notes : [],
      medications: _filters.showMedications ? _cachedMedications : [],
      habits: _filters.showHabits
          ? _habitsForDay(_focusedDay, _cachedHabits)
          : [],
      isEmbedded: true,
      onTaskUpdate: _handleTaskUpdate,
      onTaskDelete: (t) async {
        if (t.userId == 'device') {
          await _calendarSyncService.deleteDeviceEvent(t.groupId!, t.id!);
        } else {
          await _firebaseService.deleteTask(t.id!);
        }
      },
    );
  }

  void _showDayMenu(DateTime day, List<dynamic> events, List<Note> notes) {
    setState(() {
      _previousViewMode = _viewMode;
      _focusedDay = day;
      _selectedDay = day;
      _viewMode = CalendarViewMode.daily;
    });

  }
}

class _MultiSelectOption {
  final String id;
  final String label;
  const _MultiSelectOption({required this.id, required this.label});
}

class _FilterSheet extends StatefulWidget {
  final CalendarFilters filters;
  final Set<String> groupIds;
  final Map<String, String> namesCache;
  final FirebaseService service;
  final VoidCallback onUpdate;
  final bool isSidePanel;

  const _FilterSheet({
    required this.filters,
    required this.groupIds,
    required this.namesCache,
    required this.service,
    required this.onUpdate,
    this.isSidePanel = false,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _loadNames();
      _isInit = false;
    }
  }

  Future<void> _loadNames() async {
    final missingIds = widget.groupIds
        .where((id) => !widget.namesCache.containsKey(id))
        .toList();
    if (missingIds.isEmpty) return;

    if (mounted) setState(() {});
    final List<Future<void>> futures = [];
    for (final id in missingIds) {
      futures.add(_fetchName(id));
    }
    await Future.wait(futures);
    if (mounted) setState(() {});
  }

  Future<void> _fetchName(String id) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final unnamedGroup = l10n.unnamedGroup;
    final unnamedTeam = l10n.unnamedTeam;
    try {

      final groupDoc = await FirebaseFirestore.instance
          .collection('appointment_groups')
          .doc(id)
          .get();
      final groupData = groupDoc.data();
      if (groupDoc.exists && groupData != null) {
        widget.namesCache[id] = groupData['title'] ?? unnamedGroup;
        return;
      }

      final teamDoc =
          await FirebaseFirestore.instance.collection('teams').doc(id).get();
      final teamData = teamDoc.data();
      if (teamDoc.exists && teamData != null) {
        widget.namesCache[id] = teamData['name'] ?? unnamedTeam;
        return;
      }

    } catch (e) {
      debugPrint('_fetchName($id) failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.isSidePanel) {
      return _buildSidePanel(l10n);
    }

    return PhobesBottomSheet(
      title: l10n.filterTitle,
      child: Column(
        children: [
          _buildFilterSection(
            title: l10n.calendarFilterSectionGeneral,
            children: [
              _buildSwitchTile(
                icon: Icons.person_rounded,
                title: l10n.filterPersonal,
                value: widget.filters.showPersonalTasks,
                onChanged: (v) =>
                    _update(() => widget.filters.showPersonalTasks = v),
              ),
              _buildSwitchTile(
                icon: Icons.assignment_ind_rounded,
                title: l10n.calendarFilterOnlyMyTasks,
                subtitle: l10n.calendarFilterOnlyMyTasksDesc,
                value: widget.filters.showOnlyMyTasks,
                onChanged: (v) =>
                    _update(() => widget.filters.showOnlyMyTasks = v),
              ),
            ],
          ),
          _buildFilterSection(
            title: l10n.calendarFilterSectionTeams,
            children: [
              StreamBuilder<List<Team>>(
                stream: widget.service.getUserTeamsStream(),
                builder: (context, teamSnap) {
                  final teams = teamSnap.data ?? [];
                  return Column(
                    children: [
                      _buildMultiSelectFilter(
                        icon: Icons.group_rounded,
                        title: l10n.calendarFilterTeam,
                        emptyLabel: l10n.calendarFilterAllTeams,
                        options: teams
                            .map((t) => _MultiSelectOption(id: t.id, label: t.name))
                            .toList(),
                        selectedIds: widget.filters.selectedTeamIds,
                        onToggle: (id) => _update(() {
                          if (widget.filters.selectedTeamIds.contains(id)) {
                            widget.filters.selectedTeamIds.remove(id);
                          } else {
                            widget.filters.selectedTeamIds.add(id);
                          }
                          widget.filters.selectedProjectIds.clear();
                        }),
                        onClear: () => _update(() {
                          widget.filters.selectedTeamIds.clear();
                          widget.filters.selectedProjectIds.clear();
                        }),
                      ),
                      FutureBuilder<List<Project>>(
                        future: _fetchProjectsForFilter(teams),
                        builder: (context, projectSnap) {
                          final projects = projectSnap.data ?? [];
                          if (projects.isEmpty) return const SizedBox.shrink();

                          return _buildMultiSelectFilter(
                            icon: Icons.account_tree_rounded,
                            title: l10n.calendarFilterProject,
                            emptyLabel: l10n.calendarFilterAllProjects,
                            options: projects
                                .map((p) => _MultiSelectOption(
                                    id: p.id, label: p.name,),)
                                .toList(),
                            selectedIds: widget.filters.selectedProjectIds,
                            onToggle: (id) => _update(() {
                              if (widget.filters.selectedProjectIds
                                  .contains(id)) {
                                widget.filters.selectedProjectIds.remove(id);
                              } else {
                                widget.filters.selectedProjectIds.add(id);
                              }
                            }),
                            onClear: () => _update(
                              () =>
                                  widget.filters.selectedProjectIds.clear(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          _buildFilterSection(
            title: l10n.calendarFilterSectionAppointments,
            children: [
              _buildSwitchTile(
                icon: Icons.event_available_rounded,
                title: l10n.filterClient,
                value: widget.filters.showClientAppointments,
                onChanged: (v) =>
                    _update(() => widget.filters.showClientAppointments = v),
              ),
              _buildSwitchTile(
                icon: Icons.business_center_rounded,
                title: l10n.filterProvider,
                value: widget.filters.showProviderAppointments,
                onChanged: (v) =>
                    _update(() => widget.filters.showProviderAppointments = v),
              ),
            ],
          ),
          _buildFilterSection(
            title: l10n.calendarFilterSectionOther,
            children: [
              _buildSwitchTile(
                icon: Icons.medication_rounded,
                title: l10n.calendarFilterMedications,
                value: widget.filters.showMedications,
                onChanged: (v) =>
                    _update(() => widget.filters.showMedications = v),
              ),
              _buildSwitchTile(
                icon: Icons.repeat_rounded,
                title: l10n.calendarFilterHabits,
                value: widget.filters.showHabits,
                onChanged: (v) => _update(() => widget.filters.showHabits = v),
              ),
              _buildSwitchTile(
                icon: Icons.note_rounded,
                title: l10n.calendarFilterNotes,
                value: widget.filters.showNotes,
                onChanged: (v) => _update(() => widget.filters.showNotes = v),
              ),
            ],
          ),
          const SizedBox(height: 32),
          PhobesButton(
            text: l10n.reset,
            width: double.infinity,
            onPressed: () => _update(() {
              widget.filters.showPersonalTasks = true;
              widget.filters.showClientAppointments = true;
              widget.filters.showProviderAppointments = true;
              widget.filters.showMedications = true;
              widget.filters.showHabits = true;
              widget.filters.showNotes = true;
              widget.filters.showOnlyMyTasks = false;
              widget.filters.selectedTeamIds.clear();
              widget.filters.selectedProjectIds.clear();
              widget.filters.hiddenGroupIds.clear();
            }),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<List<Project>> _fetchProjectsForFilter(List<Team> teams) async {
    final selected = widget.filters.selectedTeamIds;
    final scopedTeams = selected.isEmpty
        ? teams
        : teams.where((t) => selected.contains(t.id)).toList();
    final List<Project> allProjects = [];
    for (final team in scopedTeams) {
      final projects = await widget.service.getProjectsStream(team.id).first;
      allProjects.addAll(projects);
    }
    return allProjects;
  }

  Widget _buildSidePanel(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final width = mq.size.width.clamp(0.0, 420.0);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Container(
          width: width,
          height: double.infinity,
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              left: BorderSide(
                color: cs.outline.withOpacity(isDark ? 0.12 : 0.08),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                blurRadius: 24,
                offset: const Offset(-4, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.filter_list_rounded,
                        size: 18,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.filterTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: cs.outline.withOpacity(0.08),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  physics: const BouncingScrollPhysics(),
                  child: _buildFilterContent(l10n),
                ),
              ),
              Container(
                height: 1,
                color: cs.outline.withOpacity(0.08),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: PhobesButton(
                  text: l10n.reset,
                  width: double.infinity,
                  isOutlined: true,
                  onPressed: () => _update(() {
                    widget.filters.showPersonalTasks = true;
                    widget.filters.showClientAppointments = true;
                    widget.filters.showProviderAppointments = true;
                    widget.filters.showMedications = true;
                    widget.filters.showHabits = true;
                    widget.filters.showNotes = true;
                    widget.filters.showOnlyMyTasks = false;
                    widget.filters.selectedTeamIds.clear();
                    widget.filters.selectedProjectIds.clear();
                    widget.filters.hiddenGroupIds.clear();
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterContent(AppLocalizations l10n) {
    return Column(
      children: [
        _buildFilterSection(
          title: l10n.calendarFilterSectionGeneral,
          children: [
            _buildSwitchTile(
              icon: Icons.person_rounded,
              title: l10n.filterPersonal,
              value: widget.filters.showPersonalTasks,
              onChanged: (v) =>
                  _update(() => widget.filters.showPersonalTasks = v),
            ),
            _buildSwitchTile(
              icon: Icons.assignment_ind_rounded,
              title: l10n.calendarFilterOnlyMyTasks,
              subtitle: l10n.calendarFilterOnlyMyTasksDesc,
              value: widget.filters.showOnlyMyTasks,
              onChanged: (v) =>
                  _update(() => widget.filters.showOnlyMyTasks = v),
            ),
          ],
        ),
        _buildFilterSection(
          title: l10n.calendarFilterSectionTeams,
          children: [
            StreamBuilder<List<Team>>(
              stream: widget.service.getUserTeamsStream(),
              builder: (context, teamSnap) {
                final teams = teamSnap.data ?? [];
                return Column(
                  children: [
                    _buildMultiSelectFilter(
                      icon: Icons.group_rounded,
                      title: l10n.calendarFilterTeam,
                      emptyLabel: l10n.calendarFilterAllTeams,
                      options: teams
                          .map((t) =>
                              _MultiSelectOption(id: t.id, label: t.name))
                          .toList(),
                      selectedIds: widget.filters.selectedTeamIds,
                      onToggle: (id) => _update(() {
                        if (widget.filters.selectedTeamIds.contains(id)) {
                          widget.filters.selectedTeamIds.remove(id);
                        } else {
                          widget.filters.selectedTeamIds.add(id);
                        }
                        widget.filters.selectedProjectIds.clear();
                      }),
                      onClear: () => _update(() {
                        widget.filters.selectedTeamIds.clear();
                        widget.filters.selectedProjectIds.clear();
                      }),
                    ),
                    FutureBuilder<List<Project>>(
                      future: _fetchProjectsForFilter(teams),
                      builder: (context, projectSnap) {
                        final projects = projectSnap.data ?? [];
                        if (projects.isEmpty) return const SizedBox.shrink();

                        return _buildMultiSelectFilter(
                          icon: Icons.account_tree_rounded,
                          title: l10n.calendarFilterProject,
                          emptyLabel: l10n.calendarFilterAllProjects,
                          options: projects
                              .map((p) => _MultiSelectOption(
                                    id: p.id,
                                    label: p.name,
                                  ))
                              .toList(),
                          selectedIds: widget.filters.selectedProjectIds,
                          onToggle: (id) => _update(() {
                            if (widget.filters.selectedProjectIds
                                .contains(id)) {
                              widget.filters.selectedProjectIds.remove(id);
                            } else {
                              widget.filters.selectedProjectIds.add(id);
                            }
                          }),
                          onClear: () => _update(
                            () => widget.filters.selectedProjectIds.clear(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        _buildFilterSection(
          title: l10n.calendarFilterSectionAppointments,
          children: [
            _buildSwitchTile(
              icon: Icons.event_available_rounded,
              title: l10n.filterClient,
              value: widget.filters.showClientAppointments,
              onChanged: (v) =>
                  _update(() => widget.filters.showClientAppointments = v),
            ),
            _buildSwitchTile(
              icon: Icons.business_center_rounded,
              title: l10n.filterProvider,
              value: widget.filters.showProviderAppointments,
              onChanged: (v) =>
                  _update(() => widget.filters.showProviderAppointments = v),
            ),
          ],
        ),
        _buildFilterSection(
          title: l10n.calendarFilterSectionOther,
          children: [
            _buildSwitchTile(
              icon: Icons.medication_rounded,
              title: l10n.calendarFilterMedications,
              value: widget.filters.showMedications,
              onChanged: (v) =>
                  _update(() => widget.filters.showMedications = v),
            ),
            _buildSwitchTile(
              icon: Icons.repeat_rounded,
              title: l10n.calendarFilterHabits,
              value: widget.filters.showHabits,
              onChanged: (v) => _update(() => widget.filters.showHabits = v),
            ),
            _buildSwitchTile(
              icon: Icons.note_rounded,
              title: l10n.calendarFilterNotes,
              value: widget.filters.showNotes,
              onChanged: (v) => _update(() => widget.filters.showNotes = v),
            ),
          ],
        ),
      ],
    );
  }

  void _update(VoidCallback action) {
    setState(action);
    widget.onUpdate();
  }

  Widget _buildFilterSection(
      {required String title, required List<Widget> children,}) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 20, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cs.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return PhobesCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        secondary: Icon(icon, color: cs.primary, size: 20),
        title: Text(title,
            style:
                GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),),
        subtitle: subtitle != null
            ? Text(subtitle, style: GoogleFonts.outfit(fontSize: 11))
            : null,
        value: value,
        activeThumbColor: cs.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMultiSelectFilter({
    required IconData icon,
    required String title,
    required String emptyLabel,
    required List<_MultiSelectOption> options,
    required Set<String> selectedIds,
    required ValueChanged<String> onToggle,
    required VoidCallback onClear,
  }) {
    final cs = Theme.of(context).colorScheme;
    final selectedCount = selectedIds.length;

    return PhobesCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: Icon(icon, color: cs.primary, size: 20),
          title: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
          subtitle: Text(
            selectedCount == 0
                ? emptyLabel
                : options
                    .where((o) => selectedIds.contains(o.id))
                    .map((o) => o.label)
                    .join(', '),
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: selectedCount == 0
                  ? cs.onSurface.withOpacity(0.5)
                  : cs.primary,
              fontWeight:
                  selectedCount == 0 ? FontWeight.normal : FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: selectedCount > 0
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2,),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$selectedCount',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.expand_more_rounded,
                        color: cs.onSurface.withOpacity(0.4),),
                  ],
                )
              : Icon(Icons.expand_more_rounded,
                  color: cs.onSurface.withOpacity(0.4),),
          children: [
            if (options.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  emptyLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              )
            else ...[
              if (selectedCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                      label: Text(
                        AppLocalizations.of(context)!.reset,
                        style: GoogleFonts.outfit(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onSurface.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4,),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((opt) {
                  final selected = selectedIds.contains(opt.id);
                  return FilterChip(
                    selected: selected,
                    label: Text(
                      opt.label,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? cs.primary : cs.onSurface,
                      ),
                    ),
                    onSelected: (_) => onToggle(opt.id),
                    backgroundColor: cs.onSurface.withOpacity(0.04),
                    selectedColor: cs.primary.withOpacity(0.18),
                    checkmarkColor: cs.primary,
                    side: BorderSide(
                      color: selected
                          ? cs.primary.withOpacity(0.4)
                          : cs.onSurface.withOpacity(0.08),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

}

class _SearchSheet extends StatefulWidget {
  final List<Task> tasks;
  final List<Appointment> appointments;
  final List<Note> notes;
  final Function(DateTime) onSelectDate;

  const _SearchSheet({
    required this.tasks,
    required this.appointments,
    required this.notes,
    required this.onSelectDate,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String _query = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    List<dynamic> results = [];
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();

      final filteredTasks =
          widget.tasks.where((t) => t.title.toLowerCase().contains(q)).toList();
      final filteredAppts = widget.appointments
          .where((a) => a.title.toLowerCase().contains(q))
          .toList();
      final filteredNotes =
          widget.notes.where((n) => n.title.toLowerCase().contains(q)).toList();

      results = [...filteredTasks, ...filteredAppts, ...filteredNotes];
    }

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.calendarSearchTitle,
            style: GoogleFonts.poppins(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: l10n.calendarSearchHint,
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (val) {
              setState(() {
                _query = val;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _query.trim().isEmpty
                ? Center(
                    child: Text(
                      l10n.calendarSearchPrompt,
                      style: GoogleFonts.outfit(color: Colors.white54),
                    ),
                  )
                : results.isEmpty
                    ? Center(
                        child: Text(
                          l10n.calendarSearchNoResults,
                          style: GoogleFonts.outfit(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final item = results[index];
                          final locale = AppLocalizations.of(context)?.localeName ?? 'tr';
                          String title = '';
                          String subtitle = '';
                          IconData icon = Icons.info;
                          Color color = Colors.grey;
                          DateTime? targetDate;

                          if (item is Task) {
                            title = item.title;
                            subtitle = DateFormat('dd MMM yyyy HH:mm', locale)
                                .format(item.startTime);
                            icon = Icons.task_alt_rounded;
                            color = Color(item.color);
                            targetDate = item.startTime;
                          } else if (item is Appointment) {
                            title = item.title;
                            subtitle = DateFormat('dd MMM yyyy HH:mm', locale)
                                .format(item.date);
                            icon = Icons.event_rounded;
                            color = Colors.purpleAccent;
                            targetDate = item.date;
                          } else if (item is Note) {
                            title = item.title;
                            subtitle =
                                DateFormat('dd MMM yyyy', locale).format(item.date);
                            icon = Icons.note_rounded;
                            color = Colors.amber;
                            targetDate = item.date;
                          }

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, color: color),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,),
                            ),
                            subtitle: Text(
                              subtitle,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12,),
                            ),
                            onTap: () {
                              if (targetDate != null) {
                                widget.onSelectDate(targetDate);
                              }
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
