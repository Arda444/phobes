import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_service.dart';
import '../utils/admin_ui_system.dart';
import '../../l10n/app_localizations.dart';

class BlacklistScreen extends StatelessWidget {
  const BlacklistScreen({super.key});

  void _showAddDialog(BuildContext context, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    final valueCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String selectedType = 'email';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(l10n.adminBlacklistAddTitle,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800),),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  style: GoogleFonts.outfit(color: cs.onSurface),
                  decoration: _inputDecoration(l10n.adminCategoryType, Icons.category_rounded, cs, context),
                  items: ['email', 'ip', 'deviceId']
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),)
                      .toList(),
                  onChanged: (v) => setState(() => selectedType = v ?? 'email'),
                ),
                const SizedBox(height: 16),
                _buildField(valueCtrl, selectedType == 'email' ? l10n.adminEmailAddress : (selectedType == 'ip' ? l10n.adminIpAddress : l10n.adminDeviceId), Icons.fingerprint_rounded, cs, context),
                const SizedBox(height: 16),
                _buildField(reasonCtrl, l10n.adminBlockReason, Icons.security_rounded, cs, context, maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.5))),),
            Container(
              decoration: BoxDecoration(
                gradient: AdminUISystem.primaryGradient(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  if (valueCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  await AdminService.addBlacklist(
                    type: selectedType,
                    value: valueCtrl.text.trim(),
                    reason: reasonCtrl.text.trim(),
                  );
                },
                child: Text(l10n.adminAddRecord, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      valueCtrl.dispose();
      reasonCtrl.dispose();
    });
  }

  static Widget _buildField(TextEditingController ctrl, String label, IconData icon, ColorScheme cs, BuildContext context, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.outfit(),
      decoration: _inputDecoration(label, icon, cs, context),
    );
  }

  static InputDecoration _inputDecoration(String label, IconData icon, ColorScheme cs, BuildContext context) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: cs.onSurface.withOpacity(0.4)),
      prefixIcon: Icon(icon, color: AdminUISystem.kElectricBlue(context), size: 20),
      filled: true,
      fillColor: cs.onSurface.withOpacity(0.03),
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AdminUISystem.kElectricBlue(context))),
    );
  }

  void _confirmDelete(BuildContext context, String id, String value) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.adminDeleteRecord, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(l10n.adminDeleteBlacklistConfirm(value)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(context);
              await AdminService.deleteBlacklist(id, value);
            },
            child: Text(l10n.adminDeleteConfirmAction, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.adminBlacklistManagement, style: AdminUISystem.titleStyle.copyWith(color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text(l10n.adminBlacklistSubtitle, style: AdminUISystem.subtitleStyle(context)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildAddButton(context, cs),
            ],
          ),
          const SizedBox(height: 32),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: AdminService.blacklistStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return _buildEmptyState(context, cs);

              return Column(
                children: docs.map((doc) => _buildBlacklistCard(context, doc.id, doc.data(), cs)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: AdminUISystem.primaryGradient(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AdminUISystem.kNeonPurple(context).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showAddDialog(context, cs),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(l10n.adminNewEntry, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildBlacklistCard(BuildContext context, String id, Map<String, dynamic> data, ColorScheme cs) {
    final type = data['type'] as String? ?? 'email';
    final value = data['value'] as String? ?? '—';
    final reason = data['reason'] as String? ?? '—';
    final addedBy = data['addedBy'] as String? ?? '—';
    final typeColor = _getTypeColor(context, type);

    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AdminUISystem.cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_getTypeIcon(type), color: typeColor, size: 24),
        ),
        title: Row(
          children: [
            Expanded(child: Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            _buildTypeBadge(type, typeColor),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(reason, style: GoogleFonts.outfit(fontSize: 13, color: cs.onSurface.withOpacity(0.5))),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded, size: 14, color: AdminUISystem.kElectricBlue(context)),
                const SizedBox(width: 6),
                Text(addedBy, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AdminUISystem.kElectricBlue(context))),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () => _confirmDelete(context, id, value),
          icon: Icon(Icons.delete_outline_rounded, color: cs.error.withOpacity(0.5)),
          tooltip: l10n.adminDeleteRecord,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.verified_user_rounded, size: 80, color: Colors.green.withOpacity(0.05)),
          const SizedBox(height: 24),
          Text(l10n.adminBlacklistClean, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(type.toUpperCase(), style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
    );
  }

  Color _getTypeColor(BuildContext context, String type) {
    if (type == 'email') return AdminUISystem.kAccentBlue(context);
    if (type == 'ip') return Colors.orange;
    return AdminUISystem.kNeonPurple(context);
  }

  IconData _getTypeIcon(String type) {
    if (type == 'email') return Icons.alternate_email_rounded;
    if (type == 'ip') return Icons.lan_rounded;
    return Icons.devices_other_rounded;
  }
}
