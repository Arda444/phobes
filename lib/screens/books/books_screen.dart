import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../widgets/phobes_widgets.dart';
import '../../core/module_info_catalog.dart';
import '../../core/module_ui_tokens.dart';
import '../../core/phobes_detail_panel.dart';
import '../../widgets/phobes_module_header.dart';
import 'package:phobes/l10n/app_localizations.dart';
import 'book_search_screen.dart';
import 'book_detail_screen.dart';
import 'book_quotes_screen.dart';

class BooksScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const BooksScreen({super.key, this.onClose});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen>
    with SingleTickerProviderStateMixin {
  final BookService _bookService = BookService();
  late TabController _tabController;
  late final Stream<List<UserBook>> _booksStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _booksStream = _bookService.getBooksStream().asBroadcastStream();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = ModuleUiTokens.isWideForm(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isWide ? 0 : 80),
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          PhobesModuleHeader(
              title: l10n.booksMyLibraryTitle,
              icon: Icons.menu_book_rounded,
              onClose: widget.onClose,
              onAdd: () => BookSearchScreen.open(context),
              addTooltip: l10n.booksAddBook,
              info: ModuleInfoCatalog.forBooks(l10n),
              subtitleWidget: StreamBuilder<List<UserBook>>(
                stream: _booksStream,
                builder: (context, snap) {
                  final total = snap.data?.length ?? 0;
                  final read =
                      snap.data?.where((b) => b.status == 'read').length ?? 0;
                  final reading =
                      snap.data?.where((b) => b.status == 'reading').length ?? 0;
                  return Text(
                    l10n.booksLibrarySubtitle(total, read, reading),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.72),
                    ),
                  );
                },
              ),
              tabController: _tabController,
              tabs: [
                PhobesModuleTab(l10n.booksTabLibrary, Icons.library_books_rounded),
                PhobesModuleTab(l10n.booksTabStats, Icons.bar_chart_rounded),
                PhobesModuleTab(l10n.booksTabQuotes, Icons.format_quote_rounded),
                PhobesModuleTab(l10n.booksTabGoals, Icons.flag_rounded),
              ],
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _LibraryTab(booksStream: _booksStream, bookService: _bookService),
            _StatsTab(booksStream: _booksStream, bookService: _bookService),
            _QuotesTabWrapper(bookService: _bookService),
            _GoalsTabWrapper(bookService: _bookService),
          ],
        ),
      ),
    );
  }

}

// ─── Tab 1: Library (Shelf View) ──────────────────────────────────────────

class _LibraryTab extends StatefulWidget {
  final Stream<List<UserBook>> booksStream;
  final BookService bookService;
  const _LibraryTab({required this.booksStream, required this.bookService});

