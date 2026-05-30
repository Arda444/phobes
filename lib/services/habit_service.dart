import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_firebase_service.dart';
import 'notification_service.dart';

class HabitService extends BaseFirebaseService {
  static final HabitService _instance = HabitService._internal();
  factory HabitService() => _instance;
  HabitService._internal();

  Stream<QuerySnapshot> getHabitsStream() {
    if (currentUserId == null) return const Stream.empty();
    return db
        .collection('habits')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String?> addHabit(String title) async {
    if (currentUserId == null) return null;
    final ref = await db.collection('habits').add({
      'userId': currentUserId,
      'title': title,
      'streak': 0,
      'lastCompleted': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> toggleHabit(
    String habitId,
    bool isCompleted, {
    String? milestoneTitle,
    String Function(String habitTitle, int streak)? milestoneBodyBuilder,
  }) async {
    final docRef = db.collection('habits').doc(habitId);
    final now = DateTime.now();

    if (isCompleted) {
      final doc = await docRef.get();
      final data = doc.data() ?? {};
      final today = DateTime(now.year, now.month, now.day);
      final lastTs = data['lastCompleted'];
      DateTime? lastDay;
      if (lastTs is Timestamp) {
        final d = lastTs.toDate();
        lastDay = DateTime(d.year, d.month, d.day);
      }
      if (lastDay == today) return;

      final yesterday = today.subtract(const Duration(days: 1));
      final currentStreak = (data['streak'] as num?)?.toInt() ?? 0;
      final newStreak =
          lastDay == yesterday ? currentStreak + 1 : 1;

      await docRef.update({
        'lastCompleted': Timestamp.fromDate(now),
        'streak': newStreak,
      });
      await addXP(20);

      final updatedStreak = newStreak;
      final habitTitle = data['title'] as String? ?? '';

      if ([7, 30, 100, 365].contains(updatedStreak)) {
        await NotificationService().sendNotification(
          title: milestoneTitle ?? 'Milestone! 🏆',
          body: milestoneBodyBuilder?.call(habitTitle, updatedStreak) ??
              '$habitTitle — $updatedStreak day streak!',
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
      final currentStreak = (doc.data()?['streak'] ?? 0) as int;
      await docRef.update({
        'lastCompleted': null,
        'streak': currentStreak > 0 ? currentStreak - 1 : 0,
      });
    }
  }

  Future<void> deleteHabit(String habitId) async {
    await NotificationService().cancelNotification('habit_$habitId');
    await db.collection('habits').doc(habitId).delete();
  }
}
