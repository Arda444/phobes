import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_service.dart';
import '../utils/admin_ui_system.dart';
import 'push_test_screen.dart';

class NotificationTemplatesScreen extends StatelessWidget {
  const NotificationTemplatesScreen({super.key});

  void _showTemplateDialog(BuildContext context,
      {String? id, String? title, String? body, String? target,}) {
    final titleCtrl = TextEditingController(text: title ?? '');
    final bodyCtrl = TextEditingController(text: body ?? '');
    String selectedTarget = target ?? 'Tüm Kullanıcılar';
    final targets = ['Tüm Kullanıcılar', 'Aktif', 'Yeni', 'Premium'];
    final isEdit = id != null;
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(isEdit ? 'Şablonu Düzenle' : 'Yeni Bildirim Şablonu',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800),),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(titleCtrl, 'Başlık', Icons.title_rounded, cs, context),
                const SizedBox(height: 16),
                _buildField(bodyCtrl, 'İçerik Metni', Icons.subject_rounded, cs, context, maxLines: 3),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTarget,
                  style: GoogleFonts.outfit(color: cs.onSurface),
                  decoration: _inputDecoration('Hedef Kitle', Icons.people_rounded, cs, context),
                  items: targets
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedTarget = v ?? targets[0]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('İptal', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.5))),),
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
                  if (titleCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  if (isEdit) {
                    await AdminService.updateNotificationTemplate(
                        id, titleCtrl.text.trim(), bodyCtrl.text.trim(),
                        selectedTarget,);
                  } else {
                    await AdminService.addNotificationTemplate(
                      title: titleCtrl.text.trim(),
                      body: bodyCtrl.text.trim(),
                      target: selectedTarget,
                    );
                  }
                },
                child: Text(isEdit ? 'Şablonu Güncelle' : 'Şablonu Oluştur', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _confirmDelete(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Şablonu Sil',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),),
        content: Text('"$title" şablonunu kalıcı olarak silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(context);
              await AdminService.deleteNotificationTemplate(id, title);
            },
            child: const Text('Evet, Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bildirim Şablonları',
                          style: AdminUISystem.titleStyle.copyWith(color: cs.onSurface),),
                      const SizedBox(height: 4),
                      Text('Kampanya ve Duyurular için profesyonel içerikler hazırlayın',
                          style: AdminUISystem.subtitleStyle(context),),
                    ],
                  ),
                ),
                _buildAddButton(context, cs),
              ],
            ),
            const SizedBox(height: 32),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: AdminService.notificationTemplatesStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return _buildEmptyState(cs);

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final t = data['title'] as String? ?? '—';
                    final b = data['body'] as String? ?? '';
                    final target = data['target'] as String? ?? 'Tüm Kullanıcılar';

                    return _buildTemplateCard(context, docs[i].id, t, b, target, cs);
                  },
                );
              },
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 16),
            const PushTestScreen(embedded: true),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        gradient: AdminUISystem.primaryGradient(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AdminUISystem.kNeonPurple(context).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showTemplateDialog(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Yeni Şablon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, String id, String t, String b, String target, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AdminUISystem.cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AdminUISystem.kElectricBlue(context).withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.notifications_active_rounded, color: AdminUISystem.kElectricBlue(context), size: 24),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
                          const SizedBox(height: 6),
                          _buildTargetBadge(context, target, cs),
                        ],
                      ),
                    ),
                    _TemplateActions(id: id, title: t, body: b, target: target, onDelete: () => _confirmDelete(context, id, t), onEdit: () => _showTemplateDialog(context, id: id, title: t, body: b, target: target)),
                  ],
                ),
                if (b.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(b, style: GoogleFonts.outfit(fontSize: 14, height: 1.6, color: cs.onSurface.withOpacity(0.6))),
                ],
              ],
            ),
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
          Icon(Icons.notification_important_rounded, size: 80, color: cs.onSurface.withOpacity(0.05)),
          const SizedBox(height: 24),
          Text('Şablon Bulunamadı', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildTargetBadge(BuildContext context, String target, ColorScheme cs) {
    Color badgeColor = AdminUISystem.kElectricBlue(context);
    if (target == 'Premium') badgeColor = AdminUISystem.kNeonPurple(context);
    if (target == 'Yeni') badgeColor = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: badgeColor.withOpacity(0.2))),
      child: Text(target.toUpperCase(), style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: badgeColor, letterSpacing: 0.8)),
    );
  }
}

class _TemplateActions extends StatelessWidget {
  final String id;
  final String title;
  final String body;
  final String target;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TemplateActions({required this.id, required this.title, required this.body, required this.target, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: cs.onSurface.withOpacity(0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) async {
        if (val == 'edit') onEdit();
        if (val == 'delete') onDelete();
        if (val == 'send') {
          try {
            final count = await AdminService.sendPushNotification(
              topic: 'all_users',
              title: title,
              body: body,
            );
            if (context.mounted) {
              AdminUISystem.showSuccessSnackBar(
                context,
                'Uygulama içi bildirim: $count kullanıcı',
              );
            }
          } catch (e) {
            if (context.mounted) {
              AdminUISystem.showErrorSnackBar(context, '$e');
            }
          }
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'send', child: Row(children: [Icon(Icons.send_rounded, size: 18), SizedBox(width: 12), Text('Gönder (tüm kullanıcılar)')])),
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 12), Text('Düzenle')])),
        PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: cs.error), const SizedBox(width: 12), Text('Sil', style: TextStyle(color: cs.error))])),
      ],
    );
  }
}

