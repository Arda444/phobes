import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/team_model.dart';
import 'team_activity_tab.dart';

class TeamActivityScreen extends StatelessWidget {
  final Team team;
  const TeamActivityScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    // Localization getter hatasını önlemek için geçici sabit metin veya try-catch
    // final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("Aktivite", // l10n.tabActivity yerine sabit
            style: GoogleFonts.poppins(color: Colors.white)),
      ),
      // HATA ÇÖZÜMÜ: teamId yerine team objesi gönderiliyor
      body: TeamActivityTab(team: team),
    );
  }
}
