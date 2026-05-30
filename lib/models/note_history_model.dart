import 'package:cloud_firestore/cloud_firestore.dart';

class NoteHistory {
  final String? id;
  final String editorId;
  final String editorName;
  final String contentSnapshot;
  final DateTime timestamp;
  final String? editSummary;

  NoteHistory({
    this.id,
    required this.editorId,
    required this.editorName,
    required this.contentSnapshot,
    required this.timestamp,
    this.editSummary,
  });

  Map<String, dynamic> toMap() {
    return {
      'editorId': editorId,
      'editorName': editorName,
      'contentSnapshot': contentSnapshot,
      'timestamp': Timestamp.fromDate(timestamp),
      'editSummary': editSummary,
    };
  }

  factory NoteHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteHistory(
      id: doc.id,
      editorId: data['editorId'] ?? '',
      editorName: data['editorName'] ?? 'Düzenleyici',
      contentSnapshot: data['contentSnapshot'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      editSummary: data['editSummary'],
    );
  }
}
