import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Marketing copy for landing, about, and feature tree — aligned with app modules.
class MarketingModule {
  final String id;
  final IconData icon;
  final Color color;
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) subtitle;
  final bool showOnLanding;
  final bool showInAboutGrid;

  const MarketingModule({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.showOnLanding = true,
    this.showInAboutGrid = true,
  });
}

class MarketingModuleCatalog {
  MarketingModuleCatalog._();

  static List<MarketingModule> get all => _modules;

  static List<MarketingModule> landingFeatures(AppLocalizations l10n) =>
      _modules.where((m) => m.showOnLanding).toList();

  static List<MarketingModule> aboutModules(AppLocalizations l10n) =>
      _modules.where((m) => m.showInAboutGrid).toList();

  static final List<MarketingModule> _modules = [
    MarketingModule(
      id: 'calendar',
      icon: Icons.calendar_month_rounded,
      color: const Color(0xFFE65100),
      title: (l) => l.navCalendar,
      subtitle: (l) => l.landingFeatCalendarSubtitle,
    ),
    MarketingModule(
      id: 'tasks',
      icon: Icons.task_alt_rounded,
      color: const Color(0xFF4285F4),
      title: (l) => l.featAddTask,
      subtitle: (l) => l.landingFeatTasksSubtitle,
    ),
    MarketingModule(
      id: 'appointments',
      icon: Icons.event_available_rounded,
      color: const Color(0xFF10B981),
      title: (l) => l.navAppointments,
      subtitle: (l) => l.landingFeatAppointmentsSubtitle,
    ),
    MarketingModule(
      id: 'statistics',
      icon: Icons.bar_chart_rounded,
      color: const Color(0xFFF59E0B),
      title: (l) => l.navStatistics,
      subtitle: (l) => l.landingFeatStatisticsSubtitle,
    ),
    MarketingModule(
      id: 'budget',
      icon: Icons.account_balance_wallet_rounded,
      color: const Color(0xFF06B6D4),
      title: (l) => l.featBudgetManagement,
      subtitle: (l) => l.landingFeatBudgetSubtitle,
    ),
    MarketingModule(
      id: 'nova',
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFF8B5CF6),
      title: (l) => l.novaAssistant,
      subtitle: (l) => l.landingFeatNovaSubtitle,
    ),
    MarketingModule(
      id: 'notes',
      icon: Icons.note_alt_rounded,
      color: const Color(0xFF3B82F6),
      title: (l) => l.noteMyNotes,
      subtitle: (l) => l.landingFeatNotesSubtitle,
    ),
    MarketingModule(
      id: 'projects',
      icon: Icons.view_kanban_rounded,
      color: const Color(0xFFF472B6),
      title: (l) => l.moduleInfoProjectsTitle,
      subtitle: (l) => l.landingFeatProjectsSubtitle,
    ),
    MarketingModule(
      id: 'teams',
      icon: Icons.group_rounded,
      color: const Color(0xFFEF4444),
      title: (l) => l.navTeams,
      subtitle: (l) => l.landingFeatTeamsSubtitle,
    ),
    MarketingModule(
      id: 'focus',
      icon: Icons.timer_rounded,
      color: const Color(0xFF059669),
      title: (l) => l.navFocus,
      subtitle: (l) => l.landingFeatFocusSubtitle,
    ),
    MarketingModule(
      id: 'habits',
      icon: Icons.loop_rounded,
      color: const Color(0xFF7C3AED),
      title: (l) => l.navHabits,
      subtitle: (l) => l.landingFeatHabitsSubtitle,
    ),
    MarketingModule(
      id: 'medications',
      icon: Icons.medication_rounded,
      color: const Color(0xFFDB2777),
      title: (l) => l.navMedications,
      subtitle: (l) => l.landingFeatMedicationsSubtitle,
    ),
    MarketingModule(
      id: 'upcoming',
      icon: Icons.upcoming_rounded,
      color: const Color(0xFF0D9488),
      title: (l) => l.navUpcomingEvents,
      subtitle: (l) => l.landingFeatUpcomingSubtitle,
    ),
    MarketingModule(
      id: 'books',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFFCA8A04),
      title: (l) => l.moduleInfoBooksTitle,
      subtitle: (l) => l.landingFeatBooksSubtitle,
    ),
    MarketingModule(
      id: 'corkboard',
      icon: Icons.dashboard_customize_rounded,
      color: const Color(0xFF6366F1),
      title: (l) => l.corkboardPersonalTitle,
      subtitle: (l) => l.landingFeatCorkboardSubtitle,
    ),
    MarketingModule(
      id: 'notifications',
      icon: Icons.notifications_active_rounded,
      color: const Color(0xFFF97316),
      title: (l) => l.featSmartReminders,
      subtitle: (l) => l.landingFeatNotificationsSubtitle,
      showInAboutGrid: false,
    ),
    MarketingModule(
      id: 'personalization',
      icon: Icons.palette_rounded,
      color: const Color(0xFF8B5CF6),
      title: (l) => l.landingFeatPersonalizationTitle,
      subtitle: (l) => l.landingFeatPersonalizationSubtitle,
      showInAboutGrid: false,
    ),
    MarketingModule(
      id: 'voice',
      icon: Icons.mic_rounded,
      color: const Color(0xFF0EA5E9),
      title: (l) => l.featVoiceCommand,
      subtitle: (l) => l.featVoiceCommandDesc,
      showInAboutGrid: false,
    ),
  ];
}
