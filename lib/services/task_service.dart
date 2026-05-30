import 'dart:async';
import 'dart:math' show min;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/task_model.dart';
import '../models/team_model.dart';
import 'base_firebase_service.dart';

class TaskService extends BaseFirebaseService {
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  /// Resolves parent team when [groupId] is a project id (or legacy team id).
  Future<String?> resolveTeamIdForScope({
    String? teamId,
    String? groupId,
  }) async {
    if (teamId != null) return teamId;
    if (groupId == null || currentUserId == null) return null;

    try {
      final directTeam = await db.collection('teams').doc(groupId).get();
      if (directTeam.exists) return groupId;

      final teamsSnap = await db
          .collection('teams')
          .where('memberIds', arrayContains: currentUserId)
          .get();
      for (final team in teamsSnap.docs) {
        final project =
            await team.reference.collection('projects').doc(groupId).get();
        if (project.exists) return team.id;
      }
    } catch (e) {
      debugPrint('[TaskService.resolveTeamIdForScope] error: $e');
    }
    return null;
  }

  Future<Task> _withResolvedTeamScope(Task task) async {
    final teamId = await resolveTeamIdForScope(
      teamId: task.teamId,
      groupId: task.groupId,
    );
    if (teamId == null || teamId == task.teamId) return task;
    return task.copyWith(teamId: teamId);
  }

  Future<String?> addTask(Task task) async {
    if (currentUserId == null) return null;
    try {
      final scoped = await _withResolvedTeamScope(task);
      final validatedAssignees = await _validatedAssignees(
        scoped.assignedTo,
        teamId: scoped.teamId,
        groupId: scoped.groupId,
      );
      final prepared =
          scoped.copyWith(assignedTo: validatedAssignees);
      final taskMap = prepared.toMap();
      taskMap['userId'] = currentUserId;
      final ref = await db.collection('tasks').add(taskMap);
      if (prepared.teamId != null) {
        await logTeamActivity(
            prepared.teamId!, 'task_created', prepared.title,);
      }
      final assignees = validatedAssignees
          .where((uid) => uid != currentUserId)
          .toList();
      if (assignees.isNotEmpty) {
        await _notifyAssignees(
          assignees: assignees,
          taskId: ref.id,
          taskTitle: prepared.title,
        );
      }
      return ref.id;
    } catch (e) {
      debugPrint('[TaskService.addTask] error: $e');
      rethrow;
    }
  }

  /// Batch-create recurring instances (each stored with [repeatRule] none).
  Future<void> addRecurringTaskInstances(List<Task> instances) async {
    if (currentUserId == null || instances.isEmpty) return;
    try {
      final batch = db.batch();
      for (final raw in instances) {
        final scoped = await _withResolvedTeamScope(raw);
        final validatedAssignees = await _validatedAssignees(
          scoped.assignedTo,
          teamId: scoped.teamId,
          groupId: scoped.groupId,
        );
        final prepared = scoped.copyWith(assignedTo: validatedAssignees);
        final taskMap = prepared.toMap();
        taskMap['userId'] = currentUserId;
        batch.set(db.collection('tasks').doc(), taskMap);
      }
      await batch.commit();
      final first = instances.first;
      if (first.teamId != null) {
        await logTeamActivity(
          first.teamId!,
          'task_created',
          '${first.title} (tekrarlayan seri)',
        );
      }
    } catch (e) {
      debugPrint('[TaskService.addRecurringTaskInstances] error: $e');
      rethrow;
    }
  }

  /// Assignee-safe completion toggle (Firestore rules).
  Future<void> setTaskCompleted(String taskId, bool isCompleted) async {
    if (currentUserId == null) return;
    final doc = await db.collection('tasks').doc(taskId).get();
    if (!doc.exists) return;
    final task = Task.fromFirestore(doc);
    final uid = currentUserId!;
    if (task.userId == uid) {
      await updateTask(task.copyWith(isCompleted: isCompleted));
      return;
    }
    if (task.assignedTo.contains(uid)) {
      await updateTaskStatus(taskId, isCompleted ? 'done' : 'todo');
    }
  }

