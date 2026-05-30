import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../services/notification_service.dart';

abstract class BaseFirebaseService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  String? get currentUserId => auth.currentUser?.uid;
  User? get currentUser => auth.currentUser;

  Future<void> logTeamActivity(
      String teamId, String action, String details,) async {
    if (currentUserId == null) return;
    try {
      await db.collection('activity_logs').add({
        'teamId': teamId,
        'userId': currentUserId,
        'userName': currentUser?.displayName ?? 'Bilinmeyen',
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e, s) {
      debugPrint('Log hatası: $e');
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(e, s,
            information: ['activityLog teamId=$teamId action=$action'],);
      }
    }
  }

  Future<void> addXP(
    int amount, {
    String? taskId,
    String? reason,
    String? localizedLevelUpTitle,
    String? localizedLevelUpBody,
  }) async {
    if (currentUserId == null || amount <= 0) return;
    try {
      final userRef = db.collection('users').doc(currentUserId);
      final before = await userRef.get();
      final int currentXp =
          before.exists ? (before.data()?['xp'] as int? ?? 0) : 0;
      final int currentLevel = (currentXp / 1000).floor() + 1;

      final payload = <String, dynamic>{'amount': amount};
      if (taskId != null) payload['taskId'] = taskId;
      if (reason != null) payload['reason'] = reason;

      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('addUserXp');
      final result =
          await callable.call<Map<String, dynamic>>(payload);
      final newLevel = (result.data['level'] as num?)?.toInt() ?? currentLevel;

      if (newLevel > currentLevel) {
        await NotificationService().sendNotification(
          title: localizedLevelUpTitle ?? 'Level Up! 🎉',
          body: localizedLevelUpBody?.replaceAll('$newLevel', newLevel.toString()) ??
              'Congratulations! You reached level $newLevel!',
          type: 'system',
          icon: '⭐',
          color: 0xFFFFD600,
          prefKey: 'notif_level_up',
        );
      }
    } catch (e, s) {
      debugPrint('XP ekleme hatası: $e');
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(e, s, information: ['addXP amount=$amount'],);
      }
    }
  }
}
