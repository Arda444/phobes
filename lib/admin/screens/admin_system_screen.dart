import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'analytics_screen.dart';
import 'version_management_screen.dart';
import 'maintenance_mode_screen.dart';
import 'audit_logs_screen.dart';
import 'session_history_screen.dart';
import 'data_cleanup_screen.dart';

class AdminSystemScreen extends StatelessWidget {
  const AdminSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.2),
              border: Border(
                bottom: BorderSide(color: cs.outline.withOpacity(0.08)),
              ),
            ),
            child: TabBar(
              isScrollable: true,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurface.withOpacity(0.4),
              indicatorColor: cs.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tabs: const [
                Tab(text: 'Analitik', icon: Icon(Icons.analytics_rounded, size: 18)),
                Tab(text: 'Sürüm Kontrolü', icon: Icon(Icons.system_update_rounded, size: 18)),
                Tab(text: 'Bakım', icon: Icon(Icons.construction_rounded, size: 18)),
                Tab(text: 'Loglar', icon: Icon(Icons.receipt_long_rounded, size: 18)),
                Tab(text: 'Oturumlar', icon: Icon(Icons.history_rounded, size: 18)),
                Tab(text: 'Arşiv', icon: Icon(Icons.archive_rounded, size: 18)),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                AnalyticsScreen(),
                VersionManagementScreen(),
                MaintenanceModeScreen(),
                AuditLogsScreen(),
                SessionHistoryScreen(),
                DataCleanupScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
