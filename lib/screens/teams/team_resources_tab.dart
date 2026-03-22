import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/team_model.dart';
import '../../services/firebase_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_widgets.dart';

class TeamResourcesTab extends StatelessWidget {
  final Team team;
  const TeamResourcesTab({super.key, required this.team});

  void _addLinkDialog(BuildContext context) {
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
                )),
            const SizedBox(height: 12),
            TextField(
                controller: urlCtrl,
                decoration: InputDecoration(
                  hintText: l10n.linkUrlHint,
                  labelText: 'URL',
                )),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2)),
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                FirebaseService()
                    .addTeamLink(team.id, titleCtrl.text, urlCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _editAnnouncement(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        title: Text(l10n.makeAnnouncement,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
                hintText: l10n.announcementHint, labelText: 'İçerik')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              FirebaseService().updateTeamAnnouncement(team.id, ctrl.text);
              Navigator.pop(ctx);
            },
            child: Text(l10n.publish),
          )
        ],
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();
    final l10n = AppLocalizations.of(context)!;

    final cs = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('teams')
                    .doc(team.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final announcement = data?['announcement'] as String?;

                  return PhobesCard(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withValues(alpha: 0.15),
                        cs.surfaceContainer.withValues(alpha: 0.5),
                      ],
                      begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.campaign, color: cs.primary),
                              const SizedBox(width: 8),
                              Text(l10n.announcements,
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface)),
                              const Spacer(),
                              PhobesIconButton(
                                icon: Icons.edit_rounded,
                                iconSize: 14,
                                onTap: () => _editAnnouncement(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(announcement ?? l10n.noAnnouncements,
                              style: GoogleFonts.outfit(
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                  fontSize: 13)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.resourcesTitle,
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface)),
                      PhobesCard(
                        onTap: () => _addLinkDialog(context),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        gradient: LinearGradient(
                          colors: [
                            cs.primary,
                            cs.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Ekle",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: service.getTeamResources(team.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()));
                  }
                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                            child: Text(l10n.noResourcesYet,
                                style: const TextStyle(color: Colors.grey))),
                      ),
                    );
                  }

                  final bool isWide = MediaQuery.of(context).size.width >= 900;

                  if (isWide) {
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 600,
                          mainAxisExtent: 110,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            return _buildResourceCard(
                                context, data, docs[index].id, team.id, cs);
                          },
                          childCount: docs.length,
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return _buildResourceCard(
                            context, data, docs[index].id, team.id, cs);
                      },
                      childCount: docs.length,
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildResourceCard(BuildContext context, Map<String, dynamic> data,
      String docId, String teamId, ColorScheme cs) {
    final url = data['url'] ?? '';
    final title = data['title'] ?? 'İsimsiz';

    return PhobesCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
            onSelected: (val) {
              if (val == 'delete') {
                FirebaseService().deleteTeamResource(teamId, docId);
              }
            },
          ),
        ],
      ),
    );
  }
}
