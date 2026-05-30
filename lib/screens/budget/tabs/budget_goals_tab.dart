import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../models/budget_model.dart';
import '../../../services/budget_service.dart';
import '../../../widgets/phobes_widgets.dart';
import '../../../utils/budget_currency_utils.dart';
import '../../../l10n/app_localizations.dart';

class BudgetGoalsTab extends StatefulWidget {
  final BudgetService budgetService;
  final ColorScheme cs;

  const BudgetGoalsTab({
    super.key,
    required this.budgetService,
    required this.cs,
  });

  @override
  State<BudgetGoalsTab> createState() => _BudgetGoalsTabState();
}

class _BudgetGoalsTabState extends State<BudgetGoalsTab> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<SavingsGoal>>(
      stream: widget.budgetService.getGoalsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text(l10n.budgetErrorWithDetail(snapshot.error.toString()),
                  style: GoogleFonts.outfit(color: Colors.red)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final goals = snapshot.data!;

        return Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              return CustomScrollView(
                slivers: [
                  SliverOverlapInjector(
                    handle:
                        NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  ),
                  // Summary header
                  if (goals.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: _buildSummaryHeader(goals),
                      ),
                    ),
                  // Title row
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                  width: 4,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: widget.cs.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  )),
                              const SizedBox(width: 10),
                              Text(l10n.featFinancialGoals,
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ],
                          ),
                          PhobesIconButton(
                            icon: Icons.add_rounded,
                            onTap: () => _showAddGoalSheet(context),
                            backgroundColor: widget.cs.primary,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (goals.isEmpty)
                    SliverFillRemaining(
                      child: PhobesEmptyState(
                        icon: Icons.savings_rounded,
                        title: l10n.noGoalsYet,
                        description: l10n.noGoalsYetDesc,
                        buttonText: l10n.addGoal,
                        buttonIcon: Icons.add_rounded,
                        onButtonTap: () => _showAddGoalSheet(context),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      sliver: isWide
                          ? SliverLayoutBuilder(
                              builder: (context, sliverConstraints) {
                                final width = sliverConstraints.crossAxisExtent;
                                final crossAxisCount = width >= 1500
                                    ? 4
                                    : width >= 1100
                                        ? 3
                                        : 2;
                                return SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 12,
                                    mainAxisExtent: 150,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) =>
                                        _buildGoalCard(widget.cs, goals[index]),
                                    childCount: goals.length,
                                  ),
                                );
                              },
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _buildGoalCard(
                                      widget.cs, goals[index]),
                                ),
                                childCount: goals.length,
                              ),
                            ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSummaryHeader(List<SavingsGoal> goals) {
    final l10n = AppLocalizations.of(context)!;
    final totalTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
    final totalCurrent = goals.fold(0.0, (s, g) => s + g.currentAmount);
    final completedGoals =
        goals.where((g) => g.currentAmount >= g.targetAmount).length;
    final baseCcy = widget.budgetService.baseCurrency.value;
    final overallPct =
        totalTarget > 0 ? (totalCurrent / totalTarget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.cs.primary.withOpacity(0.15),
            widget.cs.primary.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: widget.cs.primary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          // Overall circular progress
          CircularPercentIndicator(
            radius: 38.0,
            lineWidth: 7.0,
            percent: overallPct,
            center: Text(
              '${(overallPct * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: widget.cs.primary,
              ),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: widget.cs.outline.withOpacity(0.1),
            progressColor: widget.cs.primary,
            animation: true,
            animationDuration: 900,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatCurrency(totalCurrent, baseCcy),
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${formatCurrency(totalTarget, baseCcy)} ${l10n.aiFieldGoal}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: widget.cs.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSummaryChip(
                      '$completedGoals ${l10n.completed}',
                      Colors.green,
                      Icons.check_circle_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildSummaryChip(
                      '${goals.length - completedGoals} ${l10n.pending}',
                      widget.cs.primary,
                      Icons.pending_rounded,
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

  Widget _buildSummaryChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
                fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(ColorScheme cs, SavingsGoal goal) {
    final l10n = AppLocalizations.of(context)!;
    final percent =
        (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final isComplete = percent >= 1.0;
    final baseCcy = widget.budgetService.baseCurrency.value;

    String? deadlineLabel;
    Color deadlineColor = cs.onSurface.withOpacity(0.4);
    if (goal.deadline != null) {
      final daysLeft = goal.deadline!.difference(DateTime.now()).inDays;
      if (daysLeft < 0) {
        deadlineLabel = l10n.projectStatOverdue;
        deadlineColor = Colors.red;
      } else if (daysLeft == 0) {
        deadlineLabel = l10n.teamLastDayToday;
        deadlineColor = Colors.orange;
      } else if (daysLeft <= 7) {
        deadlineLabel = l10n.teamDaysLeft(daysLeft);
        deadlineColor = Colors.orange;
      } else {
        deadlineLabel = l10n.teamDaysLeft(daysLeft);
        deadlineColor = cs.onSurface.withOpacity(0.4);
      }
    }

    final progressColor = isComplete ? Colors.green : cs.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isComplete
              ? Colors.green.withOpacity(0.3)
              : cs.outline.withOpacity(0.07),
        ),
        boxShadow: isComplete
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular progress
          CircularPercentIndicator(
            radius: 40.0,
            lineWidth: 7.0,
            percent: percent,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: progressColor,
                  ),
                ),
                if (isComplete)
                  const Icon(Icons.check_rounded,
                      size: 10, color: Colors.green),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: cs.outline.withOpacity(0.1),
            progressColor: progressColor,
            animation: true,
            animationDuration: 800,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isComplete)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(l10n.completed,
                            style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ),
                    Expanded(
                      child: Text(goal.title,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    PhobesIconButton(
                      icon: Icons.edit_rounded,
                      onTap: () => _showUpdateGoalAmount(context, goal),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: goal.currentAmount),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    formatCurrency(v, baseCcy),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ),
                Text(
                  '${l10n.aiFieldGoal}: ${formatCurrency(goal.targetAmount, baseCcy)}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.45),
                  ),
                ),
                if (deadlineLabel != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: deadlineColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 11, color: deadlineColor),
                        const SizedBox(width: 4),
                        Text(
                          deadlineLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: deadlineColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final targetController = TextEditingController();

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: l10n.addGoal,
        child: Column(
          children: [
            PhobesTextField(
              controller: titleController,
              hintText: l10n.defaultGoal,
              prefixIcon: Icons.flag_rounded,
            ),
            const SizedBox(height: 12),
            PhobesTextField(
              controller: targetController,
              hintText:
                  'Hedef Tutar (${getCurrencySymbol(widget.budgetService.baseCurrency.value)})',
              prefixIcon: Icons.money_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            PhobesButton(
              text: l10n.booksCreateGoal,
              width: double.infinity,
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    targetController.text.isEmpty) {
                  return;
                }
                final targetAmount = double.tryParse(targetController.text);
                if (targetAmount == null || targetAmount <= 0) { return; }
                final goal = SavingsGoal(
                  userId: widget.budgetService.currentUserId!,
                  title: titleController.text,
                  targetAmount: targetAmount,
                );
                await widget.budgetService.addGoal(goal);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  PhobesSnackbar.show(
                      context, message: l10n.accountCreatedSuccess);
                }
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      titleController.dispose();
      targetController.dispose();
    });
  }

  void _showUpdateGoalAmount(BuildContext context, SavingsGoal goal) {
    final amountController =
        TextEditingController(text: goal.currentAmount.toStringAsFixed(0));
    final l10n = AppLocalizations.of(context)!;
    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: l10n.editTransaction,
        child: Column(
          children: [
            PhobesTextField(
              controller: amountController,
              hintText:
                  'Mevcut Para (${getCurrencySymbol(widget.budgetService.baseCurrency.value)})',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PhobesButton(
                    text: l10n.delete,
                    isOutlined: true,
                    onPressed: () async {
                      final confirmed = await PhobesBottomSheet.confirm(
                        context: context,
                        title: l10n.budgetDeleteGoalTitle,
                        message: l10n.budgetDeleteGoalMessage(goal.title),
                      );
                      if (confirmed == true) {
                        await widget.budgetService.deleteGoal(goal.id!);
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PhobesButton(
                    text: l10n.update,
                    onPressed: () async {
                      final amount =
                          double.tryParse(amountController.text) ?? 0;
                      await widget.budgetService
                          .updateGoal(goal.copyWith(currentAmount: amount));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(() => amountController.dispose());
  }
}
