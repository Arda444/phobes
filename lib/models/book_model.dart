import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String googleBooksId;
  final String title;
  final List<String> authors;
  final int pageCount;
  final String? coverUrl;
  final List<String> categories;
  final String? description;
  final String? publisher;
  final String? publishedDate;

  const Book({
    required this.googleBooksId,
    required this.title,
    this.authors = const [],
    this.pageCount = 0,
    this.coverUrl,
    this.categories = const [],
    this.description,
    this.publisher,
    this.publishedDate,
  });

  factory Book.fromGoogleBooksJson(Map<String, dynamic> json) {
    final info = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    final imageLinks = info['imageLinks'] as Map<String, dynamic>?;
    String? cover = imageLinks?['thumbnail'] as String?;
    if (cover != null) {
      cover = cover.replaceAll('http://', 'https://');
      // Web'de CORS hatasını aşmak ve resimleri hızlandırmak için proxy kullanımı:
      cover = 'https://wsrv.nl/?url=${Uri.encodeComponent(cover)}';
    }
    return Book(
      googleBooksId: json['id'] as String? ?? '',
      title: info['title'] as String? ?? 'Başlıksız',
      authors: List<String>.from(info['authors'] as List? ?? []),
      pageCount: (info['pageCount'] as int?) ?? 0,
      coverUrl: cover,
      categories: List<String>.from(info['categories'] as List? ?? []),
      description: info['description'] as String?,
      publisher: info['publisher'] as String?,
      publishedDate: info['publishedDate'] as String?,
    );
  }

  /// Creates a Book from an Open Library search result document.
  factory Book.fromOpenLibraryJson(Map<String, dynamic> doc) {
    final coverId = doc['cover_i'];
    final String? coverUrl = coverId != null
        ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
        : null;

    final isbnList = List<String>.from(doc['isbn'] as List? ?? []);
    final id = isbnList.isNotEmpty
        ? 'ol_isbn_${isbnList.first}'
        : 'ol_${(doc['key'] as String? ?? '').replaceAll('/', '_')}';

    final subjects = List<String>.from(doc['subject'] as List? ?? []);
    final publishers = List<String>.from(doc['publisher'] as List? ?? []);
    final year = doc['first_publish_year']?.toString();

    return Book(
      googleBooksId: id,
      title: doc['title'] as String? ?? '',
      authors: List<String>.from(doc['author_name'] as List? ?? []),
      pageCount: (doc['number_of_pages_median'] as int?) ?? 0,
      coverUrl: coverUrl,
      categories: subjects.take(3).toList(),
      publisher: publishers.isNotEmpty ? publishers.first : null,
      publishedDate: year,
    );
  }

  Map<String, dynamic> toMap() => {
        'googleBooksId': googleBooksId,
        'title': title,
        'authors': authors,
        'pageCount': pageCount,
        'coverUrl': coverUrl,
        'categories': categories,
        'description': description,
        'publisher': publisher,
        'publishedDate': publishedDate,
      };

  String get authorsDisplay =>
      authors.isEmpty ? 'Yazar bilinmiyor' : authors.join(', ');

  String get primaryCategory =>
      categories.isNotEmpty ? categories.first : 'Genel';
}

class UserBook {
  final String? id;
  final String userId;
  final String googleBooksId;
  final String title;
  final List<String> authors;
  final int pageCount;
  final String? coverUrl;
  final List<String> categories;
  final String status; // 'to_read' | 'reading' | 'read' | 'lent'
  final DateTime? acquisitionDate;
  final DateTime? startDate;
  final DateTime? finishDate;
  final int currentPage;
  final int rating; // 0–5
  final String notes;
  final String? lentTo;
  final DateTime? lentDate;

