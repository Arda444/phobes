import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import 'embed_utils.dart';

// ─────────────────────────────── Enums / Data ────────────────────────────────

enum WorkflowStatus { todo, pending, done }

extension WorkflowStatusX on WorkflowStatus {
  String toJson() => name;

  static WorkflowStatus fromJson(String? s) => WorkflowStatus.values
      .firstWhere((e) => e.name == s, orElse: () => WorkflowStatus.todo);

  String label(AppLocalizations l) {
    switch (this) {
      case WorkflowStatus.todo:
        return l.noteWorkflowTodo;
      case WorkflowStatus.pending:
        return l.noteWorkflowPending;
      case WorkflowStatus.done:
        return l.noteWorkflowDone;
    }
  }

  Color get color {
    switch (this) {
      case WorkflowStatus.todo:    return const Color(0xFF9CA3AF);
      case WorkflowStatus.pending: return const Color(0xFFF59E0B);
      case WorkflowStatus.done:    return const Color(0xFF10B981);
    }
  }

  IconData get icon {
    switch (this) {
      case WorkflowStatus.todo:    return Icons.radio_button_unchecked_rounded;
      case WorkflowStatus.pending: return Icons.timelapse_rounded;
      case WorkflowStatus.done:    return Icons.check_circle_rounded;
    }
  }

  WorkflowStatus get next {
    switch (this) {
      case WorkflowStatus.todo:    return WorkflowStatus.pending;
      case WorkflowStatus.pending: return WorkflowStatus.done;
      case WorkflowStatus.done:    return WorkflowStatus.todo;
    }
  }
}

class WorkflowStep {
  final String title;
  final WorkflowStatus status;

  WorkflowStep({required this.title, this.status = WorkflowStatus.todo});

  Map<String, dynamic> toJson() =>
      {'title': title, 'status': status.toJson()};

  factory WorkflowStep.fromJson(Map<String, dynamic> json) => WorkflowStep(
        title: json['title'] ?? '',
        status: WorkflowStatusX.fromJson(json['status']),
      );

  WorkflowStep copyWith({String? title, WorkflowStatus? status}) =>
      WorkflowStep(title: title ?? this.title, status: status ?? this.status);
}

class WorkflowData {
  final String name;
  final List<WorkflowStep> steps;

  WorkflowData({required this.name, required this.steps});

