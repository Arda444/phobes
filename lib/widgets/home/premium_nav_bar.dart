import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/phobes_theme.dart';
import '../../core/module_l10n.dart';
import '../../l10n/app_localizations.dart';
import '../../services/module_settings_service.dart';
import '../phobes_widgets.dart';

/// The glassmorphic bottom navigation bar shown on mobile.
class PremiumNavBar extends StatelessWidget {
  final int selectedIndex;
  final bool isMenuOpen;
  final String displayLifeTitle;
  final void Function(int) onItemTapped;

  const PremiumNavBar({
    super.key,
    required this.selectedIndex,
    required this.isMenuOpen,
    required this.displayLifeTitle,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: isAmoled && isDark
                  ? Colors.black.withOpacity(0.8)
                  : cs.surfaceVariant.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.outline.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: ModuleSettingsService.instance.customNavButton,
              builder: (context, customNavButton, _) {
                final (navIcon, activeNavIcon, navLabel) =
                    _resolveCustomNav(customNavButton, l10n);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.calendar_today_rounded,
                      activeIcon: Icons.calendar_month_rounded,
                      label: l10n.navCalendar,
                      index: 0,
                      selectedIndex: selectedIndex,
                      onTap: onItemTapped,
                    ),
                    _NavItem(
                      icon: navIcon,
                      activeIcon: activeNavIcon,
                      label: navLabel,
                      index: 1,
                      selectedIndex: selectedIndex,
                      onTap: onItemTapped,
                    ),
                    _NovaButton(
                        selectedIndex: selectedIndex, onTap: onItemTapped,),
                    _NavItem(
                      icon: isMenuOpen
                          ? Icons.close_rounded
                          : Icons.bento_rounded,
                      activeIcon: Icons.bento_rounded,
                      label: displayLifeTitle,
                      index: 3,
                      selectedIndex: selectedIndex,
                      onTap: onItemTapped,
                    ),
                    _NavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: l10n.navAccount,
                      index: 4,
                      selectedIndex: selectedIndex,
                      onTap: onItemTapped,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static (IconData, IconData, String) _resolveCustomNav(
      String key, AppLocalizations l10n,) {
    return switch (key) {
      'budget' => (
          Icons.account_balance_wallet_outlined,
          Icons.account_balance_wallet_rounded,
          l10n.navBudget,
        ),
      'habit' => (Icons.spa_outlined, Icons.spa_rounded, l10n.navHabits),
      'notes' => (Icons.note_alt_outlined, Icons.note_alt_rounded, l10n.navNotes),
      'appointments' => (
          Icons.event_available_outlined,
          Icons.event_available_rounded,
          l10n.navAppointments,
        ),
      'medications' => (
          Icons.medication_liquid_sharp,
          Icons.medication_rounded,
          l10n.navMedications,
        ),
      'focus' => (
          Icons.timelapse_outlined,
          Icons.timelapse_rounded,
          l10n.navFocus,
        ),
      'upcoming' => (
          Icons.upcoming_outlined,
          Icons.upcoming_rounded,
          l10n.navUpcomingEvents,
        ),
      'statistics' => (
          Icons.insights_outlined,
          Icons.insights_rounded,
          l10n.navStatistics,
        ),
      'corkboard' => (
          Icons.dashboard_customize_outlined,
          Icons.dashboard_customize_rounded,
          l10n.navCorkboard,
        ),
      'books' => (
          Icons.menu_book_outlined,
          Icons.menu_book_rounded,
          l10n.navBooks,
        ),
      _ => (Icons.groups_2_outlined, Icons.groups_2_rounded, l10n.navTeams),
    };
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: PhobesTheme.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: PhobesTheme.animFast,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color:
                    isSelected ? cs.primary : cs.onSurface.withOpacity(0.5),
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color:
                    isSelected ? cs.primary : cs.onSurface.withOpacity(0.5),
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NovaButton extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;
  const _NovaButton({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isSelected = selectedIndex == 2;
    return GestureDetector(
      onTap: () => onTap(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: PhobesTheme.animFast,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? PhobesTheme.primaryGradient
                  : LinearGradient(colors: [
                      cs.primary.withOpacity(0.2),
                      cs.secondary.withOpacity(0.2),
                    ],),
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: cs.primary.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.auto_awesome,
              color: isSelected ? cs.onPrimary : cs.onSurface.withOpacity(0.7),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            moduleLocalizedName(l10n, 'chat'),
            style: GoogleFonts.outfit(
              color:
                  isSelected ? cs.primary : cs.onSurface.withOpacity(0.5),
              fontSize: 10,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated menu button card used in the "Life" expandable menu.
class NavMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const NavMenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      delay: Duration(milliseconds: delay),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 280,
          child: PhobesGlassCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: GoogleFonts.outfit(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),),
                      const SizedBox(height: 2),
                      Text(desc,
                          style: GoogleFonts.outfit(
                            color: cs.onSurface.withOpacity(0.5),
                            fontSize: 11,
                          ),),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: color.withOpacity(0.5), size: 14,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
