import 'package:flutter/material.dart';
import '../../models/team_model.dart';
import '../notes/notes_screen.dart';

class TeamNotesTab extends StatelessWidget {
  final Team team;

  const TeamNotesTab({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    // Navigate or display NotesScreen specifically filtered for this team
    // For now, embedding NotesScreen but we will modify NotesScreen to easily accept a team filter
    return NotesScreen(
      teamFilterId: team.id,
      isEmbedded: true,
    );
  }
}
