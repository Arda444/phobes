import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/module_ui_tokens.dart';
import '../../models/task_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/phobes_form_wrapper.dart';
import '../../l10n/app_localizations.dart';
import 'embed_utils.dart';

class TaskCardData {
  final String taskId;

  const TaskCardData({required this.taskId});

  Map<String, dynamic> toJson() => {'taskId': taskId};

  factory TaskCardData.fromJson(Map<String, dynamic> json) =>
      TaskCardData(taskId: json['taskId'] ?? '');
}

class TaskCardBlockEmbed extends CustomBlockEmbed {
  const TaskCardBlockEmbed(String value) : super(taskCardType, value);
  static const String taskCardType = 'task_card';

  static TaskCardBlockEmbed fromData(TaskCardData data) =>
      TaskCardBlockEmbed(jsonEncode(data.toJson()));

  TaskCardData get taskCardData => TaskCardData.fromJson(jsonDecode(data));
}

class TaskCardEmbedBuilder extends EmbedBuilder {
  @override
  String get key => TaskCardBlockEmbed.taskCardType;

  @override
  bool get expanded => true;

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle,) {
    try {
      final data = TaskCardData.fromJson(jsonDecode(node.value.data));
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _TaskCardWidget(data: data, readOnly: readOnly),
      );
    } catch (_) {
      return embedError(context);
    }
  }
}

class _TaskCardWidget extends StatefulWidget {
  final TaskCardData data;
  final bool readOnly;

  const _TaskCardWidget({
    required this.data,
    required this.readOnly,
  });

  @override
  State<_TaskCardWidget> createState() => _TaskCardWidgetState();
}

class _TaskCardWidgetState extends State<_TaskCardWidget> {
  final FirebaseService _fb = FirebaseService();
  late final Stream<Task?> _taskStream;

  @override
  void initState() {
    super.initState();
    _taskStream = _fb.getTaskStream(widget.data.taskId).asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<Task?>(
      stream: _taskStream,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        final locale = l10n.localeName;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.errorContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.error.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 20, color: cs.error),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.noteTaskNotFound,
                  style: GoogleFonts.outfit(color: cs.error),
                ),
              ],
            ),
          );
        }

        final task = snapshot.data!;
        final taskColor = Color(task.color);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD6D6D6), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [

              GestureDetector(
                onTap: () async {
                  if (widget.readOnly) return;
                  final newStatus = !task.isCompleted;
                  try {
                    await _fb.setTaskCompleted(task.id!, newStatus);
                  } catch (e) {
                    debugPrint('Task update error: $e');
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted ? Colors.green.shade600 : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted ? Colors.green.shade600 : const Color(0xFF1A1A1A).withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: task.isCompleted ? const Color(0xFF1A1A1A).withOpacity(0.5) : const Color(0xFF1A1A1A),
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 11, color: const Color(0xFF1A1A1A).withOpacity(0.4)),
                        const SizedBox(width: 3),
                        Text(
                          DateFormat('d MMM yyyy, HH:mm', locale)
                              .format(task.endTime),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF1A1A1A).withOpacity(0.45),
                          ),
                        ),
                        if (task.priority > 0) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.flag_rounded, size: 11, color: task.priority == 2 ? Colors.redAccent : Colors.orangeAccent),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                width: 3,
                height: 28,
                decoration: BoxDecoration(
                  color: taskColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<TaskCardData?> showInsertTaskDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final locale = l10n.localeName;
  final FirebaseService fb = FirebaseService();

  List<Task> allTasks = [];
  bool loading = true;

  return PhobesFormWrapper.show<TaskCardData>(
    context,
    title: l10n.noteAddTask,
    panelWidth: 400,
    form: StatefulBuilder(
      builder: (ctx, setState) {
        if (loading && allTasks.isEmpty) {
          fb.getTasksForStats().then((tasks) {
            if (ctx.mounted) {
              setState(() {
                allTasks = tasks.where((t) => !t.isCompleted).toList();
                loading = false;
              });
            }
          });
        }

        final cs = Theme.of(ctx).colorScheme;
        final isWide = ModuleUiTokens.isWideForm(ctx);
        final listHeight = (MediaQuery.sizeOf(ctx).height * 0.55).clamp(220.0, 560.0);

        Widget listBody;
        if (loading) {
          listBody = Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(color: cs.primary),
            ),
          );
        } else if (allTasks.isEmpty) {
          listBody = Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                l10n.noteNoOpenTasks,
                style: GoogleFonts.outfit(color: cs.onSurface.withOpacity(0.5)),
              ),
            ),
          );
        } else {
          listBody = ListView.separated(
            itemCount: allTasks.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: cs.outline.withOpacity(0.1)),
            itemBuilder: (listCtx, i) {
              final task = allTasks[i];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(task.color),
                  ),
                ),
                title: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  DateFormat('d MMM', locale).format(task.endTime),
                  style: GoogleFonts.outfit(fontSize: 12),
                ),
                onTap: () {
                  if (task.id != null) {
                    Navigator.pop(listCtx, TaskCardData(taskId: task.id!));
                  }
                },
                hoverColor: cs.primary.withOpacity(0.05),
              );
            },
          );
        }

        final padded = Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: listBody,
        );

        if (isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: padded)],
          );
        }
        return SizedBox(height: listHeight, child: padded);
      },
    ),
  );
}
