import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final List<String> adminIds;
  final String joinCode;
  final DateTime? createdAt;

  Team({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    required this.adminIds,
    required this.joinCode,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'joinCode': joinCode,
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
