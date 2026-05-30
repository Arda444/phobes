import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../widgets/phobes_widgets.dart';
import 'package:phobes/l10n/app_localizations.dart';

class BookQuotesScreen extends StatefulWidget {
  const BookQuotesScreen({super.key});

  @override
  State<BookQuotesScreen> createState() => _BookQuotesScreenState();
}

class _BookQuotesScreenState extends State<BookQuotesScreen> {
  final BookService _bookService = BookService();
  late final Stream<List<BookQuote>> _quotesStream;

  @override
  void initState() {
    super.initState();
    _quotesStream = _bookService.getQuotesStream().asBroadcastStream();
  }

  Future<void> _addQuote() async {
    await QuoteEditorSheet.openForNew(context, _bookService);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: UnconstrainedBox(
          child: PhobesIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text(l10n.booksMyQuotesTitle,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: cs.onSurface)),
        actions: [
          PhobesIconButton(
            icon: Icons.add_rounded,
            onTap: _addQuote,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<BookQuote>>(
        stream: _quotesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return Center(child: PhobesLoadingIndicator(color: cs.primary));
          }
          final quotes = snapshot.data ?? [];
          if (quotes.isEmpty) {
            return _buildEmpty(l10n);
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 1500
                  ? 4
                  : w >= 1100
                      ? 3
                      : w >= 700
                          ? 2
                          : 1;
              if (cols == 1) {
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  itemCount: quotes.length,
                  itemBuilder: (context, i) => FadeInUp(
                    delay: Duration(milliseconds: i * 40),
                    child: QuoteCard(
                      quote: quotes[i],
                      bookService: _bookService,
                    ),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 200,
                ),
                itemCount: quotes.length,
                itemBuilder: (context, i) => FadeInUp(
                  delay: Duration(milliseconds: i * 40),
                  child: QuoteCard(
                    quote: quotes[i],
                    bookService: _bookService,
                    grid: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return PhobesEmptyState(
      icon: Icons.format_quote_rounded,
      title: l10n.booksQuotesEmptyTitle,
      description: l10n.booksQuotesEmptyDescScreen,
      buttonText: l10n.booksAddQuoteTitle,
      buttonIcon: Icons.add_rounded,
      onButtonTap: _addQuote,
    );
  }
}

// ─── Reusable QuoteCard ────────────────────────────────────────────────────

class QuoteCard extends StatelessWidget {
  final BookQuote quote;
  final BookService bookService;
  final bool grid;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.bookService,
    this.grid = false,
  });

  Future<void> _showActions(BuildContext context) async {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    await PhobesBottomSheet.show<void>(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: quote.bookTitle,
        padding: 0,
        child: _QuoteActionSheet(
          quote: quote,
          bookService: bookService,
          l10n: l10n,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final color = Color(quote.color);

    return PhobesCard(
      margin: grid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      onTap: () => _showActions(context),
      child: Stack(
        children: [
          // Decorative accent bar on the left
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color,
                    color.withOpacity(0.4),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
          // Decorative large quote glyph
          Positioned(
            top: 8,
            right: 12,
            child: Icon(
              Icons.format_quote_rounded,
              size: 44,
              color: color.withOpacity(0.10),
            ),
          ),
          if (quote.isPinned)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.push_pin_rounded,
                  size: 12,
                  color: color,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    quote.text,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      height: 1.5,
                      color: cs.onSurface.withOpacity(0.92),
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: grid ? 5 : 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 1,
                  color: cs.onSurface.withOpacity(0.05),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 12,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        quote.bookTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (quote.page != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.booksQuotePageAbbrev(quote.page!),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showActions(context),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action sheet for a single quote ──────────────────────────────────────

class _QuoteActionSheet extends StatelessWidget {
  final BookQuote quote;
  final BookService bookService;
  final AppLocalizations l10n;

  const _QuoteActionSheet({
    required this.quote,
    required this.bookService,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = Color(quote.color);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.format_quote_rounded, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quote.text,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: cs.onSurface.withOpacity(0.8),
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _ActionRow(
          icon: quote.isPinned
              ? Icons.push_pin_rounded
              : Icons.push_pin_outlined,
          label: quote.isPinned ? l10n.booksUnpinQuote : l10n.booksPinQuote,
          color: color,
          onTap: () async {
            HapticFeedback.lightImpact();
            await bookService.togglePinQuote(quote.id!, !quote.isPinned);
            if (context.mounted) Navigator.pop(context);
          },
        ),
        _ActionRow(
          icon: Icons.copy_all_rounded,
          label: l10n.btnCopy,
          color: cs.primary,
          onTap: () {
            HapticFeedback.lightImpact();
            Clipboard.setData(ClipboardData(text: quote.text));
            Navigator.pop(context);
          },
        ),
        _ActionRow(
          icon: Icons.edit_outlined,
          label: l10n.edit,
          color: Colors.amber.shade600,
          onTap: () async {
            Navigator.pop(context);
            await QuoteEditorSheet.openForEdit(
              context,
              bookService,
              quote,
            );
          },
        ),
        _ActionRow(
          icon: Icons.delete_outline_rounded,
          label: l10n.delete,
          color: cs.error,
          onTap: () async {
            Navigator.pop(context);
            final confirmed = await PhobesBottomSheet.confirm(
              context: context,
              title: l10n.booksDeleteQuoteTitle,
              message: l10n.booksDeleteQuoteMessage,
              confirmText: l10n.delete,
              confirmColor: cs.error,
            );
            if (confirmed == true) {
              HapticFeedback.mediumImpact();
              await bookService.deleteQuote(quote.id!);
            }
          },
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quote Editor Sheet (Add & Edit) ──────────────────────────────────────

class QuoteEditorSheet extends StatefulWidget {
  final BookService bookService;
  final BookQuote? existing;
  final UserBook? presetBook;

  const QuoteEditorSheet({
    super.key,
    required this.bookService,
    this.existing,
    this.presetBook,
  });

  /// Open add-mode sheet that prompts for a book first.
  static Future<void> openForNew(
    BuildContext context,
    BookService bookService, {
    UserBook? presetBook,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    UserBook? chosen = presetBook;
    if (chosen == null) {
      chosen = await _showBookPicker(context, bookService, l10n);
      if (chosen == null || !context.mounted) return;
    }
    final book = chosen;
    await PhobesBottomSheet.show<void>(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: l10n.booksAddQuoteTitle,
        padding: 0,
        child: QuoteEditorSheet(
          bookService: bookService,
          presetBook: book,
        ),
      ),
    );
  }

  static Future<void> openForEdit(
    BuildContext context,
    BookService bookService,
    BookQuote quote,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await PhobesBottomSheet.show<void>(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: l10n.booksEditQuoteTitle,
        padding: 0,
        child: QuoteEditorSheet(
          bookService: bookService,
          existing: quote,
        ),
      ),
    );
  }

  static Future<UserBook?> _showBookPicker(
    BuildContext context,
    BookService bookService,
    AppLocalizations l10n,
  ) async {
    return PhobesBottomSheet.show<UserBook>(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: l10n.booksSelectBookForQuote,
        padding: 0,
        child: _BookPickerSheet(bookService: bookService, l10n: l10n),
      ),
    );
  }

  @override
  State<QuoteEditorSheet> createState() => _QuoteEditorSheetState();
}

class _QuoteEditorSheetState extends State<QuoteEditorSheet> {
  late final TextEditingController _textCtrl;
  late final TextEditingController _pageCtrl;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _textCtrl = TextEditingController(text: existing?.text ?? '');
    _pageCtrl =
        TextEditingController(text: existing?.page?.toString() ?? '');
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  String get _bookTitle =>
      widget.existing?.bookTitle ?? widget.presetBook?.title ?? '';

  String? get _userBookId =>
      widget.existing?.userBookId ?? widget.presetBook?.id;

  int get _color {
    if (widget.existing != null) return widget.existing!.color;
    return 0xFF8B5CF6;
  }

  Future<void> _save() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _saving) return;
    final ubId = _userBookId;
    if (ubId == null) return;
    setState(() => _saving = true);
    try {
      final page = int.tryParse(_pageCtrl.text.trim());
      if (_isEdit) {
        final updated = widget.existing!.copyWith(
          text: text,
          page: page,
          clearPage: page == null,
        );
        await widget.bookService.updateQuote(updated);
      } else {
        final q = BookQuote(
          userId: '',
          userBookId: ubId,
          bookTitle: _bookTitle,
          text: text,
          page: page,
          color: _color,
          createdAt: DateTime.now(),
        );
        await widget.bookService.addQuote(q);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(_color);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_bookTitle.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, size: 13, color: color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _bookTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          TextField(
              controller: _textCtrl,
              maxLines: 6,
              minLines: 4,
              autofocus: true,
              style: GoogleFonts.outfit(
                color: cs.onSurface,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: l10n.booksAddQuoteHint,
                hintStyle: GoogleFonts.outfit(
                  color: cs.onSurface.withOpacity(0.3),
                  fontStyle: FontStyle.italic,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.outline.withOpacity(0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.outline.withOpacity(0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 160,
              child: TextField(
                controller: _pageCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 13),
                decoration: InputDecoration(
                  hintText: l10n.booksQuotePageOptional,
                  hintStyle: GoogleFonts.outfit(
                    color: cs.onSurface.withOpacity(0.3),
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.bookmark_outline_rounded,
                    size: 16,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          const SizedBox(height: 20),
          PhobesButton(
            text: l10n.save,
            icon: Icons.save_rounded,
            width: double.infinity,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

// ─── Book picker bottom sheet ──────────────────────────────────────────────

class _BookPickerSheet extends StatelessWidget {
  final BookService bookService;
  final AppLocalizations l10n;
  const _BookPickerSheet({required this.bookService, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.booksSelectBookForQuote,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.booksSelectBookForQuoteHint,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: StreamBuilder<List<UserBook>>(
              stream: bookService.getBooksStream(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: PhobesLoadingIndicator(color: cs.primary),
                    ),
                  );
                }
                final books = snap.data ?? [];
                if (books.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        l10n.booksNoBooksForQuote,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final b = books[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, b),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            _BookCoverThumb(book: b),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (b.authors.isNotEmpty)
                                    Text(
                                      b.authors.join(', '),
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color:
                                            cs.onSurface.withOpacity(0.45),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: cs.onSurface.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCoverThumb extends StatelessWidget {
  final UserBook book;
  const _BookCoverThumb({required this.book});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = book.coverUrl;
    return Container(
      width: 36,
      height: 50,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.menu_book_rounded, color: cs.primary, size: 20),
            )
          : Icon(Icons.menu_book_rounded, color: cs.primary, size: 20),
    );
  }
}

// ─── Backwards-compatible Add Quote sheet entry point ─────────────────────

class AddQuoteDialog extends StatelessWidget {
  final String userBookId;
  final String bookTitle;
  final int bookColor;
  final BookService bookService;

  const AddQuoteDialog({
    super.key,
    required this.userBookId,
    required this.bookTitle,
    required this.bookColor,
    required this.bookService,
  });

  @override
  Widget build(BuildContext context) {
    // Build a synthetic UserBook for preset.
    final preset = UserBook(
      id: userBookId,
      userId: '',
      googleBooksId: '',
      title: bookTitle,
    );
    return QuoteEditorSheet(
      bookService: bookService,
      presetBook: preset,
    );
  }
}
