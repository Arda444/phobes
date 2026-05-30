import '../l10n/app_localizations.dart';

/// Localized display names for [ModuleSettingsService.appModules] entries.
String moduleLocalizedName(AppLocalizations l10n, String moduleId) {
  return switch (moduleId) {
    'calendar' => l10n.moduleNameCalendar,
    'teams' => l10n.moduleNameTeams,
    'chat' => l10n.moduleNameNova,
    'habit' => l10n.moduleNameHabits,
    'focus' => l10n.moduleNameFocus,
    'budget' => l10n.moduleNameBudget,
    'appointments' => l10n.moduleNameAppointments,
    'notes' => l10n.moduleNameNotes,
    'medications' => l10n.moduleNameMedications,
    'upcoming' => l10n.moduleNameUpcoming,
    'statistics' => l10n.moduleNameStatistics,
    'corkboard' => l10n.moduleNameCorkboard,
    'books' => l10n.moduleNameBooks,
    _ => moduleId,
  };
}
