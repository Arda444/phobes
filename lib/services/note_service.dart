import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/note_model.dart';
import '../models/notebook_model.dart';
import '../models/note_comment_model.dart';
import '../models/note_history_model.dart';
import 'base_firebase_service.dart';

class NoteService extends BaseFirebaseService {
  static final NoteService _instance = NoteService._internal();
  factory NoteService() => _instance;
  NoteService._internal();

  Future<String?> addNote(Note note) async {
    if (currentUserId == null) return null;
    try {
      final noteMap = note.toMap();
      noteMap['userId'] = currentUserId;
      final ref = await db.collection('notes').add(noteMap);
      if (note.teamId != null) {
        await logTeamActivity(note.teamId!, 'note_created', note.title);
      }
      return ref.id;
    } catch (e) {
      debugPrint('[NoteService.addNote] error: $e');
      rethrow;
    }
  }

  Future<String?> duplicateNote(Note note) async {
    if (currentUserId == null) return null;
    final copy = Note(
      userId: note.userId,
      title: 'Kopya — ${note.title}',
      date: DateTime.now(),
      content: note.content,
      category: note.category,
      color: note.color,
      tags: note.tags,
      updatedAt: DateTime.now(),
      notebookId: note.notebookId,
      emoji: note.emoji,
      pageSize: note.pageSize,
      pageOrientation: note.pageOrientation,
      pageMargins: note.pageMargins,
    );
    return addNote(copy);
  }

