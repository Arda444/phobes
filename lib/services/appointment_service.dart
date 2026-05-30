import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'base_firebase_service.dart';
import '../models/appointment_model.dart';
import '../models/appointment_group_model.dart';
import '../models/client_model.dart';
import 'notification_service.dart';

class AppointmentService extends BaseFirebaseService {
  AppointmentService._();
  static final AppointmentService _instance = AppointmentService._();
  factory AppointmentService() => _instance;

  // ─── Appointments CRUD ──────────────────────────────────────────────────

  Stream<List<Appointment>> getAppointmentsStream() {
    if (currentUserId == null) return Stream.value([]);
    return db
        .collection('appointments')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => Appointment.fromFirestore(d)).toList());
  }

  Stream<List<Appointment>> getMyAppointmentsAsClientStream() {
    if (currentUserId == null) return Stream.value([]);
    final uid = currentUserId!;

    final bookedStream = db
        .collection('appointments')
        .where('clientId', isEqualTo: uid)
        .orderBy('date', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => Appointment.fromFirestore(d)).toList());

    final personalStream = db
        .collection('appointments')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => Appointment.fromFirestore(d))
              .where((a) => a.groupId == null || a.groupId!.isEmpty)
              .toList(),
        );

    return Rx.combineLatest2<List<Appointment>, List<Appointment>,
        List<Appointment>>(
      bookedStream.startWith(const <Appointment>[]),
      personalStream.startWith(const <Appointment>[]),
      (booked, personal) {
        final seen = <String>{};
        final merged = <Appointment>[];
        for (final a in [...personal, ...booked]) {
          final id = a.id;
          if (id == null || seen.add(id)) merged.add(a);
        }
        merged.sort((a, b) => a.date.compareTo(b.date));
        return merged;
      },
    );
  }

  Stream<List<Appointment>> getAppointmentsForDate(DateTime date) {
    if (currentUserId == null) return Stream.value([]);
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return db
        .collection('appointments')
        .where('userId', isEqualTo: currentUserId)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),)
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dayEnd))
        .orderBy('date')
        .snapshots()
        .map((s) => s.docs.map((d) => Appointment.fromFirestore(d)).toList());
  }

  Stream<List<Appointment>> getAppointmentsForDateRange(
      DateTime start, DateTime end,) {
    if (currentUserId == null) return Stream.value([]);
    return db
        .collection('appointments')
        .where('userId', isEqualTo: currentUserId)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),)
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date')
        .snapshots()
        .map((s) => s.docs.map((d) => Appointment.fromFirestore(d)).toList());
  }

  Stream<List<Appointment>> getMyAppointmentsAsClientStreamForDateRange(
      DateTime start, DateTime end,) {
    if (currentUserId == null) return Stream.value([]);
    return getMyAppointmentsAsClientStream().map((appts) {
      final rangeStart = DateTime(start.year, start.month, start.day);
      final rangeEnd = DateTime(end.year, end.month, end.day);
      return appts.where((a) {
        final d = DateTime(a.date.year, a.date.month, a.date.day);
        return !d.isBefore(rangeStart) && !d.isAfter(rangeEnd);
      }).toList();
    });
  }

  Future<String> addAppointment(Appointment appt) async {
    if (currentUserId == null) return '';
    final map = appt.toMap();
    final ownerId = map['userId'] as String?;
    if (ownerId == null || ownerId.isEmpty) {
      map['userId'] = currentUserId!;
    }
    final ref = await db.collection('appointments').add(map);
    if (appt.groupId != null) {
      await _writeSlot(appt.groupId!, appt, status: appt.status);
    }

    // Schedule a local reminder and save in-app notification for future appts.
    if (appt.date.isAfter(DateTime.now())) {
      final reminderTime =
          appt.date.subtract(const Duration(minutes: 30));
      if (reminderTime.isAfter(DateTime.now())) {
        NotificationService().scheduleAndSaveNotification(
          id: 'appt_${ref.id}',
          title: '📅 Randevu Hatırlatması',
          body: '"${appt.title}" randevunuz 30 dakika sonra başlıyor.',
          scheduledTime: reminderTime,
          type: 'appointment',
          targetId: ref.id,
          targetType: 'appointment',
          icon: '📅',
          color: 0xFF2196F3,
          channelId: 'appointments',
          channelName: 'Randevular',
          prefKey: 'notif_appt_reminder',
        );
      }
    }

    return ref.id;
  }

  DocumentReference<Map<String, dynamic>> _slotRef(
    String groupId,
    DateTime date,
  ) {
    return db
        .collection('appointment_groups')
        .doc(groupId)
        .collection('slots')
        .doc('${date.millisecondsSinceEpoch}');
  }

  DocumentReference<Map<String, dynamic>> _appointmentRef(
    String groupId,
    DateTime date,
  ) {
    return db
        .collection('appointments')
        .doc('${groupId}_${date.millisecondsSinceEpoch}');
  }

  Future<void> _writeSlot(
    String groupId,
    Appointment appt, {
    String? status,
  }) async {
    await _slotRef(groupId, appt.date).set({
      'date': Timestamp.fromDate(appt.date),
      'status': status ?? appt.status,
      'providerId': appt.userId,
      'clientId': appt.clientId,
      'groupId': groupId,
    }, SetOptions(merge: true));
  }

  /// Books a client appointment atomically.
  /// Slot occupancy lives under appointment_groups (readable for availability).
  Future<String?> bookClientAppointment(Appointment appt) async {
    if (currentUserId == null || appt.groupId == null) return null;
    if (appt.userId.isEmpty) return null;
    final groupId = appt.groupId!;
    final slotRef = _slotRef(groupId, appt.date);
    final apptRef = _appointmentRef(groupId, appt.date);

    try {
      final id = await db.runTransaction<String?>((txn) async {
        final existing = await txn.get(slotRef);
        if (existing.exists) {
          final status = existing.data()?['status'] as String? ?? '';
          if (status != 'cancelled') return null;
        }
        txn.set(slotRef, {
          'date': Timestamp.fromDate(appt.date),
          'status': appt.status.isEmpty ? 'pending' : appt.status,
          'providerId': appt.userId,
          'clientId': currentUserId,
          'groupId': groupId,
        });
        txn.set(apptRef, appt.toMap());
        return apptRef.id;
      });

      if (id != null && appt.date.isAfter(DateTime.now())) {
        NotificationService().sendNotification(
          title: '✅ Randevu Onaylandı',
          body:
              '"${appt.title}" için ${appt.date.day}.${appt.date.month} tarihinde randevunuz oluşturuldu.',
          type: 'appointment',
          targetId: id,
          targetType: 'appointment',
          icon: '✅',
          color: 0xFF4CAF50,
          prefKey: 'notif_appt_reminder',
        );
        await NotificationService().sendInAppNotificationToUsers(
          recipientIds: [appt.userId],
          title: '📅 Yeni Randevu Talebi',
          body:
              '"${appt.title}" — ${appt.date.day}.${appt.date.month} '
              '${appt.date.hour.toString().padLeft(2, '0')}:'
              '${appt.date.minute.toString().padLeft(2, '0')}',
          type: 'appointment',
          targetId: id,
          targetType: 'appointment',
          icon: '📅',
          color: 0xFF2196F3,
        );
        // Local reminder 30 min before.
        final reminderTime = appt.date.subtract(const Duration(minutes: 30));
        if (reminderTime.isAfter(DateTime.now())) {
          NotificationService().scheduleAndSaveNotification(
            id: 'appt_$id',
            title: '📅 Randevu Hatırlatması',
            body: '"${appt.title}" randevunuz 30 dakika sonra.',
            scheduledTime: reminderTime,
            type: 'appointment',
            targetId: id,
            targetType: 'appointment',
            icon: '📅',
            color: 0xFF2196F3,
            channelId: 'appointments',
            channelName: 'Randevular',
            prefKey: 'notif_appt_reminder',
          );
        }
      }
      return id;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateAppointment(Appointment appt) async {
    if (appt.id != null) {
      await db.collection('appointments').doc(appt.id).update(appt.toMap());
    }
  }

  Future<void> updateStatus(String id, String status,
      {String? reason,}) async {
    final Map<String, dynamic> data = {'status': status};
    if (status == 'confirmed') data['confirmedAt'] = FieldValue.serverTimestamp();
    if (reason != null) data['cancelReason'] = reason;
    final doc = await db.collection('appointments').doc(id).get();
    await db.collection('appointments').doc(id).update(data);

    if (doc.exists) {
      final appt = Appointment.fromFirestore(doc);
      if (appt.groupId != null) {
        await _writeSlot(
          appt.groupId!,
          appt.copyWith(status: status),
          status: status,
        );
      }
    }

    if (status == 'cancelled') {
      // Cancel the scheduled local reminder if it exists.
      NotificationService().cancelNotification('appt_$id');
      // In-app notification for cancellation.
      NotificationService().sendNotification(
        title: '❌ Randevu İptal Edildi',
        body: reason != null
            ? 'Randevunuz iptal edildi. Neden: $reason'
            : 'Randevunuz iptal edildi.',
        type: 'appointment',
        targetId: id,
        targetType: 'appointment',
        icon: '❌',
        color: 0xFFEF5350,
        prefKey: 'notif_appt_status',
      );
    } else if (status == 'confirmed') {
      NotificationService().sendNotification(
        title: '✅ Randevu Onaylandı',
        body: 'Randevunuz onaylandı. Hazır olun!',
        type: 'appointment',
        targetId: id,
        targetType: 'appointment',
        icon: '✅',
        color: 0xFF4CAF50,
        prefKey: 'notif_appt_status',
      );
    }
  }

  Future<void> deleteAppointment(String id) async {
    final doc = await db.collection('appointments').doc(id).get();
    if (doc.exists) {
      final appt = Appointment.fromFirestore(doc);
      if (appt.groupId != null) {
        await _slotRef(appt.groupId!, appt.date).delete();
      }
    }
    await db.collection('appointments').doc(id).delete();
  }

  // ─── Services (Groups) CRUD ─────────────────────────────────────────────

  Stream<List<AppointmentGroup>> getMyServicesStream() {
    if (currentUserId == null) return Stream.value([]);
    return db
        .collection('appointment_groups')
        .where('ownerId', isEqualTo: currentUserId)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => AppointmentGroup.fromFirestore(d)).toList(),);
  }

  Future<String> createService(AppointmentGroup service) async {
    final ref = await db.collection('appointment_groups').add(service.toMap());
    return ref.id;
  }

  Future<void> updateService(AppointmentGroup service) async {
    if (service.id != null) {
      await db
          .collection('appointment_groups')
          .doc(service.id)
          .update(service.toMap());
    }
  }

  Future<void> deleteService(String id) async {
    await db.collection('appointment_groups').doc(id).delete();
  }

  Future<AppointmentGroup?> getServiceById(String groupId) async {
    try {
      final doc =
          await db.collection('appointment_groups').doc(groupId).get();
      if (!doc.exists) return null;
      return AppointmentGroup.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<AppointmentGroup?> getServiceByCode(String code) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('lookupAppointmentGroupByCode');
      final result = await callable.call<Map<String, dynamic>>({
        'code': code.trim().toUpperCase(),
      });
      final groupMap = result.data['group'];
      if (groupMap == null) return null;
      final map = Map<String, dynamic>.from(groupMap as Map);
      final breaks = List<Map<String, dynamic>>.from(map['breaks'] ?? [])
          .map(
            (e) => e.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
          )
          .toList();
      return AppointmentGroup(
        id: map['id'] as String?,
        ownerId: map['ownerId'] as String? ?? '',
        title: map['title'] as String? ?? map['businessName'] as String? ?? '',
        businessName: map['businessName'] as String? ?? '',
        durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 30,
        bufferMinutes: (map['bufferMinutes'] as num?)?.toInt() ?? 0,
        minCancellationHours:
            (map['minCancellationHours'] as num?)?.toInt() ?? 24,
        startDate: DateTime.fromMillisecondsSinceEpoch(
          (map['startDateMs'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        endDate: DateTime.fromMillisecondsSinceEpoch(
          (map['endDateMs'] as num?)?.toInt() ??
              DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch,
        ),
        startHour: (map['startHour'] as num?)?.toInt() ?? 9,
        endHour: (map['endHour'] as num?)?.toInt() ?? 17,
        groupCode: map['groupCode'] as String? ?? code,
        workingDays: List<int>.from(map['workingDays'] ?? [1, 2, 3, 4, 5]),
        breaks: breaks,
        isActive: map['isActive'] as bool? ?? true,
      );
    } catch (e) {
      debugPrint('[AppointmentService.getServiceByCode] $e');
      return null;
    }
  }

  Future<List<DateTime>> getAvailableSlots(
      AppointmentGroup group, DateTime date,) async {
    if (date.isBefore(DateUtils.dateOnly(group.startDate)) ||
        date.isAfter(DateUtils.dateOnly(group.endDate))) {
      return [];
    }
    if (!group.workingDays.contains(date.weekday)) return [];

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59);

    if (group.id == null) return [];
    final snapshot = await db
        .collection('appointment_groups')
        .doc(group.id)
        .collection('slots')
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),)
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dayEnd))
        .get();

    final bookedSlots = snapshot.docs
        .where((d) => (d.data()['status'] as String? ?? '') != 'cancelled')
        .map((d) => (d.data()['date'] as Timestamp).toDate())
        .toList();
    final availableSlots = <DateTime>[];

    var currentSlot =
        DateTime(date.year, date.month, date.day, group.startHour);
    final shiftEnd =
        DateTime(date.year, date.month, date.day, group.endHour);

    while (currentSlot
            .add(Duration(minutes: group.durationMinutes))
            .isBefore(shiftEnd) ||
        currentSlot
            .add(Duration(minutes: group.durationMinutes))
            .isAtSameMomentAs(shiftEnd)) {
      bool isAvailable = true;
      final slotEnd =
          currentSlot.add(Duration(minutes: group.durationMinutes));

      for (final b in group.breaks) {
        final breakStart = DateTime(
            date.year, date.month, date.day, b['startH']!, b['startM']!,);
        final breakEnd = DateTime(
            date.year, date.month, date.day, b['endH']!, b['endM']!,);
        if (currentSlot.isBefore(breakEnd) && slotEnd.isAfter(breakStart)) {
          isAvailable = false;
          break;
        }
      }

      if (isAvailable) {
        for (final booked in bookedSlots) {
          if (booked.isAtSameMomentAs(currentSlot)) {
            isAvailable = false;
            break;
          }
        }
      }

      if (isAvailable && currentSlot.isBefore(DateTime.now())) {
        isAvailable = false;
      }

      if (isAvailable) availableSlots.add(currentSlot);

      currentSlot = currentSlot
          .add(Duration(minutes: group.durationMinutes + group.bufferMinutes));
    }

    return availableSlots;
  }

  // ─── Clients CRUD ───────────────────────────────────────────────────────

  Stream<List<Client>> getClientsStream() {
    if (currentUserId == null) return Stream.value([]);
    return db
        .collection('clients')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => Client.fromFirestore(d)).toList());
  }

  Future<String> addClient(Client client) async {
    if (currentUserId == null) return '';
    final map = client.toMap();
    map['userId'] = currentUserId!;
    final ref = await db.collection('clients').add(map);
    return ref.id;
  }

  Future<void> updateClient(Client client) async {
    if (client.id != null) {
      await db.collection('clients').doc(client.id).update(client.toMap());
    }
  }

  Future<void> deleteClient(String id) async {
    await db.collection('clients').doc(id).delete();
  }

  Future<void> incrementClientVisit(
      String clientId, double amount,) async {
    await db.collection('clients').doc(clientId).update({
      'totalVisits': FieldValue.increment(1),
      'totalSpent': FieldValue.increment(amount),
      'lastVisit': FieldValue.serverTimestamp(),
    });
  }

  // ─── Analytics ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAnalytics({int days = 30}) async {
    if (currentUserId == null) return {};
    final since =
        DateTime.now().subtract(Duration(days: days));

    final snap = await db
        .collection('appointments')
        .where('userId', isEqualTo: currentUserId)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(since),)
        .get();

    final appointments =
        snap.docs.map((d) => Appointment.fromFirestore(d)).toList();

    final int total = appointments.length;
    final int confirmed =
        appointments.where((a) => a.status == 'confirmed').length;
    final int cancelled =
        appointments.where((a) => a.status == 'cancelled').length;
    final int completed =
        appointments.where((a) => a.status == 'completed').length;
    final double revenue = appointments
        .where((a) => a.status != 'cancelled')
        .fold(0.0, (acc, a) => acc + a.price);

    final Map<int, int> hourlyDist = {};
    for (final a in appointments) {
      hourlyDist[a.date.hour] = (hourlyDist[a.date.hour] ?? 0) + 1;
    }

    final double cancelRate = total > 0 ? (cancelled / total) * 100 : 0;

    return {
      'total': total,
      'confirmed': confirmed,
      'cancelled': cancelled,
      'completed': completed,
      'revenue': revenue,
      'cancelRate': cancelRate,
      'hourlyDistribution': hourlyDist,
    };
  }
}
