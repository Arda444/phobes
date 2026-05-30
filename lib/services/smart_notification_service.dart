import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

/// Akıllı bildirim sistemi.
/// İlkeler:
///   • Kullanıcıyı bildirimlere boğma — günde maksimum 3 sistem bildirimi
///   • Her bildirim gerçek bir değer taşısın (veri tabanlı, jenerik değil)
///   • Motivasyon ve alışkanlık bağlılığı odaklı
///   • Gereksiz/rastgele bildirimler yok
class SmartNotificationService {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<String> _morningMessages = [
    'Bugün neler başaracaksın?',
    'Küçük bir adım bile önemli. Haydi başlayalım!',
    'Güne güçlü başlamak için planlarına bir bak.',
  ];

  static const List<String> _weeklyMessages = [
    'Bu haftaki performansını görmek ister misin?',
    'Bir haftayı daha geride bıraktın. Nasıl geçti?',
    'Haftalık istatistiklerin hazır!',
  ];

  /// Ana giriş noktası — app başlangıcında çağrılır.
  Future<void> scheduleDailyNotifications() async {
    final uid = _firebaseService.currentUserId;
    if (uid == null) return;

    final userDoc = await _db.collection('users').doc(uid).get();
    final prefs = userDoc.data()?['preferences']?['notifications'] ?? {};
    final userName = userDoc.data()?['name'] ?? 'sen';
    final birthDateStr = userDoc.data()?['birthDate'];

    if (prefs['notif_morning_brief'] != false) {
      await _scheduleMorningBriefing(uid);
    }

    if (prefs['notif_habit_streak'] != false) {
      await _scheduleStreakRiskCheck(uid);
    }

    if (prefs['notif_weekly_digest'] != false) {
      await _scheduleWeeklyDigest();
    }

    if (prefs['notif_milestones'] != false && birthDateStr != null) {
      try {
        final birthDate = DateTime.parse(birthDateStr);
        await _scheduleBirthday(birthDate, userName);
      } catch (e) {
        debugPrint('SmartNotification birthday schedule error: $e');
      }
    }
  }

