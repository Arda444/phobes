import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/admin_ui_system.dart';
import '../admin_service.dart';
import '../../l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  Future<void> _loadAllStats() async {
    final stats = await AdminService.getDashboardStats();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadAllStats,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AdminUISystem.horizontalPadding(context)),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(context, cs),
            const SizedBox(height: 32),
            _buildStatsGrid(context, cs),
            const SizedBox(height: 40),
            _buildSectionHeader(cs, l10n.adminSystemModules, l10n.adminModulesSubtitle),
            const SizedBox(height: 20),
            _buildModuleGrid(cs, isDark),
            const SizedBox(height: 40),
            _buildSectionHeader(cs, l10n.adminRecentActivity, l10n.adminRecentActivitySubtitle),
            const SizedBox(height: 20),
            _buildRecentActivitySection(cs, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email?.split('@').first ?? 'Admin';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.adminWelcome(name),
          style: AdminUISystem.titleStyle.copyWith(color: cs.onSurface, fontSize: 28),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.adminSystemStatusStable,
          style: AdminUISystem.subtitleStyle(context),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, ColorScheme cs) {
    return LayoutBuilder(builder: (context, constraints) {
      const double spacing = 20;
      final int crossCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
      final double itemWidth = (constraints.maxWidth - (spacing * (crossCount - 1))) / crossCount;

      final l10n = AppLocalizations.of(context)!;
      final cards = [
        AdminUISystem.buildStatCard(
          context: context,
          title: l10n.adminTotalUsers,
          value: '${_stats?['totalUsers'] ?? '...'}',
          icon: Icons.people_rounded,
          color: AdminUISystem.kElectricBlue(context),
        ),
        AdminUISystem.buildStatCard(
          context: context,
          title: 'Aktif (7 gün)',
          value: '${_stats?['activeUsers7d'] ?? '...'}',
          icon: Icons.bolt_rounded,
          color: Colors.green,
        ),
        AdminUISystem.buildStatCard(
          context: context,
          title: l10n.adminOpenFeedback,
          value: '${_stats?['openFeedback'] ?? '...'}',
          icon: Icons.feedback_rounded,
          color: AdminUISystem.kCyberPink(context),
        ),
        AdminUISystem.buildStatCard(
          context: context,
          title: l10n.adminActiveSurveys,
          value: '${_stats?['activeSurveys'] ?? '...'}',
          icon: Icons.poll_rounded,
          color: Colors.amber.shade600,
        ),
      ];

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: cards.map((c) => ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: itemWidth,
            minWidth: itemWidth,
            minHeight: 150,
          ),
          child: c,
        ),).toList(),
      );
    },);
  }

  Widget _buildSectionHeader(ColorScheme cs, String title, String subtitle) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            Text(subtitle, style: AdminUISystem.subtitleStyle(context)),
          ],
        ),
        const Spacer(),
        if (_loading)
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      ],
    );
  }

  Widget _buildModuleGrid(ColorScheme cs, bool isDark) {
    final modules = [
      _ModuleItem(Icons.manage_accounts_rounded, 'Kullanıcılar', Colors.cyan, 1, 'Kullanıcı & Rol Yönetimi'), // index 1
      _ModuleItem(Icons.notifications_active_rounded, 'Engagement', Colors.orange, 2, 'Bildirim & Geri Bildirim'), // index 2
      _ModuleItem(Icons.system_update_rounded, 'Sistem Ayarları', Colors.indigo, 3, 'Log & Bakım Modu'), // index 3
    ];

    return LayoutBuilder(builder: (context, constraints) {
      const double spacing = 16;
      final int crossCount = constraints.maxWidth > 1400 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
      final double itemWidth = (constraints.maxWidth - (spacing * (crossCount - 1))) / crossCount;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: modules.map((m) => ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: itemWidth,
            minWidth: itemWidth,
            minHeight: 90,
          ),
          child: _buildModuleCard(context, m, cs),
        ),).toList(),
      );
    },);
  }

  Widget _buildModuleCard(BuildContext context, _ModuleItem m, ColorScheme cs) {
    return InkWell(
      onTap: () => widget.onNavigate?.call(m.index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: AdminUISystem.cardDecoration(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: m.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(m.icon, color: m.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.label,
                    style: AdminUISystem.cardTitle.copyWith(color: cs.onSurface, fontSize: 16),
                  ),
                  Text(
                    m.stat,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurface.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(ColorScheme cs, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: AdminUISystem.cardDecoration(context),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: AdminService.auditLogsStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Aktivite yüklenemedi: ${snap.error}'),
            );
          }
          final docs = snap.data?.docs.take(10).toList() ?? [];
          if (docs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Henüz kayıt yok', style: AdminUISystem.subtitleStyle(context)),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: cs.outline.withOpacity(0.04)),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final action = d['action'] as String? ?? '';
              final detail = d['detail'] as String? ?? '';
              final ts = (d['timestamp'] as Timestamp?)?.toDate();
              final time = ts != null
                  ? DateFormat('dd.MM HH:mm').format(ts)
                  : '';
              return _ActivityItem(
                title: detail.isNotEmpty ? '$action — $detail' : action,
                time: time,
                icon: Icons.history_rounded,
                color: AdminUISystem.kElectricBlue(context),
              );
            },
          );
        },
      ),
    );
  }
}

class _ModuleItem {
  final IconData icon;
  final String label;
  final Color color;
  final int index;
  final String stat;
  _ModuleItem(this.icon, this.label, this.color, this.index, this.stat);
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;
  const _ActivityItem({required this.title, required this.time, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: cs.onSurface))),
          Text(time, style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withOpacity(0.4))),
        ],
      ),
    );
  }
}
