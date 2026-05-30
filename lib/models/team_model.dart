import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final List<String> adminIds;
  final String joinCode;
  final int color;
  final DateTime? createdAt;

  Team({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    required this.adminIds,
    required this.joinCode,
    this.color = 0xFF6366F1,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'joinCode': joinCode,
      'color': color,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Team.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      return Team(
        id: doc.id,
        name: 'Hatalı Takım',
        ownerId: '',
        memberIds: [],
        adminIds: [],
        joinCode: '---',
      );
    }

    return Team(
      id: doc.id,
      name: data['name'] as String? ?? 'İsimsiz Takım',
      ownerId: data['ownerId'] as String? ?? '',
      joinCode: data['joinCode'] as String? ?? '',
      color: data['color'] as int? ?? 0xFF6366F1,
      memberIds: (data['memberIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      adminIds: (data['adminIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
