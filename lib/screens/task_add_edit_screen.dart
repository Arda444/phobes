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

  // ÇOKLU ATAMA İÇİN
  List<String> _assignedToIds = [];
  List<Map<String, dynamic>> _teamMembers = [];

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

    _assignedToIds = widget.task?.assignedTo ?? [];

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

  // ÇOKLU SEÇİM DİYALOĞU
  void _showMultiSelectDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        // Dialog içinde state yönetimi için StatefulBuilder
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text("Kişileri Seç",
                  style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _teamMembers.length,
                  itemBuilder: (context, index) {
                    final member = _teamMembers[index];
                    final isSelected = _assignedToIds.contains(member['id']);

                    return CheckboxListTile(
                      activeColor: const Color(0xFF7B1FA2),
                      title: Text("${member['name']} ${member['surname']}",
                          style: const TextStyle(color: Colors.white)),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _assignedToIds.add(member['id']);
                          } else {
                            _assignedToIds.remove(member['id']);
                          }
                        });
                        // Ana ekranı da güncelle ki Avatar Stack anlık değişsin
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Tamam"),
                )
              ],
            );
          },
        );
      },
    );
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
    if (!_formKey.currentState!.validate()) return;

    final List<String> tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final Task task = Task(
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
      assignedTo: _assignedToIds, // LİSTE OLARAK GÖNDER
      createdBy: widget.task?.createdBy ?? _firebaseService.currentUserId,
      status: widget.task?.status ?? 'todo',
    );

    try {
      if (widget.task == null || widget.task?.id == null) {
        await _firebaseService.addTask(task);
      } else {
        await _firebaseService.updateTask(task);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hata oluştu: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.task != null;

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

                // ZAMANLAMA
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
                  ]),
                ),
                const SizedBox(height: 20),

                // ÇOKLU ATAMA BÖLÜMÜ
                if (_teamMembers.isNotEmpty) ...[
                  _buildSectionHeader("Görev Atama", Icons.person_add_alt),
                  GestureDetector(
                    onTap: _showMultiSelectDialog,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10)),
                      child: Row(
                        children: [
                          Expanded(
                            child: _assignedToIds.isEmpty
                                ? const Text("Atanacak kişileri seç...",
                                    style: TextStyle(color: Colors.grey))
                                : Wrap(
                                    spacing: 8,
                                    children: _assignedToIds.map((id) {
                                      final member = _teamMembers.firstWhere(
                                          (m) => m['id'] == id,
                                          orElse: () =>
                                              {'name': '?', 'surname': ''});
                                      return Chip(
                                        label: Text(
                                            "${member['name']} ${member['surname'][0]}."),
                                        backgroundColor:
                                            Colors.teal.withValues(alpha: 0.2),
                                        labelStyle: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.tealAccent),
                                        padding: EdgeInsets.zero,
                                      );
                                    }).toList(),
                                  ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // DİĞER DETAYLAR
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
                        controller: _urlCtrl,
                        hint: l10n.linkOptional,
                        icon: Icons.link_rounded,
                        keyboardType: TextInputType.url),
                  ]),
                ),
                const SizedBox(height: 20),

                // AYARLAR (Öncelik vb.)
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
                        Text(l10n.priority,
                            style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 8),
                        _buildPrioritySelector(),
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

  // --- UI Widgetları (Aynen korundu) ---
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
    return InkWell(
        onTap: () => _pickDateTime(isStart),
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(DateFormat('d MMM • HH:mm').format(date),
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
    return Row(children: [
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
              segments: const [
                ButtonSegment(value: 0, label: Text("Düşük")),
                ButtonSegment(value: 1, label: Text("Orta")),
                ButtonSegment(value: 2, label: Text("Yüksek"))
              ],
              selected: {_priority},
              onSelectionChanged: (newSet) =>
                  setState(() => _priority = newSet.first)))
    ]);
  }

  Widget _buildColorSelector() {
    return SizedBox(
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
                              : null),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 20, color: Colors.white)
                          : null));
            }));
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
        context: context,
        initialDate: isStart ? _start : _end,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 730)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _start : _end));
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
