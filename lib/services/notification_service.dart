import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      try {
        final timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));
      } catch (e) {
        debugPrint("Timezone ayarlanamadı: $e");
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String channelId = 'tasks',
    String channelName = 'Görevler',
  }) async {
    if (kIsWeb || Platform.isWindows || Platform.isLinux) {
      debugPrint('Zamanlanmış bildirimler bu platformda desteklenmiyor.');
      return;
    }

    if (scheduledTime.isBefore(DateTime.now())) return;

    int notificationId = id.hashCode;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: '$channelName hatırlatıcıları',
          importance: Importance.max,
          priority: Priority.high,
          color: const Color(0xFF7B1FA2),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(String id) async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancel(id.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> showInstantNotification(String title, String body) async {
    if (kIsWeb) return;
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails('instant_channel', 'Anlık Bildirimler',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon');
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, details);
  }

  /// Unified notification: saves to Firestore (in-app) on ALL platforms,
  /// AND shows local push on Android/iOS.
  Future<void> sendNotification({
    required String title,
    required String body,
    required String type,
    String? targetId,
    String? targetType,
    String icon = '🔔',
    int color = 0xFF6C63FF,
    String? prefKey,
  }) async {
    // Check user preference if a prefKey is provided
    if (prefKey != null) {
      final sp = await SharedPreferences.getInstance();
      final enabled = sp.getBool(prefKey) ?? true;
      if (!enabled) return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // 1) Always save to Firestore (in-app notification for ALL platforms)
    final notif = AppNotification(
      userId: userId,
      title: title,
      body: body,
      type: type,
      targetId: targetId,
      targetType: targetType,
      icon: icon,
      color: color,
    );
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notif.toMap());
    } catch (e) {
      debugPrint('Firestore bildirim kaydetme hatası: $e');
    }

    // 2) On Android/iOS, also show a local push notification
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final channelId = _channelIdForType(type);
        final channelName = _channelNameForType(type);
        await flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: '$channelName bildirimleri',
              importance: Importance.max,
              priority: Priority.high,
              color: Color(color),
              icon: '@mipmap/launcher_icon',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Local push bildirim hatası: $e');
      }
    }
  }

  /// Schedule a notification AND save to Firestore when the time comes.
  /// This wraps the existing scheduleNotification and also saves to Firestore.
  Future<void> scheduleAndSaveNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String type,
    String? targetId,
    String? targetType,
    String icon = '🔔',
    int color = 0xFF6C63FF,
    String channelId = 'tasks',
    String channelName = 'Görevler',
    String? prefKey,
  }) async {
    // Check user preference
    if (prefKey != null) {
      final sp = await SharedPreferences.getInstance();
      final enabled = sp.getBool(prefKey) ?? true;
      if (!enabled) return;
    }

    // Schedule the local push notification (Android/iOS only)
    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      channelId: channelId,
      channelName: channelName,
    );

    // Save to Firestore immediately so it shows in in-app notifications
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final notif = AppNotification(
      userId: userId,
      title: title,
      body: body,
      type: type,
      targetId: targetId,
      targetType: targetType,
      icon: icon,
      color: color,
      createdAt: scheduledTime,
    );
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notif.toMap());
    } catch (e) {
      debugPrint('Firestore zamanlanmış bildirim kaydetme hatası: $e');
    }
  }

  String _channelIdForType(String type) {
    switch (type) {
      case 'task':
        return 'tasks';
      case 'medication':
        return 'medications';
      case 'appointment':
        return 'appointments';
      case 'habit':
        return 'habits';
      case 'focus':
        return 'focus';
      case 'team':
        return 'teams';
      default:
        return 'general';
    }
  }

  String _channelNameForType(String type) {
    switch (type) {
      case 'task':
        return 'Görevler';
      case 'medication':
        return 'İlaçlar';
      case 'appointment':
        return 'Randevular';
      case 'habit':
        return 'Alışkanlıklar';
      case 'focus':
        return 'Odaklanma';
      case 'team':
        return 'Takımlar';
      default:
        return 'Genel';
    }
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    if (kIsWeb || Platform.isWindows || Platform.isLinux) {
      debugPrint('Zamanlanmış bildirimler bu platformda desteklenmiyor.');
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_briefing',
          'Günlük Özet',
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
