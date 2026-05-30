import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/module_ui_tokens.dart';
import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../widgets/phobes_form_wrapper.dart';
import '../../widgets/phobes_widgets.dart';
import 'package:phobes/l10n/app_localizations.dart';

class BookSearchScreen extends StatefulWidget {
  /// When provided, the screen acts as a book picker:
  /// tapping a result calls [onBookPicked] instead of adding to the library.
  final void Function(Book)? onBookPicked;

  /// Embedded in [PhobesFormWrapper] right panel (web/desktop wide layout).
  final bool embedInPanel;

  const BookSearchScreen({
    super.key,
    this.onBookPicked,
    this.embedInPanel = false,
  });

  /// Wide: right-side panel. Narrow: full-screen route.
  static Future<void> open(
    BuildContext context, {
    void Function(Book)? onBookPicked,
  }) {
    final l10n = AppLocalizations.of(context)!;
    if (ModuleUiTokens.isWideForm(context)) {
      return PhobesFormWrapper.show<void>(
        context,
        title: l10n.booksAddBook,
        panelWidth: 480,
        form: BookSearchScreen(
          embedInPanel: true,
          onBookPicked: onBookPicked,
        ),
      );
    }
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BookSearchScreen(onBookPicked: onBookPicked),
      ),
    );
  }

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final BookService _bookService = BookService();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Book> _results = [];
  bool _loading = false;
  String? _searchNotice;
  Timer? _debounce;
  final Set<String> _addedIds = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _searchNotice = null;
    });
    final results = await _bookService.searchBooksEnhanced(q);
    if (mounted) {
      setState(() {
        _results = results;
        _searchNotice = _bookService.lastSearchNotice;
        _loading = false;
      });
    }
  }

  Future<void> _addBook(Book book, String status) async {
    try {
      await _bookService.addBook(book, status: status);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _addedIds.add(book.googleBooksId));
        PhobesSnackbar.show(
          context,
          message: l10n.booksBookAddedSuccess,
          type: PhobesSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        PhobesSnackbar.show(
          context,
          message: l10n.booksBookAddFailed,
          type: PhobesSnackbarType.error,
        );
      }
    }
  }

  Future<void> _showAddDialog(Book book) async {
    final status = await _pickShelfStatus(context, book);
    if (status != null) {
      await _addBook(book, status);
    }
  }

  static Future<String?> _pickShelfStatus(BuildContext context, Book book) {
    final l10n = AppLocalizations.of(context)!;
    if (ModuleUiTokens.isWideForm(context)) {
      return PhobesFormWrapper.show<String>(
        context,
        title: l10n.booksAddBookWhereTitle,
        panelWidth: 400,
        form: _AddBookStatusForm(book: book),
      );
    }
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.94,
        expand: false,
        builder: (_, scrollController) {
          final cs = Theme.of(ctx).colorScheme;
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : cs.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _AddBookStatusForm(book: book, scrollable: false),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _BookSearchBody(
      searchCtrl: _searchCtrl,
      results: _results,
      loading: _loading,
      searchNotice: _searchNotice,
      addedIds: _addedIds,
      onSearchChanged: _onSearchChanged,
      onClear: () {
        _searchCtrl.clear();
        setState(() => _results = []);
      },
      onBookAction: (book) async {
        if (widget.onBookPicked != null) {
          widget.onBookPicked!(book);
          if (context.mounted) Navigator.pop(context);
        } else {
          await _showAddDialog(book);
        }
      },
    );

    if (widget.embedInPanel) {
      return body;
    }

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
        title: Text(
          l10n.booksSearchTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ),
      body: body,
    );
  }
}

class _BookSearchBody extends StatelessWidget {
  final TextEditingController searchCtrl;
  final List<Book> results;
  final bool loading;
  final String? searchNotice;
  final Set<String> addedIds;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;
  final ValueChanged<Book> onBookAction;

  const _BookSearchBody({
    required this.searchCtrl,
    required this.results,
    required this.loading,
    required this.searchNotice,
    required this.addedIds,
    required this.onSearchChanged,
    required this.onClear,
    required this.onBookAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: TextField(
            controller: searchCtrl,
            onChanged: onSearchChanged,
            autofocus: true,
            style: GoogleFonts.outfit(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: l10n.booksSearchHint,
              hintStyle:
                  GoogleFonts.outfit(color: cs.onSurface.withOpacity(0.4)),
              prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
              suffixIcon: searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: onClear,
                    )
                  : null,
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (searchNotice != null && !loading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              searchNotice!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.55),
              ),
            ),
          ),
        if (loading)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: PhobesLoadingIndicator(color: cs.primary),
            ),
          )
        else if (results.isEmpty && searchCtrl.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded,
                    size: 48, color: cs.onSurface.withOpacity(0.2)),
                const SizedBox(height: 12),
                Text(
                  l10n.booksSearchNoResults,
                  style: GoogleFonts.outfit(
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final book = results[index];
                final isAdded = addedIds.contains(book.googleBooksId);
                return FadeInRight(
                  delay: Duration(milliseconds: index * 30),
                  child: _SearchResultCard(
                    book: book,
                    isAdded: isAdded,
                    onAdd: () => onBookAction(book),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _AddBookStatusForm extends StatelessWidget {
  final Book book;
  final bool scrollable;

  const _AddBookStatusForm({
    required this.book,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          book.title,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: cs.onSurface.withOpacity(0.5),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        _StatusOption(
          icon: Icons.bookmark_add_rounded,
          label: l10n.booksAddToWantToRead,
          color: cs.primary,
          onTap: () => Navigator.pop(context, 'to_read'),
        ),
        const SizedBox(height: 10),
        _StatusOption(
          icon: Icons.auto_stories_rounded,
          label: l10n.booksAddToCurrentlyReading,
          color: const Color(0xFF3B82F6),
          onTap: () => Navigator.pop(context, 'reading'),
        ),
        const SizedBox(height: 10),
        _StatusOption(
          icon: Icons.check_circle_rounded,
          label: l10n.booksAddToRead,
          color: const Color(0xFF22C55E),
          onTap: () => Navigator.pop(context, 'read'),
        ),
      ],
    );

    if (!scrollable) return content;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: content,
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Book book;
  final bool isAdded;
  final VoidCallback onAdd;

  const _SearchResultCard({
    required this.book,
    required this.isAdded,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return PhobesCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: book.coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: book.coverUrl!,
                    width: 52, height: 74, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _fallbackCover(book.title),
                  )
                : _fallbackCover(book.title),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (book.authors.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    book.authorsDisplay,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (book.pageCount > 0) ...[
                      Icon(Icons.menu_book_rounded, size: 11, color: cs.onSurface.withOpacity(0.35)),
                      const SizedBox(width: 3),
                      Text(
                        l10n.booksPageCount(book.pageCount),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: cs.onSurface.withOpacity(0.35),
                        ),
                      ),
                    ],
                    if (book.categories.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          book.primaryCategory,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: cs.primary.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isAdded ? null : onAdd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isAdded
                    ? const Color(0xFF22C55E)
                    : cs.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isAdded ? Icons.check_rounded : Icons.add_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackCover(String title) {
    const colors = [
      Color(0xFF6366F1), Color(0xFF3B82F6),
      Color(0xFF10B981), Color(0xFFF59E0B),
    ];
    final c = colors[title.hashCode.abs() % colors.length];
    return Container(
      width: 52, height: 74,
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
      child: const Icon(Icons.menu_book_rounded, color: Colors.white54, size: 24),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatusOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
