import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'team_join_result.dart';
import '../models/task_model.dart';
import '../models/team_model.dart';
import '../models/project_model.dart';
import '../models/activity_log_model.dart';
import '../services/notification_service.dart';
import 'base_firebase_service.dart';
import 'task_service.dart';

class TeamService extends BaseFirebaseService {
  static final TeamService _instance = TeamService._internal();
  factory TeamService() => _instance;
  TeamService._internal();

  /// Generates a cryptographically-random 8-char alphanumeric join code.
  /// Avoids ambiguous chars (0/O, 1/I) to ease manual entry.
  String _generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<String> createTeam(String teamName, {int color = 0xFF6366F1}) async {
    if (currentUserId == null) throw Exception('Giriş yapılmalı');
    final joinCode = _generateJoinCode();
    final docRef = db.collection('teams').doc();
    await docRef.set({
      'name': teamName,
      'ownerId': currentUserId,
      'memberIds': [currentUserId],
      'adminIds': [currentUserId],
      'joinCode': joinCode,
      'color': color,
      'createdAt': FieldValue.serverTimestamp(),
      'announcement': null,
    });
    await db.collection('users').doc(currentUserId).update({
      'joinedTeams': FieldValue.arrayUnion([docRef.id]),
    });
    await logTeamActivity(docRef.id, 'team_created', teamName);
    return joinCode;
  }

  /// Takım katılım kodunu yeniler — eski kod geçersiz hale gelir.
  Future<String?> regenerateJoinCode(String teamId) async {
    if (currentUserId == null) return null;
    if (await _requireTeamAdmin(teamId) == null) return null;
    try {
      final newCode = _generateJoinCode();
      await db.collection('teams').doc(teamId).update({'joinCode': newCode});
      await logTeamActivity(teamId, 'join_code_rotated',
          'Katılım kodu güncellendi');
      return newCode;
    } catch (e) {
      debugPrint('[TeamService.regenerateJoinCode] error: $e');
      return null;
    }
  }

