import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phobes/models/note_model.dart';
import 'package:phobes/models/task_model.dart';

void main() {
  group('Task.fromDocData', () {
    test('handles null document data', () {
      final task = Task.fromDocData('t1', null);
      expect(task.id, 't1');
      expect(task.title, '');
      expect(task.subtasks, isEmpty);
    });

    test('parses malformed subtasks safely', () {
      final task = Task.fromDocData('t2', {
        'userId': 'u1',
        'title': 'Hello',
        'startTime': Timestamp.fromDate(DateTime(2025, 6, 15)),
        'endTime': Timestamp.fromDate(DateTime(2025, 6, 16)),
        'subtasks': [
          {'id': 's1', 'title': 'Sub', 'isCompleted': true},
          'not-a-map',
        ],
      });
      expect(task.subtasks.length, 1);
      expect(task.subtasks.first.title, 'Sub');
    });

    test('reads teamId for project-scoped tasks', () {
      final task = Task.fromDocData('t3', {
        'userId': 'u1',
        'title': 'Proj',
        'startTime': Timestamp.now(),
        'endTime': Timestamp.now(),
        'groupId': 'project1',
        'teamId': 'team1',
      });
      expect(task.teamId, 'team1');
      expect(task.groupId, 'project1');
    });
  });

  group('Note.fromDocData', () {
    test('handles null document data', () {
      final note = Note.fromDocData('n1', null);
      expect(note.id, 'n1');
      expect(note.title, '');
    });
  });

  group('Task team scoping', () {
    test('teamId and groupId remain distinct for project tasks', () {
      final task = Task(
        userId: 'u1',
        title: 'P',
        startTime: DateTime(2025, 6, 15),
        endTime: DateTime(2025, 6, 16),
        groupId: 'project-abc',
        teamId: 'team-xyz',
      );
      expect(task.teamId, isNot(task.groupId));
      expect(task.teamId, 'team-xyz');
    });
  });
}
