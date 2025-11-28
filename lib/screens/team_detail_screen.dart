import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/team_model.dart';
import 'team_kanban_tab.dart';
import 'team_dashboard_tab.dart';
import 'team_resources_tab.dart';
import 'team_activity_tab.dart';
import '../l10n/app_localizations.dart'; // EKLENDİ

class TeamDetailScreen extends StatefulWidget {
  final Team team;
  final int initialIndex;

  const TeamDetailScreen(
      {super.key, required this.team, this.initialIndex = 0});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // EKLENDİ

    final List<Widget> tabs = [
      TeamKanbanTab(team: widget.team),
      TeamDashboardTab(team: widget.team),
      TeamResourcesTab(team: widget.team),
      TeamActivityTab(team: widget.team),
    ];

    // DİL DESTEKLİ BAŞLIKLAR
    final List<String> titles = [
      l10n.tabKanbanTitle,
      l10n.tabDashboardTitle,
      l10n.tabResourcesTitle,
      l10n.tabActivityTitle
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          children: [
            Text(widget.team.name,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16)),
            Text(titles[_currentIndex],
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.tealAccent)),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
              GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
          indicatorColor: const Color(0xFF7B1FA2),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white);
            }
            return const IconThemeData(color: Colors.grey);
          }),
        ),
        child: NavigationBar(
          height: 65,
          backgroundColor: const Color(0xFF151515),
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.view_kanban_outlined),
                selectedIcon: const Icon(Icons.view_kanban),
                label: l10n.tabKanbanTitle), // DİL DESTEĞİ
            NavigationDestination(
                icon: const Icon(Icons.bar_chart_rounded),
                selectedIcon: const Icon(Icons.dashboard),
                label: l10n.tabDashboardTitle), // DİL DESTEĞİ
            NavigationDestination(
                icon: const Icon(Icons.folder_open_rounded),
                selectedIcon: const Icon(Icons.folder),
                label: l10n.tabResourcesTitle), // DİL DESTEĞİ
            NavigationDestination(
                icon: const Icon(Icons.history_rounded),
                selectedIcon: const Icon(Icons.history),
                label: l10n.tabActivityTitle), // DİL DESTEĞİ
          ],
        ),
      ),
    );
  }
}
