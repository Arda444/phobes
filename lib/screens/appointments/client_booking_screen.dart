import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/appointment_model.dart';
import '../../models/appointment_group_model.dart';
import '../../services/appointment_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_widgets.dart';

class ClientBookingScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const ClientBookingScreen({super.key, this.onClose});
  @override
  State<ClientBookingScreen> createState() => _ClientBookingScreenState();
}

class _ClientBookingScreenState extends State<ClientBookingScreen> {
  final AppointmentService _service = AppointmentService();
  int _step = 0;
  AppointmentGroup? _group;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<DateTime> _availableSlots = [];
  DateTime? _selectedSlot;
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _findGroup() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    final group = await _service.getServiceByCode(code);
    if (group != null) {
      setState(() {
        _group = group;
        _step = 1;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.invalidAppointmentCode)),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _loadSlots(DateTime day) async {
    if (_group == null) return;
    setState(() => _loading = true);
    final slots = await _service.getAvailableSlots(_group!, day);
    setState(() {
      _selectedDay = day;
      _availableSlots = slots;
      _selectedSlot = null;
      _loading = false;
    });
  }

  Future<void> _book() async {
    if (_selectedSlot == null ||
        _group == null ||
        _nameCtrl.text.trim().isEmpty) {
      return;
    }
    setState(() => _loading = true);
    final appt = Appointment(
      userId: _group!.ownerId,
      clientId: _service.currentUserId,
      groupId: _group!.id,
      title: _group!.title,
      clientName: _nameCtrl.text.trim(),
      phoneNumber:
          _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      date: _selectedSlot!,
      durationMinutes: _group!.durationMinutes,
      color: _group!.color,
      price: _group!.price,
      currency: _group!.currency,
    );
    final bookingId = await _service.bookClientAppointment(appt);
    if (!mounted) return;
    if (bookingId == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.apptSlotTaken)),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.msgAppointmentSent)),
      );
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                  child: Row(
                    children: [
                      PhobesIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {
                          if (_step > 0) {
                            setState(() => _step--);
                          } else if (widget.onClose != null) {
                            widget.onClose!();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.bookAppointment,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: List.generate(
                      3,
                      (i) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 4,
                            decoration: BoxDecoration(
                              color: i == _step
                                  ? cs.primary
                                  : i < _step
                                      ? cs.primary.withOpacity(0.4)
                                      : cs.surfaceVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _step == 0
                        ? _codeStep(l10n, cs)
                        : _step == 1
                            ? _calendarStep(l10n, cs)
                            : _infoStep(l10n, cs),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _codeStep(AppLocalizations l10n, ColorScheme cs) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner_rounded,
                size: 64, color: cs.primary.withOpacity(0.3)),
            const SizedBox(height: 24),
            Text(l10n.appointmentCode,
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              l10n.enterServiceCodeHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  color: cs.onSurface.withOpacity(0.4), fontSize: 13),
            ),
            const SizedBox(height: 24),
            PhobesTextFormField(
                controller: _codeCtrl,
                hintText: 'BOOK-XXXXXX',
                prefixIcon: Icons.key_rounded),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: PhobesButton(
                text: l10n.btnContinue,
                icon: Icons.arrow_forward_rounded,
                isLoading: _loading,
                onPressed: _findGroup,
              ),
            ),
          ],
        ),
      );

  Widget _calendarStep(AppLocalizations l10n, ColorScheme cs) {
    final color = Color(_group?.color ?? 0xFF8B5CF6);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_group != null)
            PhobesGlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        Icon(Icons.storefront_rounded, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_group!.title,
                            style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface)),
                        Text(
                          '${_group!.businessName} • ${l10n.apptMinutes(_group!.durationMinutes)}',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.4)),
                        ),
                      ],
                    ),
                  ),
                  if (_group!.price > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        '${_group!.price.toStringAsFixed(0)} ${_group!.currency}',
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            enabledDayPredicate: (d) =>
                _group?.workingDays.contains(d.weekday) ?? false,
            onDaySelected: (sel, foc) {
              setState(() => _focusedDay = foc);
              _loadSlots(sel);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.15), shape: BoxShape.circle),
              selectedDecoration:
                  BoxDecoration(color: cs.primary, shape: BoxShape.circle),
              todayTextStyle: GoogleFonts.outfit(
                  color: cs.primary, fontWeight: FontWeight.w700),
              disabledTextStyle:
                  GoogleFonts.outfit(color: cs.onSurface.withOpacity(0.15)),
              defaultTextStyle: GoogleFonts.outfit(color: cs.onSurface),
              weekendTextStyle:
                  GoogleFonts.outfit(color: cs.onSurface.withOpacity(0.5)),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600, color: cs.onSurface),
            ),
            locale: l10n.localeName,
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: PhobesLoadingIndicator())
          else if (_selectedDay != null && _availableSlots.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.apptNoSlots,
                    style: GoogleFonts.outfit(
                        color: cs.onSurface.withOpacity(0.3))),
              ),
            )
          else if (_availableSlots.isNotEmpty) ...[
            Text(
              DateFormat('d MMMM', l10n.localeName).format(_selectedDay!),
              style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSlots.map((slot) {
                final sel = _selectedSlot != null && slot == _selectedSlot;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSlot = slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? cs.primary : cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              sel ? cs.primary : cs.outline.withOpacity(0.15)),
                    ),
                    child: Text(
                      DateFormat('HH:mm').format(slot),
                      style: GoogleFonts.outfit(
                          color: sel ? cs.onPrimary : cs.onSurface,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedSlot != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: PhobesButton(
                  text: l10n.btnContinue,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => setState(() => _step = 2),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _infoStep(AppLocalizations l10n, ColorScheme cs) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.completeBooking,
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            if (_selectedSlot != null)
              Text(
                '${_group?.title} • ${DateFormat('d MMM, HH:mm', l10n.localeName).format(_selectedSlot!)}',
                style: GoogleFonts.outfit(
                    color: cs.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 24),
            PhobesTextFormField(
                controller: _nameCtrl,
                labelText: l10n.name,
                prefixIcon: Icons.person_rounded),
            const SizedBox(height: 14),
            PhobesTextFormField(
                controller: _phoneCtrl,
                labelText: l10n.phone,
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: PhobesButton(
                text: l10n.btnConfirm,
                icon: Icons.check_rounded,
                isLoading: _loading,
                onPressed: _book,
              ),
            ),
          ],
        ),
      );
}
