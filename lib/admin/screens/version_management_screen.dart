import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../admin_service.dart';
import '../utils/admin_ui_system.dart';

class VersionManagementScreen extends StatefulWidget {
  const VersionManagementScreen({super.key});

  @override
  State<VersionManagementScreen> createState() =>
      _VersionManagementScreenState();
}

class _VersionManagementScreenState extends State<VersionManagementScreen> {
  final _versionController = TextEditingController(text: '1.0.0+1');
  final _notesController = TextEditingController();
  bool _forceUpdate = false;
  bool _publishing = false;

  @override
  void dispose() {
    _versionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_versionController.text.trim().isEmpty) return;
    setState(() => _publishing = true);
    try {
      await AdminService.publishVersion(
        version: _versionController.text.trim(),
        forceUpdate: _forceUpdate,
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      _notesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('v${_versionController.text} başarıyla yayınlandı!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
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
                  Text('Versiyon Kontrolü',
                      style: AdminUISystem.titleStyle.copyWith(color: cs.onSurface),),
                  const SizedBox(height: 4),
                  Text('Uygulama dağıtım ve sürüm yönetimi merkezi',
                      style: AdminUISystem.subtitleStyle(context),),
                ],
              ),
              _buildCurrentVersionBadge(cs),
            ],
          ),
          const SizedBox(height: 32),
          _buildPublishForm(cs),
          const SizedBox(height: 48),
          _buildHistoryHeader(cs),
          const SizedBox(height: 20),
          _buildHistoryList(cs),
        ],
      ),
    );
  }

  Widget _buildCurrentVersionBadge(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AdminUISystem.kElectricBlue(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminUISystem.kElectricBlue(context).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text('AKTİF SÜRÜM', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: AdminUISystem.kElectricBlue(context), letterSpacing: 1)),
          Text('v1.0.0+1', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildPublishForm(ColorScheme cs) {
    return Container(
      decoration: AdminUISystem.cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: Icon(Icons.rocket_launch_rounded, size: 200, color: AdminUISystem.kNeonPurple(context).withOpacity(0.03)),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AdminUISystem.kNeonPurple(context).withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.auto_fix_high_rounded, color: AdminUISystem.kNeonPurple(context), size: 24),
                    ),
                    const SizedBox(width: 20),
                    Text('Yeni Sürüm Yayınla', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: cs.onSurface)),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildInput('Sürüm Numarası', _versionController, Icons.tag_rounded, cs, hint: '1.2.0+5'),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: _buildInput('Sürüm Notları', _notesController, Icons.description_rounded, cs, hint: 'Kritik performans iyileştirmeleri'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildForceUpdateToggle(cs),
                const SizedBox(height: 32),
                _buildPublishButton(cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, IconData icon, ColorScheme cs, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface.withOpacity(0.5))),
        const SizedBox(height: 10),
        TextField(
          controller: ctrl,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AdminUISystem.kElectricBlue(context), size: 18),
            filled: true,
            fillColor: cs.onSurface.withOpacity(0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AdminUISystem.kElectricBlue(context))),
          ),
        ),
      ],
    );
  }

  Widget _buildForceUpdateToggle(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _forceUpdate ? Colors.red.withOpacity(0.05) : cs.onSurface.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _forceUpdate ? Colors.red.withOpacity(0.2) : Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _forceUpdate ? Colors.red : cs.onSurface.withOpacity(0.3)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kritik Güncelleme (Force Update)', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Kullanıcılar bu sürümü yüklemeden devam edemezler', style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
              ],
            ),
          ),
          Switch(
            value: _forceUpdate,
            onChanged: (v) => setState(() => _forceUpdate = v),
            activeColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildPublishButton(ColorScheme cs) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AdminUISystem.primaryGradient(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AdminUISystem.kNeonPurple(context).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: _publishing ? null : _publish,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _publishing
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('SÜRÜMÜ GLOBAL OLARAK YAYINLA', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
                ],
              ),
      ),
    );
  }

  Widget _buildHistoryHeader(ColorScheme cs) {
    return Row(
      children: [
        Text('Yayın Geçmişi', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: cs.onSurface)),
        const SizedBox(width: 12),
        StreamBuilder<QuerySnapshot>(
          stream: AdminService.versionsStream(),
          builder: (context, snap) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AdminUISystem.kElectricBlue(context).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('${snap.data?.docs.length ?? 0}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: AdminUISystem.kElectricBlue(context))),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(ColorScheme cs) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AdminService.versionsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyHistory(cs);

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final v = data['version'] as String? ?? '—';
            final force = data['forceUpdate'] == true;
            final notes = data['notes'] as String? ?? '';
            final by = data['publishedBy'] as String? ?? 'Admin';
            final ts = data['releasedAt'] as Timestamp?;
            final date = ts != null ? DateFormat('dd MMM, HH:mm').format(ts.toDate()) : '—';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: AdminUISystem.cardDecoration(context),
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: cs.onSurface.withOpacity(0.03), shape: BoxShape.circle),
                  child: Icon(Icons.history_rounded, color: cs.onSurface.withOpacity(0.2)),
                ),
                title: Row(
                  children: [
                    Text('v$v', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: cs.onSurface)),
                    if (force) ...[
                      const SizedBox(width: 12),
                      _buildForceBadge(),
                    ],
                    const Spacer(),
                    Text(date, style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withOpacity(0.3))),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(notes, style: GoogleFonts.outfit(fontSize: 14, color: cs.onSurface.withOpacity(0.6))),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.verified_user_rounded, size: 14, color: AdminUISystem.kElectricBlue(context)),
                        const SizedBox(width: 6),
                        Text(by, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AdminUISystem.kElectricBlue(context))),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyHistory(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(50),
      width: double.infinity,
      decoration: AdminUISystem.cardDecoration(context),
      child: Column(
        children: [
          Icon(Icons.manage_history_rounded, size: 60, color: cs.onSurface.withOpacity(0.05)),
          const SizedBox(height: 20),
          Text('Dağıtım geçmişi temiz', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _buildForceBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.withOpacity(0.2))),
        child: Text('ZORUNLU', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.red, letterSpacing: 0.5)),
      );
}
