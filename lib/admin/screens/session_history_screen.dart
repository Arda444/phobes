import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../admin_service.dart';
import '../utils/admin_ui_system.dart';

class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
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
                  Text('Erişim Kayıtları', style: AdminUISystem.titleStyle.copyWith(color: cs.onSurface)),
                  const SizedBox(height: 4),
                  Text('Sistem genelindeki kullanıcı oturumlarını izleyin', style: AdminUISystem.subtitleStyle(context)),
                ],
              ),
              _buildLiveIndicator(),
            ],
          ),
          const SizedBox(height: 32),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: AdminService.sessionsStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return _buildEmptyState(cs);

              return Column(
                children: docs.map((doc) => _buildSessionCard(context, doc.data(), cs)).toList(),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('CANLI AKIŞ', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.green, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, Map<String, dynamic> data, ColorScheme cs) {
    final email = data['email'] as String? ?? 'Misafir';
    final device = data['deviceInfo'] as String? ?? 'Bilinmeyen Cihaz';
    final ip = data['ipAddress'] as String? ?? '—';
    final ts = data['timestamp'] as Timestamp?;
    final time = ts != null ? ts.toDate() : DateTime.now();
    final isDesktop = device.contains('PC') || device.contains('Windows') || device.contains('Mac');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: AdminUISystem.cardDecoration(context),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminUISystem.kElectricBlue(context).withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminUISystem.kElectricBlue(context).withOpacity(0.1)),
            ),
            child: Icon(
              isDesktop ? Icons.desktop_windows_rounded : Icons.smartphone_rounded,
              color: AdminUISystem.kElectricBlue(context),
              size: 22,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(device, style: GoogleFonts.outfit(fontSize: 11, color: cs.onSurface.withOpacity(0.4), fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: cs.onSurface.withOpacity(0.2))),
                    const SizedBox(width: 8),
                    Text('IP: $ip', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AdminUISystem.kElectricBlue(context).withOpacity(0.6))),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(DateFormat('HH:mm:ss').format(time), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w900, color: cs.onSurface)),
              Text(DateFormat('dd MMMM yyyy', 'tr').format(time), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.3))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.history_toggle_off_rounded, size: 80, color: cs.onSurface.withOpacity(0.05)),
          const SizedBox(height: 24),
          Text('Henüz Erişim Kaydı Mevcut Değil', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.4))),
        ],
      ),
    );
  }
}


