import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/task_model.dart';
import '../../services/firebase_service.dart';
import '../../services/calendar_sync_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/phobes_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'package:phobes/utils/time_utils.dart';

class TaskAddEditScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Task? task;
  final String? groupId;
  final VoidCallback? onClose;

  const TaskAddEditScreen({
    super.key,
    required this.selectedDate,
    this.task,
    this.groupId,
    this.onClose,
  });

  @override
  State<TaskAddEditScreen> createState() => _TaskAddEditScreenState();
}

class _TaskAddEditScreenState extends State<TaskAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final CalendarSyncService _calendarSyncService = CalendarSyncService();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _tagsCtrl;

  late DateTime _start;
  late DateTime _end;
  late bool _allDay;
  late int _color;
  late String _repeatRule;
  late int _priority;
  late int _reminderMinutes;

  List<String> _assignedToIds = [];
  List<Map<String, dynamic>> _teamMembers = [];

  final List<int> _colors = [
    0xFF6C63FF,
    0xFF4285F4,
    0xFF34A853,
    0xFFFBBC04,
    0xFFEA4335,
    0xFFF06292,
    0xFF8E24AA,
    0xFF009688
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task?.title ?? '');
    _descCtrl = TextEditingController(text: widget.task?.description ?? '');
    _locCtrl = TextEditingController(text: widget.task?.location ?? '');
    _urlCtrl = TextEditingController(text: widget.task?.url ?? '');
    _tagsCtrl = TextEditingController(text: widget.task?.tags.join(', ') ?? '');

    _start = widget.task?.startTime ?? widget.selectedDate;
    _end = widget.task?.endTime ?? _start.add(const Duration(hours: 1));
    _allDay = widget.task?.isAllDay ?? false;
    _color = widget.task?.color ?? _colors[0];
    _repeatRule = widget.task?.repeatRule ?? 'none';
    _priority = widget.task?.priority ?? 1;
    _reminderMinutes = widget.task?.reminderMinutes ?? -1;

    _assignedToIds = List.from(widget.task?.assignedTo ?? []);

    if (widget.groupId != null || widget.task?.groupId != null) {
      _loadTeamMembers();
    }
  }

  Future<void> _loadTeamMembers() async {
    final gid = widget.groupId ?? widget.task?.groupId;
    if (gid == null) return;

    try {
      final teamDoc =
          await FirebaseFirestore.instance.collection('teams').doc(gid).get();
      if (!teamDoc.exists) return;

      final List<dynamic> memberIds = teamDoc.data()?['memberIds'] ?? [];
      final members = await _firebaseService
          .getUsersByIds(memberIds.map((e) => e.toString()).toList());

      if (mounted) {
        setState(() => _teamMembers = members);
      }
    } catch (e) {
      debugPrint("Üye listesi hatası: $e");
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    _urlCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  void _showMultiSelectDialog(AppLocalizations l10n) {
    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cs = Theme.of(context).colorScheme;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l10n.assignTo,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_teamMembers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text("Üye bulunamadı",
                            style: GoogleFonts.outfit(
                                color: cs.onSurface.withValues(alpha: 0.4))),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _teamMembers.length,
                        itemBuilder: (context, index) {
                          final member = _teamMembers[index];
                          final isSelected =
                              _assignedToIds.contains(member['id']);
                          final name = "${member['name']} ${member['surname']}";

                          return CheckboxListTile(
                            activeColor: cs.primary,
                            checkColor: cs.onPrimary,
                            title: Text(
                              name,
                              style: GoogleFonts.outfit(color: cs.onSurface),
                            ),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  _assignedToIds.add(member['id']);
                                } else {
                                  _assignedToIds.remove(member['id']);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: PhobesButton(
                      text: l10n.save,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final List<String> tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final String tempEffectiveUserId = widget.task?.userId ??
          (widget.task?.userId == 'device'
              ? 'device'
              : _firebaseService.currentUserId ?? '');
              
    if (tempEffectiveUserId != 'device') {
      try {
        final tasks = await _firebaseService.getAllUserTasksStream().first;
        final otherTasks = tasks.where((t) => t.id != widget.task?.id).toList();

        final overlap = TimeUtils.getOverlappingTask(_start, _end, otherTasks);
        if (overlap != null) {
          final freeSlots = TimeUtils.getFreeSlots(_start, otherTasks);
          final freeText = freeSlots.join('\n');
          
          if (!mounted) return;
          final proceed = await _showOverlapWarning(overlap.title, freeText);
          if (proceed != true) return;
        }
      } catch (e) {
        debugPrint("Overlap check error: $e");
      }
    }

    final Task taskToSave = Task(
      id: widget.task?.id,
      userId: widget.task?.userId ??
          (widget.task?.userId == 'device'
              ? 'device'
              : _firebaseService.currentUserId ?? ''),
      groupId: widget.task?.groupId ?? widget.groupId,
      title: _titleCtrl.text,
      description: _descCtrl.text,
      location: _locCtrl.text,
      url: _urlCtrl.text,
      startTime: _start,
      endTime: _end,
      isAllDay: _allDay,
      color: _color,
      priority: _priority,
      reminderMinutes: _reminderMinutes,
      tags: tags,
      repeatRule: _repeatRule,
      isCompleted: widget.task?.isCompleted ?? false,
      completionTime: widget.task?.completionTime,
      postponeCount: widget.task?.postponeCount ?? 0,
      assignedTo: _assignedToIds,
      createdBy: widget.task?.createdBy ?? _firebaseService.currentUserId,
      status: widget.task?.status ?? 'todo',
    );

    try {
      String taskId;

      if (taskToSave.userId == 'device') {
        await _calendarSyncService.updateDeviceEvent(taskToSave);
        taskId = taskToSave.id ?? "device_task";
      } else {
        String? effectiveUserId = taskToSave.userId;
        if (effectiveUserId.isEmpty) {
          effectiveUserId = _firebaseService.currentUserId;
        }

        if (effectiveUserId == null || effectiveUserId.isEmpty) {
          throw Exception(
              "Kullanıcı kimliği belirlenemedi. Lütfen tekrar giriş yapın.");
        }

        if (taskToSave.id == null) {
          final taskData = taskToSave.toMap();
          taskData['userId'] = effectiveUserId;

          DocumentReference docRef = await FirebaseFirestore.instance
              .collection('tasks')
              .add(taskData);
          taskId = docRef.id;
        } else {
          await _firebaseService.updateTask(taskToSave);
          taskId = taskToSave.id!;
        }
      }

      final notifService = NotificationService();
      await notifService.cancelNotification(taskId);

      if (!taskToSave.isCompleted && _reminderMinutes > -1) {
        final triggerTime =
            _start.subtract(Duration(minutes: _reminderMinutes));
        if (triggerTime.isAfter(DateTime.now())) {
          await notifService.scheduleAndSaveNotification(
            id: taskId,
            title: "Hatırlatıcı: ${_titleCtrl.text}",
            body: _reminderMinutes == 0
                ? "Görevin zamanı geldi!"
                : "$_reminderMinutes dakika kaldı.",
            scheduledTime: triggerTime,
            type: 'task',
            targetId: taskId,
            targetType: 'task',
            icon: '📋',
            color: 0xFF8B5CF6,
            channelId: 'tasks',
            channelName: 'Görevler',
            prefKey: 'notif_task_deadline',
          );
        }
      }

      if (mounted) {
        if (widget.onClose != null) {
          widget.onClose!();
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.task != null;
    final isDeviceTask = widget.task?.userId == 'device';
    final isTeamContext =
        widget.groupId != null || widget.task?.groupId != null;
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 900;

      return Scaffold(
        backgroundColor: isWide ? Colors.transparent : cs.surface,
        appBar: isWide
            ? null
            : PhobesPremiumAppBar(
                title: isEdit ? l10n.editTask : l10n.newTask,
                onBackPressed: () {
                  if (widget.onClose != null) {
                    widget.onClose!();
                  } else {
                    Navigator.pop(context);
                  }
                },
                trailing: TextButton(
                  onPressed: _saveTask,
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    l10n.save,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                children: [
                  if (isDeviceTask)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PhobesChip(
                        label: "Google Takvim Etkinliği",
                        icon: Icons.sync_rounded,
                        isSelected: true,
                        onTap: () {},
                      ),
                    ),
                  if (isTeamContext && !isDeviceTask)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PhobesChip(
                        label: "${l10n.taskContext}: ${l10n.team}",
                        icon: Icons.group_work_rounded,
                        isSelected: true,
                        onTap: () {},
                      ),
                    ),
                  PhobesCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: EdgeInsets.zero,
                    child: PhobesTextFormField(
                      controller: _titleCtrl,
                      hintText: l10n.title,
                      prefixIcon: Icons.title_rounded,
                      isLarge: true,
                      validator: (v) =>
                          v?.isEmpty == true ? l10n.requiredField : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PhobesSectionHeader(
                    title: l10n.sectionTiming,
                    icon: Icons.access_time_filled_rounded,
                  ),
                  PhobesCard(
                    padding: const EdgeInsets.all(16),
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: _buildDateTimeTile(
                                    l10n.start, _start, true)),
                            Container(
                              width: 1,
                              height: 30,
                              color: cs.outline.withValues(alpha: 0.1),
                            ),
                            Expanded(
                                child:
                                    _buildDateTimeTile(l10n.end, _end, false)),
                          ],
                        ),
                        const Divider(height: 32, thickness: 0.5),
                        _buildReminderSelector(l10n),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l10n.allDay,
                            style: GoogleFonts.outfit(
                              color: cs.onSurface,
                              fontSize: 15,
                            ),
                          ),
                          value: _allDay,
                          activeThumbColor: cs.primary,
                          onChanged: (v) => setState(() => _allDay = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isTeamContext &&
                      !isDeviceTask &&
                      _teamMembers.isNotEmpty) ...[
                    PhobesSectionHeader(
                      title: l10n.assignTo,
                      icon: Icons.person_add_alt_1_rounded,
                    ),
                    GestureDetector(
                      onTap: () => _showMultiSelectDialog(l10n),
                      child: PhobesCard(
                        padding: const EdgeInsets.all(16),
                        margin: EdgeInsets.zero,
                        child: Row(
                          children: [
                            Expanded(
                              child: _assignedToIds.isEmpty
                                  ? Text(
                                      l10n.unassigned,
                                      style: GoogleFonts.outfit(
                                        color:
                                            cs.onSurface.withValues(alpha: 0.4),
                                      ),
                                    )
                                  : Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _assignedToIds.map((id) {
                                        final member = _teamMembers.firstWhere(
                                            (m) => m['id'] == id,
                                            orElse: () =>
                                                {'name': '?', 'surname': ''});
                                        return PhobesChip(
                                          label:
                                              "${member['name']} ${member['surname'][0]}.",
                                          isSelected: true,
                                          onTap: () {},
                                        );
                                      }).toList(),
                                    ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: cs.onSurface.withValues(alpha: 0.4)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  PhobesSectionHeader(
                    title: l10n.sectionDetails,
                    icon: Icons.article_rounded,
                  ),
                  PhobesCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        PhobesTextFormField(
                          controller: _descCtrl,
                          hintText: l10n.descriptionOptional,
                          prefixIcon: Icons.notes_rounded,
                          maxLines: 3,
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: cs.outline.withValues(alpha: 0.1),
                        ),
                        PhobesTextFormField(
                          controller: _urlCtrl,
                          hintText: l10n.linkOptional,
                          prefixIcon: Icons.link_rounded,
                          keyboardType: TextInputType.url,
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: cs.outline.withValues(alpha: 0.1),
                        ),
                        PhobesTextFormField(
                          controller: _tagsCtrl,
                          hintText: "Etiketler (virgül ile ayırın)",
                          prefixIcon: Icons.label_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PhobesSectionHeader(
                    title: l10n.sectionSettings,
                    icon: Icons.tune_rounded,
                  ),
                  PhobesCard(
                    padding: const EdgeInsets.all(16),
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.priority,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPrioritySelector(l10n),
                        const SizedBox(height: 20),
                        Text(
                          l10n.selectColor,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildColorSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (isWide)
                    PhobesButton(
                      text: l10n.save,
                      onPressed: _saveTask,
                      width: double.infinity,
                    ),
                  if (isWide) const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDateTimeTile(String label, DateTime date, bool isStart) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _pickDateTime(isStart),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('d MMM • HH:mm', 'tr').format(date),
              style: GoogleFonts.outfit(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSelector(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<int>(
      initialValue: _reminderMinutes,
      dropdownColor: cs.surfaceContainerHigh,
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: cs.onSurface.withValues(alpha: 0.4)),
      decoration: InputDecoration(
        labelText: l10n.reminder,
        labelStyle: GoogleFonts.outfit(
          color: cs.onSurface.withValues(alpha: 0.4),
          fontSize: 14,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        prefixIcon: Icon(
          Icons.notifications_active_rounded,
          color: cs.primary.withValues(alpha: 0.6),
          size: 20,
        ),
        contentPadding: EdgeInsets.zero,
      ),
      items: [
        _buildReminderItem(-1, l10n.reminderNone, cs),
        _buildReminderItem(0, l10n.reminderAtTime, cs),
        _buildReminderItem(10, l10n.reminder10Min, cs),
        _buildReminderItem(30, l10n.reminder30Min, cs),
        _buildReminderItem(60, l10n.reminder1Hour, cs),
        _buildReminderItem(1440, l10n.reminder1Day, cs),
      ],
      onChanged: (v) => setState(() => _reminderMinutes = v!),
    );
  }

  DropdownMenuItem<int> _buildReminderItem(
      int value, String text, ColorScheme cs) {
    return DropdownMenuItem(
      value: value,
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: cs.onSurface,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildPrioritySelector(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        _buildPriorityBtn(0, l10n.priorityLow, Colors.greenAccent, cs),
        const SizedBox(width: 8),
        _buildPriorityBtn(1, l10n.priorityMedium, Colors.orangeAccent, cs),
        const SizedBox(width: 8),
        _buildPriorityBtn(2, l10n.priorityHigh, Colors.redAccent, cs),
      ],
    );
  }

  Widget _buildPriorityBtn(int p, String label, Color color, ColorScheme cs) {
    final isSelected = _priority == p;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : cs.outline.withValues(alpha: 0.1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? color : cs.onSurface.withValues(alpha: 0.6),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorSelector() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _colors.length,
        itemBuilder: (context, index) {
          final colorInt = _colors[index];
          final isSelected = _color == colorInt;
          final color = Color(colorInt);
          return GestureDetector(
            onTap: () => setState(() => _color = colorInt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDateTime(bool isStart) async {
    final cs = Theme.of(context).colorScheme;
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: cs.copyWith(
            primary: cs.primary,
            onPrimary: cs.onPrimary,
            surface: cs.surfaceContainer,
            onSurface: cs.onSurface,
          ),
          textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _start : _end),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: cs.copyWith(
            primary: cs.primary,
            onPrimary: cs.onPrimary,
            surface: cs.surfaceContainer,
            onSurface: cs.onSurface,
          ),
          textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    final finalDateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _start = finalDateTime;
        if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = finalDateTime;
      }
    });
  }
}