  @override
  State<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<_LibraryTab> {
  String _filter = 'all';
  Map<String, UserBook> _bookMap = {};
  Map<int, String> _slotMap = {};
  Map<int, String> _shelfLabels = {};
  bool _loaded = false;
  bool _slotsLoaded = false;
  late final Stream<List<ShelfDecoration>> _decorationsStream;

  List<(String, String)> _filters(AppLocalizations l10n) => [
    ('all', l10n.booksFilterAll),
    ('to_read', l10n.booksStatusToRead),
    ('reading', l10n.booksStatusReading),
    ('read', l10n.booksStatusRead),
    ('lent', l10n.booksStatusLent),
  ];

  @override
  void initState() {
    super.initState();
    _decorationsStream =
        widget.bookService.getDecorationsStream().asBroadcastStream();
    widget.bookService.getSlotMap().then((map) {
      if (mounted) setState(() { _slotMap = map; _slotsLoaded = true; });
    });
    widget.bookService.getShelfLabels().then((labels) {
      if (mounted) setState(() => _shelfLabels = labels);
    });
  }

  /// Auto-place any books that are not yet assigned to a slot.
  void _autoPlaceNewBooks(List<UserBook> books) {
    final placedIds = _slotMap.values.toSet();
    final unplaced = books.where(
        (b) => b.id != null && !placedIds.contains(b.id)).toList();
    if (unplaced.isEmpty) return;
    int slot = 0;
    for (final book in unplaced) {
      while (_slotMap.containsKey(slot)) {
        slot++;
      }
      _slotMap[slot] = book.id!;
      slot++;
    }
    widget.bookService.saveSlotMap(_slotMap);
  }

  /// Remove deleted books from slotMap.
  void _cleanSlotMap() {
    final toRemove = <int>[];
    for (final entry in _slotMap.entries) {
      if (!_bookMap.containsKey(entry.value)) toRemove.add(entry.key);
    }
    if (toRemove.isNotEmpty) {
      for (final k in toRemove) {
        _slotMap.remove(k);
      }
      widget.bookService.saveSlotMap(_slotMap);
    }
  }

  /// Move a book from one slot to another. If target has a book, swap.
  void _placeBook(String bookId, int fromSlot, int toSlot) {
    if (fromSlot == toSlot) return;
    setState(() {
      final targetBookId = _slotMap[toSlot];
      if (targetBookId != null) {
        _slotMap[fromSlot] = targetBookId; // swap
      } else {
        _slotMap.remove(fromSlot);
      }
      _slotMap[toSlot] = bookId;
    });
    widget.bookService.saveSlotMap(_slotMap);
  }

  /// Filtered slotMap: only show books matching current filter.
  Map<int, String> get _filteredSlotMap {
    if (_filter == 'all') return _slotMap;
    return Map.fromEntries(_slotMap.entries.where((e) {
      final book = _bookMap[e.value];
      return book != null && book.status == _filter;
    }));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Builder(
      builder: (context) => StreamBuilder<List<UserBook>>(
        stream: widget.booksStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final books = snapshot.data!;
            _bookMap = {
              for (final b in books)
                if (b.id != null) b.id!: b
            };
            if (!_loaded && _slotsLoaded) {
              _loaded = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _autoPlaceNewBooks(books);
                  _cleanSlotMap();
                  setState(() {});
                }
              });
            } else if (_loaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _autoPlaceNewBooks(books);
                  _cleanSlotMap();
                  setState(() {});
                }
              });
            }
          }

          if (!_loaded && !snapshot.hasData) {
            return CustomScrollView(
              slivers: [
                SliverOverlapInjector(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: PhobesLoadingIndicator(color: cs.primary),
                    ),
                  ),
                ),
              ],
            );
          }

          final activeSlotMap = _filteredSlotMap;

          return CustomScrollView(
            slivers: [
              SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverToBoxAdapter(child: _buildFilterChips(cs, l10n)),
              if (_bookMap.isEmpty)
                SliverToBoxAdapter(child: _buildEmpty(cs, l10n))
              else
                SliverToBoxAdapter(
                  child: StreamBuilder<List<ShelfDecoration>>(
                    stream: _decorationsStream,
                    builder: (context, decoSnap) => _ShelfView(
                      bookMap: _bookMap,
                      slotMap: activeSlotMap,
                      decorations: decoSnap.data ?? [],
                      shelfLabels: _shelfLabels,
                      isDark: isDark,
                      cs: cs,
                      onMoveToSlot: _placeBook,
                      bookService: widget.bookService,
                      onLabelChanged: (row, label) {
                        setState(() => _shelfLabels = {
                              ..._shelfLabels,
                              row: label,
                            });
                        widget.bookService.saveShelfLabel(row, label);
                      },
                      onTap: (book) => PhobesDetailPanel.open(
                        context,
                        BookDetailScreen(userBook: book),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme cs, AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: _filters(l10n).map((f) {
          final isSelected = _filter == f.$1;
          final color = _statusColor(f.$1, cs);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(f.$2, style: GoogleFonts.outfit(fontSize: 12)),
              onSelected: (_) => setState(() => _filter = f.$1),
              selectedColor: color.withOpacity(0.15),
              checkmarkColor: color,
              labelStyle: GoogleFonts.outfit(
                color: isSelected ? color : cs.onSurface.withOpacity(0.55),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: isSelected ? color : cs.outline.withOpacity(0.2)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: PhobesEmptyState(
        icon: Icons.menu_book_rounded,
        title: _filter == 'all'
            ? l10n.booksEmptyLibraryTitle
            : l10n.booksEmptyFilterTitle,
        description: l10n.booksEmptyLibraryDesc,
      ),
    );
  }

  Color _statusColor(String status, ColorScheme cs) {
    switch (status) {
      case 'reading':
        return const Color(0xFF3B82F6);
      case 'read':
        return const Color(0xFF22C55E);
      case 'to_read':
        return cs.primary;
      case 'lent':
        return const Color(0xFFF59E0B);
      default:
        return cs.primary;
    }
  }
}

// ─── Shelf View ────────────────────────────────────────────────────────────

class _ShelfView extends StatefulWidget {
  final Map<String, UserBook> bookMap;
  final Map<int, String> slotMap;
  final List<ShelfDecoration> decorations;
  final Map<int, String> shelfLabels;
  final bool isDark;
  final ColorScheme cs;
  final void Function(String bookId, int fromSlot, int toSlot) onMoveToSlot;
  final void Function(UserBook) onTap;
  final void Function(int row, String label) onLabelChanged;
  final BookService bookService;

  const _ShelfView({
    required this.bookMap,
    required this.slotMap,
    required this.decorations,
    required this.shelfLabels,
    required this.isDark,
    required this.cs,
    required this.onMoveToSlot,
    required this.onTap,
    required this.onLabelChanged,
    required this.bookService,
  });

  @override
  State<_ShelfView> createState() => _ShelfViewState();
}

class _ShelfViewState extends State<_ShelfView> {
  String? _draggingBookId;
  int? _hoverSlot;

  // Books per section (bookend divider every N books).
  static const _sectionSize = 5;
  // Default minimum rows (creates a full bookcase look).
  static const _minRows = 5;

  static const _gap = 3.0;
  static const _bookH = 132.0;
  static const _shelfH = 12.0;
  static const _bookendW = 10.0;
  /// Tighter slots so cover art fills the shelf without wide gaps.
  static const _minSlotW = 82.0;
  static const _sectionW = _sectionSize * _minSlotW + _bookendW + 2;

  Color get _shelfColor =>
      widget.isDark ? const Color(0xFF3D2B1A) : const Color(0xFFC49A6C);

  Color get _shelfShadow => widget.isDark
      ? Colors.black.withOpacity(0.5)
      : Colors.black.withOpacity(0.2);

  Color get _bookendColor =>
      widget.isDark ? const Color(0xFF5D4037) : const Color(0xFFB8956A);

  /// Dynamically calculate how many books fit per shelf row.
  /// Adds a 5-book section whenever the screen is wide enough.
  int _perShelf(BuildContext ctx) {
    final available = MediaQuery.sizeOf(ctx).width - 24; // minus padding
    final sections = (available / _sectionW).floor().clamp(1, 4);
    return sections * _sectionSize;
  }

  int _numRows(int perShelf) {
    int maxSlot = 0;
    if (widget.slotMap.isNotEmpty) {
      maxSlot = widget.slotMap.keys.reduce((a, b) => a > b ? a : b);
    }
    final bookRows = ((maxSlot + 1) / perShelf).ceil();
    final expandRow = _draggingBookId != null ? 1 : 0;
    return [_minRows, bookRows + expandRow].reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final perShelf = _perShelf(context);
    final numRows = _numRows(perShelf);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 40),
      child: Column(
        children: List.generate(numRows, (row) => _buildRow(row, perShelf)),
      ),
    );
  }

  Widget _buildRow(int row, int perShelf) {
    // Number of 5-book sections in this row
    final numSections = (perShelf / _sectionSize).ceil();

    // Build book slots + bookend dividers
    final bookWidgets = <Widget>[];
    for (int col = 0; col < perShelf; col++) {
      // Insert vertical bookend between sections
      if (col > 0 && col % _sectionSize == 0) {
        bookWidgets.add(_buildBookend());
      }
      final slot = row * perShelf + col;
      final bookId = widget.slotMap[slot];
      final book = bookId != null ? widget.bookMap[bookId] : null;
      bookWidgets.add(
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: col < perShelf - 1 ? _gap : 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slotW = constraints.maxWidth;
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: book != null
                      ? _buildBookSlot(book, slot, slotW)
                      : _buildEmptySlot(slot, slotW),
                );
              },
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        // Books row with bookends
        SizedBox(
          height: _bookH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bookWidgets,
          ),
        ),
        // Wooden shelf board
        Container(
          height: _shelfH,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_shelfColor, _shelfColor.withOpacity(0.75)],
            ),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(3)),
            boxShadow: [
              BoxShadow(
                color: _shelfShadow,
                blurRadius: 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Opacity(
                  opacity: 0.15,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(height: 1, color: Colors.white),
                      Container(height: 1, color: Colors.black),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        // Section labels below the shelf — one label per 5-book section
        Row(
          children: List.generate(numSections, (section) {
            // Use a unique key: row * 100 + section
            final labelKey = row * 100 + section;
            return Expanded(
              child: _ShelfLabel(
                row: labelKey,
                label: widget.shelfLabels[labelKey] ?? '',
                isDark: widget.isDark,
                cs: widget.cs,
                onChanged: (label) =>
                    widget.onLabelChanged(labelKey, label),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Vertical wooden bookend divider between 5-book sections.
  Widget _buildBookend() {
    return Container(
      width: _bookendW,
      height: _bookH,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _bookendColor.withOpacity(0.6),
            _bookendColor,
            _bookendColor.withOpacity(0.85),
            _bookendColor.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            offset: const Offset(1, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Opacity(
        opacity: 0.12,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            8,
            (_) => Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlot(int slotIndex, double slotWidth) {
    // Check if a decoration occupies this slot.
    final deco =
        widget.decorations.where((d) => d.slotIndex == slotIndex).firstOrNull;
    if (deco != null) {
      return _buildDecorationSlot(deco, slotIndex);
    }

    final isHovered = _hoverSlot == slotIndex && _draggingBookId != null;

    return DragTarget<_SlotDragData>(
      onAcceptWithDetails: (d) {
        widget.onMoveToSlot(d.data.bookId, d.data.fromSlot, slotIndex);
        setState(() {
          _draggingBookId = null;
          _hoverSlot = null;
        });
      },
      onWillAcceptWithDetails: (d) {
        setState(() => _hoverSlot = slotIndex);
        return true;
      },
      onLeave: (_) => setState(() => _hoverSlot = null),
      builder: (context, candidates, _) {
        return GestureDetector(
          onTap: _draggingBookId == null
              ? () => _showDecorationPicker(context, slotIndex)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: _bookH,
            decoration: BoxDecoration(
              color: isHovered
                  ? widget.cs.primary.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isHovered
                    ? widget.cs.primary.withOpacity(0.6)
                    : widget.cs.onSurface.withOpacity(0.05),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add_rounded,
                size: 20,
                color: isHovered
                    ? widget.cs.primary.withOpacity(0.7)
                    : widget.cs.onSurface.withOpacity(0.08),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDecorationSlot(ShelfDecoration deco, int slotIndex) {
    return GestureDetector(
      onTap: () => _showDecorationPicker(context, slotIndex, existing: deco),
      child: SizedBox(
        height: _bookH,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(deco.emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  void _showDecorationPicker(BuildContext context, int slotIndex,
      {ShelfDecoration? existing}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DecorationPickerSheet(
        cs: widget.cs,
        isDark: widget.isDark,
        slotIndex: slotIndex,
        existing: existing,
        bookService: widget.bookService,
      ),
    );
  }

  Widget _buildBookSlot(UserBook book, int slot, double slotWidth) {
    final coverW = slotWidth.clamp(58.0, 92.0);
    final isHovered = _hoverSlot == slot &&
        _draggingBookId != null &&
        _draggingBookId != book.id;

    return DragTarget<_SlotDragData>(
      onAcceptWithDetails: (d) {
        widget.onMoveToSlot(d.data.bookId, d.data.fromSlot, slot);
        setState(() {
          _draggingBookId = null;
          _hoverSlot = null;
        });
      },
      onWillAcceptWithDetails: (d) {
        setState(() => _hoverSlot = slot);
        return d.data.bookId != book.id;
      },
      onLeave: (_) => setState(() => _hoverSlot = null),
      builder: (context, candidates, _) {
        return LongPressDraggable<_SlotDragData>(
          data: _SlotDragData(bookId: book.id!, fromSlot: slot),
          delay: const Duration(milliseconds: 350),
          onDragStarted: () => setState(() {
            _draggingBookId = book.id;
          }),
          onDragEnd: (_) => setState(() {
            _draggingBookId = null;
            _hoverSlot = null;
          }),
          feedback: Material(
            color: Colors.transparent,
            child: Transform.rotate(
              angle: -0.06,
              child: Opacity(
                opacity: 0.92,
                child:
                    _ShelfBookCard(
                      book: book,
                      width: coverW,
                      height: _bookH,
                      isDragging: true,
                    ),
              ),
            ),
          ),
          childWhenDragging: Container(
            height: _bookH,
            decoration: BoxDecoration(
              color: widget.cs.onSurface.withOpacity(0.04),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: widget.cs.primary.withOpacity(0.25)),
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            transform: Matrix4.identity()
              ..translate(0.0, isHovered ? -10.0 : 0.0),
            child: GestureDetector(
              onTap: () => widget.onTap(book),
              child:
                  _ShelfBookCard(
                    book: book,
                    width: coverW,
                    height: _bookH,
                    isDragging: false,
                  ),
            ),
          ),
        );
      },
    );
  }
}

class _SlotDragData {
  final String bookId;
  final int fromSlot;
  const _SlotDragData({required this.bookId, required this.fromSlot});
}

// ─── Shelf Label ──────────────────────────────────────────────────────────

class _ShelfLabel extends StatefulWidget {
  final int row;
  final String label;
  final bool isDark;
  final ColorScheme cs;
  final void Function(String) onChanged;

  const _ShelfLabel({
    required this.row,
    required this.label,
    required this.isDark,
    required this.cs,
    required this.onChanged,
  });

  @override
  State<_ShelfLabel> createState() => _ShelfLabelState();
}

class _ShelfLabelState extends State<_ShelfLabel> {
  late TextEditingController _ctrl;
  bool _editing = false;
  late FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.label);
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) {
        setState(() => _editing = false);
        widget.onChanged(_ctrl.text.trim());
      }
    });
  }

  @override
  void didUpdateWidget(_ShelfLabel old) {
    super.didUpdateWidget(old);
    if (old.label != widget.label && !_editing) {
      _ctrl.text = widget.label;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasLabel = _ctrl.text.isNotEmpty;

    return GestureDetector(
      onTap: () {
        setState(() => _editing = true);
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _focus.requestFocus());
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 28,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: _editing
            ? TextField(
                controller: _ctrl,
                focusNode: _focus,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: widget.cs.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: l10n.booksShelfNameHint,
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 11,
                    color: widget.cs.onSurface.withOpacity(0.3),
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: widget.cs.primary.withOpacity(0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: widget.cs.primary, width: 1.5),
                  ),
                  fillColor: widget.isDark
                      ? Colors.white.withOpacity(0.05)
                      : widget.cs.primary.withOpacity(0.04),
                  filled: true,
                ),
                onSubmitted: (v) {
                  setState(() => _editing = false);
                  widget.onChanged(v.trim());
                },
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasLabel) ...[
                    Icon(Icons.label_outline_rounded,
                        size: 10, color: widget.cs.onSurface.withOpacity(0.3)),
                    const SizedBox(width: 4),
                    Text(
                      _ctrl.text,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.cs.onSurface.withOpacity(0.45),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ] else
                    Icon(Icons.add_rounded,
                        size: 12, color: widget.cs.onSurface.withOpacity(0.12)),
                ],
              ),
      ),
    );
  }
}

// ─── Decoration Picker Sheet ───────────────────────────────────────────────

class _DecorationPickerSheet extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;
  final int slotIndex;
  final ShelfDecoration? existing;
  final BookService bookService;

  const _DecorationPickerSheet({
    required this.cs,
    required this.isDark,
    required this.slotIndex,
    required this.existing,
    required this.bookService,
  });

  static List<(String, List<String>)> _categories(AppLocalizations l10n) => [
    (
      l10n.booksDecorationCategoryPlants,
      [
        '🪴',
        '🌵',
        '🌿',
        '🌱',
        '🌺',
        '🌸',
        '🌻',
        '🌹',
        '🍀',
        '🌷',
        '🎋',
        '🎍',
        '🍃',
        '🌾'
      ]
    ),
    (
      l10n.booksDecorationCategoryObjects,
      [
        '🏺',
        '🫙',
        '🪔',
        '🕯️',
        '🔮',
        '🪆',
        '🗿',
        '🎭',
        '🪬',
        '💎',
        '🪩',
        '🎁',
        '🧸',
        '🪅'
      ]
    ),
    (
      l10n.booksDecorationCategoryDecor,
      [
        '🖼️',
        '📸',
        '🪞',
        '⭐',
        '🌟',
        '✨',
        '🎀',
        '🧩',
        '⌛',
        '🎶',
        '🎵',
        '📜',
        '🗝️',
        '🔭'
      ]
    ),
    (
      l10n.booksDecorationCategoryFigures,
      [
        '🦜',
        '🐱',
        '🐶',
        '🦊',
        '🐻',
        '🐺',
        '🦉',
        '🐧',
        '🦋',
        '🐉',
        '🦄',
        '🐙',
        '🐠',
        '🦀'
      ]
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cs.onSurface.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Text(l10n.booksPickDecorationTitle,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: cs.onSurface)),
              const Spacer(),
              if (existing != null)
                GestureDetector(
                  onTap: () async {
                    await bookService.removeDecoration(existing!.id!);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.error.withOpacity(0.3)),
                    ),
                    child: Text(l10n.booksRemove,
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: cs.error,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView(
              children: _categories(l10n).map((cat) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(cat.$1,
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withOpacity(0.45),
                              letterSpacing: 0.5)),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cat.$2.map((emoji) {
                        final isSelected = existing?.emoji == emoji;
                        return GestureDetector(
                          onTap: () async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid == null) return;
                            await bookService.addDecoration(ShelfDecoration(
                              userId: uid,
                              slotIndex: slotIndex,
                              emoji: emoji,
                            ));
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primary.withOpacity(0.15)
                                  : cs.onSurface.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? cs.primary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shelf Book Card ───────────────────────────────────────────────────────

class _ShelfBookCard extends StatelessWidget {
  final UserBook book;
  final double width;
  final double height;
  final bool isDragging;

  const _ShelfBookCard({
    required this.book,
    required this.width,
    required this.height,
    required this.isDragging,
  });

  static const _spineColors = [
    Color(0xFF6366F1),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFFE11D48),
    Color(0xFF7C3AED),
    Color(0xFF0EA5E9),
  ];

  Color get _spineColor =>
      _spineColors[book.title.hashCode.abs() % _spineColors.length];

  @override
  Widget build(BuildContext context) {
    final color = _spineColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDragging ? 0.5 : 0.3),
            blurRadius: isDragging ? 20 : 6,
            offset: Offset(isDragging ? 4 : 2, isDragging ? 8 : 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        child: book.coverUrl != null
            ? Stack(
                children: [
                  Image.network(
                    book.coverUrl!,
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildSpine(color),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return _buildSpine(color);
                    },
                  ),
                  // Status dot
                  _buildStatusDot(),
                  // Bottom gradient with title
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.75),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        book.title,
                        style: GoogleFonts.outfit(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              )
            : _buildSpine(color),
      ),
    );
  }

  Widget _buildSpine(Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.9),
            color,
            color.withOpacity(0.75),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Left spine highlight
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          // Centered vertical title
          Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                book.title,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
          // Author at top (rotated)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                book.authorsDisplay,
                style: GoogleFonts.outfit(
                  fontSize: 7,
                  color: Colors.white.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.fade,
                textAlign: TextAlign.right,
              ),
            ),
          ),
          _buildStatusDot(),
        ],
      ),
    );
  }

  Widget _buildStatusDot() {
    if (book.status == 'to_read') return const SizedBox.shrink();
    final (icon, color) = switch (book.status) {
      'reading' => (Icons.auto_stories_rounded, const Color(0xFF3B82F6)),
      'read' => (Icons.check_circle_rounded, const Color(0xFF22C55E)),
      'lent' => (Icons.swap_horiz_rounded, const Color(0xFFF59E0B)),
      _ => (Icons.circle, Colors.grey),
    };
    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 3)],
        ),
        child: Icon(icon, size: 8, color: Colors.white),
      ),
    );
  }
}

// ─── Tab 2: Statistics ─────────────────────────────────────────────────────

class _StatsTab extends StatefulWidget {
  final Stream<List<UserBook>> booksStream;
  final BookService bookService;
  const _StatsTab({required this.booksStream, required this.bookService});

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  Map<String, dynamic> _stats = {};
  List<Book> _recommendations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await widget.bookService.getReadingStats();
    final cats = List<String>.from(stats['preferredCategories'] ?? []);
    final authors = List<String>.from(stats['preferredAuthors'] ?? []);
    final recs = await widget.bookService.getRecommendations(
      preferredCategories: cats,
      preferredAuthors: authors,
    );
    if (mounted) {
      setState(() {
        _stats = stats;
        _recommendations = recs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Builder(
      builder: (context) => CustomScrollView(
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          if (_loading)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: PhobesLoadingIndicator(color: cs.primary),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: isWide ? 720 : double.infinity),
                      child: Column(
                        children: [
                          _buildSummary(cs, l10n),
                          const SizedBox(height: 20),
                          _buildCategoryChart(cs, l10n),
                          const SizedBox(height: 20),
                          _buildReadingSpeed(cs, l10n),
                          const SizedBox(height: 24),
                          if (_recommendations.isNotEmpty)
                            _buildRecommendations(cs, l10n),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary(ColorScheme cs, AppLocalizations l10n) {
    final cards = [
      ('📚', '${_stats['totalBooks'] ?? 0}', l10n.booksStatTotal, cs.primary),
      ('✅', '${_stats['readBooks'] ?? 0}', l10n.booksStatusRead,
          const Color(0xFF22C55E)),
      (
        '📖',
        '${_stats['readingBooks'] ?? 0}',
        l10n.booksStatusReading,
        const Color(0xFF3B82F6)
      ),
      ('🔖', '${_stats['toReadBooks'] ?? 0}', l10n.booksStatusToRead,
          cs.primary),
      (
        '📄',
        '${_stats['totalPagesRead'] ?? 0}',
        l10n.booksStatPages,
        const Color(0xFF8B5CF6)
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: cards.length > 6 ? 6 : cards.length,
      itemBuilder: (context, i) {
        if (i >= cards.length) return const SizedBox.shrink();
        final c = cards[i];
        return FadeInUp(
          delay: Duration(milliseconds: i * 50),
          child: PhobesCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(c.$1, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(c.$2,
                    style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: c.$4)),
                Text(c.$3,
                    style: GoogleFonts.outfit(
                        fontSize: 10, color: cs.onSurface.withOpacity(0.45)),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChart(ColorScheme cs, AppLocalizations l10n) {
    final dist = Map<String, int>.from(_stats['categoryDistribution'] ?? {});
    if (dist.isEmpty) return const SizedBox.shrink();
    final total = dist.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    const colors = [
      Color(0xFF8B5E3C),
      Color(0xFF3B82F6),
      Color(0xFF22C55E),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
    ];
    final entries = (dist.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(6)
        .toList();
    final sections = entries.asMap().entries.map((e) {
      final color = colors[e.key % colors.length];
      return PieChartSectionData(
        value: e.value.value.toDouble(),
        title: '${(e.value.value / total * 100).toInt()}%',
        color: color,
        radius: 56,
        titleStyle: GoogleFonts.outfit(
            fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return FadeInUp(
      child: PhobesCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.booksCategoryDistributionTitle,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.5),
                    letterSpacing: 0.8)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: PieChart(PieChartData(
                sections: sections,
                centerSpaceRadius: 28,
                sectionsSpace: 2,
              )),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: entries.asMap().entries.map((e) {
                final color = colors[e.key % colors.length];
                return Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('${e.value.key} (${e.value.value})',
                      style: GoogleFonts.outfit(
                          fontSize: 10, color: cs.onSurface.withOpacity(0.55))),
                ]);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingSpeed(ColorScheme cs, AppLocalizations l10n) {
    final avg = (_stats['avgPagesPerDay'] as double?) ?? 0.0;
    if (avg == 0) return const SizedBox.shrink();
    return FadeInUp(
      child: PhobesCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.booksReadingSpeedTitle,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.5),
                    letterSpacing: 0.8)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _SpeedTile('📖', avg.toStringAsFixed(0),
                        l10n.booksPagesPerDay, const Color(0xFF3B82F6), cs)),
                const SizedBox(width: 10),
                Expanded(
                    child: _SpeedTile('📅', (avg * 7).toStringAsFixed(0),
                        l10n.booksPagesPerWeek, const Color(0xFF8B5CF6), cs)),
                const SizedBox(width: 10),
                Expanded(
                    child: _SpeedTile('📚', (avg * 30 / 300).toStringAsFixed(1),
                        l10n.booksBooksPerMonth, const Color(0xFF22C55E), cs)),
              ],
            ),
            const SizedBox(height: 6),
            Text(l10n.booksReadingSpeedFootnote,
                style: GoogleFonts.outfit(
                    fontSize: 9, color: cs.onSurface.withOpacity(0.3))),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(ColorScheme cs, AppLocalizations l10n) {
    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.booksRecommendationsTitle,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: cs.onSurface)),
          const SizedBox(height: 4),
          Text(l10n.booksRecommendationsSubtitle,
              style: GoogleFonts.outfit(
                  fontSize: 11, color: cs.onSurface.withOpacity(0.4))),
          const SizedBox(height: 12),
          SizedBox(
            height: 185,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendations.length,
              itemBuilder: (context, i) => FadeInRight(
                delay: Duration(milliseconds: i * 40),
                child: _RecCard(book: _recommendations[i], cs: cs),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedTile extends StatelessWidget {
  final String icon, value, label;
  final Color color;
  final ColorScheme cs;
  const _SpeedTile(this.icon, this.value, this.label, this.color, this.cs);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 9, color: cs.onSurface.withOpacity(0.45)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _RecCard extends StatelessWidget {
  final Book book;
  final ColorScheme cs;
  const _RecCard({required this.book, required this.cs});

  @override
  Widget build(BuildContext context) {
    const colors = [Color(0xFF6366F1), Color(0xFF3B82F6), Color(0xFF22C55E)];
    final c = colors[book.title.hashCode.abs() % colors.length];
    return Container(
      width: 108,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book.coverUrl != null
                  ? Image.network(book.coverUrl!,
                      width: 108,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ph(c))
                  : _ph(c),
            ),
          ),
          const SizedBox(height: 5),
          Text(book.title,
              style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (book.authors.isNotEmpty)
            Text(book.authors.first,
                style: GoogleFonts.outfit(
                    fontSize: 9, color: cs.onSurface.withOpacity(0.4)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _ph(Color c) => Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [c, c.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(8)),
      child:
          const Icon(Icons.menu_book_rounded, color: Colors.white54, size: 32));
}

// ─── Tab 3: Quotes ─────────────────────────────────────────────────────────

class _QuotesTabWrapper extends StatefulWidget {
  final BookService bookService;
  const _QuotesTabWrapper({required this.bookService});

  @override
  State<_QuotesTabWrapper> createState() => _QuotesTabWrapperState();
}

class _QuotesTabWrapperState extends State<_QuotesTabWrapper> {
  late final Stream<List<BookQuote>> _quotesStream;

  @override
  void initState() {
    super.initState();
    _quotesStream = widget.bookService.getQuotesStream().asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Builder(
      builder: (context) => CustomScrollView(
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          StreamBuilder<List<BookQuote>>(
            stream: _quotesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: PhobesLoadingIndicator(color: cs.primary),
                    ),
                  ),
                );
              }
              final quotes = snapshot.data ?? [];
              if (quotes.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          const PhobesGlassCard(
                            padding: EdgeInsets.all(24),
                            borderRadius: 32,
                            child: Text('💬', style: TextStyle(fontSize: 44)),
                          ),
                          const SizedBox(height: 20),
                          Text(l10n.booksQuotesEmptyTitle,
                              style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface)),
                          const SizedBox(height: 8),
                          Text(
                            l10n.booksQuotesEmptyDescTab,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: cs.onSurface.withOpacity(0.4)),
                          ),
                          const SizedBox(height: 20),
                          PhobesButton(
                            text: l10n.booksAddQuoteTitle,
                            icon: Icons.add_rounded,
                            onPressed: () => QuoteEditorSheet.openForNew(
                              context,
                              widget.bookService,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AddQuoteShortcut(
                          onTap: () => QuoteEditorSheet.openForNew(
                            context,
                            widget.bookService,
                          ),
                        ),
                      ),
                    ),
                    SliverLayoutBuilder(
                      builder: (context, sliverConstraints) {
                        final w = sliverConstraints.crossAxisExtent;
                        final cols = w >= 1500
                            ? 4
                            : w >= 1100
                                ? 3
                                : w >= 700
                                    ? 2
                                    : 1;
                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 200,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => FadeInUp(
                              delay: Duration(milliseconds: i * 35),
                              child: QuoteCard(
                                quote: quotes[i],
                                bookService: widget.bookService,
                                grid: true,
                              ),
                            ),
                            childCount: quotes.length,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AddQuoteShortcut extends StatelessWidget {
  final VoidCallback onTap;
  const _AddQuoteShortcut({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.primary.withOpacity(0.25),
            width: 1.2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withOpacity(0.10),
              cs.primary.withOpacity(0.03),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add_rounded, size: 18, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.booksAddQuoteTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    l10n.booksSelectBookForQuoteHint,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 4: Goals ──────────────────────────────────────────────────────────

class _GoalsTabWrapper extends StatefulWidget {
  final BookService bookService;
  const _GoalsTabWrapper({required this.bookService});

  @override
  State<_GoalsTabWrapper> createState() => _GoalsTabWrapperState();
}

class _GoalsTabWrapperState extends State<_GoalsTabWrapper> {
  late final Stream<List<ReadingGoal>> _goalsStream;

  @override
  void initState() {
    super.initState();
    _goalsStream = widget.bookService.getGoalsStream().asBroadcastStream();
  }

  void _showAddGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddGoalSheetInline(bookService: widget.bookService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Builder(
      builder: (context) => CustomScrollView(
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.booksGoalsTitle,
                      style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface)),
                  PhobesIconButton(
                    icon: Icons.add_rounded,
                    backgroundColor: cs.primary,
                    color: Colors.white,
                    onTap: () => _showAddGoalSheet(context),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<ReadingGoal>>(
            stream: _goalsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: PhobesLoadingIndicator(color: cs.primary),
                    ),
                  ),
                );
              }
              final goals = snapshot.data ?? [];
              if (goals.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          const PhobesGlassCard(
                            padding: EdgeInsets.all(24),
                            borderRadius: 32,
                            child: Text('🎯', style: TextStyle(fontSize: 44)),
                          ),
                          const SizedBox(height: 20),
                          Text(l10n.booksGoalsEmptyTitleTab,
                              style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface)),
                          const SizedBox(height: 8),
                          Text(
                            l10n.booksGoalsEmptyDescTab,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: cs.onSurface.withOpacity(0.4)),
                          ),
                          const SizedBox(height: 20),
                          PhobesButton(
                            text: l10n.booksAddGoal,
                            icon: Icons.flag_rounded,
                            onPressed: () => _showAddGoalSheet(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                sliver: SliverLayoutBuilder(
                  builder: (context, sliverConstraints) {
                    final w = sliverConstraints.crossAxisExtent;
                    final cols = w >= 1500
                        ? 4
                        : w >= 1100
                            ? 3
                            : w >= 700
                                ? 2
                                : 1;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 200,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => FadeInUp(
                          delay: Duration(milliseconds: i * 50),
                          child: _GoalCard(
                            goal: goals[i],
                            bookService: widget.bookService,
                            onDelete: () =>
                                widget.bookService.deleteGoal(goals[i].id!),
                          ),
                        ),
                        childCount: goals.length,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Goal Card ─────────────────────────────────────────────────────────────

class _GoalCard extends StatefulWidget {
  final ReadingGoal goal;
  final BookService bookService;
  final VoidCallback onDelete;
  const _GoalCard(
      {required this.goal, required this.bookService, required this.onDelete});

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  int _progress = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.bookService.calculateGoalProgress(widget.goal).then((p) {
      if (mounted) {
        setState(() {
          _progress = p;
          _loaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final goal = widget.goal;
    final color = Color(goal.color);
    final unit =
        goal.isPageGoal ? l10n.booksUnitPages : l10n.booksUnitBooks;
    final pct = goal.targetValue > 0
        ? (_progress / goal.targetValue).clamp(0.0, 1.0)
        : 0.0;
    final isDone = _progress >= goal.targetValue && goal.targetValue > 0;

    return PhobesCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child:
                        Text(goal.icon, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: cs.onSurface)),
                    Text(goal.periodLabel,
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: cs.onSurface.withOpacity(0.4))),
                  ],
                ),
              ),
              if (isDone)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF22C55E).withOpacity(0.3)),
                  ),
                  child: Text('✓',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF22C55E),
                          fontWeight: FontWeight.w700)),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onDelete,
                child: Icon(Icons.close_rounded,
                    size: 16, color: cs.onSurface.withOpacity(0.25)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loaded
                    ? l10n.booksGoalProgress(_progress, goal.targetValue, unit)
                    : '...',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: cs.onSurface),
              ),
              Text('${(pct * 100).toInt()}%',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDone ? const Color(0xFF22C55E) : color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _loaded ? pct : null,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.1),
              color: isDone ? const Color(0xFF22C55E) : color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Goal Sheet (inline version for tab) ───────────────────────────────

class _AddGoalSheetInline extends StatefulWidget {
  final BookService bookService;
  const _AddGoalSheetInline({required this.bookService});

  @override
  State<_AddGoalSheetInline> createState() => _AddGoalSheetInlineState();
}

class _AddGoalSheetInlineState extends State<_AddGoalSheetInline> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController(text: '12');
  String _type = 'yearly_books';
  String _icon = '🎯';
  int _color = 0xFF8B5E3C;
  bool _saving = false;
  final _now = DateTime.now();

  static const _icons = ['🎯', '📚', '📖', '✨', '🔥', '⭐', '🏆', '💪'];
  static const _colors = [
    0xFF8B5E3C,
    0xFF6366F1,
    0xFF3B82F6,
    0xFF22C55E,
    0xFFF59E0B,
    0xFF8B5CF6,
    0xFFEF4444,
    0xFFEC4899,
  ];
  static List<(String, String, String)> _types(AppLocalizations l10n) => [
    ('yearly_books', l10n.booksGoalTypeYearlyBooks, '📚'),
    ('monthly_books', l10n.booksGoalTypeMonthlyBooks, '📖'),
    ('yearly_pages', l10n.booksGoalTypeYearlyPages, '📄'),
    ('monthly_pages', l10n.booksGoalTypeMonthlyPages, '📑'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  String _defaultTitle(AppLocalizations l10n) {
    final target = int.tryParse(_targetCtrl.text.trim()) ?? 0;
    return switch (_type) {
      'yearly_books' => l10n.booksGoalDefaultYearlyBooks(target),
      'monthly_books' => l10n.booksGoalDefaultMonthlyBooks(target),
      'yearly_pages' => l10n.booksGoalDefaultYearlyPages(target),
      'monthly_pages' => l10n.booksGoalDefaultMonthlyPages(target),
      _ => l10n.booksGoalDefaultFallback,
    };
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    final title = _titleCtrl.text.trim().isEmpty
        ? _defaultTitle(l10n)
        : _titleCtrl.text.trim();
    final target = int.tryParse(_targetCtrl.text.trim()) ?? 0;
    if (target <= 0) return;
    setState(() => _saving = true);
    try {
      await widget.bookService.addGoal(ReadingGoal(
        userId: '',
        title: title,
        type: _type,
        targetValue: target,
        year: _now.year,
        month: _type.startsWith('monthly') ? _now.month : null,
        icon: _icon,
        color: _color,
        createdAt: DateTime.now(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTitle = _defaultTitle(l10n);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(l10n.booksNewGoalTitle,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: cs.onSurface)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types(l10n).map((t) {
                  final sel = _type == t.$1;
                  final c = Color(_color);
                  return GestureDetector(
                    onTap: () => setState(() => _type = t.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? c.withOpacity(0.12)
                            : cs.onSurface.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel ? c : cs.outline.withOpacity(0.15),
                            width: sel ? 1.5 : 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(t.$3),
                        const SizedBox(width: 6),
                        Text(t.$2,
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.normal,
                                color:
                                    sel ? c : cs.onSurface.withOpacity(0.6))),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(color: cs.onSurface),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: _type.endsWith('books')
                      ? l10n.booksGoalTargetBooksLabel
                      : l10n.booksGoalTargetPagesLabel,
                  suffixText: _type.endsWith('books')
                      ? l10n.booksUnitBooks
                      : l10n.booksUnitPages,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleCtrl,
                style: GoogleFonts.outfit(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: defaultTitle,
                  hintStyle:
                      GoogleFonts.outfit(color: cs.onSurface.withOpacity(0.3)),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icons
                    .map((e) => GestureDetector(
                          onTap: () => setState(() => _icon = e),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _icon == e
                                  ? Color(_color).withOpacity(0.15)
                                  : cs.onSurface.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _icon == e
                                      ? Color(_color)
                                      : Colors.transparent),
                            ),
                            child: Center(
                                child: Text(e,
                                    style: const TextStyle(fontSize: 18))),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colors
                    .map((c) => GestureDetector(
                          onTap: () => setState(() => _color = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _color == c
                                      ? cs.onSurface
                                      : Colors.transparent,
                                  width: 2),
                              boxShadow: _color == c
                                  ? [
                                      BoxShadow(
                                          color: Color(c).withOpacity(0.4),
                                          blurRadius: 6)
                                    ]
                                  : null,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              PhobesButton(
                text: l10n.booksCreateGoal,
                icon: Icons.flag_rounded,
                width: double.infinity,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
