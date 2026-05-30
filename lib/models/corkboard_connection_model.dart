import 'package:cloud_firestore/cloud_firestore.dart';

class CorkboardConnection {
  final String? id;
  final String fromId;
  final String toId;
  final int color;
  final double thickness;
  final String? userId;
  final String? teamId;
  final String? boardId;

  CorkboardConnection({
    this.id,
    required this.fromId,
    required this.toId,
    this.color = 0xFFFF5252, // Default red string
    this.thickness = 2.0,
    this.userId,
    this.teamId,
    this.boardId,
  });

  factory CorkboardConnection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CorkboardConnection(
      id: doc.id,
      fromId: data['fromId'] ?? '',
      toId: data['toId'] ?? '',
      color: data['color'] ?? 0xFFFF5252,
      thickness: (data['thickness'] ?? 2.0).toDouble(),
      userId: data['userId'],
      teamId: data['teamId'],
      boardId: data['boardId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromId': fromId,
      'toId': toId,
      'color': color,
      'thickness': thickness,
      'userId': userId,
      'teamId': teamId,
      'boardId': boardId,
    };
  }
}
