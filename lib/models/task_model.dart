import 'package:cloud_firestore/cloud_firestore.dart';

class SubTask {
  final String id;
  final String title;
  final bool isCompleted;

  SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  SubTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

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
  /// Shared ID for all tasks in the same recurring series (null = not recurring).
  final String? recurrenceGroupId;

  final String? groupId;
  /// Parent team when [groupId] is a project id or team id.
  final String? teamId;
  final List<String> assignedTo;
  final String? createdBy;
  final String status;
  final List<SubTask> subtasks;
  final List<String> linkedNoteIds;

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
    this.recurrenceGroupId,
    this.groupId,
    this.teamId,
    this.assignedTo = const [],
    this.createdBy,
    this.status = 'todo',
    this.subtasks = const [],
    this.linkedNoteIds = const [],
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
    String? recurrenceGroupId,
    bool clearRecurrenceGroupId = false,
    String? groupId,
    String? teamId,
    bool clearTeamId = false,
    List<String>? assignedTo,
    String? createdBy,
    String? status,
    List<SubTask>? subtasks,
    List<String>? linkedNoteIds,
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
      recurrenceGroupId: clearRecurrenceGroupId
          ? null
          : (recurrenceGroupId ?? this.recurrenceGroupId),
      groupId: groupId ?? this.groupId,
      teamId: clearTeamId ? null : (teamId ?? this.teamId),
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      subtasks: subtasks ?? this.subtasks,
      linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
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
      if (recurrenceGroupId != null) 'recurrenceGroupId': recurrenceGroupId,
      'groupId': groupId,
      if (teamId != null) 'teamId': teamId,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'status': status,
      'subtasks': subtasks.map((st) => st.toMap()).toList(),
      'linkedNoteIds': linkedNoteIds,
    };
  }

  factory Task.fromFirestore(DocumentSnapshot doc) =>
      Task.fromDocData(doc.id, doc.data());

  /// Parses Firestore document fields without requiring a [DocumentSnapshot].
  factory Task.fromDocData(String id, Object? raw) {
    final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};

    List<String> assignedList = [];
    if (data['assignedTo'] is String) {
      assignedList = [data['assignedTo'] as String];
    } else if (data['assignedTo'] is List) {
      assignedList = (data['assignedTo'] as List).whereType<String>().toList();
    }

    return Task(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: data['startTime'] is Timestamp ? (data['startTime'] as Timestamp).toDate() : DateTime.now(),
      endTime: data['endTime'] is Timestamp ? (data['endTime'] as Timestamp).toDate() : DateTime.now(),
      location: data['location'] ?? '',
      url: data['url'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      isAllDay: data['isAllDay'] ?? false,
      color: data['color'] ?? 0xFF4285F4,
      priority: data['priority'] ?? 1,
      reminderMinutes: data['reminderMinutes'] ?? -1,
      isCompleted: data['isCompleted'] ?? false,
      completionTime: data['completionTime'] is Timestamp
          ? (data['completionTime'] as Timestamp).toDate()
          : null,
      postponeCount: data['postponeCount'] ?? 0,
      repeatRule: data['repeatRule'] ?? 'none',
      recurrenceGroupId: data['recurrenceGroupId'],
      groupId: data['groupId'] as String?,
      teamId: data['teamId'] as String?,
      assignedTo: assignedList,
      createdBy: data['createdBy'],
      status: data['status'] ?? 'todo',
      subtasks: data['subtasks'] is List
          ? (data['subtasks'] as List)
              .whereType<Map>()
              .map((map) => SubTask.fromMap(Map<String, dynamic>.from(map)))
              .toList()
          : [],
      linkedNoteIds: data['linkedNoteIds'] != null
          ? List<String>.from(data['linkedNoteIds'])
          : [],
    );
  }
}
