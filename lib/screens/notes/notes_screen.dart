import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../models/note_model.dart';
import '../../services/firebase_service.dart';
import '../../core/phobes_theme.dart';
import '../../core/page_transitions.dart';
import '../../widgets/phobes_widgets.dart';
import 'note_add_edit_screen.dart';

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
  final FirebaseService _fb = FirebaseService();
  String _selectedCategory = 'Tümü';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;
  bool _isGridView = true;
  String _sortBy = 'date';
  late AnimationController _fabController;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tümü', 'icon': Icons.layers_rounded, 'color': 0xFF6C63FF},
    {
      'name': 'Ekip Notları',
      'icon': Icons.groups_3_rounded,
      'color': 0xFF009688
    },
    {'name': 'Genel', 'icon': Icons.note_rounded, 'color': 0xFF4285F4},
    {'name': 'İş', 'icon': Icons.work_rounded, 'color': 0xFFFF6B6B},
    {'name': 'Kişisel', 'icon': Icons.person_rounded, 'color': 0xFF2ECC71},
    {'name': 'Fikir', 'icon': Icons.lightbulb_rounded, 'color': 0xFFFFA726},
    {'name': 'Toplantı', 'icon': Icons.groups_rounded, 'color': 0xFF00BCD4},
    {'name': 'Araştırma', 'icon': Icons.science_rounded, 'color': 0xFF9C27B0},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEmbedded) {
      _selectedCategory = 'Tümü';
    }
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget bodyContent = Stack(
      children: [
        Column(
          children: [
            if (widget.isEmbedded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ekip Notları',
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface)),
                    Row(
                      children: [
                        PhobesIconButton(
                          icon: _isSearching
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          onTap: () => setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) {
                              _searchCtrl.clear();
                              _searchQuery = '';
                            }
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildSearchBar(cs),
            ],
            _buildToolbar(isDark),
            Expanded(child: _buildNotesList(isDark)),
          ],
        ),
        Positioned(
          bottom: widget.isEmbedded
              ? 16
              : 30, // Adjusted for being inside a Scaffold
          right: 20,
          child: _buildFAB(isDark, cs),
        ),
      ],
    );

    if (widget.isEmbedded) return bodyContent;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: PhobesPremiumAppBar(
        title: 'Notlarım',
        showBackButton: false,
        trailing: PhobesIconButton(
          icon: _isSearching ? Icons.close_rounded : Icons.search_rounded,
          onTap: () => setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _searchCtrl.clear();
              _searchQuery = '';
            }
          }),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              if (_isSearching)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded,
                            size: 18,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            autofocus: true,
                            style: GoogleFonts.outfit(
                                color: cs.onSurface, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Başlık, içerik veya etiket ara...',
                              hintStyle: GoogleFonts.outfit(
                                  color: cs.onSurface.withValues(alpha: 0.3),
                                  fontSize: 15),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            onChanged: (v) =>
                                setState(() => _searchQuery = v.toLowerCase()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              _buildCategoryBar(isDark),
            ],
          ),
        ),
      ),
      body: bodyContent,
    );
  }

  Widget _buildSearchBar(ColorScheme cs) {
    if (!_isSearching) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Başlık, içerik veya etiket ara...',
                  hintStyle: GoogleFonts.outfit(
                      color: cs.onSurface.withValues(alpha: 0.3), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
              ),
            ),
            if (widget.isEmbedded)
              GestureDetector(
                onTap: () => setState(() {
                  _isSearching = false;
                  _searchCtrl.clear();
                  _searchQuery = '';
                }),
                child: Icon(Icons.close_rounded,
                    size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar(bool isDark) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected = _selectedCategory == cat['name'];
          final catColor = Color(cat['color'] as int);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat['name']),
              child: AnimatedContainer(
                duration: PhobesTheme.animFast,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: [
                          catColor,
                          catColor.withValues(alpha: 0.7),
                        ])
                      : null,
                  color: isSelected
                      ? null
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isDark ? Colors.white10 : Colors.black12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: catColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat['icon'] as IconData,
                        size: 14,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white54 : Colors.black45)),
                    const SizedBox(width: 6),
                    Text(
                      cat['name'] as String,
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white54 : Colors.black54)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolbar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showSortOptions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort_rounded,
                      size: 14,
                      color: isDark ? Colors.white38 : Colors.black38),
                  const SizedBox(width: 4),
                  Text(
                    _sortBy == 'date'
                        ? 'Tarih'
                        : _sortBy == 'title'
                            ? 'İsim'
                            : 'Kategori',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildViewToggle(Icons.grid_view_rounded, true, isDark),
                _buildViewToggle(Icons.view_list_rounded, false, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(IconData icon, bool isGrid, bool isDark) {
    final isActive = _isGridView == isGrid;
    return GestureDetector(
      onTap: () => setState(() => _isGridView = isGrid),
      child: AnimatedContainer(
        duration: PhobesTheme.animFast,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive
              ? PhobesTheme.kPrimaryColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 16,
            color: isActive
                ? PhobesTheme.kPrimaryColor
                : (isDark ? Colors.white30 : Colors.black26)),
      ),
    );
  }

  Widget _buildNotesList(bool isDark) {
    return StreamBuilder<List<Note>>(
      stream: widget.teamFilterId != null
          ? _fb.getTeamNotesStream(widget.teamFilterId!)
          : _fb.getNotesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text("Hata: ${snapshot.error}",
                  style: GoogleFonts.outfit(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          final cs = Theme.of(context).colorScheme;
          return Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: cs.primary, strokeWidth: 2),
              const SizedBox(height: 12),
              Text('Notlar yükleniyor...',
                  style: GoogleFonts.outfit(
                      color: cs.onSurface.withValues(alpha: 0.3),
                      fontSize: 13)),
            ],
          ));
        }

        var notes = snapshot.data ?? [];

        if (widget.teamFilterId != null) {
          // Additional safety: ensure we only show notes belonging to this team
          notes = notes.where((n) => n.teamId == widget.teamFilterId).toList();
        }

        if (_selectedCategory != 'Tümü') {
          notes = notes.where((n) => n.category == _selectedCategory).toList();
        }
        if (_searchQuery.isNotEmpty) {
          notes = notes.where((n) {
            final titleMatch = n.title.toLowerCase().contains(_searchQuery);
            final tagMatch =
                n.tags.any((t) => t.toLowerCase().contains(_searchQuery));
            if (titleMatch || tagMatch) return true;

            try {
              // Only attempt parsing if it looks like JSON quill content
              if (n.content.startsWith('{')) {
                final doc = quill.Document.fromJson(jsonDecode(n.content));
                return doc.toPlainText().toLowerCase().contains(_searchQuery);
              }
              return n.content.toLowerCase().contains(_searchQuery);
            } catch (_) {
              return n.content.toLowerCase().contains(_searchQuery);
            }
          }).toList();
        }

        notes.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          switch (_sortBy) {
            case 'title':
              return a.title.compareTo(b.title);
            case 'category':
              return a.category.compareTo(b.category);
            default:
              return b.date.compareTo(a.date);
          }
        });

        if (notes.isEmpty) return _buildEmptyState(isDark);

        final pinned = notes.where((n) => n.isPinned).toList();
        final regular = notes.where((n) => !n.isPinned).toList();

        return CustomScrollView(
          slivers: [
            const SliverPadding(padding: EdgeInsets.fromLTRB(20, 8, 20, 80)),
            if (pinned.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 4),
                  child: Row(
                    children: [
                      Icon(Icons.push_pin_rounded,
                          size: 14,
                          color: isDark ? Colors.amberAccent : Colors.amber),
                      const SizedBox(width: 6),
                      Text('Sabitlenmiş',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.amberAccent
                                  : Colors.amber.shade700)),
                    ],
                  ),
                ),
              ),
              _isGridView
                  ? _buildGridSliver(pinned, isDark)
                  : _buildListSliver(pinned, isDark),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
            if (regular.isNotEmpty && pinned.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 4),
                  child: Text('Tüm Notlar',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white38 : Colors.black38)),
                ),
              ),
            _isGridView
                ? _buildGridSliver(regular, isDark)
                : _buildListSliver(regular, isDark),
          ],
        );
      },
    );
  }

  SliverGrid _buildGridSliver(List<Note> notes, bool isDark) {
    final width = MediaQuery.of(context).size.width;
    final cols = width > 900 ? 3 : (width > 500 ? 2 : 2);

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (_, i) => FadeInUp(
          delay: Duration(milliseconds: i * 40),
          duration: const Duration(milliseconds: 300),
          child: _buildGridCard(notes[i], isDark),
        ),
        childCount: notes.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
    );
  }

  Widget _buildGridCard(Note note, bool isDark) {
    final noteColor = Color(note.color);
    final plainText = _extractPlainText(note);
    final wordCount =
        plainText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    return GestureDetector(
      onTap: () => _openNote(note),
      onLongPress: () => _showNoteActions(note, isDark),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: note.isPinned
                  ? Colors.amberAccent.withValues(alpha: 0.3)
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: noteColor.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  noteColor,
                  noteColor.withValues(alpha: 0.4),
                ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: noteColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getCategoryIcon(note.category),
                                  size: 10, color: noteColor),
                              const SizedBox(width: 4),
                              Text(note.category,
                                  style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: noteColor)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (note.isPinned)
                          const Icon(Icons.push_pin,
                              size: 12, color: Colors.amberAccent),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      note.title.isEmpty ? 'Başlıksız' : note.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        plainText,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isDark ? Colors.white30 : Colors.black38,
                          height: 1.6,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 10,
                            color: isDark ? Colors.white24 : Colors.black26),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(note.date),
                          style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: isDark ? Colors.white24 : Colors.black26),
                        ),
                        const Spacer(),
                        Text(
                          '$wordCount kelime',
                          style: GoogleFonts.outfit(
                              fontSize: 9,
                              color: isDark ? Colors.white12 : Colors.black12),
                        ),
                      ],
                    ),
                    if (note.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: note.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.06)),
                            ),
                            child: Text('#$tag',
                                style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.black38)),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverList _buildListSliver(List<Note> notes, bool isDark) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => FadeInUp(
          delay: Duration(milliseconds: i * 40),
          duration: const Duration(milliseconds: 300),
          child: _buildListCard(notes[i], isDark),
        ),
        childCount: notes.length,
      ),
    );
  }

  Widget _buildListCard(Note note, bool isDark) {
    final noteColor = Color(note.color);
    final plainText = _extractPlainText(note);
    final wordCount =
        plainText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    return GestureDetector(
      onTap: () => _openNote(note),
      onLongPress: () => _showNoteActions(note, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: note.isPinned
                  ? Colors.amberAccent.withValues(alpha: 0.3)
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.1)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [noteColor, noteColor.withValues(alpha: 0.3)],
                  ),
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (note.isPinned) ...[
                            const Icon(Icons.push_pin,
                                size: 12, color: Colors.amberAccent),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              note.title.isEmpty ? 'Başlıksız' : note.title,
                              style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark ? Colors.white : Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: noteColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(note.category,
                                style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: noteColor)),
                          ),
                        ],
                      ),
                      if (plainText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(plainText,
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: isDark ? Colors.white30 : Colors.black38,
                                height: 1.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(_formatDate(note.date),
                              style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black26)),
                          const SizedBox(width: 12),
                          Text('$wordCount kelime',
                              style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black12)),
                          if (note.tags.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            ...note.tags.take(2).map((t) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Text('#$t',
                                      style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: noteColor.withValues(
                                              alpha: 0.6))),
                                )),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right_rounded,
                    size: 20, color: isDark ? Colors.white12 : Colors.black12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(bool isDark, ColorScheme cs) {
    return GestureDetector(
      onTap: () {
        List<String> tags = [];
        if (widget.teamFilterId != null) {
          tags.add(widget.teamFilterId!);
        }
        _openNote(
          null,
          prefillCategory: widget.isEmbedded ? 'Ekip Notları' : null,
          prefillTeamId: widget.teamFilterId,
          prefillTags: tags,
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child:
            const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: FadeInUp(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PhobesTheme.kPrimaryColor.withValues(alpha: 0.1),
                      Colors.teal.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.note_alt_outlined,
                    color: isDark ? Colors.white24 : Colors.black12, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Sonuç bulunamadı'
                    : _selectedCategory == 'Tümü'
                        ? 'Henüz not yok'
                        : '$_selectedCategory kategorisinde not yok',
                style: GoogleFonts.outfit(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 17,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Başka bir terimle aramayı deneyin'
                    : 'İlk notunuzu oluşturmak için + butonuna dokunun',
                style: GoogleFonts.outfit(
                    color: isDark ? Colors.white24 : Colors.black26,
                    fontSize: 13),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isEmpty) ...[
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => _openNote(null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: PhobesTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: PhobesTheme.kPrimaryColor
                                .withValues(alpha: 0.3),
                            blurRadius: 12)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('İlk Notu Oluştur',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openNote(Note? note,
      {String? prefillCategory,
      String? prefillTeamId,
      List<String>? prefillTags}) {
    PhobesPageRoute.pushResponsive(
      context,
      NoteAddEditScreen(
        selectedDate: note?.date ?? DateTime.now(),
        note: note,
        preselectedCategory: note?.category ??
            prefillCategory ??
            (_selectedCategory == 'Tümü' ? 'Genel' : _selectedCategory),
        preselectedTeamId: prefillTeamId,
        preselectedTags: prefillTags,
      ),
    );
  }

  void _showNoteActions(Note note, bool isDark) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? PhobesTheme.surfaceColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(note.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    note.title.isEmpty ? 'Başlıksız' : note.title,
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildActionItem(
              icon: note.isPinned
                  ? Icons.push_pin_outlined
                  : Icons.push_pin_rounded,
              label: note.isPinned ? 'Sabitlemeyi Kaldır' : 'Sabitle',
              color: Colors.amberAccent,
              isDark: isDark,
              onTap: () async {
                Navigator.pop(ctx);
                final updated = note.copyWith(isPinned: !note.isPinned);
                await _fb.updateNote(updated);
              },
            ),
            _buildActionItem(
              icon: Icons.edit_rounded,
              label: 'Düzenle',
              color: PhobesTheme.kPrimaryColor,
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);
                _openNote(note);
              },
            ),
            _buildActionItem(
              icon: Icons.copy_rounded,
              label: 'Kopyala',
              color: Colors.cyanAccent,
              isDark: isDark,
              onTap: () async {
                Navigator.pop(ctx);
                final duplicate = Note(
                  userId: note.userId,
                  title: '${note.title} (kopya)',
                  date: DateTime.now(),
                  content: note.content,
                  category: note.category,
                  color: note.color,
                  tags: note.tags,
                );
                await _fb.addNote(duplicate);
              },
            ),
            _buildActionItem(
              icon: Icons.category_rounded,
              label: 'Kategori Değiştir',
              color: Colors.orangeAccent,
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);
                _showChangeCategoryDialog(note, isDark);
              },
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildActionItem(
              icon: Icons.delete_rounded,
              label: 'Sil',
              color: Colors.redAccent,
              isDark: isDark,
              onTap: () async {
                Navigator.pop(ctx);
                _confirmDelete(note);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showChangeCategoryDialog(Note note, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? PhobesTheme.surfaceColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Kategori Seç',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.skip(1).map((cat) {
                final catName = cat['name'] as String;
                final catColor = Color(cat['color'] as int);
                final isSelected = note.category == catName;
                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    final updated = note.copyWith(category: catName);
                    await _fb.updateNote(updated);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? catColor.withValues(alpha: 0.2)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: catColor.withValues(alpha: 0.5))
                          : Border.all(
                              color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat['icon'] as IconData,
                            size: 16,
                            color: isSelected
                                ? catColor
                                : (isDark ? Colors.white54 : Colors.black54)),
                        const SizedBox(width: 8),
                        Text(catName,
                            style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? catColor
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black87))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PhobesTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Notu Sil',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '"${note.title.isEmpty ? 'Başlıksız' : note.title}" notunu silmek istediğinize emin misiniz?',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('İptal',
                  style: GoogleFonts.outfit(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text('Sil', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && note.id != null) {
      await _fb.deleteNote(note.id!);
    }
  }

  void _showSortOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? PhobesTheme.surfaceColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Sıralama',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 16),
            _buildSortOption(
                'Tarih', 'date', Icons.calendar_today_rounded, ctx, isDark),
            _buildSortOption(
                'İsim', 'title', Icons.sort_by_alpha_rounded, ctx, isDark),
            _buildSortOption(
                'Kategori', 'category', Icons.category_rounded, ctx, isDark),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon,
      BuildContext ctx, bool isDark) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(ctx);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? PhobesTheme.kPrimaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: PhobesTheme.kPrimaryColor.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isSelected
                    ? PhobesTheme.kPrimaryColor
                    : (isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? PhobesTheme.kPrimaryColor
                        : (isDark ? Colors.white : Colors.black87))),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_rounded,
                  size: 18, color: PhobesTheme.kPrimaryColor),
          ],
        ),
      ),
    );
  }

  String _extractPlainText(Note note) {
    try {
      final doc = quill.Document.fromJson(jsonDecode(note.content));
      return doc.toPlainText().trim();
    } catch (_) {
      return note.content;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Şimdi';
    if (diff.inHours < 1) return '${diff.inMinutes}dk önce';
    if (diff.inDays < 1) return '${diff.inHours}s önce';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays}g önce';
    return DateFormat('dd MMM', 'tr').format(date);
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'İş':
        return Icons.work_rounded;
      case 'Kişisel':
        return Icons.person_rounded;
      case 'Fikir':
        return Icons.lightbulb_rounded;
      case 'Toplantı':
        return Icons.groups_rounded;
      case 'Araştırma':
        return Icons.science_rounded;
      default:
        return Icons.note_rounded;
    }
  }
}
