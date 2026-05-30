import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Sayfa kenar boşluğu değerleri (mm cinsinden).
class PageMargins {
  final double top;
  final double right;
  final double bottom;
  final double left;

  const PageMargins({
    this.top = 25,
    this.right = 25,
    this.bottom = 25,
    this.left = 25,
  });

  factory PageMargins.normal() => const PageMargins();
  factory PageMargins.narrow() => const PageMargins(top: 12, right: 12, bottom: 12, left: 12);
  factory PageMargins.wide()   => const PageMargins(right: 50, left: 50);
  factory PageMargins.mirror() => const PageMargins(right: 20, left: 30);

  Map<String, dynamic> toMap() => {
    'top': top, 'right': right, 'bottom': bottom, 'left': left,
  };

  factory PageMargins.fromMap(Map<String, dynamic> m) => PageMargins(
    top:    (m['top']    ?? 25).toDouble(),
    right:  (m['right']  ?? 25).toDouble(),
    bottom: (m['bottom'] ?? 25).toDouble(),
    left:   (m['left']   ?? 25).toDouble(),
  );

  PageMargins copyWith({double? top, double? right, double? bottom, double? left}) =>
      PageMargins(
        top:    top    ?? this.top,
        right:  right  ?? this.right,
        bottom: bottom ?? this.bottom,
        left:   left   ?? this.left,
      );

