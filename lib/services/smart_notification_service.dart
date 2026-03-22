import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class SmartNotificationService {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final List<String> _motivations = [
    "Küçük adımlar büyük başarılara götürür. Bugün bir adım daha at! 🌟",
    "Dünkü sen bugünkü senden gurur duyar. Devam et! 🚀",
    "Her gün %1 daha iyi ol. 365 günde 37 kat gelişirsin! 📈",
    "Disiplin, motivasyon bittiğinde devam etmektir. Sen yapabilirsin! 💪",
    "Unutma: Her uzman bir zamanlar acemiydi. 🎯",
    "Başarı, her gün tekrarlanan küçük çabaların toplamıdır. ✨",
    "Engeller, gözünüzü hedeften ayırdığınızda gördüğünüz korkutucu şeylerdir. 👀",
    "Sadece yap! Yarın bugünkü kendine teşekkür edeceksin. 🎁",
  ];

  Future<void> scheduleDailyNotifications() async {
    final uid = _firebaseService.currentUserId;
    if (uid == null) return;

    final userDoc = await _db.collection('users').doc(uid).get();
    final prefs = userDoc.data()?['preferences']?['notifications'] ?? {};
    final userName = userDoc.data()?['name'] ?? 'Kullanıcı';
    final birthDateStr = userDoc.data()?['birthDate'];

    // 1. Sabah Brifingi (09:00)
    if (prefs['notif_morning_brief'] != false) {
      await _scheduleMorningBriefing(uid);
    }

    // 2. Akşam Özeti (21:00)
    if (prefs['notif_evening_summary'] != false) {
      await _scheduleEveningSummary(uid);
    }

    // 3. Rastgele Motivasyon Mektubu (Gündüz vakti rastgele bir saat)
    if (prefs['notif_motivation'] != false) {
      await _scheduleRandomMotivation();
    }

    // 4. Doğum Günü Kutlaması
    if (prefs['notif_milestones'] != false && birthDateStr != null) {
      try {
        final birthDate = DateTime.parse(birthDateStr);
        await _scheduleBirthday(birthDate, userName);
      } catch (e) {
        // Geçersiz tarih formatı
      }
    }
  }

  Future<void> _scheduleMorningBriefing(String uid) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 9, 0);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notificationService.scheduleAndSaveNotification(
      id: 'morning_brief',
      title: 'Günaydın! ☀️',
      body: 'Harika bir gün seni bekliyor. Phobes ile planlarına göz at!',
      scheduledTime: scheduledTime,
      type: 'system',
      targetId: 'daily',
      targetType: 'system',
      icon: '☀️',
      color: 0xFFFFC107,
      channelId: 'daily_briefs',
      channelName: 'Günlük Özetler',
      prefKey: 'notif_morning_brief',
    );
  }

  Future<void> _scheduleEveningSummary(String uid) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 21, 0);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notificationService.scheduleAndSaveNotification(
      id: 'evening_summary',
      title: 'Günün Özeti 🌙',
      body:
          'Bugün harika iş çıkardın! Yarınki planlarını gözden geçirmeye ne dersin?',
      scheduledTime: scheduledTime,
      type: 'system',
      targetId: 'daily',
      targetType: 'system',
      icon: '🌙',
      color: 0xFF3F51B5,
      channelId: 'daily_briefs',
      channelName: 'Günlük Özetler',
      prefKey: 'notif_evening_summary',
    );
  }

  Future<void> _scheduleRandomMotivation() async {
    final now = DateTime.now();
    final random = Random();

    // Gündüz 10:00 ile 18:00 arası rastgele bir saat seç
    final hour = 10 + random.nextInt(8);
    final minute = random.nextInt(60);

    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final quote = _motivations[random.nextInt(_motivations.length)];

    await _notificationService.scheduleAndSaveNotification(
      id: 'motivation_daily',
      title: 'Günün Motivasyonu 💡',
      body: quote,
      scheduledTime: scheduledTime,
      type: 'system',
      targetId: 'motivation',
      targetType: 'system',
      icon: '💡',
      color: 0xFFFF9800,
      channelId: 'motivation',
      channelName: 'Motivasyon',
      prefKey: 'notif_motivation',
    );
  }

  Future<void> _scheduleBirthday(DateTime birthDate, String userName) async {
    final now = DateTime.now();
    var nextBirthday = DateTime(now.year, birthDate.month, birthDate.day, 9, 0);

    if (nextBirthday.isBefore(now)) {
      nextBirthday =
          DateTime(now.year + 1, birthDate.month, birthDate.day, 9, 0);
    }

    if (nextBirthday.difference(now).inDays <= 30) {
      await _notificationService.scheduleAndSaveNotification(
        id: 'birthday_notif',
        title: 'Doğum Günün Kutlu Olsun! 🎂',
        body:
            'İyi ki doğdun $userName! 🎉 Harika bir yıl daha seni bekliyor. Kendine güzel bir hediye al! 🎁',
        scheduledTime: nextBirthday,
        type: 'system',
        targetId: 'birthday',
        targetType: 'system',
        icon: '🎂',
        color: 0xFFE91E63,
        channelId: 'milestones',
        channelName: 'Kutlamalar',
        prefKey: 'notif_milestones',
      );
    }
  }

  Future<void> checkAndAlertStreakRisk() async {
    final uid = _firebaseService.currentUserId;
    if (uid == null) return;

    try {
      final snapshot =
          await _db.collection('users').doc(uid).collection('habits').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final streak = data['streak'] ?? 0;
        final isActive = data['isActive'] ?? true;

        if (isActive && streak >= 7) {
          // Placeholder for streak calculation logic
        }
      }
    } catch (e) {
      // ignore
    }
  }
}
