import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin_service.dart';
import '../utils/admin_ui_system.dart';

class MaintenanceModeScreen extends StatefulWidget {
  const MaintenanceModeScreen({super.key});

  @override
  State<MaintenanceModeScreen> createState() => _MaintenanceModeScreenState();
}

class _MaintenanceModeScreenState extends State<MaintenanceModeScreen> {
  bool _isMaintenance = false;
  final _maintenanceMsgCtrl = TextEditingController();
  bool _announcementEnabled = false;
  String _announcementType = 'info';
  final _announceTitleCtrl = TextEditingController();
  final _announceMsgCtrl = TextEditingController();
  bool _loading = true;
  bool _savingMaintenance = false;
  bool _savingAnnouncement = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _maintenanceMsgCtrl.dispose();
    _announceTitleCtrl.dispose();
    _announceMsgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await AdminService.getAppConfig();
    if (!mounted) return;
    final ann = config['announcement'] as Map<String, dynamic>? ?? {};
    setState(() {
      _isMaintenance = config['maintenanceMode'] == true;
      _maintenanceMsgCtrl.text = config['maintenanceMessage'] as String? ??
          'Sistem şu anda bakımda. Lütfen daha sonra tekrar deneyiniz.';
      _announcementEnabled = ann['enabled'] == true;
      _announceTitleCtrl.text = ann['title'] as String? ?? '';
      _announceMsgCtrl.text = ann['message'] as String? ?? '';
      _announcementType = ann['type'] as String? ?? 'info';
      _loading = false;
    });
  }

  Future<void> _saveMaintenance() async {
    setState(() => _savingMaintenance = true);
    try {
      await AdminService.setMaintenanceMode(_isMaintenance, _maintenanceMsgCtrl.text.trim());
      if (!mounted) return;
      AdminUISystem.showSuccessSnackBar(context, 'Bakım modu başarıyla güncellendi');
    } catch (e) {
      if (!mounted) return;
      AdminUISystem.showErrorSnackBar(context, 'Hata: $e');
    } finally {
      if (mounted) setState(() => _savingMaintenance = false);
    }
  }

  Future<void> _saveAnnouncement() async {
    setState(() => _savingAnnouncement = true);
    try {
      await AdminService.setAnnouncement(
        enabled: _announcementEnabled,
        title: _announceTitleCtrl.text.trim(),
        message: _announceMsgCtrl.text.trim(),
        type: _announcementType,
      );
      if (!mounted) return;
      AdminUISystem.showSuccessSnackBar(context, 'Global duyuru ayarları kaydedildi');
    } catch (e) {
      if (!mounted) return;
      AdminUISystem.showErrorSnackBar(context, 'Hata: $e');
    } finally {
      if (mounted) setState(() => _savingAnnouncement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sistem Operasyonları', style: AdminUISystem.titleStyle.copyWith(color: cs.onSurface)),
          const SizedBox(height: 4),
          Text('Kritik sistem erişimi ve global iletişim yönetimi', style: AdminUISystem.subtitleStyle(context)),
          const SizedBox(height: 32),
          _buildMaintenanceSection(cs),
          const SizedBox(height: 32),
          _buildAnnouncementSection(cs),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSection(ColorScheme cs) {
    return Container(
      decoration: AdminUISystem.cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _isMaintenance ? Colors.red.withOpacity(0.05) : AdminUISystem.kElectricBlue(context).withOpacity(0.05),
              border: Border(bottom: BorderSide(color: cs.onSurface.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_isMaintenance ? Colors.red : AdminUISystem.kElectricBlue(context)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_isMaintenance ? Icons.construction_rounded : Icons.check_circle_rounded, color: _isMaintenance ? Colors.red : AdminUISystem.kElectricBlue(context)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Global Bakım Modu', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
                      Text(_isMaintenance ? 'Sistem şu an kullanıma kapalı' : 'Sistem aktif ve yayında', style: GoogleFonts.outfit(fontSize: 13, color: _isMaintenance ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Switch(
                  value: _isMaintenance,
                  onChanged: (v) => setState(() => _isMaintenance = v),
                  activeColor: Colors.red,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildField(_maintenanceMsgCtrl, 'Kullanıcı Bilgilendirme Mesajı', Icons.message_rounded, cs, maxLines: 2),
                const SizedBox(height: 24),
                _buildButton(_isMaintenance ? 'BAKIM MODUNU BAŞLAT' : 'SİSTEMİ YAYINA AL', _isMaintenance ? Colors.red : AdminUISystem.kElectricBlue(context), _savingMaintenance, _saveMaintenance),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementSection(ColorScheme cs) {
    final activeColor = _getTypeColor(context, _announcementType);
    return Container(
      decoration: AdminUISystem.cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _announcementEnabled ? activeColor.withOpacity(0.05) : cs.onSurface.withOpacity(0.02),
              border: Border(bottom: BorderSide(color: cs.onSurface.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: activeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.campaign_rounded, color: activeColor),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Global Duyuru Paneli', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
                      Text(_announcementEnabled ? 'Duyuru bandı aktif' : 'Duyuru bandı pasif', style: GoogleFonts.outfit(fontSize: 13, color: cs.onSurface.withOpacity(0.4))),
                    ],
                  ),
                ),
                Switch(value: _announcementEnabled, onChanged: (v) => setState(() => _announcementEnabled = v), activeColor: activeColor),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Öncelik Seviyesi', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface.withOpacity(0.5))),
                const SizedBox(height: 16),
                Row(children: _buildTypeSelectors(cs)),
                const SizedBox(height: 24),
                _buildField(_announceTitleCtrl, 'Duyuru Başlığı', Icons.title_rounded, cs),
                const SizedBox(height: 16),
                _buildField(_announceMsgCtrl, 'Duyuru İçerik Metni', Icons.subject_rounded, cs, maxLines: 2),
                const SizedBox(height: 24),
                _buildButton('DUYURUYU GÜNCELLE', activeColor, _savingAnnouncement, _saveAnnouncement),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, ColorScheme cs, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface.withOpacity(0.5))),
        const SizedBox(height: 10),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.outfit(),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: cs.onSurface.withOpacity(0.3), size: 20),
            filled: true,
            fillColor: cs.onSurface.withOpacity(0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AdminUISystem.kElectricBlue(context))),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String label, Color color, bool loading, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : Text(label, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
      ),
    );
  }

  List<Widget> _buildTypeSelectors(ColorScheme cs) {
    final types = [('info', 'BİLGİ', Icons.info_outline_rounded), ('warning', 'UYARI', Icons.warning_amber_rounded), ('critical', 'KRİTİK', Icons.gpp_maybe_rounded)];
    return types.map((t) {
      final isSelected = _announcementType == t.$1;
      final color = _getTypeColor(context, t.$1);
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _announcementType = t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(right: t.$1 == 'critical' ? 0 : 12),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : cs.onSurface.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
            ),
            child: Column(
              children: [
                Icon(t.$3, color: isSelected ? color : cs.onSurface.withOpacity(0.2), size: 20),
                const SizedBox(height: 8),
                Text(t.$2, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: isSelected ? color : cs.onSurface.withOpacity(0.4))),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _getTypeColor(BuildContext context, String type) {
    if (type == 'warning') return Colors.orange;
    if (type == 'critical') return Colors.red;
    return AdminUISystem.kAccentBlue(context);
  }
}
