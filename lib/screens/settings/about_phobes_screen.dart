import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/phobes_widgets.dart';
import '../../core/phobes_theme.dart';
import '../../l10n/app_localizations.dart';

// --- SHARED WIDGETS ---

Widget _buildSectionTitle(BuildContext context, String title) {
  return FadeInLeft(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    ),
  );
}

// --- SCREEN 1: ABOUT PHOBES ---

class AboutPhobesScreen extends StatelessWidget {
  const AboutPhobesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 900;
    final horizontalPadding = isWeb ? 80.0 : 24.0;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, cs, isAmoled && isDark, l10n.aboutPhobes),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBrandHero(cs, isDark, l10n),
                      const SizedBox(height: 48),
                      _buildSectionTitle(context, l10n.brandPhilosophyTitle),
                      _buildNameMeaning(cs, isDark, l10n),
                      const SizedBox(height: 48),
                      _buildSectionTitle(context, l10n.aboutUs),
                      _buildDetailedAbout(cs, isDark, l10n),
                      const SizedBox(height: 48),
                      _buildSectionTitle(context, l10n.teamAndThanks),
                      _buildTeamAndThanks(cs, isDark, l10n),
                      const SizedBox(height: 48),
                      _buildSectionTitle(context, l10n.securityPrivacy),
                      _buildPrivacyPolicy(context, cs, isDark, l10n),
                      const SizedBox(height: 64),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, ColorScheme cs, bool amoled, String title) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: amoled ? Colors.black : cs.surface,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: cs.onSurface,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary.withValues(alpha: 0.1),
                cs.surface,
              ],
            ),
          ),
          child: Center(
            child: Icon(Icons.auto_awesome,
                size: 40,
                color: cs.primary
                    .withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.2)),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBrandHero(ColorScheme cs, bool isDark, AppLocalizations l10n) {
    return FadeIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.brandHeroTitle,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.brandHeroDesc,
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: cs.onSurface.withValues(alpha: isDark ? 0.7 : 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameMeaning(ColorScheme cs, bool isDark, AppLocalizations l10n) {
    final meanings = [
      {'letter': 'P', 'en': 'Productivity', 'tr': l10n.productivity},
      {'letter': 'H', 'en': 'Harmony', 'tr': l10n.harmony},
      {'letter': 'O', 'en': 'Order', 'tr': l10n.order},
      {'letter': 'B', 'en': 'Balance', 'tr': l10n.balance},
      {'letter': 'E', 'en': 'Efficiency', 'tr': l10n.efficiency},
      {'letter': 'S', 'en': 'Success', 'tr': l10n.success},
    ];

    return PhobesGlassCard(
      padding: const EdgeInsets.all(24),
      margin: EdgeInsets.zero,
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        children: meanings.map((m) {
          return SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m['letter']!,
                    style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: cs.primary)),
                Text(m['en']!,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
                Text(m['tr']!,
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: isDark ? 0.5 : 0.7))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailedAbout(ColorScheme cs, bool isDark, AppLocalizations l10n) {
    return PhobesGlassCard(
      padding: const EdgeInsets.all(24),
      margin: EdgeInsets.zero,
      child: Text(
        l10n.aboutPhobesLongDesc,
        style: GoogleFonts.outfit(
            fontSize: 15,
            height: 1.6,
            color: cs.onSurface.withValues(alpha: isDark ? 0.7 : 0.85)),
      ),
    );
  }

  Widget _buildTeamAndThanks(ColorScheme cs, bool isDark, AppLocalizations l10n) {
    return PhobesGlassCard(
      padding: const EdgeInsets.all(24),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.techlunaPartners,
              style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.primary)),
          const SizedBox(height: 16),
          _buildFounderTile("Arda Kocaoğlu", l10n.coFounder, cs, isDark),
          const Divider(height: 32),
          _buildFounderTile("Sude Gül Çinay", l10n.coFounder, cs, isDark),
          const SizedBox(height: 32),
          Text(l10n.specialThanks,
              style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.primary)),
          const SizedBox(height: 12),
          Text(
            l10n.specialThanksDesc,
            style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: cs.onSurface.withValues(alpha: isDark ? 0.8 : 0.9)),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(l10n.academicTitle,
                    style: GoogleFonts.outfit(fontSize: 12, color: cs.primary)),
                Text("Şenay Kocakoyun Aydoğan",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFounderTile(
      String name, String role, ColorScheme cs, bool isDark) {
    return Row(
      children: [
        CircleAvatar(
            backgroundColor: cs.primary.withValues(alpha: 0.1),
            child: Text(name[0],
                style: GoogleFonts.outfit(
                    color: cs.primary, fontWeight: FontWeight.bold))),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: cs.onSurface)),
          Text(role,
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: isDark ? 0.5 : 0.7))),
        ]),
      ],
    );
  }

  Widget _buildPrivacyPolicy(BuildContext context, ColorScheme cs, bool isDark, AppLocalizations l10n) {
    return PhobesGlassCard(
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _buildInfoRow(context, Icons.security_rounded,
              l10n.yourDataYourFortress, l10n.dataNeverSold),
          const SizedBox(height: 16),
          _buildInfoRow(context, Icons.visibility_off_rounded,
              l10n.endToEndTransparency, l10n.dataProcessingTransparency),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String title, String desc) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, color: cs.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: cs.onSurface)),
          Text(desc,
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: isDark ? 0.6 : 0.8))),
        ])),
      ],
    );
  }
}

