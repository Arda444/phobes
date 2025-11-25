import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task_model.dart';
import '../services/firebase_service.dart';
import '../services/nova_service.dart';
import 'task_add_edit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final NovaService _novaService = NovaService();
  late Task _task;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(
        urlString.startsWith('http') ? urlString : 'https://$urlString');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Link açılamadı')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  // ALT GÖREV PARÇALAYICI
  Future<void> _magicSplit() async {
    setState(() => _isGenerating = true);

    try {
      final subtasks = await _novaService.generateSubtasks(_task.title);

      if (!mounted) return;

      if (subtasks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nova öneri üretemedi.")),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Row(children: [
            Icon(Icons.auto_awesome, color: Colors.tealAccent),
            SizedBox(width: 10),
            Text("Nova Öneriyor", style: TextStyle(color: Colors.white)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Bu görevi şu adımlara bölelim mi?",
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              ...subtasks.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(children: [
                      const Icon(Icons.check_box_outline_blank,
                          size: 16, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(s,
                              style: const TextStyle(color: Colors.white))),
                    ]),
                  )),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Vazgeç")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                // Dialogu kapatmak için ctx kullanıyoruz (context güvenli)
                Navigator.pop(ctx);

                // Ana ekrana bildirim için referans al
                final messenger = ScaffoldMessenger.of(context);

                final newDesc =
                    "${_task.description}\n\n--- Nova Adımları ---\n${subtasks.map((e) => "[ ] $e").join("\n")}";
                final updatedTask = _task.copyWith(description: newDesc);

                await _firebaseService.updateTask(updatedTask);

                if (mounted) {
                  setState(() => _task = updatedTask);
                  messenger
                      .showSnackBar(const SnackBar(content: Text("Eklendi!")));
                }
              },
              child: const Text("Ekle"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // AKILLI ZAMANLAMA
  Future<void> _smartReschedule() async {
    // Referansları al
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    navigator.pop(); // Menüyü kapat
    messenger.showSnackBar(
        const SnackBar(content: Text("Nova boşluk arıyor... 🕵️")));

    final allTasks = await _firebaseService.getAllUserTasksStream().first;
    final bestTime = await _novaService.findBestSlot(_task, allTasks);

    if (mounted) {
      if (bestTime != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: const Text("Zaman Bulundu!",
                style: TextStyle(color: Colors.white)),
            content: Text(
                "${DateFormat('d MMMM HH:mm', 'tr').format(bestTime)} uygun mu?",
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Hayır")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () async {
                  await _firebaseService.updateTask(_task.copyWith(
                      startTime: bestTime,
                      endTime: bestTime.add(const Duration(hours: 1))));
                  Navigator.pop(ctx); // Dialogu kapat
                  if (mounted) {
                    setState(() => _task = _task.copyWith(startTime: bestTime));
                  }
                },
                child: const Text("Onayla"),
              )
            ],
          ),
        );
      } else {
        messenger.showSnackBar(
            const SnackBar(content: Text("Uygun boşluk bulamadım :(")));
      }
    }
  }

  void _showPostponeMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Wrap(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Ertele",
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.tealAccent),
            title: const Text("Akıllı Erteleme (Nova)",
                style: TextStyle(color: Colors.tealAccent)),
            onTap: _smartReschedule,
          ),
          _buildPostponeItem("15 Dakika", const Duration(minutes: 15)),
          _buildPostponeItem("1 Saat", const Duration(hours: 1)),
          _buildPostponeItem("Yarına", const Duration(days: 1)),
          _buildPostponeItem("1 Hafta", const Duration(days: 7)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPostponeItem(String label, Duration duration) {
    return ListTile(
      leading: const Icon(Icons.update, color: Colors.white70),
      title: Text(label, style: GoogleFonts.poppins(color: Colors.white)),
      onTap: () async {
        // HATA ÇÖZÜMÜ: Referansları işlemden önce al
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);

        final newTask = _task.copyWith(
          startTime: _task.startTime.add(duration),
          endTime: _task.endTime.add(duration),
          postponeCount: _task.postponeCount + 1,
        );
        await _firebaseService.updateTask(newTask);

        if (mounted) {
          setState(() => _task = newTask);
          navigator.pop(); // Menüyü kapat (Referansla)
          messenger.showSnackBar(SnackBar(
              content: Text("$label ertelendi!"))); // Snackbar (Referansla)
        }
      },
    );
  }

  Future<void> _deleteTask() async {
    // Referansı al
    final navigator = Navigator.of(context);

    if (_task.id != null) await _firebaseService.deleteTask(_task.id!);

    if (mounted) navigator.pop(); // Referansla çıkış yap
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM yyyy, HH:mm', 'tr');

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.tealAccent))
                : const Icon(Icons.auto_awesome, color: Colors.tealAccent),
            tooltip: "Yapay Zeka ile Böl",
            onPressed: _isGenerating ? null : _magicSplit,
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.blue),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TaskAddEditScreen(
                          selectedDate: _task.startTime, task: _task)));
              if (context.mounted) Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.red),
            onPressed: _deleteTask,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(_task.title,
                  style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Color(_task.color).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.access_time_filled_rounded,
                          color: Color(_task.color)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Başlangıç",
                            style: GoogleFonts.poppins(
                                color: Colors.grey, fontSize: 12)),
                        Text(dateFormat.format(_task.startTime),
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text("Bitiş",
                            style: GoogleFonts.poppins(
                                color: Colors.grey, fontSize: 12)),
                        Text(dateFormat.format(_task.endTime),
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_task.url.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => _launchURL(_task.url),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3))),
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(_task.url,
                                style: GoogleFonts.poppins(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline),
                                overflow: TextOverflow.ellipsis)),
                        const Icon(Icons.open_in_new_rounded,
                            color: Colors.blue, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (_task.description.isNotEmpty) ...[
                Text("Açıklama",
                    style: GoogleFonts.poppins(
                        color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade900.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(_task.description,
                      style: GoogleFonts.poppins(
                          color: Colors.white70, height: 1.5)),
                ),
                const SizedBox(height: 20),
              ],
              if (_task.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: _task.tags
                      .map((t) => Chip(
                          label: Text(t),
                          backgroundColor: Colors.grey.shade800,
                          labelStyle: GoogleFonts.poppins(color: Colors.white),
                          side: BorderSide.none))
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.flag, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _task.priority == 0
                        ? "Düşük Öncelik"
                        : (_task.priority == 1
                            ? "Orta Öncelik"
                            : "Yüksek Öncelik"),
                    style: GoogleFonts.poppins(
                        color: _task.priority == 2
                            ? Colors.redAccent
                            : (_task.priority == 1
                                ? Colors.orangeAccent
                                : Colors.greenAccent)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'task_detail_postpone',
        onPressed: _showPostponeMenu,
        backgroundColor: Colors.orange.shade800,
        icon: const Icon(Icons.update, color: Colors.white),
        label: Text("Ertele",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
