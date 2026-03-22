import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';
import '../../models/team_model.dart';
import '../../services/firebase_service.dart';
import '../../core/phobes_theme.dart';
import '../../core/page_transitions.dart';
import '../tasks/task_add_edit_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../../widgets/phobes_widgets.dart';
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
  String _currentView = 'kanban'; // kanban, list, calendar
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectColor = Color(widget.project.color);
    final isWide = MediaQuery.of(context).size.width >= 900;

    final Widget content = StreamBuilder<List<Task>>(
        stream: _fb.getProjectTasksStream(widget.team.id, widget.project.id),
        builder: (context, snapshot) {
          var tasks = snapshot.data ?? [];

          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            tasks = tasks
                .where((t) =>
                    t.title.toLowerCase().contains(q) ||
                    t.description.toLowerCase().contains(q))
                .toList();
          }

          final todoTasks = tasks.where((t) => t.status == 'todo').toList();
          final inProgressTasks =
              tasks.where((t) => t.status == 'in_progress').toList();
          final reviewTasks = tasks.where((t) => t.status == 'review').toList();
          final doneTasks =
              tasks.where((t) => t.status == 'done' || t.isCompleted).toList();

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
                  cs),
            ),
            _buildViewSwitcher(cs, isDark),
            _buildFilters(cs, isDark),
            const SizedBox(height: 2),
          ];

          Widget tabContent;
          if (_currentView == 'kanban') {
            if (isWide) {
              tabContent = Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 80),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildKanbanColumns(todoTasks, inProgressTasks,
                      reviewTasks, doneTasks, isDark, true),
                ),
              );
            } else {
              tabContent = ListView(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 120),
                children: _buildKanbanColumns(todoTasks, inProgressTasks,
                    reviewTasks, doneTasks, isDark, false),
              );
            }
          } else if (_currentView == 'list') {
            tabContent = ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: _buildListView([
                ...todoTasks,
                ...inProgressTasks,
                ...reviewTasks,
                ...doneTasks
              ], cs, isDark, projectColor),
            );
          } else if (_currentView == 'notes') {
            tabContent = ProjectNotesTab(project: widget.project);
          } else if (_currentView == 'resources') {
            tabContent =
                ProjectResourcesTab(project: widget.project, team: widget.team);
          } else if (_currentView == 'statistics') {
            tabContent = ProjectStatisticsTab(project: widget.project);
          } else {
            tabContent = ProjectActivityTab(project: widget.project);
          }

          if (isWide || widget.isEmbedded) {
            return Column(
              children: [
                ...headerWidgets,
                Expanded(child: tabContent),
              ],
            );
          } else {
            return NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: Column(
                    children: headerWidgets,
                  ),
                ),
              ],
              body: tabContent,
            );
          }
        },
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
              title: widget.project.name,
              onBackPressed: widget.onBack,
              trailing: PopupMenuButton<String>(
                offset: const Offset(0, 48),
                position: PopupMenuPosition.under,
                icon: PhobesIconButton(
                  icon: Icons.more_vert_rounded,
                  iconSize: 18,
                  padding: 6,
                  onTap: () {},
                ),
                color: cs.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                onSelected: (value) => _handleMenuAction(value),
                itemBuilder: (_) => [
                  _buildMenuItem('edit', Icons.edit_rounded, 'Düzenle'),
                  _buildMenuItem(
                      'complete', Icons.check_circle_rounded, 'Tamamla'),
                  _buildMenuItem('archive', Icons.archive_rounded, 'Arşivle'),
                  _buildMenuItem('delete', Icons.delete_rounded, 'Sil'),
                ],
              ),
            ),
      body: content,
    );
  }

  Widget _buildProjectHeader(Color projectColor, double progress, int total,
      int completed, bool isDark, ColorScheme cs) {
    final mq = MediaQuery.of(context);
    final isCompact = mq.size.width < 600;

    return Container(
      margin: EdgeInsets.fromLTRB(
        isCompact ? 4 : 4,
        isCompact ? 16 : 24, // Increased top margin
        isCompact ? 4 : 4,
        isCompact ? 4 : 4,
      ),
      padding: EdgeInsets.all(isCompact ? 8 : 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark
                ? cs.surfaceContainerHighest
                : projectColor.withValues(alpha: 0.1),
            isDark ? cs.surfaceContainer : cs.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
        border:
            Border.all(color: projectColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: projectColor.withValues(alpha: 0.1),
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
                  backgroundColor: projectColor.withValues(alpha: 0.2),
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
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: projectColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.project.status.toUpperCase(),
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
                              Icon(Icons.calendar_today_rounded,
                                  size: 12,
                                  color: widget.project.isOverdue
                                      ? Colors.redAccent
                                      : cs.onSurface.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd MMM', 'tr')
                                    .format(widget.project.deadline!),
                                style: GoogleFonts.outfit(
                                  fontSize: isCompact ? 11 : 12,
                                  color: widget.project.isOverdue
                                      ? Colors.redAccent
                                      : cs.onSurface.withValues(alpha: 0.6),
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
                      widget.project.name,
                      style: GoogleFonts.outfit(
                        fontSize: isCompact ? 20 : 28,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    if (widget.project.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.project.description,
                        style: GoogleFonts.outfit(
                          fontSize: isCompact ? 12 : 14,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: isCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (widget.onBack != null)
                PopupMenuButton<String>(
                  offset: const Offset(0, 48),
                  position: PopupMenuPosition.under,
                  icon: PhobesIconButton(
                    icon: Icons.more_horiz_rounded,
                    iconSize: 18,
                    padding: 6,
                    backgroundColor: projectColor.withValues(alpha: 0.2),
                    color: projectColor,
                    onTap: () {},
                  ),
                  color: cs.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  onSelected: (value) => _handleMenuAction(value),
                  itemBuilder: (_) => [
                    _buildMenuItem('edit', Icons.edit_rounded, 'Düzenle'),
                    _buildMenuItem(
                        'complete', Icons.check_circle_rounded, 'Tamamla'),
                    _buildMenuItem('archive', Icons.archive_rounded, 'Arşivle'),
                    _buildMenuItem('delete', Icons.delete_rounded, 'Sil'),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher(ColorScheme cs, bool isDark) {
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
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
                    : cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withValues(alpha: 0.05)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildViewTab(
                        'kanban', 'Panolar', Icons.view_kanban_rounded, cs, isCompact),
                    _buildViewTab('list', 'Liste', Icons.view_list_rounded, cs, isCompact),
                    _buildViewTab(
                        'notes', 'Notlar', Icons.note_alt_rounded, cs, isCompact),
                    _buildViewTab(
                        'resources', 'Kaynaklar', Icons.source_rounded, cs, isCompact),
                    _buildViewTab(
                        'statistics', 'İstatistik', Icons.insights_rounded, cs, isCompact),
                    _buildViewTab(
                        'activity', 'Aktivite', Icons.history_rounded, cs, isCompact),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PhobesIconButton(
            icon: Icons.filter_list_rounded,
            backgroundColor: isDark
                ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
                : cs.surfaceContainerHigh,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Görevlerde ara...',
                hintStyle: GoogleFonts.outfit(
                    color: cs.onSurface.withValues(alpha: 0.4)),
                prefixIcon: Icon(Icons.search_rounded,
                    color: cs.onSurface.withValues(alpha: 0.4), size: 18),
                filled: true,
                fillColor: isDark
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.3)
                    : cs.surfaceContainerHigh,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
      String viewId, String title, IconData icon, ColorScheme cs, bool isCompact) {
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
                      color: cs.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : cs.onSurface.withValues(alpha: 0.5)),
            if (showText) ...[
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: isSelected
                      ? Colors.white
                      : cs.onSurface.withValues(alpha: 0.5),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildListView(
      List<Task> allTasks, ColorScheme cs, bool isDark, Color projectColor) {
    if (allTasks.isEmpty) {
      return Center(
        child: Text("Bu projede hiç görev yok.",
            style:
                GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.5))),
      );
    }

    // Sort tasks: high priority first, then deadline
    var sortedTasks = List<Task>.from(allTasks)
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

        return PhobesCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          onTap: () => PhobesPageRoute.pushResponsive(
              context, TaskDetailScreen(task: task)),
          child: Row(
            children: [
              // Status Circle
              GestureDetector(
                onTap: () {
                  if (!task.isCompleted) {
                    _fb.updateTaskStatus(task.id!, 'done');
                    _fb.updateTask(task.copyWith(isCompleted: true));
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
                            : cs.outline.withValues(alpha: 0.3),
                        width: 2),
                    color: task.isCompleted ? Colors.green : Colors.transparent,
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // Title and Priority
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
                            ? cs.onSurface.withValues(alpha: 0.5)
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
                            color: cs.onSurface.withValues(alpha: 0.5)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Priority Dot
              _buildPriorityDot(task.priority),
              const SizedBox(width: 12),

              // Group (List Column roughly)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: taskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStatusText(task.status),
                  style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: taskColor),
                ),
              ),
              const SizedBox(width: 12),

              // Date
              Text(
                DateFormat('dd MMM').format(task.endTime),
                style: GoogleFonts.outfit(
                    fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
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
    switch (status) {
      case 'todo':
        return 'YAPILACAK';
      case 'in_progress':
        return 'İŞLEMDE';
      case 'review':
        return 'İNCELEME';
      case 'done':
        return 'BİTTİ';
      default:
        return 'BİLİNMİYOR';
    }
  }

  List<Widget> _buildKanbanColumns(
      List<Task> todoTasks,
      List<Task> inProgressTasks,
      List<Task> reviewTasks,
      List<Task> doneTasks,
      bool isDark,
      bool isDesktop) {
    return [
      _buildKanbanColumn(
        'Yapılacak',
        todoTasks,
        Colors.blueAccent,
        Icons.radio_button_unchecked,
        'todo',
        isDark,
        isDesktop,
      ),
      if (isDesktop) const SizedBox(width: 12),
      _buildKanbanColumn(
        'İşlemde',
        inProgressTasks,
        Colors.orangeAccent,
        Icons.timelapse_rounded,
        'in_progress',
        isDark,
        isDesktop,
      ),
      if (isDesktop) const SizedBox(width: 12),
      _buildKanbanColumn(
        'İnceleme',
        reviewTasks,
        Colors.purpleAccent,
        Icons.rate_review_rounded,
        'review',
        isDark,
        isDesktop,
      ),
      if (isDesktop) const SizedBox(width: 12),
      _buildKanbanColumn(
        'Bitti',
        doneTasks,
        Colors.greenAccent,
        Icons.check_circle,
        'done',
        isDark,
        isDesktop,
      ),
    ];
  }

  Widget _buildKanbanColumn(String title, List<Task> tasks, Color color,
      IconData icon, String statusId, bool isDark, bool isDesktop) {
    Widget columnContent = DragTarget<Task>(
      onAcceptWithDetails: (details) {
        final task = details.data;
        if (task.id != null) {
          _fb.updateTaskStatus(task.id!, statusId);
          if (statusId == 'done') {
            _fb.updateTask(task.copyWith(isCompleted: true));
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isHovering
                ? color.withValues(alpha: 0.05)
                : Theme.of(context)
                    .colorScheme
                    .surfaceContainer
                    .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHovering
                  ? color
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.1),
              width: isHovering ? 2 : 1,
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
                      child: Text("${tasks.length}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    )
                  ],
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          "Boş",
                          style: GoogleFonts.outfit(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.2),
                              fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 120),
                        itemCount: tasks.length,
                        itemBuilder: (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 0),
                          child: Draggable<Task>(
                            data: tasks[i],
                            feedback: Material(
                              color: Colors.transparent,
                              child: SizedBox(
                                width: 280,
                                child:
                                    _buildTaskCard(tasks[i], color, isDark),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildTaskCard(tasks[i], color, isDark),
                            ),
                            child: _buildTaskCard(tasks[i], color, isDark),
                          ),
                        ),
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

    return PhobesCard(
      onTap: () => PhobesPageRoute.pushResponsive(
        context,
        TaskDetailScreen(task: task),
      ),
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
          border: Border(left: BorderSide(color: Color(task.color), width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
                // Context Menu
                SizedBox(
                  width: 20,
                  height: 20,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.more_horiz_rounded,
                        size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                    color: cs.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) {
                      if (val == 'delete') {
                        _fb.deleteTask(task.id!);
                      } else if (val == 'done') {
                        _fb.updateTaskStatus(task.id!, 'done');
                        _fb.updateTask(task.copyWith(isCompleted: true));
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'done',
                        height: 32,
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 14, color: Colors.green),
                            const SizedBox(width: 6),
                            Text('Tamamla',
                                style: GoogleFonts.outfit(
                                    fontSize: 11, color: cs.onSurface)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        height: 32,
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline_rounded,
                                size: 14, color: Colors.redAccent),
                            const SizedBox(width: 6),
                            Text('Sil',
                                style: GoogleFonts.outfit(
                                    fontSize: 11, color: cs.onSurface)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(DateFormat('d MMM', 'tr').format(task.endTime),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.5))),
                ),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "GÖREV",
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

  PopupMenuItem<String> _buildMenuItem(
      String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'complete':
        await _fb.updateProject(
            widget.team.id, widget.project.id, {'status': 'completed'});
        if (mounted) Navigator.pop(context);
        break;
      case 'archive':
        await _fb.updateProject(
            widget.team.id, widget.project.id, {'status': 'archived'});
        if (mounted) Navigator.pop(context);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: PhobesTheme.surfaceColor,
            title: Text('Projeyi Sil',
                style: GoogleFonts.outfit(color: Colors.white)),
            content: Text('Bu projeyi silmek istediğinize emin misiniz?',
                style: GoogleFonts.outfit(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('İptal',
                    style: GoogleFonts.outfit(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Sil',
                    style: GoogleFonts.outfit(color: Colors.redAccent)),
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

  void _addTaskToProject() {
    PhobesPageRoute.pushResponsive(
      context,
      TaskAddEditScreen(
        selectedDate: DateTime.now(),
        groupId: widget.project.id,
      ),
    );
  }

  void _showEditProjectDialog() {
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
              'Projeyi Düzenle',
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
                  color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Proje adı',
                hintStyle: GoogleFonts.outfit(
                    color: isDark ? Colors.white38 : Colors.black38),
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
                  color: isDark ? Colors.white : Colors.black87),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Açıklama',
                hintStyle: GoogleFonts.outfit(
                    color: isDark ? Colors.white38 : Colors.black38),
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
                  'Kaydet',
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
