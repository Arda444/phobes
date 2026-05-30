import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import '../models/survey_model.dart';

class AdminService {
  static final _db = FirebaseFirestore.instance;

  // ─── Audit Logs ───────────────────────────────────────────────────────────

  static Future<void> logAudit({
    required String action,
    String? detail,
    bool success = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[AdminService.logAudit] skipped — no authenticated user');
      return;
    }
    try {
      await _db.collection('auditLogs').add({
        'action': action,
        'detail': detail ?? '',
        'adminUid': user.uid,
        'adminEmail': user.email ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'success': success,
      });
    } catch (e, s) {
      if (!kDebugMode) {
        FirebaseCrashlytics.instance
            .recordError(e, s, information: ['action: $action']);
      }
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> auditLogsStream() =>
      _db
          .collection('auditLogs')
          .orderBy('timestamp', descending: true)
          .limit(200)
          .snapshots();

  // ─── App Config ───────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAppConfig() async {
    final doc = await _db.collection('appConfig').doc('main').get();
    return doc.data() ?? {};
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> appConfigStream() =>
      _db.collection('appConfig').doc('main').snapshots();

  static Future<void> setMaintenanceMode(bool enabled, String message) async {
    await _db.collection('appConfig').doc('main').set({
      'maintenanceMode': enabled,
      'maintenanceMessage': message,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await logAudit(
      action: enabled ? 'Bakım modu açıldı' : 'Bakım modu kapatıldı',
      detail: message,
    );
  }

  static Future<void> setAnnouncement({
    required bool enabled,
    required String title,
    required String message,
    String type = 'info',
  }) async {
    await _db.collection('appConfig').doc('main').set({
      'announcement': enabled
          ? {
              'enabled': true,
              'title': title,
              'message': message,
              'type': type,
              'updatedAt': FieldValue.serverTimestamp(),
            }
          : {'enabled': false},
    }, SetOptions(merge: true));
    await logAudit(
      action: enabled ? 'Duyuru bandı yayınlandı' : 'Duyuru bandı kaldırıldı',
      detail: enabled ? '$title: $message' : null,
    );
  }

  // ─── Broadcasts (one-time popup) ──────────────────────────────────────────

  static Stream<QuerySnapshot<Map<String, dynamic>>> broadcastsStream() =>
      _db
          .collection('broadcasts')
          .orderBy('createdAt', descending: true)
          .snapshots();

  static Future<String> publishBroadcast({
    required String title,
    required String message,
    String type = 'info',
  }) async {
    final ref = await _db.collection('broadcasts').add({
      'title': title,
      'message': message,
      'type': type,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await logAudit(action: 'Popup duyuru yayınlandı', detail: title);
    return ref.id;
  }

  static Future<void> deactivateBroadcast(String id, String title) async {
    await _db.collection('broadcasts').doc(id).update({'active': false});
    await logAudit(action: 'Popup duyuru pasifleştirildi', detail: title);
  }

  // ─── Notification Templates ───────────────────────────────────────────────

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      notificationTemplatesStream() =>
          _db
              .collection('notificationTemplates')
              .orderBy('createdAt', descending: true)
              .snapshots();

  static Future<void> addNotificationTemplate({
    required String title,
    required String body,
    required String target,
  }) async {
    await _db.collection('notificationTemplates').add({
      'title': title,
      'body': body,
      'target': target,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await logAudit(action: 'Bildirim şablonu eklendi', detail: title);
  }

  static Future<void> updateNotificationTemplate(
    String id,
    String title,
    String body,
    String target,
  ) async {
    await _db.collection('notificationTemplates').doc(id).update({
      'title': title,
      'body': body,
      'target': target,
    });
    await logAudit(action: 'Bildirim şablonu güncellendi', detail: title);
  }

  static Future<void> deleteNotificationTemplate(String id, String title) async {
    await _db.collection('notificationTemplates').doc(id).delete();
    await logAudit(action: 'Bildirim şablonu silindi', detail: title);
  }

  // ─── Blacklist ─────────────────────────────────────────────────────────────

  static Stream<QuerySnapshot<Map<String, dynamic>>> blacklistStream() =>
      _db
          .collection('blacklist')
          .orderBy('addedAt', descending: true)
          .snapshots();

  static Future<void> addBlacklist({
    required String type,
    required String value,
    required String reason,
  }) async {
    await _db.collection('blacklist').add({
      'type': type,
      'value': value,
      'reason': reason,
      'addedAt': FieldValue.serverTimestamp(),
      'addedBy': FirebaseAuth.instance.currentUser?.email ?? '',
    });
    await logAudit(action: 'Kara listeye eklendi', detail: '$type: $value');
  }

  static Future<void> deleteBlacklist(String id, String value) async {
    await _db.collection('blacklist').doc(id).delete();
    await logAudit(action: 'Kara listeden çıkarıldı', detail: value);
  }

  // ─── Version Management ───────────────────────────────────────────────────

  static Stream<QuerySnapshot<Map<String, dynamic>>> versionsStream() =>
      _db
          .collection('appVersions')
          .orderBy('releasedAt', descending: true)
          .snapshots();

  static Future<void> publishVersion({
    required String version,
    required bool forceUpdate,
    required String notes,
  }) async {
    final batch = _db.batch();
    final vRef = _db.collection('appVersions').doc();
    batch.set(vRef, {
      'version': version,
      'forceUpdate': forceUpdate,
      'notes': notes,
      'releasedAt': FieldValue.serverTimestamp(),
      'publishedBy': FirebaseAuth.instance.currentUser?.email ?? '',
    });
    batch.set(
      _db.collection('appConfig').doc('main'),
      {
        'currentVersion': version,
        'forceUpdate': forceUpdate,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
    await logAudit(
      action: 'Versiyon yayınlandı',
      detail: '$version (zorunlu güncelleme: $forceUpdate)',
    );
  }

  // ─── Feedback ─────────────────────────────────────────────────────────────

  static Stream<QuerySnapshot<Map<String, dynamic>>> feedbackStream() =>
      _db
          .collection('feedback')
          .orderBy('createdAt', descending: true)
          .snapshots();

  static Future<void> replyFeedback(String id, String reply) async {
    await _db.collection('feedback').doc(id).update({
      'adminReply': reply,
      'status': 'closed',
      'repliedAt': FieldValue.serverTimestamp(),
    });
    await logAudit(action: 'Geri bildirime yanıt verildi', detail: id);
  }

  static Future<void> closeFeedback(String id) async {
    await _db.collection('feedback').doc(id).update({'status': 'closed'});
    await logAudit(action: 'Geri bildirim kapatıldı', detail: id);
  }

  // ─── Surveys ──────────────────────────────────────────────────────────────

  static Stream<QuerySnapshot<Map<String, dynamic>>> surveysStream() =>
      _db
          .collection('surveys')
          .orderBy('createdAt', descending: true)
          .snapshots();

  static Future<String> createSurvey({
    required String title,
    required String description,
    required List<SurveyQuestion> questions,
  }) async {
    final ref = await _db.collection('surveys').add({
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'status': 'draft',
      'responseCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await logAudit(action: 'Anket oluşturuldu', detail: title);
    return ref.id;
  }

  static Future<void> publishSurvey(String id, String title) async {
    await _db.collection('surveys').doc(id).update({
      'status': 'active',
      'publishedAt': FieldValue.serverTimestamp(),
    });
    await notifyAllUsersInApp(
      title: 'Yeni anket: $title',
      body: 'Katılmak için bildirimlere bakın.',
      type: 'survey',
      targetId: id,
    );
    await logAudit(action: 'Anket yayınlandı', detail: title);
  }

  static Future<void> stopSurvey(String id, String title) async {
    await _db.collection('surveys').doc(id).update({'status': 'stopped'});
    await logAudit(action: 'Anket durduruldu', detail: title);
  }

  static Future<void> deleteSurvey(String id, String title) async {
    await _db.collection('surveys').doc(id).delete();
    await logAudit(action: 'Anket silindi', detail: title);
  }

  static Future<SurveyModel?> getSurvey(String id) async {
    final doc = await _db.collection('surveys').doc(id).get();
    if (!doc.exists) return null;
    return SurveyModel.fromFirestore(doc);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> surveyResponsesStream(
    String surveyId,
  ) =>
      _db
          .collection('surveyResponses')
          .doc(surveyId)
          .collection('responses')
          .snapshots();

  // ─── Data Cleanup ─────────────────────────────────────────────────────────

  static Future<int> deleteOldDocuments(
    String collection,
    DateTime before,
  ) async {
    String timeField = 'createdAt';
    if (collection == 'auditLogs' || collection == 'activityLogs') {
      timeField = 'timestamp';
    } else if (collection == 'blacklist') {
      timeField = 'addedAt';
    } else if (collection == 'appVersions') {
      timeField = 'releasedAt';
    }

    final snap = await _db
        .collection(collection)
        .where(timeField, isLessThan: Timestamp.fromDate(before))
        .limit(500)
        .get();

    if (snap.docs.isEmpty) return 0;

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    await logAudit(
      action: 'Veri temizleme yapıldı',
      detail:
          '$collection: ${snap.docs.length} kayıt silindi (< ${before.toIso8601String()})',
    );
    return snap.docs.length;
  }

  static Future<void> cleanupOldLogs({int days = 30}) async {
    await deleteOldDocuments(
      'auditLogs',
      DateTime.now().subtract(Duration(days: days)),
    );
    await deleteOldDocuments(
      'activityLogs',
      DateTime.now().subtract(Duration(days: days)),
    );
  }

  // ─── Dashboard / Analytics Stats ────────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = Timestamp.fromDate(now.subtract(const Duration(days: 7)));
      final thirtyDaysAgo =
          Timestamp.fromDate(now.subtract(const Duration(days: 30)));

      final results = await Future.wait([
        _db.collection('users').count().get(),
        _db.collection('users').where('banned', isEqualTo: true).count().get(),
        _db.collection('feedback').where('status', isEqualTo: 'open').count().get(),
        _db.collection('surveys').where('status', isEqualTo: 'active').count().get(),
        _db.collection('users')
            .where('createdAt', isGreaterThan: sevenDaysAgo)
            .count()
            .get(),
        _db.collection('users')
            .where('lastLogin', isGreaterThan: sevenDaysAgo)
            .count()
            .get(),
        _db.collection('users')
            .where('createdAt', isGreaterThan: thirtyDaysAgo)
            .count()
            .get(),
      ]);

      return {
        'totalUsers': results[0].count,
        'bannedUsers': results[1].count,
        'openFeedback': results[2].count,
        'activeSurveys': results[3].count,
        'newUsers7d': results[4].count,
        'activeUsers7d': results[5].count,
        'newUsers30d': results[6].count,
      };
    } catch (e) {
      debugPrint('[AdminService.getDashboardStats] $e');
      return {
        'totalUsers': 0,
        'bannedUsers': 0,
        'openFeedback': 0,
        'activeSurveys': 0,
        'newUsers7d': 0,
        'activeUsers7d': 0,
        'newUsers30d': 0,
      };
    }
  }

  static Future<List<int>> getLoginCountsLast7Days() async {
    final counts = List<int>.filled(7, 0);
    try {
      final start = DateTime.now().subtract(const Duration(days: 6));
      final startTs = Timestamp.fromDate(
        DateTime(start.year, start.month, start.day),
      );
      final snap = await _db
          .collection('activityLogs')
          .where('action', isEqualTo: 'login')
          .where('timestamp', isGreaterThan: startTs)
          .get();
      final today = DateTime.now();
      for (final doc in snap.docs) {
        final ts = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        if (ts == null) continue;
        final dayIndex = today.difference(
          DateTime(ts.year, ts.month, ts.day),
        ).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          counts[6 - dayIndex]++;
        }
      }
    } catch (e) {
      debugPrint('[AdminService.getLoginCountsLast7Days] $e');
    }
    return counts;
  }

  // ─── User Management ─────────────────────────────────────────────────────

  static Future<void> updateUserStatus(String uid, {bool? banned, String? role}) async {
    final data = <String, dynamic>{};
    if (banned != null) data['banned'] = banned;
    if (role != null) data['role'] = role;
    if (data.isEmpty) return;

    await _db.collection('users').doc(uid).update(data);

    var detail = '';
    if (banned != null) {
      detail += 'Ban: ${banned ? "evet" : "hayır"}. ';
    }
    if (role != null) detail += 'Rol: $role.';
    await logAudit(action: 'Kullanıcı güncellendi', detail: 'UID: $uid. $detail');
  }

  /// Firestore role (Spark plan — Cloud Functions not required).
  static Future<void> setAdminRole(String targetUid, bool isAdmin) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == targetUid && !isAdmin) {
      throw StateError('Kendi admin yetkinizi kaldıramazsınız.');
    }
    await updateUserStatus(
      targetUid,
      role: isAdmin ? 'Admin' : 'User',
    );
    await logAudit(
      action: isAdmin ? 'Admin yetkisi verildi' : 'Admin yetkisi alındı',
      detail: targetUid,
    );
  }

  static Future<void> addIpBan(String ip, String reason) async {
    await addBlacklist(type: 'ip', value: ip, reason: reason);
  }

  // ─── Session Monitoring ───────────────────────────────────────────────────

  static Stream<QuerySnapshot<Map<String, dynamic>>> sessionsStream() =>
      _db
          .collection('activityLogs')
          .where('action', isEqualTo: 'login')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots();

  // ─── Push Messaging ───────────────────────────────────────────────────────

  /// In-app bildirim (tüm kullanıcılara) — Blaze / FCM gerekmez.
  static Future<int> notifyAllUsersInApp({
    required String title,
    required String body,
    required String type,
    String? targetId,
    String? targetType,
  }) async {
    final users = await _db.collection('users').limit(500).get();
    if (users.docs.isEmpty) return 0;

    var batch = _db.batch();
    var ops = 0;
    var sent = 0;

    for (final user in users.docs) {
      final ref = _db
          .collection('users')
          .doc(user.id)
          .collection('notifications')
          .doc();
      batch.set(ref, {
        'userId': user.id,
        'title': title,
        'body': body,
        'type': type,
        if (targetId != null) 'targetId': targetId,
        if (targetType != null) 'targetType': targetType,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'icon': type == 'survey' ? '📊' : '🔔',
        'color': 0xFF6C63FF,
      });
      ops++;
      sent++;
      if (ops >= 400) {
        await batch.commit();
        batch = _db.batch();
        ops = 0;
      }
    }
    if (ops > 0) await batch.commit();

    await logAudit(
      action: 'Uygulama içi bildirim gönderildi',
      detail: '$title ($sent kullanıcı)',
    );
    return sent;
  }

  /// FCM via [adminSendPush] when token/topic set; otherwise in-app batch.
  static Future<int> sendPushNotification({
    String? topic,
    String? token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final hasFcmTarget =
        (token != null && token.trim().isNotEmpty) ||
        (topic != null && topic.trim().isNotEmpty);
    if (hasFcmTarget) {
      try {
        await FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('adminSendPush')
            .call<Map<String, dynamic>>({
          'title': title,
          'body': body,
          if (token != null && token.trim().isNotEmpty) 'token': token.trim(),
          if (topic != null && topic.trim().isNotEmpty) 'topic': topic.trim(),
          if (data != null) 'data': data,
        });
        await logAudit(
          action: 'FCM push gönderildi',
          detail: title,
        );
        return 1;
      } catch (e) {
        debugPrint('[AdminService.sendPushNotification] FCM: $e');
        rethrow;
      }
    }
    return notifyAllUsersInApp(
      title: title,
      body: body,
      type: data?['type'] ?? 'admin',
      targetId: data?['surveyId'] ?? data?['broadcastId'],
    );
  }
}
