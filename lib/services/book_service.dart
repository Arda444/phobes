import 'dart:convert';
import 'dart:math' show Random;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

class BookService {
  static final BookService _instance = BookService._internal();
  factory BookService() => _instance;
  BookService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  String get _col => 'users/$_uid/user_books';

  static const _googleBooksBase = 'https://www.googleapis.com/books/v1/volumes';
  static const _openLibraryBase = 'https://openlibrary.org';

  static const _googleBooksApiKey = String.fromEnvironment('GOOGLE_BOOKS_API_KEY');

  /// Son aramada kullanıcıya gösterilebilecek uyarı (429, ağ hatası vb.).
  String? lastSearchNotice;

  Uri _googleBooksUri(String query, {required int maxResults}) {
    final params = <String, String>{
      'q': query,
      'maxResults': '$maxResults',
      'printType': 'books',
    };
    if (_googleBooksApiKey.isNotEmpty) {
      params['key'] = _googleBooksApiKey;
    }
    return Uri.parse(_googleBooksBase).replace(queryParameters: params);
  }

  // ─── Google Books API ──────────────────────────────────────────────────────

  Future<List<Book>> searchBooks(String query, {int maxResults = 40}) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = _googleBooksUri(query, maxResults: maxResults);
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode == 429) {
        lastSearchNotice =
            'Google Books geçici olarak sınırladı; Open Library kullanılıyor.';
        debugPrint('[BookService.searchBooks] HTTP 429 (rate limit)');
        return [];
      }
      if (response.statusCode != 200) {
        debugPrint(
          '[BookService.searchBooks] HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 120))}',
        );
        return [];
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];
      return items
          .map((item) => Book.fromGoogleBooksJson(item as Map<String, dynamic>))
          .where((b) => b.title.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[BookService.searchBooks] error: $e');
      return [];
    }
  }

  // ─── Open Library API ─────────────────────────────────────────────────────

  /// Searches Open Library — much better coverage for Turkish books.
  Future<List<Book>> searchOpenLibrary(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) return [];
    try {
      const fields =
          'key,title,author_name,isbn,cover_i,number_of_pages_median,subject,first_publish_year,publisher';
      final uri = Uri.parse(
        '$_openLibraryBase/search.json'
        '?q=${Uri.encodeComponent(query)}'
        '&limit=$limit'
        '&fields=$fields',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        debugPrint('[BookService.searchOpenLibrary] HTTP ${response.statusCode}');
        if (response.statusCode == 403 || response.statusCode == 0) {
          lastSearchNotice =
              'Kitap API\'sine erişilemedi. Web sürümünü yenileyin veya ağı kontrol edin.';
        }
        return [];
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = data['docs'] as List? ?? [];
      return docs
          .map((d) => Book.fromOpenLibraryJson(d as Map<String, dynamic>))
          .where((b) => b.title.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[BookService.searchOpenLibrary] error: $e');
      lastSearchNotice ??=
          'Kitap araması başarısız. İnternet bağlantınızı kontrol edin.';
      return [];
    }
  }

  /// Searches Open Library by ISBN — most precise lookup.
  Future<List<Book>> searchOpenLibraryByIsbn(String isbn) async {
    return searchOpenLibrary('isbn:$isbn', limit: 5);
  }

  // ─── Combined search ───────────────────────────────────────────────────────

  /// Runs Google Books + Open Library in parallel, merges and deduplicates.
  /// Preference order: if Google Books has a result for the same book, keep it
  /// (richer description/cover); add Open Library exclusives at the end.
  Future<List<Book>> searchCombined(String query, {int maxEach = 30}) async {
    // Open Library önce — Türkçe katalog + web CSP'de kritik yedek.
    final olBooks = await searchOpenLibrary(query, limit: maxEach);
    final googleBooks = await searchBooks(query, maxResults: maxEach);

    // Build a deduplication key: normalised lowercase title + first author initial.
    String dedupeKey(Book b) {
      final title = b.title.toLowerCase().trim();
      final author =
          b.authors.isNotEmpty ? b.authors.first.toLowerCase().trim() : '';
      return '$title|$author';
    }

    final seen = <String>{};
    final merged = <Book>[];

    for (final b in googleBooks) {
      final key = dedupeKey(b);
      if (seen.add(key)) merged.add(b);
    }
    for (final b in olBooks) {
      final key = dedupeKey(b);
      if (seen.add(key)) merged.add(b);
    }

    return merged;
  }

  /// Smart entry point: ISBN → exact lookup on both APIs; otherwise combined.
  Future<List<Book>> searchBooksEnhanced(String query) async {
    lastSearchNotice = null;
    final cleaned = query.replaceAll(RegExp(r'[^0-9X]'), '');
    if (cleaned.length == 10 || cleaned.length == 13) {
      final olIsbn = await searchOpenLibraryByIsbn(cleaned);
      final googleIsbn = await searchByIsbn(cleaned);
      final combined = [...olIsbn, ...googleIsbn];
      if (combined.isNotEmpty) return combined;
    }
    final merged = await searchCombined(query);
    if (merged.isEmpty && lastSearchNotice == null) {
      lastSearchNotice = 'Sonuç bulunamadı. Farklı bir başlık veya yazar deneyin.';
    }
    return merged;
  }

  Future<List<Book>> searchByIsbn(String isbn) async {
    return searchBooks('isbn:$isbn', maxResults: 5);
  }

  Future<List<Book>> getRecommendations({
    required List<String> preferredCategories,
    required List<String> preferredAuthors,
    int maxResults = 10,
  }) async {
    final query = preferredCategories.isNotEmpty
        ? 'subject:${preferredCategories.first}'
        : preferredAuthors.isNotEmpty
            ? 'inauthor:${preferredAuthors.first}'
            : 'bestseller';
    return searchBooks(query, maxResults: maxResults);
  }

  // ─── Firestore CRUD ────────────────────────────────────────────────────────

  String get _prefsDoc => 'users/$_uid/book_prefs/order';

  Stream<List<UserBook>> getBooksStream() {
    if (_uid == null) return const Stream.empty();
    return _db.collection(_col).orderBy('title').snapshots().map(
        (snap) => snap.docs.map((d) => UserBook.fromFirestore(d)).toList());
  }

  /// Returns the user's custom book sort order (list of userBook IDs).
  Future<List<String>> getBookOrder() async {
    if (_uid == null) return [];
    try {
      final doc = await _db.doc(_prefsDoc).get();
      if (!doc.exists) return [];
      return List<String>.from(doc.data()?['order'] as List? ?? []);
    } catch (_) {
      return [];
    }
  }

  /// Saves the custom book sort order to Firestore.
  Future<void> saveBookOrder(List<String> orderedIds) async {
    if (_uid == null) return;
    try {
      await _db
          .doc(_prefsDoc)
          .set({'order': orderedIds}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[BookService.saveBookOrder] error: $e');
    }
  }

  /// Returns the slot-based placement map: slot index → book ID.
  Future<Map<int, String>> getSlotMap() async {
    if (_uid == null) return {};
    try {
      final doc = await _db.doc(_prefsDoc).get();
      if (!doc.exists) return {};
      final raw = doc.data()?['slotMap'] as Map<dynamic, dynamic>?;
      if (raw == null) return {};
      return raw.map(
          (k, v) => MapEntry(int.tryParse(k.toString()) ?? 0, v.toString()));
    } catch (_) {
      return {};
    }
  }

  /// Saves slot placement map to Firestore.
  Future<void> saveSlotMap(Map<int, String> slotMap) async {
    if (_uid == null) return;
    try {
      await _db.doc(_prefsDoc).set(
        {'slotMap': slotMap.map((k, v) => MapEntry(k.toString(), v))},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[BookService.saveSlotMap] error: $e');
    }
  }

  // ─── Shelf Labels ──────────────────────────────────────────────────────────

  /// Returns a map of rowIndex → label string.
  Future<Map<int, String>> getShelfLabels() async {
    if (_uid == null) return {};
    try {
      final doc = await _db.doc(_prefsDoc).get();
      if (!doc.exists) return {};
      final raw = doc.data()?['shelfLabels'] as Map<dynamic, dynamic>?;
      if (raw == null) return {};
      return raw.map(
          (k, v) => MapEntry(int.tryParse(k.toString()) ?? 0, v.toString()));
    } catch (_) {
      return {};
    }
  }

  /// Saves or clears a label for a given row index.
  Future<void> saveShelfLabel(int row, String label) async {
    if (_uid == null) return;
    try {
      final existing = await getShelfLabels();
      final merged = Map<String, dynamic>.from(
        existing.map((k, v) => MapEntry(k.toString(), v)),
      );
      if (label.trim().isEmpty) {
        merged.remove('$row');
      } else {
        merged['$row'] = label.trim();
      }
      await _db.doc(_prefsDoc).set(
        {'shelfLabels': merged},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[BookService.saveShelfLabel] error: $e');
    }
  }

  Stream<List<UserBook>> getBooksByStatusStream(String status) {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection(_col)
        .where('status', isEqualTo: status)
        .orderBy('title')
        .snapshots()
        .map(
            (snap) => snap.docs.map((d) => UserBook.fromFirestore(d)).toList());
  }

  Future<String?> addBook(Book book, {String status = 'to_read'}) async {
    if (_uid == null) return null;
    try {
      // Prevent duplicate additions of same Google Books ID.
      final existing = await _db
          .collection(_col)
          .where('googleBooksId', isEqualTo: book.googleBooksId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return existing.docs.first.id;

      final userBook = UserBook(
        userId: _uid!,
        googleBooksId: book.googleBooksId,
        title: book.title,
        authors: book.authors,
        pageCount: book.pageCount,
        coverUrl: book.coverUrl,
        categories: book.categories,
        status: status,
      );
      final ref = await _db.collection(_col).add(userBook.toMap());
      return ref.id;
    } catch (e) {
      debugPrint('[BookService.addBook] error: $e');
      rethrow;
    }
  }

  Future<void> updateBook(UserBook book) async {
    if (book.id == null) return;
    try {
      await _db.collection(_col).doc(book.id).update(book.toMap());
    } catch (e) {
      debugPrint('[BookService.updateBook] error: $e');
      rethrow;
    }
  }

  Future<void> updateStatus(String userBookId, String newStatus) async {
    try {
      final updates = <String, dynamic>{'status': newStatus};
      if (newStatus == 'reading') {
        updates['startDate'] = FieldValue.serverTimestamp();
        updates['currentPage'] = 0;
      } else if (newStatus == 'read') {
        updates['finishDate'] = FieldValue.serverTimestamp();
      }
      await _db.collection(_col).doc(userBookId).update(updates);
    } catch (e) {
      debugPrint('[BookService.updateStatus] error: $e');
      rethrow;
    }
  }

  Future<void> updateProgress(String userBookId, int currentPage) async {
    try {
      await _db
          .collection(_col)
          .doc(userBookId)
          .update({'currentPage': currentPage});
    } catch (e) {
      debugPrint('[BookService.updateProgress] error: $e');
      rethrow;
    }
  }

  Future<void> lendBook(
      String userBookId, String lentTo, DateTime lentDate) async {
    try {
      await _db.collection(_col).doc(userBookId).update({
        'status': 'lent',
        'lentTo': lentTo,
        'lentDate': Timestamp.fromDate(lentDate),
      });
    } catch (e) {
      debugPrint('[BookService.lendBook] error: $e');
      rethrow;
    }
  }

  Future<void> returnBook(String userBookId) async {
    try {
      await _db.collection(_col).doc(userBookId).update({
        'status': 'read',
        'lentTo': null,
        'lentDate': null,
      });
    } catch (e) {
      debugPrint('[BookService.returnBook] error: $e');
      rethrow;
    }
  }

  Future<void> deleteBook(String userBookId) async {
    try {
      await _db.collection(_col).doc(userBookId).delete();
    } catch (e) {
      debugPrint('[BookService.deleteBook] error: $e');
      rethrow;
    }
  }

  // ─── Statistics helpers ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getReadingStats() async {
    if (_uid == null) {
      return {
        'totalBooks': 0,
        'readBooks': 0,
        'readingBooks': 0,
        'toReadBooks': 0,
        'totalPagesRead': 0,
        'avgPagesPerDay': 0.0,
        'categoryDistribution': <String, int>{},
        'preferredCategories': <String>[],
        'preferredAuthors': <String>[],
      };
    }
    try {
      final snap = await _db.collection(_col).get();
      final books = snap.docs.map((d) => UserBook.fromFirestore(d)).toList();

      final read = books.where((b) => b.status == 'read').toList();
      final reading = books.where((b) => b.status == 'reading').toList();
      final toRead = books.where((b) => b.status == 'to_read').toList();

      int totalPages = 0;
      double totalPagesPerDay = 0;
      int readingBooksWithDates = 0;
      final categoryCount = <String, int>{};
      final authorCount = <String, int>{};

      for (final b in read) {
        totalPages += b.pageCount;
        if (b.avgPagesPerDay > 0) {
          totalPagesPerDay += b.avgPagesPerDay;
          readingBooksWithDates++;
        }
      }
      for (final b in reading) {
        totalPages += b.currentPage;
        if (b.avgPagesPerDay > 0) {
          totalPagesPerDay += b.avgPagesPerDay;
          readingBooksWithDates++;
        }
      }

      for (final b in [...read, ...reading]) {
        final cat = b.primaryCategory;
        categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
        for (final a in b.authors) {
          authorCount[a] = (authorCount[a] ?? 0) + 1;
        }
      }

      final sortedCats = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final sortedAuthors = authorCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'totalBooks': books.length,
        'readBooks': read.length,
        'readingBooks': reading.length,
        'toReadBooks': toRead.length,
        'totalPagesRead': totalPages,
        'avgPagesPerDay': readingBooksWithDates > 0
            ? totalPagesPerDay / readingBooksWithDates
            : 0.0,
        'categoryDistribution': categoryCount,
        'preferredCategories': sortedCats.take(3).map((e) => e.key).toList(),
        'preferredAuthors': sortedAuthors.take(3).map((e) => e.key).toList(),
      };
    } catch (e) {
      debugPrint('[BookService.getReadingStats] error: $e');
      return {};
    }
  }

  // ─── Shelf Decorations ─────────────────────────────────────────────────────

  String get _decoCol => 'users/$_uid/shelf_decorations';

  Stream<List<ShelfDecoration>> getDecorationsStream() {
    if (_uid == null) return const Stream.empty();
    return _db.collection(_decoCol).snapshots().map((snap) =>
        snap.docs.map((d) => ShelfDecoration.fromFirestore(d)).toList());
  }

  Future<void> addDecoration(ShelfDecoration deco) async {
    if (_uid == null) return;
    // Remove any existing decoration at this slot first.
    final existing = await _db
        .collection(_decoCol)
        .where('slotIndex', isEqualTo: deco.slotIndex)
        .limit(1)
        .get();
    final batch = _db.batch();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    batch.set(_db.collection(_decoCol).doc(), deco.toMap());
    await batch.commit();
  }

  Future<void> removeDecoration(String decoId) async {
    try {
      await _db.collection(_decoCol).doc(decoId).delete();
    } catch (e) {
      debugPrint('[BookService.removeDecoration] error: $e');
    }
  }

  Future<void> moveDecoration(String decoId, int newSlot) async {
    try {
      await _db.collection(_decoCol).doc(decoId).update({'slotIndex': newSlot});
    } catch (e) {
      debugPrint('[BookService.moveDecoration] error: $e');
    }
  }

  // ─── Reading Goals ─────────────────────────────────────────────────────────

  String get _goalsCol => 'users/$_uid/reading_goals';

  Stream<List<ReadingGoal>> getGoalsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection(_goalsCol)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ReadingGoal.fromFirestore(d)).toList());
  }

  Future<void> addGoal(ReadingGoal goal) async {
    if (_uid == null) return;
    try {
      await _db.collection(_goalsCol).add(goal.toMap());
    } catch (e) {
      debugPrint('[BookService.addGoal] error: $e');
      rethrow;
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _db.collection(_goalsCol).doc(goalId).delete();
    } catch (e) {
      debugPrint('[BookService.deleteGoal] error: $e');
      rethrow;
    }
  }

  /// Calculates the current progress value (books read or pages read)
  /// for the given [goal] based on UserBook data.
  Future<int> calculateGoalProgress(ReadingGoal goal) async {
    if (_uid == null) return 0;
    try {
      final snap = await _db.collection(_col).get();
      final books = snap.docs.map((d) => UserBook.fromFirestore(d)).toList();

      bool inPeriod(DateTime? date) {
        if (date == null) return false;
        if (goal.isMonthly) {
          return date.year == goal.year && date.month == goal.month;
        }
        return date.year == goal.year;
      }

      if (goal.isPageGoal) {
        int pages = 0;
        for (final b in books) {
          if (b.status == 'read' && inPeriod(b.finishDate)) {
            pages += b.pageCount;
          } else if (b.status == 'reading' && inPeriod(b.startDate)) {
            pages += b.currentPage;
          }
        }
        return pages;
      } else {
        return books
            .where((b) => b.status == 'read' && inPeriod(b.finishDate))
            .length;
      }
    } catch (e) {
      debugPrint('[BookService.calculateGoalProgress] error: $e');
      return 0;
    }
  }

  // ─── Book Quotes ───────────────────────────────────────────────────────────

  String get _quotesCol => 'users/$_uid/book_quotes';

  Stream<List<BookQuote>> getQuotesStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection(_quotesCol)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BookQuote.fromFirestore(d)).toList());
  }

  Future<void> addQuote(BookQuote quote) async {
    if (_uid == null) return;
    try {
      await _db.collection(_quotesCol).add(quote.toMap());
    } catch (e) {
      debugPrint('[BookService.addQuote] error: $e');
      rethrow;
    }
  }

  Future<void> updateQuote(BookQuote quote) async {
    if (_uid == null || quote.id == null) return;
    try {
      await _db
          .collection(_quotesCol)
          .doc(quote.id)
          .update(quote.toMap());
    } catch (e) {
      debugPrint('[BookService.updateQuote] error: $e');
      rethrow;
    }
  }

  Future<void> deleteQuote(String quoteId) async {
    try {
      await _db.collection(_quotesCol).doc(quoteId).delete();
    } catch (e) {
      debugPrint('[BookService.deleteQuote] error: $e');
      rethrow;
    }
  }

  Future<void> togglePinQuote(String quoteId, bool isPinned) async {
    try {
      await _db
          .collection(_quotesCol)
          .doc(quoteId)
          .update({'isPinned': isPinned});
    } catch (e) {
      debugPrint('[BookService.togglePinQuote] error: $e');
      rethrow;
    }
  }

  /// Returns a random pinned quote, or any random quote if none are pinned.
  Future<BookQuote?> getRandomQuote() async {
    if (_uid == null) return null;
    try {
      QuerySnapshot snap = await _db
          .collection(_quotesCol)
          .where('isPinned', isEqualTo: true)
          .limit(20)
          .get();
      if (snap.docs.isEmpty) {
        snap = await _db.collection(_quotesCol).limit(20).get();
      }
      if (snap.docs.isEmpty) return null;
      final idx = Random().nextInt(snap.docs.length);
      return BookQuote.fromFirestore(snap.docs[idx]);
    } catch (e) {
      debugPrint('[BookService.getRandomQuote] error: $e');
      return null;
    }
  }
}

