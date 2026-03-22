import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/firebase_service.dart';
import '../../models/team_model.dart';
import '../../l10n/app_localizations.dart';
import '../../core/phobes_theme.dart';
import '../../core/page_transitions.dart';
import 'team_detail_screen.dart';
import 'team_add_edit_screen.dart';
import '../../widgets/phobes_widgets.dart';

class TeamScreen extends StatefulWidget {
  final void Function(Team)? onTeamSelected;
  const TeamScreen({super.key, this.onTeamSelected});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final FirebaseService _service = FirebaseService();

  void _showCreateTeamDialog() {
    final controller = TextEditingController();

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: "Yeni Takım Oluştur",
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhobesTextField(
              controller: controller,
              autofocus: true,
              hintText: "Takım adı girin",
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 24),
            PhobesButton(
              text: "Oluştur",
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await _service.createTeam(controller.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinTeamDialog() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: l10n.joinTeam,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhobesTextField(
              controller: controller,
              autofocus: true,
              hintText: "Takım kodunu girin",
              prefixIcon: Icons.key_rounded,
              suffixIcon: Icons.paste_rounded,
              onSuffixTap: () async {
                final data = await Clipboard.getData('text/plain');
                if (data?.text != null) controller.text = data!.text!;
              },
            ),
            const SizedBox(height: 24),
            PhobesButton(
              text: l10n.join,
              onPressed: () async {
                try {
                  final navigator = Navigator.of(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  final success =
                      await _service.joinTeam(controller.text.trim());
                  navigator.pop();
                  if (success) {
                    messenger.showSnackBar(SnackBar(
                        content: Text(l10n.teamJoined),
                        backgroundColor: PhobesTheme.successColor));
                  } else {
                    messenger.showSnackBar(SnackBar(
                        content: Text(l10n.invalidCode),
                        backgroundColor: PhobesTheme.errorColor));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Hata: $e"),
                        backgroundColor: PhobesTheme.errorColor));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: StreamBuilder<List<Team>>(
        stream: _service.getUserTeamsStream(),
        builder: (context, snapshot) {
          final teams = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return SafeArea(
            child: Column(
              children: [
                _buildHeader(cs, l10n, teams.length),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: PhobesTheme.kPrimaryColor))
                      : snapshot.hasError
                          ? Center(
                              child: Text("Hata: ${snapshot.error}",
                                  style: GoogleFonts.outfit(color: Colors.red)))
                          : teams.isEmpty
                              ? _buildEmptyState(l10n, isDark)
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 16, 20, 100),
                                  itemCount: teams.length,
                                  itemBuilder: (context, index) {
                                    return FadeInUp(
                                      delay: Duration(milliseconds: index * 80),
                                      duration: PhobesTheme.animNormal,
                                      child:
                                          _buildTeamCard(teams[index], isDark),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, AppLocalizations l10n, int teamCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.15),
            cs.surface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        border: Border(
            bottom: BorderSide(color: cs.primary.withValues(alpha: 0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Çalışma Alanı",
                      style: GoogleFonts.outfit(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 32)),
                  const SizedBox(height: 4),
                  Text(
                    "Ekiplerinizi ve projelerinizi yönetin",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  PhobesIconButton(
                    icon: Icons.group_add_rounded,
                    color: cs.primary,
                    backgroundColor: cs.primary.withValues(alpha: 0.1),
                    onTap: _showJoinTeamDialog,
                  ),
                  const SizedBox(width: 12),
                  PhobesIconButton(
                    icon: Icons.add_rounded,
                    color: Colors.white,
                    backgroundColor: PhobesTheme.kPrimaryColor,
                    enableGlow: true,
                    onTap: _showCreateTeamDialog,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Aktif Ekipler",
                  teamCount.toString(),
                  Icons.groups_rounded,
                  Colors.blueAccent,
                  cs,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Performans",
                  "İyi",
                  Icons.trending_up_rounded,
                  Colors.greenAccent,
                  cs,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5))),
              Text(value,
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: FadeInUp(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhobesGlassCard(
                padding: const EdgeInsets.all(28),
                borderRadius: 40,
                child: Icon(Icons.groups_3_rounded,
                    color: cs.primary.withValues(alpha: 0.2), size: 56),
              ),
              const SizedBox(height: 24),
              Text(
                "Henüz Bir Takımın Yok",
                style: GoogleFonts.outfit(
                  color: cs.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Takım çalışması ile verimliliğini artır. Bir takım oluştur veya davet kodunla hemen katıl.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              PhobesButton(
                text: l10n.createTeam,
                width: double.infinity,
                onPressed: _showCreateTeamDialog,
              ),
              const SizedBox(height: 12),
              PhobesButton(
                text: l10n.joinTeam,
                width: double.infinity,
                isOutlined: true,
                onPressed: _showJoinTeamDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(Team team, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    final isOwner = team.ownerId == _service.currentUserId;
    final isAdmin = team.adminIds.contains(_service.currentUserId);
    final roleText = isOwner ? 'SAHİP' : (isAdmin ? 'YÖNETİCİ' : 'ÜYE');
    final roleColor =
        isOwner ? Colors.amber : (isAdmin ? cs.primary : Colors.grey);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (widget.onTeamSelected != null) {
              widget.onTeamSelected!(team);
            } else {
              Navigator.push(
                context,
                PhobesPageRoute.fadeScale(TeamDetailScreen(team: team)),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          team.name.isNotEmpty
                              ? team.name[0].toUpperCase()
                              : "T",
                          style: GoogleFonts.outfit(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: GoogleFonts.outfit(
                              color: cs.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              roleText,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: roleColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.more_horiz_rounded,
                        color: cs.onSurface.withValues(alpha: 0.3)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_alt_rounded,
                            size: 16,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 6),
                        Text(
                          "${team.memberIds.length} Üye",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (isOwner || isAdmin)
                      GestureDetector(
                        onTap: () => PhobesPageRoute.pushResponsive(
                          context,
                          TeamAddEditScreen(team: team),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.settings_rounded,
                                size: 14, color: cs.primary),
                            const SizedBox(width: 4),
                            Text(
                              "Ayarlar",
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
