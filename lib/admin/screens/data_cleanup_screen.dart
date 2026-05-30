import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../admin_service.dart';
import '../utils/admin_ui_system.dart';

class DataCleanupScreen extends StatefulWidget {
  const DataCleanupScreen({super.key});

  @override
  State<DataCleanupScreen> createState() => _DataCleanupScreenState();
}

class _DataCleanupScreenState extends State<DataCleanupScreen> {
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 90));
  bool _running = false;
  String? _lastResult;

  final _collections = [
    {'id': 'activityLogs', 'label': 'Aktivite Logları', 'icon': Icons.history_rounded, 'desc': 'Kullanıcı etkileşim verileri'},
    {'id': 'auditLogs', 'label': 'Denetim Kayıtları', 'icon': Icons.gpp_maybe_rounded, 'desc': 'Yönetici işlem kayıtları'},
    {'id': 'feedback', 'label': 'Geri Bildirimler', 'icon': Icons.feedback_rounded, 'desc': 'Kullanıcı geri dönüşleri'},
  ];

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AdminUISystem.kElectricBlue(context)),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) setState(() => _selectedDate = date);
  }

  Future<void> _runCleanup(String collection, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 12),
            Text('Kritik İşlem Onayı', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('"$label" koleksiyonundan ${DateFormat('dd.MM.yyyy').format(_selectedDate)} öncesi tüm veriler KALICI olarak silinecek.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İPTAL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('VERİLERİ TEMİZLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _running = true;
      _lastResult = null;
    });
    try {
      final count = await AdminService.deleteOldDocuments(collection, _selectedDate);
      if (!mounted) return;
      setState(() => _lastResult = '$label: $count kayıt başarıyla temizlendi');
      AdminUISystem.showSuccessSnackBar(context, _lastResult!);
    } catch (e) {
      if (!mounted) return;
      AdminUISystem.showErrorSnackBar(context, 'Hata: $e');
    } finally {
      if (mounted) setState(() => _running = false);
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
                  Text('Veri Yönetimi & Hijyen', style: AdminUISystem.titleStyle.copyWith(color: cs.onSurface)),
                  const SizedBox(height: 4),
                  Text('Sistem performansını artırmak için eski verileri temizleyin', style: AdminUISystem.subtitleStyle(context)),
                ],
              ),
              _buildSafetyIndicator(),
            ],
          ),
          const SizedBox(height: 32),
          _buildFilterSection(cs),
          const SizedBox(height: 32),
          Text('Koleksiyon Denetimi', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 16),
          ..._collections.map((col) => _buildCollectionCard(col, cs)),
          if (_lastResult != null) _buildResultBanner(),
        ],
      ),
    );
  }

  Widget _buildSafetyIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_rounded, size: 14, color: Colors.orange),
          const SizedBox(width: 8),
          Text('KRİTİK MOD', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildFilterSection(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AdminUISystem.cardDecoration(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Eşik Tarihi Belirleyin', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Bu tarihten önceki tüm veriler hedef alınacaktır.', style: GoogleFonts.outfit(fontSize: 13, color: cs.onSurface.withOpacity(0.4))),
              ],
            ),
          ),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AdminUISystem.kElectricBlue(context).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdminUISystem.kElectricBlue(context).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 18, color: AdminUISystem.kElectricBlue(context)),
                  const SizedBox(width: 12),
                  Text(DateFormat('dd MMMM yyyy', 'tr').format(_selectedDate), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AdminUISystem.kElectricBlue(context))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionCard(Map<String, dynamic> col, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AdminUISystem.cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
          child: Icon(col['icon'] as IconData, color: Colors.red, size: 24),
        ),
        title: Text(col['label'] as String, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text(col['desc'] as String, style: GoogleFonts.outfit(fontSize: 13, color: cs.onSurface.withOpacity(0.4))),
        trailing: ElevatedButton(
          onPressed: _running ? null : () => _runCleanup(col['id'] as String, col['label'] as String),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.1),
            foregroundColor: Colors.red,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ).copyWith(
            side: WidgetStateProperty.all(BorderSide(color: Colors.red.withOpacity(0.2))),
          ),
          child: _running 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
              : Text('TEMİZLE', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Widget _buildResultBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminUISystem.kElectricBlue(context).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminUISystem.kElectricBlue(context).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AdminUISystem.kElectricBlue(context)),
          const SizedBox(width: 16),
          Expanded(child: Text(_lastResult!, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AdminUISystem.kElectricBlue(context)))),
        ],
      ),
    );
  }
}
