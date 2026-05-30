import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_service.dart';
import '../utils/admin_ui_system.dart';

class BroadcastAdminScreen extends StatefulWidget {
  const BroadcastAdminScreen({super.key});

  @override
  State<BroadcastAdminScreen> createState() => _BroadcastAdminScreenState();
}

class _BroadcastAdminScreenState extends State<BroadcastAdminScreen> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _type = 'info';
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_titleCtrl.text.trim().isEmpty || _msgCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await AdminService.publishBroadcast(
        title: _titleCtrl.text.trim(),
        message: _msgCtrl.text.trim(),
        type: _type,
      );
      if (!mounted) return;
      _titleCtrl.clear();
      _msgCtrl.clear();
      AdminUISystem.showSuccessSnackBar(context, 'Popup duyuru yayınlandı');
    } catch (e) {
      if (!mounted) return;
      AdminUISystem.showErrorSnackBar(context, '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pad = AdminUISystem.horizontalPadding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popup Duyuru',
            style: AdminUISystem.titleStyle.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            'Kullanıcı uygulamaya girdiğinde bir kez gösterilir.',
            style: AdminUISystem.subtitleStyle(context),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Başlık', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _msgCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Mesaj', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final t in ['info', 'warning', 'critical'])
                ChoiceChip(
                  label: Text(t.toUpperCase()),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _publish,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.campaign_rounded),
            label: Text('Yayınla', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 32),
          Text('Geçmiş', style: AdminUISystem.cardTitle.copyWith(color: cs.onSurface)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: AdminService.broadcastsStream(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Text('Hata: ${snap.error}');
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Text('Henüz duyuru yok', style: AdminUISystem.subtitleStyle(context));
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data();
                  final active = d['active'] == true;
                  return ListTile(
                    title: Text(d['title'] as String? ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      d['message'] as String? ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: active
                        ? TextButton(
                            onPressed: () => AdminService.deactivateBroadcast(
                              doc.id,
                              d['title'] as String? ?? '',
                            ),
                            child: const Text('Kapat'),
                          )
                        : const Text('Pasif', style: TextStyle(color: Colors.grey)),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
