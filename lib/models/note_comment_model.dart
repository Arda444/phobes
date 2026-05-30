import 'package:cloud_firestore/cloud_firestore.dart';

class NoteComment {
  final String? id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String text;
  final DateTime timestamp;

  NoteComment({
    this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl = '',
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory NoteComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteComment(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonim',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
