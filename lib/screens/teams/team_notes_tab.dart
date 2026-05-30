import 'package:flutter/material.dart';
import '../../models/team_model.dart';
import '../notes/notes_screen.dart';

class TeamNotesTab extends StatelessWidget {
  final Team team;

  const TeamNotesTab({super.key, required this.team});

  @override
  Widget build(BuildContext context) {

    return NotesScreen(
      teamFilterId: team.id,
      isEmbedded: true,
    );
  }
}
