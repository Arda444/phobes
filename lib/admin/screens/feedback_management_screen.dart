import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_service.dart';
import '../utils/admin_ui_system.dart';

class FeedbackManagementScreen extends StatelessWidget {
  const FeedbackManagementScreen({super.key});

  void _showReplyDialog(BuildContext context, String id, String message) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Kullanıcıya Yanıt Gönder', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
                child: Text('"${message.length > 100 ? '${message.substring(0, 100)}...' : message}"',
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.5), fontStyle: FontStyle.italic),),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                maxLines: 4,
                style: GoogleFonts.outfit(),
                decoration: InputDecoration(
                  hintText: 'Mesajınızı buraya yazın...',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.02),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                  focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AdminUISystem.kElectricBlue(context))),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('İPTAL', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.5)))),
          Container(
            decoration: BoxDecoration(gradient: AdminUISystem.primaryGradient(context), borderRadius: BorderRadius.circular(12)),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await AdminService.replyFeedback(id, ctrl.text.trim());
              },
              child: Text('YANITI GÖNDER', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        ],
      ),
    ).then((_) => ctrl.dispose());
  }

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
                  Text('Kullanıcı Deneyimi', style: AdminUISystem.titleStyle.copyWith(color: cs.onSurface)),
                  const SizedBox(height: 4),
                  Text('Gelen geri bildirimler ve çözüm süreci yönetimi', style: AdminUISystem.subtitleStyle(context)),
                ],
              ),
              _buildStatsBadge(context, cs),
            ],
          ),
          const SizedBox(height: 32),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: AdminService.feedbackStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return _buildEmptyState(cs);

              return Column(
                children: docs.map((doc) => _buildFeedbackCard(context, doc.id, doc.data(), cs)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBadge(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AdminUISystem.kElectricBlue(context).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminUISystem.kElectricBlue(context).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.query_stats_rounded, size: 14, color: AdminUISystem.kElectricBlue(context)),
          const SizedBox(width: 8),
          Text('AKTİF TAKİP', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: AdminUISystem.kElectricBlue(context), letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context, String id, Map<String, dynamic> data, ColorScheme cs) {
    final status = data['status'] as String? ?? 'open';
    final message = data['message'] as String? ?? '—';
    final user = data['userId'] as String? ?? data['username'] as String? ?? 'Anonim Kullanıcı';
    final isClosed = status == 'closed';
    final reply = data['adminReply'] as String?;
    final statusColor = isClosed ? Colors.grey : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AdminUISystem.cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(color: cs.onSurface.withOpacity(0.02), border: Border(bottom: BorderSide(color: cs.onSurface.withOpacity(0.05)))),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AdminUISystem.kElectricBlue(context).withOpacity(0.1),
                  child: Text(user[0].toUpperCase(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: AdminUISystem.kElectricBlue(context))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(user, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14))),
                _buildStatusTag(isClosed ? 'ÇÖZÜLDÜ' : 'BEKLEYEN', statusColor),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: GoogleFonts.outfit(fontSize: 15, height: 1.6, color: cs.onSurface.withOpacity(0.8))),
                if (reply != null) ...[
                  const SizedBox(height: 20),
                  _buildAdminReply(context, reply, cs),
                ],
                if (!isClosed) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => AdminService.closeFeedback(id),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: Text('KAPAT', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: cs.onSurface.withOpacity(0.4)),
                      ),
                      const SizedBox(width: 12),
                      _buildReplyButton(context, id, message),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminReply(BuildContext context, String reply, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminUISystem.kElectricBlue(context).withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminUISystem.kElectricBlue(context).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: AdminUISystem.kElectricBlue(context)),
              const SizedBox(width: 8),
              Text('YÖNETİCİ YANITI', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: AdminUISystem.kElectricBlue(context), letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(reply, style: GoogleFonts.outfit(fontSize: 13, height: 1.5, color: cs.onSurface.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildReplyButton(BuildContext context, String id, String message) {
    return Container(
      decoration: BoxDecoration(gradient: AdminUISystem.primaryGradient(context), borderRadius: BorderRadius.circular(10)),
      child: ElevatedButton.icon(
        onPressed: () => _showReplyDialog(context, id, message),
        icon: const Icon(Icons.reply_rounded, size: 16, color: Colors.white),
        label: Text('YANITLA', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      ),
    );
  }

  Widget _buildStatusTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: cs.onSurface.withOpacity(0.05)),
          const SizedBox(height: 24),
          Text('Tüm Bildirimler Yanıtlandı', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.4))),
        ],
      ),
    );
  }
}
