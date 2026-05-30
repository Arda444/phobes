import 'package:cloud_firestore/cloud_firestore.dart';

class BookClub {
  final String? id;
  final String teamId;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final bool isActive;

  /// Current book being read by the club.
  final String? bookTitle;
  final List<String> bookAuthors;
  final int bookPageCount;
  final String? bookCoverUrl;
  final String? googleBooksId;

  /// When the club started reading the current book.
  final DateTime? startDate;

  /// Target finish date voted by the club.
  final DateTime? targetFinishDate;

  /// userId → currentPage read by that member.
  final Map<String, int> memberProgress;

  /// userId → member display name (cached).
  final Map<String, String> memberNames;

  const BookClub({
    this.id,
    required this.teamId,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true,
    this.bookTitle,
    this.bookAuthors = const [],
    this.bookPageCount = 0,
    this.bookCoverUrl,
    this.googleBooksId,
    this.startDate,
    this.targetFinishDate,
    this.memberProgress = const {},
    this.memberNames = const {},
  });

  factory BookClub.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookClub(
      id: doc.id,
      teamId: d['teamId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      createdBy: d['createdBy'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: d['isActive'] as bool? ?? true,
      bookTitle: d['bookTitle'] as String?,
      bookAuthors: List<String>.from(d['bookAuthors'] as List? ?? []),
      bookPageCount: (d['bookPageCount'] as int?) ?? 0,
      bookCoverUrl: d['bookCoverUrl'] as String?,
      googleBooksId: d['googleBooksId'] as String?,
      startDate: (d['startDate'] as Timestamp?)?.toDate(),
      targetFinishDate: (d['targetFinishDate'] as Timestamp?)?.toDate(),
      memberProgress: Map<String, int>.from(
        (d['memberProgress'] as Map?)?.map(
              (k, v) => MapEntry(k as String, (v as int?) ?? 0),
            ) ??
            {},
      ),
      memberNames: Map<String, String>.from(
        (d['memberNames'] as Map?)?.map(
              (k, v) => MapEntry(k as String, v as String? ?? ''),
            ) ??
            {},
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'teamId': teamId,
        'name': name,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'isActive': isActive,
        'bookTitle': bookTitle,
        'bookAuthors': bookAuthors,
        'bookPageCount': bookPageCount,
        'bookCoverUrl': bookCoverUrl,
        'googleBooksId': googleBooksId,
        'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
        'targetFinishDate': targetFinishDate != null
            ? Timestamp.fromDate(targetFinishDate!)
            : null,
        'memberProgress': memberProgress,
        'memberNames': memberNames,
      };

  BookClub copyWith({
    String? name,
    bool? isActive,
    String? bookTitle,
    List<String>? bookAuthors,
    int? bookPageCount,
    String? bookCoverUrl,
    String? googleBooksId,
    DateTime? startDate,
    DateTime? targetFinishDate,
    Map<String, int>? memberProgress,
    Map<String, String>? memberNames,
  }) =>
      BookClub(
        id: id,
        teamId: teamId,
        name: name ?? this.name,
        createdBy: createdBy,
        createdAt: createdAt,
        isActive: isActive ?? this.isActive,
        bookTitle: bookTitle ?? this.bookTitle,
        bookAuthors: bookAuthors ?? this.bookAuthors,
        bookPageCount: bookPageCount ?? this.bookPageCount,
        bookCoverUrl: bookCoverUrl ?? this.bookCoverUrl,
        googleBooksId: googleBooksId ?? this.googleBooksId,
        startDate: startDate ?? this.startDate,
        targetFinishDate: targetFinishDate ?? this.targetFinishDate,
        memberProgress: memberProgress ?? this.memberProgress,
        memberNames: memberNames ?? this.memberNames,
      );

  double progressForMember(String uid) {
    if (bookPageCount <= 0) return 0;
    final pages = memberProgress[uid] ?? 0;
    return (pages / bookPageCount).clamp(0.0, 1.0);
  }

  double get avgProgress {
    if (memberProgress.isEmpty || bookPageCount <= 0) return 0;
    final total = memberProgress.values.fold(0, (a, b) => a + b);
    return (total / memberProgress.length / bookPageCount).clamp(0.0, 1.0);
  }

  bool get hasBook => bookTitle != null && bookTitle!.isNotEmpty;

  int get daysLeft {
    if (targetFinishDate == null) return -1;
    return targetFinishDate!.difference(DateTime.now()).inDays;
  }
}
