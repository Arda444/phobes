import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/team_model.dart';
import '../l10n/app_localizations.dart';
import 'team_activity_tab.dart'; // Aktivite widget'ını kullanıyoruz

class TeamActivityScreen extends StatelessWidget {
  final Team team;
  const TeamActivityScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.tabActivity,
            style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: TeamActivityTab(teamId: team.id),
    );
  }
}
