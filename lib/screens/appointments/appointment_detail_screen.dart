import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/appointment_model.dart';
import '../../models/appointment_group_model.dart';
import '../../services/appointment_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_widgets.dart';
import 'appointment_add_edit_screen.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onClose;
  final VoidCallback? onEdit;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
    this.onClose,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final color = Color(appointment.color);
    final dateStr = DateFormat('d MMMM yyyy, EEEE', l10n.localeName)
        .format(appointment.date);
    final timeStr = DateFormat('HH:mm').format(appointment.date);
    final endStr = DateFormat('HH:mm').format(appointment.endTime);
    final isCancelled = appointment.status == 'cancelled';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;
            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                  child: Row(
                    children: [
                      PhobesIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {
                          if (onClose != null) {
                            onClose!();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.viewDetails,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusPill(appointment.status, cs, l10n),
                    ],
                  ),
                ),
                Expanded(
                  child: isWide
                      ? _buildWideLayout(
                          context,
                          cs,
                          l10n,
                          color,
                          isCancelled,
                          dateStr,
                          timeStr,
                          endStr,
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoCard(cs, color, isCancelled),
                              const SizedBox(height: 16),
                              _buildDetailRows(
                                  context, cs, l10n, dateStr, timeStr, endStr),
                              const SizedBox(height: 24),
                              _buildActionButtons(context, cs, l10n),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme cs, Color color, bool isCancelled) {
    return PhobesGlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 48,
            decoration: BoxDecoration(
              color: isCancelled ? cs.onSurface.withOpacity(0.15) : color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isCancelled
                        ? cs.onSurface.withOpacity(0.35)
                        : cs.onSurface,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (appointment.price > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${appointment.price.toStringAsFixed(0)} ${appointment.currency}',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRows(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    String dateStr,
    String timeStr,
    String endStr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(
          icon: Icons.calendar_today_rounded,
          iconColor: const Color(0xFF3B82F6),
          label: l10n.labelDate,
          value: dateStr,
        ),
        _DetailRow(
          icon: Icons.access_time_rounded,
          iconColor: const Color(0xFF8B5CF6),
          label: l10n.duration,
          value:
              '$timeStr – $endStr  (${appointment.durationMinutes} ${l10n.apptMinutes(appointment.durationMinutes).split(' ').last})',
        ),
        _DetailRow(
          icon: Icons.person_rounded,
          iconColor: const Color(0xFF10B981),
          label: l10n.labelClient,
          value: appointment.clientName,
        ),
        if (appointment.phoneNumber != null &&
            appointment.phoneNumber!.isNotEmpty)
          _DetailRow(
            icon: Icons.phone_rounded,
            iconColor: const Color(0xFF06B6D4),
            label: l10n.phone,
            value: appointment.phoneNumber!,
            onTap: () => _launchUrl('tel:${appointment.phoneNumber}'),
          ),
        if (appointment.email != null && appointment.email!.isNotEmpty)
          _DetailRow(
            icon: Icons.email_outlined,
            iconColor: const Color(0xFFF59E0B),
            label: l10n.apptClientEmail,
            value: appointment.email!,
            onTap: () => _launchUrl('mailto:${appointment.email}'),
          ),
        if (appointment.notes != null && appointment.notes!.isNotEmpty)
          _DetailRow(
            icon: Icons.note_alt_rounded,
            iconColor: const Color(0xFFF472B6),
            label: l10n.labelNote,
            value: appointment.notes!,
          ),
        if (appointment.cancelReason != null &&
            appointment.cancelReason!.isNotEmpty)
          _DetailRow(
            icon: Icons.cancel_rounded,
            iconColor: cs.error,
            label: l10n.apptCancelReason,
            value: appointment.cancelReason!,
          ),
        if (appointment.groupId != null)
          FutureBuilder<AppointmentGroup?>(
            future: AppointmentService().getServiceById(appointment.groupId!),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final group = snapshot.data!;
              return _DetailRow(
                icon: Icons.key_rounded,
                iconColor: cs.primary,
                label: l10n.appointmentCode,
                value: group.groupCode,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: group.groupCode));
                  PhobesSnackbar.show(
                    context,
                    message: l10n.msgCodeCopied,
                    type: PhobesSnackbarType.success,
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isProvider = uid != null && appointment.userId == uid;
    final isClient =
        uid != null && appointment.clientId != null && appointment.clientId == uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (appointment.status == 'pending' && isProvider) ...[
          Row(
            children: [
              Expanded(
                child: PhobesButton(
                  text: l10n.btnApprove,
                  icon: Icons.check_rounded,
                  onPressed: () => _updateStatus(context, 'confirmed'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PhobesButton(
                  text: l10n.btnReject,
                  icon: Icons.close_rounded,
                  backgroundColor: cs.error,
                  onPressed: () => _updateStatus(context, 'cancelled'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (appointment.status == 'confirmed' && isProvider) ...[
          PhobesButton(
            text: l10n.statusCompleted,
            icon: Icons.check_circle_rounded,
            onPressed: () => _updateStatus(context, 'completed'),
          ),
          const SizedBox(height: 12),
        ],
        if (appointment.status != 'cancelled' &&
            appointment.status != 'completed' &&
            (isProvider || isClient)) ...[
          PhobesButton(
            text: l10n.apptReschedule,
            icon: Icons.edit_calendar_rounded,
            isOutlined: true,
            onPressed: onEdit ??
                () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AppointmentAddEditScreen(
                          appointment: appointment,
                          onClose: onClose,
                        ),
                      ),
                    ),
          ),
          const SizedBox(height: 12),
        ],
        if (appointment.phoneNumber != null &&
            appointment.phoneNumber!.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: PhobesButton(
                  text: l10n.apptWhatsapp,
                  icon: Icons.message_rounded,
                  backgroundColor: const Color(0xFF25D366),
                  onPressed: () => _launchUrl(
                    'https://wa.me/${appointment.phoneNumber?.replaceAll(RegExp(r'[^0-9]'), '')}',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PhobesButton(
                  text: l10n.btnCall,
                  icon: Icons.phone_rounded,
                  backgroundColor: const Color(0xFF06B6D4),
                  onPressed: () => _launchUrl('tel:${appointment.phoneNumber}'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    Color color,
    bool isCancelled,
    String dateStr,
    String timeStr,
    String endStr,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 10, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(cs, color, isCancelled),
                const SizedBox(height: 16),
                _buildDetailRows(context, cs, l10n, dateStr, timeStr, endStr),
              ],
            ),
          ),
        ),
        Container(
          width: 1,
          color: cs.outline.withOpacity(0.1),
          margin: const EdgeInsets.symmetric(vertical: 16),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 12, 20, 32),
            child: _buildActionButtons(context, cs, l10n),
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    final l10n = AppLocalizations.of(context)!;
    await AppointmentService().updateStatus(appointment.id!, status);
    if (context.mounted) {
      PhobesSnackbar.show(
        context,
        message: l10n.msgStatusUpdated,
        type: PhobesSnackbarType.success,
      );
      if (onClose != null) onClose!();
    }
  }

  Widget _buildStatusPill(
    String status,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    Color c;
    String t;
    switch (status) {
      case 'confirmed':
        c = const Color(0xFF10B981);
        t = l10n.statusConfirmed;
        break;
      case 'cancelled':
        c = const Color(0xFFEF4444);
        t = l10n.statusCancelled;
        break;
      case 'completed':
        c = const Color(0xFF6B7280);
        t = l10n.statusCompleted;
        break;
      default:
        c = const Color(0xFFF59E0B);
        t = l10n.statusPending;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(
        t,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: c,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: cs.onSurface.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: onTap != null ? cs.primary : cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
