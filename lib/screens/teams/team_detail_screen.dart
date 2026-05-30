import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/team_model.dart';
import '../../core/phobes_theme.dart';
import 'team_kanban_tab.dart';
import 'team_dashboard_tab.dart';
import 'team_resources_tab.dart';
import 'team_activity_tab.dart';
import 'team_notes_tab.dart';
import '../projects/project_list_screen.dart';
import '../projects/project_detail_screen.dart';
import '../../models/project_model.dart';
import '../../widgets/phobes_widgets.dart';
import '../../widgets/phobes_module_header.dart';
import '../../widgets/phobes_module_tab_bar.dart';
import 'tabs/team_book_club_tab.dart';
import '../../services/team_service.dart';
import '../../l10n/app_localizations.dart';

class TeamDetailScreen extends StatefulWidget {
  final Team team;
  final int initialIndex;
  final int? externalIndex;

  const TeamDetailScreen(
      {super.key,
      required this.team,
      this.initialIndex = 0,
      this.externalIndex,});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen>
    with TickerProviderStateMixin {
  late int _currentIndex;
  late TabController _tabController;
  Project? _selectedProject;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.externalIndex ?? widget.initialIndex;
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: _currentIndex,
    );
    TeamService().backfillProjectTaskTeamIds(widget.team.id);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_currentIndex != _tabController.index) {
          setState(() {
            _currentIndex = _tabController.index;

            _selectedProject = null;
          });
        }
      }
    });
  }

  void _handleProjectSelection(Project project) {
    setState(() {
      _selectedProject = project;
      _currentIndex = 1;
    });
    _tabController.animateTo(1);
  }

  void _popTeamDetail(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/teams/') && path != '/teams') {
      context.go('/teams');
      return;
    }
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TeamDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalIndex != null && widget.externalIndex != oldWidget.externalIndex) {
      setState(() {
        _currentIndex = widget.externalIndex!;
        _selectedProject = null;
      });
      _tabController.animateTo(_currentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<Widget> tabs = [
      TeamKanbanTab(
        team: widget.team,
        onProjectSelected: _handleProjectSelection,
      ),
      _selectedProject != null
          ? ProjectDetailScreen(
              project: _selectedProject!,
              team: widget.team,
              isEmbedded: true,
              onBack: () => setState(() => _selectedProject = null),
            )
          : ProjectListScreen(
              team: widget.team,
              isEmbedded: true,
              onProjectSelected: _handleProjectSelection,
            ),
      TeamDashboardTab(
        team: widget.team,
        onProjectSelected: _handleProjectSelection,
      ),
      TeamResourcesTab(team: widget.team),
      TeamActivityTab(team: widget.team),
      TeamNotesTab(team: widget.team),
      TeamBookClubTab(team: widget.team),
    ];

    final List<String> titles = [
      l10n.teamTabBoards,
      l10n.teamTabProjects,
      l10n.teamTabStats,
      l10n.teamTabResources,
      l10n.teamTabActivity,
      l10n.teamTabNotes,
      l10n.teamTabBookClub,
    ];

    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final isAmoled = PhobesTheme.amoledMode.value;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
        body: constraints.maxWidth >= 900
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  _buildTeamHeader(isDark, cs, context),
                  _teamTabBar(titles),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: tabs,
                    ),
                  ),
                ],
              )
            : NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: MediaQuery.of(context).padding.top),
                        _buildTeamHeader(isDark, cs, context),
                        _teamTabBar(titles),
                      ],
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: tabs,
                ),
              ),
      );
    },);

  }

  Widget _buildTeamHeader(bool isDark, ColorScheme cs, BuildContext context) {
    final mq = MediaQuery.of(context);
    final isCompact = mq.size.width < 600;

    return Container(
      margin: EdgeInsets.fromLTRB(
        isCompact ? 12 : 16,
        isCompact ? 16 : 24,
        isCompact ? 12 : 16,
        isCompact ? 2 : 8,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: isCompact ? 10 : 20,
      ),
      decoration: BoxDecoration(
        color: cs.primary,
        gradient: LinearGradient(
          colors: [
            cs.primary,
            cs.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context)) ...[
            PhobesIconButton(
              icon: Icons.arrow_back_rounded,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: Colors.white,
              onTap: () => _popTeamDetail(context),
              size: isCompact ? 32 : 40,
            ),
            SizedBox(width: isCompact ? 8 : 12),
          ],
          Container(
            padding: EdgeInsets.all(isCompact ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: isCompact ? 20 : 28,
            ),
          ),
          SizedBox(width: isCompact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.team.name,
                  style: GoogleFonts.outfit(
                    fontSize: isCompact ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (!isCompact) const SizedBox(height: 4),
                Text(
                  '${widget.team.memberIds.length} Üye',
                  style: GoogleFonts.outfit(
                    fontSize: isCompact ? 11 : 13,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamTabBar(List<String> titles) {
    const icons = [
      Icons.view_kanban_rounded,
      Icons.folder_rounded,
      Icons.dashboard_rounded,
      Icons.source_rounded,
      Icons.history_rounded,
      Icons.note_alt_rounded,
      Icons.menu_book_rounded,
    ];

    return PhobesModuleTabBar(
      controller: _tabController,
      tabs: List.generate(
        titles.length,
        (i) => PhobesModuleTab(titles[i], icons[i]),
      ),
    );
  }
}
