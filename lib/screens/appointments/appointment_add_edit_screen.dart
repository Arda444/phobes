import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/appointment_group_model.dart';
import '../../services/appointment_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_widgets.dart';

class AppointmentAddEditScreen extends StatefulWidget {
  final Appointment? appointment;
  final DateTime? initialDate;
  final VoidCallback? onClose;

  const AppointmentAddEditScreen({
    super.key,
    this.appointment,
    this.initialDate,
    this.onClose,
  });

  @override
  State<AppointmentAddEditScreen> createState() =>
      _AppointmentAddEditScreenState();
}

class _AppointmentAddEditScreenState extends State<AppointmentAddEditScreen> {
  final AppointmentService _service = AppointmentService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _clientCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _priceCtrl;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _durationMinutes = 60;
  int _selectedColor = 0xFF8B5CF6;
  int _reminderMinutes = 30;
  String _recurrence = 'none';
  bool _isSaving = false;

  bool get _isEditing => widget.appointment != null;

  @override
  void initState() {
    super.initState();
    final appt = widget.appointment;
    _titleCtrl = TextEditingController(text: appt?.title ?? '');
    _clientCtrl = TextEditingController(text: appt?.clientName ?? '');
    _phoneCtrl = TextEditingController(text: appt?.phoneNumber ?? '');
    _emailCtrl = TextEditingController(text: appt?.email ?? '');
    _notesCtrl = TextEditingController(text: appt?.notes ?? '');
    _priceCtrl = TextEditingController(
      text: appt != null && appt.price > 0 ? appt.price.toStringAsFixed(0) : '',
    );

    if (appt != null) {
      _selectedDate = appt.date;
      _selectedTime = TimeOfDay(hour: appt.date.hour, minute: appt.date.minute);
      _durationMinutes = appt.durationMinutes;
      _selectedColor = appt.color;
      _reminderMinutes = appt.reminderMinutes;
      _recurrence = appt.recurrence;
    } else if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
      _selectedTime = TimeOfDay(
        hour: widget.initialDate!.hour,
        minute: widget.initialDate!.minute,
      );
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _clientCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final price = double.tryParse(_priceCtrl.text) ?? 0.0;

    final appt = Appointment(
      id: widget.appointment?.id,
      userId: _service.currentUserId ?? '',
      title: _titleCtrl.text.trim(),
      clientName: _clientCtrl.text.trim(),
      phoneNumber:
          _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      date: date,
      durationMinutes: _durationMinutes,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      color: _selectedColor,
      price: price,
      reminderMinutes: _reminderMinutes,
      recurrence: _recurrence,
      status: widget.appointment?.status ?? 'confirmed',
    );

    final l10n = AppLocalizations.of(context)!;
    try {
      if (_isEditing) {
        await _service.updateAppointment(appt);
      } else {
        await _service.addAppointment(appt);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.apptSaved)));
        if (widget.onClose != null) {
          widget.onClose!();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .budgetErrorWithDetail(e.toString()))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Row(
                children: [
                  PhobesIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing ? l10n.btnEdit : l10n.apptQuickAdd,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  PhobesButton(
                    text: l10n.btnSave,
                    icon: Icons.check_rounded,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 800;
                  final leftCol = [
                    PhobesTextFormField(
                      controller: _titleCtrl,
                      labelText: l10n.serviceTitle,
                      prefixIcon: Icons.edit_rounded,
                      validator: (v) => v == null || v.isEmpty
                          ? l10n.fillAllFieldsPrompt
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _sectionHeader(l10n.labelClient, Icons.person_rounded, cs),
                    const SizedBox(height: 10),
                    PhobesTextFormField(
                      controller: _clientCtrl,
                      labelText: l10n.name,
                      prefixIcon: Icons.badge_rounded,
                      validator: (v) => v == null || v.isEmpty
                          ? l10n.fillAllFieldsPrompt
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: PhobesTextFormField(
                            controller: _phoneCtrl,
                            labelText: l10n.phone,
                            prefixIcon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PhobesTextFormField(
                            controller: _emailCtrl,
                            labelText: l10n.apptClientEmail,
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sectionHeader(
                        l10n.labelDate, Icons.calendar_month_rounded, cs),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _DateTimeCard(
                            icon: Icons.calendar_today_rounded,
                            label: DateFormat('d MMM yyyy', l10n.localeName)
                                .format(_selectedDate),
                            onTap: () => _pickDate(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateTimeCard(
                            icon: Icons.access_time_rounded,
                            label: _selectedTime.format(context),
                            onTap: () => _pickTime(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _sectionHeader(l10n.duration, Icons.timer_rounded, cs),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [15, 30, 45, 60, 90, 120].map((d) {
                        final sel = _durationMinutes == d;
                        return ChoiceChip(
                          label: Text(l10n.apptMinutes(d)),
                          selected: sel,
                          onSelected: (_) =>
                              setState(() => _durationMinutes = d),
                          selectedColor: cs.primary.withOpacity(0.15),
                          labelStyle: GoogleFonts.outfit(
                            color: sel
                                ? cs.primary
                                : cs.onSurface.withOpacity(0.5),
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    PhobesTextFormField(
                      controller: _priceCtrl,
                      labelText: l10n.price,
                      prefixIcon: Icons.payments_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ];
                  final rightCol = [
                    _sectionHeader(
                        l10n.apptServiceColor, Icons.palette_rounded, cs),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: AppointmentGroup.serviceColors.map((c) {
                        final sel = _selectedColor == c;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: sel
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                          color: Color(c).withOpacity(0.5),
                                          blurRadius: 10)
                                    ]
                                  : null,
                            ),
                            child: sel
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _sectionHeader(
                        l10n.apptReminder, Icons.notifications_rounded, cs),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        (-1, l10n.apptReminderNone),
                        (0, l10n.apptReminderAtTime),
                        (10, l10n.apptReminder10Min),
                        (30, l10n.apptReminder30Min),
                        (60, l10n.apptReminder1Hour),
                        (1440, l10n.apptReminder1Day),
                      ].map((opt) {
                        final sel = _reminderMinutes == opt.$1;
                        return ChoiceChip(
                          label: Text(opt.$2),
                          selected: sel,
                          onSelected: (_) =>
                              setState(() => _reminderMinutes = opt.$1),
                          selectedColor: cs.primary.withOpacity(0.15),
                          labelStyle: GoogleFonts.outfit(
                            fontSize: 12,
                            color: sel
                                ? cs.primary
                                : cs.onSurface.withOpacity(0.5),
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _sectionHeader(
                        l10n.apptRecurrence, Icons.repeat_rounded, cs),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        ('none', l10n.apptRecurrenceNone),
                        ('weekly', l10n.apptRecurrenceWeekly),
                        ('biweekly', l10n.apptRecurrenceBiweekly),
                        ('monthly', l10n.apptRecurrenceMonthly),
                      ].map((r) {
                        final sel = _recurrence == r.$1;
                        return ChoiceChip(
                          label: Text(r.$2),
                          selected: sel,
                          onSelected: (_) => setState(() => _recurrence = r.$1),
                          selectedColor: cs.primary.withOpacity(0.15),
                          labelStyle: GoogleFonts.outfit(
                            fontSize: 12,
                            color: sel
                                ? cs.primary
                                : cs.onSurface.withOpacity(0.5),
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    PhobesTextFormField(
                      controller: _notesCtrl,
                      labelText: l10n.labelNote,
                      prefixIcon: Icons.note_alt_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        child: PhobesButton(
                          text: l10n.apptDeleteAppointment,
                          icon: Icons.delete_rounded,
                          backgroundColor: cs.error,
                          onPressed: () => _deleteAppointment(context),
                        ),
                      ),
                  ];
                  return Form(
                    key: _formKey,
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 12, 10, 32),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: leftCol,
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                color: cs.outline.withOpacity(0.08),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 12, 20, 32),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: rightCol,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...leftCol,
                                const SizedBox(height: 20),
                                ...rightCol
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
    );
  }

  Widget _sectionHeader(String title, IconData icon, ColorScheme cs) {
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime(BuildContext context) async {
    final time =
        await showTimePicker(context: context, initialTime: _selectedTime);
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _deleteAppointment(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.apptDeleteAppointment),
        content: Text(l10n.apptDeleteAppointmentConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.btnCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.btnDelete, style: TextStyle(color: cs.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && widget.appointment?.id != null) {
      await _service.deleteAppointment(widget.appointment!.id!);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.apptAppointmentDeleted)),
      );
      if (widget.onClose != null) {
        widget.onClose!();
      } else {
        nav.pop();
      }
    }
  }

  ColorScheme get cs => Theme.of(context).colorScheme;
}

class _DateTimeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DateTimeCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.outfit(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
