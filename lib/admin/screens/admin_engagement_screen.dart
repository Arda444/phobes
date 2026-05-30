import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notification_templates_screen.dart';
import 'feedback_management_screen.dart';
import 'surveys_screen.dart';
import 'broadcast_admin_screen.dart';

class AdminEngagementScreen extends StatelessWidget {
  const AdminEngagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
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
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tabs: const [
                Tab(text: 'Bildirimler', icon: Icon(Icons.notifications_active_rounded, size: 18)),
                Tab(text: 'Popup Duyuru', icon: Icon(Icons.campaign_rounded, size: 18)),
                Tab(text: 'Geri Bildirim', icon: Icon(Icons.feedback_rounded, size: 18)),
                Tab(text: 'Anket', icon: Icon(Icons.poll_rounded, size: 18)),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                NotificationTemplatesScreen(),
                BroadcastAdminScreen(),
                FeedbackManagementScreen(),
                SurveysScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
