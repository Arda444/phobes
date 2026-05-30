import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/firebase_service.dart';
import '../../services/team_join_result.dart';
import '../../models/team_model.dart';
import '../../models/task_model.dart';
import '../../models/project_model.dart';
import '../../l10n/app_localizations.dart';
import '../../core/phobes_theme.dart';
import '../../core/page_transitions.dart';
import '../../core/module_ui_tokens.dart';
import '../../core/phobes_detail_panel.dart';
import 'package:go_router/go_router.dart';
import 'team_detail_screen.dart';
import 'team_add_edit_screen.dart';
import '../../core/module_info_catalog.dart';
import '../../widgets/phobes_module_header.dart';
import '../../widgets/phobes_widgets.dart';

class TeamScreen extends StatefulWidget {
  final void Function(Team)? onTeamSelected;
  const TeamScreen({super.key, this.onTeamSelected});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final FirebaseService _service = FirebaseService();
  late final Stream<List<Team>> _teamsStream;

  @override
  void initState() {
    super.initState();
    _teamsStream = _service.getUserTeamsStream().asBroadcastStream();
  }

  void _showCreateTeamDialog() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    int selectedColor = 0xFF6366F1;
    final colors = [
      0xFF6366F1,
      0xFF3B82F6,
      0xFF10B981,
      0xFFF59E0B,
      0xFFEF4444,
      0xFF8B5CF6,
      0xFFEC4899,
      0xFF06B6D4,
    ];

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => PhobesBottomSheet(
          title: l10n.createTeamTitle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhobesTextField(
                controller: controller,
                autofocus: true,
                hintText: l10n.teamNameHint,
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.teamColorLabel,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 45,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: colors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final c = colors[index];
                    final isSelected = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedColor = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Color(c).withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              PhobesButton(
                text: AppLocalizations.of(ctx)!.create,
                onPressed: () async {
                  if (controller.text.trim().isNotEmpty) {
                    await _service.createTeam(controller.text.trim(),
                        color: selectedColor);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
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
              hintText: l10n.joinCodeHint,
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
                  final result =
                      await _service.joinTeam(controller.text.trim());
                  navigator.pop();
                  switch (result) {
                    case JoinTeamResult.success:
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.teamJoined),
                          backgroundColor: PhobesTheme.successColor,
                        ),
                      );
                    case JoinTeamResult.invalidCode:
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.invalidCode),
                          backgroundColor: PhobesTheme.errorColor,
                        ),
                      );
                    case JoinTeamResult.permissionDenied:
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.joinTeamPermissionDenied),
                          backgroundColor: PhobesTheme.errorColor,
                        ),
                      );
                    case JoinTeamResult.error:
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.joinTeamFailed),
                          backgroundColor: PhobesTheme.errorColor,
                        ),
                      );
                  }
                } catch (e) {
                  if (mounted) {
                    final l10n = AppLocalizations.of(context)!;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.errorGeneric(e.toString())),
                        backgroundColor: PhobesTheme.errorColor,
                      ),
                    );
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final crossAxisCount = w >= 1500
              ? 4
              : w >= 1100
                  ? 3
                  : w >= 700
                      ? 2
                      : 1;
          final isWide = crossAxisCount > 1;

          return StreamBuilder<List<Team>>(
            stream: _teamsStream,
            builder: (context, snapshot) {
              final teams = snapshot.data ?? [];
              // İlk yükleme: henüz hiç veri yoksa spinner göster.
              // Veri varken yeniden yükleniyorsa mevcut listeyi koru (blink önleme).
              final isFirstLoad =
                  snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData;

              return Column(
                children: [
                  _buildHeader(cs, l10n, teams.length),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      child: isFirstLoad
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: PhobesTheme.kPrimaryColor,
                              ),
                            )
                          : snapshot.hasError
                              ? Center(
                                  child: Text(
                                    l10n.teamErrorWithDetail(
                                        snapshot.error.toString()),
                                    style:
                                        GoogleFonts.outfit(color: Colors.red),
                                  ),
                                )
                              : teams.isEmpty
                                  ? _buildEmptyState(l10n, isDark)
                                  : isWide
                                      ? GridView.builder(
                                          padding: const EdgeInsets.fromLTRB(
                                            24,
                                            24,
                                            24,
                                            100,
                                          ),
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            crossAxisSpacing: 24,
                                            mainAxisSpacing: 24,
                                            mainAxisExtent: _teamCardGridHeight(
                                              context,
                                            ),
                                          ),
                                          itemCount: teams.length,
                                          itemBuilder: (context, index) {
                                            return FadeInUp(
                                              delay: Duration(
                                                milliseconds: index * 80,
                                              ),
                                              duration: PhobesTheme.animNormal,
                                              child: _buildTeamCard(
                                                teams[index],
                                                isDark,
                                              ),
                                            );
                                          },
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.fromLTRB(
                                            20,
                                            16,
                                            20,
                                            100,
                                          ),
                                          itemCount: teams.length,
                                          itemBuilder: (context, index) {
                                            return FadeInUp(
                                              delay: Duration(
                                                milliseconds: index * 80,
                                              ),
                                              duration: PhobesTheme.animNormal,
                                              child: _buildTeamCard(
                                                teams[index],
                                                isDark,
                                              ),
                                            );
                                          },
                                        ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, AppLocalizations l10n, int teamCount) {
    return PhobesModuleHeaderBar(
      title: l10n.teamWorkspace,
      icon: Icons.groups_rounded,
      subtitle: l10n.teamWorkspaceSubtitle,
      info: ModuleInfoCatalog.forTeams(l10n),
      onAdd: _showCreateTeamDialog,
      addTooltip: l10n.create,
      extraActions: [
        Tooltip(
          message: l10n.joinTeam,
          child: PhobesModuleHeaderIconButton(
            icon: Icons.group_add_rounded,
            onTap: _showJoinTeamDialog,
          ),
        ),
      ],
      useExtendedHeight: true,
      toolbarHeight: 200,
      customContent: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              l10n.teamActiveTeams,
              teamCount.toString(),
              Icons.groups_rounded,
              Colors.blueAccent,
              cs,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              l10n.teamPerformance,
              l10n.teamPerformanceGood,
              Icons.trending_up_rounded,
              Colors.greenAccent,
              cs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PhobesEmptyState(
          icon: Icons.groups_3_rounded,
          title: l10n.teamEmptyTitle,
          description: l10n.teamEmptyDescription,
          buttonText: l10n.createTeam,
          buttonIcon: Icons.add_rounded,
          onButtonTap: _showCreateTeamDialog,
        ),
        // Secondary: join with a code
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: PhobesButton(
            text: l10n.joinTeam,
            isOutlined: true,
            onPressed: _showJoinTeamDialog,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  /// Grid hücre yüksekliği — metin ölçeği büyüyünce alt satır (üye/ayarlar) kesilmesin.
  static double _teamCardGridHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    return (300 * scale).clamp(300.0, 380.0);
  }

  Widget _buildTeamCard(Team team, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isOwner = team.ownerId == _service.currentUserId;
    final isAdmin = team.adminIds.contains(_service.currentUserId);
    final roleText = isOwner
        ? l10n.teamRoleOwner
        : (isAdmin ? l10n.teamRoleAdmin : l10n.teamRoleMember);
    final roleColor =
        isOwner ? Colors.amber : (isAdmin ? cs.primary : Colors.grey);
    final teamColor = Color(team.color);

    return Container(
      key: ValueKey(team.id),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(isDark ? 0.05 : 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (widget.onTeamSelected != null) {
              widget.onTeamSelected!(team);
            } else if (ModuleUiTokens.isWideForm(context)) {
              context.go('/teams/${team.id}', extra: team);
            } else {
              PhobesDetailPanel.open(
                context,
                TeamDetailScreen(team: team),
              );
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      teamColor,
                      teamColor.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: teamColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              team.name.isNotEmpty
                                  ? team.name[0].toUpperCase()
                                  : 'T',
                              style: GoogleFonts.outfit(
                                color: teamColor,
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.1),
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
                        Icon(
                          Icons.more_horiz_rounded,
                          color: cs.onSurface.withOpacity(0.3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _TeamCardStats(
                      teamId: team.id,
                      teamColor: teamColor,
                      service: _service,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.people_alt_rounded,
                                size: 16,
                                color: cs.onSurface.withOpacity(0.4),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${team.memberIds.length} ${l10n.teamMemberCountLabel}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: cs.onSurface.withOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isOwner || isAdmin) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => PhobesPageRoute.pushResponsive(
                              context,
                              TeamAddEditScreen(team: team),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.settings_rounded,
                                  size: 14,
                                  color: teamColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.sectionSettings,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: teamColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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
}

// ─── Takım kartı istatistikleri — stream'ler initState'te bir kez oluşur ─────
class _TeamCardStats extends StatefulWidget {
  final String teamId;
  final Color teamColor;
  final FirebaseService service;

  const _TeamCardStats({
    required this.teamId,
    required this.teamColor,
    required this.service,
  });

  @override
  State<_TeamCardStats> createState() => _TeamCardStatsState();
}

class _TeamCardStatsState extends State<_TeamCardStats> {
  late final Stream<List<Task>> _tasksStream;
  late final Stream<List<Project>> _projectsStream;

  @override
  void initState() {
    super.initState();
    _tasksStream =
        widget.service.getTeamTasksStream(widget.teamId).asBroadcastStream();
    _projectsStream =
        widget.service.getProjectsStream(widget.teamId).asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Task>>(
      stream: _tasksStream,
      builder: (context, taskSnap) {
        final tasks = taskSnap.data ?? [];
        final total = tasks.length;
        final completed =
            tasks.where((t) => t.isCompleted || t.status == 'done').length;
        final progress = total > 0 ? completed / total : 0.0;
        final percent = (progress * 100).toInt();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.teamTaskProgress,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '%$percent',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: widget.teamColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: widget.teamColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(widget.teamColor),
              ),
            ),
            StreamBuilder<List<Project>>(
              stream: _projectsStream,
              builder: (context, projSnap) {
                final projectCount = projSnap.data?.length ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _statBox(l10n.teamProjectsLabel, projectCount.toString(),
                            Icons.dashboard_rounded, cs),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statBox(l10n.teamTasksLabel, total.toString(),
                            Icons.check_circle_rounded, cs),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _statBox(String label, String value, IconData icon, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.teamColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.teamColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: widget.teamColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
