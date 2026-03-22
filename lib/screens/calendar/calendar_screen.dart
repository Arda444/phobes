import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phobes/l10n/app_localizations.dart';
import '../../models/task_model.dart';
import '../../models/note_model.dart';
import '../../models/appointment_model.dart';
import '../../models/medication_model.dart';
import '../../services/firebase_service.dart';
import '../../services/nova_service.dart';
import '../../services/calendar_sync_service.dart';
import '../../core/phobes_theme.dart';
import '../../core/page_transitions.dart';
import '../tasks/task_add_edit_screen.dart';
import '../../widgets/calendar/calendar_day_card.dart';
import '../../widgets/calendar/day_timeline_sheet.dart';
import '../../widgets/phobes_widgets.dart';
import '../notifications/notifications_screen.dart';

enum CalendarViewMode { weekly, monthly, daily }

class CalendarFilters {
  bool showPersonalTasks = true;
  bool showClientAppointments = true;
  bool showProviderAppointments = true;
  bool showMedications = true;
  bool showHabits = true;
  bool showNotes = true;
  Set<String> hiddenGroupIds = {};
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

  late Stream<List<Note>> _notesStream;
  List<Task> _deviceTasks = [];

  List<Task> _cachedTasks = [];
  List<Appointment> _cachedAppointments = [];
  List<Medication> _cachedMedications = [];
  List<Map<String, dynamic>> _cachedHabits = [];
  List<Note> _cachedNotes = [];
  StreamSubscription? _medSub;
  StreamSubscription? _habitSub;

  final Map<String, String> _groupNamesCache = {};

