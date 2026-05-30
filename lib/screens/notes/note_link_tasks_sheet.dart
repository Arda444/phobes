import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task_model.dart';
import '../../services/firebase_service.dart';

class NoteLinkTasksSheet extends StatefulWidget {
  final String noteId;
  final List<String> linkedTaskIds;

  const NoteLinkTasksSheet({
    super.key,
    required this.noteId,
    required this.linkedTaskIds,
  });

  @override
  State<NoteLinkTasksSheet> createState() => _NoteLinkTasksSheetState();
}

class _NoteLinkTasksSheetState extends State<NoteLinkTasksSheet> {
  final _searchController = TextEditingController();
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  late Set<String> _linkedIds;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _linkedIds = Set.from(widget.linkedTaskIds);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await FirebaseService().getTasksForStats();
    if (mounted) {
      setState(() {
        _allTasks = tasks;
        _filteredTasks = tasks;
        _loading = false;
      });
    }
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTasks = _allTasks;
      } else {
        _filteredTasks = _allTasks
            .where((t) => t.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [

          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.link_rounded, color: cs.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n?.noteLinkTask ?? 'Link Task',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_linkedIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_linkedIds.length}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n?.noteSearchHint ?? 'Search...',
                hintStyle: GoogleFonts.outfit(
                    fontSize: 14, color: cs.onSurface.withOpacity(0.3),),
                prefixIcon: Icon(Icons.search_rounded,
                    color: cs.onSurface.withOpacity(0.4), size: 20,),
                filled: true,
                fillColor: isDark
                    ? cs.surfaceVariant.withOpacity(0.3)
                    : cs.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),

          if (_linkedIds.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 14, color: cs.primary,),
                  const SizedBox(width: 6),
                  Text(
                    l10n?.noteLinkedTasks ?? 'Linked Tasks',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],

          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: cs.primary,
                      strokeWidth: 2,
                    ),
                  )
                : _filteredTasks.isEmpty
                    ? Center(
                        child: Text(
                          l10n?.noData ?? 'No tasks found',
                          style: GoogleFonts.outfit(
                            color: cs.onSurface.withOpacity(0.4),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredTasks.length,
                        itemBuilder: (ctx, i) {
                          final task = _filteredTasks[i];
                          final isLinked = _linkedIds.contains(task.id);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                dense: true,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),),
                                tileColor: isLinked
                                    ? cs.primary.withOpacity(isDark ? 0.12 : 0.06)
                                    : null,
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Color(task.color).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    task.isCompleted
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    size: 18,
                                    color: Color(task.color),
                                  ),
                                ),
                                title: Text(
                                  task.title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: task.tags.isNotEmpty
                                    ? Text(
                                        task.tags.join(', '),
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color:
                                              cs.onSurface.withOpacity(0.4),
                                        ),
                                        maxLines: 1,
                                      )
                                    : null,
                                trailing: IconButton(
                                  icon: Icon(
                                    isLinked
                                        ? Icons.link_off_rounded
                                        : Icons.add_link_rounded,
                                    color: isLinked
                                        ? cs.error
                                        : cs.primary,
                                    size: 20,
                                  ),
                                  onPressed: () => _toggleLink(task.id!),
                                ),
                                onTap: () => _toggleLink(task.id!),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _linkedIds.toList()),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n?.save ?? 'Done',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLink(String taskId) async {
    final isLinked = _linkedIds.contains(taskId);
    setState(() {
      if (isLinked) {
        _linkedIds.remove(taskId);
      } else {
        _linkedIds.add(taskId);
      }
    });
    if (isLinked) {
      await FirebaseService().unlinkTaskFromNote(widget.noteId, taskId);
    } else {
      await FirebaseService().linkTaskToNote(widget.noteId, taskId);
    }
  }
}
