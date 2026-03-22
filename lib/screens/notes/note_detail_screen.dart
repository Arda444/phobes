import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import '../../models/note_model.dart';
import '../../services/firebase_service.dart';
import '../../core/page_transitions.dart';
import '../../widgets/phobes_widgets.dart';
import 'note_add_edit_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  final VoidCallback? onClose;

  const NoteDetailScreen({
    super.key,
    required this.note,
    this.onClose,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Note _note;
  late quill.QuillController _contentCtrl;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _loadContent();
  }

  void _loadContent() {
    if (_note.content.isNotEmpty) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(_note.content));
        _contentCtrl = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        final doc = quill.Document()..insert(0, _note.content);
        _contentCtrl = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      _contentCtrl = quill.QuillController.basic();
    }
  }

  Future<void> _deleteNote() async {
    final confirmed = await PhobesBottomSheet.confirm(
      context: context,
      title: "Notu Sil",
      message: "Bu not kalıcı olarak silinecek. Emin misiniz?",
      confirmText: "Sil",
      confirmColor: Colors.red,
    );

    if (confirmed == true && mounted) {
      if (_note.id != null) {
        await _firebaseService.deleteNote(_note.id!);
      }
      if (!mounted) return;

      if (widget.onClose != null) {
        widget.onClose!();
      } else {
        Navigator.pop(context);
      }

      PhobesSnackbar.show(
        context,
        message: "Not silindi",
        type: PhobesSnackbarType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_note.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _note.tags
                          .map((t) => PhobesChip(label: t, isSelected: true))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  PhobesCard(
                    padding: const EdgeInsets.all(20),
                    margin: EdgeInsets.zero,
                    child: IgnorePointer(
                      ignoring: true, // completely read-only
                      child: quill.QuillEditor.basic(
                        configurations: quill.QuillEditorConfigurations(
                          controller: _contentCtrl,
                          sharedConfigurations:
                              const quill.QuillSharedConfigurations(
                            locale: Locale('tr'),
                          ),
                          customStyles: quill.DefaultStyles(
                            paragraph: quill.DefaultTextBlockStyle(
                              GoogleFonts.outfit(
                                fontSize: 16,
                                color: cs.onSurface,
                                height: 1.6,
                              ),
                              const quill.VerticalSpacing(0, 0),
                              const quill.VerticalSpacing(0, 0),
                              null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final noteColor = Color(_note.color);
    final dateFormat = DateFormat('d MMMM yyyy, HH:mm', 'tr');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            noteColor.withValues(alpha: 0.15),
            cs.surface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        border: Border(
          bottom: BorderSide(
            color: noteColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PhobesIconButton(
                icon: Icons.arrow_back_rounded,
                backgroundColor: cs.surface.withValues(alpha: 0.5),
                onTap: () {
                  if (widget.onClose != null) {
                    widget.onClose!();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              Row(
                children: [
                  PhobesIconButton(
                    icon: Icons.edit_rounded,
                    backgroundColor: cs.surface.withValues(alpha: 0.5),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      await navigator.push(PhobesPageRoute.slideUp(
                          NoteAddEditScreen(
                              selectedDate: _note.date, note: _note)));
                      if (mounted) {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else {
                          navigator.pop();
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  PhobesIconButton(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                    onTap: _deleteNote,
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: noteColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _note.category.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: noteColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_note.isPinned) ...[
                const SizedBox(width: 8),
                Icon(Icons.push_pin_rounded, size: 16, color: noteColor),
              ]
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _note.title.isEmpty ? 'Başlıksız' : _note.title,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateFormat.format(_note.updatedAt ?? _note.date),
            style: GoogleFonts.outfit(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
