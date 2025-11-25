import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String? id; // Firestore Document ID
  final String userId; // Notun sahibi
  final String title;
  final DateTime date;
  final String content; // Quill JSON içeriği

  Note({
    this.id,
    required this.userId,
    this.title = '',
    required this.date,
    required this.content,
  });

  Note copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? date,
    String? content,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      content: content ?? this.content,
    );
  }

  // Firebase'e gönderirken
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'date': Timestamp.fromDate(date), // DateTime -> Timestamp
      'content': content,
    };
  }

  // Firebase'den çekerken
  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp).toDate(), // Timestamp -> DateTime
      content: data['content'] ?? '',
    );
  }
}
