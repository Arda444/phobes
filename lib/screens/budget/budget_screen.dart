import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/budget_service.dart';
import '../../models/budget_model.dart';
import '../../core/module_info_catalog.dart';
import '../../core/module_ui_tokens.dart';
import '../../widgets/phobes_module_header.dart';
import '../../utils/budget_currency_utils.dart';
import 'package:phobes/l10n/app_localizations.dart';
import 'tabs/budget_overview_tab.dart';
import 'tabs/budget_goals_tab.dart';
import 'tabs/budget_debts_tab.dart';
import 'tabs/budget_accounts_tab.dart';
import 'tabs/budget_statistics_tab.dart';

class BudgetScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const BudgetScreen({super.key, this.onClose});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BudgetService _budgetService = BudgetService();

  String? _selectedAccountId;
  final _overviewKey = GlobalKey<BudgetOverviewTabState>();
  late final Stream<List<Account>> _accountsStream;

  void _onCurrencyChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _accountsStream = _budgetService.getAccountsStream().asBroadcastStream();
    _budgetService.loadBaseCurrency().then((_) {
      if (mounted) setState(() {});
    });
    _budgetService.baseCurrency.addListener(_onCurrencyChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _budgetService.baseCurrency.removeListener(_onCurrencyChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = ModuleUiTokens.isWideForm(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: isWide ? 0 : 80),
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          PhobesModuleHeader(
              title: l10n.budgetModuleTitle,
              icon: Icons.account_balance_wallet_rounded,
              onClose: widget.onClose ?? () => Navigator.pop(context),
              onAdd: () =>
                  _overviewKey.currentState?.showAddTransactionSheet(context),
              addTooltip: l10n.budgetAddTransactionTooltip,
              info: ModuleInfoCatalog.forBudget(l10n),
              useExtendedHeight: true,
              customContent: _buildNetWorth(cs),
              tabController: _tabController,
              tabs: [
                PhobesModuleTab(l10n.tabOverview, Icons.home_rounded),
                PhobesModuleTab(l10n.tabStatistics, Icons.analytics_rounded),
                PhobesModuleTab(l10n.tabAccounts, Icons.account_balance_wallet_rounded),
                PhobesModuleTab(l10n.tabDebts, Icons.handshake_rounded),
                PhobesModuleTab(l10n.tabGoals, Icons.savings_rounded),
              ],
            ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            BudgetOverviewTab(
              key: _overviewKey,
              budgetService: _budgetService,
              selectedAccountId: _selectedAccountId,
              onAccountClear: () => setState(() => _selectedAccountId = null),
            ),
            BudgetStatisticsTab(budgetService: _budgetService, cs: cs),
            BudgetAccountsTab(
              budgetService: _budgetService,
              cs: cs,
              onAccountTap: (accountId) {
                setState(() {
                  _selectedAccountId = accountId;
                  _tabController.animateTo(0);
                });
              },
            ),
            BudgetDebtsTab(budgetService: _budgetService, cs: cs),
            BudgetGoalsTab(budgetService: _budgetService, cs: cs),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorth(ColorScheme cs) {
    return StreamBuilder<List<Account>>(
      stream: _accountsStream,
      builder: (context, snap) {
        final l10n = AppLocalizations.of(context)!;
        final accounts = snap.data ?? [];
        final netWorth = accounts.fold(0.0, (s, a) => s + a.balance);
        final baseCcy = _budgetService.baseCurrency.value;

        return Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.netWorth,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: netWorth),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    formatCurrency(v, baseCcy),
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: netWorth >= 0 ? cs.onSurface : Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
