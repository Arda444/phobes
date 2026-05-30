import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/phobes_theme.dart';
import '../../l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/note_model.dart';
import '../../models/team_model.dart';
import '../../models/note_history_model.dart';
import '../../services/firebase_service.dart';
import 'table_embed.dart';
import 'callout_embed.dart';
import 'divider_embed.dart';
import 'note_toolbar.dart';
import 'slash_command_overlay.dart';
import 'note_templates.dart';
import 'note_link_tasks_sheet.dart';
import 'note_permission_sheet.dart';
import 'task_card_embed.dart';
import 'workflow_embed.dart';
import 'page_canvas.dart';
import 'page_settings_panel.dart';
import 'page_break_embed.dart';

class NoteAddEditScreen extends StatefulWidget {
  final Note? existingNote;
  final String? teamId;
  final String? projectId;
  final String? templateKey;
  final String? notebookId;

  const NoteAddEditScreen({
    super.key,
    this.existingNote,
    this.teamId,
    this.projectId,
    this.templateKey,
    this.notebookId,
  });

  @override
  State<NoteAddEditScreen> createState() => _NoteAddEditScreenState();
}

class _NoteAddEditScreenState extends State<NoteAddEditScreen> {
  // Multi-page support: each element is one page
  final List<QuillController> _pageControllers = [];
  final List<FocusNode> _pageFocusNodes = [];
  final List<ScrollController> _pageScrollControllers = [];
  int _activePageIndex = 0;

  // Safe getters — guarded against empty list during hot-reload / early frames
  QuillController get _quillController {
    if (_pageControllers.isEmpty) return QuillController.basic();
    final idx = _activePageIndex.clamp(0, _pageControllers.length - 1);
    return _pageControllers[idx];
  }

  FocusNode get _editorFocus {
    if (_pageFocusNodes.isEmpty) return FocusNode();
    final idx = _activePageIndex.clamp(0, _pageFocusNodes.length - 1);
    return _pageFocusNodes[idx];
  }

  late TextEditingController _titleController;
  final FocusNode _titleFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final LayerLink _slashLayerLink = LayerLink();
  final TextEditingController _tagController = TextEditingController();

  String _category = 'general';
  int _color = 0xFF6C63FF;
  bool _isPinned = false;
  bool _isFavorite = false;
  String _emoji = '';
  String _viewPermission = 'owner';
  String _editPermission = 'owner';
  List<String> _allowedUserIds = [];
  List<String> _linkedTaskIds = [];
  List<String> _tags = [];
  String? _teamId;
  String? _projectId;
  String? _notebookId;
  List<String> _headerStyles = ['modern'];
  List<String> _headerElements = ['main_title', 'meta_info'];

  String _pageSize = 'a4';
  String _pageOrientation = 'portrait';
  PageMargins _pageMargins = PageMargins.normal();

  bool _saving = false;
  final ValueNotifier<bool> _hasUnsavedChanges = ValueNotifier(false);
  Timer? _autoSaveTimer;
  Timer? _debounceTimer;
  String? _createdNoteId;
  DateTime? _lastHistoryAt;

  OverlayEntry? _slashOverlay;
  int _slashOffset = -1;
  String _prevText = '';
  String? _saveError;

  bool get _isEditing => widget.existingNote != null;

  static const _categories = [
    ('general', Icons.note_rounded, 0xFF6C63FF),
    ('work', Icons.work_rounded, 0xFF4285F4),
    ('personal', Icons.person_rounded, 0xFFFF6B6B),
    ('ideas', Icons.lightbulb_rounded, 0xFFFFB800),
    ('meeting', Icons.groups_rounded, 0xFF00BFA5),
    ('research', Icons.science_rounded, 0xFF9C27B0),
    ('study', Icons.school_rounded, 0xFFFF7043),
  ];

  static const _colorPalette = [
    0xFF6C63FF,
    0xFF4285F4,
    0xFFFF6B6B,
    0xFFFFB800,
    0xFF00BFA5,
    0xFF9C27B0,
    0xFFFF7043,
    0xFF607D8B,
    0xFFE91E63,
    0xFF3F51B5,
    0xFF009688,
    0xFF795548,
  ];

  String _getCatName(String k, AppLocalizations? l) {
    switch (k) {
      case 'general':
        return l?.noteCatGeneral ?? 'General';
      case 'work':
        return l?.noteCatWork ?? 'Work';
      case 'personal':
        return l?.noteCatPersonal ?? 'Personal';
      case 'ideas':
        return l?.noteCatIdeas ?? 'Ideas';
      case 'meeting':
        return l?.noteCatMeeting ?? 'Meeting';
      case 'research':
        return l?.noteCatResearch ?? 'Research';
      case 'study':
        return l?.noteCatStudy ?? 'Study';
      default:
        return k;
    }
  }

  /// Creates a QuillController + FocusNode + ScrollController for a new page.
  void _addPageFromDoc(Document doc) {
    final idx = _pageControllers.length;

    final ctrl = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: widget.existingNote?.isLocked ?? false,
    );

