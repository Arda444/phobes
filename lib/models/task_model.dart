import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String? id;
  final String userId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String url;
  final List<String> tags;
  final bool isAllDay;
  final int color;
  final int priority;
  final int reminderMinutes;
  final bool isCompleted;
  final DateTime? completionTime;
  final int postponeCount;
  final String repeatRule;

  final String? groupId;
  final List<String> assignedTo; // DEĞİŞTİ: Artık Liste
  final String? createdBy;
  final String status;

  Task({
    this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.url = '',
    this.tags = const [],
    this.isAllDay = false,
    this.color = 0xFF4285F4,
    this.priority = 1,
    this.reminderMinutes = -1,
    this.isCompleted = false,
    this.completionTime,
    this.postponeCount = 0,
    this.repeatRule = 'none',
    this.groupId,
    this.assignedTo = const [], // Varsayılan boş liste
    this.createdBy,
    this.status = 'todo',
  });

  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? url,
    List<String>? tags,
    bool? isAllDay,
    int? color,
    int? priority,
    int? reminderMinutes,
    bool? isCompleted,
    DateTime? completionTime,
    int? postponeCount,
    String? repeatRule,
    String? groupId,
    List<String>? assignedTo, // DEĞİŞTİ
    String? createdBy,
    String? status,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      url: url ?? this.url,
      tags: tags ?? this.tags,
      isAllDay: isAllDay ?? this.isAllDay,
      color: color ?? this.color,
      priority: priority ?? this.priority,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      completionTime: completionTime ?? this.completionTime,
      postponeCount: postponeCount ?? this.postponeCount,
      repeatRule: repeatRule ?? this.repeatRule,
      groupId: groupId ?? this.groupId,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'url': url,
      'tags': tags,
      'isAllDay': isAllDay,
      'color': color,
      'priority': priority,
      'reminderMinutes': reminderMinutes,
      'isCompleted': isCompleted,
      'completionTime':
          completionTime != null ? Timestamp.fromDate(completionTime!) : null,
      'postponeCount': postponeCount,
      'repeatRule': repeatRule,
      'groupId': groupId,
      'assignedTo': assignedTo, // Liste olarak kaydet
      'createdBy': createdBy,
      'status': status,
    };
  }

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Eski verilerle uyumluluk için kontrol (String gelirse listeye çevir)
    List<String> assignedList = [];
    if (data['assignedTo'] is String) {
      assignedList = [data['assignedTo']];
    } else if (data['assignedTo'] is List) {
      assignedList = List<String>.from(data['assignedTo']);
    }

    return Task(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      url: data['url'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      isAllDay: data['isAllDay'] ?? false,
      color: data['color'] ?? 0xFF4285F4,
      priority: data['priority'] ?? 1,
      reminderMinutes: data['reminderMinutes'] ?? -1,
      isCompleted: data['isCompleted'] ?? false,
      completionTime: data['completionTime'] != null
          ? (data['completionTime'] as Timestamp).toDate()
          : null,
      postponeCount: data['postponeCount'] ?? 0,
      repeatRule: data['repeatRule'] ?? 'none',
      groupId: data['groupId'],
      assignedTo: assignedList,
      createdBy: data['createdBy'],
      status: data['status'] ?? 'todo',
    );
  }
}
