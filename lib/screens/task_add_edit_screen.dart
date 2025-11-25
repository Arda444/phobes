import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../services/firebase_service.dart';
import '../l10n/app_localizations.dart';

class TaskAddEditScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Task? task;
  final String? groupId;

  const TaskAddEditScreen({
    super.key,
    required this.selectedDate,
    this.task,
    this.groupId,
  });

  @override
  State<TaskAddEditScreen> createState() => _TaskAddEditScreenState();
}

class _TaskAddEditScreenState extends State<TaskAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();

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

  // GÖREV ATAMA (YENİ)
  String? _assignedTo;
  List<Map<String, dynamic>> _teamMembers = [];

  late final Map<String, String> _repeatOptions;
  bool _l10nInitialized = false;

  final List<int> _colors = [
    0xFF4285F4,
    0xFF34A853,
    0xFFFBBC04,
    0xFFEA4335,
    0xFF9AA0A6,
    0xFF8E24AA,
    0xFFF06292,
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

    _assignedTo = widget.task?.assignedTo;

    // Eğer ekip görevi ise üyeleri yükle
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
        setState(() {
          _teamMembers = members;
        });
      }
    } catch (e) {
      debugPrint("Üye listesi hatası: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_l10nInitialized) {
      final l10n = AppLocalizations.of(context)!;
      _repeatOptions = {
        'none': l10n.repeatNone,
        'daily': l10n.repeatDaily,
        'weekly': l10n.repeatWeekly,
        'monthly': l10n.repeatMonthly,
      };
      _l10nInitialized = true;
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

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final List<String> tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final Task task = Task(
      // Nova'dan gelen görevlerde ID null olduğu için burası null kalır, düzenlemede ise dolar.
      id: widget.task?.id,
      userId: widget.task?.userId ?? '',
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
      assignedTo: _assignedTo,
      createdBy: widget.task?.createdBy ?? _firebaseService.currentUserId,
    );

    try {
      // --- KRİTİK DÜZELTME: ID KONTROLÜ ---
      // Eğer widget.task null ise VEYA task var ama ID'si null ise (Nova'dan gelen)
      // bunu YENİ GÖREV (addTask) olarak kaydet.
      if (widget.task == null || widget.task?.id == null) {
        await _firebaseService.addTask(task);
      } else {
        // Aksi takdirde güncelle (updateTask)
        await _firebaseService.updateTask(task);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hata oluştu: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(isEdit ? l10n.editTask : l10n.newTask,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.white)),
        leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
              onPressed: _saveTask,
              child: Text(l10n.save,
                  style: GoogleFonts.poppins(
                      color: Colors.purple.shade300,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)))
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.groupId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Chip(
                        avatar: const Icon(Icons.group_work, size: 16),
                        label: Text("${l10n.taskContext}: ${l10n.team}"),
                        backgroundColor: Colors.indigo.shade900),
                  ),
                TextFormField(
                    controller: _titleCtrl,
                    style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    decoration: InputDecoration(
                        hintText: l10n.title,
                        hintStyle: GoogleFonts.poppins(color: Colors.white24),
                        border: InputBorder.none),
                    validator: (v) =>
                        v?.isEmpty == true ? l10n.requiredField : null),
                const SizedBox(height: 20),

                _buildSectionHeader(
                    l10n.sectionTiming, Icons.access_time_rounded),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10)),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                          child: _buildDateTimeTile(l10n.start, _start, true)),
                      Container(width: 1, height: 40, color: Colors.white10),
                      Expanded(child: _buildDateTimeTile(l10n.end, _end, false))
                    ]),
                    const Divider(color: Colors.white10, height: 30),
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.allDay,
                            style: GoogleFonts.poppins(color: Colors.white)),
                        value: _allDay,
                        activeTrackColor: Colors.purple.shade400,
                        onChanged: (v) => setState(() => _allDay = v)),
                    _buildRepeatDropdown(),
                  ]),
                ),
                const SizedBox(height: 20),

                // GÖREV ATAMA KISMI (Ekip Göreviyse)
                if (_teamMembers.isNotEmpty) ...[
                  _buildSectionHeader("Görev Atama", Icons.person_add_alt),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10)),
                    child: DropdownButtonFormField<String>(
                      initialValue: _assignedTo,
                      decoration:
                          const InputDecoration(border: InputBorder.none),
                      dropdownColor: Colors.grey.shade800,
                      style: GoogleFonts.poppins(color: Colors.white),
                      hint: const Text("Kime atanacak?",
                          style: TextStyle(color: Colors.grey)),
                      items: [
                        const DropdownMenuItem(
                            value: null,
                            child: Text("Kimse (Herkes Görebilir)")),
                        ..._teamMembers.map((m) => DropdownMenuItem(
                              value: m['id'].toString(),
                              child: Text("${m['name']} ${m['surname']}"),
                            ))
                      ],
                      onChanged: (val) => setState(() => _assignedTo = val),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                _buildSectionHeader(
                    l10n.sectionDetails, Icons.article_outlined),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10)),
                  child: Column(children: [
                    _buildTextField(
                        controller: _descCtrl,
                        hint: l10n.descriptionOptional,
                        icon: Icons.notes_rounded,
                        maxLines: 3),
                    const Divider(color: Colors.white10),
                    _buildTextField(
                        controller: _locCtrl,
                        hint: l10n.locationOptional,
                        icon: Icons.location_on_outlined),
                    const Divider(color: Colors.white10),
                    _buildTextField(
                        controller: _urlCtrl,
                        hint: l10n.linkOptional,
                        icon: Icons.link_rounded,
                        keyboardType: TextInputType.url),
                  ]),
                ),
                const SizedBox(height: 20),

                _buildSectionHeader(l10n.sectionSettings, Icons.tune_rounded),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPrioritySelector(),
                        const SizedBox(height: 16),
                        _buildReminderDropdown(),
                        const SizedBox(height: 16),
                        Text(l10n.tagsHint,
                            style: GoogleFonts.poppins(
                                color: Colors.grey, fontSize: 12)),
                        _buildTextField(
                            controller: _tagsCtrl,
                            hint: l10n.tagsHint,
                            icon: Icons.label_outline),
                        const SizedBox(height: 16),
                        _buildColorSelector(),
                      ]),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Row(children: [
          Icon(icon, size: 18, color: Colors.purple.shade300),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.poppins(
                  color: Colors.purple.shade300,
                  fontWeight: FontWeight.w600,
                  fontSize: 14))
        ]));
  }

  Widget _buildDateTimeTile(String label, DateTime date, bool isStart) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
        onTap: () => _pickDateTime(isStart),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                  _allDay
                      ? DateFormat('d MMM yyyy', l10n.localeName).format(date)
                      : DateFormat('d MMM • HH:mm', l10n.localeName)
                          .format(date),
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15))
            ])));
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      int maxLines = 1,
      TextInputType? keyboardType}) {
    return TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
            prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12)));
  }

  Widget _buildPrioritySelector() {
    final l10n = AppLocalizations.of(context)!;
    return Row(children: [
      const Icon(Icons.flag_rounded, color: Colors.grey, size: 20),
      const SizedBox(width: 12),
      Expanded(
          child: SegmentedButton<int>(
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected)
                          ? (_priority == 0
                              ? Colors.green.shade800
                              : (_priority == 1
                                  ? Colors.orange.shade800
                                  : Colors.red.shade800))
                          : Colors.transparent),
                  foregroundColor: WidgetStateProperty.all(Colors.white)),
              segments: [
                ButtonSegment(
                    value: 0,
                    label: Text(l10n.priorityLow),
                    icon: const Icon(Icons.low_priority)),
                ButtonSegment(value: 1, label: Text(l10n.priorityMedium)),
                ButtonSegment(
                    value: 2,
                    label: Text(l10n.priorityHigh),
                    icon: const Icon(Icons.priority_high))
              ],
              selected: {_priority},
              onSelectionChanged: (newSet) =>
                  setState(() => _priority = newSet.first)))
    ]);
  }

  Widget _buildReminderDropdown() {
    final l10n = AppLocalizations.of(context)!;
    return Row(children: [
      const Icon(Icons.notifications_none_rounded,
          color: Colors.grey, size: 20),
      const SizedBox(width: 12),
      Expanded(
          child: DropdownButtonFormField<int>(
              initialValue: _reminderMinutes,
              dropdownColor: Colors.grey.shade800,
              decoration: const InputDecoration(border: InputBorder.none),
              style: GoogleFonts.poppins(color: Colors.white),
              items: [
                DropdownMenuItem(value: -1, child: Text(l10n.reminderNone)),
                DropdownMenuItem(value: 0, child: Text(l10n.reminderAtTime)),
                DropdownMenuItem(value: 10, child: Text(l10n.reminder10Min)),
                DropdownMenuItem(value: 60, child: Text(l10n.reminder1Hour)),
                DropdownMenuItem(value: 1440, child: Text(l10n.reminder1Day))
              ],
              onChanged: (v) => setState(() => _reminderMinutes = v!)))
    ]);
  }

  Widget _buildRepeatDropdown() {
    final l10n = AppLocalizations.of(context)!;
    return Row(children: [
      Text(l10n.repeat, style: GoogleFonts.poppins(color: Colors.white)),
      const SizedBox(width: 16),
      Expanded(
          child: DropdownButtonFormField<String>(
              initialValue: _repeatRule,
              dropdownColor: Colors.grey.shade800,
              decoration: const InputDecoration(border: InputBorder.none),
              style: GoogleFonts.poppins(
                  color: Colors.purple.shade200, fontWeight: FontWeight.w600),
              items: _repeatOptions.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _repeatRule = v!)))
    ]);
  }

  Widget _buildColorSelector() {
    final l10n = AppLocalizations.of(context)!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.selectColor,
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 8),
      SizedBox(
          height: 40,
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final colorInt = _colors[index];
                final isSelected = _color == colorInt;
                return GestureDetector(
                    onTap: () => setState(() => _color = colorInt),
                    child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: Color(colorInt),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2.5)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: Color(colorInt)
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8)
                                  ]
                                : null),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 20, color: Colors.white)
                            : null));
              }))
    ]);
  }

  Future<void> _pickDateTime(bool isStart) async {
    final currentTheme = Theme.of(context);
    final date = await showDatePicker(
        context: context,
        initialDate: isStart ? _start : _end,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 730)),
        builder: (context, child) => Theme(
            data: currentTheme.copyWith(
                colorScheme: const ColorScheme.dark(
                    primary: Colors.purple,
                    onPrimary: Colors.white,
                    surface: Colors.grey,
                    onSurface: Colors.white)),
            child: child!));
    if (date == null || !mounted) return;
    if (_allDay) {
      setState(() {
        if (isStart) {
          _start = DateTime(date.year, date.month, date.day);
        } else {
          _end = DateTime(date.year, date.month, date.day);
        }
      });
      return;
    }
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _start : _end),
        builder: (context, child) => Theme(
            data: currentTheme.copyWith(
                colorScheme: const ColorScheme.dark(
                    primary: Colors.purple, onPrimary: Colors.white)),
            child: child!));
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