  Future<JoinTeamResult> joinTeam(String code) async {
    if (currentUserId == null) return JoinTeamResult.error;
    final normalized = code.trim().toUpperCase();
    if (normalized.length < 6) return JoinTeamResult.invalidCode;
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('joinTeamByCode');
      final result = await callable.call<Map<String, dynamic>>({
        'code': normalized,
      });
      final teamId = result.data['teamId'] as String?;
      if (teamId == null) return JoinTeamResult.error;
      if (result.data['alreadyMember'] != true) {
        await logTeamActivity(
            teamId, 'member_joined', currentUser?.displayName ?? 'Üye',);
      }
      return JoinTeamResult.success;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[TeamService.joinTeam] ${e.code}: ${e.message}');
      if (e.code == 'not-found' || e.code == 'invalid-argument') {
        return JoinTeamResult.invalidCode;
      }
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        return JoinTeamResult.permissionDenied;
      }
      return JoinTeamResult.error;
    } catch (e) {
      debugPrint('[TeamService.joinTeam] error: $e');
      return JoinTeamResult.error;
    }
  }

  /// Legacy bool API for callers not yet migrated.
  Future<bool> joinTeamLegacy(String code) async =>
      (await joinTeam(code)) == JoinTeamResult.success;

  Stream<List<Team>> getUserTeamsStream() {
    if (currentUserId == null) return Stream.value([]);
    return db
        .collection('teams')
        .where('memberIds', arrayContains: currentUserId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Team.fromFirestore(d)).toList(),);
  }

  Stream<List<Task>> getTeamTasksStream(String teamId) =>
      TaskService().getTeamTasksStream(teamId);

  Future<void> addTeamLink(String teamId, String title, String url,
      {String? description, int? color,}) async {
    if (await _requireTeamAdmin(teamId) == null) return;
    await db.collection('teams').doc(teamId).collection('resources').add({
      'title': title,
      'url': url,
      'description': description,
      'color': color,
      'addedBy': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'link',
    });
    await logTeamActivity(teamId, 'added_link', title);
  }

  Future<void> updateTeamResource(
      String teamId, String resourceId, Map<String, dynamic> updates,) async {
    await db
        .collection('teams')
        .doc(teamId)
        .collection('resources')
        .doc(resourceId)
        .update(updates);
  }

  Stream<QuerySnapshot> getTeamResources(String teamId) {
    return db
        .collection('teams')
        .doc(teamId)
        .collection('resources')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteTeamResource(
      String teamId, String resourceId,) async {
    await db
        .collection('teams')
        .doc(teamId)
        .collection('resources')
        .doc(resourceId)
        .delete();
  }

  Future<void> updateTeamAnnouncement(
      String teamId, String message,) async {
    if (await _requireTeamAdmin(teamId) == null) return;
    await db.collection('teams').doc(teamId).update({
      'announcement': message,
      'announcementBy': currentUser?.displayName,
      'announcementDate': FieldValue.serverTimestamp(),
    });
    final teamDoc = await db.collection('teams').doc(teamId).get();
    final memberIds = List<String>.from(teamDoc.data()?['memberIds'] ?? []);
    await NotificationService().sendInAppNotificationToUsers(
      recipientIds: memberIds,
      title: 'Takım Duyurusu',
      body: message,
      type: 'team',
      targetId: teamId,
      targetType: 'team',
      icon: '📢',
      color: 0xFFFF5722,
    );
    if (currentUserId != null) {
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
  }

  Future<void> updateTeam(Team team) async {
    if (currentUserId == null) return;
    if (team.ownerId == currentUserId) {
      await db.collection('teams').doc(team.id).update({
        'name': team.name,
        'color': team.color,
      });
    }
  }

  Future<void> leaveTeam(String teamId) async {
    if (currentUserId == null) return;
    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('leaveTeam')
          .call({'teamId': teamId});
      await logTeamActivity(
          teamId, 'member_left', currentUser?.displayName ?? 'Üye',);
    } catch (e) {
      debugPrint('[TeamService.leaveTeam] $e');
      rethrow;
    }
  }

  Future<void> deleteTeam(String teamId) async {
    if (await _requireTeamOwner(teamId) == null) return;
    await db.collection('teams').doc(teamId).delete();
  }

  Future<void> kickMember(String teamId, String memberId) async {
    if (await _requireTeamAdmin(teamId) == null) return;
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('kickTeamMember');
      await callable.call<Map<String, dynamic>>({
        'teamId': teamId,
        'memberId': memberId,
      });
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[TeamService.kickMember] ${e.code}: ${e.message}');
      rethrow;
    }
  }

  Future<void> promoteToAdmin(String teamId, String memberId) async {
    if (await _requireTeamOwner(teamId) == null) return;
    await db.collection('teams').doc(teamId).update({
      'adminIds': FieldValue.arrayUnion([memberId]),
    });
  }

  Future<void> demoteFromAdmin(String teamId, String memberId) async {
    if (await _requireTeamOwner(teamId) == null) return;
    await db.collection('teams').doc(teamId).update({
      'adminIds': FieldValue.arrayRemove([memberId]),
    });
  }

  Stream<List<ActivityLog>> getTeamActivityLogs(String teamId) {
    return db
        .collection('activity_logs')
        .where('teamId', isEqualTo: teamId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ActivityLog.fromFirestore(d)).toList(),);
  }

  // ─── Projects ─────────────────────────────────────────────────────────────

  Future<String> createProject(String teamId, Project project) async {
    final doc = await db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .add(project.toMap());

    if (currentUserId != null) {
      final now = DateTime.now();
      // Add project task directly to avoid circular dependency with TaskService.
      await db.collection('tasks').add({
        'userId': currentUserId,
        'title': 'Proje: ${project.name}',
        'description':
            'Takım projesi başlatıldı. Detaylar ve alt görevler için projeyi inceleyin.\n${project.description}',
        'startTime': Timestamp.fromDate(now),
        'endTime': Timestamp.fromDate(
            project.deadline ?? now.add(const Duration(hours: 1)),),
        'color': project.color,
        'priority': 2,
        'groupId': doc.id,
        'teamId': teamId,
        'tags': ['Proje', project.name],
        'status': 'todo',
        'isCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return doc.id;
  }

  Stream<List<Project>> getProjectsStream(String teamId) {
    return db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => Project.fromFirestore(d)).toList(),);
  }

  Stream<Project> getProjectStream(String teamId, String projectId) {
    return db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .doc(projectId)
        .snapshots()
        .map((doc) => Project.fromFirestore(doc));
  }

  Future<void> addProjectResource(
      String teamId, String projectId, String title, String url,
      {String? description, int? color,}) async {
    await db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .doc(projectId)
        .collection('resources')
        .add({
      'title': title,
      'url': url,
      'description': description,
      'color': color,
      'addedBy': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProjectResource(String teamId, String projectId,
      String resourceId, Map<String, dynamic> updates,) async {
    await db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .doc(projectId)
        .collection('resources')
        .doc(resourceId)
        .update(updates);
  }

  Stream<QuerySnapshot> getProjectResources(
      String teamId, String projectId,) {
    return db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .doc(projectId)
        .collection('resources')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteProjectResource(
      String teamId, String projectId, String resourceId,) async {
    await db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .doc(projectId)
        .collection('resources')
        .doc(resourceId)
        .delete();
  }

  Future<void> updateProject(
      String teamId, String projectId, Map<String, dynamic> data,) async {
    await db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .doc(projectId)
        .update(data);
  }

  Future<void> deleteProject(String teamId, String projectId) async {
    if (await _requireTeamAdmin(teamId) == null) return;
    await db
        .collection('teams')
        .doc(teamId)
        .collection('projects')
        .doc(projectId)
        .delete();
  }

  Stream<List<Task>> getProjectTasksStream(
      String teamId, String projectId,) =>
      TaskService().getProjectTasksStream(teamId, projectId);

  /// Sets [teamId] on legacy project tasks via Cloud Function (team member).
  Future<void> backfillProjectTaskTeamIds(String teamId) async {
    if (currentUserId == null) return;
    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('backfillTeamTaskTeamIds')
          .call({'teamId': teamId});
    } catch (e) {
      debugPrint('[TeamService.backfillProjectTaskTeamIds] $e');
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _requireTeamAdmin(String teamId) async {
    if (currentUserId == null) return null;
    final doc = await db.collection('teams').doc(teamId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    final isOwner = data['ownerId'] == currentUserId;
    final isAdmin =
        (data['adminIds'] as List<dynamic>? ?? []).contains(currentUserId);
    return (isOwner || isAdmin) ? data : null;
  }

  Future<Map<String, dynamic>?> _requireTeamOwner(String teamId) async {
    if (currentUserId == null) return null;
    final doc = await db.collection('teams').doc(teamId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return data['ownerId'] == currentUserId ? data : null;
  }
}
