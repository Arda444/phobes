import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/project_model.dart';
import '../../models/team_model.dart';
import '../../services/firebase_service.dart';
import '../projects/project_detail_screen.dart';
import '../../core/page_transitions.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_widgets.dart';

class TeamKanbanTab extends StatefulWidget {
  final Team team;
  final Function(Project)? onProjectSelected;
  const TeamKanbanTab({super.key, required this.team, this.onProjectSelected});

  @override
  State<TeamKanbanTab> createState() => _TeamKanbanTabState();
}

class _TeamKanbanTabState extends State<TeamKanbanTab> {
  final FirebaseService _service = FirebaseService();
  bool _showMyTasksOnly = false;
  String _searchQuery = '';
  late final Stream<List<Project>> _projectsStream;

  @override
  void initState() {
    super.initState();
    _projectsStream =
        _service.getProjectsStream(widget.team.id).asBroadcastStream();
  }

  bool get _canManageProjects {
    final uid = _service.currentUserId;
    if (uid == null) return false;
    return widget.team.ownerId == uid ||
        widget.team.adminIds.contains(uid);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;
    final cs = Theme.of(context).colorScheme;

    return Column(
        children: [
          _buildFilterHeader(l10n),
          Expanded(
            child: StreamBuilder<List<Project>>(
              stream: _projectsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: PhobesLoadingIndicator(color: cs.primary),
                  );
                }

                final projects = snapshot.data!;

                final filteredProjects = projects.where((p) {
                  final matchesSearch = p.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                  final matchesFilter =
                      !_showMyTasksOnly || p.managerId == _service.currentUserId;
                  return matchesSearch && matchesFilter;
                }).toList();

                final todoProjects = filteredProjects
                    .where((p) => p.status == 'todo' || p.status == 'active')
                    .toList();
                final progressProjects = filteredProjects
                    .where((p) => p.status == 'in_progress')
                    .toList();
                final reviewProjects =
                    filteredProjects.where((p) => p.status == 'review').toList();
                final doneProjects = filteredProjects
                    .where((p) => p.status == 'done' || p.status == 'completed')
                    .toList();

                if (isDesktop) {
                  return Row(
                    children: [
                      Expanded(
                          child: _buildDragTargetSection(
                              title: l10n.statusTodo,
                              color: Colors.blueAccent,
                              projects: todoProjects,
                              statusId: 'todo',
                              icon: Icons.assignment_outlined,),),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildDragTargetSection(
                              title: l10n.statusInProgress,
                              color: Colors.orangeAccent,
                              projects: progressProjects,
                              statusId: 'in_progress',
                              icon: Icons.pending_actions_outlined,),),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildDragTargetSection(
                              title: l10n.statusReview,
                              color: Colors.purpleAccent,
                              projects: reviewProjects,
                              statusId: 'review',
                              icon: Icons.rate_review_rounded,),),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildDragTargetSection(
                              title: l10n.statusDone,
                              color: Colors.greenAccent,
                              projects: doneProjects,
                              statusId: 'done',
                              icon: Icons.check_circle_outline,),),
                    ],
                  );
                } else {
                  return ListView(
                    primary: false,
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: isDesktop ? 0 : 90),
                    children: [
                      _buildDragTargetSection(
                          title: l10n.statusTodo,
                          color: Colors.blueAccent,
                          projects: todoProjects,
                          statusId: 'todo',
                          icon: Icons.assignment_outlined,),
                      _buildDragTargetSection(
                          title: l10n.statusInProgress,
                          color: Colors.orangeAccent,
                          projects: progressProjects,
                          statusId: 'in_progress',
                          icon: Icons.pending_actions_outlined,),
                      _buildDragTargetSection(
                          title: l10n.statusReview,
                          color: Colors.purpleAccent,
                          projects: reviewProjects,
                          statusId: 'review',
                          icon: Icons.rate_review_rounded,),
                      _buildDragTargetSection(
                          title: l10n.statusDone,
                          color: Colors.greenAccent,
                          projects: doneProjects,
                          statusId: 'done',
                          icon: Icons.check_circle_outline,),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      );
  }

