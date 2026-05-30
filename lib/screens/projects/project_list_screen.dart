import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../models/project_model.dart';
import '../../models/team_model.dart';
import '../../models/task_model.dart';
import '../../services/firebase_service.dart';
import '../../core/phobes_detail_panel.dart';
import '../../core/module_info_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_module_header.dart';
import '../../widgets/phobes_module_info.dart';
import '../../widgets/phobes_widgets.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends StatefulWidget {
  final Team team;
  final Function(Project)? onProjectSelected;
  final bool isEmbedded;
  const ProjectListScreen({
    super.key,
    required this.team,
    this.onProjectSelected,
    this.isEmbedded = false,
  });

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final FirebaseService _fb = FirebaseService();
  String _filter = 'all';
  late final Stream<List<Project>> _projectsStream;
  late final Stream<List<Task>> _teamTasksStream;

  @override
  void initState() {
    super.initState();
    _projectsStream = _fb.getProjectsStream(widget.team.id);
    _teamTasksStream =
        _fb.getTeamTasksStream(widget.team.id).asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final Widget bodyContent = LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final crossAxisCount = w >= 1500
          ? 4
          : w >= 1100
              ? 3
              : w >= 700
                  ? 2
                  : 1;
      final isWide = crossAxisCount > 1;

      return Column(
        children: [
          if (!widget.isEmbedded)
            PhobesModuleHeaderBar(
              title: l10n.moduleInfoProjectsTitle,
              icon: Icons.folder_rounded,
              info: ModuleInfoCatalog.forProjects(l10n),
              onAdd: () => _showCreateProjectDialog(context),
              addTooltip: l10n.create,
              filterChips: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('all', l10n.projectFilterAll),
                  _buildFilterChip('active', l10n.projectFilterActive),
                  _buildFilterChip('completed', l10n.projectFilterCompleted),
                  _buildFilterChip('archived', l10n.projectFilterArchived),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.moduleInfoProjectsTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  PhobesIconButton(
                    icon: Icons.info_outline_rounded,
                    onTap: () => PhobesModuleInfo.show(
                      context,
                      content: ModuleInfoCatalog.forProjects(l10n),
                    ),
                  ),
                  PhobesIconButton(
                    icon: Icons.add_rounded,
                    backgroundColor: cs.primary,
                    color: Colors.white,
                    onTap: () => _showCreateProjectDialog(context),
                  ),
                ],
              ),
            ),
          if (widget.isEmbedded)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              width: double.infinity,
              child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 12,
              children: [
                _buildFilterChip('all', l10n.projectFilterAll),
                _buildFilterChip('active', l10n.projectFilterActive),
                _buildFilterChip('completed', l10n.projectFilterCompleted),
                _buildFilterChip('archived', l10n.projectFilterArchived),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Project>>(
              stream: _projectsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  );
                }

                final allProjects = snapshot.data ?? [];
                final projects = _filter == 'all'
                    ? allProjects
                    : allProjects.where((p) => p.status == _filter).toList();

                if (projects.isEmpty) {
                  return Center(
                    child: FadeInUp(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_rounded,
                              size: 64,
                              color: cs.onSurface.withOpacity(0.1),),
                          const SizedBox(height: 24),
                          Text(
                            l10n.projectEmptyTitle,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.projectEmptySubtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: cs.onSurface.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return isWide
                    ? GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          mainAxisExtent: 220,
                        ),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          return FadeInUp(
                            delay: Duration(milliseconds: index * 50),
                            duration: const Duration(milliseconds: 500),
                            child: _buildProjectCard(projects[index]),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          return FadeInUp(
                            delay: Duration(milliseconds: index * 50),
                            duration: const Duration(milliseconds: 500),
                            child: _buildProjectCard(projects[index]),
                          );
                        },
                      );
              },
            ),
          ),
        ],
      );
    },);

    return Scaffold(
      backgroundColor: cs.surface,
      body: bodyContent,
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return PhobesChip(
      label: label,
      isSelected: isSelected,
      onTap: () => setState(() => _filter = value),
    );
  }

  Widget _buildProjectCard(Project project) {
    final cs = Theme.of(context).colorScheme;
    final locale = AppLocalizations.of(context)!.localeName;
    final projectColor = Color(project.color);

    return PhobesCard(
      onTap: () {
        if (widget.onProjectSelected != null) {
          widget.onProjectSelected!(project);
        } else {
          PhobesDetailPanel.open(
            context,
            ProjectDetailScreen(project: project, team: widget.team),
          );
        }
      },
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  projectColor,
                  projectColor.withOpacity(0.5),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: projectColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: projectColor.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        project.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    _buildStatusBadge(project),
                  ],
                ),
                if (project.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    project.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: cs.onSurface.withOpacity(0.6),
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _ProjectProgressSection(
                  tasksStream: _teamTasksStream,
                  projectId: project.id,
                  projectColor: projectColor,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (project.deadline != null) ...[
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: project.isOverdue
                            ? Colors.redAccent
                            : cs.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd MMM yyyy', locale)
                            .format(project.deadline!),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: project.isOverdue
                              ? Colors.redAccent
                              : cs.onSurface.withOpacity(0.4),
                          fontWeight: project.isOverdue
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: cs.onSurface.withOpacity(0.2),
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

  Widget _buildStatusBadge(Project project) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String label;

    switch (project.status) {
      case 'completed':
        color = Colors.greenAccent;
        label = l10n.projectStatusCompletedUpper;
        break;
      case 'archived':
        color = Colors.grey;
        label = l10n.projectStatusArchivedUpper;
        break;
      default:
        color = cs.primary;
        label = l10n.projectStatusActiveUpper;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
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
          title: l10n.projectNewProjectTitle,
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
                l10n.projectColorSelection,
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
                l10n.projectDeadlineLabel,
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
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: cs.copyWith(
                            primary: cs.primary,
                            onPrimary: Colors.white,
                            surface: cs.surfaceVariant,
                            onSurface: cs.onSurface,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              textStyle: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,),
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
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
                            ? DateFormat('dd MMM yyyy', l10n.localeName)
                                .format(deadline!)
                            : l10n.projectNoDateSelected,
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
                  text: l10n.projectCreateButton,
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    final project = Project(
                      id: '',
                      teamId: widget.team.id,
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      managerId: _fb.currentUserId ?? '',
                      color: selectedColor,
                      deadline: deadline,
                    );

                    await _fb.createProject(widget.team.id, project);
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

// ─── Proje ilerleme bölümü — stream initState'te bir kez oluşturulur ──────────
class _ProjectProgressSection extends StatelessWidget {
  final Stream<List<Task>> tasksStream;
  final String projectId;
  final Color projectColor;

  const _ProjectProgressSection({
    required this.tasksStream,
    required this.projectId,
    required this.projectColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Task>>(
      stream: tasksStream,
      builder: (context, snapshot) {
        final tasks = (snapshot.data ?? [])
            .where((t) => t.groupId == projectId)
            .toList();
        final total = tasks.length;
        final todoCount = tasks
            .where((t) => t.status == 'todo' || t.status == 'active')
            .length;
        final progressCount =
            tasks.where((t) => t.status == 'in_progress').length;
        final reviewCount = tasks.where((t) => t.status == 'review').length;
        final doneCount = tasks
            .where((t) =>
                t.status == 'done' || t.status == 'completed' || t.isCompleted)
            .length;
        final progress = total > 0 ? doneCount / total : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.projectProgress,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: projectColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: projectColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(projectColor),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatItem(label: l10n.statusTodo, count: todoCount, color: Colors.blueAccent),
                const SizedBox(width: 8),
                _StatItem(label: l10n.statusInProgress, count: progressCount, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                _StatItem(label: l10n.statusReview, count: reviewCount, color: Colors.purpleAccent),
                const SizedBox(width: 8),
                _StatItem(label: l10n.statusDone, count: doneCount, color: Colors.greenAccent),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
