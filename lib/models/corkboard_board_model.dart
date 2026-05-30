import 'package:cloud_firestore/cloud_firestore.dart';

class CorkboardBoard {
  final String? id;
  final String userId;
  final String? teamId;
  final String title;
  final int sortOrder;
  final DateTime createdAt;

  CorkboardBoard({
    this.id,
    required this.userId,
    this.teamId,
    required this.title,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CorkboardBoard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CorkboardBoard(
      id: doc.id,
      userId: data['userId'] ?? '',
      teamId: data['teamId'],
      title: data['title'] ?? 'Pano',
      sortOrder: data['sortOrder'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'teamId': teamId,
      'title': title,
      'sortOrder': sortOrder,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  CorkboardBoard copyWith({
    String? id,
    String? userId,
    String? teamId,
    String? title,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return CorkboardBoard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      teamId: teamId ?? this.teamId,
      title: title ?? this.title,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
