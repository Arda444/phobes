import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String? id;
  final String userId;
  final String? clientId;
  final String? groupId;
  final String title;
  final String clientName;
  final String? phoneNumber;
  final DateTime date;
  final int durationMinutes;
  final String status;
  final String? notes;

  Appointment({
    this.id,
    required this.userId,
    this.clientId,
    this.groupId,
    required this.title,
    required this.clientName,
    this.phoneNumber,
    required this.date,
    this.durationMinutes = 60,
    this.status = 'pending',
    this.notes,
  });

  DateTime get endTime => date.add(Duration(minutes: durationMinutes));

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'clientId': clientId,
      'groupId': groupId,
      'title': title,
      'clientName': clientName,
      'phoneNumber': phoneNumber,
      'date': Timestamp.fromDate(date),
      'durationMinutes': durationMinutes,
      'status': status,
      'notes': notes,
    };
  }

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      userId: data['userId'] ?? '',
      clientId: data['clientId'],
      groupId: data['groupId'],
      title: data['title'] ?? '',
      clientName: data['clientName'] ?? '',
      phoneNumber: data['phoneNumber'],
      date: (data['date'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 60,
      status: data['status'] ?? 'pending',
      notes: data['notes'],
    );
  }

  Appointment copyWith({
    String? title,
    String? clientName,
    String? phoneNumber,
    DateTime? date,
    int? durationMinutes,
    String? status,
    String? notes,
    String? clientId,
  }) {
    return Appointment(
      id: id,
      userId: userId,
      clientId: clientId ?? this.clientId,
      groupId: groupId,
      title: title ?? this.title,
      clientName: clientName ?? this.clientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