// --- SCREEN 2: FEATURE TREE ---

class PhobesFeatureTreeScreen extends StatelessWidget {
  const PhobesFeatureTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 900;
    final horizontalPadding = isWeb ? 80.0 : 24.0;
    final l10n = AppLocalizations.of(context)!;

    final List<Map<String, dynamic>> categories = [
      {
        'title': l10n.catTaskProject,
        'icon': Icons.handyman_rounded,
        'color': Colors.blue,
        'description': l10n.catTaskProjectDesc,
        'sections': [
          {
            'name': l10n.secActionManagement,
            'features': [
              {
                'n': l10n.featAddTask,
                'd': l10n.featAddTaskDesc,
                'i': Icons.add_task_rounded
              },
              {
                'n': l10n.featDynamicSnooze,
                'd': l10n.featDynamicSnoozeDesc,
                'i': Icons.update_rounded
              },
              {
                'n': l10n.featSubtasks,
                'd': l10n.featSubtasksDesc,
                'i': Icons.account_tree_outlined
              },
              {
                'n': l10n.featQuickEdit,
                'd': l10n.featQuickEditDesc,
                'i': Icons.edit_note_rounded
              },
            ]
          },
          {
            'name': l10n.secViewModes,
            'features': [
              {
                'n': l10n.featDailyList,
                'd': l10n.featDailyListDesc,
                'i': Icons.view_day_rounded
              },
              {
                'n': l10n.featWeeklyCalendar,
                'd': l10n.featWeeklyCalendarDesc,
                'i': Icons.view_week_rounded
              },
              {
                'n': l10n.featMonthlyPlanner,
                'd': l10n.featMonthlyPlannerDesc,
                'i': Icons.calendar_month_rounded
              },
              {
                'n': l10n.featKanbanBoard,
                'd': l10n.featKanbanBoardDesc,
                'i': Icons.view_kanban_rounded
              },
            ]
          },
          {
            'name': l10n.secNavDiscovery,
            'features': [
              {
                'n': l10n.featAdvancedFiltering,
                'd': l10n.featAdvancedFilteringDesc,
                'i': Icons.filter_alt_rounded
              },
              {
                'n': l10n.featSmartTaskSearch,
                'd': l10n.featSmartTaskSearchDesc,
                'i': Icons.search_rounded
              },
              {
                'n': l10n.featPriorityLabels,
                'd': l10n.featPriorityLabelsDesc,
                'i': Icons.label_important_rounded
              },
            ]
          }
        ]
      },
      {
        'title': l10n.catNovaAi,
        'icon': Icons.psychology_rounded,
        'color': Colors.purple,
        'description': l10n.catNovaAiDesc,
        'sections': [
          {
            'name': l10n.secAnalysisPlanning,
            'features': [
              {
                'n': l10n.featVoiceCommand,
                'd': l10n.featVoiceCommandDesc,
                'i': Icons.keyboard_voice_rounded
              },
              {
                'n': l10n.featSmartReminders,
                'd': l10n.featSmartRemindersDesc,
                'i': Icons.notifications_active_rounded
              },
              {
                'n': l10n.featUsageAnalytics,
                'd': l10n.featUsageAnalyticsDesc,
                'i': Icons.analytics_rounded
              },
            ]
          }
        ]
      },
      {
        'title': l10n.catFinance,
        'icon': Icons.account_balance_wallet_rounded,
        'color': Colors.green,
        'description': l10n.catFinanceDesc,
        'sections': [
          {
            'name': l10n.secControlPanel,
            'features': [
              {
                'n': l10n.featBudgetManagement,
                'd': l10n.featBudgetManagementDesc,
                'i': Icons.payments_rounded
              },
              {
                'n': l10n.featFinancialGoals,
                'd': l10n.featFinancialGoalsDesc,
                'i': Icons.track_changes_rounded
              },
              {
                'n': l10n.featSubscriptionTracking,
                'd': l10n.featSubscriptionTrackingDesc,
                'i': Icons.event_repeat_rounded
              },
            ]
          }
        ]
      },
      {
        'title': l10n.catLifeHealth,
        'icon': Icons.favorite_rounded,
        'color': Colors.red,
        'description': l10n.catLifeHealthDesc,
        'sections': [
          {
            'name': l10n.secBalanceTools,
            'features': [
              {
                'n': l10n.featHealthTracking,
                'd': l10n.featHealthTrackingDesc,
                'i': Icons.monitor_heart_rounded
              },
              {
                'n': l10n.featMindfulnessReminders,
                'd': l10n.featMindfulnessRemindersDesc,
                'i': Icons.self_improvement_rounded
              },
              {
                'n': l10n.featMedicationTracking,
                'd': l10n.featMedicationTrackingDesc,
                'i': Icons.medication_rounded
              },
            ]
          }
        ]
      },
      {
        'title': l10n.catPhobesCore,
        'icon': Icons.hub_rounded,
        'color': Colors.orange,
        'description': l10n.catPhobesCoreDesc,
        'sections': [
          {
            'name': l10n.secSecuritySpeed,
            'features': [
              {
                'n': l10n.featCloudSync,
                'd': l10n.featCloudSyncDesc,
                'i': Icons.cloud_sync_rounded
              },
              {
                'n': l10n.featBiometricLock,
                'd': l10n.featBiometricLockDesc,
                'i': Icons.fingerprint_rounded
              },
              {
                'n': l10n.featOfflineSupport,
                'd': l10n.featOfflineSupportDesc,
                'i': Icons.cloud_off_rounded
              },
            ]
          }
        ]
      },
    ];

