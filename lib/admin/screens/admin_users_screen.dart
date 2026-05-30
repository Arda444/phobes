import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_list_screen.dart';
import 'segmentation_screen.dart';
import 'blacklist_screen.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
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
                Tab(text: 'Kullanıcı Listesi', icon: Icon(Icons.people_rounded, size: 18)),
                Tab(text: 'Segmentler', icon: Icon(Icons.pie_chart_rounded, size: 18)),
                Tab(text: 'Kara Liste', icon: Icon(Icons.block_rounded, size: 18)),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                UserListScreen(),
                SegmentationScreen(),
                BlacklistScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
