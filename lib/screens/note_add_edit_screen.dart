import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../services/firebase_service.dart';
import '../l10n/app_localizations.dart';
import '../services/nova_service.dart';

class NoteAddEditScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Note? note;
  const NoteAddEditScreen({super.key, required this.selectedDate, this.note});

  @override
  State<NoteAddEditScreen> createState() => _NoteAddEditScreenState();
}

class _NoteAddEditScreenState extends State<NoteAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late quill.QuillController _contentCtrl;
  final FirebaseService _firebaseService = FirebaseService();
  final NovaService _novaService = NovaService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _loadContent();
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

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
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
          content: Text("Göreye dönüştürülecek bir şey bulamadım.")));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text("${tasks.length} Görev Bulundu",
            style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tasks.length,
            itemBuilder: (c, i) => ListTile(
              leading:
                  const Icon(Icons.check_circle_outline, color: Colors.teal),
              title: Text(tasks[i].title,
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                  DateFormat('dd MMM HH:mm').format(tasks[i].startTime),
                  style: const TextStyle(color: Colors.grey)),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              Navigator.pop(ctx);
              for (var t in tasks) {
                await _firebaseService.addTask(t);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Görevler takvimine eklendi! 🎉")));
              }
            },
            child: const Text("Hepsini Ekle"),
          )
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);
    final note = Note(
        id: widget.note?.id,
        userId: widget.note?.userId ?? '',
        title: _titleCtrl.text.isEmpty ? 'Başlıksız' : _titleCtrl.text,
        content: jsonEncode(_contentCtrl.document.toDelta().toJson()),
        date: widget.selectedDate);
    try {
      if (widget.note == null) {
        await _firebaseService.addNote(note);
      } else {
        await _firebaseService.updateNote(note);
      }
      if (mounted) Navigator.pop(context, true);
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
    await _firebaseService.deleteNote(widget.note!.id!);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_fix_high, color: Colors.tealAccent),
              tooltip: "Notu Göreve Çevir",
              onPressed: _analyzeNoteWithNova,
            ),
            if (widget.note != null)
              IconButton(
                  icon:
                      const Icon(Icons.delete_rounded, color: Colors.redAccent),
                  onPressed: _deleteNote),
            IconButton(
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_rounded, color: Colors.white),
                onPressed: _saveNote)
          ]),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                    child: TextFormField(
                        controller: _titleCtrl,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                            hintText: l10n.title,
                            hintStyle: GoogleFonts.poppins(
                                color: Colors.white38,
                                fontSize: 24,
                                fontWeight: FontWeight.w600),
                            border: InputBorder.none))),
                quill.QuillToolbar.simple(
                    configurations: quill.QuillSimpleToolbarConfigurations(
                        controller: _contentCtrl,
                        showFontFamily: false,
                        showFontSize: false,
                        showSearchButton: false,
                        dialogTheme: quill.QuillDialogTheme(
                            dialogBackgroundColor: Colors.grey.shade800,
                            inputTextStyle:
                                GoogleFonts.poppins(color: Colors.white),
                            labelTextStyle:
                                GoogleFonts.poppins(color: Colors.white)))),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade900.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: quill.QuillEditor.basic(
                        configurations: quill.QuillEditorConfigurations(
                            controller: _contentCtrl,
                            sharedConfigurations:
                                const quill.QuillSharedConfigurations(
                                    locale: Locale('tr')))),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
