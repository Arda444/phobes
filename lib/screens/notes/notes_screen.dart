import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/phobes_theme.dart';
import '../../core/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../models/note_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/phobes_widgets.dart';
import '../../core/module_info_catalog.dart';
import '../../widgets/phobes_module_header.dart';
import 'note_add_edit_screen.dart';
import 'notebook_sidebar.dart';

class NotesScreen extends StatefulWidget {
  final String? teamFilterId;
  final bool isEmbedded;

  const NotesScreen({
    super.key,
    this.teamFilterId,
    this.isEmbedded = false,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isGridView = true;
  String _sortBy = 'date';
  final _searchController = TextEditingController();

  String? _selectedNotebookId;
  final bool _isSidebarExpanded = true;
  Timer? _searchDebounce;

  Stream<List<Note>>? _notesStream;
  String? _streamCacheKey;

  final List<String> _tabKeys = [
    'all',
    'team',
    'project',
    'favorites',
    'archive',
    'trash'
  ];
  final List<IconData> _tabIcons = [
    Icons.note_alt_rounded,
    Icons.groups_rounded,
    Icons.folder_rounded,
    Icons.star_rounded,
    Icons.archive_rounded,
    Icons.delete_rounded,
  ];

  static const _categories = [
    ('all', Icons.apps_rounded, 0xFF9E9E9E),
    ('general', Icons.note_rounded, 0xFF6C63FF),
    ('work', Icons.work_rounded, 0xFF4285F4),
    ('personal', Icons.person_rounded, 0xFFFF6B6B),
    ('ideas', Icons.lightbulb_rounded, 0xFFFFB800),
    ('meeting', Icons.groups_rounded, 0xFF00BFA5),
    ('research', Icons.science_rounded, 0xFF9C27B0),
    ('study', Icons.school_rounded, 0xFFFF7043),
  ];

  Stream<List<Note>> _getStream() {
    final key = '${widget.teamFilterId}|$_currentTab|$_selectedNotebookId';
    if (_streamCacheKey == key && _notesStream != null) return _notesStream!;
    _streamCacheKey = key;
    if (widget.teamFilterId != null) {
      _notesStream = FirebaseService().getTeamNotesStream(widget.teamFilterId!);
    } else if (_currentTab == 4) {
      _notesStream = FirebaseService().getArchivedNotesStream();
    } else if (_currentTab == 5) {
      _notesStream = FirebaseService().getTrashStream();
    } else if (_selectedNotebookId != null) {
      _notesStream =
          FirebaseService().getNotesByNotebookStream(_selectedNotebookId!);
    } else {
      _notesStream = FirebaseService().getNotesStream();
    }
    return _notesStream!;
  }

  @override
  void initState() {
    super.initState();
    final tabCount = widget.teamFilterId != null ? 1 : 6;
    _tabController = TabController(length: tabCount, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _currentTab != _tabController.index) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  String _getTabName(String key, AppLocalizations? l10n) {
    switch (key) {
      case 'all':
        return l10n?.noteAll ?? 'All';
      case 'team':
        return l10n?.noteTeamNotes ?? 'Team';
      case 'project':
        return l10n?.noteProjectNotes ?? 'Projects';
      case 'favorites':
        return l10n?.noteFavorites ?? 'Favorites';
      case 'archive':
        return l10n?.noteArchive ?? 'Archive';
      case 'trash':
        return l10n?.noteTrash ?? 'Trash';
      default:
        return key;
    }
  }

  String _getCategoryName(String key, AppLocalizations? l10n) {
    switch (key) {
      case 'all':
        return l10n?.noteAll ?? 'All';
      case 'general':
        return l10n?.noteCatGeneral ?? 'General';
      case 'work':
        return l10n?.noteCatWork ?? 'Work';
      case 'personal':
        return l10n?.noteCatPersonal ?? 'Personal';
      case 'ideas':
        return l10n?.noteCatIdeas ?? 'Ideas';
      case 'meeting':
        return l10n?.noteCatMeeting ?? 'Meeting';
      case 'research':
        return l10n?.noteCatResearch ?? 'Research';
      case 'study':
        return l10n?.noteCatStudy ?? 'Study';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;
    final l10n = AppLocalizations.of(context);
    final isCompact = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: widget.isEmbedded
          ? Colors.transparent
          : (isAmoled && isDark ? Colors.black : cs.surface),
      drawer: isCompact
          ? Drawer(
              child: NotebookSidebar(
                selectedNotebookId: _selectedNotebookId,
                onSelected: (id) {
                  setState(() => _selectedNotebookId = id);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: SafeArea(
        top: !widget.isEmbedded,
        child: Row(
          children: [
            if (!isCompact && !widget.isEmbedded)
              NotebookSidebar(
                selectedNotebookId: _selectedNotebookId,
                onSelected: (id) => setState(() => _selectedNotebookId = id),
                isExpanded: _isSidebarExpanded,
              ),
            Expanded(
              child: widget.isEmbedded ? _buildEmbeddedContent(cs, isDark, l10n, isCompact) : _buildStandardContent(cs, isDark, l10n, isCompact),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardContent(ColorScheme cs, bool isDark, AppLocalizations? l10n, bool isCompact) {
     return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        PhobesModuleHeader(
          title: l10n?.notes ?? 'Notlar',
            icon: Icons.note_alt_rounded,
            onClose: () => Navigator.pop(context),
            info: l10n != null ? ModuleInfoCatalog.forNotes(l10n) : null,
            extraActions: [
              if (isCompact)
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
              _headerIcon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                () => setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                }),
              ),
              _headerIcon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                () => setState(() => _isGridView = !_isGridView),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                offset: const Offset(0, 45),
                onSelected: (v) => setState(() => _sortBy = v),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'date', child: Text(l10n?.noteSortDate ?? 'Tarih')),
                  PopupMenuItem(value: 'title', child: Text(l10n?.noteSortTitle ?? 'Başlık')),
                  PopupMenuItem(value: 'category', child: Text(l10n?.noteSortCategory ?? 'Kategori')),
                ],
                child: IgnorePointer(
                  child: PhobesModuleHeaderIconButton(
                    icon: Icons.sort_rounded,
                    onTap: () {},
                  ),
                ),
              ),
            ],
            onAdd: _navigateToEditor,
            addTooltip: 'Yeni Not',
            tabController: widget.teamFilterId == null ? _tabController : null,
            tabs: widget.teamFilterId == null ? _tabKeys.asMap().entries.map((e) {
              return PhobesModuleTab(_getTabName(e.value, l10n), _tabIcons[e.key]);
            }).toList() : null,
        ),
      ],
      body: Builder(
        builder: (context) => ModuleNestedScroll.scrollView(
          context: context,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  if (widget.teamFilterId != null) const SizedBox(height: 16),
                  _buildSearchBar(cs, isDark, l10n),
                  if (_currentTab != 4 && _currentTab != 5)
                    _buildCategoryChips(cs, isDark, l10n),
                ],
              ),
            ),
            SliverFillRemaining(
              child: _buildNotesList(cs, isDark, l10n, isCompact),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmbeddedContent(ColorScheme cs, bool isDark, AppLocalizations? l10n, bool isCompact) {
    return Column(
      children: [
        _buildSearchBar(cs, isDark, l10n),
        if (_currentTab != 4 && _currentTab != 5) _buildCategoryChips(cs, isDark, l10n),
        Expanded(child: _buildNotesList(cs, isDark, l10n, isCompact)),
      ],
    );
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return PhobesModuleHeaderIconButton(icon: icon, onTap: onTap);
  }

  Widget _buildSearchBar(ColorScheme cs, bool isDark, AppLocalizations? l10n) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: _isSearching
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) {
                  _searchDebounce?.cancel();
                  _searchDebounce =
                      Timer(const Duration(milliseconds: 300), () {
                    if (mounted) setState(() => _searchQuery = v);
                  });
                },
                style: GoogleFonts.outfit(fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n?.noteSearchHint ?? 'Search notes...',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 14,
                    color: cs.onSurface.withOpacity(0.3),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: cs.onSurface.withOpacity(0.4),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? cs.surfaceVariant.withOpacity(0.3)
                      : cs.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildCategoryChips(
      ColorScheme cs, bool isDark, AppLocalizations? l10n) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final (key, icon, colorVal) = _categories[i];
          final selected = _selectedCategory == key;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                  horizontal: selected ? 14 : 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? Color(colorVal).withOpacity(isDark ? 0.15 : 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? Color(colorVal).withOpacity(0.4)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: selected
                        ? Color(colorVal)
                        : cs.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getCategoryName(key, l10n),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? Color(colorVal)
                          : cs.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotesList(
      ColorScheme cs, bool isDark, AppLocalizations? l10n, bool isCompact) {
    return StreamBuilder<List<Note>>(
      stream: _getStream(),
      builder: (context, snapshot) {
        // Show loading only on first load (no cached data yet)
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: PhobesLoadingIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.notesLoadFailed ?? 'Notes could not be loaded',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          );
        }

        List<Note> notes = snapshot.data ?? [];

        if (widget.teamFilterId == null) {
          switch (_tabKeys[_currentTab]) {
            case 'all':
              notes = notes.where((n) => !n.isArchived).toList();
              break;
            case 'team':
              notes = notes
                  .where((n) => n.teamId != null && !n.isArchived)
                  .toList();
              break;
            case 'project':
              notes = notes
                  .where((n) => n.projectId != null && !n.isArchived)
                  .toList();
              break;
            case 'favorites':
              notes =
                  notes.where((n) => n.isFavorite && !n.isArchived).toList();
              break;
            case 'archive':
              break;
            case 'trash':
              break;
          }
        }

        if (_selectedCategory != 'all' &&
            _currentTab != 4 &&
            _currentTab != 5) {
          notes = notes.where((n) => n.category == _selectedCategory).toList();
        }

        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          notes = notes
              .where(
                (n) =>
                    n.title.toLowerCase().contains(q) ||
                    n.content.toLowerCase().contains(q) ||
                    n.tags.any((t) => t.toLowerCase().contains(q)),
              )
              .toList();
        }

        switch (_sortBy) {
          case 'title':
            notes.sort((a, b) => a.title.compareTo(b.title));
            break;
          case 'category':
            notes.sort((a, b) => a.category.compareTo(b.category));
            break;
          default:
            notes.sort((a, b) => b.date.compareTo(a.date));
        }

        final pinned = notes.where((n) => n.isPinned).toList();
        final unpinned = notes.where((n) => !n.isPinned).toList();

        if (notes.isEmpty) {
          return _buildEmptyState(cs, isDark, l10n);
        }

        final columns = PhobesResponsive.getGridColumns(context);

        if (_isGridView) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (pinned.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildHorizontalSection(
                    title: l10n?.notePin ?? 'Pinned',
                    icon: Icons.push_pin_rounded,
                    items: pinned,
                    cs: cs,
                    isDark: isDark,
                    l10n: l10n,
                  ),
                ),
              ],
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    _selectedNotebookId == null
                        ? (l10n?.noteAll ?? 'All Notes')
                        : (l10n?.noteNotebookNotes ?? 'Notebook Notes'),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns.clamp(1, 4),
                    childAspectRatio: isCompact ? 1.1 : 1.3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => FadeInUp(
                      duration: Duration(milliseconds: 200 + i * 50),
                      child: _buildNoteCard(
                          unpinned[i], cs, isDark, l10n, isCompact),
                    ),
                    childCount: unpinned.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        } else {
          final allNotes = [...pinned, ...unpinned];
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
            itemCount: allNotes.length,
            itemBuilder: (ctx, i) => FadeInUp(
              duration: Duration(milliseconds: 200 + i * 30),
              child: _buildNoteListTile(allNotes[i], cs, isDark, l10n),
            ),
          );
        }
      },
    );
  }

  Widget _buildHorizontalSection({
    required String title,
    required IconData icon,
    required List<Note> items,
    required ColorScheme cs,
    required bool isDark,
    required AppLocalizations? l10n,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) => SizedBox(
              width: 200,
              child: _buildNoteCard(items[i], cs, isDark, l10n, true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(Note note, ColorScheme cs, bool isDark,
      AppLocalizations? l10n, bool isCompact) {
    final dateStr = DateFormat.MMMd(Localizations.localeOf(context).toString())
        .format(note.date);

    return Hero(
      tag: 'note_${note.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openNote(note),
          onLongPress: () => _showNoteActions(note, cs, isDark, l10n),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDark ? cs.surfaceVariant : cs.surface,
              border: Border.all(color: Color(note.color).withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                    color: Color(note.color).withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (note.emoji.isNotEmpty)
                      Text(note.emoji, style: const TextStyle(fontSize: 22))
                    else
                      Icon(_getCategoryIcon(note.category),
                          size: 18, color: Color(note.color)),
                    if (note.isPinned)
                      Icon(Icons.push_pin_rounded, size: 14, color: cs.primary),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  note.title.isEmpty
                      ? (l10n?.untitledNote ?? 'Untitled')
                      : note.title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    note.preview,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.5),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      dateStr,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: cs.onSurface.withOpacity(0.3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (note.isFavorite)
                      Icon(Icons.star_rounded,
                          size: 13, color: Colors.amber.withOpacity(0.7)),
                    if (note.isShared)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.share_rounded,
                          size: 13,
                          color: cs.secondary.withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteListTile(
      Note note, ColorScheme cs, bool isDark, AppLocalizations? l10n) {
    final dateStr = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .add_Hm()
        .format(note.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openNote(note),
          onLongPress: () => _showNoteActions(note, cs, isDark, l10n),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceVariant : cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: cs.outline.withOpacity(isDark ? 0.12 : 0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(note.color),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                if (note.emoji.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child:
                        Text(note.emoji, style: const TextStyle(fontSize: 20)),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.title.isEmpty
                                  ? (l10n?.untitledNote ?? 'Untitled')
                                  : note.title,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (note.isPinned)
                            Icon(Icons.push_pin_rounded,
                                size: 13, color: cs.primary),
                          if (note.isShared)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(Icons.share_rounded,
                                  size: 13, color: cs.secondary),
                            ),
                          if (note.isFavorite)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.star_rounded,
                                  size: 13, color: Colors.amber),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color(note.color).withOpacity(isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(note.category),
                    size: 16,
                    color: Color(note.color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String key) {
    switch (key) {
      case 'work':
        return Icons.work_rounded;
      case 'personal':
        return Icons.person_rounded;
      case 'ideas':
        return Icons.lightbulb_rounded;
      case 'meeting':
        return Icons.groups_rounded;
      case 'research':
        return Icons.science_rounded;
      case 'study':
        return Icons.school_rounded;
      default:
        return Icons.note_rounded;
    }
  }

  Widget _buildEmptyState(ColorScheme cs, bool isDark, AppLocalizations? l10n) {
    return PhobesEmptyState(
      icon: Icons.note_alt_rounded,
      title: l10n?.noteEmptyState ?? 'Düşüncelerin Burada Canlanacak',
      description: l10n?.noteEmptyStateDesc ??
          'Henüz bir notun yok. Yeni sayfa açmak için + butonuna dokunun.',
      buttonText: l10n?.noteCreateFirst ?? 'Create Your First Note',
      buttonIcon: Icons.add_rounded,
      onButtonTap: _navigateToEditor,
    );
  }

  void _openNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteAddEditScreen(existingNote: note)),
    );
  }

  void _navigateToEditor({String? templateKey}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteAddEditScreen(
          teamId: widget.teamFilterId,
          templateKey: templateKey,
          notebookId: _selectedNotebookId,
        ),
      ),
    );
  }

  void _showNoteActions(
      Note note, ColorScheme cs, bool isDark, AppLocalizations? l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (note.deletedAt != null) ...[
              _actionTile(
                icon: Icons.restore_rounded,
                label: l10n?.noteRestore ?? 'Restore',
                color: Colors.teal,
                onTap: () {
                  Navigator.pop(ctx);
                  if (note.id != null) FirebaseService().restoreNote(note.id!);
                },
              ),
              _actionTile(
                icon: Icons.delete_forever_rounded,
                label: l10n?.noteDeletePermanent ?? 'Delete Permanently',
                color: cs.error,
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(note, l10n);
                },
              ),
              const SizedBox(height: 8),
            ] else ...[
              _actionTile(
                icon: note.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                label: note.isPinned
                    ? (l10n?.noteUnpin ?? 'Unpin')
                    : (l10n?.notePin ?? 'Pin'),
                color: cs.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  final updated = note.copyWith(isPinned: !note.isPinned);
                  FirebaseService().updateNote(updated);
                },
              ),
              _actionTile(
                icon: note.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                label: note.isFavorite
                    ? (l10n?.noteUnfavorite ?? 'Unfavorite')
                    : (l10n?.noteFavorite ?? 'Favorite'),
                color: Colors.amber,
                onTap: () {
                  Navigator.pop(ctx);
                  if (note.id != null) {
                    FirebaseService()
                        .toggleNoteFavorite(note.id!, !note.isFavorite);
                  }
                },
              ),
              _actionTile(
                icon: note.isLocked
                    ? Icons.lock_open_rounded
                    : Icons.lock_rounded,
                label: note.isLocked
                    ? (l10n?.noteUnlock ?? 'Unlock')
                    : (l10n?.noteLock ?? 'Lock'),
                color: Colors.deepOrange,
                onTap: () {
                  Navigator.pop(ctx);
                  if (note.id != null) {
                    FirebaseService().toggleNoteLock(note.id!, !note.isLocked);
                  }
                },
              ),
              _actionTile(
                icon: note.isArchived
                    ? Icons.unarchive_rounded
                    : Icons.archive_rounded,
                label: note.isArchived
                    ? (l10n?.noteUnarchive ?? 'Unarchive')
                    : (l10n?.noteArchiveAction ?? 'Archive'),
                color: Colors.teal,
                onTap: () {
                  Navigator.pop(ctx);
                  final id = note.id;
                  if (id == null) return;
                  if (note.isArchived) {
                    FirebaseService().unarchiveNote(id);
                  } else {
                    FirebaseService().archiveNote(id);
                  }
                },
              ),
              _actionTile(
                icon: Icons.edit_rounded,
                label: l10n?.edit ?? 'Edit',
                color: cs.secondary,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteAddEditScreen(existingNote: note),
                    ),
                  );
                },
              ),
              _actionTile(
                icon: Icons.copy_all_rounded,
                label: l10n?.noteDuplicate ?? 'Duplicate',
                color: cs.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  FirebaseService().duplicateNote(note);
                },
              ),
              _actionTile(
                icon: Icons.delete_rounded,
                label: l10n?.noteMoveToTrash ?? 'Move to Trash',
                color: cs.error,
                onTap: () {
                  Navigator.pop(ctx);
                  if (note.id != null) FirebaseService().moveToTrash(note.id!);
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(label,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: cs.onSurface.withOpacity(0.3),
      ),
      onTap: onTap,
    );
  }

  void _confirmDelete(Note note, AppLocalizations? l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n?.deleteNoteTitle ?? 'Delete Note',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(l10n?.deleteNoteWarning ?? 'Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (note.id != null) FirebaseService().deleteNote(note.id!);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
  }
}
