import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String? id;
  final String userId;
  final String title;
  final DateTime date;
  final String content;
  final String category;
  final int color;
  final bool isPinned;
  final String? projectId;
  final String? teamId;
  final List<String> tags;
  final DateTime? updatedAt;

  Note({
    this.id,
    required this.userId,
    this.title = '',
    required this.date,
    required this.content,
    this.category = 'Genel',
    this.color = 0xFF6C63FF,
    this.isPinned = false,
    this.projectId,
    this.teamId,
    this.tags = const [],
    this.updatedAt,
  });

  Note copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? date,
    String? content,
    String? category,
    int? color,
    bool? isPinned,
    String? projectId,
    String? teamId,
    List<String>? tags,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      content: content ?? this.content,
      category: category ?? this.category,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      projectId: projectId ?? this.projectId,
      teamId: teamId ?? this.teamId,
      tags: tags ?? this.tags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get preview {
    return content.length > 100 ? content.substring(0, 100) : content;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'date': Timestamp.fromDate(date),
      'content': content,
      'category': category,
      'color': color,
      'isPinned': isPinned,
      'projectId': projectId,
      'teamId': teamId,
      'tags': tags,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      content: data['content'] ?? '',
      category: data['category'] ?? 'Genel',
      color: data['color'] ?? 0xFF6C63FF,
      isPinned: data['isPinned'] ?? false,
      projectId: data['projectId'],
      teamId: data['teamId'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
