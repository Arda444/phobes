import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String? id;
  final String userId;
  final String name;
  final String? phone;
  final String? email;
  final String? note;
  final String? address;
  final List<String> tags;
  final int totalVisits;
  final double totalSpent;
  final DateTime? lastVisit;
  final DateTime createdAt;

  Client({
    this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.email,
    this.note,
    this.address,
    this.tags = const [],
    this.totalVisits = 0,
    this.totalSpent = 0.0,
    this.lastVisit,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'note': note,
      'address': address,
      'tags': tags,
      'totalVisits': totalVisits,
      'totalSpent': totalSpent,
      'lastVisit': lastVisit != null ? Timestamp.fromDate(lastVisit!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Client.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Client(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      email: data['email'],
      note: data['note'],
      address: data['address'],
      tags: List<String>.from(data['tags'] ?? []),
      totalVisits: data['totalVisits'] ?? 0,
      totalSpent: (data['totalSpent'] ?? 0).toDouble(),
      lastVisit: data['lastVisit'] is Timestamp
          ? (data['lastVisit'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Client copyWith({
    String? name,
    String? phone,
    String? email,
    String? note,
    String? address,
    List<String>? tags,
    int? totalVisits,
    double? totalSpent,
    DateTime? lastVisit,
  }) {
    return Client(
      id: id,
      userId: userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      note: note ?? this.note,
      address: address ?? this.address,
      tags: tags ?? this.tags,
      totalVisits: totalVisits ?? this.totalVisits,
      totalSpent: totalSpent ?? this.totalSpent,
      lastVisit: lastVisit ?? this.lastVisit,
      createdAt: createdAt,
    );
  }
}
