import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/task_model.dart';
import '../models/note_model.dart';
import '../models/team_model.dart';
import '../models/activity_log_model.dart';
import '../models/appointment_model.dart';
import '../models/appointment_group_model.dart';
import '../models/project_model.dart';
import '../models/medication_model.dart';
import '../models/app_notification_model.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';
import '../services/notification_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String? get currentUserId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String surname,
    required DateTime birthDate,
  }) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (cred.user != null) {
      await _saveUserToFirestore(cred.user!, name, surname, birthDate);
      await cred.user!.updateDisplayName("$name $surname");
    }
    return cred;
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential cred = await _auth.signInWithCredential(credential);

    if (cred.user != null) {
      final userDoc = await _db.collection('users').doc(cred.user!.uid).get();
      if (!userDoc.exists) {
        List<String> names = (cred.user!.displayName ?? "Misafir").split(" ");
        String name = names.first;
        String surname = names.length > 1 ? names.sublist(1).join(" ") : "";
        await _saveUserToFirestore(cred.user!, name, surname, DateTime.now());
      }
    }
    return cred;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> _saveUserToFirestore(
      User user, String name, String surname, DateTime birthDate) async {
    await _db.collection('users').doc(user.uid).set({
      'email': user.email,
      'name': name,
      'surname': surname,
      'birthDate': Timestamp.fromDate(birthDate),
      'createdAt': FieldValue.serverTimestamp(),
      'joinedTeams': [],
      'xp': 0,
      'level': 1,
      'photoUrl': null,
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot> getUserDataStream() {
    if (currentUserId == null) return const Stream.empty();
    return _db.collection('users').doc(currentUserId).snapshots();
  }

  Future<void> updateUserName(String name, String surname) async {
    if (currentUserId == null) return;
    await _db.collection('users').doc(currentUserId).update({
      'name': name,
      'surname': surname,
    });
    await currentUser?.updateDisplayName("$name $surname");
  }

  Future<void> updateAvatar(String avatarSeed) async {
    if (currentUserId == null) return;
    final String avatarUrl =
        "https://api.dicebear.com/9.x/micah/png?seed=$avatarSeed";

    await _db.collection('users').doc(currentUserId).update({
      'photoUrl': avatarUrl,
    });

    try {
      await currentUser?.updatePhotoURL(avatarUrl);
    } catch (e) {
      debugPrint("Auth foto güncelleme uyarısı: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    List<Map<String, dynamic>> users = [];
    for (var i = 0; i < userIds.length; i += 10) {
      var end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
      var sublist = userIds.sublist(i, end);
      var snapshot = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: sublist)
          .get();
      for (var doc in snapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id;
        users.add(data);
      }
    }
    return users;
  }

  Future<void> addXP(int amount) async {
    if (currentUserId == null) return;
    final userRef = _db.collection('users').doc(currentUserId);

    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;

        int currentXp = snapshot.data()?['xp'] ?? 0;
        int currentLevel = (currentXp / 1000).floor() + 1;
        int newXp = currentXp + amount;
        int newLevel = (newXp / 1000).floor() + 1;

        transaction.update(userRef, {'xp': newXp, 'level': newLevel});

        // Notify: level up
        if (newLevel > currentLevel) {
          NotificationService().sendNotification(
            title: 'Seviye Atladın! 🎉',
            body: 'Tebrikler! Seviye $newLevel\'e yükseldin!',
            type: 'system',
            icon: '⭐',
            color: 0xFFFFD600,
            prefKey: 'notif_level_up',
          );
        }
      });
    } catch (e) {
      debugPrint("XP ekleme hatası: $e");
    }
  }

  Stream<QuerySnapshot> getHabitsStream() {
    if (currentUserId == null) return const Stream.empty();
    return _db
        .collection('habits')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addHabit(String title) async {
    if (currentUserId == null) return;
    await _db.collection('habits').add({
      'userId': currentUserId,
      'title': title,
      'streak': 0,
      'lastCompleted': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleHabit(String habitId, bool isCompleted) async {
    final docRef = _db.collection('habits').doc(habitId);
    final now = DateTime.now();

    if (isCompleted) {
      await docRef.update({
        'lastCompleted': Timestamp.fromDate(now),
        'streak': FieldValue.increment(1)
      });
      await addXP(20);

      // Get updated streak for milestone check
      final updatedDoc = await docRef.get();
      final updatedStreak = updatedDoc.data()?['streak'] ?? 1;
      final habitTitle = updatedDoc.data()?['title'] ?? 'Alışkanlık';

      // Notify: streak milestones
      if ([7, 30, 100, 365].contains(updatedStreak)) {
        await NotificationService().sendNotification(
          title: 'Kilometre Taşı! 🏆',
          body: '$habitTitle için $updatedStreak günlük seri! Harika!',
          type: 'habit',
          targetId: habitId,
          targetType: 'habit',
          icon: '🏆',
          color: 0xFFFF9800,
          prefKey: 'notif_habit_milestone',
        );
      }
    } else {
      final doc = await docRef.get();
      final data = doc.data();
      final currentStreak = data?['streak'] ?? 0;
      await docRef.update({
        'lastCompleted': null,
        'streak': currentStreak > 0 ? currentStreak - 1 : 0,
      });
    }
  }

  Future<void> deleteHabit(String habitId) async {
    await _db.collection('habits').doc(habitId).delete();
  }

  Future<void> addTask(Task task) async {
    if (currentUserId == null) return;
    final taskMap = task.toMap();
    taskMap['userId'] = currentUserId;
    await _db.collection('tasks').add(taskMap);

    if (task.groupId != null) {
      await logTeamActivity(task.groupId!, 'task_created', task.title);
    }
  }

  Future<List<Task>> getTasksForStats() async {
    if (currentUserId == null) return [];
    try {
      final owned = await _db
          .collection('tasks')
          .where('userId', isEqualTo: currentUserId)
          .limit(1000)
          .get();
      final assigned = await _db
          .collection('tasks')
          .where('assignedTo', arrayContains: currentUserId)
          .limit(1000)
          .get();

      final allDocs = [...owned.docs, ...assigned.docs];
      final seenIds = <String>{};
      final tasks = <Task>[];

      for (var doc in allDocs) {
        if (seenIds.add(doc.id)) {
          tasks.add(Task.fromFirestore(doc));
        }
      }
      return tasks;
    } catch (e) {
      debugPrint("getTasksForStats error: $e");
      rethrow;
    }
  }

  Stream<List<Task>> getAllUserTasksStream() {
    if (currentUserId == null) return Stream.value([]);

    // Query for tasks where the user is the owner
    final ownedQuery = _db
        .collection('tasks')
        .where('userId', isEqualTo: currentUserId)
        .snapshots();

    // Use manual stream merging to be more reactive and efficient
    // Since we don't have rxdart, we can wrap them.
    return ownedQuery.asyncMap((ownedSnap) async {
      final assignedSnap = await _db
          .collection('tasks')
          .where('assignedTo', arrayContains: currentUserId)
          .get();

      final allDocs = [...ownedSnap.docs, ...assignedSnap.docs];
      final seenIds = <String>{};
      final tasks = <Task>[];

      for (var doc in allDocs) {
        if (seenIds.add(doc.id)) {
          tasks.add(Task.fromFirestore(doc));
        }
      }
      tasks.sort((a, b) => a.startTime.compareTo(b.startTime));
      return tasks;
    });
  }

  /// Optimized stream that fetches tasks only within a specific date range using semi-server-side filtering.
  Stream<List<Task>> getTasksStreamForDateRange(DateTime start, DateTime end) {
    if (currentUserId == null) return Stream.value([]);

    // Fetch ALL user tasks (already optimized in getAllUserTasksStream)
    // and filter by date range on the client side to avoid composite index requirements.
    return getAllUserTasksStream().map((tasks) {
      return tasks.where((t) {
        // Range check: t.startTime is within [start, end]
        return t.startTime
                .isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.startTime.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    });
  }

  Stream<List<Task>> getTasksForDateRange(DateTime start, DateTime end) {
    if (currentUserId == null) return Stream.value([]);

    return getAllUserTasksStream().map((tasks) {
      return tasks.where((t) {
        return t.startTime
                .isAfter(start.subtract(const Duration(minutes: 1))) &&
            t.startTime.isBefore(end.add(const Duration(minutes: 1)));
      }).toList();
    });
  }

  Future<void> updateTask(Task task) async {
    if (task.id != null) {
      // Ensure status is synced with isCompleted
      final updatedTask = task.copyWith(
        status: task.isCompleted ? 'done' : 'todo',
      );

      await _db.collection('tasks').doc(task.id).update(updatedTask.toMap());

      if (updatedTask.isCompleted) {
        if (updatedTask.groupId != null) {
          await logTeamActivity(
              updatedTask.groupId!, 'task_completed', updatedTask.title);
        }
        await addXP(50);
      }
    }
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': status,
      'isCompleted': status == 'done',
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }

  Future<void> addNote(Note note) async {
    if (currentUserId == null) return;
    final noteMap = note.toMap();
    noteMap['userId'] = currentUserId;
    await _db.collection('notes').add(noteMap);

    if (note.teamId != null) {
      await logTeamActivity(note.teamId!, 'note_created', note.title);
    }
  }

  Stream<List<Note>> getNotesStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('notes')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList());
  }

  Stream<List<Note>> getTeamNotesStream(String teamId) {
    // Return all notes associated with this teamId, regardless of creator
    return _db
        .collection('notes')
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList());
  }

  Future<void> updateNote(Note note) async {
    if (note.id != null) {
      await _db.collection('notes').doc(note.id).update(note.toMap());
    }
  }

  Future<void> deleteNote(String noteId) async {
    await _db.collection('notes').doc(noteId).delete();
  }

  Future<String> createAppointmentGroup(AppointmentGroup group) async {
    await _db.collection('appointment_groups').add(group.toMap());
    return group.groupCode;
  }

  Future<void> updateAppointmentGroup(AppointmentGroup group) async {
    if (group.id != null) {
      await _db
          .collection('appointment_groups')
          .doc(group.id)
          .update(group.toMap());
    }
  }

  Future<void> deleteAppointmentGroup(String groupId) async {
    await _db.collection('appointment_groups').doc(groupId).delete();
  }

  Stream<List<AppointmentGroup>> getMyAppointmentGroups() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('appointment_groups')
        .where('ownerId', isEqualTo: currentUserId)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => AppointmentGroup.fromFirestore(d)).toList());
  }

  Future<AppointmentGroup?> getGroupById(String groupId) async {
    try {
      final doc = await _db.collection('appointment_groups').doc(groupId).get();
      if (!doc.exists) return null;
      return AppointmentGroup.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Stream<List<Appointment>> getAppointmentsStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('appointments')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc))
            .toList());
  }

  Stream<List<Appointment>> getMyAppointmentsAsClientStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('appointments')
        .where('clientId', isEqualTo: currentUserId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc))
            .toList());
  }

  /// Optimized stream for date-range filtered appointments as provider
  Stream<List<Appointment>> getAppointmentsStreamForDateRange(
      DateTime start, DateTime end) {
    if (currentUserId == null) return Stream.value([]);

    // Client-side filtering to avoid composite index
    return getAppointmentsStream().map((appts) {
      return appts
          .where((a) =>
              a.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              a.date.isBefore(end.add(const Duration(seconds: 1))))
          .toList();
    });
  }

  /// Optimized stream for date-range filtered appointments as client
  Stream<List<Appointment>> getMyAppointmentsAsClientStreamForDateRange(
      DateTime start, DateTime end) {
    if (currentUserId == null) return Stream.value([]);

    // Client-side filtering to avoid composite index
    return getMyAppointmentsAsClientStream().map((appts) {
      return appts
          .where((a) =>
              a.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              a.date.isBefore(end.add(const Duration(seconds: 1))))
          .toList();
    });
  }

  Future<AppointmentGroup?> getGroupByCode(String code) async {
    final query = await _db
        .collection('appointment_groups')
        .where('groupCode', isEqualTo: code)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return AppointmentGroup.fromFirestore(query.docs.first);
  }

  Future<List<DateTime>> getAvailableSlots(
      AppointmentGroup group, DateTime date) async {
    if (date.isBefore(DateUtils.dateOnly(group.startDate)) ||
        date.isAfter(DateUtils.dateOnly(group.endDate))) {
      return [];
    }

    if (!group.workingDays.contains(date.weekday)) {
      return [];
    }

    final dayStart = DateTime(date.year, date.month, date.day, 0, 0);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59);

    final snapshot = await _db
        .collection('appointments')
        .where('groupId', isEqualTo: group.id)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dayEnd))
        .get();

    List<DateTime> bookedSlots =
        snapshot.docs.map((d) => (d['date'] as Timestamp).toDate()).toList();
    List<DateTime> availableSlots = [];

    DateTime currentSlot =
        DateTime(date.year, date.month, date.day, group.startHour, 0);
    DateTime shiftEnd =
        DateTime(date.year, date.month, date.day, group.endHour, 0);

    while (currentSlot
            .add(Duration(minutes: group.durationMinutes))
            .isBefore(shiftEnd) ||
        currentSlot
            .add(Duration(minutes: group.durationMinutes))
            .isAtSameMomentAs(shiftEnd)) {
      bool isAvailable = true;
      DateTime slotEnd =
          currentSlot.add(Duration(minutes: group.durationMinutes));

      for (var b in group.breaks) {
        DateTime breakStart = DateTime(
            date.year, date.month, date.day, b['startH']!, b['startM']!);
        DateTime breakEnd =
            DateTime(date.year, date.month, date.day, b['endH']!, b['endM']!);

        if (currentSlot.isBefore(breakEnd) && slotEnd.isAfter(breakStart)) {
          isAvailable = false;
          break;
        }
      }

      if (isAvailable) {
        for (var booked in bookedSlots) {
          if (booked.isAtSameMomentAs(currentSlot)) {
            isAvailable = false;
            break;
          }
        }
      }

      if (isAvailable && currentSlot.isBefore(DateTime.now())) {
        isAvailable = false;
      }

      if (isAvailable) {
        availableSlots.add(currentSlot);
      }

      currentSlot = currentSlot
          .add(Duration(minutes: group.durationMinutes + group.bufferMinutes));
    }

    return availableSlots;
  }

  Future<void> addAppointment(Appointment appt) async {
    await _db.collection('appointments').add(appt.toMap());
  }

  Future<void> updateAppointment(Appointment appt) async {
    if (appt.id != null) {
      await _db.collection('appointments').doc(appt.id).update(appt.toMap());
    }
  }

  Future<void> deleteAppointment(String id) async {
    await _db.collection('appointments').doc(id).delete();
  }

  Future<String> createTeam(String teamName) async {
    if (currentUserId == null) throw Exception("Giriş yapılmalı");
    final String joinCode = "TEAM-${1000 + Random().nextInt(9000)}";
    final docRef = _db.collection('teams').doc();

    await docRef.set({
      'name': teamName,
      'ownerId': currentUserId,
      'memberIds': [currentUserId],
      'adminIds': [currentUserId],
      'joinCode': joinCode,
      'createdAt': FieldValue.serverTimestamp(),
      'announcement': null,
    });

    await _db.collection('users').doc(currentUserId).update({
      'joinedTeams': FieldValue.arrayUnion([docRef.id])
    });

    await logTeamActivity(docRef.id, 'team_created', teamName);

    return joinCode;
  }

  Future<bool> joinTeam(String code) async {
    if (currentUserId == null) return false;
    final query =
        await _db.collection('teams').where('joinCode', isEqualTo: code).get();

    if (query.docs.isEmpty) return false;
    final teamDoc = query.docs.first;

    await _db.collection('teams').doc(teamDoc.id).update({
      'memberIds': FieldValue.arrayUnion([currentUserId])
    });

    await _db.collection('users').doc(currentUserId).update({
      'joinedTeams': FieldValue.arrayUnion([teamDoc.id])
    });

    await logTeamActivity(
        teamDoc.id, 'member_joined', currentUser?.displayName ?? 'Üye');

    return true;
  }

  Stream<List<Team>> getUserTeamsStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('teams')
        .where('memberIds', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => Team.fromFirestore(d)).toList());
  }

  Stream<List<Task>> getTeamTasksStream(String teamId) {
    return _db
        .collection('tasks')
        .where('groupId', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) {
      final tasks =
          snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
      tasks.sort((a, b) => a.startTime.compareTo(b.startTime));
      return tasks;
    });
  }

  Future<void> addTeamLink(String teamId, String title, String url) async {
    await _db.collection('teams').doc(teamId).collection('resources').add({
      'title': title,
      'url': url,
      'addedBy': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'link',
    });
    await logTeamActivity(teamId, 'added_link', title);
  }

  Stream<QuerySnapshot> getTeamResources(String teamId) {
    return _db
        .collection('teams')
        .doc(teamId)
        .collection('resources')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteTeamResource(String teamId, String resourceId) async {
    await _db
        .collection('teams')
        .doc(teamId)
        .collection('resources')
        .doc(resourceId)
        .delete();
  }

  Future<void> updateTeamAnnouncement(String teamId, String message) async {
    await _db.collection('teams').doc(teamId).update({
      'announcement': message,
      'announcementBy': currentUser?.displayName,
      'announcementDate': FieldValue.serverTimestamp(),
    });

    // Notify: new announcement
    await NotificationService().sendNotification(
      title: 'Takım Duyurusu',
      body: message,
      type: 'team',
      targetId: teamId,
      targetType: 'team',
      icon: '📢',
      color: 0xFFFF5722,
      prefKey: 'notif_team_announce',
    );
  }

  Future<void> updateTeam(Team team) async {
    if (currentUserId == null) return;
    if (team.ownerId == currentUserId) {
      await _db.collection('teams').doc(team.id).update({'name': team.name});
    }
  }

  Future<void> leaveTeam(String teamId) async {
    if (currentUserId == null) return;

    await _db.collection('teams').doc(teamId).update({
      'memberIds': FieldValue.arrayRemove([currentUserId]),
      'adminIds': FieldValue.arrayRemove([currentUserId])
    });
    await _db.collection('users').doc(currentUserId).update({
      'joinedTeams': FieldValue.arrayRemove([teamId])
    });
    await logTeamActivity(
        teamId, 'member_left', currentUser?.displayName ?? 'Üye');
  }

  Future<void> deleteTeam(String teamId) async {
    if (currentUserId == null) return;
    await _db.collection('teams').doc(teamId).delete();
  }

  Future<void> kickMember(String teamId, String memberId) async {
    if (currentUserId == null) return;
    await _db.collection('teams').doc(teamId).update({
      'memberIds': FieldValue.arrayRemove([memberId]),
      'adminIds': FieldValue.arrayRemove([memberId])
    });
    await _db.collection('users').doc(memberId).update({
      'joinedTeams': FieldValue.arrayRemove([teamId])
    });
  }

  Future<void> promoteToAdmin(String teamId, String memberId) async {
    if (currentUserId == null) return;
    await _db.collection('teams').doc(teamId).update({
      'adminIds': FieldValue.arrayUnion([memberId])
    });
  }

  Future<void> demoteFromAdmin(String teamId, String memberId) async {
    if (currentUserId == null) return;
    await _db.collection('teams').doc(teamId).update({
      'adminIds': FieldValue.arrayRemove([memberId])
    });
  }

  Future<void> logTeamActivity(
      String teamId, String action, String details) async {
    if (currentUserId == null) return;
    try {
      await _db.collection('activity_logs').add({
        'teamId': teamId,
        'userId': currentUserId,
        'userName': currentUser?.displayName ?? 'Bilinmeyen',
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Log hatası: $e");
    }
  }

  Stream<List<ActivityLog>> getTeamActivityLogs(String teamId) {
    return _db
        .collection('activity_logs')
        .where('teamId', isEqualTo: teamId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => ActivityLog.fromFirestore(d)).toList());
  }

  Future<String> createProject(String teamId, Project project) async {
    final doc = await _db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .add(project.toMap());

    // Automatic Todo Creation: Add a task for the project manager
    if (currentUserId != null) {
      final now = DateTime.now();
      final projectTask = Task(
        userId: currentUserId!,
        title: "Proje: ${project.name}",
        description:
            "Takım projesi başlatıldı. Detaylar ve alt görevler için projeyi inceleyin.\n${project.description}",
        startTime: now,
        endTime: project.deadline ?? now.add(const Duration(hours: 1)),
        color: project.color,
        priority: 2, // Important
        groupId: teamId, // Link to team
        tags: ['Proje', project.name],
        status: 'todo',
      );
      await addTask(projectTask);
    }

    return doc.id;
  }

  Stream<List<Project>> getProjectsStream(String teamId) {
    return _db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Project.fromFirestore(d)).toList());
  }

  Future<void> addProjectResource(
      String teamId, String projectId, String title, String url) async {
    await _db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .doc(projectId)
        .collection('resources')
        .add({
      'title': title,
      'url': url,
      'addedBy': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'link',
    });
    await logTeamActivity(teamId, 'added_project_resource', title);
  }

  Stream<QuerySnapshot> getProjectResources(String teamId, String projectId) {
    return _db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .doc(projectId)
        .collection('resources')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteProjectResource(
      String teamId, String projectId, String resourceId) async {
    await _db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .doc(projectId)
        .collection('resources')
        .doc(resourceId)
        .delete();
  }

  Future<void> updateProject(
      String teamId, String projectId, Map<String, dynamic> data) async {
    await _db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .doc(projectId)
        .update(data);
  }

  Future<void> deleteProject(String teamId, String projectId) async {
    await _db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .doc(projectId)
        .delete();
  }

  Stream<List<Task>> getProjectTasksStream(String teamId, String projectId) {
    return _db
        .collection('tasks')
        .where('groupId', isEqualTo: projectId)
        .snapshots()
        .map((s) => s.docs.map((d) => Task.fromFirestore(d)).toList());
  }

  Future<void> deleteAllData() async {
    if (currentUserId == null) return;

    final collections = [
      _db.collection('tasks').where('userId', isEqualTo: currentUserId),
      _db.collection('notes').where('userId', isEqualTo: currentUserId),
      _db.collection('habits').where('userId', isEqualTo: currentUserId),
      _db.collection('appointments').where('userId', isEqualTo: currentUserId),
      _db
          .collection('appointment_groups')
          .where('ownerId', isEqualTo: currentUserId),
      _db
          .collection('budget_transactions')
          .where('userId', isEqualTo: currentUserId),
      _db
          .collection('budget_accounts')
          .where('userId', isEqualTo: currentUserId),
      _db.collection('budget_debts').where('userId', isEqualTo: currentUserId),
      _db.collection('budget_limits').where('userId', isEqualTo: currentUserId),
      _db.collection('savings_goals').where('userId', isEqualTo: currentUserId),
      _db.collection('budget_assets').where('userId', isEqualTo: currentUserId),
      _db.collection('users').doc(currentUserId).collection('medications'),
      _db.collection('users').doc(currentUserId).collection('notifications'),
    ];

    final allDocs = <DocumentReference>[];
    for (final query in collections) {
      try {
        final snapshot = await query.get();
        allDocs.addAll(snapshot.docs.map((d) => d.reference));
      } catch (e) {
        debugPrint("Error fetching docs for deletion: $e");
      }
    }

    // Process deletions in smaller reliable batches
    for (var i = 0; i < allDocs.length; i += 400) {
      // 400 to be safe with Firebase limits
      final batch = _db.batch();
      final end = (i + 400 < allDocs.length) ? i + 400 : allDocs.length;
      for (var j = i; j < end; j++) {
        batch.delete(allDocs[j]);
      }
      try {
        await batch.commit();
      } catch (e) {
        debugPrint("Error committing deletion batch: $e");
        throw Exception("Veriler silinirken hata oluştu: $e");
      }
    }
  }

  Future<void> generateFullTestEnvironment(
      {Function(double)? onProgress}) async {
    if (currentUserId == null) return;
    debugPrint(">> Test Gen: Başlıyor...");
    onProgress?.call(0.02);

    debugPrint(">> Test Gen: Veriler siliniyor...");
    await deleteAllData();
    debugPrint(">> Test Gen: Bildirimler iptal ediliyor...");
    await NotificationService().cancelAllNotifications();
    onProgress?.call(0.08);

    final random = Random();
    final now = DateTime.now();
    final uid = currentUserId!;

    debugPrint(">> Test Gen: XP resetleniyor...");
    await _db.collection('users').doc(uid).update({'xp': 950, 'level': 1});
    onProgress?.call(0.10);

    debugPrint(">> Test Gen: Bütçe Ultimate Data başlatılıyor...");
    await BudgetService().generateUltimateTestData(days: 90);
    debugPrint(">> Test Gen: Bütçe limitleri ekleniyor...");
    for (var l in [
      BudgetLimit(userId: uid, category: 'Market', limitAmount: 3000),
      BudgetLimit(userId: uid, category: 'Yemek', limitAmount: 2000),
      BudgetLimit(userId: uid, category: 'Ulaşım', limitAmount: 1500),
      BudgetLimit(userId: uid, category: 'Eğlence', limitAmount: 1000),
      BudgetLimit(userId: uid, category: 'Fatura', limitAmount: 2500),
    ]) {
      await BudgetService().addLimit(l);
    }
    for (var g in [
      SavingsGoal(
          userId: uid,
          title: 'Tatil Fonu',
          targetAmount: 50000,
          currentAmount: 42000,
          deadline: now.add(const Duration(days: 90)),
          icon: '✈️'),
      SavingsGoal(
          userId: uid,
          title: 'Yeni Telefon',
          targetAmount: 40000,
          currentAmount: 32000,
          deadline: now.add(const Duration(days: 45)),
          icon: '📱'),
      SavingsGoal(
          userId: uid,
          title: 'Acil Durum Fonu',
          targetAmount: 100000,
          currentAmount: 55000,
          icon: '🏦'),
      SavingsGoal(
          userId: uid,
          title: 'Araba',
          targetAmount: 500000,
          currentAmount: 125000,
          deadline: now.add(const Duration(days: 365)),
          icon: '🚗'),
    ]) {
      await BudgetService().addGoal(g);
    }
    onProgress?.call(0.35);

    // ── TEAMS & PROJECTS ──
    final t1 = await _db.collection('teams').add({
      'name': 'Broadway Yazılım Ekibi',
      'ownerId': uid,
      'memberIds': [uid],
      'adminIds': [uid],
      'joinCode': 'TEAM-${1000 + random.nextInt(9000)}',
      'createdAt': FieldValue.serverTimestamp(),
      'announcement':
          'Sprint #14 başladı! Hedef: Bildirim sistemi entegrasyonu.',
      'announcementBy': currentUser?.displayName,
      'announcementDate': FieldValue.serverTimestamp(),
    });
    final t2 = await _db.collection('teams').add({
      'name': 'Tasarım Stüdyosu',
      'ownerId': uid,
      'memberIds': [uid],
      'adminIds': [uid],
      'joinCode': 'TEAM-${1000 + random.nextInt(9000)}',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('users').doc(uid).update({
      'joinedTeams': FieldValue.arrayUnion([t1.id, t2.id])
    });
    final p1 =
        await _db.collection('teams').doc(t1.id).collection('projects').add({
      'teamId': t1.id,
      'name': 'Phobes Mobil Uygulama',
      'description': 'Kişisel asistan uygulaması.',
      'managerId': uid,
      'status': 'active',
      'deadline': Timestamp.fromDate(now.add(const Duration(days: 30))),
      'color': 0xFF6366F1,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final p2 =
        await _db.collection('teams').doc(t1.id).collection('projects').add({
      'teamId': t1.id,
      'name': 'Backend API',
      'description': 'REST API geliştirme.',
      'managerId': uid,
      'status': 'active',
      'deadline': Timestamp.fromDate(now.add(const Duration(days: 60))),
      'color': 0xFF10B981,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('teams').doc(t2.id).collection('projects').add({
      'teamId': t2.id,
      'name': 'UI/UX Redesign',
      'description': 'Yeni tasarım sistemi.',
      'managerId': uid,
      'status': 'active',
      'deadline': Timestamp.fromDate(now.add(const Duration(days: 45))),
      'color': 0xFFEC4899,
      'createdAt': FieldValue.serverTimestamp(),
    });
    for (var a in [
      ['team_created', 'Broadway Yazılım Ekibi'],
      ['project_created', 'Phobes Mobil Uygulama'],
      ['task_completed', 'Login ekranı tamamlandı'],
    ]) {
      await logTeamActivity(t1.id, a[0], a[1]);
    }
    onProgress?.call(0.40);

    // ── TASKS (90 days) ──
    final titles = [
      'Sprint toplantısı hazırlığı',
      'Kod review yap',
      'API endpoint geliştir',
      'Test senaryoları yaz',
      'Dokümantasyon güncelle',
      'Veritabanı migrasyonu',
      'UI bileşeni oluştur',
      'Performans optimizasyonu',
      'Güvenlik taraması',
      'Haftalık rapor hazırla',
      'Müşteri toplantısı',
      'Bug fix: Login hatası',
      'Alışveriş listesi hazırla',
      'Spor salonu',
      'Kitap oku',
    ];
    final clrs = [
      0xFF4285F4,
      0xFF34A853,
      0xFFEA4335,
      0xFFFF9800,
      0xFF9C27B0,
      0xFF00BCD4
    ];
    for (int i = 0; i < 90; i++) {
      final d = now.subtract(Duration(days: i));
      int cnt = i == 0 ? 5 : (1 + random.nextInt(3));
      for (int j = 0; j < cnt; j++) {
        final h = 8 + random.nextInt(10);
        final done = i > 0 && random.nextDouble() > 0.3;
        await addTask(Task(
          userId: uid,
          title: i == 0
              ? titles[j % titles.length]
              : '${titles[random.nextInt(titles.length)]} #${i * 3 + j}',
          description: 'Otomatik oluşturulan test görevi.',
          startTime: DateTime(d.year, d.month, d.day, h, 0),
          endTime: DateTime(d.year, d.month, d.day, h + 1, 30),
          isCompleted: done,
          status: done
              ? 'done'
              : (i == 0
                  ? 'todo'
                  : (random.nextBool() ? 'in_progress' : 'todo')),
          priority: random.nextInt(3),
          color: clrs[random.nextInt(clrs.length)],
          groupId: j == 0 && i % 3 == 0
              ? p1.id
              : (j == 1 && i % 5 == 0 ? p2.id : null),
          reminderMinutes: i == 0 ? 15 : -1,
        ));
      }
    }
    onProgress?.call(0.55);

    // ── NOTES (17 notes, 5 categories) ──
    final noteData = {
      'Fikirler': [
        'Uygulama Fikirleri|AI destekli kişisel asistan.',
        'Startup Konsepti|SaaS proje yönetim aracı.',
        'Otomasyon|CI/CD pipeline.'
      ],
      'Toplantı': [
        'Sprint #14|Bildirim sistemi öncelikli.',
        'Müşteri GeriBildirim|Dashboard daha sezgisel.',
        'Tasarım|Dark mode güncellendi.'
      ],
      'Kişisel': [
        'Okuma Listesi|Clean Code, Design Patterns.',
        'Hedefler 2026|Flutter uzmanı ol.',
        'Seyahat|İstanbul-Kapadokya-Antalya.'
      ],
      'Kod Blokları': [
        'Animation Snippet|AnimatedContainer.',
        'Firebase Query|Composite index.',
        'State Pattern|Provider best practices.'
      ],
      'İş': [
        'Proje Durumu|Backend %80, Frontend %65.',
        'Teknik Borç|Legacy API migration.'
      ],
    };
    for (var e in noteData.entries) {
      for (var n in e.value) {
        final parts = n.split('|');
        await addNote(Note(
            userId: uid,
            title: parts[0],
            content: '{"ops":[{"insert":"${parts[1]}\\n"}]}',
            date: now.subtract(Duration(days: random.nextInt(30))),
            category: e.key,
            color: clrs[random.nextInt(clrs.length)]));
      }
    }
    onProgress?.call(0.60);

    // ── HABITS (6, "Kod Yaz" at 99 for milestone test) ──
    for (var h in [
      {'t': '2L Su İç', 's': 23},
      {'t': '30 Dakika Yürüyüş', 's': 7},
      {'t': 'Kitap Oku', 's': 45},
      {'t': 'Meditasyon', 's': 12},
      {'t': 'Kod Yaz', 's': 99},
      {'t': 'Erken Kalk', 's': 5},
    ]) {
      await _db.collection('habits').add({
        'userId': uid,
        'title': h['t'],
        'streak': h['s'],
        'lastCompleted': (h['s'] as int) > 0
            ? Timestamp.fromDate(now.subtract(const Duration(days: 1)))
            : null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    onProgress?.call(0.65);

    // ── MEDICATIONS (5 with stock tracking) ──
    for (var m in [
      Medication(
          userId: uid,
          name: 'Vitamin C',
          icon: '🍋',
          dosage: '1000mg',
          startDate: now.subtract(const Duration(days: 60)),
          times: ['09:00'],
          reminderEnabled: true,
          stock: 15,
          stockTracking: true,
          notes: 'Kahvaltıdan sonra.'),
      Medication(
          userId: uid,
          name: 'Magnezyum',
          icon: '💊',
          dosage: '400mg',
          startDate: now.subtract(const Duration(days: 45)),
          times: ['22:00'],
          reminderEnabled: true,
          stock: 4,
          stockTracking: true,
          notes: 'Yatmadan önce.'),
      Medication(
          userId: uid,
          name: 'Omega-3',
          icon: '🐟',
          dosage: '1 Kapsül',
          startDate: now.subtract(const Duration(days: 30)),
          times: ['08:00', '20:00'],
          reminderEnabled: true,
          stock: 2,
          stockTracking: true,
          notes: 'Yemeklerle birlikte.'),
      Medication(
          userId: uid,
          name: 'Probiyotik',
          icon: '🦠',
          dosage: '1 Kapsül',
          startDate: now.subtract(const Duration(days: 20)),
          times: ['07:30'],
          reminderEnabled: true,
          stock: 30,
          stockTracking: true,
          notes: 'Aç karnına.'),
      Medication(
          userId: uid,
          name: 'D Vitamini',
          icon: '☀️',
          dosage: '4000 IU',
          startDate: now.subtract(const Duration(days: 15)),
          times: ['12:00'],
          reminderEnabled: false,
          notes: 'Güneşli günlerde atlanabilir.'),
    ]) {
      final ref = await _db.collection(_medCol).add(m.toMap());
      for (int d = 1; d <= 7; d++) {
        final dt = now.subtract(Duration(days: d));
        final k =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        if (random.nextDouble() > 0.2) {
          await _db
              .collection(_medCol)
              .doc(ref.id)
              .update({'takenHistory.$k': m.times});
        }
      }
    }
    onProgress?.call(0.75);

    // ── APPOINTMENTS (10) ──
    final grp = await _db.collection('appointment_groups').add({
      'ownerId': uid,
      'title': 'Danışmanlık Seansı',
      'businessName': 'Broadway Danışmanlık',
      'description': 'Kariyer danışmanlığı.',
      'durationMinutes': 45,
      'slotInterval': 60,
      'startHour': 9,
      'endHour': 17,
      'workDays': [1, 2, 3, 4, 5],
      'joinCode': 'APPT-${1000 + random.nextInt(9000)}',
      'createdAt': FieldValue.serverTimestamp(),
    });
    final sts = [
      'completed',
      'completed',
      'completed',
      'confirmed',
      'confirmed',
      'pending',
      'pending',
      'cancelled'
    ];
    final cns = [
      'Ahmet Yılmaz',
      'Elif Demir',
      'Mehmet Kaya',
      'Zeynep Çelik',
      'Can Arslan',
      'Ayşe Özkan',
      'Burak Şahin',
      'Deniz Aktaş'
    ];
    for (int r = 0; r < 8; r++) {
      await addAppointment(Appointment(
          userId: uid,
          clientId: uid,
          groupId: grp.id,
          title: 'Danışmanlık Seansı',
          clientName: cns[r],
          date: r < 3
              ? now.subtract(Duration(days: (r + 1) * 7, hours: 10))
              : now.add(Duration(days: (r - 2) * 3, hours: 10)),
          status: sts[r]));
    }
    await addAppointment(Appointment(
        userId: uid,
        clientId: uid,
        groupId: grp.id,
        title: '🔔 Yaklaşan Randevu',
        clientName: 'Test Müşterisi',
        date: now.add(const Duration(hours: 2)),
        status: 'confirmed'));
    await addAppointment(Appointment(
        userId: uid,
        clientId: uid,
        title: '📅 Yarınki Toplantı',
        clientName: 'Proje Sponsoru',
        date: DateTime(now.year, now.month, now.day + 1, 14, 0),
        status: 'pending'));
    onProgress?.call(0.82);

    // ── 10-MINUTE NOTIFICATION TEST ──
    final tt = now.add(const Duration(minutes: 10));
    await addTask(Task(
        userId: uid,
        title: '🔔 Bildirim Test Görevi',
        description: '10 dk sonra hatırlatma gelecek.',
        startTime: tt,
        endTime: tt.add(const Duration(hours: 1)),
        reminderMinutes: 0,
        priority: 2,
        color: 0xFFEA4335));
    await NotificationService().scheduleAndSaveNotification(
        id: 'test_task',
        title: 'Görev Zamanı: 🔔 Test',
        body: 'Bu görevin süresi geldi.',
        scheduledTime: tt,
        type: 'task',
        icon: '📋',
        color: 0xFF8B5CF6);
    final testMed = Medication(
        userId: uid,
        name: 'Test Şurubu',
        icon: '🧪',
        dosage: '5ml',
        startDate: now,
        times: [
          '${tt.hour.toString().padLeft(2, '0')}:${tt.minute.toString().padLeft(2, '0')}'
        ],
        reminderEnabled: true,
        stock: 3,
        stockTracking: true);
    await addMedication(testMed);
    await NotificationService().scheduleAndSaveNotification(
        id: 'test_med',
        title: 'İlaç: ${testMed.name}',
        body: 'Dozunuzu almayı unutmayın.',
        scheduledTime: tt,
        type: 'medication',
        icon: '💊',
        color: 0xFF009688,
        channelId: 'medications',
        channelName: 'İlaçlarım');
    await addAppointment(Appointment(
        userId: uid,
        clientId: uid,
        title: '🔔 Test Randevusu',
        clientName: 'Sistem Testi',
        date: tt,
        status: 'pending'));
    await NotificationService().scheduleAndSaveNotification(
        id: 'test_appt',
        title: 'Yaklaşan Randevu',
        body: 'Test Randevusu başlıyor.',
        scheduledTime: tt,
        type: 'appointment',
        icon: '📅',
        color: 0xFF2196F3,
        channelId: 'appointments',
        channelName: 'Randevular');
    await addHabit('🔔 Test Alışkanlığı');
    await NotificationService().scheduleAndSaveNotification(
        id: 'test_habit',
        title: 'Alışkanlık Hatırlatıcısı',
        body: 'Test alışkanlığını tamamla!',
        scheduledTime: tt,
        type: 'habit',
        icon: '🔥',
        color: 0xFF4CAF50);
    onProgress?.call(0.92);

    // ── INITIAL IN-APP NOTIFICATIONS (12) ──
    for (var n in [
      AppNotification(
          userId: uid,
          title: 'Sistem Hazır! 🚀',
          body: 'Test verileri yüklendi.',
          type: 'system',
          icon: '🚀',
          color: 0xFF6C63FF,
          createdAt: now),
      AppNotification(
          userId: uid,
          title: 'Yaklaşan Görevler',
          body: 'Bugün 5 görevin var!',
          type: 'task',
          icon: '📋',
          color: 0xFF8B5CF6,
          createdAt: now.subtract(const Duration(hours: 1))),
      AppNotification(
          userId: uid,
          title: 'İlaç Zamanı',
          body: 'Vitamin C - 09:00 dozunu almayı unutma.',
          type: 'medication',
          icon: '🍋',
          color: 0xFF009688,
          createdAt: now.subtract(const Duration(hours: 2))),
      AppNotification(
          userId: uid,
          title: 'Seri Devam Ediyor! 🔥',
          body: 'Kitap Oku - 45 günlük seri!',
          type: 'habit',
          icon: '🔥',
          color: 0xFF4CAF50,
          createdAt: now.subtract(const Duration(hours: 3))),
      AppNotification(
          userId: uid,
          title: 'Randevu Onaylandı ✅',
          body: 'Elif Demir - Danışmanlık Seansı.',
          type: 'appointment',
          icon: '✅',
          color: 0xFF4CAF50,
          createdAt: now.subtract(const Duration(hours: 5))),
      AppNotification(
          userId: uid,
          title: 'Büyük Harcama! 💸',
          body: 'Market - 850 TL harcama.',
          type: 'budget',
          icon: '💸',
          color: 0xFFF44336,
          createdAt: now.subtract(const Duration(hours: 6))),
      AppNotification(
          userId: uid,
          title: 'Bütçe Limiti Yaklaşıyor ⚠️',
          body: 'Yemek: 1650 / 2000 TL (%82)',
          type: 'budget',
          icon: '⚠️',
          color: 0xFFFF9800,
          createdAt: now.subtract(const Duration(hours: 8))),
      AppNotification(
          userId: uid,
          title: 'Takım Duyurusu 📢',
          body: 'Sprint #14 başladı!',
          type: 'team',
          icon: '📢',
          color: 0xFFFF5722,
          createdAt: now.subtract(const Duration(hours: 10))),
      AppNotification(
          userId: uid,
          title: 'Stok Azalıyor! ⚠️',
          body: 'Omega-3 - Kalan: 2',
          type: 'medication',
          icon: '⚠️',
          color: 0xFFFF9800,
          createdAt: now.subtract(const Duration(hours: 12))),
      AppNotification(
          userId: uid,
          title: 'Hedefe Çok Yaklaştın! 💪',
          body: 'Tatil Fonu - %84',
          type: 'budget',
          icon: '💪',
          color: 0xFFFF9800,
          createdAt: now.subtract(const Duration(hours: 24))),
      AppNotification(
          userId: uid,
          title: 'Görev Tamamlandı ✅',
          body: 'Sprint toplantısı hazırlığı',
          type: 'task',
          icon: '✅',
          color: 0xFF4CAF50,
          createdAt: now.subtract(const Duration(days: 1, hours: 3))),
      AppNotification(
          userId: uid,
          title: 'Odak Süresi Bitti 🎯',
          body: '25 dk odak seansı tamamlandı. +100 XP',
          type: 'focus',
          icon: '🎯',
          color: 0xFFFF9800,
          createdAt: now.subtract(const Duration(days: 1, hours: 6))),
    ]) {
      await addAppNotification(n);
    }
    onProgress?.call(0.98);

    await addAppNotification(AppNotification(
        userId: uid,
        title: '✅ Test Ortamı Hazır!',
        body:
            '10 dk sonra bildirim testleri başlayacak. Kod Yaz alışkanlığını tamamla → 100. gün milestone!',
        type: 'system',
        icon: '✅',
        color: 0xFF4CAF50,
        createdAt: now));
    onProgress?.call(1.0);
  }

  String get _medCol => 'users/$currentUserId/medications';

  Future<void> addMedication(Medication med) async {
    await _db.collection(_medCol).add(med.toMap());
  }

  Future<void> updateMedication(Medication med) async {
    if (med.id == null) return;
    await _db.collection(_medCol).doc(med.id).update(med.toMap());
  }

  Future<void> deleteMedication(String medId) async {
    await _db.collection(_medCol).doc(medId).delete();
  }

  Stream<List<Medication>> getMedicationsStream() {
    return _db.collection(_medCol).orderBy('name').snapshots().map((snap) =>
        snap.docs.map((d) => Medication.fromMap(d.data(), d.id)).toList());
  }

  Future<Medication?> getMedicationById(String medId) async {
    final doc = await _db.collection(_medCol).doc(medId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Medication.fromMap(doc.data()!, doc.id);
  }

  Future<void> markMedicationTaken(
      String medId, String dateKey, String time) async {
    final docRef = _db.collection(_medCol).doc(medId);
    String medName = '';
    int stockAfter = 0;
    bool trackingStock = false;

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      medName = data['name'] ?? 'İlaç';
      final bool tracking = data['stockTracking'] ?? false;
      trackingStock = tracking;
      final int currentStock = data['stock'] ?? 0;

      final Map<String, dynamic> updates = {
        'takenHistory.$dateKey': FieldValue.arrayUnion([time]),
      };
      if (tracking && currentStock > 0) {
        updates['stock'] = currentStock - 1;
        stockAfter = currentStock - 1;
      } else {
        stockAfter = currentStock;
      }
      transaction.update(docRef, updates);
    });

    // Notify: stock low warning
    if (trackingStock && stockAfter <= 5 && stockAfter > 0) {
      await NotificationService().sendNotification(
        title: 'Stok Azalıyor! ⚠️',
        body: '$medName - Kalan stok: $stockAfter',
        type: 'medication',
        targetId: medId,
        targetType: 'medication',
        icon: '⚠️',
        color: 0xFFFF9800,
        prefKey: 'notif_med_refill',
      );
    } else if (trackingStock && stockAfter <= 0) {
      await NotificationService().sendNotification(
        title: 'Stok Bitti! 🚨',
        body: '$medName stoğunuz tükendi. Yenileme zamanı.',
        type: 'medication',
        targetId: medId,
        targetType: 'medication',
        icon: '🚨',
        color: 0xFFF44336,
        prefKey: 'notif_med_refill',
      );
    }
  }

  Future<void> unmarkMedicationTaken(
      String medId, String dateKey, String time) async {
    final docRef = _db.collection(_medCol).doc(medId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final bool tracking = data['stockTracking'] ?? false;
      final int currentStock = data['stock'] ?? 0;

      final Map<String, dynamic> updates = {
        'takenHistory.$dateKey': FieldValue.arrayRemove([time]),
      };
      if (tracking) {
        updates['stock'] = currentStock + 1;
      }
      transaction.update(docRef, updates);
    });
  }

  String get _notifCol => 'users/$currentUserId/notifications';

  Future<void> addAppNotification(AppNotification notif) async {
    await _db.collection(_notifCol).add(notif.toMap());
  }

  Stream<List<AppNotification>> getNotificationsStream() {
    return _db
        .collection(_notifCol)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<int> getUnreadNotificationCount() {
    return _db
        .collection(_notifCol)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markNotificationRead(String notifId) async {
    await _db.collection(_notifCol).doc(notifId).update({'isRead': true});
  }

  Future<void> markAllNotificationsRead() async {
    final batch = _db.batch();
    final unread =
        await _db.collection(_notifCol).where('isRead', isEqualTo: false).get();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteOldNotifications({int daysOld = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    final batch = _db.batch();
    final old = await _db
        .collection(_notifCol)
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
        .get();
    for (var doc in old.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // GLOBAL MEDICINE DATABASE METHODS
  Future<List<Map<String, dynamic>>> searchMedicines(String query) async {
    if (query.isEmpty) return [];

    // Normalize query for search (Turkish chars, lowercase, trim)
    // IMPORTANT: Must match the Python import script's normalization exactly.
    String normalize(String s) {
      // First replace uppercase Turkish chars BEFORE toLowerCase
      // to avoid combining character issues (İ.toLowerCase() = i̇ in some locales)
      s = s
          .replaceAll('İ', 'i')
          .replaceAll('I', 'i')  // Turkish I → i (not ı)
          .replaceAll('Ğ', 'g')
          .replaceAll('Ü', 'u')
          .replaceAll('Ş', 's')
          .replaceAll('Ö', 'o')
          .replaceAll('Ç', 'c');
      s = s.toLowerCase();
      s = s
          .replaceAll('ı', 'i')
          .replaceAll('ğ', 'g')
          .replaceAll('ü', 'u')
          .replaceAll('ş', 's')
          .replaceAll('ö', 'o')
          .replaceAll('ç', 'c');
      // Remove any combining characters (e.g. combining dot above U+0307)
      s = s.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
      return s.trim();
    }

    final searchTerm = normalize(query);
    if (searchTerm.isEmpty) return [];

    // Search by Name (prefix match)
    final snapshotName = await _db
        .collection('medicines')
        .where('name_lowercase', isGreaterThanOrEqualTo: searchTerm)
        .where('name_lowercase', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .limit(25)
        .get();

    // Search by Generic Name (prefix match)
    final snapshotGeneric = await _db
        .collection('medicines')
        .where('generic_name_lowercase', isGreaterThanOrEqualTo: searchTerm)
        .where('generic_name_lowercase', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .limit(25)
        .get();

    final results = <String, Map<String, dynamic>>{};

    for (var doc in snapshotName.docs) {
      results[doc.id] = {...doc.data(), 'id': doc.id};
    }
    for (var doc in snapshotGeneric.docs) {
      results[doc.id] = {...doc.data(), 'id': doc.id};
    }

    return results.values.toList();
  }
}
