import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

/// Slash command data
class SlashCommand {
  final String key;
  final String label;
  final String description;
  final IconData icon;
  final Color? color;
  final void Function(QuillController controller, int offset) action;

  const SlashCommand({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
    this.color,
    required this.action,
  });
}

/// Overlay widget that shows slash commands when user types "/"
class SlashCommandOverlay extends StatefulWidget {
  final QuillController controller;
  final LayerLink layerLink;
  final VoidCallback onDismiss;
  final List<SlashCommand> commands;
  final int slashOffset;

  const SlashCommandOverlay({
    super.key,
    required this.controller,
    required this.layerLink,
    required this.onDismiss,
    required this.commands,
    required this.slashOffset,
  });

  @override
  State<SlashCommandOverlay> createState() => _SlashCommandOverlayState();
}

class _SlashCommandOverlayState extends State<SlashCommandOverlay> {
  String _filter = '';
  int _selectedIndex = 0;
  List<SlashCommand> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.commands;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.document.toPlainText();
    final cursorPos = widget.controller.selection.baseOffset;

    if (cursorPos > widget.slashOffset) {
      final query = text.substring(widget.slashOffset + 1, cursorPos).toLowerCase();
      setState(() {
        _filter = query;
        _filtered = widget.commands
            .where((c) =>
                c.key.contains(query) ||
                c.label.toLowerCase().contains(query),)
            .toList();
        _selectedIndex = 0;
      });

      if (_filtered.isEmpty) {
        widget.onDismiss();
      }
    } else {
      widget.onDismiss();
    }
  }

  void _selectCommand(SlashCommand cmd) {

    final cursorPos = widget.controller.selection.baseOffset;
    final deleteLen = cursorPos - widget.slashOffset;
    widget.controller.replaceText(widget.slashOffset, deleteLen, '', null);

    cmd.action(widget.controller, widget.slashOffset);
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    if (_filtered.isEmpty) return const SizedBox.shrink();

    return CompositedTransformFollower(
      link: widget.layerLink,
      showWhenUnlinked: false,
      offset: const Offset(0, 24),
      child: Material(
        elevation: 8,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(14),
        color: cs.surface,
        child: Container(
          width: 280,
          constraints: const BoxConstraints(maxHeight: 320),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      _filter.isEmpty ? l10n.noteSlashCommands : '/$_filter',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withOpacity(0.4),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: cs.outline.withOpacity(0.06)),

              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) {
                    final cmd = _filtered[i];
                    final selected = i == _selectedIndex;
                    final accent = cmd.color ?? cs.primary;

                    return InkWell(
                      onTap: () => _selectCommand(cmd),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8,),
                        color: selected
                            ? cs.primary.withOpacity(isDark ? 0.08 : 0.04)
                            : null,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: accent.withOpacity(isDark ? 0.12 : 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(cmd.icon, size: 16, color: accent),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cmd.label,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface,
                                      ),),
                                  Text(cmd.description,
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: cs.onSurface.withOpacity(0.4),
                                      ),),
                                ],
                              ),
                            ),
                            Text('/${cmd.key}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  color: cs.onSurface.withOpacity(0.2),
                                ),),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns the default slash commands list.
