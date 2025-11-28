import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/team_model.dart';
import '../services/firebase_service.dart';
import '../l10n/app_localizations.dart';

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
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.addLinkTitle,
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    hintText: l10n.linkTitleHint,
                    hintStyle: const TextStyle(color: Colors.grey))),
            TextField(
                controller: urlCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    hintText: l10n.linkUrlHint,
                    hintStyle: const TextStyle(color: Colors.grey))),
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
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.makeAnnouncement,
            style: const TextStyle(color: Colors.white)),
        content: TextField(
            controller: ctrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
                hintText: l10n.announcementHint,
                hintStyle: const TextStyle(color: Colors.grey))),
        actions: [
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      floatingActionButton: FloatingActionButton(
        heroTag: 'resources_fab',
        backgroundColor: const Color(0xFF009688),
        onPressed: () => _addLinkDialog(context),
        child: const Icon(Icons.link, color: Colors.white),
      ),
      body: Center(
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

                    return Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.deepPurple.shade900,
                            Colors.blue.shade900
                          ]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.campaign,
                                  color: Colors.orangeAccent),
                              const SizedBox(width: 8),
                              Text(l10n.announcements,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              const Spacer(),
                              IconButton(
                                  icon: const Icon(Icons.edit,
                                      size: 16, color: Colors.white54),
                                  onPressed: () => _editAnnouncement(context))
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(announcement ?? l10n.noAnnouncements,
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Text(l10n.resourcesTitle,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
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

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return Card(
                          color: const Color(0xFF1E1E1E),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.link, color: Colors.blue),
                            ),
                            title: Text(data['title'],
                                style:
                                    GoogleFonts.poppins(color: Colors.white)),
                            subtitle: Text(data['url'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () => service.deleteTeamResource(
                                  team.id, docs[index].id),
                            ),
                            onTap: () => _launchURL(context, data['url']),
                          ),
                        );
                      },
                      childCount: docs.length,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
