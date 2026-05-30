import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String? id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? targetId;
  final String? targetType;
  final DateTime createdAt;
  final bool isRead;
  final String icon;
  final int color;

  AppNotification({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.targetId,
    this.targetType,
    DateTime? createdAt,
    this.isRead = false,
    this.icon = '🔔',
    this.color = 0xFF6C63FF,
  }) : createdAt = createdAt ?? DateTime.now();

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    String? targetId,
    String? targetType,
    DateTime? createdAt,
    bool? isRead,
    String? icon,
    int? color,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'targetId': targetId,
      'targetType': targetType,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'icon': icon,
      'color': color,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String docId) {
    return AppNotification(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'system',
      targetId: map['targetId'],
      targetType: map['targetType'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      icon: map['icon'] ?? '🔔',
      color: map['color'] ?? 0xFF6C63FF,
    );
  }
}
