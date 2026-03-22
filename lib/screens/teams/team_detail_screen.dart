import 'package:flutter/material.dart';
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

class TeamDetailScreen extends StatefulWidget {
  final Team team;
  final int initialIndex;
  final int? externalIndex;

  const TeamDetailScreen(
      {super.key,
      required this.team,
      this.initialIndex = 0,
      this.externalIndex});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  late int _currentIndex;
  Project? _selectedProject;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.externalIndex ?? widget.initialIndex;
  }

  @override
  void didUpdateWidget(TeamDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalIndex != null && widget.externalIndex != _currentIndex) {
      setState(() {
        _currentIndex = widget.externalIndex!;
        _selectedProject = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final List<Widget> tabs = [
      TeamKanbanTab(team: widget.team),
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
              onProjectSelected: (project) =>
                  setState(() => _selectedProject = project),
            ),
      TeamDashboardTab(team: widget.team),
      TeamResourcesTab(team: widget.team),
      TeamActivityTab(team: widget.team),
      TeamNotesTab(team: widget.team),
    ];

    final List<String> titles = [
      'Panolar',
      'Projeler',
      'İstatistik',
      'Kaynaklar',
      'Aktivite',
      'Notlar',
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 900;

      return Scaffold(
        backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
        appBar: null,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  if (isWide)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Text(
                        widget.team.name,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    )
                  else
                    _buildTeamHeader(isDark, cs, context),
                  _buildTopTabBar(
                      cs, titles, isDark, constraints.maxWidth < 600),
                ],
              ),
            ),
          ],
          body: IndexedStack(
            index: _currentIndex,
            children: tabs,
          ),
        ),
      );
    });
  }

  Widget _buildTeamHeader(bool isDark, ColorScheme cs, BuildContext context) {
    final mq = MediaQuery.of(context);
    final isCompact = mq.size.width < 600;

    return Container(
      margin: EdgeInsets.fromLTRB(
        isCompact ? 12 : 16,
        isCompact ? 16 : 24, // Increased top margin
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
            cs.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
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
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: Colors.white,
              onTap: () => Navigator.pop(context),
              size: isCompact ? 32 : 40,
            ),
            SizedBox(width: isCompact ? 8 : 12),
          ],
          Container(
            padding: EdgeInsets.all(isCompact ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
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
                  "${widget.team.memberIds.length} Üye",
                  style: GoogleFonts.outfit(
                    fontSize: isCompact ? 11 : 13,
                    color: Colors.white.withValues(alpha: 0.8),
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

  Widget _buildTopTabBar(ColorScheme cs, List<String> titles, bool isDark, bool isCompact) {
    final icons = [
      Icons.view_kanban_rounded,
      Icons.folder_rounded,
      Icons.dashboard_rounded,
      Icons.source_rounded,
      Icons.history_rounded,
      Icons.note_alt_rounded,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
              : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withValues(alpha: 0.05)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(titles.length, (index) {
              final isSelected = _currentIndex == index;
              final showText = isSelected || !isCompact;
              
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icons[index],
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : cs.onSurface.withValues(alpha: 0.5),
                      ),
                      if (showText) ...[
                        const SizedBox(width: 6),
                        Text(
                          titles[index],
                          style: GoogleFonts.outfit(
                            color: isSelected
                                ? Colors.white
                                : cs.onSurface.withValues(alpha: 0.5),
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
