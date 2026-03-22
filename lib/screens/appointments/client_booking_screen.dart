import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment_group_model.dart';
import '../../models/appointment_model.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_widgets.dart';
import '../../core/phobes_theme.dart';

class ClientBookingScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const ClientBookingScreen({super.key, this.onClose});

  @override
  State<ClientBookingScreen> createState() => _ClientBookingScreenState();
}

class _ClientBookingScreenState extends State<ClientBookingScreen> {
  final _codeCtrl = TextEditingController();
  final FirebaseService _service = FirebaseService();

  AppointmentGroup? _foundGroup;
  DateTime _selectedDay = DateTime.now();
  List<DateTime> _availableSlots = [];
  bool _isLoadingSlots = false;

  Future<void> _findGroup() async {
    if (_codeCtrl.text.isEmpty) return;

    final group = await _service.getGroupByCode(_codeCtrl.text.trim());

    if (!mounted) return;

    if (group != null) {
      setState(() {
        _foundGroup = group;
        _selectedDay = DateTime.now();
      });
      _loadSlotsForDay(DateTime.now());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.invalidCode)));
    }
  }

  Future<void> _loadSlotsForDay(DateTime date) async {
    if (_foundGroup == null) return;
    setState(() => _isLoadingSlots = true);

    final slots = await _service.getAvailableSlots(_foundGroup!, date);

    if (!mounted) return;

    setState(() {
      _availableSlots = slots;
      _isLoadingSlots = false;
    });
  }

  void _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _bookSlot(DateTime slot) {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    if (_service.currentUser != null) {
      nameCtrl.text = _service.currentUser!.displayName ?? "";
    }

    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PhobesGlassCard(
        margin: EdgeInsets.zero,
        borderRadius: 24,
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.bookNewAppointment,
                style: GoogleFonts.outfit(
                    color: cs.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(DateFormat('d MMMM yyyy, HH:mm', l10n.localeName).format(slot),
                style: GoogleFonts.outfit(
                    color: cs.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            PhobesTextFormField(
              controller: nameCtrl,
              labelText: l10n.name,
              prefixIcon: Icons.person_rounded,
            ),
            const SizedBox(height: 16),
            PhobesTextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              labelText: "Telefon",
              prefixIcon: Icons.phone_rounded,
            ),
            const SizedBox(height: 32),
            PhobesButton(
              text: l10n.btnApprove,
              width: double.infinity,
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                  final appt = Appointment(
                    userId: _foundGroup!.ownerId,
                    clientId: _service.currentUserId,
                    groupId: _foundGroup!.id,
                    title: "${_foundGroup!.title} - ${nameCtrl.text}",
                    clientName: nameCtrl.text,
                    phoneNumber: phoneCtrl.text,
                    date: slot,
                    durationMinutes: _foundGroup!.durationMinutes,
                    status: 'pending',
                  );

                  DocumentReference ref = await FirebaseFirestore.instance
                      .collection('appointments')
                      .add(appt.toMap());

                  final reminderTime = slot.subtract(const Duration(hours: 1));
                  if (reminderTime.isAfter(DateTime.now())) {
                    await NotificationService().scheduleAndSaveNotification(
                      id: ref.id,
                      title: "Randevu Hatırlatması",
                      body:
                          "${_foundGroup!.businessName} ile randevunuz yaklaşıyor (1 Saat).",
                      scheduledTime: reminderTime,
                      type: 'appointment',
                      targetId: ref.id,
                      targetType: 'appointment',
                      icon: '📅',
                      color: 0xFF2196F3,
                      channelId: 'appointments',
                      channelName: 'Randevular',
                      prefKey: 'notif_appt_reminder',
                    );
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(l10n.msgStatusUpdated),
                        backgroundColor: Colors.green));
                    _loadSlotsForDay(_selectedDay);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;

    return Scaffold(
      backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
      appBar: PhobesPremiumAppBar(
        title: l10n.bookNewAppointment,
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
          constraints: const BoxConstraints(maxWidth: 700),
          child: _foundGroup == null
              ? _buildCodeInputStep(l10n)
              : _buildCalendarStep(l10n),
        ),
      ),
    );
  }

  Widget _buildCodeInputStep(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(Icons.qr_code_2_rounded, size: 80, color: cs.primary),
          ),
          const SizedBox(height: 32),
          Text(l10n.joinCode,
              style: GoogleFonts.outfit(
                  color: cs.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(l10n.enterServiceCodeHint,
              style: GoogleFonts.outfit(
                  color: cs.onSurface.withValues(alpha: 0.5), fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          PhobesCard(
            padding: const EdgeInsets.all(4),
            child: TextField(
              controller: _codeCtrl,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  color: cs.onSurface,
                  fontSize: 24,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                  hintText: "BOOK-XXXXXX",
                  hintStyle: GoogleFonts.outfit(
                      color: cs.onSurface.withValues(alpha: 0.1)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          const SizedBox(height: 32),
          PhobesButton(
            text: l10n.btnCall,
            width: double.infinity,
            onPressed: _findGroup,
          )
        ],
      ),
    );
  }

  Widget _buildCalendarStep(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        PhobesCard(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_foundGroup!.businessName,
                            style: GoogleFonts.outfit(
                                color: cs.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1),
                        const SizedBox(height: 4),
                        Text(_foundGroup!.title,
                            style: GoogleFonts.outfit(
                                color: cs.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                        "${_foundGroup!.price} ${_foundGroup!.currency}",
                        style: GoogleFonts.outfit(
                            color: cs.primary, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 12),
              if (_foundGroup!.description.isNotEmpty)
                Text(_foundGroup!.description,
                    style: GoogleFonts.outfit(
                        color: cs.onSurface.withValues(alpha: 0.5),
                        fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (_foundGroup!.businessPhone != null)
                    _iconBtn(Icons.phone_rounded, l10n.btnCall,
                        () => _launch("tel:${_foundGroup!.businessPhone}"), cs),
                  if (_foundGroup!.mapUrl != null)
                    _iconBtn(Icons.map_rounded, l10n.btnMap,
                        () => _launch(_foundGroup!.mapUrl!), cs),
                  if (_foundGroup!.businessWebsite != null)
                    _iconBtn(Icons.language_rounded, l10n.btnWeb,
                        () => _launch(_foundGroup!.businessWebsite!), cs),
                ],
              )
            ],
          ),
        ),
        TableCalendar(
          locale: l10n.localeName,
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(const Duration(days: 90)),
          focusedDay: _selectedDay,
          calendarFormat: CalendarFormat.week,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
            });
            _loadSlotsForDay(selectedDay);
          },
          calendarStyle: CalendarStyle(
            defaultTextStyle: GoogleFonts.outfit(color: cs.onSurface),
            weekendTextStyle: GoogleFonts.outfit(color: cs.error),
            todayDecoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle),
            todayTextStyle: GoogleFonts.outfit(
                color: cs.primary, fontWeight: FontWeight.bold),
            selectedDecoration:
                BoxDecoration(color: cs.primary, shape: BoxShape.circle),
            selectedTextStyle: GoogleFonts.outfit(
                color: cs.onPrimary, fontWeight: FontWeight.bold),
          ),
          headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon:
                  Icon(Icons.chevron_left_rounded, color: cs.onSurface),
              rightChevronIcon:
                  Icon(Icons.chevron_right_rounded, color: cs.onSurface),
              titleTextStyle: GoogleFonts.outfit(
                  color: cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
        Divider(color: cs.onSurface.withValues(alpha: 0.1), height: 32),
        Expanded(
          child: _isLoadingSlots
              ? const Center(child: PhobesLoadingIndicator())
              : _availableSlots.isEmpty
                  ? Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_rounded,
                            color: cs.onSurface.withValues(alpha: 0.2),
                            size: 64),
                        const SizedBox(height: 16),
                        Text(l10n.msgNoAppointments,
                            style: GoogleFonts.outfit(
                                color: cs.onSurface.withValues(alpha: 0.4))),
                      ],
                    ))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12),
                      itemCount: _availableSlots.length,
                      itemBuilder: (context, index) {
                        final slot = _availableSlots[index];
                        return PhobesCard(
                          margin: EdgeInsets.zero,
                          padding: EdgeInsets.zero,
                          onTap: () => _bookSlot(slot),
                          child: Center(
                            child: Text(DateFormat('HH:mm').format(slot),
                                style: GoogleFonts.outfit(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _iconBtn(
      IconData icon, String label, VoidCallback onTap, ColorScheme cs) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          PhobesIconButton(
            icon: icon,
            onTap: onTap,
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.outfit(
                  color: cs.onSurface.withValues(alpha: 0.5), fontSize: 11))
        ],
      ),
    );
  }
}
