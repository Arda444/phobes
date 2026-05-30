import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/team_model.dart';
import '../../services/firebase_service.dart';
import '../../l10n/app_localizations.dart';
import 'team_detail_screen.dart';

/// Shell center route for `/teams/:teamId` (web wide layout).
class TeamDetailRouteScreen extends StatelessWidget {
  final String teamId;
  final Team? team;

  const TeamDetailRouteScreen({
    super.key,
    required this.teamId,
    this.team,
  });

  @override
  Widget build(BuildContext context) {
    if (team != null && team!.id == teamId) {
      return TeamDetailScreen(team: team!);
    }

    return StreamBuilder<List<Team>>(
      stream: FirebaseService().getUserTeamsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final teams = snapshot.data ?? [];
        Team? resolved;
        for (final t in teams) {
          if (t.id == teamId) {
            resolved = t;
            break;
          }
        }

        if (resolved == null) {
          final l10n = AppLocalizations.of(context)!;
          return Center(
            child: Text(
              l10n.teamNotFound,
              style: GoogleFonts.outfit(fontSize: 16),
            ),
          );
        }

        return TeamDetailScreen(team: resolved);
      },
    );
  }
}