  /// Sabah brifing: 09:00 — günün görev/alışkanlık özetini tetikle.
  /// Jenerik "Günaydın" değil, kullanıcıya değer katar.
  Future<void> _scheduleMorningBriefing(String uid) async {
    final now = DateTime.now();
    var t = DateTime(now.year, now.month, now.day, 9);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));

    int pendingTasks = 0;
    try {
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final qs = await _db
          .collection('tasks')
          .where('userId', isEqualTo: uid)
          .where('status', isNotEqualTo: 'completed')
          .where('endTime', isLessThanOrEqualTo: Timestamp.fromDate(tomorrow))
          .limit(10)
          .get();
      pendingTasks = qs.docs.length;
    } catch (e) {
      debugPrint('SmartNotification morning tasks error: $e');
    }

    final body = pendingTasks > 0
        ? '$pendingTasks bekleyen görevin var. Harika bir gün seni bekliyor!'
        : _morningMessages[Random().nextInt(_morningMessages.length)];

    await _notificationService.scheduleAndSaveNotification(
      id: 'morning_brief',
      title: '\u2600\uFE0F Günaydın!',
      body: body,
      scheduledTime: t,
      type: 'system',
      targetId: 'daily',
      targetType: 'system',
      icon: '\u2600\uFE0F',
      color: 0xFFFFC107,
      channelId: 'daily_briefs',
      channelName: 'Günlük Özetler',
      prefKey: 'notif_morning_brief',
    );
  }

  /// Streak risk: 20:00 — o gün alışkanlıklarını tamamlamadıysa uyar.
  Future<void> _scheduleStreakRiskCheck(String uid) async {
    final now = DateTime.now();
    var t = DateTime(now.year, now.month, now.day, 20);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));

    int atRiskCount = 0;
    try {
      final today = DateTime(now.year, now.month, now.day);
      final habits = await _db
          .collection('habits')
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in habits.docs) {
        final data = doc.data();
        final streak = (data['streak'] ?? 0) as int;
        if (streak < 3) continue;
        final lastCompleted = data['lastCompleted'];
        final completedToday = lastCompleted is Timestamp &&
            lastCompleted.toDate().year == today.year &&
            lastCompleted.toDate().month == today.month &&
            lastCompleted.toDate().day == today.day;
        if (!completedToday) atRiskCount++;
      }
    } catch (e) {
      debugPrint('SmartNotification streak check error: $e');
    }

    if (atRiskCount == 0) return;

    final msg = atRiskCount == 1
        ? '1 alışkanlık seriyi risk altında. Tamamlamak için hâlâ vakit var!'
        : '$atRiskCount alışkanlık serisi risk altında. Kaybetmeden önce tamamla!';

    await _notificationService.scheduleAndSaveNotification(
      id: 'streak_risk',
      title: '\u{1F525} Serin Tehlikede!',
      body: msg,
      scheduledTime: t,
      type: 'habit',
      targetId: 'streak_risk',
      targetType: 'habit',
      icon: '\u{1F525}',
      color: 0xFFFF5722,
      channelId: 'habits',
      channelName: 'Alışkanlıklar',
      prefKey: 'notif_habit_streak',
    );
  }

  /// Haftalık özet: Pazar günü 10:00.
  Future<void> _scheduleWeeklyDigest() async {
    final now = DateTime.now();

    final daysUntilSunday = (7 - now.weekday) % 7;
    var t = DateTime(now.year, now.month, now.day, 10)
        .add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));

    if (t.isBefore(now)) t = t.add(const Duration(days: 7));

    await _notificationService.scheduleAndSaveNotification(
      id: 'weekly_digest',
      title: '\u{1F4CA} Haftalık Rapor Hazır',
      body: _weeklyMessages[Random().nextInt(_weeklyMessages.length)],
      scheduledTime: t,
      type: 'system',
      targetId: 'weekly',
      targetType: 'system',
      icon: '\u{1F4CA}',
      color: 0xFF3F51B5,
      channelId: 'daily_briefs',
      channelName: 'Günlük Özetler',
      prefKey: 'notif_weekly_digest',
    );
  }

  /// Doğum günü: doğum gününde 09:00.
  Future<void> _scheduleBirthday(DateTime birthDate, String userName) async {
    final now = DateTime.now();
    var t = DateTime(now.year, birthDate.month, birthDate.day, 9);
    if (t.isBefore(now)) {
      t = DateTime(now.year + 1, birthDate.month, birthDate.day, 9);
    }
    if (t.difference(now).inDays > 30) return;

    await _notificationService.scheduleAndSaveNotification(
      id: 'birthday_notif',
      title: '\u{1F382} Doğum Günün Kutlu Olsun!',
      body: 'Harika bir yıl daha seni bekliyor, $userName! \u{1F389}',
      scheduledTime: t,
      type: 'system',
      targetId: 'birthday',
      targetType: 'system',
      icon: '\u{1F382}',
      color: 0xFFE91E63,
      channelId: 'milestones',
      channelName: 'Kutlamalar',
      prefKey: 'notif_milestones',
    );
  }

  /// Seviye atlama kutlaması — firebase_service'ten çağrılır.
  Future<void> sendLevelUpNotification(int newLevel) async {
    await _notificationService.sendNotification(
      title: '\u2B50 Seviye $newLevel!',
      body: 'Tebrikler! Yeni bir seviyeye ulaştın. Harika ilerliyorsun!',
      type: 'system',
      icon: '\u2B50',
      color: 0xFFFFD600,
      prefKey: 'notif_level_up',
    );
  }

  /// Alışkanlık seri kutlaması — firebase_service'ten çağrılır.
  Future<void> sendStreakMilestone(String habitName, int days) async {
    final msg = days >= 100
        ? '$habitName alışkanlığında $days gün seriye ulaştın! \u{1F3C6}'
        : days >= 30
            ? '$habitName alışkanlığında $days günlük seri! Muhteşemsin!'
            : '$habitName alışkanlığında $days günlük seri! Böyle devam!';

    await _notificationService.sendNotification(
      title: '\u{1F525} $days Günlük Seri!',
      body: msg,
      type: 'habit',
      icon: '\u{1F525}',
      color: 0xFF4CAF50,
      prefKey: 'notif_habit_milestone',
    );
  }

  /// Görev son tarihi yaklaşıyor — task_add_edit_screen'den çağrılır.
  Future<void> sendTaskDeadlineReminder({
    required String taskTitle,
    required DateTime deadline,
    required String taskId,
    int minutesBefore = 60,
  }) async {
    final reminderTime = deadline.subtract(Duration(minutes: minutesBefore));
    if (reminderTime.isBefore(DateTime.now())) return;

    final timeLabel = minutesBefore >= 60
        ? '${minutesBefore ~/ 60} saat'
        : '$minutesBefore dakika';

    await _notificationService.scheduleAndSaveNotification(
      id: 'task_$taskId',
      title: '\u{1F4CB} Son Tarihe $timeLabel Kaldı',
      body: '"$taskTitle" görevi için zamanın daralıyor.',
      scheduledTime: reminderTime,
      type: 'task',
      targetId: taskId,
      targetType: 'task',
      icon: '\u{1F4CB}',
      color: 0xFF8B5CF6,
      prefKey: 'notif_task_deadline',
    );
  }

  /// Gecikmiş görev uyarısı — tek seferlik, spam değil.
  Future<void> sendOverdueTaskAlert(String taskTitle, String taskId) async {
    await _notificationService.sendNotification(
      title: '\u26A0\uFE0F Görev Gecikti',
      body: '"$taskTitle" görevi tamamlanmadı.',
      type: 'task',
      targetId: taskId,
      targetType: 'task',
      icon: '\u26A0\uFE0F',
      color: 0xFFEF5350,
      prefKey: 'notif_task_overdue',
    );
  }
}
