import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/project_model.dart';
import '../../../../widgets/phobes_widgets.dart';

class ProjectNotesTab extends StatelessWidget {
  final Project project;

  const ProjectNotesTab({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tüm Notlar',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              PhobesButton(
                text: 'Yeni Not',
                icon: Icons.add_rounded,
                onPressed: () {},
                isOutlined: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: 3, // Placeholder count
              itemBuilder: (context, index) {
                return PhobesCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  onTap: () {},
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Örnek Not Başlığı ${index + 1}',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          Icon(Icons.more_horiz_rounded,
                              color: cs.onSurface.withValues(alpha: 0.5)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bu, projeyle ilgili örnek bir not içeriğidir. Daha fazla detay eklenebilir.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 12,
                              color: cs.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 6),
                          Text(
                            '2 saat önce',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
