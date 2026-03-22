import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../models/note_model.dart';
import '../../services/firebase_service.dart';
import '../../core/phobes_theme.dart';
import '../../services/nova_service.dart';
import '../../widgets/phobes_widgets.dart';

class NoteAddEditScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Note? note;
  final String? preselectedCategory;
  final String? preselectedProjectId;
  final String? preselectedTeamId;
  final List<String>? preselectedTags;

  const NoteAddEditScreen({
    super.key,
    required this.selectedDate,
    this.note,
    this.preselectedCategory,
    this.preselectedProjectId,
    this.preselectedTeamId,
    this.preselectedTags,
  });

  @override
  State<NoteAddEditScreen> createState() => _NoteAddEditScreenState();
}

class _NoteAddEditScreenState extends State<NoteAddEditScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _tagsCtrl;
  late quill.QuillController _contentCtrl;
  final FirebaseService _fb = FirebaseService();
  final NovaService _novaService = NovaService();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  bool _isSaving = false;
  bool _isFocusMode = false;
  bool _hasUnsavedChanges = false;
  bool _showToolbar = true;
  late String _category;
  late int _color;
  late bool _isPinned;
  String? _projectId;
  String? _teamId;

  int _wordCount = 0;
  int _charCount = 0;

  Timer? _autoSaveTimer;
  DateTime? _lastSaved;

  String _emoji = '';

  late AnimationController _focusModeController;

  final List<String> _categories = [
    'Genel',
    'Ekip Notları',
    'İş',
    'Kişisel',
    'Fikir',
    'Toplantı',
    'Araştırma',
  ];

  final List<int> _noteColors = [
    0xFF6C63FF,
    0xFF4285F4,
    0xFF00BCD4,
    0xFFFF6B6B,
    0xFF2ECC71,
    0xFFFFA726,
    0xFFE91E63,
    0xFF9C27B0,
  ];

  final List<String> _emojis = [
    '',
    '📝',
    '💡',
    '🎯',
    '🔥',
    '⭐',
    '📚',
    '💼',
    '🧠',
    '🎨',
    '🚀',
    '🌟',
    '📌',
    '✅',
    '❤️',
    '🏠',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');

    String initialTags = widget.note?.tags.join(', ') ?? '';
    if (widget.note == null && widget.preselectedTags != null) {
      initialTags = widget.preselectedTags!.join(', ');
    }
    _tagsCtrl = TextEditingController(text: initialTags);

    _category = widget.note?.category ?? widget.preselectedCategory ?? 'Genel';
    _color = widget.note?.color ?? 0xFF6C63FF;
    _isPinned = widget.note?.isPinned ?? false;
    _projectId = widget.note?.projectId ?? widget.preselectedProjectId;
    _teamId = widget.note?.teamId ?? widget.preselectedTeamId;
    _loadContent();
    _updateStats();

    _focusModeController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);

    _titleCtrl.addListener(_onContentChanged);
    _contentCtrl.document.changes.listen((_) {
      _onContentChanged();
      _updateStats();
    });
  }

  void _loadContent() {
    if (widget.note != null && widget.note!.content.isNotEmpty) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(widget.note!.content));
        _contentCtrl = quill.QuillController(
            document: doc, selection: const TextSelection.collapsed(offset: 0));
      } catch (e) {
        _contentCtrl = quill.QuillController.basic();
      }
    } else {
      _contentCtrl = quill.QuillController.basic();
    }
  }

  void _onContentChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 30), () {
      if (_hasUnsavedChanges && widget.note != null) {
        _saveNote(silent: true);
      }
    });
  }

  void _updateStats() {
    final text = _contentCtrl.document.toPlainText().trim();
    setState(() {
      _charCount = text.length;
      _wordCount = text.isEmpty
          ? 0
          : text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _tagsCtrl.dispose();
    _contentCtrl.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    _scrollCtrl.dispose();
    _autoSaveTimer?.cancel();
    _focusModeController.dispose();
    super.dispose();
  }

  void _toggleFocusMode() {
    setState(() {
      _isFocusMode = !_isFocusMode;
      if (_isFocusMode) {
        _focusModeController.forward();
        _contentFocus.requestFocus();
      } else {
        _focusModeController.reverse();
      }
    });
  }

  Future<void> _analyzeNoteWithNova() async {
    final text = _contentCtrl.document.toPlainText();
    if (text.trim().isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nova notlarını inceliyor... 🧠")));

    final tasks = await _novaService.extractTasksFromNote(text);
    if (!mounted) return;

    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Göreve dönüştürülecek bir şey bulamadım.")));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PhobesTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_fix_high,
                  color: Colors.tealAccent, size: 18),
            ),
            const SizedBox(width: 10),
            Text("${tasks.length} Görev Bulundu",
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tasks.length,
            itemBuilder: (c, i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.tealAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tasks[i].title,
                            style: GoogleFonts.outfit(
                                color: Colors.white, fontSize: 13)),
                        Text(
                          DateFormat('dd MMM HH:mm').format(tasks[i].startTime),
                          style: GoogleFonts.outfit(
                              color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("İptal",
                  style: GoogleFonts.outfit(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(ctx);
              for (var t in tasks) {
                await _fb.addTask(t);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Görevler takvimine eklendi! 🎉")));
              }
            },
            child: Text("Hepsini Ekle",
                style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote({bool silent = false}) async {
    if (_isSaving) return;
    if (!silent && !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final List<String> tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final note = Note(
      id: widget.note?.id,
      userId: widget.note?.userId ?? '',
      title: _titleCtrl.text.isEmpty ? 'Başlıksız' : _titleCtrl.text,
      content: jsonEncode(_contentCtrl.document.toDelta().toJson()),
      date: widget.selectedDate,
      category: _category,
      color: _color,
      isPinned: _isPinned,
      projectId: _projectId,
      teamId: _teamId,
      tags: tags,
    );

    try {
      if (widget.note == null) {
        await _fb.addNote(note);
      } else {
        await _fb.updateNote(note);
      }
      _hasUnsavedChanges = false;
      _lastSaved = DateTime.now();

      if (silent) {
        if (mounted) setState(() => _isSaving = false);
      } else {
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteNote() async {
    if (widget.note?.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PhobesTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Notu Sil',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Bu notu silmek istediğinize emin misiniz?',
            style: GoogleFonts.outfit(color: Colors.white70)),
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
    if (confirm == true) {
      await _fb.deleteNote(widget.note!.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteColor = Color(_color);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final save = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: PhobesTheme.surfaceColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Kaydedilmemiş Değişiklikler',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text('Değişiklikleri kaydetmek ister misiniz?',
                style: GoogleFonts.outfit(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Kaydetme',
                      style: GoogleFonts.outfit(color: Colors.redAccent))),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: PhobesTheme.kPrimaryColor),
                  child: Text('Kaydet',
                      style: GoogleFonts.outfit(color: Colors.white))),
            ],
          ),
        );
        if (!context.mounted) return;
        if (save == true) {
          await _saveNote();
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _isFocusMode ? null : _buildAppBar(isDark, noteColor),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_isFocusMode) _buildMetaBar(isDark, noteColor),
              AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.fromLTRB(_isFocusMode ? 32 : 24,
                    _isFocusMode ? 40 : 12, _isFocusMode ? 32 : 24, 4),
                child: Row(
                  children: [
                    if (!_isFocusMode)
                      GestureDetector(
                        onTap: () => _showEmojiPicker(isDark),
                        child: Container(
                          width: 38,
                          height: 38,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.06)),
                          ),
                          child: Center(
                            child: Text(
                              _emoji.isEmpty ? '😀' : _emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: TextFormField(
                        controller: _titleCtrl,
                        focusNode: _titleFocus,
                        style: GoogleFonts.outfit(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: _isFocusMode ? 30 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Başlık',
                          hintStyle: GoogleFonts.outfit(
                              color: isDark ? Colors.white12 : Colors.black12,
                              fontSize: _isFocusMode ? 30 : 24,
                              fontWeight: FontWeight.bold),
                          border: InputBorder.none,
                        ),
                        onFieldSubmitted: (_) => _contentFocus.requestFocus(),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: _isFocusMode ? 32 : 24),
                child: Row(
                  children: [
                    if (!_isFocusMode && _emoji.isEmpty)
                      const SizedBox(width: 48),
                    Icon(Icons.calendar_today_rounded,
                        size: 11,
                        color: isDark ? Colors.white24 : Colors.black26),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMMM yyyy', 'tr')
                          .format(widget.selectedDate),
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: isDark ? Colors.white24 : Colors.black26),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black12,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_wordCount kelime · $_charCount karakter',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: isDark ? Colors.white12 : Colors.black12),
                    ),
                    if (_lastSaved != null) ...[
                      const Spacer(),
                      Icon(Icons.cloud_done_rounded,
                          size: 12, color: Colors.green.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'Kaydedildi',
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.green.withValues(alpha: 0.5)),
                      ),
                    ],
                    if (_hasUnsavedChanges && _lastSaved == null) ...[
                      const Spacer(),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Kaydedilmedi',
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.orange.withValues(alpha: 0.6)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (!_isFocusMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Icon(Icons.sell_outlined,
                          size: 13,
                          color: isDark ? Colors.white24 : Colors.black26),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SizedBox(
                          height: 28,
                          child: TextField(
                            controller: _tagsCtrl,
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color:
                                    isDark ? Colors.white38 : Colors.black45),
                            decoration: InputDecoration(
                              hintText: 'Etiketler (virgülle ayır)',
                              hintStyle: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white12 : Colors.black12),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            onChanged: (_) => _onContentChanged(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: _isFocusMode ? 32 : 24, vertical: 8),
                child: Divider(
                    height: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.1)),
              ),
              if (_showToolbar && !_isFocusMode) _buildEditorToolbar(isDark),
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(
                    _isFocusMode ? 24 : 12,
                    0,
                    _isFocusMode ? 24 : 12,
                    12,
                  ),
                  decoration: !_isFocusMode
                      ? BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.1)),
                        )
                      : null,
                  padding: EdgeInsets.symmetric(
                    horizontal: _isFocusMode ? 8 : 20,
                    vertical: _isFocusMode ? 0 : 14,
                  ),
                  child: quill.QuillEditor.basic(
                    focusNode: _contentFocus,
                    configurations: quill.QuillEditorConfigurations(
                      controller: _contentCtrl,
                      placeholder: 'Yazmaya başla...',
                      sharedConfigurations:
                          const quill.QuillSharedConfigurations(
                              locale: Locale('tr')),
                    ),
                  ),
                ),
              ),
              if (_isFocusMode) _buildFocusModeBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color noteColor) {
    final cs = Theme.of(context).colorScheme;
    return PhobesPremiumAppBar(
      title: widget.note != null ? 'Düzenle' : 'Yeni Not',
      onBackPressed: () => Navigator.maybePop(context),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhobesIconButton(
            icon: _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            iconSize: 19,
            padding: 6,
            color: _isPinned
                ? Colors.amberAccent
                : cs.onSurface.withValues(alpha: 0.3),
            onTap: () => setState(() => _isPinned = !_isPinned),
          ),
          const SizedBox(width: 4),
          PhobesIconButton(
            icon: Icons.center_focus_strong_rounded,
            iconSize: 19,
            padding: 6,
            color: cs.onSurface.withValues(alpha: 0.3),
            onTap: _toggleFocusMode,
          ),
          const SizedBox(width: 4),
          PhobesIconButton(
            icon: Icons.auto_fix_high_rounded,
            iconSize: 19,
            padding: 6,
            color: Colors.tealAccent,
            onTap: _analyzeNoteWithNova,
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            position: PopupMenuPosition.under,
            icon: PhobesIconButton(
              icon: Icons.more_vert_rounded,
              iconSize: 19,
              padding: 6,
              onTap: () {},
            ),
            color: cs.surfaceContainerHigh,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) async {
              switch (value) {
                case 'save':
                  _saveNote();
                  break;
                case 'delete':
                  _deleteNote();
                  break;
                case 'share':
                  _shareNote();
                  break;
                case 'toggle_toolbar':
                  setState(() => _showToolbar = !_showToolbar);
                  break;
              }
            },
            itemBuilder: (_) => [
              _buildPopupItem('save', Icons.save_rounded, 'Kaydet',
                  PhobesTheme.kPrimaryColor, isDark),
              _buildPopupItem(
                  'toggle_toolbar',
                  _showToolbar
                      ? Icons.keyboard_hide_rounded
                      : Icons.keyboard_rounded,
                  _showToolbar ? 'Araç Çubuğunu Gizle' : 'Araç Çubuğunu Göster',
                  Colors.blueAccent,
                  isDark),
              _buildPopupItem(
                  'share', Icons.share_rounded, 'Paylaş', Colors.cyan, isDark),
              if (widget.note != null)
                _buildPopupItem('delete', Icons.delete_rounded, 'Sil',
                    Colors.redAccent, isDark),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
      String value, IconData icon, String label, Color color, bool isDark) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildMetaBar(bool isDark, Color noteColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showCategoryPicker(isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: noteColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: noteColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getCategoryIcon(_category), size: 12, color: noteColor),
                  const SizedBox(width: 5),
                  Text(_category,
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: noteColor)),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down, size: 14, color: noteColor),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 22,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: _noteColors.length,
              itemBuilder: (_, i) {
                final c = _noteColors[i];
                final isSelected = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: Color(c).withValues(alpha: 0.4),
                                  blurRadius: 6)
                            ]
                          : [],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 10, color: Colors.white)
                        : null,
                  ),
                );
              },
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _saveNote(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient:
                    _hasUnsavedChanges ? PhobesTheme.primaryGradient : null,
                color: _hasUnsavedChanges
                    ? null
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isSaving
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: Colors.white))
                      : Icon(Icons.check_rounded,
                          size: 14,
                          color: _hasUnsavedChanges
                              ? Colors.white
                              : (isDark ? Colors.white30 : Colors.black26)),
                  const SizedBox(width: 4),
                  Text('Kaydet',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _hasUnsavedChanges
                              ? Colors.white
                              : (isDark ? Colors.white30 : Colors.black26))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorToolbar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? PhobesTheme.surfaceColor.withValues(alpha: 0.5)
            : Colors.grey.shade100,
        border: Border(
          top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04)),
          bottom: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04)),
        ),
      ),
      child: quill.QuillToolbar.simple(
        configurations: quill.QuillSimpleToolbarConfigurations(
          controller: _contentCtrl,
          showFontFamily: false,
          showFontSize: false,
          showSearchButton: false,
          showInlineCode: true,
          showCodeBlock: true,
          showListCheck: true,
          showSubscript: false,
          showSuperscript: false,
          multiRowsDisplay: false,
          toolbarSize: 38,
          dialogTheme: quill.QuillDialogTheme(
            dialogBackgroundColor: PhobesTheme.surfaceColor,
            inputTextStyle: GoogleFonts.outfit(color: Colors.white),
            labelTextStyle: GoogleFonts.outfit(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusModeBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? PhobesTheme.surfaceColor.withValues(alpha: 0.6)
            : Colors.grey.shade50,
        border: Border(
            top: BorderSide(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Text('$_wordCount kelime',
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isDark ? Colors.white30 : Colors.black26)),
          const Spacer(),
          GestureDetector(
            onTap: _toggleFocusMode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: PhobesTheme.kPrimaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fullscreen_exit_rounded,
                      size: 16, color: PhobesTheme.kPrimaryColor),
                  const SizedBox(width: 6),
                  Text('Çık',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PhobesTheme.kPrimaryColor)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _saveNote(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: PhobesTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('Kaydet',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareNote() {
    final text = _contentCtrl.document.toPlainText().trim();
    final title = _titleCtrl.text.isEmpty ? 'Başlıksız' : _titleCtrl.text;
    Clipboard.setData(ClipboardData(text: '$title\n\n$text'));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not panoya kopyalandı 📋')));
  }

  void _showEmojiPicker(bool isDark) {
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
            Text('İkon Seç',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _emojis.map((e) {
                final isSelected = _emoji == e;
                return GestureDetector(
                  onTap: () {
                    setState(() => _emoji = e);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? PhobesTheme.kPrimaryColor.withValues(alpha: 0.2)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: PhobesTheme.kPrimaryColor
                                  .withValues(alpha: 0.5))
                          : Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Center(
                      child: e.isEmpty
                          ? Icon(Icons.block_rounded,
                              size: 18,
                              color: isDark ? Colors.white30 : Colors.black26)
                          : Text(e, style: const TextStyle(fontSize: 22)),
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

  void _showCategoryPicker(bool isDark) {
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
              children: _categories.map((cat) {
                final isSelected = _category == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() => _category = cat);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(_color).withValues(alpha: 0.2)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: Color(_color).withValues(alpha: 0.5))
                          : Border.all(
                              color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getCategoryIcon(cat),
                            size: 16,
                            color: isSelected
                                ? Color(_color)
                                : (isDark ? Colors.white54 : Colors.black54)),
                        const SizedBox(width: 8),
                        Text(cat,
                            style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Color(_color)
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
