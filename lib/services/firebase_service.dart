import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // debugPrint için
import 'dart:math';
import '../models/task_model.dart';
import '../models/note_model.dart';
import '../models/team_model.dart';
import '../models/activity_log_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String? get currentUserId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

  // ==================================================
  // 1. AUTH (KİMLİK DOĞRULAMA)
  // ==================================================

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
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // --- KULLANICI VERİLERİ ---

  Future<void> _saveUserToFirestore(
      User user, String name, String surname, DateTime birthDate) async {
    await _db.collection('users').doc(user.uid).set({
      'email': user.email,
      'name': name,
      'surname': surname,
      'birthDate': Timestamp.fromDate(birthDate),
      'createdAt': FieldValue.serverTimestamp(),
      'joinedTeams': [],
      'xp': 0, // Oyunlaştırma
      'level': 1, // Oyunlaştırma
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

  // --- AVATAR GÜNCELLEME ---
  Future<void> updateAvatar(String avatarSeed) async {
    if (currentUserId == null) return;

    // DiceBear Adventurer kullanıyoruz
    final String avatarUrl =
        "https://api.dicebear.com/9.x/adventurer/png?seed=$avatarSeed";

    // 1. Veritabanını güncelle
    await _db.collection('users').doc(currentUserId).update({
      'photoUrl': avatarUrl,
    });

    // 2. Auth profilini güncelle
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

  // ==================================================
  // 2. OYUNLAŞTIRMA (XP & LEVEL)
  // ==================================================

  Future<void> addXP(int amount) async {
    if (currentUserId == null) return;
    final userRef = _db.collection('users').doc(currentUserId);

    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;

        int currentXp = snapshot.data()?['xp'] ?? 0;
        int newXp = currentXp + amount;
        int newLevel = (newXp / 1000).floor() + 1; // Her 1000 XP'de level atla

        transaction.update(userRef, {'xp': newXp, 'level': newLevel});
      });
    } catch (e) {
      debugPrint("XP ekleme hatası: $e");
    }
  }

  // ==================================================
  // 3. ALIŞKANLIKLAR (HABITS)
  // ==================================================

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
      await addXP(20); // Ödül
    } else {
      // Geri alma mantığı
    }
  }

  Future<void> deleteHabit(String habitId) async {
    await _db.collection('habits').doc(habitId).delete();
  }

  // ==================================================
  // 4. GÖREV (TASK) İŞLEMLERİ
  // ==================================================

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
    final DateTime startDate =
        DateTime.now().subtract(const Duration(days: 365));
    final DateTime endDate = DateTime.now().add(const Duration(days: 30));

    try {
      final snapshot = await _db
          .collection('tasks')
          .where('userId', isEqualTo: currentUserId)
          .where('groupId', isNull: true)
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .limit(2000)
          .get();
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<Task>> getTasksStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: currentUserId)
        .where('groupId', isNull: true)
        .snapshots()
        .map((snapshot) {
      final tasks =
          snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
      tasks.sort((a, b) => a.startTime.compareTo(b.startTime));
      return tasks;
    });
  }

  Stream<List<Task>> getAllUserTasksStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('tasks')
        .where(Filter.or(
          Filter('userId', isEqualTo: currentUserId),
          Filter('assignedTo', isEqualTo: currentUserId),
        ))
        .snapshots()
        .map((snapshot) {
      final tasks =
          snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
      tasks.sort((a, b) => a.startTime.compareTo(b.startTime));
      return tasks;
    });
  }

  Future<void> updateTask(Task task) async {
    if (task.id != null) {
      await _db.collection('tasks').doc(task.id).update(task.toMap());

      if (task.isCompleted) {
        if (task.groupId != null) {
          await logTeamActivity(task.groupId!, 'task_completed', task.title);
        }
        await addXP(50); // Ödül
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }

  // ==================================================
  // 5. NOT (NOTE) İŞLEMLERİ
  // ==================================================

  Future<void> addNote(Note note) async {
    if (currentUserId == null) return;
    final noteMap = note.toMap();
    noteMap['userId'] = currentUserId;
    await _db.collection('notes').add(noteMap);
  }

  Stream<List<Note>> getNotesStream() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('notes')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      final notes =
          snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
      notes.sort((a, b) => b.date.compareTo(a.date));
      return notes;
    });
  }

  Future<void> updateNote(Note note) async {
    if (note.id != null) {
      await _db.collection('notes').doc(note.id).update(note.toMap());
    }
  }

  Future<void> deleteNote(String noteId) async {
    await _db.collection('notes').doc(noteId).delete();
  }

  // ==================================================
  // 6. EKİP (TEAM) İŞLEMLERİ
  // ==================================================

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

  // --- AKTİVİTE LOGLARI ---

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

  // --- YÖNETİM & TEST ---

  Future<void> deleteAllData() async {
    if (currentUserId == null) return;

    // Düzeltilmiş for döngüleri (Süslü parantez eklendi)
    final tasks = await _db
        .collection('tasks')
        .where('userId', isEqualTo: currentUserId)
        .get();
    for (var doc in tasks.docs) {
      await doc.reference.delete();
    }

    final notes = await _db
        .collection('notes')
        .where('userId', isEqualTo: currentUserId)
        .get();
    for (var doc in notes.docs) {
      await doc.reference.delete();
    }

    final habits = await _db
        .collection('habits')
        .where('userId', isEqualTo: currentUserId)
        .get();
    for (var doc in habits.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> generateSimulationData() async {
    // Test verisi
  }
}
