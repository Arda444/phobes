import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/notebook_model.dart';
import '../../services/firebase_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_form_wrapper.dart';

class NotebookSidebar extends StatefulWidget {
  final String? selectedNotebookId;
  final Function(String?) onSelected;
  final bool isExpanded;

  const NotebookSidebar({
    super.key,
    required this.selectedNotebookId,
    required this.onSelected,
    this.isExpanded = true,
  });

  @override
  State<NotebookSidebar> createState() => _NotebookSidebarState();
}

class _NotebookSidebarState extends State<NotebookSidebar> {
  late final Stream<List<Notebook>> _notebooksStream;

  @override
  void initState() {
    super.initState();
    _notebooksStream =
        FirebaseService().getNotebooksStream().asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: widget.isExpanded ? 240 : 70,
      decoration: BoxDecoration(
        color: isDark ? cs.surface : cs.surface.withOpacity(0.5),
        border: Border(right: BorderSide(color: cs.outline.withOpacity(0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          if (widget.isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.book_rounded, color: cs.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    l10n.notebooksHeader,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: cs.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            )
          else
            const Center(child: Icon(Icons.book_rounded, size: 22)),

          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<List<Notebook>>(
              stream: _notebooksStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${l10n.error}: ${snapshot.error}',
                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  );
                }
                final notebooks = snapshot.data ?? [];

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [

                    _SidebarItem(
                      icon: Icons.all_inbox_rounded,
                      label: AppLocalizations.of(context)!.allNotes,
                      isSelected: widget.selectedNotebookId == null,
                      isExpanded: widget.isExpanded,
                      onTap: () => widget.onSelected(null),
                      color: cs.primary,
                    ),
                    const SizedBox(height: 4),
                    Divider(height: 24, color: cs.outline.withOpacity(0.05)),

                    if (notebooks.isEmpty)
                      if (widget.isExpanded)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            AppLocalizations.of(context)!.notebookEmpty,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: cs.onSurface.withOpacity(0.3),
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink()
                    else
                      ...notebooks.map((nb) => _SidebarItem(
                            label: nb.name,
                            emoji: nb.icon,
                            isSelected: widget.selectedNotebookId == nb.id,
                            isExpanded: widget.isExpanded,
                            onTap: () => widget.onSelected(nb.id),
                            color: Color(nb.color),
                            onLongPress: widget.isExpanded ? () => _showNotebookMenu(context, nb) : null,
                          ),),

                    const SizedBox(height: 12),

                    if (widget.isExpanded)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextButton.icon(
                          onPressed: () => _showAddNotebook(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(AppLocalizations.of(context)!.notebookNew,
                              style: GoogleFonts.outfit(fontSize: 13)),
                          style: TextButton.styleFrom(
                            foregroundColor: cs.primary.withOpacity(0.7),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        onPressed: () => _showAddNotebook(context),
                        icon: Icon(Icons.add_circle_outline_rounded, size: 20, color: cs.primary),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNotebook(BuildContext context) {
    PhobesFormWrapper.show(
      context,
      title: AppLocalizations.of(context)!.notebookNew,
      form: _AddNotebookForm(),
    );
  }

  void _showNotebookMenu(BuildContext context, Notebook nb) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit_rounded, color: cs.primary),
                title: Text(AppLocalizations.of(ctx)!.edit, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => _EditNotebookDialog(notebook: nb));
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                title: Text(AppLocalizations.of(ctx)!.delete, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: cs.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, nb);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Notebook nb) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteNotebook, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(AppLocalizations.of(context)!.confirmDeleteNotebook(nb.name),
            style: GoogleFonts.outfit(),),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(ctx)!.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            onPressed: () {
              Navigator.pop(ctx);
              if (nb.id != null) FirebaseService().deleteNotebook(nb.id!);
            },
            child: Text(AppLocalizations.of(ctx)!.delete),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;
  final Color color;
  final VoidCallback? onLongPress;

  const _SidebarItem({
    this.icon,
    this.emoji,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
    required this.color,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isExpanded) {
      return Center(
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: color.withOpacity(0.3)) : null,
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, size: 20, color: isSelected ? color : cs.onSurface.withOpacity(0.4))
                    : Text(emoji!, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ),
      );
    }

    return FadeInLeft(
      duration: const Duration(milliseconds: 200),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selected: isSelected,
        selectedTileColor: color.withOpacity(isDark ? 0.08 : 0.05),
        leading: icon != null
            ? Icon(icon, size: 18, color: isSelected ? color : cs.onSurface.withOpacity(0.5))
            : Text(emoji!, style: const TextStyle(fontSize: 16)),
        title: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : cs.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

class _AddNotebookForm extends StatefulWidget {
  @override
  State<_AddNotebookForm> createState() => _AddNotebookFormState();
}

class _AddNotebookFormState extends State<_AddNotebookForm> {
  final _controller = TextEditingController();
  String _emoji = '📓';
  final int _color = 0xFF6C63FF;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.notebookNameLabel,
              hintText: AppLocalizations.of(context)!.notebookNameHint,
              prefixIcon: Center(
                widthFactor: 1,
                child: Text(_emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['📓', '📕', '📗', '📘', '📙', '📔', '📓', '📑', '🔬', '🎨']
                  .map((e) => GestureDetector(
                        onTap: () => setState(() => _emoji = e),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Opacity(
                            opacity: _emoji == e ? 1.0 : 0.4,
                            child: Text(e, style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                      ),)
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final uid = FirebaseService().currentUserId;
                    if (_controller.text.trim().isEmpty || uid == null) return;
                    try {
                      await FirebaseService().addNotebook(Notebook(
                        userId: uid,
                        name: _controller.text.trim(),
                        icon: _emoji,
                        color: _color,
                        createdAt: DateTime.now(),
                      ),);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.errorGeneric(e.toString())),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(l10n.create),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditNotebookDialog extends StatefulWidget {
  final Notebook notebook;
  const _EditNotebookDialog({required this.notebook});

  @override
  State<_EditNotebookDialog> createState() => _EditNotebookDialogState();
}

class _EditNotebookDialogState extends State<_EditNotebookDialog> {
  late final TextEditingController _controller;
  late String _emoji;

  static const _emojis = ['📓', '📕', '📗', '📘', '📙', '📔', '📑', '🔬', '🎨', '💡', '🗂️', '✏️'];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.notebook.name);
    _emoji = widget.notebook.icon;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.editNotebookTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.notebookNameLabel,
              prefixIcon: Center(
                widthFactor: 1,
                child: Text(_emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _emojis
                  .map((e) => GestureDetector(
                        onTap: () => setState(() => _emoji = e),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Opacity(
                            opacity: _emoji == e ? 1.0 : 0.4,
                            child: Text(e, style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                      ),)
                  .toList(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
        FilledButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              FirebaseService().updateNotebook(widget.notebook.copyWith(
                name: _controller.text,
                icon: _emoji,
              ),);
              Navigator.pop(context);
            }
          },
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
