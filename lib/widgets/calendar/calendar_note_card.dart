import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../phobes_widgets.dart';

class CalendarNoteCard extends StatelessWidget {
  final String noteText;
  final String title;
  final VoidCallback onTap;

  const CalendarNoteCard({
    super.key,
    required this.noteText,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FadeInUp(
      child: PhobesGlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: cs.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                PhobesIconButton(
                  icon: Icons.edit_rounded,
                  iconSize: 14,
                  padding: 6,
                  color: cs.primary,
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  onTap: onTap,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 1,
              width: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0)],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                noteText,
                style: GoogleFonts.outfit(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 7,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                Icons.notes_rounded,
                size: 16,
                color: cs.onSurface.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
