import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/book_club_model.dart';
import '../models/book_model.dart';

class BookClubService {
  static final BookClubService _instance = BookClubService._internal();
  factory BookClubService() => _instance;
  BookClubService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String _clubsCol(String teamId) => 'teams/$teamId/book_clubs';

  // ─── CRUD ──────────────────────────────────────────────────────────────────

  Stream<List<BookClub>> getClubsStream(String teamId) {
    return _db
        .collection(_clubsCol(teamId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BookClub.fromFirestore(d)).toList());
  }

  Stream<BookClub?> getActiveClubStream(String teamId) {
    return _db
        .collection(_clubsCol(teamId))
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : BookClub.fromFirestore(snap.docs.first));
  }

  Future<String?> createClub({
    required String teamId,
    required String name,
    required List<String> memberIds,
    required Map<String, String> memberNames,
  }) async {
    if (_uid == null) return null;
    try {
      final activeSnap = await _db
          .collection(_clubsCol(teamId))
          .where('isActive', isEqualTo: true)
          .get();
      if (activeSnap.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in activeSnap.docs) {
          batch.update(doc.reference, {'isActive': false});
        }
        await batch.commit();
      }
      final club = BookClub(
        teamId: teamId,
        name: name,
        createdBy: _uid!,
        createdAt: DateTime.now(),
        memberProgress: {for (final id in memberIds) id: 0},
        memberNames: memberNames,
      );
      final ref = await _db.collection(_clubsCol(teamId)).add(club.toMap());
      return ref.id;
    } catch (e) {
      debugPrint('[BookClubService.createClub] error: $e');
      rethrow;
    }
  }

  /// Sets (or changes) the current book for a club and resets all member progress.
  Future<void> setCurrentBook({
    required String teamId,
    required String clubId,
    required Book book,
    DateTime? targetFinishDate,
  }) async {
    try {
      // Fetch current member list to reset their progress.
      final doc =
          await _db.collection(_clubsCol(teamId)).doc(clubId).get();
      final club = BookClub.fromFirestore(doc);
      final resetProgress = {
        for (final uid in club.memberProgress.keys) uid: 0,
      };

      await _db.collection(_clubsCol(teamId)).doc(clubId).update({
        'bookTitle': book.title,
        'bookAuthors': book.authors,
        'bookPageCount': book.pageCount,
        'bookCoverUrl': book.coverUrl,
        'googleBooksId': book.googleBooksId,
        'startDate': FieldValue.serverTimestamp(),
        'targetFinishDate': targetFinishDate != null
            ? Timestamp.fromDate(targetFinishDate)
            : null,
        'memberProgress': resetProgress,
      });
    } catch (e) {
      debugPrint('[BookClubService.setCurrentBook] error: $e');
      rethrow;
    }
  }

  /// Updates the current user's reading progress in the club.
  Future<void> updateMyProgress({
    required String teamId,
    required String clubId,
    required int currentPage,
  }) async {
    if (_uid == null) return;
    try {
      await _db.collection(_clubsCol(teamId)).doc(clubId).update({
        'memberProgress.$_uid': currentPage,
      });
    } catch (e) {
      debugPrint('[BookClubService.updateMyProgress] error: $e');
      rethrow;
    }
  }

  Future<void> setTargetFinishDate({
    required String teamId,
    required String clubId,
    required DateTime date,
  }) async {
    try {
      await _db.collection(_clubsCol(teamId)).doc(clubId).update({
        'targetFinishDate': Timestamp.fromDate(date),
      });
    } catch (e) {
      debugPrint('[BookClubService.setTargetFinishDate] error: $e');
      rethrow;
    }
  }

  Future<void> deactivateClub({
    required String teamId,
    required String clubId,
  }) async {
    try {
      await _db
          .collection(_clubsCol(teamId))
          .doc(clubId)
          .update({'isActive': false});
    } catch (e) {
      debugPrint('[BookClubService.deactivateClub] error: $e');
      rethrow;
    }
  }

  Future<void> deleteClub({
    required String teamId,
    required String clubId,
  }) async {
    try {
      await _db.collection(_clubsCol(teamId)).doc(clubId).delete();
    } catch (e) {
      debugPrint('[BookClubService.deleteClub] error: $e');
      rethrow;
    }
  }
}
