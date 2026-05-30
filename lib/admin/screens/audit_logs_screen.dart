import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_service.dart';
import '../utils/admin_ui_system.dart';
import 'package:intl/intl.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async => Future.delayed(const Duration(milliseconds: 500)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Güvenlik Duvarı & Loglar',
                        style: AdminUISystem.titleStyle.copyWith(color: cs.onSurface),),
                    const SizedBox(height: 4),
                    Text('Sistem üzerindeki tüm kritik admin eylemleri',
                        style: AdminUISystem.subtitleStyle(context),),
                  ],
                ),
                _buildSecurityStatus(cs),
              ],
            ),
            const SizedBox(height: 32),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: AdminService.auditLogsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return _buildEmptyState(cs);

                return Column(
                  children: docs.map((doc) => _buildLogCard(context, doc.data(), cs)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityStatus(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('SİSTEM GÜVENLİ', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.green, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, Map<String, dynamic> data, ColorScheme cs) {
    final ts = data['timestamp'] as Timestamp?;
    final time = ts != null ? _formatTs(ts.toDate()) : '—';
    final success = data['success'] != false;
    final action = data['action'] as String? ?? '—';
    final detail = data['detail'] as String? ?? '';
    final adminEmail = data['adminEmail'] as String? ?? '—';
    final accentColor = success ? AdminUISystem.kElectricBlue(context) : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AdminUISystem.cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: accentColor.withOpacity(0.5)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Icon(success ? Icons.shield_rounded : Icons.gpp_maybe_rounded, color: accentColor, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(action, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: cs.onSurface))),
                        Text(time, style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withOpacity(0.3))),
                      ],
                    ),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(detail, style: GoogleFonts.outfit(fontSize: 13, height: 1.5, color: cs.onSurface.withOpacity(0.6))),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMetaChip(Icons.person_rounded, adminEmail, cs),
                        if (data['ip'] != null) _buildMetaChip(Icons.lan_rounded, data['ip'] as String, cs),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.history_edu_rounded, size: 80, color: cs.onSurface.withOpacity(0.05)),
          const SizedBox(height: 24),
          Text('Kayıt Bulunamadı', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text, ColorScheme cs) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: cs.onSurface.withOpacity(0.04), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: cs.onSurface.withOpacity(0.2)),
            const SizedBox(width: 8),
            Text(text, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.5))),
          ],
        ),
      );

  String _formatTs(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} d';
    if (diff.inHours < 24) return '${diff.inHours} s';
    return DateFormat('dd.MM HH:mm').format(dt);
  }
}