    final fn = FocusNode();
    fn.addListener(() {
      if (fn.hasFocus && mounted && _activePageIndex != idx) {
        setState(() {
          _activePageIndex = idx;
          _prevText = _pageControllers[idx].document.toPlainText();
        });
        _dismissSlash();
      }
    });

    // Add to lists BEFORE registering the listener so the getter is safe if
    // the controller fires synchronously.
    _pageControllers.add(ctrl);
    _pageFocusNodes.add(fn);
    _pageScrollControllers.add(ScrollController());

    ctrl.addListener(_onChange);
  }

  /// Parses saved content into one or more Documents (supports old single-page
  /// and new multi-page JSON formats).
  static List<Document> _parseContent(String? content) {
    if (content == null || content.isEmpty) return [Document()];
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        if (decoded.isEmpty) return [Document()];
        // Multi-page: outer list elements are themselves lists (page op arrays)
        if (decoded.first is List) {
          return decoded
              .map<Document>((ops) => Document.fromJson(ops as List))
              .toList();
        }
        // Single-page ops list (legacy format)
        return [Document.fromJson(decoded)];
      }
    } catch (_) {
      // fallback: treat content as plain text on a single page
    }
    return [Document()..insert(0, content)];
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _teamId = widget.teamId;
    _projectId = widget.projectId;

    if (_isEditing) {
      final n = widget.existingNote!;
      _titleController.text = n.title;
      _tags = List.from(n.tags);
      _category = n.category;
      _color = n.color;
      _isPinned = n.isPinned;
      _isFavorite = n.isFavorite;
      _emoji = n.emoji;
      _viewPermission = n.viewPermission;
      _editPermission = n.editPermission;
      _allowedUserIds = List.from(n.allowedUserIds);
      _linkedTaskIds = List.from(n.linkedTaskIds);
      _teamId = n.teamId ?? widget.teamId;
      _projectId = n.projectId ?? widget.projectId;
      _notebookId = n.notebookId ?? widget.notebookId;
      _headerStyles = List.from(n.headerStyles);
      _headerElements = List.from(n.headerElements);
      _pageSize = n.pageSize;
      _pageOrientation = n.pageOrientation;
      _pageMargins = n.pageMargins;

      for (final doc in _parseContent(n.content)) {
        _addPageFromDoc(doc);
      }
    } else {
      Document doc;
      if (widget.templateKey != null) {
        final t = noteTemplates.firstWhere(
          (t) => t.key == widget.templateKey,
          orElse: () => noteTemplates.first,
        );
        doc = t.toDocument();
        _category = t.category;
        _color = t.color;
      } else {
        doc = Document();
      }
      _notebookId = widget.notebookId;
      _addPageFromDoc(doc);
    }

    _prevText = _quillController.document.toPlainText();

    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_hasUnsavedChanges.value) _saveNote(silent: true);
    });
  }

  void _onChange() {
    if (!_hasUnsavedChanges.value) {
      _hasUnsavedChanges.value = true;
    }
    _detectSlashCommand();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (_hasUnsavedChanges.value && mounted) _saveNote(silent: true);
    });
  }

  void _markDirty() {
    _hasUnsavedChanges.value = true;
  }

  @override
  void dispose() {
    _hasUnsavedChanges.dispose();
    _dismissSlash();
    for (final ctrl in _pageControllers) {
      ctrl.removeListener(_onChange);
      ctrl.dispose();
    }
    for (final fn in _pageFocusNodes) {
      fn.dispose();
    }
    for (final sc in _pageScrollControllers) {
      sc.dispose();
    }
    _titleController.dispose();
    _titleFocus.dispose();
    _scrollController.dispose();
    _tagController.dispose();
    _autoSaveTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _detectSlashCommand() {
    final text = _quillController.document.toPlainText();
    final cursor = _quillController.selection.baseOffset;

    if (text.length > _prevText.length && cursor > 0) {
      final newChar = text.substring(cursor - 1, cursor);
      if (newChar == '/' && _slashOverlay == null) {
        final lineStart = text.lastIndexOf('\n', cursor - 2) + 1;
        final lineContent = text.substring(lineStart, cursor - 1).trim();
        if (lineContent.isEmpty) {
          _showSlashOverlay(cursor - 1);
        }
      }
    }
    _prevText = text;
  }

  void _showSlashOverlay(int offset) {
    _slashOffset = offset;
    _slashOverlay = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 60,
        child: SlashCommandOverlay(
          controller: _quillController,
          layerLink: _slashLayerLink,
          slashOffset: _slashOffset,
          onDismiss: _dismissSlash,
          commands: buildSlashCommands(
            l10n: AppLocalizations.of(context)!,
            onInsertTable: _insertTable,
            onInsertCallout: _insertCallout,
            onInsertDivider: _insertDivider,
            onInsertTask: _insertTask,
            onInsertWorkflow: _insertWorkflow,
            onInsertTable2: _insertTable2,
            onInsertTable3: _insertTable3,
            onInsertPageBreak: _insertPageBreak,
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_slashOverlay!);
  }

  void _dismissSlash() {
    _slashOverlay?.remove();
    _slashOverlay = null;
    _slashOffset = -1;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;
    final l = AppLocalizations.of(context);
    final compact = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: isDark
          ? (isAmoled ? Colors.black : cs.surfaceContainerHighest)
          : cs.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            _header(cs, isDark, l),
            Expanded(
              child: CompositedTransformTarget(
                link: _slashLayerLink,
                child: ColoredBox(
                  color: _pageSize == 'free'
                      ? cs.surface
                      : (isDark ? cs.surfaceContainerHigh : cs.surface),
                  child: GestureDetector(
                    onTap: () {
                      if (mounted) _editorFocus.requestFocus();
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: _pageSize == 'free'
                          ? EdgeInsets.symmetric(
                              horizontal: compact ? 16 : 32, vertical: 16,)
                          : const EdgeInsets.symmetric(
                              vertical: 32, horizontal: 20,),
                      child: Column(
                        children: [
                          // First page (title + editor)
                          RepaintBoundary(
                            child: _buildPage(0, cs, isDark, l, compact),
                          ),

                          // Additional pages
                          for (int pi = 1;
                              pi < _pageControllers.length;
                              pi++) ...[
                            const SizedBox(height: 24),
                            RepaintBoundary(
                              child: _buildPage(pi, cs, isDark, l, compact),
                            ),
                          ],

                          if (_pageSize != 'free') ...[
                            const SizedBox(height: 16),
                            _addPageButton(cs),
                            const SizedBox(height: 32),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.existingNote?.isLocked ?? false)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: cs.errorContainer.withOpacity(0.6),
                child: Row(
                  children: [
                    Icon(Icons.lock_rounded,
                        size: 15, color: cs.onErrorContainer,),
                    const SizedBox(width: 8),
                    Text(
                      l?.noteLockedMessage ??
                          'This note is locked — editing disabled.',
                      style:
                          TextStyle(fontSize: 12, color: cs.onErrorContainer),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        if (widget.existingNote?.id != null) {
                          FirebaseService()
                              .toggleNoteLock(widget.existingNote!.id!, false);
                        }
                      },
                      child: Text(
                        l?.noteUnlock ?? 'Unlock',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onErrorContainer,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              NoteToolbar(
                controller: _quillController,
                isCompact: compact,
                onInsertTable: _insertTable,
                onInsertCallout: _insertCallout,
                onInsertDivider: _insertDivider,
                onInsertTask: _insertTask,
                onInsertWorkflow: _insertWorkflow,
              ),
            _statusBar(cs, isDark, l),
          ],
        ),
      ),
    );
  }

  Widget _header(ColorScheme cs, bool isDark, AppLocalizations? l) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? cs.surface.withOpacity(0.95) : cs.surface,
        border: Border(bottom: BorderSide(color: cs.outline.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: _handleBack,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ListenableBuilder(
              listenable: _titleController,
              builder: (_, __) => Text(
                _titleController.text.isEmpty
                    ? (l?.untitledNote ?? 'Untitled')
                    : _titleController.text,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _titleController.text.isEmpty
                      ? cs.onSurface.withOpacity(0.3)
                      : cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_pageSize != 'free')
            GestureDetector(
              onTap: _openPageSettings,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: cs.primary.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.article_outlined,
                        size: 12, color: cs.primary.withOpacity(0.7),),
                    const SizedBox(width: 4),
                    Text(
                      '${_pageSize.toUpperCase()} · ${_pageOrientation == 'portrait' ? '↕' : '↔'}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.primary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          ValueListenableBuilder<bool>(
            valueListenable: _hasUnsavedChanges,
            builder: (context, hasUnsaved, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _saving
                  ? SizedBox(
                      key: const ValueKey('saving'),
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  : Icon(
                      key: ValueKey(hasUnsaved ? 'unsaved' : 'saved'),
                      hasUnsaved
                          ? Icons.circle_outlined
                          : Icons.check_circle_rounded,
                      size: 16,
                      color: hasUnsaved
                          ? cs.onSurface.withOpacity(0.3)
                          : Colors.green.withOpacity(0.7),
                    ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, size: 20),
            onPressed: () => _showSettings(cs, isDark, l),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _statusBar(ColorScheme cs, bool isDark, AppLocalizations? l) {
    final allText =
        _pageControllers.map((c) => c.document.toPlainText().trim()).join(' ');
    final wordCount =
        allText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final charCount = allText.replaceAll(RegExp(r'\s'), '').length;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? cs.surface : cs.surfaceVariant.withOpacity(0.3),
        border: Border(top: BorderSide(color: cs.outline.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Icon(Icons.text_fields_rounded,
              size: 11, color: cs.onSurface.withOpacity(0.4),),
          const SizedBox(width: 4),
          Text(
            '$wordCount kelime · $charCount karakter',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: cs.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_saveError != null)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline_rounded, size: 11, color: cs.error),
              const SizedBox(width: 4),
              Text(
                'Kaydedilemedi',
                style: GoogleFonts.outfit(
                    fontSize: 11, color: cs.error, fontWeight: FontWeight.w600,),
              ),
            ],)
          else if (_saving)
            Text(
              'Kaydediliyor...',
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: cs.primary.withOpacity(0.6),
                  fontWeight: FontWeight.w500,),
            )
          else if (!_hasUnsavedChanges.value)
            Text(
              'Kaydedildi',
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.green.withOpacity(0.7),
                  fontWeight: FontWeight.w500,),
            ),
        ],
      ),
    );
  }

  DefaultStyles _quillStyles(ColorScheme cs, bool isDark) {
    const textColor = Color(0xFF1A1A1A);
    final mutedColor = const Color(0xFF1A1A1A).withOpacity(0.5);

    return DefaultStyles(
      h1: DefaultTextBlockStyle(
        GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1.3,),
        const VerticalSpacing(16, 8),
        const VerticalSpacing(0, 0),
        null,
      ),
      h2: DefaultTextBlockStyle(
        GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1.3,),
        const VerticalSpacing(14, 6),
        const VerticalSpacing(0, 0),
        null,
      ),
      h3: DefaultTextBlockStyle(
        GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
            height: 1.3,),
        const VerticalSpacing(12, 4),
        const VerticalSpacing(0, 0),
        null,
      ),
      paragraph: DefaultTextBlockStyle(
        GoogleFonts.outfit(fontSize: 15, color: textColor, height: 1.6),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      bold: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textColor),
      italic: GoogleFonts.outfit(fontStyle: FontStyle.italic, color: textColor),
      underline: GoogleFonts.outfit(
          decoration: TextDecoration.underline, color: textColor,),
      strikeThrough: GoogleFonts.outfit(
          decoration: TextDecoration.lineThrough, color: mutedColor,),
      lists: DefaultListBlockStyle(
        GoogleFonts.outfit(fontSize: 15, color: textColor, height: 1.6),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
        null,
      ),
      code: DefaultTextBlockStyle(
        TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: isDark ? const Color(0xFFCE9178) : const Color(0xFFFFB86C),),
        const VerticalSpacing(8, 8),
        const VerticalSpacing(0, 0),
        BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      quote: DefaultTextBlockStyle(
        GoogleFonts.outfit(
            fontSize: 15,
            color: textColor.withOpacity(0.6),
            fontStyle: FontStyle.italic,
            height: 1.5,),
        const VerticalSpacing(8, 8),
        const VerticalSpacing(0, 0),
        BoxDecoration(
          border: Border(
              left: BorderSide(color: cs.primary.withOpacity(0.4), width: 3),),
        ),
      ),
    );
  }

  Future<void> _insertTable() async {
    _dismissSlash();
    // 1. Capture the exact state BEFORE the dialog takes focus
    final doc = _quillController.document;
    final selection = _quillController.selection;
    int savedOffset = selection.baseOffset;

    // 2. Fallback if selection is invalid or at the absolute end
    if (savedOffset < 0) {
      savedOffset = doc.length > 0 ? doc.length - 1 : 0;
    }

    final data = await showInsertTableDialog(context);
    if (!mounted || data == null) return;

    // 3. Robust refocusing before modification (crucial for Web)
    _editorFocus.requestFocus();
    await Future.delayed(Duration.zero); // Let focus settle

    // 4. Re-verify the offset against the current document state
    final insertAt = savedOffset.clamp(0, doc.length);

    // 5. Perform the insertion
    doc.insert(insertAt, TableBlockEmbed.fromTableData(data));

    // 6. Restore focus and place cursor after the table
    _quillController.updateSelection(
        TextSelection.collapsed(offset: (insertAt + 1).clamp(0, doc.length)),
        ChangeSource.local,);

    _markDirty();
  }

  Future<void> _insertCallout() async {
    _dismissSlash();
    final savedOffset = (_quillController.selection.baseOffset)
        .clamp(0, _quillController.document.length - 1);
    final data = await showInsertCalloutDialog(context);
    if (!mounted) return;
    if (data != null) {
      _quillController.document
          .insert(savedOffset, CalloutBlockEmbed.fromData(data));
      _quillController.updateSelection(
          TextSelection.collapsed(offset: savedOffset + 1), ChangeSource.local,);
      _markDirty();
    }
  }

  void _insertDivider() {
    _dismissSlash();
    final idx = _quillController.selection.baseOffset;
    _quillController.document.insert(idx, const DividerBlockEmbed());
    _quillController.updateSelection(
        TextSelection.collapsed(offset: idx + 1), ChangeSource.local,);
    _markDirty();
  }

  Widget _buildPage(int index, ColorScheme cs, bool isDark, AppLocalizations? l,
      bool compact,) {
    final ctrl = _pageControllers[index];
    final fn = _pageFocusNodes[index];
    final isFirstPage = index == 0;

    return PageCanvas(
      pageSize: _pageSize,
      pageOrientation: _pageOrientation,
      margins: _pageMargins,
      isEditMode: true,
      child: GestureDetector(
        onTap: () {
          setState(() => _activePageIndex = index);
          fn.requestFocus();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            if (isFirstPage) ...[
              Row(
                children: [
                  if (_emoji.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => _showSettings(cs, isDark, l),
                      child: Text(_emoji,
                          style: TextStyle(fontSize: compact ? 28 : 34),),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      focusNode: _titleFocus,
                      style: TextStyle(
                        fontSize: compact ? 22 : 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                        height: 1.3,
                        fontFamily: 'Outfit',
                      ),
                      decoration: InputDecoration(
                        hintText: l?.untitledNote ?? 'Başlıksız Not',
                        hintStyle: TextStyle(
                          fontSize: compact ? 22 : 26,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A).withOpacity(0.35),
                          height: 1.3,
                          fontFamily: 'Outfit',
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        _markDirty();
                        _debounceTimer?.cancel();
                        _debounceTimer = Timer(const Duration(seconds: 2), () {
                          if (_hasUnsavedChanges.value && mounted) {
                            _saveNote(silent: true);
                          }
                        });
                      },
                      onSubmitted: (_) => fn.requestFocus(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: cs.outline.withOpacity(0.1), height: 1),
              const SizedBox(height: 12),
              if (!_isEditing && ctrl.document.length <= 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 12, color: cs.primary.withOpacity(0.3),),
                      const SizedBox(width: 4),
                      Text(AppLocalizations.of(context)!.noteSlashInsertHint,
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withOpacity(0.28),
                              fontFamily: 'Outfit',),),
                    ],
                  ),
                ),
            ] else ...[
              // Continuation page header
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(
                      'Sayfa ${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withOpacity(0.3),
                        fontFamily: 'Outfit',
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Divider(
                            color: cs.outline.withOpacity(0.08), height: 1,),),
                  ],
                ),
              ),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 200),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: const TextSelectionThemeData(
                    cursorColor: Color(0xFF1A1A1A),
                    selectionColor: Color(0x331A1A1A),
                    selectionHandleColor: Color(0xFF1A1A1A),
                  ),
                ),
                child: QuillEditor(
                  focusNode: fn,
                  scrollController: _pageScrollControllers[index],
                  configurations: QuillEditorConfigurations(
                    controller: ctrl,
                    placeholder: isFirstPage
                        ? (l?.writeYourNotes ?? 'Yazmaya başla...')
                        : '',
                    scrollable: false,
                    embedBuilders: [
                      TableEmbedBuilder(
                          onTableUpdated: (_) =>
                              _markDirty(),),
                      CalloutEmbedBuilder(),
                      DividerEmbedBuilder(),
                      TaskCardEmbedBuilder(),
                      WorkflowEmbedBuilder(),
                      PageBreakEmbedBuilder(),
                    ],
                    customStyles: _quillStyles(cs, isDark),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _addPageButton(ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _appendNewPage,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: cs.primary.withOpacity(0.2),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
          color: isDark
              ? cs.primary.withOpacity(0.06)
              : cs.primary.withOpacity(0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded,
                  size: 14, color: cs.primary.withOpacity(0.7),),
            ),
            const SizedBox(width: 8),
            Text(
              'Yeni Sayfa Ekle',
              style: TextStyle(
                fontSize: 12,
                color: cs.primary.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Adds a fresh A4 page (new QuillController) below the existing pages.
  void _appendNewPage() {
    _dismissSlash();
    _addPageFromDoc(Document());
    setState(() {
      _activePageIndex = _pageControllers.length - 1;
      _markDirty();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
      _pageFocusNodes.last.requestFocus();
    });
  }

  void _insertTable2() {
    _dismissSlash();
    final data = TableData.empty(3, 2);
    final idx = _quillController.selection.baseOffset;
    _quillController.document.insert(idx, TableBlockEmbed.fromTableData(data));
    _quillController.updateSelection(
        TextSelection.collapsed(offset: idx + 1), ChangeSource.local,);
    _markDirty();
  }

  void _insertTable3() {
    _dismissSlash();
    final data = TableData.empty(3, 3);
    final idx = _quillController.selection.baseOffset;
    _quillController.document.insert(idx, TableBlockEmbed.fromTableData(data));
    _quillController.updateSelection(
        TextSelection.collapsed(offset: idx + 1), ChangeSource.local,);
    _markDirty();
  }

  void _insertPageBreak() {
    _dismissSlash();
    final idx = _quillController.selection.baseOffset;
    _quillController.document.insert(idx, const PageBreakBlockEmbed());
    _quillController.updateSelection(
        TextSelection.collapsed(offset: idx + 1), ChangeSource.local,);
    _markDirty();
  }

  Future<void> _insertTask() async {
    _dismissSlash();
    final data = await showInsertTaskDialog(context);
    if (data != null) {
      final idx = _quillController.selection.baseOffset;
      _quillController.document.insert(idx, TaskCardBlockEmbed.fromData(data));
      _quillController.updateSelection(
          TextSelection.collapsed(offset: idx + 1), ChangeSource.local,);
      _markDirty();
    }
  }

  Future<void> _insertWorkflow() async {
    _dismissSlash();
    final data = WorkflowData(
      name: 'Yeni İş Akışı',
      steps: [
        WorkflowStep(title: 'Hazırlık'),
        WorkflowStep(title: 'Uygulama'),
        WorkflowStep(title: 'Bitiş'),
      ],
    );
    final idx = _quillController.selection.baseOffset;
    _quillController.document.insert(idx, WorkflowBlockEmbed.fromData(data));
    _quillController.updateSelection(
        TextSelection.collapsed(offset: idx + 1), ChangeSource.local,);
    _markDirty();
  }

  void _showSettings(ColorScheme cs, bool isDark, AppLocalizations? l) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setBS) {
            return Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.55,
                minChildSize: 0.3,
                maxChildSize: 0.9,
                expand: false,
                builder: (_, sc) {
                  return ListView(
                    controller: sc,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 16),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.onSurface.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.article_outlined,
                            color: cs.primary, size: 20,),
                        title: Text(l?.notePageLayout ?? 'Page Layout',
                            style: GoogleFonts.outfit(
                                fontSize: 14, fontWeight: FontWeight.w600,),),
                        subtitle: Text(
                            '${_pageSize.toUpperCase()} · ${_pageOrientation == 'portrait' ? 'Dikey' : 'Yatay'}',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(0.5),),),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: cs.onSurface.withOpacity(0.3),),
                        onTap: () {
                          Navigator.pop(ctx);
                          _openPageSettings();
                        },
                      ),
                      const Divider(height: 8),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _sAction(
                            icon: _isPinned
                                ? Icons.push_pin_rounded
                                : Icons.push_pin_outlined,
                            label: _isPinned
                                ? (l?.noteUnpin ?? 'Unpin')
                                : (l?.notePin ?? 'Pin'),
                            active: _isPinned,
                            color: cs.primary,
                            cs: cs,
                            isDark: isDark,
                            onTap: () {
                              setState(() => _isPinned = !_isPinned);
                              setBS(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          _sAction(
                            icon: _isFavorite
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            label: l?.noteFavorite ?? 'Favorite',
                            active: _isFavorite,
                            color: Colors.amber,
                            cs: cs,
                            isDark: isDark,
                            onTap: () {
                              setState(() => _isFavorite = !_isFavorite);
                              setBS(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          _sAction(
                            icon: Icons.link_rounded,
                            label:
                                '${l?.noteLinkTask ?? 'Tasks'}${_linkedTaskIds.isNotEmpty ? ' (${_linkedTaskIds.length})' : ''}',
                            active: _linkedTaskIds.isNotEmpty,
                            color: cs.tertiary,
                            cs: cs,
                            isDark: isDark,
                            onTap: () {
                              Navigator.pop(ctx);
                              _showLinkTasks();
                            },
                          ),
                        ],
                      ),
                      if (_teamId != null) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          _sAction(
                            icon: Icons.shield_rounded,
                            label: l?.notePermissions ?? 'Permissions',
                            active: false,
                            color: cs.secondary,
                            cs: cs,
                            isDark: isDark,
                            onTap: () {
                              Navigator.pop(ctx);
                              _showPermissions();
                            },
                          ),
                        ],),
                      ],
                      const SizedBox(height: 20),
                      _label(l?.noteSortCategory ?? 'Category', cs),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((cat) {
                          final (key, icon, clr) = cat;
                          final sel = _category == key;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _category = key);
                              setBS(() {});
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8,),
                              decoration: BoxDecoration(
                                color: sel
                                    ? Color(clr)
                                        .withOpacity(isDark ? 0.2 : 0.12)
                                    : cs.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                                border: sel
                                    ? Border.all(
                                        color: Color(clr).withOpacity(0.4),)
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 16, color: Color(clr)),
                                  const SizedBox(width: 6),
                                  Text(_getCatName(key, l),
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: sel
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: sel
                                              ? Color(clr)
                                              : cs.onSurface.withOpacity(0.6),),),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      _label('Color', cs),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _colorPalette.map((c) {
                          final sel = _color == c;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _color = c);
                              setBS(() {});
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(c),
                                shape: BoxShape.circle,
                                border: sel
                                    ? Border.all(
                                        color: Colors.white, width: 2.5,)
                                    : null,
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                            color: Color(c).withOpacity(0.5),
                                            blurRadius: 8,),
                                      ]
                                    : null,
                              ),
                              child: sel
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 16,)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      _label('Emoji', cs),
                      const SizedBox(height: 8),
                      _emojiGrid(cs, isDark, setBS),
                      const SizedBox(height: 20),
                      _label('Tags', cs),
                      const SizedBox(height: 8),
                      _tagsSection(cs, isDark, l, setBS),
                      const SizedBox(height: 24),
                      _label(
                          'Ba\u015fl\u0131k Stilleri (\u00c7oklu Se\u00e7im)',
                          cs,),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['modern', 'integrated', 'official', 'fun']
                            .map((style) {
                          final sel = _headerStyles.contains(style);
                          return FilterChip(
                            label: Text(style.toUpperCase(),
                                style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: sel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: sel
                                        ? cs.primary
                                        : cs.onSurface.withOpacity(0.6),),),
                            selected: sel,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _headerStyles.add(style);
                                } else {
                                  _headerStyles.remove(style);
                                }
                                _markDirty();
                              });
                              setBS(() {});
                            },
                            selectedColor: cs.primary.withOpacity(0.15),
                            checkmarkColor: cs.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      _label('Ba\u015fl\u0131k Bile\u015fenleri', cs),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          (
                            'giant_title',
                            'B\u00fcy\u00fck Boy Ba\u015fl\u0131k'
                          ),
                          ('main_title', 'Ana Ba\u015fl\u0131k'),
                          ('subtitle', 'Alt Ba\u015fl\u0131k'),
                          ('meta_info', 'Meta Bilgiler'),
                        ].map((el) {
                          final sel = _headerElements.contains(el.$1);
                          return FilterChip(
                            label: Text(el.$2,
                                style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: sel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: sel
                                        ? cs.secondary
                                        : cs.onSurface.withOpacity(0.6),),),
                            selected: sel,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _headerElements.add(el.$1);
                                } else {
                                  _headerElements.remove(el.$1);
                                }
                                _markDirty();
                              });
                              setBS(() {});
                            },
                            selectedColor: cs.secondary.withOpacity(0.15),
                            checkmarkColor: cs.secondary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _sAction(
      {required IconData icon,
      required String label,
      required bool active,
      required Color color,
      required ColorScheme cs,
      required bool isDark,
      required VoidCallback onTap,}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? color.withOpacity(isDark ? 0.15 : 0.08)
                : cs.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: active ? Border.all(color: color.withOpacity(0.3)) : null,
          ),
          child: Column(children: [
            Icon(icon,
                size: 20,
                color: active ? color : cs.onSurface.withOpacity(0.4),),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? color : cs.onSurface.withOpacity(0.45),),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,),
          ],),
        ),
      ),
    );
  }

  Widget _label(String t, ColorScheme cs) => Text(t,
      style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: cs.onSurface.withOpacity(0.4),
          letterSpacing: 0.5,),);

  Widget _emojiGrid(ColorScheme cs, bool isDark, StateSetter setBS) {
    final emojis = [
      '',
      '\u{1F4CC}',
      '\u{1F4A1}',
      '\u{1F680}',
      '\u{1F4BC}',
      '\u{1F4DA}',
      '\u{1F3A8}',
      '\u{1F52C}',
      '\u{1F4CA}',
      '\u{1F4BB}',
      '\u2764',
      '\u2B50',
      '\u{1F525}',
      '\u{1F30D}',
      '\u2728',
      '\u{1F9E0}',
      '\u{1F4DD}',
      '\u{1F3AF}',
      '\u{1F4C5}',
      '\u{1F511}',
      '\u{1F4B0}',
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: emojis.map((e) {
        final sel = _emoji == e;
        return GestureDetector(
          onTap: () {
            setState(() => _emoji = e);
            setBS(() {});
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: sel
                  ? cs.primary.withOpacity(0.12)
                  : cs.surfaceVariant.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
              border:
                  sel ? Border.all(color: cs.primary.withOpacity(0.4)) : null,
            ),
            alignment: Alignment.center,
            child: e.isEmpty
                ? Icon(Icons.close_rounded,
                    size: 14, color: cs.onSurface.withOpacity(0.3),)
                : Text(e, style: const TextStyle(fontSize: 18)),
          ),
        );
      }).toList(),
    );
  }

  Widget _tagsSection(
      ColorScheme cs, bool isDark, AppLocalizations? l, StateSetter setBS,) {
    final tagCtrl = _tagController;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tags
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5,),
                      decoration: BoxDecoration(
                        color: Color(_color).withOpacity(isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('#$tag',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Color(_color),
                                fontWeight: FontWeight.w600,),),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() => _tags.remove(tag));
                            setBS(() {});
                          },
                          child: Icon(Icons.close_rounded,
                              size: 14, color: Color(_color),),
                        ),
                      ],),
                    ),)
                .toList(),
          ),
        if (_tags.isNotEmpty) const SizedBox(height: 8),
        TextField(
          controller: tagCtrl,
          style: GoogleFonts.outfit(fontSize: 13),
          decoration: InputDecoration(
            hintText: l?.tagsHint ?? 'Add tag...',
            hintStyle: GoogleFonts.outfit(
                fontSize: 13, color: cs.onSurface.withOpacity(0.25),),
            prefixIcon: Icon(Icons.tag_rounded,
                size: 16, color: cs.onSurface.withOpacity(0.3),),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            filled: true,
            fillColor: cs.surfaceVariant.withOpacity(0.2),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            isDense: true,
          ),
          onSubmitted: (v) {
            final t = v.trim();
            if (t.isNotEmpty && !_tags.contains(t)) {
              setState(() => _tags.add(t));
              setBS(() {});
            }
            tagCtrl.clear();
          },
        ),
      ],
    );
  }

  void _openPageSettings() {
    PageSettingsPanel.show(
      context,
      pageSize: _pageSize,
      pageOrientation: _pageOrientation,
      pageMargins: _pageMargins,
      onChanged: (size, orientation, margins) {
        setState(() {
          _pageSize = size;
          _pageOrientation = orientation;
          _pageMargins = margins;
          _markDirty();
        });
      },
    );
  }

  Future<void> _showLinkTasks() async {
    // For new notes without an ID yet, save first to obtain a Firestore document ID
    if (widget.existingNote?.id == null && _createdNoteId == null) {
      await _saveNote(silent: true);
    }
    final noteId = widget.existingNote?.id ?? _createdNoteId ?? '';
    if (noteId.isEmpty || !mounted) return;
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          NoteLinkTasksSheet(noteId: noteId, linkedTaskIds: _linkedTaskIds),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _linkedTaskIds = result;
        _markDirty();
      });
    }
  }

  Future<void> _showPermissions() async {
    Team? team;
    if (_teamId != null) {
      final doc =
          await FirebaseFirestore.instance.collection('teams').doc(_teamId).get();
      if (doc.exists) {
        team = Team.fromFirestore(doc);
      }
    }
    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotePermissionSheet(
        noteId: widget.existingNote?.id ?? _createdNoteId ?? '',
        currentViewPerm: _viewPermission,
        currentEditPerm: _editPermission,
        currentAllowedUsers: _allowedUserIds,
        team: team,
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _viewPermission = result['viewPerm'] as String;
      _editPermission = result['editPerm'] as String;
      _allowedUserIds = List<String>.from(result['allowedUsers'] as List);
      _markDirty();
    });
  }

  Future<void> _handleBack() async {
    if (_hasUnsavedChanges.value) {
      await _saveNote(silent: true, writeHistory: true);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveNote(
      {bool silent = false, bool writeHistory = false,}) async {
    if (_saving) return;
    if (mounted) setState(() => _saving = true);

    try {
      // ── Auth guard ────────────────────────────────────────────────────────
      final currentUid = FirebaseService().currentUserId;
      if (currentUid == null) {
        throw Exception('Oturumunuz sonlanmış. Lütfen yeniden giriş yapın.');
      }

      final title = _titleController.text.trim();
      // Serialize all pages; single-page notes use legacy flat format for compatibility
      final allDeltas =
          _pageControllers.map((c) => c.document.toDelta().toJson()).toList();
      final content = allDeltas.length == 1
          ? jsonEncode(allDeltas.first)
          : jsonEncode(allDeltas);
      final l = AppLocalizations.of(context);

      final effectiveId = widget.existingNote?.id ?? _createdNoteId;
      final ownerId = widget.existingNote?.userId ?? currentUid;
      final note = Note(
        id: effectiveId,
        userId: ownerId,
        title: title.isEmpty ? (l?.untitledNote ?? 'Untitled Note') : title,
        date: widget.existingNote?.date ?? DateTime.now(),
        content: content,
        category: _category,
        color: _color,
        isPinned: _isPinned,
        isFavorite: _isFavorite,
        emoji: _emoji,
        tags: _tags,
        teamId: _teamId,
        projectId: _projectId,
        notebookId: _notebookId,
        linkedTaskIds: _linkedTaskIds,
        viewPermission: _viewPermission,
        editPermission: _editPermission,
        allowedUserIds: _allowedUserIds,
        lastEditedBy: currentUid,
        headerStyles: _headerStyles,
        headerElements: _headerElements,
        pageSize: _pageSize,
        pageOrientation: _pageOrientation,
        pageMargins: _pageMargins,
      );

      if (_isEditing || _createdNoteId != null) {
        // ── Update existing note ────────────────────────────────────────────
        if (effectiveId == null) {
          // This should never happen; throw so the catch block shows an error.
          throw StateError('Düzenleme modunda not ID bulunamadı.');
        }
        await FirebaseService().updateNote(note);

        final shouldWriteHistory = writeHistory ||
            _lastHistoryAt == null ||
            DateTime.now().difference(_lastHistoryAt!) >=
                const Duration(minutes: 10);
        if (shouldWriteHistory) {
          try {
            final user = FirebaseService().currentUser;
            await FirebaseService().saveNoteVersion(
              effectiveId,
              NoteHistory(
                editorId: user?.uid ?? currentUid,
                editorName: user?.displayName ?? 'Düzenleyici',
                contentSnapshot: content,
                timestamp: DateTime.now(),
                editSummary: 'Düzenlendi',
              ),
            );
            _lastHistoryAt = DateTime.now();
          } catch (e) {
            // History save is non-fatal; log but don't surface to user.
            debugPrint('[_saveNote] saveNoteVersion error (non-fatal): $e');
          }
        }
      } else {
        // ── Create new note ─────────────────────────────────────────────────
        final newId = await FirebaseService().addNote(note);
        if (newId == null) {
          throw Exception('Not oluşturulamadı. Lütfen tekrar deneyin.');
        }
        if (mounted) {
          setState(() => _createdNoteId = newId);
        }
      }

      if (mounted) {
        setState(() {
          _hasUnsavedChanges.value = false;
          _saveError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saveError = 'Kaydedilemedi: $e');
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.errorNoteSave(e.toString()) ??
                    'Kaydetme hatası: $e',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      // ── Always reset the saving flag — even on early return or exception ──
      if (mounted) setState(() => _saving = false);
    }
  }
}
