import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/team_model.dart';
import '../../services/firebase_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_widgets.dart';

class TeamAddEditScreen extends StatefulWidget {
  final Team team;
  const TeamAddEditScreen({super.key, required this.team});

  @override
  State<TeamAddEditScreen> createState() => _TeamAddEditScreenState();
}

class _TeamAddEditScreenState extends State<TeamAddEditScreen> {
  final FirebaseService _service = FirebaseService();

  bool _isOwner = false;
  bool _isAdmin = false;
  bool _isLoading = false;

  String _displayTeamName = "";
  List<Map<String, dynamic>> _membersData = [];

  @override
  void initState() {
    super.initState();
    _displayTeamName = widget.team.name;
    final String? userId = _service.currentUserId;
    if (userId != null) {
      _isOwner = userId == widget.team.ownerId;
      _isAdmin = widget.team.adminIds.contains(userId);
    }
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (widget.team.memberIds.isEmpty) return;
    try {
      final members = await _service.getUsersByIds(widget.team.memberIds);
      if (mounted) setState(() => _membersData = members);
    } catch (e) {
      debugPrint("Üye hatası: $e");
    }
  }

  void _showEditNameDialog() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _displayTeamName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(l10n.editInfo, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: l10n.teamName,
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.purple)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _updateTeamName(controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTeamName(String newName) async {
    setState(() => _isLoading = true);
    try {
      final updatedTeam = Team(
        id: widget.team.id,
        name: newName,
        ownerId: widget.team.ownerId,
        memberIds: widget.team.memberIds,
        adminIds: widget.team.adminIds,
        joinCode: widget.team.joinCode,
        createdAt: widget.team.createdAt,
      );

      await _service.updateTeam(updatedTeam);

      if (mounted) {
        setState(() {
          _displayTeamName = newName;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.infoUpdated)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  void _showMemberMenu(Map<String, dynamic> member) {
    final String mId = member['id'];
    if (mId == widget.team.ownerId) return;

    if (!_isOwner && !_isAdmin) return;

    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.grey.shade900,
        builder: (ctx) => Wrap(children: [
              if (_isOwner)
                ListTile(
                    leading: const Icon(Icons.security, color: Colors.blue),
                    title: Text(
                        widget.team.adminIds.contains(mId)
                            ? "Yöneticiliği Al"
                            : "Yönetici Yap",
                        style: const TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      setState(() => _isLoading = true);
                      if (widget.team.adminIds.contains(mId)) {
                        await _service.demoteFromAdmin(widget.team.id, mId);
                      } else {
                        await _service.promoteToAdmin(widget.team.id, mId);
                      }

                      if (mounted) {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Yetki güncellendi (Sayfayı yenileyin)")));
                      }
                    }),
              ListTile(
                  leading: const Icon(Icons.person_remove, color: Colors.red),
                  title: const Text("Ekipten Çıkar",
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _kickMemberConfirm(
                        mId, "${member['name']} ${member['surname']}");
                  })
            ]));
  }

  Future<void> _kickMemberConfirm(String memberId, String memberName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Üyeyi Çıkar", style: TextStyle(color: Colors.white)),
        content: Text(
            "Bu üyeyi ($memberName) ekipten çıkarmak istediğinize emin misiniz?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("İptal")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Çıkar")),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await _service.kickMember(widget.team.id, memberId);
      if (mounted) {
        setState(() {
          _membersData.removeWhere((m) => m['id'] == memberId);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Üye çıkarıldı")));
      }
    }
  }

  Future<void> _leaveOrDeleteTeam() async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(_isOwner ? l10n.delete : "Ekipten Ayrıl",
            style: const TextStyle(color: Colors.white)),
        content: Text(
          _isOwner
              ? l10n.clearAllDataWarning
              : "Bu ekipten ayrılmak istediğine emin misin?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_isOwner ? l10n.delete : "Ayrıl",
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        if (_isOwner) {
          await _service.deleteTeam(widget.team.id);
        } else {
          await _service.leaveTeam(widget.team.id);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Hata: $e")));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canEdit = _isOwner || _isAdmin;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: PhobesPremiumAppBar(
        title: l10n.team,
        trailing: canEdit
            ? PhobesIconButton(
                icon: Icons.edit,
                onTap: _showEditNameDialog,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.5),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            child: Text(
                              _displayTeamName.isNotEmpty
                                  ? _displayTeamName[0].toUpperCase()
                                  : "?",
                              style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _displayTeamName,
                          style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: widget.team.joinCode));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("${l10n.joinCode} kopyalandı!")));
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.team.joinCode,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.5)),
                                const SizedBox(width: 10),
                                const Icon(Icons.copy_rounded,
                                    color: Colors.white70, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  PhobesCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        Theme.of(context)
                            .colorScheme
                            .surfaceContainer
                            .withValues(alpha: 0.5),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${l10n.members} (${_membersData.length})",
                          style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        if (_membersData.isEmpty)
                          const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                  child: Text("...",
                                      style: TextStyle(color: Colors.grey)))),
                        ..._membersData.map((m) {
                          final mId = m['id'];
                          final isOwnerMember = mId == widget.team.ownerId;
                          final isAdminMember =
                              widget.team.adminIds.contains(mId);
                          final isMe = mId == _service.currentUserId;
                          final photoUrl = m['photoUrl'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.1)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: isOwnerMember
                                    ? Colors.orange
                                    : (isAdminMember
                                        ? Colors.purple
                                        : Colors.blue.shade700),
                                backgroundImage: photoUrl != null
                                    ? CachedNetworkImageProvider(photoUrl)
                                    : null,
                                child: photoUrl == null
                                    ? Text(m['name']?[0] ?? "?",
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 14))
                                    : null,
                              ),
                              title: Text(
                                  "${m['name']} ${m['surname']} ${isMe ? '(Ben)' : ''}",
                                  style: GoogleFonts.outfit(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  isOwnerMember
                                      ? "Kurucu"
                                      : (isAdminMember ? "Yönetici" : "Üye"),
                                  style: GoogleFonts.outfit(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                      fontSize: 11)),
                              trailing: (canEdit && mId != widget.team.ownerId)
                                  ? PhobesIconButton(
                                      icon: Icons.more_horiz_rounded,
                                      iconSize: 16,
                                      padding: 4,
                                      backgroundColor: Colors.transparent,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.3),
                                      onTap: () => _showMemberMenu(m))
                                  : null,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _leaveOrDeleteTeam,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                                color: Colors.red.withValues(alpha: 0.2))),
                      ),
                      icon: Icon(
                          _isOwner
                              ? Icons.delete_forever_rounded
                              : Icons.exit_to_app_rounded,
                          size: 20,
                          color: Colors.redAccent),
                      label: Text(_isOwner ? l10n.delete : "Ekipten Ayrıl",
                          style: GoogleFonts.outfit(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 100), // Spacing for navbar
                ],
              ),
            ),
    );
  }
}
