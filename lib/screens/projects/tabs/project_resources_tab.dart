import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/project_model.dart';
import '../../../../models/team_model.dart';
import '../../../../widgets/phobes_widgets.dart';
import '../../../../services/firebase_service.dart';
import '../../../../l10n/app_localizations.dart';

class ProjectResourcesTab extends StatelessWidget {
  final Project project;
  final Team team;

  const ProjectResourcesTab({
    super.key,
    required this.project,
    required this.team,
  });

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final l10n = AppLocalizations.of(context)!;
    final Uri url = Uri.parse(
        urlString.startsWith('http') ? urlString : 'https://$urlString');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.linkError)));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("${l10n.error}: $e")));
      }
    }
  }

  void _addResourceDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        title: Text(l10n.addLinkTitle,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: l10n.linkTitleHint,
                labelText: 'Başlık',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(
                hintText: l10n.linkUrlHint,
                labelText: 'URL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                FirebaseService().addProjectResource(
                  team.id,
                  project.id,
                  titleCtrl.text,
                  urlCtrl.text,
                );
                Navigator.pop(ctx);
              }
            },
            child: Text(l10n.save),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KAYNAKLAR',
                style: GoogleFonts.outfit(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: () => _addResourceDialog(context),
                child: PhobesCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: EdgeInsets.zero,
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Ekle',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseService().getProjectResources(team.id, project.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Henüz kaynak eklenmemiş',
                      style: GoogleFonts.outfit(
                          color: cs.onSurface.withValues(alpha: 0.3)),
                    ),
                  );
                }

                final resources = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 600,
                    mainAxisExtent: 110,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: resources.length,
                  itemBuilder: (context, index) {
                    final data =
                        resources[index].data() as Map<String, dynamic>;
                    final docId = resources[index].id;
                    return _buildResourceCard(context, data, docId, cs);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, Map<String, dynamic> data,
      String docId, ColorScheme cs) {
    final url = data['url'] ?? '';
    final title = data['title'] ?? 'İsimsiz';

    return PhobesCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      onTap: url.isNotEmpty ? () => _launchURL(context, url) : null,
      gradient: LinearGradient(
        colors: [
          cs.primary.withValues(alpha: 0.05),
          cs.surfaceContainer.withValues(alpha: 0.5),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
            ),
            child: Icon(Icons.link_rounded, color: cs.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz_rounded,
                color: cs.onSurface.withValues(alpha: 0.3)),
            color: cs.surfaceContainerHigh,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (val) {
              if (val == 'delete') {
                FirebaseService()
                    .deleteProjectResource(team.id, project.id, docId);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Text('Sil',
                        style: GoogleFonts.outfit(
                            color: Colors.redAccent, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
