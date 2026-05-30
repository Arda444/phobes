import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

/// Custom premium toolbar for the Phobes note editor.
/// Replaces QuillToolbar.simple with a responsive, two-layer design.
class NoteToolbar extends StatefulWidget {
  final QuillController controller;
  final VoidCallback onInsertTable;
  final VoidCallback onInsertCallout;
  final VoidCallback onInsertDivider;
  final VoidCallback? onInsertTask;
  final VoidCallback? onInsertWorkflow;
  final bool isCompact;

  const NoteToolbar({
    super.key,
    required this.controller,
    required this.onInsertTable,
    required this.onInsertCallout,
    required this.onInsertDivider,
    this.onInsertTask,
    this.onInsertWorkflow,
    this.isCompact = true,
  });

  @override
  State<NoteToolbar> createState() => _NoteToolbarState();
}

class _NoteToolbarState extends State<NoteToolbar> {
  bool _expanded = false;

  QuillController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_refresh);
  }

  @override
  void dispose() {
    _c.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool _isActive(Attribute attr) {
    final style = _c.getSelectionStyle();
    if (attr.key == Attribute.list.key) {
      return style.attributes[Attribute.list.key]?.value == attr.value;
    }
    if (attr.key == Attribute.header.key) {
      return style.attributes[Attribute.header.key]?.value == attr.value;
    }
    return style.attributes.containsKey(attr.key);
  }

  void _toggle(Attribute attr) {
    if (_isActive(attr)) {
      _c.formatSelection(Attribute.clone(attr, null));
    } else {
      _c.formatSelection(attr);
    }
  }

  void _toggleInline(Attribute attr) {
    _c.formatSelection(
      _isActive(attr) ? Attribute.clone(attr, null) : attr,
    );
  }

  int _currentHeader() {
    final v = _c.getSelectionStyle().attributes[Attribute.header.key]?.value;
    if (v is int) return v;
    return 0;
  }

  static const _clearColor = Color(0x00000001); // sentinel: remove color attribute

  static const _textColors = [
    Colors.black, Color(0xFF374151), Color(0xFF6B7280),
    Colors.red, Color(0xFFEA580C), Colors.amber,
    Color(0xFF16A34A), Color(0xFF0891B2), Colors.blue,
    Color(0xFF7C3AED), Color(0xFFDB2777), Colors.white,
  ];

  static const _highlightColors = [
    Color(0xFFFEF08A), Color(0xFFFED7AA), Color(0xFFFCA5A5),
    Color(0xFFBBF7D0), Color(0xFFBAE6FD), Color(0xFFDDD6FE),
    Color(0xFFFBCFE8), Color(0xFFE5E7EB),
  ];

  Color? _currentTextColor() {
    final hex = _c.getSelectionStyle().attributes['color']?.value as String?;
    if (hex == null) return null;
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return null;
    }
  }

  Color? _currentHighlightColor() {
    final hex = _c.getSelectionStyle().attributes['background']?.value as String?;
    if (hex == null) return null;
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return null;
    }
  }

  String _colorToHex(Color c) => '#${c.value.toRadixString(16).substring(2)}';

  Widget _colorToolBtn({
    required IconData icon,
    required String tooltip,
    required Color? active,
    required ColorScheme cs,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: active != null ? cs.primary.withOpacity(0.12) : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 17, color: cs.onSurface.withOpacity(0.55)),
              if (active != null)
                Positioned(
                  bottom: 5,
                  child: Container(
                    width: 14,
                    height: 3,
                    decoration: BoxDecoration(
                      color: active,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickColor(ColorScheme cs, {required bool isHighlight}) async {
    final colors = isHighlight ? _highlightColors : _textColors;
    final selected = await showDialog<Color>(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: cs.surface,
          title: Text(
            isHighlight ? 'Vurgulama Rengi' : 'Metin Rengi',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.pop(ctx, _clearColor),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.outline.withOpacity(0.4)),
                  ),
                  child: Icon(Icons.format_clear_rounded,
                      size: 18, color: cs.onSurface.withOpacity(0.5),),
                ),
              ),
              ...colors.map((c) => InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.pop(ctx, c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c,
                    border: Border.all(color: cs.outline.withOpacity(0.25)),
                  ),
                ),
              ),),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(ctx)!.cancel),
            ),
          ],
        );
      },
    );

    if (!mounted || selected == null) return;
    if (selected == _clearColor) {
      if (isHighlight) {
        _c.formatSelection(Attribute.clone(const BackgroundAttribute(''), null));
      } else {
        _c.formatSelection(Attribute.clone(const ColorAttribute(''), null));
      }
    } else {
      if (isHighlight) {
        _c.formatSelection(BackgroundAttribute(_colorToHex(selected)));
      } else {
        _c.formatSelection(ColorAttribute(_colorToHex(selected)));
      }
    }
  }

  Widget _colorPickerBtn(ColorScheme cs) {
    return _colorToolBtn(
      icon: Icons.format_color_text_rounded,
      tooltip: 'Metin Rengi',
      active: _currentTextColor(),
      cs: cs,
      onTap: () => _pickColor(cs, isHighlight: false),
    );
  }

  Widget _highlightPickerBtn(ColorScheme cs) {
    return _colorToolBtn(
      icon: Icons.highlight_rounded,
      tooltip: 'Vurgulama',
      active: _currentHighlightColor(),
      cs: cs,
      onTap: () => _pickColor(cs, isHighlight: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? cs.surfaceVariant.withOpacity(0.5)
        : cs.surfaceVariant.withOpacity(0.6);
    final borderColor = cs.outline.withOpacity(0.08);

    if (!widget.isCompact) {

      return Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRow1(cs, isDark),
            Divider(height: 1, color: borderColor),
            _buildRow2(cs, isDark),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        _btn(Icons.undo_rounded, 'Undo', () => _c.undo(), false, cs),
                        _btn(Icons.redo_rounded, 'Redo', () => _c.redo(), false, cs),
                        _divider(cs),
                        _btn(Icons.format_bold_rounded, 'Bold',
                            () => _toggleInline(Attribute.bold), _isActive(Attribute.bold), cs,),
                        _btn(Icons.format_italic_rounded, 'Italic',
                            () => _toggleInline(Attribute.italic), _isActive(Attribute.italic), cs,),
                        _btn(Icons.format_underline_rounded, 'Underline',
                            () => _toggleInline(Attribute.underline), _isActive(Attribute.underline), cs,),
                        _btn(Icons.strikethrough_s_rounded, 'Strikethrough',
                            () => _toggleInline(Attribute.strikeThrough), _isActive(Attribute.strikeThrough), cs,),
                        _divider(cs),
                        _headerDropdown(cs, isDark),
                        const SizedBox(width: 4),
                        _fontSizeDropdown(cs, isDark),
                        _divider(cs),
                        _btn(Icons.format_list_bulleted_rounded, 'Bullet',
                            () => _toggle(Attribute.ul), _isActive(Attribute.ul), cs,),
                        _btn(Icons.format_list_numbered_rounded, 'Numbered',
                            () => _toggle(Attribute.ol), _isActive(Attribute.ol), cs,),
                        _btn(Icons.checklist_rounded, 'Checklist',
                            () => _toggle(Attribute.unchecked), _isActive(Attribute.unchecked), cs,),
                        _divider(cs),
                        _colorPickerBtn(cs),
                        _highlightPickerBtn(cs),
                        if (_expanded) ...[
                          _divider(cs),
                          _btn(Icons.format_quote_rounded, 'Quote',
                              () => _toggle(Attribute.blockQuote), _isActive(Attribute.blockQuote), cs,),
                          _btn(Icons.code_rounded, 'Code Block',
                              () => _toggle(Attribute.codeBlock), _isActive(Attribute.codeBlock), cs,),
                          _btn(Icons.data_object_rounded, 'Inline Code',
                              () => _toggleInline(Attribute.inlineCode), _isActive(Attribute.inlineCode), cs,),
                          _btn(Icons.link_rounded, 'Link', _insertLink, false, cs),
                          _divider(cs),
                          _btn(Icons.format_align_left_rounded, 'Left',
                              () => _c.formatSelection(Attribute.leftAlignment), false, cs,),
                          _btn(Icons.format_align_center_rounded, 'Center',
                              () => _c.formatSelection(Attribute.centerAlignment), false, cs,),
                          _btn(Icons.format_align_right_rounded, 'Right',
                              () => _c.formatSelection(Attribute.rightAlignment), false, cs,),
                        ],
                      ],
                    ),
                  ),
                ),

                _btn(
                  _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  _expanded ? 'Less' : 'More',
                  () => setState(() => _expanded = !_expanded),
                  _expanded,
                  cs,
                ),
              ],
            ),
          ),

          SizedBox(
            height: 40,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: _insertButtons(cs, isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow1(ColorScheme cs, bool isDark) {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            _btn(Icons.undo_rounded, 'Undo', () => _c.undo(), false, cs),
            _btn(Icons.redo_rounded, 'Redo', () => _c.redo(), false, cs),
            _divider(cs),
            _btn(Icons.format_bold_rounded, 'Bold',
                () => _toggleInline(Attribute.bold), _isActive(Attribute.bold), cs,),
            _btn(Icons.format_italic_rounded, 'Italic',
                () => _toggleInline(Attribute.italic), _isActive(Attribute.italic), cs,),
            _btn(Icons.format_underline_rounded, 'Underline',
                () => _toggleInline(Attribute.underline), _isActive(Attribute.underline), cs,),
            _btn(Icons.strikethrough_s_rounded, 'Strikethrough',
                () => _toggleInline(Attribute.strikeThrough), _isActive(Attribute.strikeThrough), cs,),
            _divider(cs),
            _headerDropdown(cs, isDark),
            const SizedBox(width: 4),
            _fontSizeDropdown(cs, isDark),
            _divider(cs),
            _btn(Icons.format_list_bulleted_rounded, 'Bullet',
                () => _toggle(Attribute.ul), _isActive(Attribute.ul), cs,),
            _btn(Icons.format_list_numbered_rounded, 'Numbered',
                () => _toggle(Attribute.ol), _isActive(Attribute.ol), cs,),
            _btn(Icons.checklist_rounded, 'Checklist',
                () => _toggle(Attribute.unchecked), _isActive(Attribute.unchecked), cs,),
            _divider(cs),
            _colorPickerBtn(cs),
            _highlightPickerBtn(cs),
            _divider(cs),
            _btn(Icons.format_quote_rounded, 'Quote',
                () => _toggle(Attribute.blockQuote), _isActive(Attribute.blockQuote), cs,),
            _btn(Icons.code_rounded, 'Code Block',
                () => _toggle(Attribute.codeBlock), _isActive(Attribute.codeBlock), cs,),
            _btn(Icons.data_object_rounded, 'Inline Code',
                () => _toggleInline(Attribute.inlineCode), _isActive(Attribute.inlineCode), cs,),
            _btn(Icons.link_rounded, 'Link', _insertLink, false, cs),
            _divider(cs),
            _btn(Icons.format_align_left_rounded, 'Left',
                () => _c.formatSelection(Attribute.leftAlignment), false, cs,),
            _btn(Icons.format_align_center_rounded, 'Center',
                () => _c.formatSelection(Attribute.centerAlignment), false, cs,),
            _btn(Icons.format_align_right_rounded, 'Right',
                () => _c.formatSelection(Attribute.rightAlignment), false, cs,),
          ],
        ),
      ),
    );
  }

  Widget _buildRow2(ColorScheme cs, bool isDark) {
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: _insertButtons(cs, isDark)),
      ),
    );
  }

  List<Widget> _insertButtons(ColorScheme cs, bool isDark) {
    return [
      _insertChip(Icons.table_chart_rounded, 'Table', widget.onInsertTable, cs, isDark),
      const SizedBox(width: 4),
      _insertChip(Icons.info_rounded, 'Callout', widget.onInsertCallout, cs, isDark),
      const SizedBox(width: 4),
      _insertChip(Icons.horizontal_rule_rounded, 'Divider', widget.onInsertDivider, cs, isDark),
      const SizedBox(width: 4),
      if (widget.onInsertTask != null)
        _insertChip(Icons.task_alt_rounded, 'Task', widget.onInsertTask!, cs, isDark),
      if (widget.onInsertTask != null) const SizedBox(width: 4),
      if (widget.onInsertWorkflow != null)
        _insertChip(Icons.account_tree_rounded, 'Workflow', widget.onInsertWorkflow!, cs, isDark),
    ];
  }

  static const _fontSizes = [8, 10, 11, 12, 14, 16, 18, 24, 36];

  int? _currentFontSize() {
    final v = _c.getSelectionStyle().attributes['size']?.value;
    if (v is String) return int.tryParse(v);
    if (v is int) return v;
    return null;
  }

  Widget _fontSizeDropdown(ColorScheme cs, bool isDark) {
    final current = _currentFontSize();
    final label = current != null ? '${current}pt' : '12pt';

    return PopupMenuButton<int>(
      tooltip: 'Font Size',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, -280),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: current != null
              ? cs.secondary.withOpacity(0.1)
              : cs.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: current != null
                    ? cs.secondary
                    : cs.onSurface.withOpacity(0.5),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                size: 16,
                color: current != null
                    ? cs.secondary
                    : cs.onSurface.withOpacity(0.4),),
          ],
        ),
      ),
      onSelected: (size) {
        _c.formatSelection(SizeAttribute('$size'));
      },
      itemBuilder: (_) => _fontSizes.map((size) {
        final isActive = current == size;
        return PopupMenuItem<int>(
          value: size,
          child: Row(
            children: [
              if (isActive)
                Icon(Icons.check_rounded, size: 14, color: cs.secondary)
              else
                const SizedBox(width: 14),
              const SizedBox(width: 8),
              Text(
                '${size}pt',
                style: GoogleFonts.outfit(
                  fontSize: size.toDouble().clamp(10, 18),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _headerDropdown(ColorScheme cs, bool isDark) {
    final h = _currentHeader();
    final label = h == 0
        ? 'Normal'
        : 'H$h';

    return PopupMenuButton<int>(
      tooltip: 'Heading',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, -200),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: h > 0
              ? cs.primary.withOpacity(0.1)
              : cs.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: h > 0 ? cs.primary : cs.onSurface.withOpacity(0.5),
                ),),
            Icon(Icons.arrow_drop_down_rounded,
                size: 16,
                color: h > 0 ? cs.primary : cs.onSurface.withOpacity(0.4),),
          ],
        ),
      ),
      onSelected: (v) {
        if (v == 0) {
          _c.formatSelection(Attribute.clone(Attribute.h1, null));
        } else {
          _c.formatSelection(HeaderAttribute(level: v));
        }
      },
      itemBuilder: (_) => [
        _headerItem('Normal', 16, FontWeight.w400, 0, cs),
        _headerItem('Heading 1', 22, FontWeight.w800, 1, cs),
        _headerItem('Heading 2', 18, FontWeight.w700, 2, cs),
        _headerItem('Heading 3', 15, FontWeight.w600, 3, cs),
      ],
    );
  }

  PopupMenuItem<int> _headerItem(
      String text, double size, FontWeight weight, int value, ColorScheme cs,) {
    final isActive = _currentHeader() == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (isActive)
            Icon(Icons.check_rounded, size: 14, color: cs.primary)
          else
            const SizedBox(width: 14),
          const SizedBox(width: 8),
          Text(text,
              style: GoogleFonts.outfit(
                  fontSize: size, fontWeight: weight, color: cs.onSurface,),),
        ],
      ),
    );
  }

  void _insertLink() {
    final cs = Theme.of(context).colorScheme;
    final urlCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: cs.surface,
        title: Text(AppLocalizations.of(context)!.noteAddLink,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: urlCtrl,
          autofocus: true,
          style: GoogleFonts.outfit(fontSize: 14),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.noteLinkUrlHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (url.isNotEmpty) {
                _c.formatSelection(LinkAttribute(url));
              }
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    ).then((_) => urlCtrl.dispose());
  }

  Widget _btn(IconData icon, String tooltip, VoidCallback onTap, bool active, ColorScheme cs) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: active ? cs.primary.withOpacity(0.12) : null,
          ),
          child: Icon(icon,
              size: 18,
              color: active ? cs.primary : cs.onSurface.withOpacity(0.5),),
        ),
      ),
    );
  }

  Widget _divider(ColorScheme cs) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: cs.outline.withOpacity(0.08),
    );
  }

  Widget _insertChip(
      IconData icon, String label, VoidCallback onTap, ColorScheme cs, bool isDark,) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: cs.primary.withOpacity(isDark ? 0.08 : 0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cs.primary.withOpacity(0.7)),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.primary.withOpacity(0.7),),),
          ],
        ),
      ),
    );
  }
}
