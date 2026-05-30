import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/budget_model.dart';
import '../../../services/budget_service.dart';
import '../../../widgets/phobes_widgets.dart';
import '../../../utils/budget_currency_utils.dart';
import '../../../l10n/app_localizations.dart';

class BudgetAccountsTab extends StatefulWidget {
  final BudgetService budgetService;
  final ColorScheme cs;
  final Function(String) onAccountTap;

  const BudgetAccountsTab({
    super.key,
    required this.budgetService,
    required this.cs,
    required this.onAccountTap,
  });

  @override
  State<BudgetAccountsTab> createState() => _BudgetAccountsTabState();
}

class _BudgetAccountsTabState extends State<BudgetAccountsTab> {
  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.money_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      case AccountType.investment:
        return Icons.trending_up_rounded;
    }
  }

  List<Color> _getAccountGradient(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return [const Color(0xFF11998E), const Color(0xFF38EF7D)];
      case AccountType.bank:
        return [const Color(0xFF667EEA), const Color(0xFF764BA2)];
      case AccountType.creditCard:
        return [const Color(0xFFFF6B6B), const Color(0xFFEE5A24)];
      case AccountType.investment:
        return [const Color(0xFFF7971E), const Color(0xFFFFD200)];
    }
  }

  String _getAccountTypeLabel(AppLocalizations l10n, AccountType type) {
    switch (type) {
      case AccountType.cash:
        return l10n.budgetMethodCash.toUpperCase();
      case AccountType.bank:
        return l10n.tabAccounts.toUpperCase();
      case AccountType.creditCard:
        return l10n.budgetMethodCreditCard.toUpperCase();
      case AccountType.investment:
        return l10n.totalAssets.toUpperCase();
    }
  }

  Widget _buildCurrencySelector(
      StateSetter setModalState, String current, Function(String) onSelect) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.budgetCurrency,
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6))),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: kSupportedCurrencies.map((code) {
              final isSelected = current == code;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${getCurrencySymbol(code)} $code',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  selected: isSelected,
                  onSelected: (_) => setModalState(() => onSelect(code)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showAddAccountSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    AccountType selectedType = AccountType.cash;
    String selectedCurrency = widget.budgetService.baseCurrency.value;

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => PhobesBottomSheet(
          title: l10n.createAccount,
          child: Column(
            children: [
              PhobesTextField(
                controller: nameController,
                hintText: l10n.tabAccounts,
                prefixIcon: Icons.edit_rounded,
              ),
              const SizedBox(height: 12),
              PhobesTextField(
                controller: balanceController,
                hintText: l10n.budgetLimitAmountHint(
                    getCurrencySymbol(selectedCurrency)),
                prefixIcon: Icons.account_balance_wallet_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildCurrencySelector(
                  setModalState, selectedCurrency, (val) => selectedCurrency = val),
              const SizedBox(height: 16),
              // Account type selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.tabAccounts,
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6))),
                  const SizedBox(height: 10),
                  Row(
                    children: AccountType.values.map((type) {
                      final isSelected = selectedType == type;
                      final grad = _getAccountGradient(type);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedType = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 4),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(colors: grad)
                                  : null,
                              color: isSelected
                                  ? null
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _getAccountIcon(type),
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                  size: 22,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _getAccountTypeLabel(l10n, type),
                                  style: GoogleFonts.outfit(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.5),
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PhobesButton(
                text: l10n.createAccount,
                width: double.infinity,
                onPressed: () async {
                  if (nameController.text.isEmpty) return;
                  final account = Account(
                    userId: widget.budgetService.currentUserId!,
                    name: nameController.text,
                    type: selectedType,
                    balance: double.tryParse(balanceController.text) ?? 0.0,
                    currency: selectedCurrency,
                  );
                  await widget.budgetService.addAccount(account);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      nameController.dispose();
      balanceController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => CustomScrollView(
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          // Total balance header
          SliverToBoxAdapter(
            child: StreamBuilder<List<Account>>(
              stream: widget.budgetService.getAccountsStream(),
              builder: (context, snapshot) {
                final l10n = AppLocalizations.of(context)!;
                final accounts = snapshot.data ?? [];
                final totalBalance =
                    accounts.fold(0.0, (s, a) => s + a.balance);
                final baseCcy = widget.budgetService.baseCurrency.value;

                // Per-type breakdown
                final cashTotal = accounts
                    .where((a) => a.type == AccountType.cash)
                    .fold(0.0, (s, a) => s + a.balance);
                final bankTotal = accounts
                    .where((a) => a.type == AccountType.bank)
                    .fold(0.0, (s, a) => s + a.balance);
                final investTotal = accounts
                    .where((a) => a.type == AccountType.investment)
                    .fold(0.0, (s, a) => s + a.balance);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.netWorth,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: widget.cs.onSurface.withOpacity(0.5),
                                    fontWeight: FontWeight.w500,
                                  )),
                              const SizedBox(height: 4),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: totalBalance),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) => Text(
                                  formatCurrency(v, baseCcy),
                                  style: GoogleFonts.outfit(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: totalBalance >= 0
                                        ? widget.cs.onSurface
                                        : Colors.redAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${accounts.length} ${l10n.tabAccounts.toLowerCase()}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: widget.cs.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                          PhobesIconButton(
                            icon: Icons.add_card_rounded,
                            onTap: () => _showAddAccountSheet(context),
                            backgroundColor: widget.cs.primary,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      if (accounts.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (cashTotal != 0)
                                _buildTypeSummaryChip(
                                    l10n.budgetMethodCash,
                                    cashTotal,
                                    const Color(0xFF11998E),
                                    baseCcy),
                              if (bankTotal != 0) ...[
                                const SizedBox(width: 8),
                                _buildTypeSummaryChip(
                                    l10n.tabAccounts,
                                    bankTotal,
                                    const Color(0xFF667EEA),
                                    baseCcy),
                              ],
                              if (investTotal != 0) ...[
                                const SizedBox(width: 8),
                                _buildTypeSummaryChip(
                                    l10n.totalAssets,
                                    investTotal,
                                    const Color(0xFFF7971E), baseCcy),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
          // Account cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: StreamBuilder<List<Account>>(
              stream: widget.budgetService.getAccountsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()));
                }
                final accounts = snapshot.data ?? [];
                if (accounts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildAddAccountCard(context),
                  );
                }

                return SliverLayoutBuilder(
                  builder: (context, sliverConstraints) {
                    final width = sliverConstraints.crossAxisExtent;
                    final crossAxisCount = width >= 1500
                        ? 4
                        : width >= 1100
                            ? 3
                            : width >= 700
                                ? 2
                                : 1;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 175,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildBankCard(context, accounts[index]),
                        childCount: accounts.length,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildTypeSummaryChip(
      String label, double amount, Color color, String? ccy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            '$label: ${formatCurrency(amount, ccy)}',
            style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard(BuildContext context, Account account) {
    final gradient = _getAccountGradient(account.type);
    final l10n = AppLocalizations.of(context)!;
    final typeLabel = _getAccountTypeLabel(l10n, account.type);
    final icon = _getAccountIcon(account.type);

    return GestureDetector(
      onTap: account.id != null ? () => widget.onAccountTap(account.id!) : null,
      child: Container(
        height: 175,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.38),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background circles
            Positioned(
              top: -25,
              right: -20,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              right: 50,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
                      ),
                      Text(
                        typeLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.65),
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    account.name,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.88),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: account.balance),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text(
                      formatCurrency(v, account.currency),
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Card chip dots bottom right
            Positioned(
              bottom: 22,
              right: 22,
              child: Row(
                children: List.generate(
                  4,
                  (i) => Container(
                    margin: const EdgeInsets.only(left: 5),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i < 3
                          ? Colors.white.withOpacity(0.28)
                          : Colors.white.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAccountCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddAccountSheet(context),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.cs.primary.withOpacity(0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(24),
          color: widget.cs.primary.withOpacity(0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.cs.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded,
                  color: widget.cs.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.createAccount,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: widget.cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