  /// Preset adını döndürür (normal/narrow/wide/mirror/custom)
  String get presetName {
    if (top == 25 && right == 25 && bottom == 25 && left == 25) return 'normal';
    if (top == 12 && right == 12 && bottom == 12 && left == 12) return 'narrow';
    if (top == 25 && right == 50 && bottom == 25 && left == 50) return 'wide';
    if (top == 25 && right == 20 && bottom == 25 && left == 30) return 'mirror';
    return 'custom';
  }
}

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

  final List<String> sharedProjectIds;
  final String? teamId;
  final List<String> tags;
  final DateTime? updatedAt;

  final bool isArchived;
  final bool isFavorite;
  final String emoji;
  final List<String> linkedTaskIds;
  final String viewPermission;
  final String editPermission;
  final List<String> allowedUserIds;
  final String? lastEditedBy;
  final String? template;
  final String? notebookId;
  final List<String> headerStyles;
  final List<String> headerElements;

  final String pageSize;
  final String pageOrientation;
  final PageMargins pageMargins;
  final bool isLocked;
  final DateTime? deletedAt;

  Note({
    this.id,
    required this.userId,
    this.title = '',
    required this.date,
    required this.content,
    this.category = 'general',
    this.color = 0xFF6C63FF,
    this.isPinned = false,
    this.projectId,
    this.sharedProjectIds = const [],
    this.teamId,
    this.tags = const [],
    this.updatedAt,
    this.isArchived = false,
    this.isFavorite = false,
    this.emoji = '',
    this.linkedTaskIds = const [],
    this.viewPermission = 'owner',
    this.editPermission = 'owner',
    this.allowedUserIds = const [],
    this.lastEditedBy,
    this.template,
    this.notebookId,
    this.headerStyles = const ['modern'],
    this.headerElements = const ['main_title', 'meta_info'],
    this.pageSize = 'a4',
    this.pageOrientation = 'portrait',
    PageMargins? pageMargins,
    this.isLocked = false,
    this.deletedAt,
  }) : pageMargins = pageMargins ?? PageMargins.normal();

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
    List<String>? sharedProjectIds,
    String? teamId,
    List<String>? tags,
    DateTime? updatedAt,
    bool? isArchived,
    bool? isFavorite,
    String? emoji,
    List<String>? linkedTaskIds,
    String? viewPermission,
    String? editPermission,
    List<String>? allowedUserIds,
    String? lastEditedBy,
    String? template,
    String? notebookId,
    List<String>? headerStyles,
    List<String>? headerElements,
    String? pageSize,
    String? pageOrientation,
    PageMargins? pageMargins,
    bool? isLocked,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
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
      sharedProjectIds: sharedProjectIds ?? this.sharedProjectIds,
      teamId: teamId ?? this.teamId,
      tags: tags ?? this.tags,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      emoji: emoji ?? this.emoji,
      linkedTaskIds: linkedTaskIds ?? this.linkedTaskIds,
      viewPermission: viewPermission ?? this.viewPermission,
      editPermission: editPermission ?? this.editPermission,
      allowedUserIds: allowedUserIds ?? this.allowedUserIds,
      lastEditedBy: lastEditedBy ?? this.lastEditedBy,
      template: template ?? this.template,
      notebookId: notebookId ?? this.notebookId,
      headerStyles: headerStyles ?? this.headerStyles,
      headerElements: headerElements ?? this.headerElements,
      pageSize: pageSize ?? this.pageSize,
      pageOrientation: pageOrientation ?? this.pageOrientation,
      pageMargins: pageMargins ?? this.pageMargins,
      isLocked: isLocked ?? this.isLocked,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  /// Returns up to 150 characters of plain text extracted from the Quill Delta
  /// JSON. Handles both single-page (flat op-list) and multi-page (list of
  /// op-lists) content formats gracefully.
  String get preview {
    try {
      final decoded = jsonDecode(content);
      final ops = <dynamic>[];

      if (decoded is List) {
        if (decoded.isNotEmpty && decoded.first is List) {
          // Multi-page: [[op, ...], [op, ...], ...]
          for (final page in decoded) {
            if (page is List) ops.addAll(page);
          }
        } else {
          // Single-page: [op, ...]
          ops.addAll(decoded);
        }
      }

      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is Map && op['insert'] is String) {
          buffer.write(op['insert'] as String);
          if (buffer.length >= 150) break;
        }
      }
      final text = buffer.toString().trim().replaceAll('\n', ' ');
      return text.length > 150 ? '${text.substring(0, 150)}…' : text;
    } catch (_) {
      // Fallback for plain text or unparseable content
      final text = content.trim();
      return text.length > 150 ? '${text.substring(0, 150)}…' : text;
    }
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
      'sharedProjectIds': sharedProjectIds,
      'teamId': teamId,
      'tags': tags,
      'updatedAt': FieldValue.serverTimestamp(),
      'isArchived': isArchived,
      'isFavorite': isFavorite,
      'emoji': emoji,
      'linkedTaskIds': linkedTaskIds,
      'viewPermission': viewPermission,
      'editPermission': editPermission,
      'allowedUserIds': allowedUserIds,
      'lastEditedBy': lastEditedBy,
      'template': template,
      'notebookId': notebookId,
      'headerStyles': headerStyles,
      'headerElements': headerElements,
      'pageSize': pageSize,
      'pageOrientation': pageOrientation,
      'pageMargins': pageMargins.toMap(),
      'isLocked': isLocked,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }

  bool get isShared => teamId != null || projectId != null || allowedUserIds.isNotEmpty || viewPermission != 'owner';

  factory Note.fromFirestore(DocumentSnapshot doc) =>
      Note.fromDocData(doc.id, doc.data());

  /// Parses Firestore document fields without requiring a [DocumentSnapshot].
  factory Note.fromDocData(String id, Object? raw) {
    final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    return Note(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      content: data['content'] ?? '',
      category: data['category'] ?? 'general',
      color: data['color'] ?? 0xFF6C63FF,
      isPinned: data['isPinned'] ?? false,
      projectId: data['projectId'],
      sharedProjectIds: (data['sharedProjectIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      teamId: data['teamId'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isArchived: data['isArchived'] ?? false,
      isFavorite: data['isFavorite'] ?? false,
      emoji: data['emoji'] ?? '',
      linkedTaskIds: data['linkedTaskIds'] != null
          ? List<String>.from(data['linkedTaskIds'])
          : [],
      viewPermission: data['viewPermission'] ?? 'owner',
      editPermission: data['editPermission'] ?? 'owner',
      allowedUserIds: data['allowedUserIds'] != null
          ? List<String>.from(data['allowedUserIds'])
          : [],
      lastEditedBy: data['lastEditedBy'],
      template: data['template'],
      notebookId: data['notebookId'],
      headerStyles: data['headerStyles'] != null ? List<String>.from(data['headerStyles']) : const ['modern'],
      headerElements: data['headerElements'] != null ? List<String>.from(data['headerElements']) : const ['main_title', 'meta_info'],
      pageSize: data['pageSize'] ?? 'a4',
      pageOrientation: data['pageOrientation'] ?? 'portrait',
      pageMargins: data['pageMargins'] != null
          ? PageMargins.fromMap(Map<String, dynamic>.from(data['pageMargins']))
          : PageMargins.normal(),
      isLocked: data['isLocked'] ?? false,
      deletedAt: data['deletedAt'] is Timestamp
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