  final CalendarFilters _filters = CalendarFilters();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _notesStream = _firebaseService.getNotesStream();
    _loadDeviceCalendar();
  }

  void _loadMedicationsAndHabits() {
    try {
      _medSub = _firebaseService.getMedicationsStream().listen(
        (meds) {
          if (mounted) setState(() => _cachedMedications = meds);
        },
        onError: (e) => debugPrint('Medication stream error: $e'),
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('Medication stream init error: $e');
    }

    try {
      _habitSub = _firebaseService.getHabitsStream().listen(
        (snapshot) {
          if (mounted) {
            setState(() {
              _cachedHabits = snapshot.docs
                  .map((d) => {
                        ...d.data() as Map<String, dynamic>,
                        'id': d.id,
                      })
                  .toList();
            });
          }
        },
        onError: (e) => debugPrint('Habit stream error: $e'),
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('Habit stream init error: $e');
    }
  }

  @override
  void dispose() {
    _medSub?.cancel();
    _habitSub?.cancel();
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
      await _firebaseService.updateTask(task);
    }
  }

  Map<DateTime, List<dynamic>> _processAllEvents(
    List<Task> tasks,
    List<Appointment> clientAppts,
    List<Appointment> providerAppts, {
    required DateTime visibleStart,
    required DateTime visibleEnd,
  }) {
    final map = <DateTime, List<dynamic>>{};

    if (_filters.showPersonalTasks) {
      for (final t in tasks) {
        if (t.groupId != null && _filters.hiddenGroupIds.contains(t.groupId)) {
          continue;
        }

        if (t.repeatRule == 'none') {
          final dateOnly = DateUtils.dateOnly(t.startTime);
          // Only add if it's within or close to the visible range
          if (dateOnly
                  .isAfter(visibleStart.subtract(const Duration(days: 1))) &&
              dateOnly.isBefore(visibleEnd.add(const Duration(days: 1)))) {
            map[dateOnly] = [...?map[dateOnly], t];
          }
        } else {
          // OPTIMIZED RECURRING PROCESSING
          // Start from the first occurrence, but skip forward to visibleStart
          DateTime nextDate = t.startTime;

          // If the task started long ago, jump to the month before the visible range
          if (nextDate.isBefore(visibleStart)) {
            if (t.repeatRule == 'daily') {
              final diff = visibleStart.difference(nextDate).inDays;
              nextDate = nextDate.add(Duration(days: diff - 1));
            } else if (t.repeatRule == 'weekly') {
              final diff = visibleStart.difference(nextDate).inDays;
              nextDate = nextDate.add(Duration(days: (diff ~/ 7) * 7));
            } else if (t.repeatRule == 'monthly') {
              // Monthly is trickier, skip by month count roughly
              int monthsDiff = (visibleStart.year - nextDate.year) * 12 +
                  (visibleStart.month - nextDate.month);
              if (monthsDiff > 1) {
                nextDate = DateTime(
                    nextDate.year,
                    nextDate.month + monthsDiff - 1,
                    nextDate.day,
                    nextDate.hour,
                    nextDate.minute);
              }
            }
          }

          int safeGuard = 0;
          while (nextDate.isBefore(visibleEnd) && safeGuard < 100) {
            safeGuard++;
            final dateOnly = DateUtils.dateOnly(nextDate);

            // Only add if it falls within the window
            if (dateOnly
                    .isAfter(visibleStart.subtract(const Duration(days: 1))) &&
                dateOnly.isBefore(visibleEnd.add(const Duration(days: 1)))) {
              final virtualTask = t.copyWith(
                startTime: DateTime(nextDate.year, nextDate.month, nextDate.day,
                    t.startTime.hour, t.startTime.minute),
                endTime: DateTime(nextDate.year, nextDate.month, nextDate.day,
                    t.endTime.hour, t.endTime.minute),
              );
              map[dateOnly] = [...?map[dateOnly], virtualTask];
            }

            if (t.repeatRule == 'daily') {
              nextDate = nextDate.add(const Duration(days: 1));
            } else if (t.repeatRule == 'weekly') {
              nextDate = nextDate.add(const Duration(days: 7));
            } else if (t.repeatRule == 'monthly') {
              nextDate = DateTime(nextDate.year, nextDate.month + 1,
                  t.startTime.day, t.startTime.hour, t.startTime.minute);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final startRange = DateTime(_focusedDay.year, _focusedDay.month - 3, 1);
    final endRange = DateTime(_focusedDay.year, _focusedDay.month + 3, 0);

    return Scaffold(
      backgroundColor: cs.surface,
      body: StreamBuilder<List<Task>>(
        stream:
            _firebaseService.getTasksStreamForDateRange(startRange, endRange),
        builder: (context, taskSnapshot) {
          return StreamBuilder<List<Appointment>>(
            stream: _firebaseService.getAppointmentsStreamForDateRange(
                startRange, endRange),
            builder: (context, providerApptSnapshot) {
              return StreamBuilder<List<Appointment>>(
                stream: _firebaseService
                    .getMyAppointmentsAsClientStreamForDateRange(
                        startRange, endRange),
                builder: (context, clientApptSnapshot) {
                  return StreamBuilder<List<Note>>(
                    stream: _notesStream,
                    builder: (context, noteSnapshot) {
                      if (taskSnapshot.hasError) {
                        return Center(
                            child: Text("Hata: ${taskSnapshot.error}"));
                      }
                      if (providerApptSnapshot.hasError) {
                        return Center(
                            child: Text(
                                "Randevu Hatası: ${providerApptSnapshot.error}"));
                      }

                      if (taskSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          _cachedTasks.isEmpty) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: cs.primary,
                          ),
                        );
                      }

                      final tasks = taskSnapshot.data ?? [];
                      final clientAppts = clientApptSnapshot.data ?? [];
                      final providerAppts = providerApptSnapshot.data ?? [];
                      final notes = noteSnapshot.data ?? [];

                      final List<Task> allTasks = [...tasks, ..._deviceTasks];
                      _cachedTasks = allTasks;
                      _cachedAppointments = [...clientAppts, ...providerAppts];
                      _cachedNotes = notes;

                      final eventsMap = _processAllEvents(
                          allTasks, clientAppts, providerAppts,
                          visibleStart:
                              _focusedDay.subtract(const Duration(days: 35)),
                          visibleEnd:
                              _focusedDay.add(const Duration(days: 35)));
                      final notesMap = _processNotesForCalendar(notes);

                      return RepaintBoundary(
                        child: Column(
                          children: [
                            _buildHeader(l10n),
                            _buildDateNavigator(l10n),
                            Expanded(
                              child:
                                  _buildBodyContent(l10n, eventsMap, notesMap),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.15),
            cs.surface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        border: Border(
          bottom: BorderSide(
            color: cs.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (_viewMode == CalendarViewMode.daily &&
                      _previousViewMode != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: PhobesIconButton(
                        icon: Icons.arrow_back_rounded,
                        backgroundColor: cs.surface.withValues(alpha: 0.5),
                        onTap: () {
                          setState(() {
                            _viewMode = _previousViewMode!;
                            _previousViewMode = null;
                          });
                        },
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              size: 14, color: cs.primary),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMMM yyyy', l10n.localeName)
                                .format(_focusedDay),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 8,
                  children: [
                    PhobesIconButton(
                      icon: _viewMode == CalendarViewMode.weekly
                          ? Icons.view_week_rounded
                          : (_viewMode == CalendarViewMode.monthly
                              ? Icons.calendar_view_month_rounded
                              : Icons.view_day_rounded),
                      backgroundColor: cs.surface.withValues(alpha: 0.5),
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
                      stream: _firebaseService.getUnreadNotificationCount(),
                      builder: (context, snap) {
                        final count = snap.data ?? 0;
                        return PhobesIconButton(
                          icon: count > 0
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          badgeCount: count,
                          backgroundColor: cs.surface.withValues(alpha: 0.5),
                          onTap: () => PhobesPageRoute.pushResponsive(
                            context,
                            const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    PhobesIconButton(
                      icon: Icons.filter_list_rounded,
                      backgroundColor: cs.surface.withValues(alpha: 0.5),
                      onTap: () =>
                          _showFilterDialog(_cachedTasks, _cachedAppointments),
                    ),
                    if (!isSameDay(_focusedDay, DateTime.now()))
                      PhobesIconButton(
                        icon: Icons.calendar_today_rounded,
                        backgroundColor: cs.primary.withValues(alpha: 0.15),
                        color: cs.primary,
                        onTap: () {
                          setState(() {
                            _focusedDay = DateTime.now();
                            _selectedDay = DateTime.now();
                            // Keep current view mode instead of forcing daily
                          });
                        },
                      ),
                    PhobesIconButton(
                      icon: Icons.search_rounded,
                      backgroundColor: cs.surface.withValues(alpha: 0.5),
                      onTap: () => _showSearchSheet(
                          _cachedTasks, _cachedAppointments, _cachedNotes),
                    ),
                    _buildAddMenu(l10n),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddMenu(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return PhobesIconButton(
      icon: Icons.add_rounded,
      backgroundColor: cs.primary,
      color: cs.onPrimary,
      enableGlow: true,
      onTap: () {
        PhobesBottomSheet.show(
          context: context,
          builder: (ctx) => PhobesBottomSheet(
            title: "Yeni Kayıt",
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAddOption(
                  ctx,
                  icon: Icons.auto_awesome_rounded,
                  title: l10n.addSmart,
                  subtitle: "Nova ile hızla oluşturun",
                  color: Colors.tealAccent,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showNovaWizard();
                  },
                ),
                _buildAddOption(
                  ctx,
                  icon: Icons.edit_calendar_rounded,
                  title: l10n.addManual,
                  subtitle: "Kendiniz planlayın",
                  onTap: () {
                    Navigator.pop(ctx);
                    PhobesPageRoute.pushResponsive(
                        context,
                        TaskAddEditScreen(
                            selectedDate: _selectedDay ?? DateTime.now()));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddOption(BuildContext ctx,
      {required IconData icon,
      required String title,
      required String subtitle,
      Color? color,
      required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return PhobesCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? cs.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color ?? cs.primary),
        ),
        title:
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }

  void _showFilterDialog(List<Task> tasks, List<Appointment> appointments) {
    final Set<String> teamIds = {};
    for (var t in tasks) {
      if (t.groupId != null) teamIds.add(t.groupId!);
    }
    for (var a in appointments) {
      if (a.groupId != null) teamIds.add(a.groupId!);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        filters: _filters,
        teamIds: teamIds,
        namesCache: _groupNamesCache,
        onUpdate: () => setState(() {}),
      ),
    );
  }

  void _showSearchSheet(
      List<Task> tasks, List<Appointment> appointments, List<Note> notes) {
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
          // Also load medications/habits if switching to daily
          if (_cachedMedications.isEmpty && _cachedHabits.isEmpty) {
            _loadMedicationsAndHabits();
          }
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
          color: cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cs.onSurface.withValues(alpha: 0.05),
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
              }),
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _getWeekDays(DateTime focused) {
    DateTime startOfWeek =
        focused.subtract(Duration(days: focused.weekday - 1));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  Widget _buildBodyContent(AppLocalizations l10n,
      Map<DateTime, List<dynamic>> events, Map<DateTime, List<Note>> notes) {
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
      Map<DateTime, List<Note>> notesMap) {
    final weekDays = _getWeekDays(_focusedDay);
    final isWide = MediaQuery.of(context).size.width > 900;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Expanded(
              child: _buildRow(weekDays.sublist(0, 3), eventsMap, notesMap)),
          Expanded(
              child: _buildRow(weekDays.sublist(3, 6), eventsMap, notesMap)),
          Expanded(
              child: _buildThirdRow(weekDays[6], l10n, eventsMap, notesMap)),
          SizedBox(height: isWide ? 0 : 87),
        ],
      ),
    );
  }

  Widget _buildRow(List<DateTime> days, Map<DateTime, List<dynamic>> eventsMap,
      Map<DateTime, List<Note>> notesMap) {
    return Row(
        children:
            days.map((day) => _buildDayBox(day, eventsMap, notesMap)).toList());
  }

  Widget _buildThirdRow(
      DateTime sunday,
      AppLocalizations l10n,
      Map<DateTime, List<dynamic>> eventsMap,
      Map<DateTime, List<Note>> notesMap) {
    return Row(children: [
      _buildDayBox(sunday, eventsMap, notesMap),
      Expanded(flex: 2, child: _buildWeeklySummaryBox(l10n, eventsMap)),
    ]);
  }

  Widget _buildWeeklySummaryBox(
      AppLocalizations l10n, Map<DateTime, List<dynamic>> eventsMap) {
    int totalTasks = 0;
    int completedTasks = 0;
    int totalAppointments = 0;

    final weekDays = _getWeekDays(_focusedDay);
    for (var day in weekDays) {
      final dateKey = DateUtils.dateOnly(day);
      if (eventsMap.containsKey(dateKey)) {
        for (var event in eventsMap[dateKey]!) {
          if (event is Task) {
            totalTasks++;
            if (event.isCompleted || event.status == 'done') {
              completedTasks++;
            }
          } else if (event is Appointment) {
            totalAppointments++;
          }
        }
      }
    }

    final cs = Theme.of(context).colorScheme;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return PhobesCard(
      margin: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
      padding: const EdgeInsets.all(12),
      gradient: LinearGradient(
        colors: [
          cs.primary.withValues(alpha: 0.2),
          cs.secondary.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
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
                  "Haftalık Özet",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Görevler",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                "$completedTasks/$totalTasks",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: cs.onSurface.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Randevular",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$totalAppointments",
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: cs.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayBox(DateTime day, Map<DateTime, List<dynamic>> eventsMap,
      Map<DateTime, List<Note>> notesMap) {
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
      Map<DateTime, List<Note>> notesMap) {
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
            headerVisible: true,
            shouldFillViewport: true,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: GoogleFonts.outfit(
                  color: cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
              leftChevronIcon:
                  Icon(Icons.chevron_left_rounded, color: cs.primary, size: 22),
              rightChevronIcon: Icon(Icons.chevron_right_rounded,
                  color: cs.primary, size: 22),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.outfit(
                  color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13),
              weekendStyle: GoogleFonts.outfit(
                  color: Colors.redAccent.withValues(alpha: 0.8), fontSize: 13),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              todayDecoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: cs.primary, width: 1.5),
              ),
              defaultTextStyle: GoogleFonts.outfit(color: cs.onSurface),
              weekendTextStyle: GoogleFonts.outfit(
                  color: Colors.redAccent.withValues(alpha: 0.8)),
            ),
            onPageChanged: (focusedDay) =>
                setState(() => _focusedDay = focusedDay),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              final dateKey = DateUtils.dateOnly(selectedDay);
              _showDayMenu(selectedDay, eventsMap[dateKey] ?? [],
                  notesMap[dateKey] ?? []);
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) => _buildMonthlyCell(
                  day, eventsMap[DateUtils.dateOnly(day)] ?? [], false, false),
              todayBuilder: (context, day, focusedDay) => _buildMonthlyCell(
                  day, eventsMap[DateUtils.dateOnly(day)] ?? [], true, false),
              selectedBuilder: (context, day, focusedDay) => _buildMonthlyCell(
                  day, eventsMap[DateUtils.dateOnly(day)] ?? [], false, true),
            ),
          ),
        ),
        const SizedBox(height: 87),
      ],
    );
  }

  Widget _buildMonthlyCell(
      DateTime day, List<dynamic> dailyEvents, bool isToday, bool isSelected) {
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
                  ? Colors.orangeAccent.withValues(alpha: 0.5)
                  : cs.outline.withValues(alpha: isDark ? 0.1 : 0.05)),
          width: isSelected || isToday ? 1 : 0.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: -2,
                )
              ]
            : null,
      ),
      child: _buildMonthlyCellContent(day, dailyEvents, isToday, isSelected),
    );
  }

  Widget _buildMonthlyCellContent(
      DateTime day, List<dynamic> dailyEvents, bool isToday, bool isSelected) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${day.day}',
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: isSelected ? Colors.white : cs.onSurface,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500)),
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
      Map<DateTime, List<Note>> notesMap) {
    final dateKey = DateUtils.dateOnly(_focusedDay);
    final events = eventsMap[dateKey] ?? [];
    final notes = notesMap[dateKey] ?? [];

    return DayTimelineSheet(
      day: _focusedDay,
      events: events,
      notes: _filters.showNotes ? notes : [],
      medications: _filters.showMedications ? _cachedMedications : [],
      habits: _filters.showHabits ? _cachedHabits : [],
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
    // Lazy load medications & habits only when daily view is opened
    if (_cachedMedications.isEmpty && _cachedHabits.isEmpty) {
      _loadMedicationsAndHabits();
    }
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
                                  PhobesPageRoute.pushResponsive(
                                    context,
                                    TaskAddEditScreen(
                                      selectedDate: generatedTask.startTime,
                                      task: generatedTask,
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
}

class _FilterSheet extends StatefulWidget {
  final CalendarFilters filters;
  final Set<String> teamIds;
  final Map<String, String> namesCache;
  final VoidCallback onUpdate;

  const _FilterSheet({
    required this.filters,
    required this.teamIds,
    required this.namesCache,
    required this.onUpdate,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  bool _isLoading = false;
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
    final missingIds = widget.teamIds
        .where((id) => !widget.namesCache.containsKey(id))
        .toList();
    if (missingIds.isEmpty) return;

    if (mounted) setState(() => _isLoading = true);
    final List<Future<void>> futures = [];
    for (var id in missingIds) {
      futures.add(_fetchName(id));
    }
    await Future.wait(futures);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchName(String id) async {
    String unknownLabel = "Bilinmeyen";
    String errorLabel = "Hata";

    if (mounted) {
      try {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          unknownLabel = l10n.unknown;
          errorLabel = l10n.error;
        }
      } catch (_) {
        // Intentionally ignored - context may not have localizations
      }
    }

    try {
      final groupDoc = await FirebaseFirestore.instance
          .collection('appointment_groups')
          .doc(id)
          .get();
      if (groupDoc.exists && groupDoc.data() != null) {
        widget.namesCache[id] = groupDoc.data()!['title'] ?? "İsimsiz Grup";
        return;
      }
      final teamDoc =
          await FirebaseFirestore.instance.collection('teams').doc(id).get();
      if (teamDoc.exists && teamDoc.data() != null) {
        widget.namesCache[id] = teamDoc.data()!['name'] ?? "İsimsiz Takım";
        return;
      }
      widget.namesCache[id] = "$unknownLabel ($id)";
    } catch (e) {
      widget.namesCache[id] = "$errorLabel ($id)";
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      height: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.filterTitle,
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  widget.filters.showPersonalTasks = true;
                  widget.filters.showClientAppointments = true;
                  widget.filters.showProviderAppointments = true;
                  widget.filters.showMedications = true;
                  widget.filters.showHabits = true;
                  widget.filters.showNotes = true;
                  widget.filters.hiddenGroupIds.clear();
                  widget.onUpdate();
                  if (mounted) setState(() {});
                },
                child: Text(l10n.reset),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildSwitchTile(
                    l10n.filterPersonal, widget.filters.showPersonalTasks, (v) {
                  widget.filters.showPersonalTasks = v;
                  widget.onUpdate();
                  if (mounted) setState(() {});
                }),
                _buildSwitchTile(
                    l10n.filterClient, widget.filters.showClientAppointments,
                    (v) {
                  widget.filters.showClientAppointments = v;
                  widget.onUpdate();
                  if (mounted) setState(() {});
                }),
                _buildSwitchTile(l10n.filterProvider,
                    widget.filters.showProviderAppointments, (v) {
                  widget.filters.showProviderAppointments = v;
                  widget.onUpdate();
                  if (mounted) setState(() {});
                }),
                const Divider(color: Colors.white10, height: 30),
                _buildSwitchTile("İlaçlar", widget.filters.showMedications,
                    (v) {
                  widget.filters.showMedications = v;
                  widget.onUpdate();
                  if (mounted) setState(() {});
                }),
                _buildSwitchTile("Alışkanlıklar", widget.filters.showHabits,
                    (v) {
                  widget.filters.showHabits = v;
                  widget.onUpdate();
                  if (mounted) setState(() {});
                }),
                _buildSwitchTile("Notlar", widget.filters.showNotes, (v) {
                  widget.filters.showNotes = v;
                  widget.onUpdate();
                  if (mounted) setState(() {});
                }),
                if (widget.teamIds.isNotEmpty) ...[
                  const Divider(color: Colors.white10, height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Ekipler ve Projeler",
                          style: GoogleFonts.poppins(
                              color: Colors.grey, fontSize: 12)),
                      if (_isLoading)
                        const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...widget.teamIds.map((gid) {
                    final displayName =
                        widget.namesCache[gid] ?? "${l10n.loading}...";

                    if (displayName.startsWith(l10n.unknown) ||
                        displayName.startsWith(l10n.error) ||
                        displayName.startsWith("Bilinmeyen") ||
                        displayName.startsWith("Hata")) {
                      return const SizedBox.shrink();
                    }

                    final isActive =
                        !widget.filters.hiddenGroupIds.contains(gid);
                    return SwitchListTile(
                      title: Text(displayName,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      value: isActive,
                      activeTrackColor: Colors.purpleAccent,
                      dense: true,
                      onChanged: (v) {
                        if (v) {
                          widget.filters.hiddenGroupIds.remove(gid);
                        } else {
                          widget.filters.hiddenGroupIds.add(gid);
                        }
                        widget.onUpdate();
                        if (mounted) setState(() {});
                      },
                    );
                  }),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      activeTrackColor: Colors.tealAccent,
      onChanged: onChanged,
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
            "Arama",
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
              hintText: 'Ara...',
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
                      'Aramak istediğiniz kelimeyi yazın.',
                      style: GoogleFonts.outfit(color: Colors.white54),
                    ),
                  )
                : results.isEmpty
                    ? Center(
                        child: Text(
                          "Sonuç bulunamadı.",
                          style: GoogleFonts.outfit(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final item = results[index];
                          String title = '';
                          String subtitle = '';
                          IconData icon = Icons.info;
                          Color color = Colors.grey;
                          DateTime? targetDate;

                          if (item is Task) {
                            title = item.title;
                            subtitle = DateFormat('dd MMM yyyy HH:mm')
                                .format(item.startTime);
                            icon = Icons.task_alt_rounded;
                            color = Color(item.color);
                            targetDate = item.startTime;
                          } else if (item is Appointment) {
                            title = item.title;
                            subtitle = DateFormat('dd MMM yyyy HH:mm')
                                .format(item.date);
                            icon = Icons.event_rounded;
                            color = Colors.purpleAccent;
                            targetDate = item.date;
                          } else if (item is Note) {
                            title = item.title;
                            subtitle =
                                DateFormat('dd MMM yyyy').format(item.date);
                            icon = Icons.note_rounded;
                            color = Colors.amber;
                            targetDate = item.date;
                          }

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 0),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, color: color),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              subtitle,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
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
