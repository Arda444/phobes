import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/task_model.dart';
import '../../services/firebase_service.dart';
import '../../services/calendar_sync_service.dart';
import '../../services/notification_service.dart';
import '../../core/navigation_keys.dart';
import '../../widgets/phobes_widgets.dart';
import '../../widgets/phobes_form_wrapper.dart';
import '../../l10n/app_localizations.dart';
import 'package:phobes/utils/time_utils.dart';

class TaskAddEditScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Task? task;
  final String? groupId;
  final String? teamId;
  final VoidCallback? onClose;

  const TaskAddEditScreen({
    super.key,
    required this.selectedDate,
    this.task,
    this.groupId,
    this.teamId,
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
  DateTime? _repeatEndDate;
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
    0xFF009688,
  ];

  void _dismissForm([Object? result]) {
    if (PhobesFormScope.maybeOf(context) != null) {
      PhobesFormScope.closeForm(context, result);
    } else {
      Navigator.of(context).pop(result);
    }
  }

  void _finishSave(String message) {
    if (!mounted) return;
    _dismissForm(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final root = rootNavigatorKey.currentContext;
      if (root != null) {
        PhobesSnackbar.show(
          root,
          message: message,
          type: PhobesSnackbarType.success,
        );
      }
    });
  }

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
    final tid =
        widget.teamId ?? widget.task?.teamId ?? widget.groupId;
    if (tid == null) return;

    try {
      final teamDoc =
          await FirebaseFirestore.instance.collection('teams').doc(tid).get();
      if (!teamDoc.exists) {
        final gid = widget.groupId ?? widget.task?.groupId;
        if (gid == null || gid == tid) return;
        final teamsSnap = await FirebaseFirestore.instance
            .collection('teams')
            .where('memberIds', arrayContains: _firebaseService.currentUserId)
            .get();
        for (final t in teamsSnap.docs) {
          final proj = await t.reference.collection('projects').doc(gid).get();
          if (proj.exists) {
            return _loadMembersForTeam(t.id);
          }
        }
        return;
      }
      await _loadMembersForTeam(tid);
    } catch (e) {
      debugPrint('Üye listesi hatası: $e');
    }
  }

  Future<void> _loadMembersForTeam(String teamId) async {
    try {
      final teamDoc =
          await FirebaseFirestore.instance.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) return;

      final List<dynamic> memberIds = teamDoc.data()?['memberIds'] ?? [];
      final members = await _firebaseService.getUsersByIds(
        memberIds.map((e) => e.toString()).toList(),
        teamId: teamId,
      );

      if (mounted) {
        setState(() => _teamMembers = members);
      }
    } catch (e) {
      debugPrint('Üye listesi hatası: $e');
    }
  }

  String? get _effectiveTeamId =>
      widget.teamId ?? widget.task?.teamId;

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
                        child: Text(l10n.taskMemberNotFound,
                            style: GoogleFonts.outfit(
                                color: cs.onSurface.withValues(alpha: 0.4),),),
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
                  ),
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
        debugPrint('Overlap check error: $e');
      }
    }

    final groupId = widget.task?.groupId ?? widget.groupId;
    final resolvedTeamId = await _firebaseService.resolveTeamIdForTaskScope(
      teamId: widget.task?.teamId ?? widget.teamId ?? _effectiveTeamId,
      groupId: groupId,
    );

    final Task taskToSave = Task(
      id: widget.task?.id,
      userId: widget.task?.userId ??
          (widget.task?.userId == 'device'
              ? 'device'
              : _firebaseService.currentUserId ?? ''),
      groupId: groupId,
      teamId: resolvedTeamId,
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
        taskId = taskToSave.id ?? 'device_task';
      } else {
        String? effectiveUserId = taskToSave.userId;
        if (effectiveUserId.isEmpty) {
          effectiveUserId = _firebaseService.currentUserId;
        }

        if (effectiveUserId == null || effectiveUserId.isEmpty) {
          throw Exception(
              'Kullanıcı kimliği belirlenemedi. Lütfen tekrar giriş yapın.',);
        }

        if (taskToSave.id == null) {
          if (_repeatRule != 'none' && _repeatEndDate != null) {
            // ── Recurring series ─────────────────────────────────────────
            final seriesId = '${effectiveUserId}_${DateTime.now().millisecondsSinceEpoch}';
            final instances = _buildRecurringInstances(taskToSave, seriesId, effectiveUserId);
            await _firebaseService.addRecurringTaskInstances(instances);
            taskId = seriesId;
          } else {
            final createdId = await _firebaseService.addTask(taskToSave);
            if (createdId == null) {
              throw Exception('Görev oluşturulamadı.');
            }
            taskId = createdId;
          }
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
            title: 'Hatırlatıcı: ${_titleCtrl.text}',
            body: _reminderMinutes == 0
                ? 'Görevin zamanı geldi!'
                : '$_reminderMinutes dakika kaldı.',
            scheduledTime: triggerTime,
            type: 'task',
            targetId: taskId,
            targetType: 'task',
            icon: '📋',
            color: 0xFF8B5CF6,
            prefKey: 'notif_task_deadline',
          );
        }
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        if (_repeatRule != 'none' && _repeatEndDate != null) {
          final instances =
              _buildRecurringInstances(taskToSave, taskId, taskToSave.userId);
          _finishSave(l10n.recurringSeriesCreated(instances.length));
        } else {
          _finishSave(
            widget.task == null
                ? 'Görev başarıyla eklendi'
                : 'Görev başarıyla düzenlendi',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        PhobesSnackbar.show(
          context,
          message: 'Görev eklenemedi. Tekrar deneyin.',
          type: PhobesSnackbarType.error,
        );
      }
    }
  }

  /// Generates all Task instances for a recurring series between [base.startTime]
  /// and [_repeatEndDate] (inclusive) using [_repeatRule].
  List<Task> _buildRecurringInstances(Task base, String seriesId, String userId) {
    final duration = base.endTime.difference(base.startTime);
    final endDate = _repeatEndDate!;
    final instances = <Task>[];
    DateTime cursor = base.startTime;

    while (!cursor.isAfter(endDate)) {
      instances.add(base.copyWith(
        startTime: cursor,
        endTime: cursor.add(duration),
        repeatRule: 'none',
        recurrenceGroupId: seriesId,
      ),);
      switch (_repeatRule) {
        case 'daily':
          cursor = cursor.add(const Duration(days: 1));
        case 'weekly':
          cursor = cursor.add(const Duration(days: 7));
        case 'monthly':
          cursor = DateTime(
              cursor.month < 12 ? cursor.year : cursor.year + 1,
              cursor.month < 12 ? cursor.month + 1 : 1,
              cursor.day, cursor.hour, cursor.minute,);
        case 'yearly':
          cursor = DateTime(cursor.year + 1, cursor.month, cursor.day,
              cursor.hour, cursor.minute,);
        default:
          return instances; // unknown rule — stop
      }
    }
    return instances;
  }

  Future<bool?> _showOverlapWarning(String overlapTaskName, String freeSlots) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text(l10n.taskOverlapTitle,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),),
        content: Text(
          l10n.taskOverlapMessage(overlapTaskName, freeSlots),
          style: GoogleFonts.outfit(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(ctx)!.cancel,
                style: TextStyle(
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),),),
          ),
          PhobesButton(
            text: l10n.taskSaveAnyway,
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
                onBackPressed: () => _dismissForm(),
                trailing: TextButton(
                  onPressed: _saveTask,
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),),
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
                  if (isWide) ...[
                    Row(
                      children: [
                        Text(
                          isEdit ? l10n.editTask : l10n.newTask,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (isDeviceTask)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PhobesChip(
                        label: l10n.taskGoogleCalendarEvent,
                        icon: Icons.sync_rounded,
                        isSelected: true,
                        onTap: () {},
                      ),
                    ),
                  if (isTeamContext && !isDeviceTask)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PhobesChip(
                        label: '${l10n.taskContext}: ${l10n.team}',
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
                                    l10n.start, _start, true,),),
                            Container(
                              width: 1,
                              height: 30,
                              color: cs.outline.withValues(alpha: 0.1),
                            ),
                            Expanded(
                                child:
                                    _buildDateTimeTile(l10n.end, _end, false),),
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
                          thumbColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? cs.primary
                                : null,
                          ),
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
                                                {'name': '?', 'surname': ''},);
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
                                color: cs.onSurface.withValues(alpha: 0.4),),
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
                          hintText: l10n.tagsHint,
                          prefixIcon: Icons.label_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!isDeviceTask) ...[
                    const SizedBox(height: 24),
                    PhobesSectionHeader(
                      title: l10n.repeat,
                      icon: Icons.repeat_rounded,
                    ),
                    PhobesCard(
                      padding: const EdgeInsets.all(16),
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRepeatRuleSelector(l10n, cs),
                          if (_repeatRule != 'none') ...[
                            const SizedBox(height: 16),
                            _buildRepeatEndDateRow(l10n, cs),
                          ],
                        ],
                      ),
                    ),
                  ],
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
                  // Toplu Ekle butonu — yeni görev eklerken görünür
                  if (!isEdit && !isDeviceTask)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PhobesButton(
                        text: l10n.bulkAddTasks,
                        icon: Icons.playlist_add_rounded,
                        isOutlined: true,
                        width: double.infinity,
                        onPressed: () => _showBulkAddSheet(context, l10n),
                      ),
                    ),
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
    },);
  }

  Widget _buildDateTimeTile(String label, DateTime date, bool isStart) {
    final cs = Theme.of(context).colorScheme;
    final locale = AppLocalizations.of(context)!.localeName;
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
              DateFormat('d MMM • HH:mm', locale).format(date),
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
          color: cs.onSurface.withValues(alpha: 0.4),),
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
      int value, String text, ColorScheme cs,) {
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

  Widget _buildRepeatRuleSelector(AppLocalizations l10n, ColorScheme cs) {
    final options = [
      ('none', l10n.repeatNone, Icons.block_rounded),
      ('daily', l10n.repeatDaily, Icons.today_rounded),
      ('weekly', l10n.repeatWeekly, Icons.view_week_rounded),
      ('monthly', l10n.repeatMonthly, Icons.calendar_month_rounded),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = _repeatRule == opt.$1;
        return GestureDetector(
          onTap: () => setState(() {
            _repeatRule = opt.$1;
            if (opt.$1 == 'none') _repeatEndDate = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary.withOpacity(0.15)
                  : cs.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? cs.primary.withOpacity(0.5)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(opt.$3,
                    size: 15,
                    color: isSelected
                        ? cs.primary
                        : cs.onSurface.withOpacity(0.5),),
                const SizedBox(width: 6),
                Text(opt.$2,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? cs.primary
                          : cs.onSurface.withOpacity(0.7),
                    ),),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRepeatEndDateRow(AppLocalizations l10n, ColorScheme cs) {
    final locale = l10n.localeName;
    final endLabel = _repeatEndDate != null
        ? DateFormat('d MMM yyyy', locale).format(_repeatEndDate!)
        : l10n.taskRepeatEndSelect;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _repeatEndDate ??
              _start.add(const Duration(days: 30)),
          firstDate: _start.add(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (picked != null) setState(() => _repeatEndDate = picked);
      },
      child: Row(
        children: [
          Icon(Icons.event_rounded,
              size: 18, color: cs.primary.withOpacity(0.7),),
          const SizedBox(width: 10),
          Text('${l10n.taskRepeatEndLabel}  ',
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: cs.onSurface.withOpacity(0.5),),),
          Text(endLabel,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _repeatEndDate != null
                      ? cs.onSurface
                      : cs.primary,),),
          const Spacer(),
          if (_repeatEndDate != null)
            GestureDetector(
              onTap: () => setState(() => _repeatEndDate = null),
              child: Icon(Icons.close_rounded,
                  size: 16, color: cs.onSurface.withOpacity(0.4),),
            ),
        ],
      ),
    );
  }

  /// Shows a bottom sheet for adding multiple tasks at once.
  /// Each non-empty line becomes a separate task with the same
  /// date/time/priority/color settings.
  void _showBulkAddSheet(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final textCtrl = TextEditingController();

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => PhobesBottomSheet(
          title: l10n.bulkAddTasks,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: cs.primary,),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l10n.bulkAddInfo,
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: cs.primary.withOpacity(0.8),),),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Multi-line text area
                TextField(
                  controller: textCtrl,
                  maxLines: 8,
                  autofocus: true,
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l10n.bulkAddHint,
                    hintStyle: GoogleFonts.outfit(
                        color: cs.onSurface.withOpacity(0.4),),
                    filled: true,
                    fillColor: cs.onSurface.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: cs.outline.withOpacity(0.2),),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: cs.outline.withOpacity(0.15),),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: cs.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  onChanged: (_) => setSheet(() {}),
                ),
                const SizedBox(height: 12),
                // Preview count
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: textCtrl,
                  builder: (_, val, __) {
                    final count = val.text
                        .split('\n')
                        .where((l) => l.trim().isNotEmpty)
                        .length;
                    if (count == 0) return const SizedBox.shrink();
                    return Text(
                      l10n.bulkAddCount(count),
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: cs.primary,
                          fontWeight: FontWeight.w600,),
                    );
                  },
                ),
                const SizedBox(height: 20),
                PhobesButton(
                  text: l10n.save,
                  width: double.infinity,
                  onPressed: () async {
                    final titles = textCtrl.text
                        .split('\n')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();
                    if (titles.isEmpty) return;

                    final uid = _firebaseService.currentUserId;
                    if (uid == null || uid.isEmpty) return;

                    final duration = _end.difference(_start);
                    final tasks = titles
                        .map(
                          (titleText) => Task(
                            userId: uid,
                            title: titleText,
                            description: _descCtrl.text,
                            startTime: _start,
                            endTime: _start.add(duration),
                            isAllDay: _allDay,
                            color: _color,
                            priority: _priority,
                            reminderMinutes: _reminderMinutes,
                            groupId: widget.groupId,
                            teamId: widget.teamId,
                          ),
                        )
                        .toList();
                    for (final t in tasks) {
                      await _firebaseService.addTask(t);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      _finishSave(
                        l10n.recurringSeriesCreated(titles.length),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() => textCtrl.dispose());
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
                        ),
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
