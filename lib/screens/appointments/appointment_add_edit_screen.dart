import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../services/firebase_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_widgets.dart';
import '../../core/phobes_theme.dart';

class AppointmentAddEditScreen extends StatefulWidget {
  final Appointment? appointment;
  final VoidCallback? onClose;
  const AppointmentAddEditScreen({super.key, this.appointment, this.onClose});

  @override
  State<AppointmentAddEditScreen> createState() =>
      _AppointmentAddEditScreenState();
}

class _AppointmentAddEditScreenState extends State<AppointmentAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _duration = 60;
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    if (widget.appointment != null) {
      _titleCtrl.text = widget.appointment!.title;
      _clientCtrl.text = widget.appointment!.clientName;
      _phoneCtrl.text = widget.appointment!.phoneNumber ?? "";
      _notesCtrl.text = widget.appointment!.notes ?? "";
      _selectedDate = widget.appointment!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.appointment!.date);
      _duration = widget.appointment!.durationMinutes;
      _status = widget.appointment!.status;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final DateTime finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute);

    final appt = Appointment(
      id: widget.appointment?.id,
      userId: "",
      groupId: widget.appointment?.groupId,
      title: _titleCtrl.text,
      clientName: _clientCtrl.text,
      phoneNumber: _phoneCtrl.text,
      date: finalDateTime,
      durationMinutes: _duration,
      notes: _notesCtrl.text,
      status: _status,
    );

    if (widget.appointment == null) {
      await FirebaseService().addAppointment(appt);
    } else {
      await FirebaseService().updateAppointment(appt);
    }

    if (mounted) {
      if (widget.onClose != null) {
        widget.onClose!();
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.appointment != null;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;

    return Scaffold(
      backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
      appBar: PhobesPremiumAppBar(
        title: isEdit ? l10n.edit : l10n.bookNewAppointment,
        onBackPressed: () {
          if (widget.onClose != null) {
            widget.onClose!();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhobesTextFormField(
                    controller: _titleCtrl,
                    labelText: l10n.serviceTitle,
                    prefixIcon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 16),
                  PhobesTextFormField(
                    controller: _clientCtrl,
                    labelText: l10n.labelClient,
                    prefixIcon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 16),
                  PhobesTextFormField(
                    controller: _phoneCtrl,
                    labelText: "Telefon",
                    prefixIcon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: PhobesCard(
                          margin: EdgeInsets.zero,
                          padding: const EdgeInsets.all(16),
                          onTap: () async {
                            final d = await showDatePicker(
                                context: context,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                                initialDate: _selectedDate);
                            if (d != null) setState(() => _selectedDate = d);
                          },
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  color: cs.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  DateFormat('d MMM yyyy', l10n.localeName)
                                      .format(_selectedDate),
                                  style: GoogleFonts.outfit(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PhobesCard(
                          margin: EdgeInsets.zero,
                          padding: const EdgeInsets.all(16),
                          onTap: () async {
                            final t = await showTimePicker(
                                context: context, initialTime: _selectedTime);
                            if (t != null) setState(() => _selectedTime = t);
                          },
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded,
                                  color: cs.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedTime.format(context),
                                  style: GoogleFonts.outfit(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isEdit) ...[
                    DropdownButtonFormField<String>(
                        initialValue: _status,
                        dropdownColor: cs.surfaceContainerHigh,
                        style: GoogleFonts.outfit(color: cs.onSurface),
                        icon:
                            Icon(Icons.expand_more_rounded, color: cs.primary),
                        decoration: InputDecoration(
                            labelText: l10n.taskStatus,
                            labelStyle: GoogleFonts.outfit(
                                color: cs.onSurface.withValues(alpha: 0.5)),
                            filled: true,
                            fillColor: cs.surfaceContainer,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none)),
                        items: [
                          DropdownMenuItem(
                              value: 'pending',
                              child: Text(l10n.statusPending)),
                          DropdownMenuItem(
                              value: 'confirmed',
                              child: Text(l10n.statusConfirmed)),
                          DropdownMenuItem(
                              value: 'completed',
                              child: Text(l10n.statusCompleted)),
                          DropdownMenuItem(
                              value: 'cancelled',
                              child: Text(l10n.statusCancelled)),
                        ],
                        onChanged: (v) => setState(() => _status = v!)),
                    const SizedBox(height: 16),
                  ],
                  PhobesTextFormField(
                    controller: _notesCtrl,
                    labelText: l10n.labelNote,
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 40),
                  PhobesButton(
                    width: double.infinity,
                    onPressed: _save,
                    text: l10n.save,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _clientCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
