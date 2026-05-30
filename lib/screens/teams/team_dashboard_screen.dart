import 'package:flutter/material.dart';

import '../../models/team_model.dart';
import '../../l10n/app_localizations.dart';
import '../../core/phobes_theme.dart';
import '../../widgets/phobes_widgets.dart';
import 'team_dashboard_tab.dart';

class TeamDashboardScreen extends StatelessWidget {
  final Team team;
  const TeamDashboardScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: PhobesTheme.backgroundColor,
      appBar: PhobesPremiumAppBar(title: l10n.tabDashboard),
      body: TeamDashboardTab(team: team),
    );
  }
}
