import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/project_model.dart';
import '../../../../widgets/phobes_widgets.dart';

class ProjectStatisticsTab extends StatelessWidget {
  final Project project;

  const ProjectStatisticsTab({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Proje İstatistikleri',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Toplam Görev',
                      value: '24',
                      icon: Icons.task_alt_rounded,
                      color: Colors.blueAccent,
                      cs: cs,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Tamamlanan',
                      value: '18',
                      icon: Icons.check_circle_rounded,
                      color: Colors.greenAccent,
                      cs: cs,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Geciken',
                      value: '2',
                      icon: Icons.warning_rounded,
                      color: Colors.redAccent,
                      cs: cs,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Harcanan Efor',
                      value: '120 sa',
                      icon: Icons.timer_rounded,
                      color: Colors.orangeAccent,
                      cs: cs,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PhobesCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.bar_chart_rounded,
                        size: 64, color: cs.primary.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'Detaylı grafikler yakında eklenecek',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ColorScheme cs,
  }) {
    return PhobesCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
