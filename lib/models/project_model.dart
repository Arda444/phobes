import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String teamId;
  final String name;
  final String description;
  final String managerId;
  final String status;
  final DateTime? deadline;
  final int color;
  final DateTime? createdAt;

  Project({
    required this.id,
    required this.teamId,
    required this.name,
    this.description = '',
    required this.managerId,
    this.status = 'active',
    this.deadline,
    this.color = 0xFF6C63FF,
    this.createdAt,
  });

  Project copyWith({
    String? id,
    String? teamId,
    String? name,
    String? description,
    String? managerId,
    String? status,
    DateTime? deadline,
    int? color,
    DateTime? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      description: description ?? this.description,
      managerId: managerId ?? this.managerId,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'name': name,
      'description': description,
      'managerId': managerId,
      'status': status,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'color': color,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Project(
      id: doc.id,
      teamId: data['teamId'] as String? ?? '',
      name: data['name'] as String? ?? 'İsimsiz Proje',
      description: data['description'] as String? ?? '',
      managerId: data['managerId'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      deadline: data['deadline'] is Timestamp
          ? (data['deadline'] as Timestamp).toDate()
          : null,
      color: data['color'] as int? ?? 0xFF6C63FF,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  bool get isActive =>
      status == 'active' ||
      status == 'todo' ||
      status == 'in_progress' ||
      status == 'review';
  bool get isCompleted => status == 'completed' || status == 'done';
  bool get isArchived => status == 'archived';

  bool get isOverdue =>
      deadline != null &&
      deadline!.isBefore(DateTime.now()) &&
      !isCompleted &&
      !isArchived;
}
