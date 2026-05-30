import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/admin_ui_system.dart';

class SegmentationScreen extends StatefulWidget {
  const SegmentationScreen({super.key});

  @override
  State<SegmentationScreen> createState() => _SegmentationScreenState();
}

class _SegmentationScreenState extends State<SegmentationScreen> {
  bool _loading = true;
  int? _totalUsers;
  int? _newUsers;
  int? _activeUsers;

  @override
  void initState() {
    super.initState();
    _loadSegments();
  }

  Future<void> _loadSegments() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = Timestamp.fromDate(now.subtract(const Duration(days: 30)));
      final sevenDaysAgo = Timestamp.fromDate(now.subtract(const Duration(days: 7)));

      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').count().get(),
        FirebaseFirestore.instance.collection('users').where('createdAt', isGreaterThan: thirtyDaysAgo).count().get(),
        FirebaseFirestore.instance.collection('users').where('lastLogin', isGreaterThan: sevenDaysAgo).count().get(),
      ]);

      if (!mounted) return;
      setState(() {
        _totalUsers = results[0].count;
        _newUsers = results[1].count;
        _activeUsers = results[2].count;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = _totalUsers ?? 0;

    final segments = [
      _SegmentData(
        label: 'Global Kullanıcı Kitlesi',
        desc: 'Sisteme kayıtlı tüm aktif ve pasif profiller',
        count: _totalUsers,
        color: AdminUISystem.kElectricBlue(context),
        icon: Icons.public_rounded,
        percent: 100,
      ),
      _SegmentData(
        label: 'Aktif Etkileşim Grubu',
        desc: 'Son 7 gün içerisinde sistemde işlem yapanlar',
        count: _activeUsers,
        color: AdminUISystem.kAccentBlue(context),
        icon: Icons.bolt_rounded,
        percent: (total > 0 && _activeUsers != null) ? (_activeUsers! / total * 100).round() : 0,
      ),
      _SegmentData(
        label: 'Yeni Katılımcılar',
        desc: 'Son 30 gün verilerine göre yeni kayıtlar',
        count: _newUsers,
        color: AdminUISystem.kNeonPurple(context),
        icon: Icons.auto_awesome_rounded,
        percent: (total > 0 && _newUsers != null) ? (_newUsers! / total * 100).round() : 0,
      ),
    ];

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
                  Text('Segment Analitiği', style: AdminUISystem.titleStyle.copyWith(color: cs.onSurface)),
                  const SizedBox(height: 4),
                  Text('Kullanıcı dağılımı ve demografik performans takibi', style: AdminUISystem.subtitleStyle(context)),
                ],
              ),
              _buildRefreshButton(cs),
            ],
          ),
          const SizedBox(height: 32),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.only(top: 100), child: CircularProgressIndicator()))
          else
            ...segments.map((s) => _buildSegmentCard(s, cs)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(color: AdminUISystem.kElectricBlue(context).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: IconButton(
        icon: Icon(Icons.refresh_rounded, color: AdminUISystem.kElectricBlue(context)),
        onPressed: () {
          setState(() => _loading = true);
          _loadSegments();
        },
      ),
    );
  }

  Widget _buildSegmentCard(_SegmentData s, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: AdminUISystem.cardDecoration(context).copyWith(
        border: Border.all(color: s.color.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: s.color.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
                child: Icon(s.icon, color: s.color, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.label, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(s.desc, style: GoogleFonts.outfit(fontSize: 13, color: cs.onSurface.withOpacity(0.4))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(s.count?.toString() ?? '—', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: s.color, letterSpacing: -1)),
                  Text('Kullanıcı', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: s.color.withOpacity(0.5), letterSpacing: 0.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildProgressBar(s),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('%${s.percent} Toplam pay', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onSurface.withOpacity(0.3))),
              if (s.percent > 0) Icon(Icons.show_chart_rounded, size: 16, color: s.color.withOpacity(0.4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(_SegmentData s) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Container(height: 8, width: double.infinity, color: s.color.withOpacity(0.05)),
          LayoutBuilder(
            builder: (context, constraints) => AnimatedContainer(
              duration: const Duration(seconds: 1),
              curve: Curves.easeOutQuart,
              height: 8,
              width: constraints.maxWidth * (s.percent / 100),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [s.color, s.color.withOpacity(0.6)]),
                boxShadow: [BoxShadow(color: s.color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 2))],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentData {
  final String label;
  final String desc;
  final int? count;
  final Color color;
  final IconData icon;
  final int percent;

  _SegmentData({
    required this.label,
    required this.desc,
    required this.count,
    required this.color,
    required this.icon,
    required this.percent,
  });
}
