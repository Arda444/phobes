import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../services/notification_settings_service.dart';
import '../../widgets/phobes_widgets.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final Map<String, bool> _prefs = {};
  bool _isLoading = true;

  // Granular per-module prefs (the "advanced" toggles).
  static const _defaultOff = {'notif_budget_insight'};

  static const _prefKeys = [
    'notif_task_deadline',
    'notif_task_overdue',
    'notif_habit_streak',
    'notif_habit_milestone',
    'notif_med_dose',
    'notif_med_missed',
    'notif_med_refill',
    'notif_appt_reminder',
    'notif_appt_status',
    'notif_focus_break',
    'notif_budget_limit',
    'notif_budget_goal',
    'notif_budget_insight',
    'notif_team_assign',
    'notif_team_announce',
    'notif_team_deadline',
    'notif_level_up',
    'notif_milestones',
    'notif_morning_brief',
    'notif_weekly_digest',
  ];

  // ─── Master section (top-level master toggles via NotificationSettingsService)
  List<_MasterItem> _masterItems(AppLocalizations l10n) {
    final ns = NotificationSettingsService.instance;
    return [
      _MasterItem(
        icon: Icons.notifications_active_rounded,
        title: l10n.pushNotifications,
        subtitle: l10n.pushNotificationsSubtitle,
        color: const Color(0xFF3B82F6),
        listenable: ns.pushEnabled,
        onChanged: ns.setPushEnabled,
      ),
      _MasterItem(
        icon: Icons.task_alt_rounded,
        title: l10n.taskReminders,
        subtitle: l10n.taskRemindersSubtitle,
        color: const Color(0xFFF59E0B),
        listenable: ns.taskRemindersEnabled,
        onChanged: ns.setTaskRemindersEnabled,
      ),
      _MasterItem(
        icon: Icons.group_add_rounded,
        title: l10n.teamInvites,
        subtitle: l10n.teamInvitesSubtitle,
        color: const Color(0xFF14B8A6),
        listenable: ns.teamInvitesEnabled,
        onChanged: ns.setTeamInvitesEnabled,
      ),
      _MasterItem(
        icon: Icons.wb_sunny_rounded,
        title: l10n.dailyBriefing,
        subtitle: l10n.dailyBriefingSubtitle,
        color: const Color(0xFFEAB308),
        listenable: ns.dailyBriefingEnabled,
        onChanged: ns.setDailyBriefingEnabled,
      ),
      _MasterItem(
        icon: Icons.alternate_email_rounded,
        title: l10n.emailNotifications,
        subtitle: l10n.emailNotificationsSubtitle,
        color: const Color(0xFFA855F7),
        listenable: ns.emailEnabled,
        onChanged: ns.setEmailEnabled,
      ),
    ];
  }

  List<_NotifSection> _sections(AppLocalizations l10n) => [
        _NotifSection(
          title: l10n.notifPrefsSectionTasks,
          icon: Icons.task_alt_rounded,
          color: const Color(0xFF8B5CF6),
          items: [
            _NotifItem('notif_task_deadline', l10n.notifPrefsTaskDeadline,
                l10n.notifPrefsTaskDeadlineDesc),
            _NotifItem('notif_task_overdue', l10n.notifPrefsTaskOverdue,
                l10n.notifPrefsTaskOverdueDesc),
          ],
        ),
        _NotifSection(
          title: l10n.notifPrefsSectionHabits,
          icon: Icons.spa_rounded,
          color: const Color(0xFF4CAF50),
          items: [
            _NotifItem('notif_habit_streak', l10n.notifPrefsHabitStreak,
                l10n.notifPrefsHabitStreakDesc),
            _NotifItem('notif_habit_milestone', l10n.notifPrefsHabitMilestone,
                l10n.notifPrefsHabitMilestoneDesc),
          ],
        ),
        _NotifSection(
          title: l10n.notifPrefsSectionMeds,
          icon: Icons.medication_rounded,
          color: const Color(0xFF009688),
          items: [
            _NotifItem('notif_med_dose', l10n.notifPrefsMedDose,
                l10n.notifPrefsMedDoseDesc),
            _NotifItem('notif_med_missed', l10n.notifPrefsMedMissed,
                l10n.notifPrefsMedMissedDesc),
            _NotifItem('notif_med_refill', l10n.notifPrefsMedRefill,
                l10n.notifPrefsMedRefillDesc),
          ],
        ),
        _NotifSection(
          title: l10n.notifPrefsSectionAppointments,
          icon: Icons.event_rounded,
          color: const Color(0xFF2196F3),
          items: [
            _NotifItem('notif_appt_reminder', l10n.notifPrefsApptReminder,
                l10n.notifPrefsApptReminderDesc),
            _NotifItem('notif_appt_status', l10n.notifPrefsApptStatus,
                l10n.notifPrefsApptStatusDesc),
          ],
        ),
        _NotifSection(
          title: l10n.notifPrefsSectionFocus,
          icon: Icons.timelapse_rounded,
          color: const Color(0xFFFF9800),
          items: [
            _NotifItem('notif_focus_break', l10n.notifPrefsFocusBreak,
                l10n.notifPrefsFocusBreakDesc),
          ],
        ),
        _NotifSection(
          title: l10n.notifPrefsSectionBudget,
          icon: Icons.account_balance_wallet_rounded,
          color: const Color(0xFF26A69A),
          items: [
            _NotifItem('notif_budget_limit', l10n.notifPrefsBudgetLimit,
                l10n.notifPrefsBudgetLimitDesc),
            _NotifItem('notif_budget_goal', l10n.notifPrefsBudgetGoal,
                l10n.notifPrefsBudgetGoalDesc),
            _NotifItem('notif_budget_insight', l10n.notifPrefsBudgetInsight,
                l10n.notifPrefsBudgetInsightDesc),
          ],
        ),
        _NotifSection(
          title: l10n.notifPrefsSectionTeams,
          icon: Icons.groups_rounded,
          color: const Color(0xFFFF5722),
          items: [
            _NotifItem('notif_team_assign', l10n.notifPrefsTeamAssign,
                l10n.notifPrefsTeamAssignDesc),
            _NotifItem('notif_team_announce', l10n.notifPrefsTeamAnnounce,
                l10n.notifPrefsTeamAnnounceDesc),
            _NotifItem('notif_team_deadline', l10n.notifPrefsTeamDeadline,
                l10n.notifPrefsTeamDeadlineDesc),
          ],
        ),
        _NotifSection(
          title: l10n.notifPrefsSectionXp,
          icon: Icons.stars_rounded,
          color: const Color(0xFFFFD600),
          items: [
            _NotifItem('notif_level_up', l10n.notifPrefsLevelUp,
                l10n.notifPrefsLevelUpDesc),
            _NotifItem('notif_milestones', l10n.notifPrefsMilestones,
                l10n.notifPrefsMilestonesDesc),
          ],
        ),
        _NotifSection(
          title: l10n.notifPrefsSectionGeneral,
          icon: Icons.notifications_rounded,
          color: const Color(0xFF607D8B),
          items: [
            _NotifItem('notif_morning_brief', l10n.notifPrefsMorningBrief,
                l10n.notifPrefsMorningBriefDesc),
            _NotifItem('notif_weekly_digest', l10n.notifPrefsWeeklyDigest,
                l10n.notifPrefsWeeklyDigestDesc),
          ],
        ),
      ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    for (final key in _prefKeys) {
      _prefs[key] = sp.getBool(key) ?? !_defaultOff.contains(key);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _togglePref(String key, bool value) async {
    setState(() => _prefs[key] = value);
    final sp = await SharedPreferences.getInstance();
    sp.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final sections = _sections(l10n);
    final masterItems = _masterItems(l10n);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: UnconstrainedBox(
          child: PhobesIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          l10n.notifPrefsTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: PhobesLoadingIndicator(color: cs.primary))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    _buildHeader(l10n, cs),
                    const SizedBox(height: 20),
                    FadeInUp(child: _buildMasterCard(masterItems, cs)),
                    const SizedBox(height: 16),
                    _buildSectionHeader(
                      l10n.notifPrefsSubtitle,
                      cs,
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(sections.length, (i) {
                      final section = sections[i];
                      return FadeInUp(
                        delay: Duration(milliseconds: 60 + (i * 40)),
                        child: _buildSection(section, cs),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, ColorScheme cs) {
    return FadeIn(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withOpacity(0.15),
              cs.primary.withOpacity(0.03),
            ],
          ),
          border: Border.all(color: cs.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: cs.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.notifPrefsTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.notifPrefsSubtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: cs.onSurface.withOpacity(0.45),
        ),
      ),
    );
  }

  Widget _buildMasterCard(List<_MasterItem> items, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _buildMasterRow(items[i], cs),
            if (i < items.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: cs.outline.withOpacity(0.06),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMasterRow(_MasterItem item, ColorScheme cs) {
    return ValueListenableBuilder<bool>(
      valueListenable: item.listenable,
      builder: (context, value, _) {
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => item.onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: value
                        ? item.color.withOpacity(0.16)
                        : cs.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: value
                        ? item.color
                        : cs.onSurface.withOpacity(0.35),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: value
                              ? cs.onSurface
                              : cs.onSurface.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: value,
                  onChanged: item.onChanged,
                  trackColor: WidgetStateProperty.resolveWith(
                    (states) =>
                        states.contains(WidgetState.selected) ? cs.primary : null,
                  ),
                  thumbColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? Colors.white
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(_NotifSection section, ColorScheme cs) {
    final allOn = section.items.every((item) => _prefs[item.key] == true);
    final anyOn = section.items.any((item) => _prefs[item.key] == true);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            onTap: () {
              final newVal = !allOn;
              for (final item in section.items) {
                _togglePref(item.key, newVal);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: section.color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      section.icon,
                      size: 18,
                      color: section.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _sectionStatus(section, allOn, anyOn),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: anyOn
                                ? cs.onSurface.withOpacity(0.6)
                                : cs.onSurface.withOpacity(0.4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: allOn,
                    onChanged: (v) {
                      for (final item in section.items) {
                        _togglePref(item.key, v);
                      }
                    },
                    trackColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? cs.primary
                          : null,
                    ),
                    thumbColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? Colors.white
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: cs.outline.withOpacity(0.06),
          ),
          ...section.items.map((item) {
            final isOn = _prefs[item.key] ?? true;
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                children: [
                  const SizedBox(width: 50),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isOn
                                ? cs.onSurface
                                : cs.onSurface.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          item.description,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: cs.onSurface.withOpacity(0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isOn,
                    onChanged: (v) => _togglePref(item.key, v),
                    trackColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? cs.primary
                          : null,
                    ),
                    thumbColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? Colors.white
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  String _sectionStatus(_NotifSection section, bool allOn, bool anyOn) {
    final l10n = AppLocalizations.of(context)!;
    if (allOn) return l10n.notifPrefsAllOn;
    if (!anyOn) return l10n.notifPrefsAllOff;
    final on = section.items.where((i) => _prefs[i.key] == true).length;
    return '$on / ${section.items.length}';
  }
}

class _NotifSection {
  final String title;
  final IconData icon;
  final Color color;
  final List<_NotifItem> items;

  const _NotifSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class _NotifItem {
  final String key;
  final String title;
  final String description;

  const _NotifItem(this.key, this.title, this.description);
}

class _MasterItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final ValueNotifier<bool> listenable;
  final Future<void> Function(bool) onChanged;

  const _MasterItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.listenable,
    required this.onChanged,
  });
}
