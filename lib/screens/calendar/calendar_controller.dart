import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/task_model.dart';
import '../../models/note_model.dart';
import '../../models/appointment_model.dart';
import '../../models/medication_model.dart';
import '../../services/firebase_service.dart';

/// Stream sources for [CalendarController] (implemented by [FirebaseService]).
abstract class CalendarStreams {
  Stream<List<Task>> getTasksStreamForDateRange(DateTime start, DateTime end);
  Stream<List<Task>> getCalendarTasksStream(DateTime start, DateTime end);
  Stream<List<Appointment>> getAppointmentsStreamForDateRange(
    DateTime start,
    DateTime end,
  );
  Stream<List<Appointment>> getMyAppointmentsAsClientStreamForDateRange(
    DateTime start,
    DateTime end,
  );
  Stream<List<Note>> getNotesStream();
  Stream<List<Medication>> getMedicationsStream();
  Stream<QuerySnapshot> getHabitsStream();
}

/// Pure date-range check used when filtering notes/medications/habits.
bool isDateInCalendarRange(
  DateTime date,
  DateTime rangeStart,
  DateTime rangeEnd,
) {
  final day = DateTime(date.year, date.month, date.day);
  final start = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
  final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
  return !day.isBefore(start) && !day.isAfter(end);
}

/// Holds a snapshot of all calendar data needed to render any view.
class CalendarData {
  final List<Task> tasks;
  final List<Appointment> providerAppointments;
  final List<Appointment> clientAppointments;
  final List<Note> notes;
  final List<Medication> medications;
  final List<Map<String, dynamic>> habits;

  const CalendarData({
    this.tasks = const [],
    this.providerAppointments = const [],
    this.clientAppointments = const [],
    this.notes = const [],
    this.medications = const [],
    this.habits = const [],
  });

  CalendarData copyWith({
    List<Task>? tasks,
    List<Appointment>? providerAppointments,
    List<Appointment>? clientAppointments,
    List<Note>? notes,
    List<Medication>? medications,
    List<Map<String, dynamic>>? habits,
  }) {
    return CalendarData(
      tasks: tasks ?? this.tasks,
      providerAppointments: providerAppointments ?? this.providerAppointments,
      clientAppointments: clientAppointments ?? this.clientAppointments,
      notes: notes ?? this.notes,
      medications: medications ?? this.medications,
      habits: habits ?? this.habits,
    );
  }
}

/// Combines all calendar data sources into a single stream.
/// Replaces 4 nested StreamBuilders + 2 manual StreamSubscriptions in CalendarScreen.
class CalendarController {
  final CalendarStreams _service;
  final _controller = StreamController<CalendarData>.broadcast();

  CalendarData _current = const CalendarData();

  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd = DateTime.now();

  // Debounce: avoid emitting multiple events in rapid succession
  Timer? _debounce;

  final List<StreamSubscription> _subs = [];

  CalendarController(this._service);

  Stream<CalendarData> get stream => _controller.stream;
  CalendarData get current => _current;

  bool _inCalendarRange(DateTime date) =>
      isDateInCalendarRange(date, _rangeStart, _rangeEnd);

  bool _medicationVisibleInRange(Medication m) {
    if (!m.isActive) return false;
    final rangeStart =
        DateTime(_rangeStart.year, _rangeStart.month, _rangeStart.day);
    final rangeEnd = DateTime(_rangeEnd.year, _rangeEnd.month, _rangeEnd.day);
    final medStart =
        DateTime(m.startDate.year, m.startDate.month, m.startDate.day);
    final medEnd = m.endDate != null
        ? DateTime(m.endDate!.year, m.endDate!.month, m.endDate!.day)
        : rangeEnd;
    return !medEnd.isBefore(rangeStart) && !medStart.isAfter(rangeEnd);
  }

  void updateRange({
    required DateTime startRange,
    required DateTime endRange,
  }) {
    if (startRange == _rangeStart && endRange == _rangeEnd) return;
    start(startRange: startRange, endRange: endRange);
  }

  void start({
    required DateTime startRange,
    required DateTime endRange,
  }) {
    _rangeStart = startRange;
    _rangeEnd = endRange;
    _cancelAll();
    _current = const CalendarData();
    if (!_controller.isClosed) {
      _controller.add(_current);
    }

    final rangeStart = startRange;
    final rangeEnd = endRange;

    _subs.add(_service
        .getCalendarTasksStream(rangeStart, rangeEnd)
        .listen((tasks) {
      _update(_current.copyWith(tasks: tasks));
    }, onError: (e) {
      debugPrint('CalendarController tasks error: $e');
      _update(_current.copyWith(tasks: const []));
    },),);

    _subs.add(_service
        .getAppointmentsStreamForDateRange(startRange, endRange)
        .listen((appts) {
      _update(_current.copyWith(
        providerAppointments: appts
            .where((a) => a.groupId != null && a.groupId!.isNotEmpty)
            .toList(),
      ));
    }, onError: (e) => debugPrint('CalendarController appts error: $e'),),);

    _subs.add(_service
        .getMyAppointmentsAsClientStreamForDateRange(startRange, endRange)
        .listen((appts) {
      _update(_current.copyWith(clientAppointments: appts));
    }, onError: (e) => debugPrint('CalendarController client appts error: $e'),),);

    _subs.add(_service.getNotesStream().listen((notes) {
      final filtered =
          notes.where((n) => _inCalendarRange(n.date)).toList(growable: false);
      _update(_current.copyWith(notes: filtered));
    }, onError: (e) => debugPrint('CalendarController notes error: $e'),),);

    _subs.add(_service.getMedicationsStream().listen((meds) {
      final filtered = meds.where(_medicationVisibleInRange).toList(growable: false);
      _update(_current.copyWith(medications: filtered));
    }, onError: (e) => debugPrint('CalendarController medications error: $e'),),);

    _subs.add(_service.getHabitsStream().listen((snapshot) {
      final habits = snapshot.docs
          .map((d) {
            try {
              return {...Map<String, dynamic>.from(d.data() as Map), 'id': d.id};
            } catch (_) {
              return <String, dynamic>{'id': d.id};
            }
          })
          .toList();
      _update(_current.copyWith(habits: habits));
    }, onError: (e) => debugPrint('CalendarController habits error: $e'),),);
  }

  void _update(CalendarData updated) {
    _current = updated;
    // Debounce: batch rapid stream events into one rebuild
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 50), () {
      if (!_controller.isClosed) {
        _controller.add(_current);
      }
    });
  }

  void _cancelAll() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _debounce?.cancel();
  }

  void dispose() {
    _cancelAll();
    _controller.close();
  }
}