  Stream<List<Note>> getNotesStream() {
    if (currentUserId == null) return Stream.value([]);
    // deletedAt filter is applied at Firestore level to avoid downloading
    // soft-deleted notes — each downloaded doc costs a read.
    return db
        .collection('notes')
        .where(Filter.and(
          Filter('deletedAt', isNull: true),
          Filter.or(
            Filter('userId', isEqualTo: currentUserId),
            Filter('allowedUserIds', arrayContains: currentUserId),
          ),
        ),)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Note.fromFirestore(d)).toList(),);
  }

  Stream<List<Note>> getTeamNotesStream(String teamId) {
    return db
        .collection('notes')
        .where('teamId', isEqualTo: teamId)
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Note.fromFirestore(d)).toList(),);
  }

  Future<void> updateNote(Note note) async {
    if (note.id == null || currentUserId == null) return;
    try {
      final updated = note.copyWith(
        updatedAt: DateTime.now(),
        lastEditedBy: currentUserId,
      );
      final isOwner = note.userId == currentUserId;
      final isCollaborator =
          !isOwner && note.allowedUserIds.contains(currentUserId);

      if (isCollaborator) {
        await db.collection('notes').doc(note.id).update({
          'title': updated.title,
          'content': updated.content,
          'tags': updated.tags,
          'updatedAt': FieldValue.serverTimestamp(),
          'isPinned': updated.isPinned,
          'isFavorite': updated.isFavorite,
          'isArchived': updated.isArchived,
          'deletedAt': updated.deletedAt != null
              ? Timestamp.fromDate(updated.deletedAt!)
              : null,
          'notebookId': updated.notebookId,
          'color': updated.color,
          'emoji': updated.emoji,
          'lastEditedBy': currentUserId,
        });
      } else {
        await db.collection('notes').doc(note.id).update(updated.toMap());
      }
    } catch (e) {
      debugPrint('[NoteService.updateNote] error: $e');
      rethrow;
    }
  }

  Future<void> deleteNote(String noteId) async {
    await db.collection('notes').doc(noteId).delete();
  }

  Future<void> archiveNote(String noteId) async {
    await db.collection('notes').doc(noteId).update({'isArchived': true});
  }

  Future<void> unarchiveNote(String noteId) async {
    await db.collection('notes').doc(noteId).update({'isArchived': false});
  }

  Future<void> toggleNoteFavorite(String noteId, bool isFavorite) async {
    await db
        .collection('notes')
        .doc(noteId)
        .update({'isFavorite': isFavorite});
  }

  Future<void> toggleNoteLock(String noteId, bool isLocked) async {
    await db
        .collection('notes')
        .doc(noteId)
        .update({'isLocked': isLocked});
  }

  Future<void> moveToTrash(String noteId) async {
    await db.collection('notes').doc(noteId).update({
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> restoreNote(String noteId) async {
    await db
        .collection('notes')
        .doc(noteId)
        .update({'deletedAt': null});
  }

  Stream<List<Note>> getTrashStream() {
    if (currentUserId == null) return Stream.value([]);
    // orderBy('deletedAt') null değerleri otomatik dışladığı için ek bir
    // isNull: false filtresine (ve yeni indexe) gerek kalmıyor.
    return db
        .collection('notes')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('deletedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Note.fromFirestore(d)).toList());
  }

  Future<void> updateNotePermissions(
    String noteId, {
    required String viewPermission,
    required String editPermission,
    List<String>? allowedUserIds,
  }) async {
    await db.collection('notes').doc(noteId).update({
      'viewPermission': viewPermission,
      'editPermission': editPermission,
      if (allowedUserIds != null) 'allowedUserIds': allowedUserIds,
    });
  }

  Stream<List<Note>> getArchivedNotesStream() {
    if (currentUserId == null) return Stream.value([]);
    return db
        .collection('notes')
        .where(Filter.or(
          Filter('userId', isEqualTo: currentUserId),
          Filter('allowedUserIds', arrayContains: currentUserId),
        ),)
        .where('isArchived', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Note.fromFirestore(d)).toList(),);
  }

  Stream<List<Note>> getProjectNotesStream(String projectId) {
    if (currentUserId == null) return Stream.value([]);
    // userId/allowedUserIds filtresi olmadan Firestore Rules sorguyu reddediyor.
    return db
        .collection('notes')
        .where(Filter.and(
          Filter('projectId', isEqualTo: projectId),
          Filter('deletedAt', isNull: true),
          Filter.or(
            Filter('userId', isEqualTo: currentUserId),
            Filter('allowedUserIds', arrayContains: currentUserId),
          ),
        ),)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Note.fromFirestore(d)).toList(),);
  }

  Future<void> linkTaskToNote(String noteId, String taskId) async {
    final batch = db.batch();
    batch.update(db.collection('notes').doc(noteId), {
      'linkedTaskIds': FieldValue.arrayUnion([taskId]),
    });
    batch.update(db.collection('tasks').doc(taskId), {
      'linkedNoteIds': FieldValue.arrayUnion([noteId]),
    });
    await batch.commit();
  }

  Future<void> unlinkTaskFromNote(String noteId, String taskId) async {
    final batch = db.batch();
    batch.update(db.collection('notes').doc(noteId), {
      'linkedTaskIds': FieldValue.arrayRemove([taskId]),
    });
    batch.update(db.collection('tasks').doc(taskId), {
      'linkedNoteIds': FieldValue.arrayRemove([noteId]),
    });
    await batch.commit();
  }

  Future<void> addNoteComment(String noteId, NoteComment comment) async {
    if (currentUserId == null) return;
    final map = comment.toMap();
    map['userId'] = currentUserId!;
    map['userName'] = currentUser?.displayName ?? comment.userName;
    await db.collection('notes').doc(noteId).collection('comments').add(map);
  }

  Stream<List<NoteComment>> getNoteCommentsStream(String noteId) {
    return db
        .collection('notes')
        .doc(noteId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => NoteComment.fromFirestore(d)).toList(),);
  }

  Future<void> saveNoteVersion(String noteId, NoteHistory history) async {
    final col =
        db.collection('notes').doc(noteId).collection('history');
    await col.add(history.toMap());
    final countSnap = await col.count().get();
    if ((countSnap.count ?? 0) <= 5) return;
    final snap =
        await col.orderBy('timestamp', descending: true).get();
    if (snap.docs.length > 5) {
      final batch = db.batch();
      for (var i = 5; i < snap.docs.length; i++) {
        batch.delete(snap.docs[i].reference);
      }
      await batch.commit();
    }
  }

  Stream<List<NoteHistory>> getNoteHistoryStream(String noteId) {
    return db
        .collection('notes')
        .doc(noteId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => NoteHistory.fromFirestore(d)).toList(),);
  }

  Future<void> addNotebook(Notebook notebook) async {
    if (currentUserId == null) return;
    await db.collection('notebooks').add(notebook.toMap());
  }

  Stream<List<Notebook>> getNotebooksStream() {
    if (currentUserId == null) return Stream.value([]);
    return db
        .collection('notebooks')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => Notebook.fromFirestore(d)).toList();
          list.sort((a, b) => a.order.compareTo(b.order));
          return list;
        });
  }

  Future<void> updateNotebook(Notebook notebook) async {
    if (notebook.id == null) return;
    await db
        .collection('notebooks')
        .doc(notebook.id)
        .update(notebook.toMap());
  }

  Future<void> deleteNotebook(String notebookId) async {
    await db.collection('notebooks').doc(notebookId).delete();
    final notes = await db
        .collection('notes')
        .where('notebookId', isEqualTo: notebookId)
        .get();
    final batch = db.batch();
    for (final doc in notes.docs) {
      batch.update(doc.reference, {'notebookId': null});
    }
    await batch.commit();
  }

  Stream<List<Note>> getNotesByNotebookStream(String notebookId) {
    if (currentUserId == null) return Stream.value([]);
    // Defterler kullanıcıya özel; userId filtresi olmadan Firestore Rules
    // sorguyu reddediyor (permission-denied).
    return db
        .collection('notes')
        .where('userId', isEqualTo: currentUserId)
        .where('notebookId', isEqualTo: notebookId)
        .where('deletedAt', isNull: true)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Note.fromFirestore(d)).toList());
  }
}
