import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';
import '../../models/team_model.dart';
import '../../services/firebase_service.dart';
import '../../core/phobes_theme.dart';
import '../../core/phobes_detail_panel.dart';
import '../tasks/task_add_edit_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../../widgets/phobes_widgets.dart';
import '../../widgets/phobes_form_wrapper.dart';
import '../../l10n/app_localizations.dart';
import 'tabs/project_notes_tab.dart';
import 'tabs/project_resources_tab.dart';
import 'tabs/project_statistics_tab.dart';
import 'tabs/project_activity_tab.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  final Team team;
  final VoidCallback? onBack;

  final bool isEmbedded;
  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.team,
    this.onBack,
    this.isEmbedded = false,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final FirebaseService _fb = FirebaseService();
  String _currentView = 'kanban';
  String _searchQuery = '';
  late final Stream<Project> _projectStream;
  late final Stream<List<Task>> _projectTasksStream;

  bool _canUpdateTaskStatus(Task task) {
    final uid = _fb.currentUserId;
    if (uid == null) return false;
    if (widget.team.ownerId == uid || widget.team.adminIds.contains(uid)) {
      return true;
    }
    if (task.userId == uid) return true;
    return task.assignedTo.contains(uid);
  }

  @override
  void initState() {
    super.initState();
    _fb.backfillProjectTaskTeamIds(widget.team.id);
    _projectStream = _fb
        .getProjectStream(widget.team.id, widget.project.id)
        .asBroadcastStream();
    _projectTasksStream = _fb
        .getProjectTasksStream(widget.team.id, widget.project.id)
        .asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectColor = Color(widget.project.color);
    final isWide = MediaQuery.of(context).size.width >= 900;
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<Project>(
      stream: _projectStream,
      builder: (context, projectSnapshot) {
        final currentProject = projectSnapshot.data ?? widget.project;

        return StreamBuilder<List<Task>>(
          stream: _projectTasksStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off_rounded,
                          size: 48, color: cs.error.withOpacity(0.85),),
                      const SizedBox(height: 12),
                      Text(
                        l10n.projectTasksLoadError,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return Center(
                child: PhobesLoadingIndicator(color: cs.primary),
              );
            }

            var tasks = snapshot.data ?? [];

            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              tasks = tasks
                  .where(
                    (t) =>
                        t.title.toLowerCase().contains(q) ||
                        t.description.toLowerCase().contains(q),
                  )
                  .toList();
            }

            final todoTasks = tasks.where((t) => t.status == 'todo').toList();
            final inProgressTasks =
                tasks.where((t) => t.status == 'in_progress').toList();
            final reviewTasks =
                tasks.where((t) => t.status == 'review').toList();
            final doneTasks = tasks
                .where((t) => t.status == 'done' || t.isCompleted)
                .toList();

            final total = tasks.length;
            final completed = doneTasks.length;
            final progress = total > 0 ? completed / total : 0.0;

            final headerWidgets = [
              if (widget.onBack != null) const SizedBox(height: 4),
              FadeInDown(
                duration: PhobesTheme.animNormal,
                child: _buildProjectHeader(
                  projectColor,
                  progress,
                  snapshot.data?.length ?? 0,
                  snapshot.data
                          ?.where((t) => t.status == 'done' || t.isCompleted)
                          .length ??
                      0,
                  isDark,
                  cs,
                  currentProject,
                ),
              ),
              _buildViewSwitcher(cs, isDark),
              _buildFilters(cs, isDark),
              const SizedBox(height: 2),
            ];

            Widget tabContent;
            if (_currentView == 'kanban') {
              if (isWide) {
                tabContent = Padding(
                  padding: EdgeInsets.fromLTRB(8, 4, 8, isWide ? 0 : 90),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildKanbanColumns(
                      todoTasks,
                      inProgressTasks,
                      reviewTasks,
                      doneTasks,
                      isDark,
                      true,
                    ),
                  ),
                );
              } else {
                tabContent = ListView(
                  padding: EdgeInsets.fromLTRB(8, 4, 8, isWide ? 0 : 90),
                  children: _buildKanbanColumns(
                    todoTasks,
                    inProgressTasks,
                    reviewTasks,
                    doneTasks,
                    isDark,
                    false,
                  ),
                );
              }
            } else if (_currentView == 'list') {
              tabContent = ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: _buildListView(
                  [
                    ...todoTasks,
                    ...inProgressTasks,
                    ...reviewTasks,
                    ...doneTasks,
                  ],
                  cs,
                  isDark,
                  projectColor,
                ),
              );
            } else if (_currentView == 'notes') {
              tabContent = ProjectNotesTab(
                project: currentProject,
                teamId: widget.team.id,
              );
            } else if (_currentView == 'resources') {
              tabContent = ProjectResourcesTab(
                project: currentProject,
                team: widget.team,
              );
            } else if (_currentView == 'statistics') {
              tabContent = ProjectStatisticsTab(
                project: currentProject,
                teamId: widget.team.id,
              );
            } else {
              tabContent = ProjectActivityTab(
                project: currentProject,
                teamId: widget.team.id,
              );
            }

            final Widget content = SafeArea(
              top: widget.onBack != null && !widget.isEmbedded,
              bottom: false,
              child: (isWide || widget.isEmbedded)
                  ? Column(
                      children: [
                        ...headerWidgets,
                        Expanded(child: tabContent),
                      ],
                    )
                  : NestedScrollView(
                      headerSliverBuilder: (context, _) => [
                        SliverToBoxAdapter(
                          child: Column(
                            children: headerWidgets,
                          ),
                        ),
                      ],
                      body: tabContent,
                    ),
            );

            if (widget.isEmbedded) {
              return Material(
                color: Colors.transparent,
                child: content,
              );
            }

            return Scaffold(
              backgroundColor: cs.surface,
              appBar: widget.onBack != null
                  ? null
                  : PhobesPremiumAppBar(
                      title: currentProject.name,
                      onBackPressed: widget.onBack,
                      trailing: PopupMenuButton<String>(
                        offset: const Offset(0, 48),
                        position: PopupMenuPosition.under,
                        icon: IgnorePointer(
                          child: PhobesIconButton(
                            icon: Icons.more_vert_rounded,
                            iconSize: 18,
                            padding: 6,
                            onTap: () {},
                          ),
                        ),
                        color: cs.surfaceVariant.withOpacity(0.95),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: cs.outline.withOpacity(0.1),
                          ),
                        ),
                        elevation: 8,
                        onSelected: (value) => _handleMenuAction(value),
                        itemBuilder: (_) => [
                          _buildMenuItem(
                            'edit',
                            Icons.edit_rounded,
                            AppLocalizations.of(context)!.edit,
                            cs,
                          ),
                          if (currentProject.status != 'active')
                            _buildMenuItem(
                              'active',
                              Icons.play_arrow_rounded,
                              l10n.projectMakeActive,
                              cs,
                              color: Colors.blueAccent,
                            ),
                          if (currentProject.status != 'completed')
                            _buildMenuItem(
                              'complete',
                              Icons.check_circle_rounded,
                              l10n.projectMarkComplete,
                              cs,
                              color: Colors.greenAccent,
                            ),
                          if (currentProject.status != 'archived')
                            _buildMenuItem(
                              'archive',
                              Icons.archive_rounded,
                              l10n.projectArchive,
                              cs,
                              color: Colors.orangeAccent,
                            ),
                          _buildMenuItem(
                            'delete',
                            Icons.delete_rounded,
                            AppLocalizations.of(context)!.delete,
                            cs,
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),
              body: content,
            );
          },
        );
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String label,
    ColorScheme cs, {
    Color? color,
    bool isDestructive = false,
  }) {
    final textColor =
        isDestructive ? Colors.redAccent : (color ?? cs.onSurface);
    final iconColor = isDestructive
        ? Colors.redAccent
        : (color ?? cs.onSurface.withOpacity(0.7));

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectHeader(
    Color projectColor,
    double progress,
    int total,
    int completed,
    bool isDark,
    ColorScheme cs,
    Project currentProject,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final mq = MediaQuery.of(context);
    final isCompact = mq.size.width < 600;

    return Container(
      margin: EdgeInsets.fromLTRB(
        isCompact ? 4 : 4,
        widget.isEmbedded ? 12 : 24,
        isCompact ? 4 : 4,
        isCompact ? 4 : 4,
      ),
      padding: EdgeInsets.all(isCompact ? 8 : 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? cs.surfaceVariant : projectColor.withOpacity(0.1),
            isDark ? cs.surfaceVariant : cs.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
        border: Border.all(color: projectColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: projectColor.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.onBack != null) ...[
                PhobesIconButton(
                  icon: Icons.arrow_back_rounded,
                  backgroundColor: projectColor.withOpacity(0.2),
                  color: projectColor,
                  padding: isCompact ? 8 : 10,
                  size: isCompact ? 36 : 40,
                  onTap: widget.onBack!,
                ),
                SizedBox(width: isCompact ? 12 : 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: projectColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getProjectStatusLabel(currentProject.status),
                            style: GoogleFonts.outfit(
                              fontSize: isCompact ? 9 : 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: projectColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (widget.project.deadline != null)
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: widget.project.isOverdue
                                    ? Colors.redAccent
                                    : cs.onSurface.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd MMM', locale)
                                    .format(widget.project.deadline!),
                                style: GoogleFonts.outfit(
                                  fontSize: isCompact ? 11 : 12,
                                  color: widget.project.isOverdue
                                      ? Colors.redAccent
                                      : cs.onSurface.withOpacity(0.6),
                                  fontWeight: widget.project.isOverdue
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: isCompact ? 2 : 4),
                    Text(
                      currentProject.name,
                      style: GoogleFonts.outfit(
                        fontSize: isCompact ? 20 : 28,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    if (widget.project.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        currentProject.description,
                        style: GoogleFonts.outfit(
                          fontSize: isCompact ? 12 : 14,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                        maxLines: isCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (widget.onBack != null)
                PopupMenuButton<String>(
                  offset: const Offset(0, 48),
                  position: PopupMenuPosition.under,
                  icon: IgnorePointer(
                    child: PhobesIconButton(
                      icon: Icons.more_horiz_rounded,
                      iconSize: 18,
                      padding: 6,
                      backgroundColor: projectColor.withOpacity(0.2),
                      color: projectColor,
                      onTap: () {},
                    ),
                  ),
                  color: cs.surfaceVariant.withOpacity(0.95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: cs.outline.withOpacity(0.1),
                    ),
                  ),
                  elevation: 8,
                  onSelected: (value) => _handleMenuAction(value),
                  itemBuilder: (_) => [
                    _buildMenuItem('edit', Icons.edit_rounded, AppLocalizations.of(context)!.edit, cs),
                    if (currentProject.status != 'active')
                      _buildMenuItem(
                        'active',
                        Icons.play_arrow_rounded,
                        l10n.projectMakeActive,
                        cs,
                        color: Colors.blueAccent,
                      ),
                    if (currentProject.status != 'completed')
                      _buildMenuItem(
                        'complete',
                        Icons.check_circle_rounded,
                        l10n.projectMarkComplete,
                        cs,
                        color: Colors.greenAccent,
                      ),
                    if (currentProject.status != 'archived')
                      _buildMenuItem(
                        'archive',
                        Icons.archive_rounded,
                        l10n.projectArchive,
                        cs,
                        color: Colors.orangeAccent,
                      ),
                    _buildMenuItem(
                      'delete',
                      Icons.delete_rounded,
                      AppLocalizations.of(context)!.delete,
                      cs,
                      isDestructive: true,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher(ColorScheme cs, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);
    final isCompact = mq.size.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? cs.surfaceVariant.withOpacity(0.4)
                    : cs.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withOpacity(0.05)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildViewTab(
                      'kanban',
                      l10n.projectViewKanban,
                      Icons.view_kanban_rounded,
                      cs,
                      isCompact,
                    ),
                    _buildViewTab('list', l10n.projectViewList, Icons.view_list_rounded, cs,
                        isCompact),
                    _buildViewTab(
                      'notes',
                      l10n.projectViewNotes,
                      Icons.note_alt_rounded,
                      cs,
                      isCompact,
                    ),
                    _buildViewTab(
                      'resources',
                      l10n.projectViewResources,
                      Icons.source_rounded,
                      cs,
                      isCompact,
                    ),
                    _buildViewTab(
                      'statistics',
                      l10n.projectViewStatistics,
                      Icons.insights_rounded,
                      cs,
                      isCompact,
                    ),
                    _buildViewTab(
                      'activity',
                      l10n.projectViewActivity,
                      Icons.history_rounded,
                      cs,
                      isCompact,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PhobesIconButton(
            icon: Icons.filter_list_rounded,
            backgroundColor:
                isDark ? cs.surfaceVariant.withOpacity(0.4) : cs.surfaceVariant,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ColorScheme cs, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 13),
              decoration: InputDecoration(
                hintText: l10n.projectSearchTasksHint,
                hintStyle: GoogleFonts.outfit(
                  color: cs.onSurface.withOpacity(0.4),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: cs.onSurface.withOpacity(0.4),
                  size: 18,
                ),
                filled: true,
                fillColor: isDark
                    ? cs.surfaceVariant.withOpacity(0.3)
                    : cs.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PhobesIconButton(
            icon: Icons.add_rounded,
            backgroundColor: Color(widget.project.color),
            color: Colors.white,
            onTap: () => _addTaskToProject(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTab(
    String viewId,
    String title,
    IconData icon,
    ColorScheme cs,
    bool isCompact,
  ) {
    final isSelected = _currentView == viewId;
    final showText = isSelected || !isCompact;

    return GestureDetector(
      onTap: () => setState(() => _currentView = viewId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : cs.onSurface.withOpacity(0.5),
            ),
            if (showText) ...[
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color:
                      isSelected ? Colors.white : cs.onSurface.withOpacity(0.5),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListView(
    List<Task> allTasks,
    ColorScheme cs,
    bool isDark,
    Color projectColor,
  ) {
    if (allTasks.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Text(
          l10n.projectNoTasks,
          style: GoogleFonts.outfit(color: cs.onSurface.withOpacity(0.5)),
        ),
      );
    }

    final sortedTasks = List<Task>.from(allTasks)
      ..sort((a, b) {
        if (b.priority != a.priority) return b.priority.compareTo(a.priority);
        return a.endTime.compareTo(b.endTime);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        final taskColor = Color(task.color);
        final locale = AppLocalizations.of(context)!.localeName;

        return PhobesCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          onTap: () => PhobesDetailPanel.open(
            context,
            TaskDetailScreen(task: task),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (task.id != null && !task.isCompleted) {
                    _fb.setTaskCompleted(task.id!, true);
                  }
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isCompleted
                          ? Colors.green
                          : cs.outline.withOpacity(0.3),
                      width: 2,
                    ),
                    color: task.isCompleted ? Colors.green : Colors.transparent,
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: task.isCompleted
                            ? cs.onSurface.withOpacity(0.5)
                            : cs.onSurface,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              _buildPriorityDot(task.priority),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: taskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStatusText(task.status),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: taskColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('dd MMM', locale).format(task.endTime),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriorityDot(int priority) {
    Color color;
    switch (priority) {
      case 3:
        color = Colors.redAccent;
        break;
      case 2:
        color = Colors.orangeAccent;
        break;
      default:
        color = Colors.greenAccent;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  String _getStatusText(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'todo':
        return l10n.projectStatusTodoUpper;
      case 'in_progress':
        return l10n.projectStatusInProgressUpper;
      case 'review':
        return l10n.projectStatusReviewUpper;
      case 'done':
        return l10n.projectStatusDoneUpper;
      default:
        return l10n.projectStatusUnknownUpper;
    }
  }

  List<Widget> _buildKanbanColumns(
    List<Task> todoTasks,
    List<Task> inProgressTasks,
    List<Task> reviewTasks,
    List<Task> doneTasks,
    bool isDark,
    bool isDesktop,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _buildKanbanColumn(
        l10n.statusTodo,
        todoTasks,
        Colors.blueAccent,
        Icons.radio_button_unchecked,
        'todo',
        isDark,
        isDesktop,
      ),
      if (isDesktop) const SizedBox(width: 12),
      _buildKanbanColumn(
        l10n.statusInProgress,
        inProgressTasks,
        Colors.orangeAccent,
        Icons.timelapse_rounded,
        'in_progress',
        isDark,
        isDesktop,
      ),
      if (isDesktop) const SizedBox(width: 12),
      _buildKanbanColumn(
        l10n.statusReview,
        reviewTasks,
        Colors.purpleAccent,
        Icons.rate_review_rounded,
        'review',
        isDark,
        isDesktop,
      ),
      if (isDesktop) const SizedBox(width: 12),
      _buildKanbanColumn(
        l10n.statusDone,
        doneTasks,
        Colors.greenAccent,
        Icons.check_circle,
        'done',
        isDark,
        isDesktop,
      ),
    ];
  }

  Widget _buildKanbanColumn(
    String title,
    List<Task> tasks,
    Color color,
    IconData icon,
    String statusId,
    bool isDark,
    bool isDesktop,
  ) {
    final Widget columnContent = DragTarget<Task>(
      onWillAcceptWithDetails: (d) => _canUpdateTaskStatus(d.data),
      onAcceptWithDetails: (details) {
        final task = details.data;
        if (task.id != null && _canUpdateTaskStatus(task)) {
          _fb.updateTaskStatus(task.id!, statusId);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isHovering
                ? color.withOpacity(0.05)
                : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHovering
                  ? color
                  : Theme.of(context).colorScheme.outline.withOpacity(0.1),
              width: isHovering ? 2 : 1,
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
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.projectKanbanEmpty,
                          style: GoogleFonts.outfit(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.2),
                            fontSize: 12,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(8, 4, 8,
                            MediaQuery.of(context).size.width >= 900 ? 20 : 0),
                        itemCount: tasks.length,
                        itemBuilder: (ctx, i) {
                          final task = tasks[i];
                          final bool useLongPress = (Theme.of(context)
                                      .platform ==
                                  TargetPlatform.android ||
                              Theme.of(context).platform == TargetPlatform.iOS);

                          final Widget taskCard =
                              _buildTaskCard(task, color, isDark);

                          final Widget feedback = Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: 280,
                              child: taskCard,
                            ),
                          );

                          if (useLongPress) {
                            return Padding(
                              padding: const EdgeInsets.only(),
                              child: LongPressDraggable<Task>(
                                data: task,
                                delay: const Duration(milliseconds: 150),
                                feedback: feedback,
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: taskCard,
                                ),
                                child: taskCard,
                              ),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.only(),
                              child: Draggable<Task>(
                                data: task,
                                feedback: feedback,
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: taskCard,
                                ),
                                child: taskCard,
                              ),
                            );
                          }
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );

    return isDesktop
        ? Expanded(child: columnContent)
        : SizedBox(
            width: double.infinity,
            height: 400,
            child: columnContent,
          );
  }

  Widget _buildTaskCard(Task task, Color accentColor, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;

    return PhobesCard(
      onTap: () => PhobesDetailPanel.open(
        context,
        TaskDetailScreen(task: task),
      ),
      margin: const EdgeInsets.only(bottom: 8),
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
            child: Container(color: Color(task.color)),
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
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          size: 14,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        color: cs.surfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (val) {
                          if (val == 'delete') {
                            _fb.deleteTask(task.id!);
                          } else if (val == 'done') {
                            _fb.setTaskCompleted(task.id!, true);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'done',
                            height: 32,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.projectMarkComplete,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            height: 32,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 14,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(context)!.delete,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('d MMM', locale).format(task.endTime),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.projectTaskBadge,
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

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'active':
        await _fb.updateProject(
          widget.team.id,
          widget.project.id,
          {'status': 'active'},
        );
        break;
      case 'complete':
        await _fb.updateProject(
          widget.team.id,
          widget.project.id,
          {'status': 'completed'},
        );
        break;
      case 'archive':
        await _fb.updateProject(
          widget.team.id,
          widget.project.id,
          {'status': 'archived'},
        );
        break;
      case 'delete':
        final l10n = AppLocalizations.of(context)!;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: PhobesTheme.surfaceColor,
            title: Text(
              l10n.projectDeleteTitle,
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            content: Text(
              l10n.projectDeleteConfirm,
              style: GoogleFonts.outfit(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  AppLocalizations.of(ctx)!.cancel,
                  style: GoogleFonts.outfit(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  AppLocalizations.of(ctx)!.delete,
                  style: GoogleFonts.outfit(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await _fb.deleteProject(widget.team.id, widget.project.id);
          if (mounted) Navigator.pop(context);
        }
        break;
      case 'edit':
        _showEditProjectDialog();
        break;
    }
  }

  String _getProjectStatusLabel(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'active':
      case 'in_progress':
        return l10n.projectStatusActiveUpper;
      case 'completed':
      case 'done':
        return l10n.projectStatusCompletedUpper;
      case 'archived':
      case 'archive':
        return l10n.projectStatusArchivedUpper;
      default:
        return status.toUpperCase();
    }
  }

  void _addTaskToProject() {
    final l10n = AppLocalizations.of(context)!;
    PhobesFormWrapper.show(
      context,
      title: l10n.projectNewTaskTitle,
      form: TaskAddEditScreen(
        selectedDate: DateTime.now(),
        groupId: widget.project.id,
        teamId: widget.team.id,
      ),
    );
  }

  void _showEditProjectDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: widget.project.name);
    final descCtrl = TextEditingController(text: widget.project.description);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: isDark ? PhobesTheme.surfaceColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.projectEditTitle,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: l10n.projectNameHint,
                hintStyle: GoogleFonts.outfit(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                filled: true,
                fillColor:
                    isDark ? PhobesTheme.backgroundColor : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l10n.projectDescriptionLabel,
                hintStyle: GoogleFonts.outfit(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                filled: true,
                fillColor:
                    isDark ? PhobesTheme.backgroundColor : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  await _fb.updateProject(
                    widget.team.id,
                    widget.project.id,
                    {
                      'name': nameCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                    },
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PhobesTheme.kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.save,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
