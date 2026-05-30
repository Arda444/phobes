import 'package:cloud_firestore/cloud_firestore.dart';

enum CorkItemType { note, taskRef, noteRef, image, link }

/// Default square note size (width = height).
const double kCorkDefaultSize = 220;
const double kCorkMinSize = 120;
const double kCorkMaxSize = 420;

class CorkboardItem {
  final String? id;
  final String userId;
  final String? teamId;
  final String? boardId;
  final CorkItemType type;
  final String content;
  final double posX;
  final double posY;
  final double rotation;
  final double size;
  final int color;
  final DateTime createdAt;

  CorkboardItem({
    this.id,
    required this.userId,
    this.teamId,
    this.boardId,
    required this.type,
    required this.content,
    this.posX = 0,
    this.posY = 0,
    this.rotation = 0,
    this.size = kCorkDefaultSize,
    this.color = 0xFFFFF9C4,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CorkboardItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CorkboardItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      teamId: data['teamId'],
      boardId: data['boardId'],
      type: CorkItemType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'note'),
        orElse: () => CorkItemType.note,
      ),
      content: data['content'] ?? '',
      posX: (data['posX'] as num?)?.toDouble() ?? 0.0,
      posY: (data['posY'] as num?)?.toDouble() ?? 0.0,
      rotation: (data['rotation'] as num?)?.toDouble() ?? 0.0,
      size: (data['size'] as num?)?.toDouble() ??
          (data['width'] as num?)?.toDouble() ??
          kCorkDefaultSize,
      color: data['color'] as int? ?? 0xFFFFF9C4,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'teamId': teamId,
      'boardId': boardId,
      'type': type.name,
      'content': content,
      'posX': posX,
      'posY': posY,
      'rotation': rotation,
      'size': size,
      'color': color,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  CorkboardItem copyWith({
    String? id,
    String? userId,
    String? teamId,
    String? boardId,
    CorkItemType? type,
    String? content,
    double? posX,
    double? posY,
    double? rotation,
    double? size,
    int? color,
    DateTime? createdAt,
  }) {
    return CorkboardItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      teamId: teamId ?? this.teamId,
      boardId: boardId ?? this.boardId,
      type: type ?? this.type,
      content: content ?? this.content,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      rotation: rotation ?? this.rotation,
      size: size ?? this.size,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
