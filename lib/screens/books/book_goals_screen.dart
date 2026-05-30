import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../widgets/phobes_widgets.dart';
import 'package:phobes/l10n/app_localizations.dart';

class BookGoalsScreen extends StatefulWidget {
  const BookGoalsScreen({super.key});

  @override
  State<BookGoalsScreen> createState() => _BookGoalsScreenState();
}

class _BookGoalsScreenState extends State<BookGoalsScreen> {
  final BookService _bookService = BookService();
  late final Stream<List<ReadingGoal>> _goalsStream;

  @override
  void initState() {
    super.initState();
    _goalsStream = _bookService.getGoalsStream().asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: UnconstrainedBox(
          child: PhobesIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          l10n.booksGoalsTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        actions: [
          PhobesIconButton(
            icon: Icons.add_rounded,
            backgroundColor: cs.primary,
            color: Colors.white,
            onTap: () => _showAddGoalSheet(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<ReadingGoal>>(
        stream: _goalsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return Center(child: PhobesLoadingIndicator(color: cs.primary));
          }
          final goals = snapshot.data ?? [];
          if (goals.isEmpty) {
            return _buildEmpty(cs, l10n);
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 1500
                  ? 4
                  : w >= 1100
                      ? 3
                      : w >= 700
                          ? 2
                          : 1;
              if (cols == 1) {
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  itemCount: goals.length,
                  itemBuilder: (context, i) => FadeInUp(
                    delay: Duration(milliseconds: i * 50),
                    child: _GoalCard(
                      goal: goals[i],
                      bookService: _bookService,
                      onDelete: () => _bookService.deleteGoal(goals[i].id!),
                    ),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 200,
                ),
                itemCount: goals.length,
                itemBuilder: (context, i) => FadeInUp(
                  delay: Duration(milliseconds: i * 50),
                  child: _GoalCard(
                    goal: goals[i],
                    bookService: _bookService,
                    onDelete: () => _bookService.deleteGoal(goals[i].id!),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs, AppLocalizations l10n) {
    return Center(
      child: FadeInUp(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PhobesGlassCard(
                padding: EdgeInsets.all(28),
                borderRadius: 40,
                child: Text('🎯', style: TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: 24),
              Text(l10n.booksGoalsEmptyTitle,
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
              const SizedBox(height: 8),
              Text(
                l10n.booksGoalsEmptyDesc,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: cs.onSurface.withOpacity(0.4)),
              ),
              const SizedBox(height: 24),
              PhobesButton(
                text: l10n.booksAddFirstGoal,
                icon: Icons.flag_rounded,
                onPressed: () => _showAddGoalSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddGoalSheet(bookService: _bookService),
    );
  }
}

// ─── Goal Card ─────────────────────────────────────────────────────────────

class _GoalCard extends StatefulWidget {
  final ReadingGoal goal;
  final BookService bookService;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.bookService,
    required this.onDelete,
  });

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  int _progress = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final p = await widget.bookService.calculateGoalProgress(widget.goal);
    if (mounted) setState(() { _progress = p; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final goal = widget.goal;
    final color = Color(goal.color);
    final unit =
        goal.isPageGoal ? l10n.booksUnitPages : l10n.booksUnitBooks;
    final pct =
        goal.targetValue > 0 ? (_progress / goal.targetValue).clamp(0.0, 1.0) : 0.0;
    final isDone = _progress >= goal.targetValue;

    return PhobesCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(goal.icon, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 15, color: cs.onSurface)),
                    Text(goal.periodLabel,
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: cs.onSurface.withOpacity(0.4))),
                  ],
                ),
              ),
              if (isDone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
                  ),
                  child: Text(l10n.booksGoalCompleted,
                      style: GoogleFonts.outfit(
                          fontSize: 10, color: const Color(0xFF22C55E),
                          fontWeight: FontWeight.w700)),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onDelete,
                child: Icon(Icons.delete_outline_rounded,
                    size: 18, color: cs.onSurface.withOpacity(0.3)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loaded
                    ? l10n.booksGoalProgress(_progress, goal.targetValue, unit)
                    : '...',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 14, color: cs.onSurface),
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _loaded ? pct : null,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.1),
              color: isDone ? const Color(0xFF22C55E) : color,
            ),
          ),
          if (!isDone && goal.targetValue > _progress) ...[
            const SizedBox(height: 8),
            Text(
              l10n.booksGoalRemaining(goal.targetValue - _progress, unit),
              style: GoogleFonts.outfit(
                  fontSize: 11, color: cs.onSurface.withOpacity(0.4)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Add Goal Bottom Sheet ─────────────────────────────────────────────────

class _AddGoalSheet extends StatefulWidget {
  final BookService bookService;
  const _AddGoalSheet({required this.bookService});

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController(text: '12');
  String _type = 'yearly_books';
  String _icon = '🎯';
  int _color = 0xFF6366F1;
  bool _saving = false;

  final now = DateTime.now();

  static const _icons = ['🎯', '📚', '📖', '✨', '🔥', '⭐', '🏆', '💪'];
  static const _colors = [
    0xFF6366F1, 0xFF3B82F6, 0xFF22C55E,
    0xFFF59E0B, 0xFFEF4444, 0xFF8B5CF6,
    0xFF06B6D4, 0xFFEC4899,
  ];

  static List<(String, String, String)> _types(AppLocalizations l10n) => [
    ('yearly_books', l10n.booksGoalTypeYearlyBooks, '📚'),
    ('monthly_books', l10n.booksGoalTypeMonthlyBooks, '📖'),
    ('yearly_pages', l10n.booksGoalTypeYearlyPages, '📄'),
    ('monthly_pages', l10n.booksGoalTypeMonthlyPages, '📑'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  String _defaultTitle(AppLocalizations l10n) {
    final target = int.tryParse(_targetCtrl.text.trim()) ?? 0;
    return switch (_type) {
      'yearly_books' => l10n.booksGoalDefaultYearlyBooks(target),
      'monthly_books' => l10n.booksGoalDefaultMonthlyBooks(target),
      'yearly_pages' => l10n.booksGoalDefaultYearlyPages(target),
      'monthly_pages' => l10n.booksGoalDefaultMonthlyPages(target),
      _ => l10n.booksGoalDefaultFallback,
    };
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    final title = _titleCtrl.text.trim().isEmpty
        ? _defaultTitle(l10n)
        : _titleCtrl.text.trim();
    final target = int.tryParse(_targetCtrl.text.trim()) ?? 0;
    if (target <= 0) return;

    setState(() => _saving = true);
    try {
      final goal = ReadingGoal(
        userId: '',
        title: title,
        type: _type,
        targetValue: target,
        year: now.year,
        month: _type.startsWith('monthly') ? now.month : null,
        icon: _icon,
        color: _color,
        createdAt: DateTime.now(),
      );
      await widget.bookService.addGoal(goal);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        PhobesSnackbar.show(context, message: l10n.booksGoalAddFailed,
            type: PhobesSnackbarType.error);
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTitle = _defaultTitle(l10n);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(l10n.booksNewGoalTitle,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 18, color: cs.onSurface)),
              const SizedBox(height: 20),

              // Type selector
              _SectionLabel(l10n.booksGoalTypeSection, cs),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _types(l10n).map((t) {
                  final sel = _type == t.$1;
                  final color = Color(_color);
                  return GestureDetector(
                    onTap: () => setState(() => _type = t.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? color.withOpacity(0.12) : cs.onSurface.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? color : cs.outline.withOpacity(0.15),
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.$3),
                          const SizedBox(width: 6),
                          Text(t.$2,
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                                  color: sel ? color : cs.onSurface.withOpacity(0.6))),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Target value
              _SectionLabel(l10n.booksGoalTargetSection, cs),
              const SizedBox(height: 8),
              TextField(
                controller: _targetCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: _type.endsWith('books')
                      ? l10n.booksGoalTargetBooksLabel
                      : l10n.booksGoalTargetPagesLabel,
                  hintStyle: GoogleFonts.outfit(color: cs.onSurface.withOpacity(0.3)),
                  suffixText: _type.endsWith('books')
                      ? l10n.booksUnitBooks
                      : l10n.booksUnitPages,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Custom title (optional)
              _SectionLabel(l10n.booksTitleOptionalSection, cs),
              const SizedBox(height: 8),
              TextField(
                controller: _titleCtrl,
                style: GoogleFonts.outfit(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: defaultTitle,
                  hintStyle: GoogleFonts.outfit(color: cs.onSurface.withOpacity(0.3)),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Icon
              _SectionLabel(l10n.booksIconSection, cs),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _icons.map((e) => GestureDetector(
                  onTap: () => setState(() => _icon = e),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _icon == e
                          ? Color(_color).withOpacity(0.15)
                          : cs.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _icon == e
                            ? Color(_color)
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 20))),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),

              // Color
              _SectionLabel(l10n.booksColorSection, cs),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _colors.map((c) => GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == c ? cs.onSurface : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: _color == c
                          ? [BoxShadow(color: Color(c).withOpacity(0.4), blurRadius: 6)]
                          : null,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),

              PhobesButton(
                text: l10n.booksCreateGoal,
                icon: Icons.flag_rounded,
                width: double.infinity,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  const _SectionLabel(this.text, this.cs);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.outfit(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: cs.onSurface.withOpacity(0.45), letterSpacing: 0.6));
  }
}
