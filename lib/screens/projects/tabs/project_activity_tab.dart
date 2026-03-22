import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/project_model.dart';

class ProjectActivityTab extends StatelessWidget {
  final Project project;

  const ProjectActivityTab({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activities = [
      {
        'title': 'Görev tamamlandı: Arka plan API entegrasyonu',
        'time': '2 saat önce',
        'icon': Icons.check_circle_rounded,
        'color': Colors.green
      },
      {
        'title': 'Yeni not eklendi: Toplantı Notları',
        'time': 'Dün',
        'icon': Icons.note_add_rounded,
        'color': Colors.blue
      },
      {
        'title': 'Proje oluşturuldu',
        'time': '1 hafta önce',
        'icon': Icons.rocket_launch_rounded,
        'color': cs.primary
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Proje Geçmişi',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (activity['color'] as Color)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              activity['icon'] as IconData,
                              size: 16,
                              color: activity['color'] as Color,
                            ),
                          ),
                          if (index < activities.length - 1)
                            Container(
                              width: 2,
                              height: 30,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: cs.outline.withValues(alpha: 0.1),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['title'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity['time'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
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
