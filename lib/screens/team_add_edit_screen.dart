import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart'; // EKLENDİ
import '../models/team_model.dart';
import '../services/firebase_service.dart';
import '../l10n/app_localizations.dart';
import 'team_detail_screen.dart';

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

  // 1. İSİM DÜZENLEME DİYALOĞU
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

  // 2. ÜYE İŞLEMLERİ MENÜSÜ
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.team,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _showEditNameDialog,
              tooltip: "İsmi Düzenle",
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. PROFİL KARTI (İSİM & KOD)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade900.withValues(alpha: 0.8),
                          Colors.purple.shade900.withValues(alpha: 0.8)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white24,
                          child: Text(
                            _displayTeamName.isNotEmpty
                                ? _displayTeamName[0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _displayTeamName,
                          style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // KOD KOPYALAMA BUTONU
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
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.team.joinCode,
                                    style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        letterSpacing: 1)),
                                const SizedBox(width: 8),
                                const Icon(Icons.copy,
                                    color: Colors.white70, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 2. MODERN AKSİYON BUTONLARI
                  _buildModernButton(
                    icon: Icons.list_alt_rounded,
                    title: l10n.tabTasks, // "Görevler"
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TeamDetailScreen(
                                team: widget.team, initialIndex: 0))),
                  ),
                  const SizedBox(height: 16),
                  _buildModernButton(
                    icon: Icons.bar_chart_rounded,
                    title: l10n.tabDashboard, // "Pano"
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TeamDetailScreen(
                                team: widget.team, initialIndex: 1))),
                  ),
                  const SizedBox(height: 16),
                  _buildModernButton(
                    icon: Icons.history_rounded,
                    title: l10n.tabActivity, // "Aktivite"
                    color: Colors.green,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TeamDetailScreen(
                                team: widget.team, initialIndex: 2))),
                  ),

                  const SizedBox(height: 32),

                  // 3. ÜYE LİSTESİ
                  Text(
                    "${l10n.members} (${_membersData.length})",
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 12),

                  if (_membersData.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: Text("...",
                                style: TextStyle(color: Colors.grey)))),

                  ..._membersData.map((m) {
                    final mId = m['id'];
                    final isOwnerMember = mId == widget.team.ownerId;
                    final isAdminMember = widget.team.adminIds.contains(mId);
                    final isMe = mId == _service.currentUserId;
                    final photoUrl = m['photoUrl']; // Firestore'dan gelen foto

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        // DÜZELTME: AVATAR GÖSTERİMİ
                        leading: CircleAvatar(
                          backgroundColor: isOwnerMember
                              ? Colors.orange
                              : (isAdminMember
                                  ? Colors.purple
                                  : Colors.blue.shade700),
                          // Eğer foto URL varsa CachedNetworkImage, yoksa Baş Harf
                          backgroundImage: photoUrl != null
                              ? CachedNetworkImageProvider(photoUrl)
                              : null,
                          child: photoUrl == null
                              ? Text(m['name']?[0] ?? "?",
                                  style: const TextStyle(color: Colors.white))
                              : null,
                        ),
                        title: Text(
                            "${m['name']} ${m['surname']} ${isMe ? '(Ben)' : ''}",
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                        subtitle: Text(
                            isOwnerMember
                                ? "Kurucu"
                                : (isAdminMember ? "Yönetici" : "Üye"),
                            style: GoogleFonts.poppins(
                                color: Colors.white54, fontSize: 12)),
                        trailing: (canEdit && mId != widget.team.ownerId)
                            ? IconButton(
                                icon: const Icon(Icons.more_vert,
                                    color: Colors.white54),
                                onPressed: () => _showMemberMenu(m))
                            : null,
                      ),
                    );
                  }),

                  const SizedBox(height: 40),

                  // 4. SİL / AYRIL BUTONU
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _leaveOrDeleteTeam,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                                color: Colors.red.withValues(alpha: 0.5))),
                      ),
                      icon: Icon(
                          _isOwner ? Icons.delete_forever : Icons.exit_to_app,
                          color: Colors.red),
                      label: Text(_isOwner ? l10n.delete : "Ekipten Ayrıl",
                          style: GoogleFonts.poppins(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildModernButton(
      {required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(title,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade700, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
