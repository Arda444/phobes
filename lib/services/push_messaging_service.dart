import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

/// Global handler for notification taps (survey / broadcast deep links).
typedef PushTapHandler = void Function(Map<String, dynamic> data);

class PushMessagingService {
  PushMessagingService._();
  static final PushMessagingService instance = PushMessagingService._();

  static PushTapHandler? onNotificationTap;

  bool _initialized = false;

  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      await messaging.subscribeToTopic('all_users');

      final token = await messaging.getToken();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (token != null && uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set(
          {'fcmToken': token},
          SetOptions(merge: true),
        );
      }

      messaging.onTokenRefresh.listen((newToken) async {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) return;
        await FirebaseFirestore.instance.collection('users').doc(userId).set(
          {'fcmToken': newToken},
          SetOptions(merge: true),
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        onNotificationTap?.call(Map<String, dynamic>.from(message.data));
      });

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        onNotificationTap?.call(Map<String, dynamic>.from(initial.data));
      }
    } catch (e) {
      debugPrint('[PushMessagingService] init error: $e');
    }
  }
}
