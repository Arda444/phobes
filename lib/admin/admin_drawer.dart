import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/phobes_theme.dart';
import '../l10n/app_localizations.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isSidebar;

  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isSidebar = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final l10n = AppLocalizations.of(context)!;

    final menuItems = <_AdminMenuItem>[
      _AdminMenuItem(Icons.dashboard_rounded, l10n.adminDashboard),
      _AdminMenuItem(Icons.people_alt_rounded, l10n.adminUsers),
      _AdminMenuItem(Icons.group_work_rounded, l10n.adminEngagement),
      _AdminMenuItem(Icons.memory_rounded, l10n.adminSystemSettings),
    ];

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.15) : Colors.white.withOpacity(0.2),
        border: Border(
          right: BorderSide(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, cs, isDark),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Divider(color: Colors.white12),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final isSelected = index == selectedIndex;
                  return _buildMenuItem(
                    context, item, isSelected, index, cs, isDark,
                  );
                },
              ),
            ),
            _buildFooter(context, cs, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: PhobesTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phobes',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    letterSpacing: -0.6,
                  ),
                ),
                Text(
                  l10n.adminConsole,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    _AdminMenuItem item,
    bool isSelected,
    int index,
    ColorScheme cs,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isSelected ? PhobesTheme.primaryGradient : null,
          boxShadow: isSelected ? [
            BoxShadow(
              color: cs.primary.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onItemSelected(index),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: isSelected ? Colors.white : cs.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.label,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme cs, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.error.withOpacity(0.12)),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded, color: cs.error, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.adminExitPanel,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: cs.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminMenuItem {
  final IconData icon;
  final String label;
  const _AdminMenuItem(this.icon, this.label);
}
