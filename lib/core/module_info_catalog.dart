import 'package:flutter/material.dart' show Icons;
import '../l10n/app_localizations.dart';
import '../widgets/phobes_module_info.dart';

/// Central module help copy — used by headers across the app.
class ModuleInfoCatalog {
  ModuleInfoCatalog._();

  static PhobesModuleInfoContent forCalendar(AppLocalizations l10n) =>
      PhobesModuleInfoContent(
        title: l10n.appTitle,
        intro: l10n.moduleInfoCalendarIntro,
        sections: [
          PhobesInfoSection(
            title: l10n.moduleInfoCalendarSection1Title,
            icon: Icons.calendar_month_rounded,
            bullets: [
              l10n.moduleInfoCalendarSection1B1,
              l10n.moduleInfoCalendarSection1B2,
            ],
          ),
          PhobesInfoSection(
            title: l10n.moduleInfoCalendarSection2Title,
            icon: Icons.add_circle_outline_rounded,
            bullets: [
              l10n.moduleInfoCalendarSection2B1,
              l10n.moduleInfoCalendarSection2B2,
            ],
          ),
        ],
        tips: [l10n.moduleInfoCalendarTip1],
      );

  static PhobesModuleInfoContent forBudget(AppLocalizations l10n) =>
      PhobesModuleInfoContent(
        title: l10n.moduleInfoBudgetTitle,
        intro: l10n.moduleInfoBudgetIntro,
        sections: [
          PhobesInfoSection(
            title: l10n.moduleInfoBudgetSection1Title,
            bullets: [
              l10n.moduleInfoBudgetSection1B1,
              l10n.moduleInfoBudgetSection1B2,
            ],
          ),
        ],
        tips: [l10n.moduleInfoBudgetTip1],
      );

  static PhobesModuleInfoContent forBooks(AppLocalizations l10n) =>
      PhobesModuleInfoContent(
        title: l10n.moduleInfoBooksTitle,
        intro: l10n.moduleInfoBooksIntro,
        sections: [
          PhobesInfoSection(
            title: l10n.moduleInfoBooksSection1Title,
            icon: Icons.menu_book_rounded,
            bullets: [
              l10n.moduleInfoBooksSection1B1,
              l10n.moduleInfoBooksSection1B2,
            ],
          ),
        ],
        tips: [l10n.moduleInfoBooksTip1],
      );

  static PhobesModuleInfoContent forNotes(AppLocalizations l10n) =>
      PhobesModuleInfoContent(
        title: l10n.moduleInfoNotesTitle,
        intro: l10n.moduleInfoNotesIntro,
        sections: [
          PhobesInfoSection(
            title: l10n.moduleInfoNotesSection1Title,
            bullets: [
              l10n.moduleInfoNotesSection1B1,
              l10n.moduleInfoNotesSection1B2,
            ],
          ),
        ],
        tips: [l10n.moduleInfoNotesTip1],
      );

  static PhobesModuleInfoContent forMedications(AppLocalizations l10n) =>
      PhobesModuleInfoContent(
        title: l10n.moduleInfoMedsTitle,
        intro: l10n.moduleInfoMedsIntro,
        sections: [
          PhobesInfoSection(
            title: l10n.moduleInfoMedsSection1Title,
            icon: Icons.medication_rounded,
            bullets: [
              l10n.moduleInfoMedsSection1B1,
              l10n.moduleInfoMedsSection1B2,
            ],
          ),
        ],
        tips: [l10n.moduleInfoMedsTip1],
      );

  static PhobesModuleInfoContent forAppointments(AppLocalizations l10n) =>
      PhobesModuleInfoContent(
        title: l10n.moduleInfoApptTitle,
        intro: l10n.moduleInfoApptIntro,
        sections: [
          PhobesInfoSection(
            title: l10n.moduleInfoApptSection1Title,
            bullets: [
              l10n.moduleInfoApptSection1B1,
              l10n.moduleInfoApptSection1B2,
            ],
          ),
        ],
        tips: [l10n.moduleInfoApptTip1],
      );

  static PhobesModuleInfoContent forHabits(AppLocalizations l10n) =>
      PhobesModuleInfoContent(
        title: l10n.moduleInfoHabitsTitle,
        intro: l10n.moduleInfoHabitsIntro,
        sections: [
          PhobesInfoSection(
            title: l10n.moduleInfoHabitsSection1Title,
            icon: Icons.local_fire_department_rounded,
            bullets: [
              l10n.moduleInfoHabitsSection1B1,
              l10n.moduleInfoHabitsSection1B2,
            ],
          ),
        ],
        tips: [l10n.moduleInfoHabitsTip1],
      );

  static PhobesModuleInfoContent forUpcoming(AppLocalizations l10n) =>
      PhobesModuleInfoContent(
        title: l10n.moduleInfoUpcomingTitle,
        intro: l10n.moduleInfoUpcomingIntro,
        sections: [
          PhobesInfoSection(
            title: l10n.moduleInfoUpcomingSection1Title,
            bullets: [
              l10n.moduleInfoUpcomingSection1B1,
              l10n.moduleInfoUpcomingSection1B2,
            ],
          ),
        ],
        tips: [l10n.moduleInfoUpcomingTip1],
      );

  static PhobesModuleInfoContent forTeams(AppLocalizations l10n) =>
      PhobesModuleInfoContent(
        title: l10n.navTeams,
        intro: l10n.moduleInfoTeamsIntro,
        sections: [
          PhobesInfoSection(
            title: l10n.moduleInfoTeamsSection1Title,
            bullets: [
              l10n.moduleInfoTeamsSection1B1,
              l10n.moduleInfoTeamsSection1B2,
            ],
          ),
        ],
        tips: [l10n.moduleInfoTeamsTip1],
      );

  static PhobesModuleInfoContent forFocus(AppLocalizations l10n) =>
      PhobesModuleInfoContent(
        title: l10n.navFocus,
        intro: l10n.moduleInfoFocusIntro,
        tips: [l10n.moduleInfoFocusTip1],
      );

  static PhobesModuleInfoContent forStatistics(AppLocalizations l10n) =>
      PhobesModuleInfoContent(
        title: l10n.navStatistics,
        intro: l10n.moduleInfoStatsIntro,
        tips: [l10n.moduleInfoStatsTip1],
      );

  static PhobesModuleInfoContent forCorkboard(AppLocalizations l10n) =>
      PhobesModuleInfoContent(
        title: l10n.moduleInfoCorkboardTitle,
        intro: l10n.moduleInfoCorkboardIntro,
        tips: [l10n.moduleInfoCorkboardTip1],
      );

  static PhobesModuleInfoContent forProjects(AppLocalizations l10n) =>
      PhobesModuleInfoContent(
        title: l10n.moduleInfoProjectsTitle,
        intro: l10n.moduleInfoProjectsIntro,
        tips: [l10n.moduleInfoProjectsTip1],
      );
}
