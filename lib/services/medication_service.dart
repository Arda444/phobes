import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show TimeOfDay;
import '../models/medication_model.dart';
import 'base_firebase_service.dart';
import 'notification_service.dart';

class MedicationService extends BaseFirebaseService {
  static final MedicationService _instance = MedicationService._internal();
  factory MedicationService() => _instance;
  MedicationService._internal();

  String get _medCol => 'users/$currentUserId/medications';

  Future<void> addMedication(Medication med) async {
    final ref = await db.collection(_medCol).add(med.toMap());
    if (med.isActive && med.reminderEnabled) {
      await _scheduleDoseReminders(ref.id, med);
    }
  }

  Future<void> updateMedication(Medication med) async {
    if (med.id == null) return;
    try {
      await db.collection(_medCol).doc(med.id!).update(med.toMap());
      // Cancel old reminders and reschedule with new times.
      await _cancelDoseReminders(med.id!, times: med.times);
      if (med.isActive && med.reminderEnabled) {
        await _scheduleDoseReminders(med.id!, med);
      }
    } catch (e) {
      debugPrint('[MedicationService.updateMedication] error: $e');
      rethrow;
    }
  }

  Future<void> deleteMedication(String medId) async {
    try {
      final existing = await getMedicationById(medId);
      await _cancelDoseReminders(medId, times: existing?.times);
      await db.collection(_medCol).doc(medId).delete();
    } catch (e) {
      debugPrint('[MedicationService.deleteMedication] error: $e');
      rethrow;
    }
  }

  /// Schedules a daily recurring local reminder for each time slot in [med.times].
  Future<void> _scheduleDoseReminders(String medId, Medication med) async {
    final ns = NotificationService();
    for (final timeStr in med.times) {
      final parts = timeStr.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;
      await ns.scheduleDailyMedicationReminder(
        medId: medId,
        medName: med.name,
        timeSlot: timeStr,
        time: TimeOfDay(hour: hour, minute: minute),
      );
    }
  }

  Future<void> _cancelDoseReminders(
    String medId, {
    List<String>? times,
  }) async {
    final ns = NotificationService();
    if (times != null) {
      for (final timeStr in times) {
        await ns.cancelNotification(
          'med_${medId}_${timeStr.replaceAll(':', '_')}',
        );
      }
    }
    // Legacy IDs from older clients / add-edit screen.
    for (var i = 0; i < 8; i++) {
      await ns.cancelNotification('med_${medId}_$i');
    }
  }

  Stream<List<Medication>> getMedicationsStream() {
    if (currentUserId == null) return const Stream.empty();
    return db
        .collection(_medCol)
        .orderBy('name')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Medication.fromMap(d.data(), d.id)).toList(),);
  }

  Future<Medication?> getMedicationById(String medId) async {
    final doc = await db.collection(_medCol).doc(medId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return Medication.fromMap(data, doc.id);
  }

  Future<void> markMedicationTaken(
    String medId,
    String dateKey,
    String time, {
    String? lowStockTitle,
    String? lowStockBody,
    String? emptyStockTitle,
    String? emptyStockBody,
  }) async {
    final docRef = db.collection(_medCol).doc(medId);
    String medName = '';
    int stockAfter = 0;
    bool trackingStock = false;
    int stockThreshold = 5;

    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      medName = data['name'] ?? '';
      final bool tracking = data['stockTracking'] ?? false;
      trackingStock = tracking;
      stockThreshold = (data['stockThreshold'] as num?)?.toInt() ?? 5;
      final int currentStock = data['stock'] ?? 0;

      final updates = <String, dynamic>{
        'takenHistory.$dateKey': FieldValue.arrayUnion([time]),
      };
      if (tracking && currentStock > 0) {
        updates['stock'] = currentStock - 1;
        stockAfter = currentStock - 1;
      } else {
        stockAfter = currentStock;
      }
      transaction.update(docRef, updates);
    });

    if (trackingStock && stockAfter <= stockThreshold && stockAfter > 0) {
      await NotificationService().sendNotification(
        title: lowStockTitle ?? 'Low Stock! ⚠️',
        body: lowStockBody ?? '$medName - Remaining: $stockAfter',
        type: 'medication',
        targetId: medId,
        targetType: 'medication',
        icon: '⚠️',
        color: 0xFFFF9800,
        prefKey: 'notif_med_refill',
      );
    } else if (trackingStock && stockAfter <= 0) {
      await NotificationService().sendNotification(
        title: emptyStockTitle ?? 'Out of Stock! 🚨',
        body: emptyStockBody ?? '$medName stock is empty. Time to refill.',
        type: 'medication',
        targetId: medId,
        targetType: 'medication',
        icon: '🚨',
        color: 0xFFF44336,
        prefKey: 'notif_med_refill',
      );
    }
  }

  // ── Medicine catalogue search (global 'medicines' collection) ────────────

  Future<List<Map<String, dynamic>>> searchMedicines(String query) async {
    if (query.isEmpty) return [];

    String normalize(String s) {
      s = s
          .replaceAll('İ', 'i').replaceAll('I', 'i').replaceAll('Ğ', 'g')
          .replaceAll('Ü', 'u').replaceAll('Ş', 's').replaceAll('Ö', 'o')
          .replaceAll('Ç', 'c');
      s = s.toLowerCase();
      s = s
          .replaceAll('ı', 'i').replaceAll('ğ', 'g').replaceAll('ü', 'u')
          .replaceAll('ş', 's').replaceAll('ö', 'o').replaceAll('ç', 'c');
      return s.replaceAll(RegExp(r'[̀-ͯ]'), '').trim();
    }

    final term = normalize(query);
    if (term.isEmpty) return [];

    final upperBound = term + String.fromCharCode(0xF8FF);

    final byName = await db
        .collection('medicines')
        .where('name_lowercase', isGreaterThanOrEqualTo: term)
        .where('name_lowercase', isLessThanOrEqualTo: upperBound)
        .limit(25)
        .get();

    final byGeneric = await db
        .collection('medicines')
        .where('generic_name_lowercase', isGreaterThanOrEqualTo: term)
        .where('generic_name_lowercase', isLessThanOrEqualTo: upperBound)
        .limit(25)
        .get();

    final results = <String, Map<String, dynamic>>{};
    for (final doc in byName.docs) {
      results[doc.id] = {...doc.data(), 'id': doc.id};
    }
    for (final doc in byGeneric.docs) {
      results[doc.id] = {...doc.data(), 'id': doc.id};
    }
    return results.values.toList();
  }

  Future<void> unmarkMedicationTaken(
      String medId, String dateKey, String time,) async {
    final docRef = db.collection(_medCol).doc(medId);

    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final bool tracking = data['stockTracking'] ?? false;
      final int currentStock = data['stock'] ?? 0;

      final updates = <String, dynamic>{
        'takenHistory.$dateKey': FieldValue.arrayRemove([time]),
      };
      if (tracking) updates['stock'] = currentStock + 1;
      transaction.update(docRef, updates);
    });
  }
}