    return Scaffold(
      backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, cs, isAmoled && isDark, l10n.featureTree),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, l10n.featureCatalogTitle),
                      Text(
                        l10n.featureCatalogDesc,
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: cs.onSurface
                                .withValues(alpha: isDark ? 0.6 : 0.8)),
                      ),
                      const SizedBox(height: 48),
                      _buildSectionTitle(context, l10n.featureTreeTitle),
                      ...categories
                          .map((cat) => _buildImmersiveCategory(cat, cs, isWeb))
                          ,
                      const SizedBox(height: 64),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, ColorScheme cs, bool amoled, String title) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: amoled ? Colors.black : cs.surface,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(title.toUpperCase(),
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context)),
    );
  }

  Widget _buildImmersiveCategory(
      Map<String, dynamic> cat, ColorScheme cs, bool isWeb) {
    final color = cat['color'] as Color;
    final List<dynamic> sections = cat['sections'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInLeft(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(cat['icon'] as IconData, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                cat['title'] as String,
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 56),
          child: Text(cat['description'] as String,
              style: GoogleFonts.outfit(
                  fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6))),
        ),
        const SizedBox(height: 24),
        ...sections.map((sec) => _buildSection(sec, color, cs, isWeb)),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildSection(
      Map<String, dynamic> sec, Color color, ColorScheme cs, bool isWeb) {
    final List<dynamic> features = sec['features'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 56, bottom: 16),
          child: Text(sec['name'] as String,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 1.2)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 48, right: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWeb ? 2 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isWeb ? 2.8 : 3.5,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final f = features[index];
            return FadeInUp(
              delay: Duration(milliseconds: 50 * index),
              child: PhobesGlassCard(
                padding: const EdgeInsets.all(16),
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(f['i'] as IconData, color: color, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f['n'] as String,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(f['d'] as String,
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                  height: 1.2),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// --- SCREEN 3: CONTACT & SUPPORT ---

class PhobesContactScreen extends StatelessWidget {
  const PhobesContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 900;
    final horizontalPadding = isWeb ? 80.0 : 24.0;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, cs, isAmoled && isDark, l10n.contact),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, l10n.contactChannels),
                      PhobesGlassCard(
                        padding: const EdgeInsets.all(24),
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _buildContactTile(
                              Icons.alternate_email_rounded,
                              l10n.generalContact,
                              "hello@phobes.app",
                              () => _launchEmail(
                                  'hello@phobes.app', l10n.aboutPhobes),
                            ),
                            const Divider(height: 32),
                            _buildContactTile(
                              Icons.support_agent_rounded,
                              l10n.supportHotline,
                              "support@phobes.app",
                              () => _launchEmail(
                                  'support@phobes.app', l10n.support),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildSectionTitle(context, l10n.corpInfo),
                      PhobesGlassCard(
                        padding: const EdgeInsets.all(24),
                        margin: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Techluna Software and Design",
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(
                                l10n.techlunaDesc,
                                style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: cs.onSurface
                                        .withValues(alpha: isDark ? 0.6 : 0.8))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 64),
                      Center(
                        child: Text(
                          l10n.allRightsReserved,
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.3)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, ColorScheme cs, bool amoled, String title) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: amoled ? Colors.black : cs.surface,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(title.toUpperCase(),
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context)),
    );
  }

  Widget _buildContactTile(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.blueAccent),
      ),
      title:
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _launchEmail(String email, String subject) async {
    final Uri uri =
        Uri(scheme: 'mailto', path: email, query: 'subject=$subject');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