  Widget _buildFilterHeader(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNarrow = MediaQuery.of(context).size.width < 500;

    return Container(
      padding: EdgeInsets.fromLTRB(16, isNarrow ? 8 : 4, 16, 4),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: cs.outline.withOpacity(0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (!isNarrow) ...[
                Expanded(flex: 3, child: _buildSearchField(cs, isDark)),
                const SizedBox(width: 16),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _showMyTasksOnly,
                    activeTrackColor: Colors.purpleAccent,
                    inactiveThumbColor: Colors.grey,
                    activeThumbColor: Colors.white,
                    onChanged: (val) =>
                        setState(() => _showMyTasksOnly = val),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _showMyTasksOnly
                      ? l10n.teamPersonalTasks
                      : l10n.teamAllTeamTasks,
                  style: GoogleFonts.outfit(
                    color: cs.onSurface.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
              ] else ...[
                Expanded(
                  child: Text(
                    _showMyTasksOnly
                        ? l10n.teamPersonalTasks
                        : l10n.teamAllTeamTasks,
                    style: GoogleFonts.outfit(
                      color: cs.onSurface.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _showMyTasksOnly,
                    activeTrackColor: Colors.purpleAccent,
                    inactiveThumbColor: Colors.grey,
                    activeThumbColor: Colors.white,
                    onChanged: (val) =>
                        setState(() => _showMyTasksOnly = val),
                  ),
                ),
              ],
              if (_canManageProjects) ...[
                const SizedBox(width: 12),
                PhobesIconButton(
                  icon: Icons.add_rounded,
                  backgroundColor: cs.primary,
                  color: Colors.white,
                  onTap: () => _showCreateProjectDialog(context),
                ),
              ],
            ],
          ),
          if (isNarrow) ...[
            const SizedBox(height: 8),
            _buildSearchField(cs, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField(ColorScheme cs, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 36,
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 13),
        decoration: InputDecoration(
          hintText: l10n.teamSearchProjectsHint,
          hintStyle: GoogleFonts.outfit(
              color: cs.onSurface.withOpacity(0.4),),
          prefixIcon: Icon(Icons.search_rounded,
              color: cs.onSurface.withOpacity(0.4), size: 18,),
          filled: true,
          fillColor: isDark
              ? cs.surfaceVariant.withOpacity(0.3)
              : cs.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDragTargetSection({
    required String title,
    required Color color,
    required List<Project> projects,
    required String statusId,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return DragTarget<Project>(
      onWillAcceptWithDetails: (details) => _canManageProjects,
      onAcceptWithDetails: (details) {
        if (!_canManageProjects) return;
        final project = details.data;
        if (project.status != statusId) {
          _service
              .updateProject(widget.team.id, project.id, {'status': statusId});
          _service.logTeamActivity(widget.team.id, 'project_status_change',
              '${project.name} -> $title',);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          height: MediaQuery.of(context).size.width > 800 ? null : 300,
          decoration: BoxDecoration(
            color: isHovered
                ? color.withOpacity(0.05)
                : cs.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHovered ? color : cs.outline.withOpacity(0.1),
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 14,),),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2,),
                      decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),),
                      child: Text('${projects.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11,),),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: projects.isEmpty
                    ? Center(
                        child: Text(
                          l10n.teamKanbanEmpty,
                          style: GoogleFonts.outfit(
                              color: cs.onSurface.withOpacity(0.2),
                              fontSize: 12,),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(8, 4, 8, MediaQuery.of(context).size.width >= 900 ? 20 : 0),
                        itemCount: projects.length,
                        itemBuilder: (ctx, i) =>
                            _buildDraggableCard(context, projects[i], color),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableCard(
      BuildContext context, Project project, Color accentColor,) {
    final bool useLongPress = (Theme.of(context).platform == TargetPlatform.android ||
            Theme.of(context).platform == TargetPlatform.iOS);

    final Widget card = _ProjectBoardCard(
      project: project,
      accentColor: accentColor,
      team: widget.team,
      onProjectSelected: widget.onProjectSelected,
    );

    final Widget feedback = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 280,
        child: card,
      ),
    );

    if (useLongPress) {
      return LongPressDraggable<Project>(
        data: project,
        delay: const Duration(milliseconds: 150),
        feedback: feedback,
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: card,
        ),
        child: card,
      );
    } else {
      return Draggable<Project>(
        data: project,
        feedback: feedback,
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: card,
        ),
        child: card,
      );
    }
  }

  void _showCreateProjectDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final cs = Theme.of(context).colorScheme;
    int selectedColor = 0xFF6366F1;
    DateTime? deadline;

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
          title: l10n.newProjectTitle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhobesTextFormField(
                controller: nameController,
                hintText: l10n.projectNameHint,
                prefixIcon: Icons.folder_rounded,
              ),
              const SizedBox(height: 16),
              PhobesTextFormField(
                controller: descController,
                hintText: l10n.projectDescriptionHint,
                prefixIcon: Icons.description_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.colorSelectionLabel,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface.withOpacity(0.4),
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
                            ? const Icon(Icons.check,
                                size: 18, color: Colors.white,)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.deadlineLabel,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface.withOpacity(0.4),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setSheetState(() => deadline = picked);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: cs.outline.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 18, color: cs.primary,),
                      const SizedBox(width: 12),
                      Text(
                        deadline != null
                            ? DateFormat('dd MMM yyyy').format(deadline!)
                            : l10n.noDateSelected,
                        style: GoogleFonts.outfit(
                          color: deadline != null
                              ? cs.onSurface
                              : cs.onSurface.withOpacity(0.4),
                          fontWeight: deadline != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: PhobesButton(
                  text: l10n.createProjectButton,
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    final project = Project(
                      id: '',
                      teamId: widget.team.id,
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      managerId: _service.currentUserId ?? '',
                      color: selectedColor,
                      deadline: deadline,
                    );

                    await _service.createProject(widget.team.id, project);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectBoardCard extends StatelessWidget {
  final Project project;
  final Team team;
  final Color accentColor;
  final Function(Project)? onProjectSelected;

  const _ProjectBoardCard({
    required this.project,
    required this.accentColor,
    required this.team,
    this.onProjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return PhobesCard(
      onTap: () {
        if (onProjectSelected != null) {
          onProjectSelected!(project);
        } else {
          Navigator.push(
              context,
              PhobesPageRoute.fadeScale(
                  ProjectDetailScreen(project: project, team: team),),);
        }
      },
      margin: const EdgeInsets.only(bottom: 5),
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        colors: [
          accentColor.withOpacity(0.1),
          cs.surfaceVariant.withOpacity(0.5),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(color: Color(project.color)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,),),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (project.deadline != null)
                      Expanded(
                        child: Text(
                            DateFormat('d MMM').format(project.deadline!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: cs.onSurface.withOpacity(0.3),),),
                      )
                    else
                      Expanded(
                        child: Text(l10n.teamNoDeadline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: cs.onSurface.withOpacity(0.3),),),
                      ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2,),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.teamProjectBadge,
                        style: GoogleFonts.outfit(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
