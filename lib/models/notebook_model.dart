import 'package:cloud_firestore/cloud_firestore.dart';

class Notebook {
  final String? id;
  final String userId;
  final String name;
  final String icon;
  final int color;
  final int order;
  final DateTime createdAt;

  Notebook({
    this.id,
    required this.userId,
    required this.name,
    this.icon = '📓',
    this.color = 0xFF6C63FF,
    this.order = 0,
    required this.createdAt,
  });

  Notebook copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    int? color,
    int? order,
    DateTime? createdAt,
  }) {
    return Notebook(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Notebook.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    return Notebook(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      icon: data['icon'] ?? '📓',
      color: data['color'] ?? 0xFF6C63FF,
      order: data['order'] ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
