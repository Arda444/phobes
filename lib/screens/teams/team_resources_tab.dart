import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/team_model.dart';
import '../../services/firebase_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_widgets.dart';

class TeamResourcesTab extends StatefulWidget {
  final Team team;
  const TeamResourcesTab({super.key, required this.team});

  @override
  State<TeamResourcesTab> createState() => _TeamResourcesTabState();
}

class _TeamResourcesTabState extends State<TeamResourcesTab> {
  Team get team => widget.team;
  late final FirebaseService _service;
  late final Stream<DocumentSnapshot> _teamStream;
  late final Stream<QuerySnapshot> _resourcesStream;

  bool get _isTeamAdmin {
    final uid = _service.currentUserId;
    if (uid == null) return false;
    return team.ownerId == uid || team.adminIds.contains(uid);
  }

  @override
  void initState() {
    super.initState();
    _service = FirebaseService();
    _teamStream = FirebaseFirestore.instance
        .collection('teams')
        .doc(team.id)
        .snapshots();
    _resourcesStream = _service.getTeamResources(team.id);
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

  void _showResourceDialog(BuildContext context,
      {Map<String, dynamic>? initialData, String? docId}) {
    final l10n = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController(text: initialData?['title'] ?? '');
    final urlCtrl = TextEditingController(text: initialData?['url'] ?? '');
    final descCtrl =
        TextEditingController(text: initialData?['description'] ?? '');
    int selectedColor = initialData?['color'] ?? _resourceColors[0];
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: cs.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                    docId == null ? l10n.addLinkTitle : l10n.teamEditResourceTitle,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: l10n.linkTitleHint,
                      labelText: l10n.teamResourceTitleLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlCtrl,
                    decoration: InputDecoration(
                      hintText: l10n.linkUrlHint,
                      labelText: l10n.teamResourceUrlLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l10n.teamResourceDescriptionHint,
                      labelText: l10n.teamResourceDescriptionLabel,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.teamResourceColorSelection,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.7),
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
                          onTap: () =>
                              setState(() => selectedColor = colorValue),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(colorValue),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? cs.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
                    FirebaseService().addTeamLink(
                      team.id,
                      titleCtrl.text,
                      urlCtrl.text,
                      description: descCtrl.text,
                      color: selectedColor,
                    );
                  } else {
                    FirebaseService().updateTeamResource(team.id, docId, data);
                  }
                  Navigator.pop(context);
                }
              },
              child:
                  Text(l10n.save, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _editAnnouncement(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  l10n.makeAnnouncement,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: l10n.announcementHint,
                    labelText: l10n.teamAnnouncementContentLabel,
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
              backgroundColor: cs.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              FirebaseService().updateTeamAnnouncement(team.id, ctrl.text);
              Navigator.pop(context);
            },
            child: Text(l10n.publish, style: TextStyle(color: cs.onPrimary)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final l10n = AppLocalizations.of(context)!;
    final Uri url = Uri.parse(
      urlString.startsWith('http') ? urlString : 'https://$urlString',
    );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final bool isWide = MediaQuery.of(context).size.width >= 900;

    return StreamBuilder<DocumentSnapshot>(
      stream: _teamStream,
      builder: (context, teamSnapshot) {
        final teamData = teamSnapshot.data?.data() as Map<String, dynamic>?;
        final announcement = teamData?['announcement'] as String?;

        return StreamBuilder<QuerySnapshot>(
          stream: _resourcesStream,
          builder: (context, resourcesSnapshot) {
            final docs = resourcesSnapshot.data?.docs ?? [];

            return CustomScrollView(
              primary: false,
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: PhobesCard(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withOpacity(0.15),
                        cs.surfaceVariant.withOpacity(0.5),
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
                            Text(
                              l10n.announcements,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const Spacer(),
                            if (_isTeamAdmin)
                              PhobesIconButton(
                                icon: Icons.edit_rounded,
                                iconSize: 14,
                                onTap: () => _editAnnouncement(context),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          announcement ?? l10n.noAnnouncements,
                          style: GoogleFonts.outfit(
                            color: cs.onSurface.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.resourcesTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        if (_isTeamAdmin)
                          PhobesButton(
                            text: l10n.add,
                            icon: Icons.add_rounded,
                            width: 100,
                            onPressed: () => _showResourceDialog(context),
                          ),
                      ],
                    ),
                  ),
                ),
                if (docs.isEmpty &&
                    resourcesSnapshot.connectionState !=
                        ConnectionState.waiting)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Center(
                        child: Text(
                          l10n.noResourcesYet,
                          style: GoogleFonts.outfit(
                              color: cs.onSurface.withOpacity(0.3)),
                        ),
                      ),
                    ),
                  )
                else if (resourcesSnapshot.connectionState ==
                    ConnectionState.waiting)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: isWide ? 500 : 450,
                        mainAxisExtent: isWide ? 150 : 130,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          return _buildResourceCard(
                            context,
                            data,
                            docs[index].id,
                            team.id,
                            cs,
                            isWide,
                          );
                        },
                        childCount: docs.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildResourceCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    String teamId,
    ColorScheme cs,
    bool isWide,
  ) {
    final url = data['url'] ?? '';
    final title = data['title'] ?? AppLocalizations.of(context)!.teamUnnamedResource;
    final description = data['description'] as String?;
    final colorValue = data['color'] as int? ?? 0xFF6366F1;
    final resourceColor = Color(colorValue);

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
            child: Icon(Icons.link_rounded,
                color: resourceColor, size: isWide ? 30 : 26),
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
          if (_isTeamAdmin)
            PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: cs.onSurface.withOpacity(0.3),
            ),
            color: cs.surfaceVariant,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: cs.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.edit,
                        style: GoogleFonts.outfit(
                            color: cs.primary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.delete,
                        style: GoogleFonts.outfit(
                            color: Colors.redAccent, fontSize: 13)),
                  ],
                ),
              ),
            ],
            onSelected: (val) {
              if (val == 'delete') {
                FirebaseService().deleteTeamResource(teamId, docId);
              } else if (val == 'edit') {
                _showResourceDialog(context, initialData: data, docId: docId);
              }
            },
          ),
        ],
      ),
    );
  }
}
