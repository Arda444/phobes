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
        urlString.startsWith('http') ? urlString : 'https://$urlString',);
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
            .showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    }
  }

  static const List<int> _resourceColors = [
    0xFF6366F1,
    0xFFEC4899,
    0xFFF59E0B,
    0xFF10B981,
    0xFF3B82F6,
    0xFF8B5CF6,
    0xFF06B6D4,
    0xFFF43F5E,
  ];

  void _showResourceDialog(BuildContext context, {Map<String, dynamic>? initialData, String? docId}) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final titleCtrl = TextEditingController(text: initialData?['title'] ?? '');
    final urlCtrl = TextEditingController(text: initialData?['url'] ?? '');
    final descCtrl = TextEditingController(text: initialData?['description'] ?? '');
    int selectedColor = initialData?['color'] ?? _resourceColors[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: EdgeInsets.zero,
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    docId == null ? l10n.addLinkTitle : l10n.projectEditResource,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.linkTitleHint,
                    labelText: l10n.projectResourceTitleLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.linkUrlHint,
                    labelText: l10n.projectResourceUrlLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.projectResourceDescHint,
                    labelText: l10n.projectResourceDescLabel,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.projectColorSelectionTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.maxFinite,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _resourceColors.map((colorValue) {
                      final bool isSelected = selectedColor == colorValue;
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = colorValue),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(colorValue),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(selectedColor),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                  final data = {
                    'title': titleCtrl.text,
                    'url': urlCtrl.text,
                    'description': descCtrl.text,
                    'color': selectedColor,
                  };

                  if (docId == null) {
                    FirebaseService().addProjectResource(
                      team.id,
                      project.id,
                      titleCtrl.text,
                      urlCtrl.text,
                      description: descCtrl.text,
                      color: selectedColor,
                    );
                  } else {
                    FirebaseService().updateProjectResource(
                        team.id, project.id, docId, data,);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _addResourceDialog(BuildContext context) {
    _showResourceDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.projectResourcesHeader,
                style: GoogleFonts.outfit(
                  color: cs.onSurface.withOpacity(0.5),
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
                    colors: [cs.primary, cs.primary.withOpacity(0.8)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: Colors.white, size: 18,),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.add,
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
                      l10n.projectResourcesEmpty,
                      style: GoogleFonts.outfit(
                          color: cs.onSurface.withOpacity(0.3),),
                    ),
                  );
                }

                final resources = snapshot.data!.docs;
                final bool isWide = MediaQuery.of(context).size.width >= 900;

                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isWide ? 500 : 450,
                    mainAxisExtent: isWide ? 150 : 130,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: resources.length,
                  itemBuilder: (context, index) {
                    final data =
                        resources[index].data() as Map<String, dynamic>;
                    final docId = resources[index].id;
                    return _buildResourceCard(context, data, docId, cs, isWide);
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
      String docId, ColorScheme cs, bool isWide,) {
    final l10n = AppLocalizations.of(context)!;
    final url = data['url'] ?? '';
    final title = data['title'] ?? l10n.projectResourceUntitled;
    final description = data['description'] as String?;
    final color = data['color'] as int? ?? 0xFF6366F1;
    final resourceColor = Color(color);

    return PhobesCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      onTap: url.isNotEmpty ? () => _launchURL(context, url) : null,
      gradient: LinearGradient(
        colors: [
          resourceColor.withOpacity(0.1),
          cs.surfaceVariant.withOpacity(0.5),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Container(
            width: isWide ? 64 : 52,
            height: isWide ? 64 : 52,
            decoration: BoxDecoration(
              color: resourceColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(isWide ? 16 : 12),
              border: Border.all(color: resourceColor.withOpacity(0.2)),
            ),
            child: Icon(Icons.link_rounded, color: resourceColor, size: isWide ? 30 : 26),
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
                    fontSize: isWide ? 18 : 15,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: cs.onSurface.withOpacity(0.6),
                      fontSize: isWide ? 14 : 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: resourceColor.withOpacity(0.7),
                    fontSize: isWide ? 12 : 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz_rounded,
                color: cs.onSurface.withOpacity(0.3),),
            color: cs.surfaceVariant,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (val) {
              if (val == 'delete') {
                FirebaseService()
                    .deleteProjectResource(team.id, project.id, docId);
              } else if (val == 'edit') {
                _showResourceDialog(context, initialData: data, docId: docId);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        color: cs.primary, size: 18,),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.edit,
                        style: GoogleFonts.outfit(
                            color: cs.primary, fontSize: 13,),),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 18,),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.delete,
                        style: GoogleFonts.outfit(
                            color: Colors.redAccent, fontSize: 13,),),
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
