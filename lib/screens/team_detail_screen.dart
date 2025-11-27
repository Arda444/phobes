import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/team_model.dart';
import 'team_kanban_tab.dart';
import 'team_dashboard_tab.dart';
import 'team_resources_tab.dart';
import 'team_activity_tab.dart';

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
    // Sekmeler Listesi
    final List<Widget> tabs = [
      TeamKanbanTab(team: widget.team), // 0
      TeamDashboardTab(team: widget.team), // 1
      TeamResourcesTab(team: widget.team), // 2
      TeamActivityTab(team: widget.team), // 3
    ];

    // Başlıklar
    final List<String> titles = ["İş Panosu", "Pano", "Kaynaklar", "Aktivite"];

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
        actions: const [
          // Ayarlar butonu KALDIRILDI
        ],
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
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.view_kanban_outlined),
                selectedIcon: Icon(Icons.view_kanban),
                label: "İşler"),
            NavigationDestination(
                icon: Icon(Icons.bar_chart_rounded),
                selectedIcon: Icon(Icons.dashboard),
                label: "Pano"),
            NavigationDestination(
                icon: Icon(Icons.folder_open_rounded),
                selectedIcon: Icon(Icons.folder),
                label: "Kaynak"),
            NavigationDestination(
                icon: Icon(Icons.history_rounded),
                selectedIcon: Icon(Icons.history),
                label: "Aktivite"),
          ],
        ),
      ),
    );
  }
}
