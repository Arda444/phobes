import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String? id;
  final String userId;
  final String? clientId;
  final String? groupId;
  final String title;
  final String clientName;
  final String? phoneNumber;
  final String? email;
  final DateTime date;
  final int durationMinutes;
  final String status;
  final String? notes;
  final int reminderMinutes;
  final int color;
  final double price;
  final String currency;
  final String recurrence;
  final String? recurrenceGroupId;
  final String? cancelReason;
  final DateTime? confirmedAt;

  Appointment({
    this.id,
    required this.userId,
    this.clientId,
    this.groupId,
    required this.title,
    required this.clientName,
    this.phoneNumber,
    this.email,
    required this.date,
    this.durationMinutes = 60,
    this.status = 'pending',
    this.notes,
    this.reminderMinutes = -1,
    this.color = 0xFF8B5CF6,
    this.price = 0.0,
    this.currency = 'TL',
    this.recurrence = 'none',
    this.recurrenceGroupId,
    this.cancelReason,
    this.confirmedAt,
  });

  DateTime get endTime => date.add(Duration(minutes: durationMinutes));

  bool get isPast => date.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'clientId': clientId,
      'groupId': groupId,
      'title': title,
      'clientName': clientName,
      'phoneNumber': phoneNumber,
      'email': email,
      'date': Timestamp.fromDate(date),
      'durationMinutes': durationMinutes,
      'status': status,
      'notes': notes,
      'reminderMinutes': reminderMinutes,
      'color': color,
      'price': price,
      'currency': currency,
      'recurrence': recurrence,
      'recurrenceGroupId': recurrenceGroupId,
      'cancelReason': cancelReason,
      'confirmedAt':
          confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
    };
  }

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    return Appointment(
      id: doc.id,
      userId: data['userId'] ?? '',
      clientId: data['clientId'],
      groupId: data['groupId'],
      title: data['title'] ?? '',
      clientName: data['clientName'] ?? '',
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      durationMinutes: data['durationMinutes'] ?? 60,
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      reminderMinutes: data['reminderMinutes'] ?? -1,
      color: data['color'] ?? 0xFF8B5CF6,
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'TL',
      recurrence: data['recurrence'] ?? 'none',
      recurrenceGroupId: data['recurrenceGroupId'],
      cancelReason: data['cancelReason'],
      confirmedAt: data['confirmedAt'] is Timestamp
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Appointment copyWith({
    String? title,
    String? clientName,
    String? phoneNumber,
    String? email,
    DateTime? date,
    int? durationMinutes,
    String? status,
    String? notes,
    String? clientId,
    String? groupId,
    int? reminderMinutes,
    int? color,
    double? price,
    String? currency,
    String? recurrence,
    String? recurrenceGroupId,
    String? cancelReason,
    DateTime? confirmedAt,
  }) {
    return Appointment(
      id: id,
      userId: userId,
      clientId: clientId ?? this.clientId,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      clientName: clientName ?? this.clientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      color: color ?? this.color,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      recurrence: recurrence ?? this.recurrence,
      recurrenceGroupId: recurrenceGroupId ?? this.recurrenceGroupId,
      cancelReason: cancelReason ?? this.cancelReason,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }
}