  Map<String, dynamic> toJson() => {
        'name': name,
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  factory WorkflowData.fromJson(Map<String, dynamic> json) {
    final stepList = json['steps'] as List<dynamic>? ?? [];
    return WorkflowData(
      name: json['name'] ?? 'İş Akışı',
      steps: stepList
          .map((s) => WorkflowStep.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  WorkflowData copyWith({String? name, List<WorkflowStep>? steps}) =>
      WorkflowData(name: name ?? this.name, steps: steps ?? this.steps);
}

// ─────────────────────────────── Embed ───────────────────────────────────────

class WorkflowBlockEmbed extends CustomBlockEmbed {
  const WorkflowBlockEmbed(String value) : super(workflowType, value);
  static const String workflowType = 'workflow';

  static WorkflowBlockEmbed fromData(WorkflowData data) =>
      WorkflowBlockEmbed(jsonEncode(data.toJson()));
}

class WorkflowEmbedBuilder extends EmbedBuilder {
  @override
  String get key => WorkflowBlockEmbed.workflowType;

  @override
  bool get expanded => true;

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    try {
      final data =
          WorkflowData.fromJson(jsonDecode(node.value.data));
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _WorkflowWidget(
          data: data,
          readOnly: readOnly,
          onUpdate: (updated) {
            if (readOnly) return;
            final result =
                getCustomEmbedNode(controller, controller.selection.start);
            if (result != null) {
              controller.replaceText(
                  result.offset, 1, WorkflowBlockEmbed.fromData(updated), null);
            }
          },
        ),
      );
    } catch (_) {
      return embedError(context);
    }
  }
}

// ─────────────────────────────── Widget ──────────────────────────────────────

class _WorkflowWidget extends StatefulWidget {
  final WorkflowData data;
  final bool readOnly;
  final ValueChanged<WorkflowData> onUpdate;

  const _WorkflowWidget({
    required this.data,
    required this.readOnly,
    required this.onUpdate,
  });

  @override
  State<_WorkflowWidget> createState() => _WorkflowWidgetState();
}

class _WorkflowWidgetState extends State<_WorkflowWidget> {
  late WorkflowData _data;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _nameCtrl = TextEditingController(text: _data.name);
  }

  @override
  void didUpdateWidget(covariant _WorkflowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _data = widget.data;
      if (_nameCtrl.text != _data.name) {
        _nameCtrl.text = _data.name;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _update(WorkflowData d) {
    setState(() => _data = d);
    widget.onUpdate(d);
  }

  int get _doneCount =>
      _data.steps.where((s) => s.status == WorkflowStatus.done).length;

  double get _progress =>
      _data.steps.isEmpty ? 0 : _doneCount / _data.steps.length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          _buildHeader(l10n),

          // ── Progress bar ──────────────────────────────────────────────────
          if (_data.steps.isNotEmpty) _buildProgress(l10n),

          // ── Steps ─────────────────────────────────────────────────────────
          if (_data.steps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: List.generate(_data.steps.length, (i) {
                  return _buildStep(i);
                }),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Text(
                'Henüz adım eklenmedi.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF1A1A1A).withOpacity(0.35),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEF0F3)),
        ),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.account_tree_outlined,
            size: 15,
            color: const Color(0xFF1A1A1A).withOpacity(0.55),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: widget.readOnly
              ? Text(
                  _data.name,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF1A1A1A)),
                )
              : TextField(
                  controller: _nameCtrl,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF1A1A1A)),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => _update(_data.copyWith(name: v)),
                ),
        ),
        // Step count badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$_doneCount / ${_data.steps.length}',
            style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A).withOpacity(0.5)),
          ),
        ),
        if (!widget.readOnly) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              final newSteps = List<WorkflowStep>.from(_data.steps)
                ..add(WorkflowStep(title: l10n.noteWorkflowNewStep));
              _update(_data.copyWith(steps: newSteps));
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.09),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded,
                  size: 16, color: Color(0xFF6C63FF)),
            ),
          ),
        ],
      ]),
    );
  }

  // ── Progress bar ────────────────────────────────────────────────────────────

  Widget _buildProgress(AppLocalizations l10n) {
    final pct = (_progress * 100).round();
    final barColor = _progress == 1.0
        ? const Color(0xFF10B981)
        : const Color(0xFF6C63FF);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _progress == 1.0
                    ? l10n.noteWorkflowCompletedCelebration
                    : l10n.booksProgressTitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _progress == 1.0
                      ? const Color(0xFF10B981)
                      : const Color(0xFF1A1A1A).withOpacity(0.45),
                ),
              ),
              Text(
                '%$pct',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE9ECF0),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Single step ─────────────────────────────────────────────────────────────

  Widget _buildStep(int i) {
    final step = _data.steps[i];
    final isLast = i == _data.steps.length - 1;
    final color = step.status.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Timeline column ──────────────────────────────────────────
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  const SizedBox(height: 11),
                  // Status dot — tappable in edit mode
                  GestureDetector(
                    onTap: widget.readOnly
                        ? null
                        : () {
                            final newSteps =
                                List<WorkflowStep>.from(_data.steps);
                            newSteps[i] =
                                step.copyWith(status: step.status.next);
                            _update(_data.copyWith(steps: newSteps));
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.status == WorkflowStatus.done
                            ? color
                            : Colors.white,
                        border: Border.all(color: color, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.25),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        step.status.icon,
                        size: 13,
                        color: step.status == WorkflowStatus.done
                            ? Colors.white
                            : color,
                      ),
                    ),
                  ),
                  // Connector line
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E9EF),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  if (isLast) const SizedBox(height: 10),
                ],
              ),
            ),

            // ── Step content ──────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: isLast ? 0 : 12,
                  right: 4,
                ),
                child: widget.readOnly
                    ? _StepReadOnly(step: step)
                    : _StepEditable(
                        step: step,
                        onTitleChanged: (v) {
                          final newSteps =
                              List<WorkflowStep>.from(_data.steps);
                          newSteps[i] = step.copyWith(title: v);
                          _update(_data.copyWith(steps: newSteps));
                        },
                        onDelete: () {
                          final newSteps =
                              List<WorkflowStep>.from(_data.steps)
                                ..removeAt(i);
                          _update(_data.copyWith(steps: newSteps));
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── Step sub-widgets ────────────────────────────────────────

class _StepReadOnly extends StatelessWidget {
  final WorkflowStep step;
  const _StepReadOnly({required this.step});

  @override
  Widget build(BuildContext context) {
    final isDone = step.status == WorkflowStatus.done;
    return Row(children: [
      Expanded(
        child: Text(
          step.title,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: isDone
                ? const Color(0xFF1A1A1A).withOpacity(0.38)
                : const Color(0xFF1A1A1A).withOpacity(0.88),
            decoration: isDone ? TextDecoration.lineThrough : null,
            decorationColor:
                const Color(0xFF1A1A1A).withOpacity(0.38),
          ),
        ),
      ),
      _StatusBadge(status: step.status),
    ]);
  }
}

class _StepEditable extends StatefulWidget {
  final WorkflowStep step;
  final ValueChanged<String> onTitleChanged;
  final VoidCallback onDelete;

  const _StepEditable({
    required this.step,
    required this.onTitleChanged,
    required this.onDelete,
  });

  @override
  State<_StepEditable> createState() => _StepEditableState();
}

class _StepEditableState extends State<_StepEditable> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.step.title);
  }

  @override
  void didUpdateWidget(covariant _StepEditable old) {
    super.didUpdateWidget(old);
    if (old.step.title != widget.step.title &&
        _ctrl.text != widget.step.title) {
      _ctrl.text = widget.step.title;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.step.status == WorkflowStatus.done;
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _ctrl,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: isDone
                ? const Color(0xFF1A1A1A).withOpacity(0.38)
                : const Color(0xFF1A1A1A).withOpacity(0.88),
            decoration: isDone ? TextDecoration.lineThrough : null,
            decorationColor:
                const Color(0xFF1A1A1A).withOpacity(0.38),
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: widget.onTitleChanged,
        ),
      ),
      _StatusBadge(status: widget.step.status),
      const SizedBox(width: 4),
      GestureDetector(
        onTap: widget.onDelete,
        child: Icon(
          Icons.close_rounded,
          size: 14,
          color: const Color(0xFF1A1A1A).withOpacity(0.25),
        ),
      ),
    ]);
  }
}

class _StatusBadge extends StatelessWidget {
  final WorkflowStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = status.color;
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        status.label(l10n),
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
