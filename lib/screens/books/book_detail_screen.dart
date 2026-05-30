import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../widgets/phobes_widgets.dart';
import 'package:phobes/l10n/app_localizations.dart';
import 'book_quotes_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final UserBook userBook;
  const BookDetailScreen({super.key, required this.userBook});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final BookService _bookService = BookService();
  late UserBook _book;

  @override
  void initState() {
    super.initState();
    _book = widget.userBook;
  }

  Future<void> _save(UserBook updated) async {
    setState(() => _book = updated);
    try {
      await _bookService.updateBook(updated);
    } catch (_) {}
  }

  String _ratingLabel(AppLocalizations l10n, int rating) => switch (rating) {
        1 => l10n.booksRatingTerrible,
        2 => l10n.booksRatingMediocre,
        3 => l10n.booksRatingGood,
        4 => l10n.booksRatingVeryGood,
        5 => l10n.booksRatingExcellent,
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(cs, isDark, l10n),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 720 : double.infinity),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildStatusSelector(cs, l10n),
                      const SizedBox(height: 24),
                      if (_book.status == 'reading' || _book.status == 'read')
                        _buildProgressSection(cs, l10n),
                      _buildDatesSection(cs, l10n),
                      const SizedBox(height: 20),
                      _buildRatingSection(cs, l10n),
                      const SizedBox(height: 20),
                      _buildNotesSection(cs, isDark, l10n),
                      const SizedBox(height: 20),
                      _buildQuotesSection(cs, l10n),
                      if (_book.status == 'lent' || _book.lentTo != null)
                        _buildLendingSection(cs, isDark, l10n),
                      const SizedBox(height: 20),
                      _buildDangerZone(cs, l10n),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ColorScheme cs, bool isDark, AppLocalizations l10n) {
    const color = Color(0xFF8B5E3C);
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: cs.surface,
      leading: UnconstrainedBox(
        child: PhobesIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
      ),
      actions: [
        if (_book.status != 'lent')
          PhobesIconButton(
            icon: Icons.swap_horiz_rounded,
            onTap: () => _showLendDialog(),
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.2),
                cs.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Cover
                  Hero(
                    tag: 'book_cover_${_book.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _book.coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: _book.coverUrl!,
                              width: 100, height: 148,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _coverPlaceholder(_book.title),
                            )
                          : _coverPlaceholder(_book.title),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _book.title,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _book.authorsDisplay,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: cs.onSurface.withOpacity(0.5),
                          ),
                        ),
                        if (_book.pageCount > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.menu_book_rounded, size: 13,
                                  color: cs.onSurface.withOpacity(0.4)),
                              const SizedBox(width: 4),
                              Text(
                                l10n.booksPageCount(_book.pageCount),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: cs.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSelector(ColorScheme cs, AppLocalizations l10n) {
    final statuses = [
      ('to_read', l10n.booksStatusToRead, Icons.bookmark_rounded, cs.primary),
      ('reading', l10n.booksStatusReading, Icons.auto_stories_rounded,
          const Color(0xFF3B82F6)),
      ('read', l10n.booksStatusRead, Icons.check_circle_rounded,
          const Color(0xFF22C55E)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.booksReadingStatusTitle,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, fontSize: 13,
                color: cs.onSurface.withOpacity(0.5), letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Row(
          children: statuses.map((s) {
            final isSelected = _book.status == s.$1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () async {
                    if (_book.status == s.$1) return;
                    final updated = _book.copyWith(status: s.$1);
                    await _save(updated);
                    await _bookService.updateStatus(_book.id!, s.$1);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? s.$4.withOpacity(0.15)
                          : cs.onSurface.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? s.$4
                            : cs.outline.withOpacity(0.15),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(s.$3, color: isSelected ? s.$4 : cs.onSurface.withOpacity(0.3), size: 20),
                        const SizedBox(height: 4),
                        Text(s.$2,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                              color: isSelected ? s.$4 : cs.onSurface.withOpacity(0.4),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProgressSection(ColorScheme cs, AppLocalizations l10n) {
    return FadeInDown(
      child: PhobesCard(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.booksProgressTitle,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 13,
                    color: cs.onSurface.withOpacity(0.5), letterSpacing: 0.8)),
            const SizedBox(height: 16),
            Row(
              children: [
                CircularPercentIndicator(
                  radius: 48,
                  lineWidth: 8,
                  percent: _book.progressPercent,
                  center: Text(
                    '${(_book.progressPercent * 100).toInt()}%',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: cs.onSurface,
                    ),
                  ),
                  progressColor: const Color(0xFF3B82F6),
                  backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.booksProgressPages(
                            _book.currentPage, _book.pageCount),
                        style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_book.pageCount > _book.currentPage)
                        Text(
                          l10n.booksPagesRemaining(
                              _book.pageCount - _book.currentPage),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.45),
                          ),
                        ),
                      if (_book.avgPagesPerDay > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          l10n.booksAvgPagesPerDay(
                              _book.avgPagesPerDay.round()),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_book.pageCount > 0) ...[
              Slider(
                value: _book.currentPage.toDouble(),
                max: _book.pageCount.toDouble(),
                divisions: _book.pageCount,
                activeColor: const Color(0xFF3B82F6),
                onChanged: (v) => setState(() =>
                    _book = _book.copyWith(currentPage: v.toInt())),
                onChangeEnd: (v) =>
                    _bookService.updateProgress(_book.id!, v.toInt()),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(color: cs.onSurface),
                    decoration: InputDecoration(
                      labelText: l10n.booksCurrentPageLabel,
                      labelStyle: GoogleFonts.outfit(
                          fontSize: 12, color: cs.onSurface.withOpacity(0.5)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    controller: TextEditingController(
                        text: _book.currentPage.toString()),
                    onSubmitted: (val) {
                      final page = int.tryParse(val) ?? _book.currentPage;
                      final clamped = page.clamp(0, _book.pageCount);
                      setState(() =>
                          _book = _book.copyWith(currentPage: clamped));
                      _bookService.updateProgress(_book.id!, clamped);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSection(ColorScheme cs, AppLocalizations l10n) {
    return PhobesCard(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.booksDatesTitle,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700, fontSize: 13,
                  color: cs.onSurface.withOpacity(0.5), letterSpacing: 0.8)),
          const SizedBox(height: 12),
          _DateRow(
            label: l10n.booksAcquisitionDate,
            date: _book.acquisitionDate,
            icon: Icons.shopping_bag_rounded,
            selectLabel: l10n.booksSelectDate,
            onPick: (d) => _save(_book.copyWith(acquisitionDate: d)),
          ),
          const Divider(height: 20),
          _DateRow(
            label: l10n.booksStartDate,
            date: _book.startDate,
            icon: Icons.play_circle_rounded,
            color: const Color(0xFF3B82F6),
            selectLabel: l10n.booksSelectDate,
            onPick: (d) => _save(_book.copyWith(startDate: d)),
          ),
          const Divider(height: 20),
          _DateRow(
            label: l10n.booksFinishDate,
            date: _book.finishDate,
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF22C55E),
            selectLabel: l10n.booksSelectDate,
            onPick: (d) => _save(_book.copyWith(finishDate: d)),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(ColorScheme cs, AppLocalizations l10n) {
    return PhobesCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.booksMyRatingTitle,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700, fontSize: 13,
                  color: cs.onSurface.withOpacity(0.5), letterSpacing: 0.8)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _book.rating;
              return GestureDetector(
                onTap: () {
                  final newRating = i + 1 == _book.rating ? 0 : i + 1;
                  _save(_book.copyWith(rating: newRating));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 36,
                    color: filled ? const Color(0xFFFBBF24) : cs.onSurface.withOpacity(0.2),
                  ),
                ),
              );
            }),
          ),
          if (_book.rating > 0) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                _ratingLabel(l10n, _book.rating),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFFFBBF24),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection(
      ColorScheme cs, bool isDark, AppLocalizations l10n) {
    final ctrl = TextEditingController(text: _book.notes);
    return PhobesCard(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.booksNotesAndQuotesTitle,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700, fontSize: 13,
                  color: cs.onSurface.withOpacity(0.5), letterSpacing: 0.8)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLines: 6,
            style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 13),
            decoration: InputDecoration(
              hintText: l10n.booksNotesHint,
              hintStyle: GoogleFonts.outfit(
                  color: cs.onSurface.withOpacity(0.3), fontSize: 13),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outline.withOpacity(0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outline.withOpacity(0.15)),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            onChanged: (_) {},
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: PhobesButton(
              text: l10n.save,
              onPressed: () {
                _save(_book.copyWith(notes: ctrl.text));
                FocusScope.of(context).unfocus();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesSection(ColorScheme cs, AppLocalizations l10n) {
    return StreamBuilder<List<BookQuote>>(
      stream: _bookService.getQuotesStream().where(
            (list) => list.any((q) => q.userBookId == _book.id),
          ),
      builder: (context, snapshot) {
        final bookQuotes =
            (snapshot.data ?? []).where((q) => q.userBookId == _book.id).toList();

        return PhobesCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(l10n.booksQuotesSectionTitle,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: cs.onSurface.withOpacity(0.5),
                          letterSpacing: 0.8)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => QuoteEditorSheet.openForNew(
                      context,
                      _bookService,
                      presetBook: _book,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cs.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 14, color: cs.primary),
                          const SizedBox(width: 4),
                          Text(l10n.booksAdd,
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (bookQuotes.isEmpty) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    l10n.booksQuotesEmptyDetail,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: cs.onSurface.withOpacity(0.35)),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                ...bookQuotes.take(3).map((q) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: QuoteCard(
                        quote: q,
                        bookService: _bookService,
                      ),
                    )),
                if (bookQuotes.length > 3)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BookQuotesScreen()),
                    ),
                    child: Text(
                      l10n.booksViewAllQuotes(bookQuotes.length),
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: cs.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLendingSection(
      ColorScheme cs, bool isDark, AppLocalizations l10n) {
    return PhobesCard(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.swap_horiz_rounded,
                    color: Color(0xFFF59E0B), size: 18),
              ),
              const SizedBox(width: 10),
              Text(l10n.booksLendingInfoTitle,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700, fontSize: 13,
                      color: cs.onSurface.withOpacity(0.5), letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 12),
          if (_book.lentTo != null) ...[
            _InfoRow(label: l10n.booksLentTo, value: _book.lentTo!, cs: cs),
            if (_book.lentDate != null)
              _InfoRow(
                label: l10n.booksLentDate,
                value: '${_book.lentDate!.day}.${_book.lentDate!.month}.${_book.lentDate!.year}',
                cs: cs,
              ),
            const SizedBox(height: 16),
            PhobesButton(
              text: l10n.booksMarkReturned,
              icon: Icons.check_rounded,
              onPressed: () async {
                await _bookService.returnBook(_book.id!);
                setState(() {
                  _book = _book.copyWith(
                    status: 'read',
                    clearLentTo: true,
                    clearLentDate: true,
                  );
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDangerZone(ColorScheme cs, AppLocalizations l10n) {
    return PhobesCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.delete_outline_rounded, color: cs.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l10n.booksRemoveFromLibrary,
                style: GoogleFonts.outfit(color: cs.error, fontSize: 13)),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(cs, l10n),
            child: Text(l10n.booksRemove,
                style: GoogleFonts.outfit(
                    color: cs.error, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(ColorScheme cs, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.booksRemoveBookTitle,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(l10n.booksRemoveBookConfirm(_book.title),
            style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: GoogleFonts.outfit()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.booksRemove,
                style: GoogleFonts.outfit(color: cs.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _bookService.deleteBook(_book.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _showLendDialog() async {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(l10n.booksLendBookTitle,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 18, color: cs.onSurface)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: GoogleFonts.outfit(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: l10n.booksLendToLabel,
                  prefixIcon: const Icon(Icons.person_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              PhobesButton(
                text: l10n.booksLendBookAction,
                width: double.infinity,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  await _bookService.lendBook(
                      _book.id!, nameCtrl.text.trim(), DateTime.now());
                  setState(() {
                    _book = _book.copyWith(
                      status: 'lent',
                      lentTo: nameCtrl.text.trim(),
                      lentDate: DateTime.now(),
                    );
                  });
                  nameCtrl.dispose();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder(String title) {
    const colors = [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF3B82F6)];
    final c = colors[title.hashCode.abs() % colors.length];
    return Container(
      width: 100, height: 148,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c, c.withOpacity(0.7)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.menu_book_rounded, color: Colors.white54, size: 40),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final String selectLabel;
  final DateTime? date;
  final IconData icon;
  final Color? color;
  final void Function(DateTime) onPick;

  const _DateRow({
    required this.label,
    required this.selectLabel,
    required this.date,
    required this.icon,
    this.color,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.primary;
    return Row(
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 13, color: cs.onSurface.withOpacity(0.6))),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: c.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.withOpacity(0.2)),
            ),
            child: Text(
              date != null
                  ? '${date!.day}.${date!.month}.${date!.year}'
                  : selectLabel,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: date != null ? c : cs.onSurface.withOpacity(0.35),
                fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;

  const _InfoRow({required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label: ',
              style: GoogleFonts.outfit(
                  fontSize: 13, color: cs.onSurface.withOpacity(0.5))),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
        ],
      ),
    );
  }
}