  /// Writes an in-app notification directly to each assignee's Firestore
  /// notification subcollection. Cannot use NotificationService.sendNotification
  /// because that method writes only to the current user's collection.
  Future<void> _notifyAssignees({
    required List<String> assignees,
    required String taskId,
    required String taskTitle,
  }) async {
    final batch = db.batch();
    for (final uid in assignees) {
      final ref = db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc();
      batch.set(ref, {
        'userId': uid,
        'title': '📋 Yeni Görev Atandı',
        'body': '"$taskTitle" görevi size atandı.',
        'type': 'task',
        'targetId': taskId,
        'targetType': 'task',
        'icon': '📋',
        'color': 0xFF8B5CF6,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Stream<Task?> getTaskStream(String taskId) {
    if (currentUserId == null) return const Stream.empty();
    return db.collection('tasks').doc(taskId).snapshots().map(
          (doc) => doc.exists ? Task.fromFirestore(doc) : null,
        );
  }

  Future<List<Task>> getTasksForStats() async {
    if (currentUserId == null) return [];
    try {
      final owned = await db
          .collection('tasks')
          .where('userId', isEqualTo: currentUserId)
          .limit(1000)
          .get();
      final assigned = await db
          .collection('tasks')
          .where('assignedTo', arrayContains: currentUserId)
          .limit(1000)
          .get();
      final seenIds = <String>{};
      final tasks = <Task>[];
      for (final doc in [...owned.docs, ...assigned.docs]) {
        if (seenIds.add(doc.id)) tasks.add(Task.fromFirestore(doc));
      }
      return tasks;
    } catch (e) {
      debugPrint('getTasksForStats error: $e');
      rethrow;
    }
  }

  /// Combines owned + assigned task streams so updates to either side
  /// are reflected in real-time without a full re-fetch.
  Stream<List<Task>> getAllUserTasksStream() {
    if (currentUserId == null) return Stream.value([]);
    final controller = StreamController<List<Task>>.broadcast();
    List<Task>? owned;
    List<Task>? assigned;

    void emit() {
      if (owned == null || assigned == null) return;
      final seen = <String>{};
      final all = <Task>[];
      for (final t in [...owned!, ...assigned!]) {
        if (t.id != null && seen.add(t.id!)) all.add(t);
      }
      all.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (!controller.isClosed) controller.add(all);
    }

    final s1 = db
        .collection('tasks')
        .where('userId', isEqualTo: currentUserId)
        .limit(500)
        .snapshots()
        .listen(
      (snap) {
        owned = snap.docs.map((d) => Task.fromFirestore(d)).toList();
        emit();
      },
      onError: controller.addError,
    );

    final s2 = db
        .collection('tasks')
        .where('assignedTo', arrayContains: currentUserId)
        .limit(500)
        .snapshots()
        .listen(
      (snap) {
        assigned = snap.docs.map((d) => Task.fromFirestore(d)).toList();
        emit();
      },
      onError: controller.addError,
    );

    controller.onCancel = () {
      s1.cancel();
      s2.cancel();
    };
    return controller.stream;
  }

  // Firestore whereIn limit.
  static const _kWhereInLimit = 30;

  Stream<List<Task>> getCalendarRelevantTasksStream() {
    if (currentUserId == null) return Stream.value([]);
    return db
        .collection('teams')
        .where('memberIds', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((teamsSnap) async {
      try {
      final teams = teamsSnap.docs.map((d) => Team.fromFirestore(d)).toList();
      final adminTeams = teams
          .where(
            (t) =>
                t.ownerId == currentUserId ||
                t.adminIds.contains(currentUserId),
          )
          .toList();

      // Fetch all project subcollections in parallel (one read per team —
      // subcollections can't be batched with whereIn).
      final projectSnaps = await Future.wait(
        adminTeams.map(
          (t) => db.collection('teams').doc(t.id).collection('projects').get(),
        ),
      );

      // Collect every groupId that needs task queries (teams + projects).
      final groupIds = <String>[
        ...adminTeams.map((t) => t.id),
        for (final snap in projectSnaps)
          for (final doc in snap.docs) doc.id,
      ];

      // Build all query futures in parallel:
      //   • 1 read for owned tasks
      //   • 1 read for assigned tasks
      //   • ceil(groupIds.length / 30) reads with whereIn — instead of
      //     one read per groupId (the previous N+1 pattern).
      final queryFutures = <Future<QuerySnapshot>>[
        db
            .collection('tasks')
            .where('userId', isEqualTo: currentUserId)
            .get(),
        db
            .collection('tasks')
            .where('assignedTo', arrayContains: currentUserId)
            .get(),
        for (var i = 0; i < groupIds.length; i += _kWhereInLimit)
          db
              .collection('tasks')
              .where(
                'groupId',
                whereIn: groupIds.sublist(
                  i,
                  min(i + _kWhereInLimit, groupIds.length),
                ),
              )
              .get(),
      ];

      final snaps = await Future.wait(queryFutures);

      final seenIds = <String>{};
      final allTasks = <Task>[];
      for (final snap in snaps) {
        for (final doc in snap.docs) {
          if (seenIds.add(doc.id)) allTasks.add(Task.fromFirestore(doc));
        }
      }
      allTasks.sort((a, b) => a.startTime.compareTo(b.startTime));
      return allTasks;
      } catch (e) {
        debugPrint('[TaskService.getCalendarRelevantTasksStream] $e');
        return <Task>[];
      }
    });
  }

  /// Owned, assigned, and team/project tasks visible on the calendar.
  Stream<List<Task>> getCalendarTasksStream(DateTime start, DateTime end) {
    if (currentUserId == null) return Stream.value([]);

    final controller = StreamController<List<Task>>.broadcast();
    List<Task> rangeTasks = [];
    List<Task> teamTasks = [];

    void emitMerged() {
      final seen = <String>{};
      final merged = <Task>[];
      for (final t in [...rangeTasks, ...teamTasks]) {
        final id = t.id ?? '';
        if (id.isEmpty || seen.add(id)) merged.add(t);
      }
      merged.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (!controller.isClosed) controller.add(merged);
    }

    final subRange =
        getTasksStreamForDateRange(start, end).listen((tasks) {
      rangeTasks = tasks;
      emitMerged();
    }, onError: (e) {
      debugPrint('[TaskService.getCalendarTasksStream] range: $e');
      rangeTasks = [];
      emitMerged();
    });

    final subTeam = getCalendarRelevantTasksStream().listen((tasks) {
      teamTasks = tasks
          .where(
            (t) =>
                !t.startTime.isBefore(start) && !t.startTime.isAfter(end),
          )
          .toList();
      emitMerged();
    }, onError: (e) {
      debugPrint('[TaskService.getCalendarTasksStream] team: $e');
      teamTasks = [];
      emitMerged();
    });

    controller.onCancel = () async {
      await subRange.cancel();
      await subTeam.cancel();
    };

    return controller.stream;
  }

  /// Date-range variant: queries Firestore with bounds so only relevant tasks
  /// are downloaded. Falls back to client-side filter for assigned tasks.
  Stream<List<Task>> getTasksStreamForDateRange(DateTime start, DateTime end) {
    if (currentUserId == null) return Stream.value([]);

    final startTs =
        Timestamp.fromDate(start.subtract(const Duration(seconds: 1)));
    final endTs = Timestamp.fromDate(end.add(const Duration(seconds: 1)));

    final controller = StreamController<List<Task>>.broadcast();
    List<Task>? owned;
    List<Task>? assigned;

    void emit() {
      if (owned == null || assigned == null) return;
      final seen = <String>{};
      final all = <Task>[];
      for (final t in [...owned!, ...assigned!]) {
        if (t.id != null && seen.add(t.id!)) all.add(t);
      }
      all.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (!controller.isClosed) controller.add(all);
    }

    final s1 = db
        .collection('tasks')
        .where('userId', isEqualTo: currentUserId)
        .where('startTime', isGreaterThan: startTs)
        .where('startTime', isLessThan: endTs)
        .snapshots()
        .listen(
      (snap) {
        owned = snap.docs.map((d) => Task.fromFirestore(d)).toList();
        emit();
      },
      onError: controller.addError,
    );

    // Assigned tasks: Firestore doesn't support inequality + array-contains
    // together, so filter by date client-side after the array-contains query.
    final s2 = db
        .collection('tasks')
        .where('assignedTo', arrayContains: currentUserId)
        .snapshots()
        .listen(
      (snap) {
        assigned = snap.docs
            .map((d) => Task.fromFirestore(d))
            .where(
              (t) =>
                  t.startTime
                      .isAfter(start.subtract(const Duration(seconds: 1))) &&
                  t.startTime.isBefore(end.add(const Duration(seconds: 1))),
            )
            .toList();
        emit();
      },
      onError: controller.addError,
    );

    controller.onCancel = () {
      s1.cancel();
      s2.cancel();
    };
    return controller.stream;
  }

  Stream<List<Task>> getTasksForDateRange(DateTime start, DateTime end) =>
      getTasksStreamForDateRange(start, end);

  Future<List<String>> _validatedAssignees(
    List<String> assignees, {
    String? teamId,
    String? groupId,
  }) async {
    if (assignees.isEmpty) return assignees;
    final unique = assignees.toSet().toList();
    if (teamId == null && groupId == null) {
      return unique.where((uid) => uid == currentUserId).toList();
    }
    try {
      List<String>? members;
      if (teamId != null) {
        final teamDoc = await db.collection('teams').doc(teamId).get();
        if (teamDoc.exists) {
          members = List<String>.from(teamDoc.data()?['memberIds'] ?? []);
        }
      } else if (groupId != null) {
        final teamDoc = await db.collection('teams').doc(groupId).get();
        if (teamDoc.exists) {
          members = List<String>.from(teamDoc.data()?['memberIds'] ?? []);
        } else {
          final teamsSnap = await db
              .collection('teams')
              .where('memberIds', arrayContains: currentUserId)
              .get();
          for (final t in teamsSnap.docs) {
            final proj =
                await t.reference.collection('projects').doc(groupId).get();
            if (proj.exists) {
              members = List<String>.from(t.data()['memberIds'] ?? []);
              break;
            }
          }
        }
      }
      final memberIds = members;
      if (memberIds == null) {
        return unique.where((uid) => uid == currentUserId).toList();
      }
      return unique.where((uid) => memberIds.contains(uid)).toList();
    } catch (e) {
      debugPrint('[TaskService._validatedAssignees] error: $e');
      return unique.where((uid) => uid == currentUserId).toList();
    }
  }

  Future<void> updateTask(Task task) async {
    if (task.id == null) return;
    try {
      final existingSnap = await db.collection('tasks').doc(task.id).get();
      if (!existingSnap.exists) return;
      final existing = Task.fromFirestore(existingSnap);

      final scoped = await _withResolvedTeamScope(task);
      final validatedAssignees = await _validatedAssignees(
        scoped.assignedTo,
        teamId: scoped.teamId,
        groupId: scoped.groupId,
      );

      final completionChanged = scoped.isCompleted != existing.isCompleted;
      final resolvedStatus = completionChanged
          ? (scoped.isCompleted ? 'done' : 'todo')
          : existing.status;

      final completionTime = completionChanged
          ? (scoped.isCompleted
              ? DateTime.now()
              : null)
          : existing.completionTime;

      final updatedTask = scoped.copyWith(
        assignedTo: validatedAssignees,
        status: resolvedStatus,
        completionTime: completionTime,
      );
      await db.collection('tasks').doc(task.id).update(updatedTask.toMap());

      if (completionChanged && updatedTask.isCompleted) {
        if (updatedTask.teamId != null) {
          await logTeamActivity(
            updatedTask.teamId!,
            'task_completed',
            updatedTask.title,
          );
        }
        await _grantTaskCompletionXp(task.id!);
      }
    } catch (e) {
      debugPrint('[TaskService.updateTask] error: $e');
      rethrow;
    }
  }

  Future<void> _grantTaskCompletionXp(String taskId) async {
    await addXP(50, taskId: taskId, reason: 'task_complete');
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    if (currentUserId == null) return;
    try {
      final isDone = status == 'done';
      final doc = await db.collection('tasks').doc(taskId).get();
      if (!doc.exists) return;
      final existing = Task.fromFirestore(doc);
      final wasDone = existing.isCompleted;

      await db.collection('tasks').doc(taskId).update({
        'status': status,
        'isCompleted': isDone,
        'completionTime': isDone
            ? FieldValue.serverTimestamp()
            : null,
      });

      if (isDone && !wasDone && existing.userId == currentUserId) {
        if (existing.teamId != null) {
          await logTeamActivity(
            existing.teamId!,
            'task_completed',
            existing.title,
          );
        }
        await _grantTaskCompletionXp(taskId);
      }
    } catch (e) {
      debugPrint('[TaskService.updateTaskStatus] error: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await db.collection('tasks').doc(taskId).delete();
    } catch (e) {
      debugPrint('[TaskService.deleteTask] error: $e');
      rethrow;
    }
  }

  Stream<List<Task>> getTeamTasksStream(String teamId) {
    final controller = StreamController<List<Task>>.broadcast();
    List<Task> byTeamId = [];
    List<Task> legacy = [];

    void emit() {
      final seen = <String>{};
      final merged = <Task>[];
      for (final t in [...byTeamId, ...legacy]) {
        if (seen.add(t.id ?? '')) merged.add(t);
      }
      merged.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (!controller.isClosed) controller.add(merged);
    }

    void onStreamError(Object e, StackTrace st, String label) {
      debugPrint('[TaskService.getTeamTasksStream] $label: $e\n$st');
      if (!controller.isClosed) controller.add([]);
    }

    List<Task> parseTasks(QuerySnapshot snap) {
      final out = <Task>[];
      for (final doc in snap.docs) {
        try {
          out.add(Task.fromFirestore(doc));
        } catch (e) {
          debugPrint('[TaskService.getTeamTasksStream] parse: $e');
        }
      }
      return out;
    }

    final s1 = db
        .collection('tasks')
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .listen((snap) {
      byTeamId = parseTasks(snap);
      emit();
    }, onError: (e, st) => onStreamError(e, st, 'teamId query'));

    final s2 = db
        .collection('tasks')
        .where('groupId', isEqualTo: teamId)
        .snapshots()
        .listen((snap) {
      legacy = parseTasks(snap)
          .where((t) => t.teamId == null || t.teamId == teamId)
          .toList();
      emit();
    }, onError: (e, st) => onStreamError(e, st, 'groupId query'));

    controller.onListen = () => emit();

    controller.onCancel = () {
      s1.cancel();
      s2.cancel();
    };
    return controller.stream;
  }

  Stream<List<Task>> getProjectTasksStream(
    String teamId,
    String projectId,
  ) {
    final controller = StreamController<List<Task>>.broadcast();
    List<Task> scoped = [];
    List<Task> legacyOwn = [];

    void emit() {
      final seen = <String>{};
      final merged = <Task>[];
      for (final t in [...scoped, ...legacyOwn]) {
        if (seen.add(t.id ?? '')) merged.add(t);
      }
      merged.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (!controller.isClosed) controller.add(merged);
    }

    void onStreamError(Object e, StackTrace st, String label) {
      debugPrint('[TaskService.getProjectTasksStream] $label: $e\n$st');
    }

    List<Task> parseTasks(QuerySnapshot snap) {
      final out = <Task>[];
      for (final doc in snap.docs) {
        try {
          out.add(Task.fromFirestore(doc));
        } catch (e) {
          debugPrint('[TaskService.getProjectTasksStream] parse: $e');
        }
      }
      return out;
    }

    final s1 = db
        .collection('tasks')
        .where('teamId', isEqualTo: teamId)
        .where('groupId', isEqualTo: projectId)
        .snapshots()
        .listen((snap) {
      scoped = parseTasks(snap);
      emit();
    }, onError: (e, st) => onStreamError(e, st, 'teamId+groupId query'));

    StreamSubscription<QuerySnapshot>? s2;
    final uid = currentUserId;
    if (uid != null) {
      s2 = db
          .collection('tasks')
          .where('groupId', isEqualTo: projectId)
          .where('userId', isEqualTo: uid)
          .snapshots()
          .listen((snap) {
        legacyOwn = parseTasks(snap)
            .where((t) => t.teamId == null || t.teamId != teamId)
            .toList();
        emit();
      }, onError: (e, st) => onStreamError(e, st, 'legacy own query'));
    }

    controller.onListen = () => emit();

    controller.onCancel = () {
      s1.cancel();
      s2?.cancel();
    };
    return controller.stream;
  }
}