  const UserBook({
    this.id,
    required this.userId,
    required this.googleBooksId,
    required this.title,
    this.authors = const [],
    this.pageCount = 0,
    this.coverUrl,
    this.categories = const [],
    this.status = 'to_read',
    this.acquisitionDate,
    this.startDate,
    this.finishDate,
    this.currentPage = 0,
    this.rating = 0,
    this.notes = '',
    this.lentTo,
    this.lentDate,
  });

  factory UserBook.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserBook(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      googleBooksId: d['googleBooksId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      authors: List<String>.from(d['authors'] as List? ?? []),
      pageCount: (d['pageCount'] as int?) ?? 0,
      coverUrl: d['coverUrl'] as String?,
      categories: List<String>.from(d['categories'] as List? ?? []),
      status: d['status'] as String? ?? 'to_read',
      acquisitionDate: (d['acquisitionDate'] as Timestamp?)?.toDate(),
      startDate: (d['startDate'] as Timestamp?)?.toDate(),
      finishDate: (d['finishDate'] as Timestamp?)?.toDate(),
      currentPage: (d['currentPage'] as int?) ?? 0,
      rating: (d['rating'] as int?) ?? 0,
      notes: d['notes'] as String? ?? '',
      lentTo: d['lentTo'] as String?,
      lentDate: (d['lentDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'googleBooksId': googleBooksId,
        'title': title,
        'authors': authors,
        'pageCount': pageCount,
        'coverUrl': coverUrl,
        'categories': categories,
        'status': status,
        'acquisitionDate': acquisitionDate != null
            ? Timestamp.fromDate(acquisitionDate!)
            : null,
        'startDate':
            startDate != null ? Timestamp.fromDate(startDate!) : null,
        'finishDate':
            finishDate != null ? Timestamp.fromDate(finishDate!) : null,
        'currentPage': currentPage,
        'rating': rating,
        'notes': notes,
        'lentTo': lentTo,
        'lentDate': lentDate != null ? Timestamp.fromDate(lentDate!) : null,
      };

  UserBook copyWith({
    String? id,
    String? status,
    DateTime? acquisitionDate,
    DateTime? startDate,
    DateTime? finishDate,
    int? currentPage,
    int? rating,
    String? notes,
    String? lentTo,
    DateTime? lentDate,
    bool clearLentTo = false,
    bool clearLentDate = false,
    bool clearStartDate = false,
    bool clearFinishDate = false,
  }) =>
      UserBook(
        id: id ?? this.id,
        userId: userId,
        googleBooksId: googleBooksId,
        title: title,
        authors: authors,
        pageCount: pageCount,
        coverUrl: coverUrl,
        categories: categories,
        status: status ?? this.status,
        acquisitionDate: acquisitionDate ?? this.acquisitionDate,
        startDate: clearStartDate ? null : (startDate ?? this.startDate),
        finishDate: clearFinishDate ? null : (finishDate ?? this.finishDate),
        currentPage: currentPage ?? this.currentPage,
        rating: rating ?? this.rating,
        notes: notes ?? this.notes,
        lentTo: clearLentTo ? null : (lentTo ?? this.lentTo),
        lentDate: clearLentDate ? null : (lentDate ?? this.lentDate),
      );

  double get progressPercent =>
      pageCount > 0 ? (currentPage / pageCount).clamp(0.0, 1.0) : 0.0;

  String get authorsDisplay =>
      authors.isEmpty ? 'Yazar bilinmiyor' : authors.join(', ');

  String get primaryCategory =>
      categories.isNotEmpty ? categories.first : 'Genel';

  /// Average pages per day while reading.
  double get avgPagesPerDay {
    if (startDate == null || currentPage == 0) return 0;
    final end = finishDate ?? DateTime.now();
    final days = end.difference(startDate!).inDays;
    if (days <= 0) return currentPage.toDouble();
    return currentPage / days;
  }
}

// ─── ShelfDecoration ───────────────────────────────────────────────────────

class ShelfDecoration {
  final String? id;
  final String userId;
  final int slotIndex;
  final String emoji;

  const ShelfDecoration({
    this.id,
    required this.userId,
    required this.slotIndex,
    required this.emoji,
  });

  factory ShelfDecoration.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ShelfDecoration(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      slotIndex: (d['slotIndex'] as int?) ?? 0,
      emoji: d['emoji'] as String? ?? '🪴',
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'slotIndex': slotIndex,
        'emoji': emoji,
      };
}

// ─── ReadingGoal ───────────────────────────────────────────────────────────

/// Supported goal types:
///   yearly_books  — finish N books in the given year
///   monthly_books — finish N books in the given month
///   yearly_pages  — read N pages in the given year
///   monthly_pages — read N pages in the given month
class ReadingGoal {
  final String? id;
  final String userId;
  final String title;
  final String type; // 'yearly_books' | 'monthly_books' | 'yearly_pages' | 'monthly_pages'
  final int targetValue;
  final int year;
  final int? month; // null for yearly goals
  final String icon;
  final int color;
  final DateTime createdAt;

  const ReadingGoal({
    this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.targetValue,
    required this.year,
    this.month,
    this.icon = '🎯',
    this.color = 0xFF6366F1,
    required this.createdAt,
  });

  factory ReadingGoal.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReadingGoal(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      type: d['type'] as String? ?? 'yearly_books',
      targetValue: (d['targetValue'] as int?) ?? 0,
      year: (d['year'] as int?) ?? DateTime.now().year,
      month: d['month'] as int?,
      icon: d['icon'] as String? ?? '🎯',
      color: (d['color'] as int?) ?? 0xFF6366F1,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'type': type,
        'targetValue': targetValue,
        'year': year,
        'month': month,
        'icon': icon,
        'color': color,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  ReadingGoal copyWith({
    String? title,
    int? targetValue,
    String? icon,
    int? color,
  }) =>
      ReadingGoal(
        id: id,
        userId: userId,
        title: title ?? this.title,
        type: type,
        targetValue: targetValue ?? this.targetValue,
        year: year,
        month: month,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        createdAt: createdAt,
      );

  bool get isMonthly => type.startsWith('monthly');
  bool get isPageGoal => type.endsWith('pages');

  String get periodLabel => isMonthly
      ? '${_months[month! - 1]} $year'
      : '$year yılı';

  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];
}

// ─── BookQuote ─────────────────────────────────────────────────────────────

class BookQuote {
  final String? id;
  final String userId;
  final String userBookId;
  final String bookTitle;
  final String text;
  final int? page;
  final int color;
  final bool isPinned;
  final DateTime createdAt;

  const BookQuote({
    this.id,
    required this.userId,
    required this.userBookId,
    required this.bookTitle,
    required this.text,
    this.page,
    this.color = 0xFF6366F1,
    this.isPinned = false,
    required this.createdAt,
  });

  factory BookQuote.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookQuote(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      userBookId: d['userBookId'] as String? ?? '',
      bookTitle: d['bookTitle'] as String? ?? '',
      text: d['text'] as String? ?? '',
      page: d['page'] as int?,
      color: (d['color'] as int?) ?? 0xFF6366F1,
      isPinned: d['isPinned'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userBookId': userBookId,
        'bookTitle': bookTitle,
        'text': text,
        'page': page,
        'color': color,
        'isPinned': isPinned,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  BookQuote copyWith({
    String? id,
    String? userId,
    String? userBookId,
    String? bookTitle,
    String? text,
    int? page,
    bool clearPage = false,
    int? color,
    bool? isPinned,
    DateTime? createdAt,
  }) =>
      BookQuote(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        userBookId: userBookId ?? this.userBookId,
        bookTitle: bookTitle ?? this.bookTitle,
        text: text ?? this.text,
        page: clearPage ? null : (page ?? this.page),
        color: color ?? this.color,
        isPinned: isPinned ?? this.isPinned,
        createdAt: createdAt ?? this.createdAt,
      );
}
