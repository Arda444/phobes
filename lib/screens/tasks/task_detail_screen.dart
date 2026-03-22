import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/task_model.dart';
import '../../services/firebase_service.dart';
import '../../services/nova_service.dart';
import '../../services/notification_service.dart';
import '../../core/page_transitions.dart';
import '../../widgets/phobes_widgets.dart';
import '../../core/phobes_theme.dart';
import 'package:phobes/utils/time_utils.dart';
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
  final TextEditingController _subtaskController = TextEditingController();

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

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
          PhobesSnackbar.show(context,
              message: "Bağlantı açılamadı", type: PhobesSnackbarType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        PhobesSnackbar.show(context,
            message: "Hata: $e", type: PhobesSnackbarType.error);
      }
    }
  }

  Future<void> _magicSplit() async {
    setState(() => _isGenerating = true);

    try {
      final subtasks = await _novaService.generateSubtasks(_task.title);

      if (!mounted) return;

      if (subtasks.isEmpty) {
        PhobesSnackbar.show(context,
            message: "Nova öneri üretemedi.", type: PhobesSnackbarType.error);
        return;
      }

      _showSubtaskDialog(subtasks);
    } catch (e) {
      if (mounted) {
        PhobesSnackbar.show(context,
            message: "Hata: $e", type: PhobesSnackbarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showSubtaskDialog(List<String> subtasks) {
    final cs = Theme.of(context).colorScheme;
    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: "Nova Öneriyor",
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.tealAccent),
                const SizedBox(width: 8),
                Text("Bu görevi şu adımlara bölelim mi?",
                    style: GoogleFonts.outfit(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontSize: 14)),
              ],
            ),
            const SizedBox(height: 24),
            ...subtasks.map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_box_outline_blank,
                          size: 18, color: cs.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(s,
                            style: GoogleFonts.outfit(
                                color: cs.onSurface, fontSize: 14)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            PhobesButton(
              text: "Adımları Ekle",
              width: double.infinity,
              onPressed: () async {
                final navigator = Navigator.of(ctx);

                final newSubtasks = List<SubTask>.from(_task.subtasks);
                int index = 0;
                for (var s in subtasks) {
                  newSubtasks.add(SubTask(
                    id: '${DateTime.now().millisecondsSinceEpoch}_${index++}',
                    title: s,
                  ));
                }

                final updatedTask = _task.copyWith(subtasks: newSubtasks);

                navigator.pop();

                await _firebaseService.updateTask(updatedTask);

                if (mounted) {
                  setState(() => _task = updatedTask);
                  PhobesSnackbar.show(context,
                      message: "Adımlar alt görev olarak eklendi!",
                      type: PhobesSnackbarType.success);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _smartReschedule() async {
    final cs = Theme.of(context).colorScheme;

    PhobesSnackbar.show(context,
        message: "Nova boşluk arıyor... 🕵️", type: PhobesSnackbarType.info);

    final allTasks = await _firebaseService.getAllUserTasksStream().first;
    final bestTime = await _novaService.findBestSlot(_task, allTasks);

    if (!mounted) return;

    if (bestTime != null) {
      PhobesBottomSheet.show(
        context: context,
        builder: (ctx) => PhobesBottomSheet(
          title: "Zaman Bulundu!",
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_available_rounded, color: cs.primary),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('d MMMM HH:mm', 'tr').format(bestTime),
                      style: GoogleFonts.outfit(
                        color: cs.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                  "Bu zaman dilimi planın için uygun görünüyor. Onaylıyor musun?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 14,
                  )),
              const SizedBox(height: 32),
              PhobesButton(
                text: "Planla",
                width: double.infinity,
                onPressed: () async {
                  final dialogNav = Navigator.of(ctx);
                  final bestEnd =
                      bestTime.add(_task.endTime.difference(_task.startTime));
                  await _firebaseService.updateTask(
                      _task.copyWith(startTime: bestTime, endTime: bestEnd));
                  dialogNav.pop();
                  if (mounted) {
                    setState(() => _task =
                        _task.copyWith(startTime: bestTime, endTime: bestEnd));
                    PhobesSnackbar.show(context,
                        message: "Görev başarıyla planlandı!",
                        type: PhobesSnackbarType.success);
                  }
                },
              ),
              const SizedBox(height: 12),
              PhobesButton(
                text: "İptal",
                width: double.infinity,
                backgroundColor: cs.onSurface.withValues(alpha: 0.05),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    } else {
      PhobesSnackbar.show(context,
          message: "Uygun boşluk bulamadım :(", type: PhobesSnackbarType.error);
    }
  }

  void _showPostponeMenu() {
    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: "Görev Ertele",
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPostponeItem(
                "Akıllı Erteleme (Nova)", null, Icons.auto_awesome, true),
            _buildPostponeItem(
                "Özel Zaman Seç", null, Icons.edit_calendar_rounded),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            _buildPostponeItem(
                "15 Dakika", const Duration(minutes: 15), Icons.timer_outlined),
            _buildPostponeItem(
                "1 Saat", const Duration(hours: 1), Icons.alarm_rounded),
            _buildPostponeItem(
                "Yarına", const Duration(days: 1), Icons.event_rounded),
            _buildPostponeItem("1 Hafta", const Duration(days: 7),
                Icons.calendar_month_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildPostponeItem(String label, Duration? duration, IconData icon,
      [bool isNova = false]) {
    final cs = Theme.of(context).colorScheme;
    return PhobesCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: isNova ? Colors.tealAccent : cs.primary),
        title: Text(label,
            style: GoogleFonts.outfit(
                color: isNova ? Colors.tealAccent : cs.onSurface,
                fontWeight: isNova ? FontWeight.bold : FontWeight.w500)),
        onTap: () async {
          if (isNova) {
            Navigator.of(context).pop();
            _smartReschedule();
            return;
          }

          if (duration == null) {
            Navigator.of(context).pop();
            _showCustomPostponePicker();
            return;
          }

          final newStart = _task.startTime.add(duration);
          final newEnd = _task.endTime.add(duration);
          Navigator.of(context).pop();
          
          await _tryPostponeTask(newStart, newEnd, label);
        },
      ),
    );
  }

  Future<void> _showCustomPostponePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _task.startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_task.startTime),
    );

    if (pickedTime == null || !mounted) return;

    final newStartTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    
    final duration = _task.endTime.difference(_task.startTime);
    final newEndTime = newStartTime.add(duration);

    await _tryPostponeTask(newStartTime, newEndTime);
  }

  Future<void> _tryPostponeTask(DateTime newStart, DateTime newEnd, [String? successLabel]) async {
    final tasks = await _firebaseService.getAllUserTasksStream().first;
    final otherTasks = tasks.where((t) => t.id != _task.id).toList();

    final overlap = TimeUtils.getOverlappingTask(newStart, newEnd, otherTasks);
    if (overlap != null) {
      final freeSlots = TimeUtils.getFreeSlots(newStart, otherTasks);
      final freeText = freeSlots.join('\n');
      
      if (!mounted) return;
      final proceed = await _showOverlapWarning(overlap.title, freeText);
      if (proceed != true) return;
    }

    final newTask = _task.copyWith(
      startTime: newStart,
      endTime: newEnd,
      postponeCount: _task.postponeCount + 1,
    );

    await _firebaseService.updateTask(newTask);

    if (!mounted) return;

    setState(() => _task = newTask);
    
    PhobesSnackbar.show(
      context,
      message: successLabel != null 
        ? "$successLabel ertelendi!" 
        : "Görev ${DateFormat('d MMM HH:mm', 'tr').format(newStart)} tarihine ertelendi!",
      type: PhobesSnackbarType.success,
    );
  }

  Future<bool?> _showOverlapWarning(String overlapTaskName, String freeSlots) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text("Saat Çakışması", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          "Seçtiğiniz saatlerde '$overlapTaskName' görevi ile meşgulsünüz.\n\nBoş vakitleriniz:\n$freeSlots\n\nYine de kaydetmek istiyor musunuz?",
          style: GoogleFonts.outfit(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text("İptal", style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7))),
          ),
          PhobesButton(
            text: "Yine de Kaydet",
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask() async {
    final confirmed = await PhobesBottomSheet.confirm(
      context: context,
      title: "Görevi Sil",
      message: "Bu görev kalıcı olarak silinecek. Emin misiniz?",
      confirmText: "Görevi Sil",
      confirmColor: Colors.red,
    );

    if (confirmed == true && mounted) {
      if (_task.id != null) {
        await _firebaseService.deleteTask(_task.id!);
        await NotificationService().cancelNotification(_task.id!);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      if (!context.mounted) return;
      if (mounted) {
        PhobesSnackbar.show(context,
            message: "Görev silindi", type: PhobesSnackbarType.success);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM yyyy, HH:mm', 'tr');
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'task_detail_postpone',
        onPressed: _showPostponeMenu,
        backgroundColor: Colors.orange.shade800,
        elevation: 4,
        icon: const Icon(Icons.update_rounded, color: Colors.white),
        label: Text(
          "Ertele",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNovaCard(),
                  const SizedBox(height: 24),
                  _buildTimeCard(dateFormat),
                  const SizedBox(height: 24),
                  if (_task.description.isNotEmpty) ...[
                    _buildSectionLabel("Açıklama"),
                    const SizedBox(height: 12),
                    PhobesCard(
                      padding: const EdgeInsets.all(16),
                      margin: EdgeInsets.zero,
                      child: Text(
                        _task.description,
                        style: GoogleFonts.outfit(
                          color: cs.onSurface.withValues(alpha: 0.7),
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  _buildSectionLabel("Alt Görevler"),
                  const SizedBox(height: 12),
                  _buildSubtasksList(),
                  const SizedBox(height: 24),

                  if (_task.url.isNotEmpty) ...[
                    _buildSectionLabel("Bağlantı"),
                    const SizedBox(height: 12),
                    _buildLinkCard(),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_task.assignedTo.isNotEmpty)
                        Expanded(child: _buildAssignees()),
                      if (_task.tags.isNotEmpty) Expanded(child: _buildTags()),
                    ],
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

  Widget _buildSectionLabel(String text) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.outfit(
        color: cs.onSurface.withValues(alpha: 0.4),
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final taskColor = Color(_task.color);
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            taskColor.withValues(alpha: 0.15),
            cs.surface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        border: Border(
          bottom: BorderSide(
            color: taskColor.withValues(alpha: 0.1),
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
                onTap: () => Navigator.pop(context),
              ),
              Row(
                children: [
                  PhobesIconButton(
                    icon: Icons.edit_rounded,
                    backgroundColor: cs.surface.withValues(alpha: 0.5),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      await navigator.push(PhobesPageRoute.slideUp(
                          TaskAddEditScreen(
                              selectedDate: _task.startTime, task: _task)));
                      if (mounted) {}
                    },
                  ),
                  const SizedBox(width: 8),
                  PhobesIconButton(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                    onTap: _deleteTask,
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildPriorityBadge(),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final updatedTask =
                      _task.copyWith(isCompleted: !_task.isCompleted);
                  await _firebaseService.updateTask(updatedTask);
                  if (!context.mounted) return;
                  setState(() => _task = updatedTask);
                  PhobesSnackbar.show(context,
                      message: _task.isCompleted
                          ? "Görev tamamlandı!"
                          : "Görev geri alındı.",
                      type: PhobesSnackbarType.success);
                },
                child: _buildStatusBadge(
                  _task.isCompleted ? "TAMAMLANDI" : "TAMAMLA",
                  _task.isCompleted ? Colors.blueAccent : cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _task.title,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    Color color;
    String label;
    switch (_task.priority) {
      case 2:
        color = Colors.redAccent;
        label = "YÜKSEK ÖNCELİK";
        break;
      case 1:
        color = Colors.orangeAccent;
        label = "NORMAL";
        break;
      default:
        color = Colors.greenAccent;
        label = "DÜŞÜK";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTimeCard(DateFormat dateFormat) {
    final cs = Theme.of(context).colorScheme;
    return PhobesCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today_rounded, color: cs.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeRow(
                    "BAŞLANGIÇ", dateFormat.format(_task.startTime), cs),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                _buildTimeRow("BİTİŞ", dateFormat.format(_task.endTime), cs),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, String value, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: cs.onSurface.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: cs.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNovaCard() {
    final cs = Theme.of(context).colorScheme;
    return PhobesGlassCard(
      onTap: _isGenerating ? null : _magicSplit,
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: PhobesTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: _isGenerating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Nova Asistan",
                  style: GoogleFonts.outfit(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Bu görevi akıllı adımlara böl",
                  style: GoogleFonts.outfit(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: cs.onSurface.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildLinkCard() {
    return PhobesCard(
      onTap: () => _launchURL(_task.url),
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.link_rounded, color: Colors.blueAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _task.url,
              style: GoogleFonts.outfit(
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.open_in_new_rounded,
              color: Colors.blueAccent, size: 16),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel("Etiketler"),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _task.tags
              .map((t) => PhobesChip(label: t, isSelected: true))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAssignees() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel("Kişiler"),
        const SizedBox(height: 12),
        Wrap(
          spacing: -8,
          children: _task.assignedTo.map((userId) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final name = data?['name'] ?? '?';
                final photoUrl = data?['photoUrl'];
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: PhobesAvatar(
                    size: 32,
                    name: name,
                    imageUrl: photoUrl,
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubtasksList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._task.subtasks.map((st) => _buildSubtaskItem(st)),
        const SizedBox(height: 8),
        _buildAddSubtaskField(),
      ],
    );
  }

  Widget _buildSubtaskItem(SubTask st) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        leading: Transform.scale(
          scale: 1.1,
          child: Checkbox(
            value: st.isCompleted,
            activeColor: cs.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) async {
              if (val == null) return;
              final newSubtasks = List<SubTask>.from(_task.subtasks);
              final index = newSubtasks.indexWhere((s) => s.id == st.id);
              if (index != -1) {
                newSubtasks[index] = st.copyWith(isCompleted: val);
                final updatedTask = _task.copyWith(subtasks: newSubtasks);
                setState(() => _task = updatedTask);
                await _firebaseService.updateTask(updatedTask);
              }
            },
          ),
        ),
        title: Text(
          st.title,
          style: GoogleFonts.outfit(
            color: st.isCompleted ? cs.onSurface.withValues(alpha: 0.5) : cs.onSurface,
            decoration: st.isCompleted ? TextDecoration.lineThrough : null,
            fontSize: 15,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurface.withValues(alpha: 0.3), size: 20),
          onPressed: () async {
            final newSubtasks = List<SubTask>.from(_task.subtasks)..removeWhere((s) => s.id == st.id);
            final updatedTask = _task.copyWith(subtasks: newSubtasks);
            setState(() => _task = updatedTask);
            await _firebaseService.updateTask(updatedTask);
          },
        ),
      ),
    );
  }

  Widget _buildAddSubtaskField() {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _subtaskController,
            style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Yeni alt görev ekle...",
              hintStyle: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.4)),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onSubmitted: (val) => _addSubtask(val),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () => _addSubtask(_subtaskController.text),
          ),
        )
      ],
    );
  }

  Future<void> _addSubtask(String title) async {
    if (title.trim().isEmpty) return;
    
    final newSt = SubTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
    );
    
    final newSubtasks = List<SubTask>.from(_task.subtasks)..add(newSt);
    final updatedTask = _task.copyWith(subtasks: newSubtasks);
    
    setState(() {
      _task = updatedTask;
      _subtaskController.clear();
    });
    
    await _firebaseService.updateTask(updatedTask);
  }
}
