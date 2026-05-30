import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/l10n_lookup.dart';
import '../l10n/app_localizations.dart';
import '../models/app_notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<String> _resolveLanguageCode([String? languageCode]) async {
    if (languageCode != null) return effectiveLanguageCode(languageCode);
    final prefs = await SharedPreferences.getInstance();
    return effectiveLanguageCode(prefs.getString('language_code'));
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // flutter_local_notifications is not supported on web; init can hang or
    // throw on mobile browsers and block bootstrap before the first frame.
    if (kIsWeb) return;

    // tz.initializeTimeZones() is called in main() before runApp() to avoid
    // blocking the render isolate mid-frame.
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      try {
        final rawName = (await FlutterTimezone.getLocalTimezone()).toString();
        final tzName = _normalizeTimezone(rawName);
        tz.setLocalLocation(tz.getLocation(tzName));
      } catch (e) {
        debugPrint('Timezone ayarlanamadı: $e');
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Some Android ROMs return "TimezoneInfo(GMT+3:00)" instead of an IANA name.
  /// Maps to the nearest Etc/GMT-X offset zone so tz.getLocation() won't throw.
  String _normalizeTimezone(String raw) {
    if (!raw.startsWith('TimezoneInfo(')) return raw;
    final inner = raw.substring(13, raw.length - 1);
    final match = RegExp(r'GMT([+-]\d{1,2})').firstMatch(inner);
    if (match == null) return 'UTC';
    final offset = int.tryParse(match.group(1)!) ?? 0;
    // IANA Etc/GMT uses the inverted sign convention (GMT+3 → Etc/GMT-3).
    return 'Etc/GMT${offset > 0 ? '-' : '+'}${offset.abs()}';
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;

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
    String? channelName,
    String? languageCode,
  }) async {
    if (kIsWeb || Platform.isWindows || Platform.isLinux) {
      debugPrint('Zamanlanmış bildirimler bu platformda desteklenmiyor.');
      return;
    }

    if (scheduledTime.isBefore(DateTime.now())) return;

    final lang = await _resolveLanguageCode(languageCode);
    final l = l10nFor(lang);
    final resolvedChannelName = channelName ?? l.notifChannelTasks;

    final int notificationId = id.hashCode;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          resolvedChannelName,
          channelDescription: l.notifChannelDescription(resolvedChannelName),
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

  Future<void> showInstantNotification(
    String title,
    String body, {
    String? languageCode,
  }) async {
    if (kIsWeb) return;
    final lang = await _resolveLanguageCode(languageCode);
    final l = l10nFor(lang);
    final androidDetails = AndroidNotificationDetails(
      'instant_channel',
      l.notifChannelInstant,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    final details = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, details);
  }

  static bool _cleanupDone = false;

  /// Deletes in-app notification docs older than 30 days for the current user.
  /// Called lazily on first sendNotification() per session.
  Future<void> cleanupOldNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final cutoff = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 30)),);
      final old = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('createdAt', isLessThan: cutoff)
          .get();
      if (old.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in old.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('Cleaned up ${old.docs.length} old notifications.');
    } catch (e) {
      debugPrint('Notification cleanup error: $e');
    }
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
    String? languageCode,
  }) async {

    if (prefKey != null) {
      final sp = await SharedPreferences.getInstance();
      final enabled = sp.getBool(prefKey) ?? true;
      if (!enabled) return;
    }

    // Lazy one-time cleanup of notifications older than 30 days.
    if (!_cleanupDone) {
      _cleanupDone = true;
      cleanupOldNotifications().catchError((e) => debugPrint('cleanup: $e'));
    }

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

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final lang = await _resolveLanguageCode(languageCode);
        final l = l10nFor(lang);
        final channelId = _channelIdForType(type);
        final channelName = _channelNameForType(type, l);
        await flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch.hashCode.abs(),
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: l.notifChannelDescription(channelName),
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

  /// Writes in-app notifications to other users (team announcements, etc.).
  Future<void> sendInAppNotificationToUsers({
    required List<String> recipientIds,
    required String title,
    required String body,
    required String type,
    String? targetId,
    String? targetType,
    String icon = '🔔',
    int color = 0xFF6C63FF,
  }) async {
    final senderId = FirebaseAuth.instance.currentUser?.uid;
    if (senderId == null || recipientIds.isEmpty) return;

    var batch = FirebaseFirestore.instance.batch();
    var ops = 0;
    for (final uid in recipientIds) {
      if (uid == senderId) continue;
      final notif = AppNotification(
        userId: uid,
        title: title,
        body: body,
        type: type,
        targetId: targetId,
        targetType: targetType,
        icon: icon,
        color: color,
      );
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc();
      batch.set(ref, notif.toMap());
      ops++;
      if (ops >= 400) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        ops = 0;
      }
    }
    if (ops > 0) await batch.commit();
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
    String? channelName,
    String? prefKey,
    String? languageCode,
  }) async {

    if (prefKey != null) {
      final sp = await SharedPreferences.getInstance();
      final enabled = sp.getBool(prefKey) ?? true;
      if (!enabled) return;
    }

    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      channelId: channelId,
      channelName: channelName,
      languageCode: languageCode,
    );

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

  String _channelNameForType(String type, AppLocalizations l) {
    switch (type) {
      case 'task':
        return l.notifChannelTasks;
      case 'medication':
        return l.notifChannelMedications;
      case 'appointment':
        return l.notifChannelAppointments;
      case 'habit':
        return l.notifChannelHabits;
      case 'focus':
        return l.notifChannelFocus;
      case 'team':
        return l.notifChannelTeams;
      default:
        return l.notifChannelGeneral;
    }
  }

  /// Per-habit günlük hatırlatıcı — her gün belirlenen saatte çalar.
  Future<void> scheduleDailyHabitReminder({
    required String habitId,
    required String habitName,
    required TimeOfDay time,
    String? languageCode,
  }) async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final lang = await _resolveLanguageCode(languageCode);
    final l = l10nFor(lang);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute,);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      'habit_$habitId'.hashCode,
      l.notifHabitReminderTitle,
      l.notifHabitReminderBody(habitName),
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'habits',
          l.notifChannelHabits,
          channelDescription: l.notifChannelDescription(l.notifChannelHabits),
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF4CAF50),
          icon: '@mipmap/launcher_icon',
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
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Per-medication günlük doz hatırlatıcısı — her gün belirlenen saatte çalar.
  Future<void> scheduleDailyMedicationReminder({
    required String medId,
    required String medName,
    required String timeSlot,
    required TimeOfDay time,
    String? languageCode,
  }) async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final lang = await _resolveLanguageCode(languageCode);
    final l = l10nFor(lang);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final id = 'med_${medId}_${timeSlot.replaceAll(':', '_')}';

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id.hashCode,
      l.notifMedicationTitle,
      l.notifMedicationBody(medName),
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medications',
          l.notifChannelMedications,
          channelDescription: l.notifChannelDescription(l.notifChannelMedications),
          importance: Importance.max,
          priority: Priority.high,
          color: const Color(0xFF009688),
          icon: '@mipmap/launcher_icon',
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
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── In-app (Firestore) notification CRUD ──────────────────────────────────

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;
  String get _notifCol => 'users/$_currentUserId/notifications';

  Future<void> addAppNotification(AppNotification notif) async {
    if (_currentUserId == null) return;
    await FirebaseFirestore.instance.collection(_notifCol).add(notif.toMap());
  }

  Stream<List<AppNotification>> getNotificationsStream() {
    if (_currentUserId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection(_notifCol)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppNotification.fromMap(d.data(), d.id)).toList(),);
  }

  Stream<int> getUnreadNotificationCount() {
    if (_currentUserId == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection(_notifCol)
        .where('isRead', isEqualTo: false)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markNotificationRead(String notifId) async {
    if (_currentUserId == null) return;
    await FirebaseFirestore.instance
        .collection(_notifCol)
        .doc(notifId)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsRead() async {
    if (_currentUserId == null) return;
    final db = FirebaseFirestore.instance;
    final unread = await db
        .collection(_notifCol)
        .where('isRead', isEqualTo: false)
        .get();
    const batchLimit = 400;
    var batch = db.batch();
    var ops = 0;
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
      ops++;
      if (ops >= batchLimit) {
        await batch.commit();
        batch = db.batch();
        ops = 0;
      }
    }
    if (ops > 0) await batch.commit();
  }

  Future<void> deleteOldNotifications({int daysOld = 30}) async {
    if (_currentUserId == null) return;
    final db = FirebaseFirestore.instance;
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    final old = await db
        .collection(_notifCol)
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
        .get();
    const batchLimit = 400;
    var batch = db.batch();
    var ops = 0;
    for (final doc in old.docs) {
      batch.delete(doc.reference);
      ops++;
      if (ops >= batchLimit) {
        await batch.commit();
        batch = db.batch();
        ops = 0;
      }
    }
    if (ops > 0) await batch.commit();
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? languageCode,
  }) async {
    if (kIsWeb || Platform.isWindows || Platform.isLinux) {
      debugPrint('Zamanlanmış bildirimler bu platformda desteklenmiyor.');
      return;
    }

    final lang = await _resolveLanguageCode(languageCode);
    final l = l10nFor(lang);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute,);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_briefing',
          l.notifChannelDailyBriefing,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
