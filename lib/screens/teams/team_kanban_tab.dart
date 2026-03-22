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
  const TeamKanbanTab({super.key, required this.team});

  @override
  State<TeamKanbanTab> createState() => _TeamKanbanTabState();
}

class _TeamKanbanTabState extends State<TeamKanbanTab> {
  final FirebaseService _service = FirebaseService();
  bool _showMyTasksOnly = false;

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
              stream: _service.getProjectsStream(widget.team.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: PhobesLoadingIndicator(color: cs.primary),
                  );
                }

                var projects = snapshot.data!;

                final todoProjects = projects
                    .where((p) => p.status == 'todo' || p.status == 'active')
                    .toList();
                final progressProjects =
                    projects.where((p) => p.status == 'in_progress').toList();
                final reviewProjects =
                    projects.where((p) => p.status == 'review').toList();
                final doneProjects = projects
                    .where((p) => p.status == 'done' || p.status == 'completed')
                    .toList();

                if (isDesktop) {
                  return Row(
                    children: [
                      Expanded(
                          child: _buildDragTargetSection(
                              title: "Yapılacak",
                              color: Colors.blueAccent,
                              projects: todoProjects,
                              statusId: 'todo',
                              icon: Icons.assignment_outlined)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildDragTargetSection(
                              title: "İşlemde",
                              color: Colors.orangeAccent,
                              projects: progressProjects,
                              statusId: 'in_progress',
                              icon: Icons.pending_actions_outlined)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildDragTargetSection(
                              title: "İnceleme",
                              color: Colors.purpleAccent,
                              projects: reviewProjects,
                              statusId: 'review',
                              icon: Icons.rate_review_rounded)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildDragTargetSection(
                              title: "Bitti",
                              color: Colors.greenAccent,
                              projects: doneProjects,
                              statusId: 'done',
                              icon: Icons.check_circle_outline)),
                    ],
                  );
                } else {
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      _buildDragTargetSection(
                          title: "Yapılacak",
                          color: Colors.blueAccent,
                          projects: todoProjects,
                          statusId: 'todo',
                          icon: Icons.assignment_outlined),
                      _buildDragTargetSection(
                          title: "İşlemde",
                          color: Colors.orangeAccent,
                          projects: progressProjects,
                          statusId: 'in_progress',
                          icon: Icons.pending_actions_outlined),
                      _buildDragTargetSection(
                          title: "İnceleme",
                          color: Colors.purpleAccent,
                          projects: reviewProjects,
                          statusId: 'review',
                          icon: Icons.rate_review_rounded),
                      _buildDragTargetSection(
                          title: "Bitti",
                          color: Colors.greenAccent,
                          projects: doneProjects,
                          statusId: 'done',
                          icon: Icons.check_circle_outline),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: cs.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _showMyTasksOnly ? l10n.filterMyTasks : l10n.filterAllTeamTasks,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                      color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _showMyTasksOnly,
                  activeTrackColor: Colors.purpleAccent,
                  inactiveThumbColor: Colors.grey,
                  activeThumbColor: Colors.white,
                  onChanged: (val) => setState(() => _showMyTasksOnly = val),
                ),
              ),
            ],
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
    return DragTarget<Project>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final project = details.data;
        if (project.status != statusId) {
          _service
              .updateProject(widget.team.id, project.id, {'status': statusId});
          _service.logTeamActivity(widget.team.id, 'project_status_change',
              "${project.name} -> $title");
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          height: MediaQuery.of(context).size.width > 800 ? null : 300,
          decoration: BoxDecoration(
            color: isHovered
                ? color.withValues(alpha: 0.05)
                : cs.surfaceContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHovered ? color : cs.outline.withValues(alpha: 0.1),
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
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
                              fontSize: 14)),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text("${projects.length}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    )
                  ],
                ),
              ),
              Expanded(
                child: projects.isEmpty
                    ? Center(
                        child: Text(
                          "Boş",
                          style: GoogleFonts.outfit(
                              color: cs.onSurface.withValues(alpha: 0.2),
                              fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 120),
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
      BuildContext context, Project project, Color accentColor) {
    return Draggable<Project>(
      data: project,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 280,
          child: _ProjectBoardCard(
              project: project, accentColor: accentColor, team: widget.team),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _ProjectBoardCard(
            project: project, accentColor: accentColor, team: widget.team),
      ),
      child: _ProjectBoardCard(
          project: project, accentColor: accentColor, team: widget.team),
    );
  }
}

class _ProjectBoardCard extends StatelessWidget {
  final Project project;
  final Team team;
  final Color accentColor;

  const _ProjectBoardCard(
      {required this.project, required this.accentColor, required this.team});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PhobesCard(
      onTap: () {
        PhobesPageRoute.pushResponsive(
            context, ProjectDetailScreen(project: project, team: team));
      },
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        colors: [
          accentColor.withValues(alpha: 0.1),
          cs.surfaceContainer.withValues(alpha: 0.5),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border:
              Border(left: BorderSide(color: Color(project.color), width: 4)),
        ),
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
                          fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (project.deadline != null)
                  Expanded(
                    child: Text(DateFormat('d MMM').format(project.deadline!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: cs.onSurface.withValues(alpha: 0.3))),
                  )
                else
                  Expanded(
                    child: Text("Süresiz",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: cs.onSurface.withValues(alpha: 0.3))),
                  ),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "PROJE",
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
