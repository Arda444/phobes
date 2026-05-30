import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/note_model.dart';
import '../../../../models/project_model.dart';
import '../../../../services/firebase_service.dart';
import '../../../../widgets/phobes_widgets.dart';
import '../../notes/note_add_edit_screen.dart';

class ProjectNotesTab extends StatelessWidget {
  final Project project;
  final String teamId;

  const ProjectNotesTab({
    super.key,
    required this.project,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final service = FirebaseService();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.projectNotesTitle,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              PhobesButton(
                text: l10n.newNote,
                icon: Icons.add_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteAddEditScreen(
                        projectId: project.id,
                        teamId: teamId,
                      ),
                    ),
                  );
                },
                isOutlined: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: service.getProjectNotesStream(project.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: PhobesLoadingIndicator(color: cs.primary),
                  );
                }
                final notes = snapshot.data ?? [];
                if (notes.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.projectNoLinkedNotes,
                      style: GoogleFonts.outfit(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return PhobesCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NoteAddEditScreen(
                              existingNote: note,
                              projectId: project.id,
                              teamId: teamId,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title.isEmpty
                                ? l10n.untitledNote
                                : note.title,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          if (note.preview.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              note.preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('d MMM yyyy', locale)
                                .format(note.updatedAt ?? note.date),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: cs.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
