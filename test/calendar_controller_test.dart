import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phobes/models/appointment_model.dart';
import 'package:phobes/models/medication_model.dart';
import 'package:phobes/models/note_model.dart';
import 'package:phobes/models/task_model.dart';
import 'package:phobes/screens/calendar/calendar_controller.dart';

class _MockCalendarStreams implements CalendarStreams {
  final _calendarTasks = StreamController<List<Task>>.broadcast();
  final _tasks = StreamController<List<Task>>.broadcast();
  final _providerAppts = StreamController<List<Appointment>>.broadcast();
  final _clientAppts = StreamController<List<Appointment>>.broadcast();
  final _notes = StreamController<List<Note>>.broadcast();
  final _meds = StreamController<List<Medication>>.broadcast();
  final _habits = StreamController<QuerySnapshot>.broadcast();

  void emitTasks(List<Task> tasks) {
    _tasks.add(tasks);
    _calendarTasks.add(tasks);
  }
  void emitNotes(List<Note> notes) => _notes.add(notes);

  @override
  Stream<List<Task>> getTasksStreamForDateRange(DateTime start, DateTime end) =>
      _tasks.stream;

  @override
  Stream<List<Task>> getCalendarTasksStream(DateTime start, DateTime end) =>
      _calendarTasks.stream;

  @override
  Stream<List<Appointment>> getAppointmentsStreamForDateRange(
    DateTime start,
    DateTime end,
  ) =>
      _providerAppts.stream;

  @override
  Stream<List<Appointment>> getMyAppointmentsAsClientStreamForDateRange(
    DateTime start,
    DateTime end,
  ) =>
      _clientAppts.stream;

  @override
  Stream<List<Note>> getNotesStream() => _notes.stream;

  @override
  Stream<List<Medication>> getMedicationsStream() => _meds.stream;

  @override
  Stream<QuerySnapshot> getHabitsStream() => _habits.stream;

  void close() {
    _calendarTasks.close();
    _tasks.close();
    _providerAppts.close();
    _clientAppts.close();
    _notes.close();
    _meds.close();
    _habits.close();
  }
}

Task _task(String id, DateTime start) => Task(
      id: id,
      userId: 'u1',
      title: 'Task $id',
      startTime: start,
      endTime: start.add(const Duration(hours: 1)),
    );

Note _note(String id, DateTime date) => Note(
      id: id,
      userId: 'u1',
      title: 'Note $id',
      content: '',
      date: date,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalendarController', () {
    late _MockCalendarStreams mock;
    late CalendarController controller;

    setUp(() {
      mock = _MockCalendarStreams();
      controller = CalendarController(mock);
    });

    tearDown(() {
      controller.dispose();
      mock.close();
    });

    test('merges task and note streams after debounce', () async {
      final start = DateTime(2026, 5);
      final end = DateTime(2026, 5, 31);

      final events = <CalendarData>[];
      final sub = controller.stream.listen(events.add);

      controller.start(startRange: start, endRange: end);

      mock.emitTasks([_task('t1', DateTime(2026, 5, 10))]);
      mock.emitNotes([
        _note('n1', DateTime(2026, 5, 12)),
        _note('n2', DateTime(2026, 6)),
      ]);

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(events, isNotEmpty);
      final latest = events.last;
      expect(latest.tasks.length, 1);
      expect(latest.notes.length, 1);
      expect(latest.notes.first.id, 'n1');

      await sub.cancel();
    });

    test('updateRange restarts subscriptions', () async {
      final events = <CalendarData>[];
      final sub = controller.stream.listen(events.add);

      controller.start(
        startRange: DateTime(2026, 5),
        endRange: DateTime(2026, 5, 31),
      );
      mock.emitTasks([_task('t1', DateTime(2026, 5, 5))]);

      controller.updateRange(
        startRange: DateTime(2026, 6),
        endRange: DateTime(2026, 6, 30),
      );
      mock.emitTasks([_task('t2', DateTime(2026, 6, 5))]);

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(controller.current.tasks.length, 1);
      expect(controller.current.tasks.first.id, 't2');

      await sub.cancel();
    });
  });
}
