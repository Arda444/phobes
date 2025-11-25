import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final List<String> adminIds; // YENİ: Yöneticiler listesi
  final String joinCode;
  final DateTime? createdAt;

  Team({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    required this.adminIds, // Constructor'a eklendi
    required this.joinCode,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'adminIds': adminIds, // Map'e eklendi
      'joinCode': joinCode,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // GÜVENLİ FACTORY METODU
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

      // Üye listesini güvenli çek
      memberIds: (data['memberIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],

      // YENİ: Yönetici listesini güvenli çek
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
