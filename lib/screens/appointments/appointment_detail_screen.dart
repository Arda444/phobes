import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/appointment_group_model.dart';
import '../../models/appointment_model.dart';
import '../../services/firebase_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_widgets.dart';
import '../../core/phobes_theme.dart';
import '../../core/page_transitions.dart';
import 'appointment_add_edit_screen.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onClose;
  const AppointmentDetailScreen(
      {super.key, required this.appointment, this.onClose});

  Future<AppointmentGroup?> _loadGroup() async {
    if (appointment.groupId == null) return null;
    return await FirebaseService().getGroupById(appointment.groupId!);
  }

  void _launch(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _cancelAppointment(BuildContext context, AppointmentGroup group) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = appointment.date.difference(now).inHours;
    final cs = Theme.of(context).colorScheme;

    if (difference < group.minCancellationHours) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cs.surfaceContainerHigh,
          title: Text(l10n.cancellationPolicy,
              style: GoogleFonts.outfit(
                  color: cs.error, fontWeight: FontWeight.bold)),
          content: Text(
            l10n.policyWarning(group.minCancellationHours),
            style: GoogleFonts.outfit(color: cs.onSurfaceVariant),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("Tamam",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)))
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cs.surfaceContainerHigh,
          title: Text(l10n.statusCancelled,
              style: GoogleFonts.outfit(
                  color: cs.onSurface, fontWeight: FontWeight.bold)),
          content: Text(l10n.deleteNoteWarning,
              style: GoogleFonts.outfit(color: cs.onSurfaceVariant)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel,
                    style: GoogleFonts.outfit(color: cs.onSurfaceVariant))),
            PhobesButton(
              text: l10n.btnReject,
              onPressed: () async {
                await FirebaseService().updateAppointment(
                    appointment.copyWith(status: 'cancelled'));
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  if (onClose != null) {
                    onClose!();
                  } else {
                    Navigator.pop(context);
                  }
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.msgStatusUpdated)));
                }
              },
            ),
          ],
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'confirmed':
        return l10n.statusConfirmed.toUpperCase();
      case 'cancelled':
        return l10n.statusCancelled.toUpperCase();
      case 'completed':
        return l10n.statusCompleted.toUpperCase();
      default:
        return l10n.statusPending.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;
    final statusColor = _getStatusColor(appointment.status);

    return Scaffold(
      backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
      body: Column(
        children: [
          _buildHeader(context, l10n, statusColor, cs),
          Expanded(
            child: FutureBuilder<AppointmentGroup?>(
              future: _loadGroup(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: PhobesLoadingIndicator());
                }
                final group = snapshot.data;
                final isCancelled = appointment.status == 'cancelled';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (group != null) ...[
                          PhobesGlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.labelProvider,
                                    style: GoogleFonts.outfit(
                                        color:
                                            cs.onSurface.withValues(alpha: 0.5),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Text(group.businessName,
                                    style: GoogleFonts.outfit(
                                        color: cs.onSurface,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                                Text(group.title,
                                    style: GoogleFonts.outfit(
                                        color: cs.primary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                                if (group.description.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(group.description,
                                      style: GoogleFonts.outfit(
                                          color: cs.onSurface
                                              .withValues(alpha: 0.7),
                                          height: 1.5)),
                                ],
                                const SizedBox(height: 32),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    if (group.businessPhone != null)
                                      _iconBtn(
                                          Icons.phone_rounded,
                                          l10n.btnCall,
                                          () => _launch(
                                              "tel:${group.businessPhone}"),
                                          cs),
                                    if (group.mapUrl != null)
                                      _iconBtn(Icons.map_rounded, l10n.btnMap,
                                          () => _launch(group.mapUrl!), cs),
                                    if (group.businessWebsite != null)
                                      _iconBtn(
                                          Icons.language_rounded,
                                          l10n.btnWeb,
                                          () => _launch(group.businessWebsite!),
                                          cs),
                                  ],
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!isCancelled)
                            PhobesCard(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded,
                                          color: cs.error, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          l10n.policyWarning(
                                              group.minCancellationHours),
                                          style: GoogleFonts.outfit(
                                              color: cs.onSurface
                                                  .withValues(alpha: 0.6),
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  PhobesButton(
                                    width: double.infinity,
                                    text: l10n.btnReject,
                                    gradient: LinearGradient(
                                      colors: [
                                        cs.error,
                                        cs.error.withValues(alpha: 0.8)
                                      ],
                                    ),
                                    onPressed: () =>
                                        _cancelAppointment(context, group),
                                  )
                                ],
                              ),
                            ),
                        ] else ...[
                          const Center(child: PhobesLoadingIndicator())
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n,
      Color statusColor, ColorScheme cs) {
    final dateStr =
        DateFormat('d MMMM yyyy', l10n.localeName).format(appointment.date);
    final timeStr =
        DateFormat('HH:mm', l10n.localeName).format(appointment.date);
    final statusText = _getStatusText(context, appointment.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [statusColor.withValues(alpha: 0.2), cs.surface],
          ),
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(32)),
          border: Border(
              bottom: BorderSide(
                  color: statusColor.withValues(alpha: 0.2), width: 1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              PhobesIconButton(
                icon: Icons.edit_rounded,
                backgroundColor: cs.surface.withValues(alpha: 0.5),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  await navigator.push(PhobesPageRoute.slideUp(
                      AppointmentAddEditScreen(appointment: appointment)));
                  if (context.mounted) {
                    if (onClose != null) {
                      onClose!();
                    } else {
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3))),
            child: Text(
              statusText,
              style: GoogleFonts.outfit(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                    height: 1),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  dateStr,
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            appointment.title,
            style: GoogleFonts.outfit(
                fontSize: 15, color: cs.onSurface.withValues(alpha: 0.4)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(
      IconData icon, String label, VoidCallback onTap, ColorScheme cs) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          PhobesIconButton(
            icon: icon,
            onTap: onTap,
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.outfit(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w500))
        ],
      ),
    );
  }
}
