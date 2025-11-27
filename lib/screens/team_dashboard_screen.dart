import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/team_model.dart';
import '../l10n/app_localizations.dart';
import 'team_dashboard_tab.dart'; // Tab widget'ı

class TeamDashboardScreen extends StatelessWidget {
  final Team team;
  const TeamDashboardScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(l10n.tabDashboard,
            style: GoogleFonts.poppins(color: Colors.white)),
      ),
      // HATA ÇÖZÜMÜ: Artık 'tasks' değil, 'team' gönderiyoruz.
      // Veri çekme işlemini TeamDashboardTab kendi içinde yapıyor.
      body: TeamDashboardTab(team: team),
    );
  }
}
