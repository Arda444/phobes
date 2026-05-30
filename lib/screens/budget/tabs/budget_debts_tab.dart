import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/budget_model.dart';
import '../../../services/budget_service.dart';
import '../../../widgets/phobes_widgets.dart';
import '../../../utils/budget_currency_utils.dart';
import '../../../l10n/app_localizations.dart';

class BudgetDebtsTab extends StatefulWidget {
  final BudgetService budgetService;
  final ColorScheme cs;

  const BudgetDebtsTab({
    super.key,
    required this.budgetService,
    required this.cs,
  });

  @override
  State<BudgetDebtsTab> createState() => _BudgetDebtsTabState();
}

class _BudgetDebtsTabState extends State<BudgetDebtsTab> {
  DebtType? _activeSection;
  late final Stream<List<Debt>> _debtsStream;

  @override
  void initState() {
    super.initState();
    _debtsStream = widget.budgetService.getDebtsStream().asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
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
              StreamBuilder<List<Debt>>(
                stream: _debtsStream,
                builder: (context, snapshot) {
                  final l10n = AppLocalizations.of(context)!;
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                          child: Text(l10n.budgetErrorWithDetail(
                              snapshot.error.toString()))),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()));
                  }

                  final allDebts = snapshot.data!;
                  // DebtType.debt = "sana borcu var" (alacak), DebtType.credit = "borcun var"
                  final receivables =
                      allDebts.where((d) => d.type == DebtType.debt).toList();
                  final payables =
                      allDebts.where((d) => d.type == DebtType.credit).toList();

                  final totalReceivable = receivables.fold(
                      0.0, (s, d) => s + (d.isPaid ? 0 : d.amount));
                  final totalPayable = payables.fold(
                      0.0, (s, d) => s + (d.isPaid ? 0 : d.amount));

                  final visibleDebts = _activeSection == null
                      ? allDebts
                      : allDebts
                          .where((d) => d.type == _activeSection)
                          .toList();

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      // Summary header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: _buildSummaryHeader(
                          receivables: receivables,
                          payables: payables,
                          totalReceivable: totalReceivable,
                          totalPayable: totalPayable,
                          baseCcy: widget.budgetService.baseCurrency.value,
                        ),
                      ),
                      // Section toggle + add button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSectionToggle(
                                label: l10n.categoryIncomes,
                                count: receivables.length,
                                color: Colors.green,
                                isActive: _activeSection == DebtType.debt,
                                onTap: () => setState(() => _activeSection =
                                    _activeSection == DebtType.debt
                                        ? null
                                        : DebtType.debt),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildSectionToggle(
                                label: l10n.tabDebts,
                                count: payables.length,
                                color: Colors.red,
                                isActive: _activeSection == DebtType.credit,
                                onTap: () => setState(() => _activeSection =
                                    _activeSection == DebtType.credit
                                        ? null
                                        : DebtType.credit),
                              ),
                            ),
                            const SizedBox(width: 10),
                            PhobesIconButton(
                              icon: Icons.add_rounded,
                              onTap: () => _showAddDebtSheet(context),
                              backgroundColor: widget.cs.primary,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (allDebts.isEmpty)
                        _buildEmptyState(context)
                      else if (visibleDebts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text(
                              l10n.noDebtsYet,
                              style: GoogleFonts.outfit(
                                  color: widget.cs.onSurface.withOpacity(0.4),
                                  fontSize: 14),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: isWide
                              ? _buildWideGrid(visibleDebts)
                              : _buildNarrowList(visibleDebts),
                        ),
                      const SizedBox(height: 80),
                    ]),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader({
    required List<Debt> receivables,
    required List<Debt> payables,
    required double totalReceivable,
    required double totalPayable,
    required String? baseCcy,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final netBalance = totalReceivable - totalPayable;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.cs.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: widget.cs.outline.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryStatCard(
                  label: l10n.categoryIncomes,
                  amount: totalReceivable,
                  color: Colors.green,
                  icon: Icons.arrow_downward_rounded,
                  count: receivables.where((d) => !d.isPaid).length,
                  baseCcy: baseCcy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryStatCard(
                  label: l10n.tabDebts,
                  amount: totalPayable,
                  color: Colors.red,
                  icon: Icons.arrow_upward_rounded,
                  count: payables.where((d) => !d.isPaid).length,
                  baseCcy: baseCcy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: netBalance >= 0
                  ? Colors.green.withOpacity(0.08)
                  : Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  netBalance >= 0
                      ? Icons.account_balance_rounded
                      : Icons.warning_amber_rounded,
                  size: 16,
                  color: netBalance >= 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  '${l10n.netWorth}: ${formatCurrency(netBalance.abs(), baseCcy)}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: netBalance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStatCard({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    required int count,
    required String? baseCcy,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: widget.cs.onSurface.withOpacity(0.55),
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(amount, baseCcy),
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            '$count bekliyor',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: widget.cs.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionToggle({
    required String label,
    required int count,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color.withOpacity(0.5) : color.withOpacity(0.15),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              color == Colors.green
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 14,
              color: isActive ? color : color.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? color : color.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PhobesEmptyState(
      icon: Icons.handshake_rounded,
      title: l10n.noDebtsYet,
      description: l10n.noDebtsYetDesc,
      buttonText: l10n.addDebt,
      buttonIcon: Icons.add_rounded,
      onButtonTap: () => _showAddDebtSheet(context),
    );
  }

  Widget _buildWideGrid(List<Debt> debts) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1500
            ? 4
            : width >= 1100
                ? 3
                : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 10,
            mainAxisExtent: 80,
          ),
          itemCount: debts.length,
          itemBuilder: (context, index) =>
              _buildDebtCard(widget.cs, debts[index]),
        );
      },
    );
  }

  Widget _buildNarrowList(List<Debt> debts) {
    return Column(
      children: debts
          .map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildDebtCard(widget.cs, d),
              ))
          .toList(),
    );
  }

  Widget _buildDebtCard(ColorScheme cs, Debt debt) {
    final l10n = AppLocalizations.of(context)!;
    final isReceivable = debt.type == DebtType.debt;
    final color = isReceivable ? Colors.green : Colors.red;
    final icon = isReceivable
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final label =
        isReceivable ? l10n.categoryIncomes : l10n.categoryExpenses;

    return GestureDetector(
      onTap: () => _toggleDebtStatus(debt),
      child: Container(
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: debt.isPaid
                ? cs.outline.withOpacity(0.06)
                : color.withOpacity(0.18),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              // Avatar with initials
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: debt.isPaid
                        ? [Colors.grey.shade400, Colors.grey.shade600]
                        : [color.withOpacity(0.7), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: debt.isPaid
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : Text(
                          debt.personName.isNotEmpty
                              ? debt.personName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      debt.personName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: debt.isPaid
                            ? cs.onSurface.withOpacity(0.4)
                            : cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(icon,
                            size: 11,
                            color: debt.isPaid
                                ? cs.onSurface.withOpacity(0.3)
                                : color),
                        const SizedBox(width: 3),
                        Text(
                          isReceivable
                              ? l10n.noDebtsYetDesc
                              : l10n.tabDebts,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: debt.isPaid
                                ? cs.onSurface.withOpacity(0.3)
                                : cs.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatCurrency(
                        debt.amount, widget.budgetService.baseCurrency.value),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color:
                          debt.isPaid ? cs.onSurface.withOpacity(0.3) : color,
                    ),
                  ),
                  if (debt.isPaid)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(l10n.statusCompleted.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          )),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(label,
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            color: color,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleDebtStatus(Debt debt) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await PhobesBottomSheet.confirm(
      context: context,
      title: debt.isPaid ? l10n.pending : l10n.statusCompleted,
      message: debt.personName,
      confirmText: l10n.save,
      cancelText: l10n.cancel,
    );
    if (confirmed == true) {
      await widget.budgetService
          .updateDebt(debt.copyWith(isPaid: !debt.isPaid));
    }
  }

  void _showAddDebtSheet(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DebtType selectedType = DebtType.debt;
    final l10n = AppLocalizations.of(context)!;

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => PhobesBottomSheet(
          title: l10n.addDebt,
          child: Column(
            children: [
              // Type toggle buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setModalState(() => selectedType = DebtType.debt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selectedType == DebtType.debt
                              ? Colors.green.withOpacity(0.15)
                              : Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedType == DebtType.debt
                                ? Colors.green.withOpacity(0.5)
                                : Colors.green.withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.arrow_downward_rounded,
                                color: Colors.green, size: 20),
                            const SizedBox(height: 4),
                            Text(l10n.categoryIncomes,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setModalState(() => selectedType = DebtType.credit),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selectedType == DebtType.credit
                              ? Colors.red.withOpacity(0.15)
                              : Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedType == DebtType.credit
                                ? Colors.red.withOpacity(0.5)
                                : Colors.red.withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.arrow_upward_rounded,
                                color: Colors.red, size: 20),
                            const SizedBox(height: 4),
                            Text(l10n.tabDebts,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PhobesTextField(
                controller: nameController,
                hintText: l10n.teamMemberDefaultName,
                prefixIcon: Icons.person_rounded,
              ),
              const SizedBox(height: 12),
              PhobesTextField(
                controller: amountController,
                hintText: l10n.budgetLimitAmountHint(
                    getCurrencySymbol(widget.budgetService.baseCurrency.value)),
                prefixIcon: Icons.money_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              PhobesButton(
                text: l10n.save,
                width: double.infinity,
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      amountController.text.isEmpty) {
                    return;
                  }
                  final debtAmount = double.tryParse(amountController.text);
                  if (debtAmount == null || debtAmount <= 0) return;
                  final debt = Debt(
                    userId: widget.budgetService.currentUserId!,
                    personName: nameController.text,
                    amount: debtAmount,
                    type: selectedType,
                    date: DateTime.now(),
                  );
                  await widget.budgetService.addDebt(debt);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      nameController.dispose();
      amountController.dispose();
    });
  }
}