/// Callbacks for custom embeds (table, callout, divider) are provided externally.
List<SlashCommand> buildSlashCommands({
  required AppLocalizations l10n,
  required VoidCallback onInsertTable,
  required VoidCallback onInsertCallout,
  required VoidCallback onInsertDivider,
  VoidCallback? onInsertTask,
  VoidCallback? onInsertWorkflow,
  VoidCallback? onInsertTable2,
  VoidCallback? onInsertTable3,
  VoidCallback? onInsertPageBreak,
}) {
  return [
    SlashCommand(
      key: 'h1',
      label: l10n.noteSlashHeading1Label,
      description: l10n.noteSlashHeading1Desc,
      icon: Icons.title_rounded,
      action: (c, offset) => c.formatSelection(Attribute.h1),
    ),
    SlashCommand(
      key: 'h2',
      label: l10n.noteSlashHeading2Label,
      description: l10n.noteSlashHeading2Desc,
      icon: Icons.title_rounded,
      action: (c, offset) => c.formatSelection(Attribute.h2),
    ),
    SlashCommand(
      key: 'h3',
      label: l10n.noteSlashHeading3Label,
      description: l10n.noteSlashHeading3Desc,
      icon: Icons.title_rounded,
      action: (c, offset) => c.formatSelection(Attribute.h3),
    ),
    SlashCommand(
      key: 'bullet',
      label: l10n.noteSlashBulletLabel,
      description: l10n.noteSlashBulletDesc,
      icon: Icons.format_list_bulleted_rounded,
      action: (c, offset) => c.formatSelection(Attribute.ul),
    ),
    SlashCommand(
      key: 'numbered',
      label: l10n.noteSlashNumberedLabel,
      description: l10n.noteSlashNumberedDesc,
      icon: Icons.format_list_numbered_rounded,
      action: (c, offset) => c.formatSelection(Attribute.ol),
    ),
    SlashCommand(
      key: 'checklist',
      label: l10n.noteSlashChecklistLabel,
      description: l10n.noteSlashChecklistDesc,
      icon: Icons.checklist_rounded,
      color: const Color(0xFF00BFA5),
      action: (c, offset) => c.formatSelection(Attribute.unchecked),
    ),
    SlashCommand(
      key: 'table',
      label: l10n.noteSlashTableLabel,
      description: l10n.noteSlashTableDesc,
      icon: Icons.table_chart_rounded,
      color: const Color(0xFF4285F4),
      action: (c, offset) => onInsertTable(),
    ),
    SlashCommand(
      key: 'callout',
      label: l10n.noteSlashCalloutLabel,
      description: l10n.noteSlashCalloutDesc,
      icon: Icons.info_rounded,
      color: const Color(0xFFFF9800),
      action: (c, offset) => onInsertCallout(),
    ),
    SlashCommand(
      key: 'divider',
      label: l10n.noteSlashDividerLabel,
      description: l10n.noteSlashDividerDesc,
      icon: Icons.horizontal_rule_rounded,
      action: (c, offset) => onInsertDivider(),
    ),
    SlashCommand(
      key: 'quote',
      label: l10n.noteSlashQuoteLabel,
      description: l10n.noteSlashQuoteDesc,
      icon: Icons.format_quote_rounded,
      action: (c, offset) => c.formatSelection(Attribute.blockQuote),
    ),
    SlashCommand(
      key: 'code',
      label: l10n.noteSlashCodeLabel,
      description: l10n.noteSlashCodeDesc,
      icon: Icons.code_rounded,
      color: const Color(0xFF9C27B0),
      action: (c, offset) => c.formatSelection(Attribute.codeBlock),
    ),
    if (onInsertTask != null)
      SlashCommand(
        key: 'task',
        label: l10n.noteSlashTaskCardLabel,
        description: l10n.noteSlashTaskCardDesc,
        icon: Icons.task_alt_rounded,
        color: const Color(0xFFE91E63),
        action: (c, offset) => onInsertTask(),
      ),
    if (onInsertTask != null)
      SlashCommand(
        key: 'görev',
        label: l10n.noteSlashTaskCardLabel,
        description: l10n.noteSlashTaskCardDesc,
        icon: Icons.task_alt_rounded,
        color: const Color(0xFFE91E63),
        action: (c, offset) => onInsertTask(),
      ),
    if (onInsertWorkflow != null)
      SlashCommand(
        key: 'workflow',
        label: l10n.noteSlashWorkflowLabel,
        description: l10n.noteSlashWorkflowDesc,
        icon: Icons.account_tree_rounded,
        color: const Color(0xFF00BCD4),
        action: (c, offset) => onInsertWorkflow(),
      ),
    if (onInsertTable2 != null)
      SlashCommand(
        key: 'table2',
        label: l10n.noteSlashTable2Label,
        description: l10n.noteSlashTable2Desc,
        icon: Icons.table_chart_outlined,
        color: const Color(0xFF4285F4),
        action: (c, offset) => onInsertTable2(),
      ),
    if (onInsertTable3 != null)
      SlashCommand(
        key: 'table3',
        label: l10n.noteSlashTable3Label,
        description: l10n.noteSlashTable3Desc,
        icon: Icons.table_chart_rounded,
        color: const Color(0xFF4285F4),
        action: (c, offset) => onInsertTable3(),
      ),
    if (onInsertPageBreak != null)
      SlashCommand(
        key: 'pagebreak',
        label: l10n.noteSlashPageBreakLabel,
        description: l10n.noteSlashPageBreakDesc,
        icon: Icons.insert_page_break_outlined,
        color: const Color(0xFF757575),
        action: (c, offset) => onInsertPageBreak(),
      ),
  ];
}
