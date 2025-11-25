import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLog {
  final String id;
  final String teamId;
  final String userId;
  final String userName;
  final String action; // 'create', 'complete', 'join' vb.
  final String details;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.userName,
    required this.action,
    required this.details,
    required this.timestamp,
  });

  factory ActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityLog(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Bilinmeyen',
      action: data['action'] ?? '',
      details: data['details'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
