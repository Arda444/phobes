import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:home_widget/home_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:phobes/l10n/app_localizations.dart';
import '../../core/phobes_theme.dart';

import '../../widgets/phobes_widgets.dart';
import '../calendar/calendar_screen.dart';
import '../calendar/upcoming_events_screen.dart';
import '../appointments/appointment_screen.dart';
import '../teams/team_screen.dart';
import '../notes/notes_screen.dart';
import '../habit/habit_screen.dart';
import '../medication/medications_screen.dart';
import '../focus/focus_screen.dart';
import '../notifications/notifications_screen.dart';
import '../tasks/task_add_edit_screen.dart';
import '../chat/nova_chat_screen.dart';
import 'account_screen.dart';
import 'statistics_screen.dart';
import '../budget/budget_screen.dart';
import '../teams/team_detail_screen.dart';
import '../../models/team_model.dart';
import '../../services/firebase_service.dart';
import '../../services/budget_service.dart';
import '../../services/widget_service.dart';
import '../../services/module_settings_service.dart';
import '../../widgets/home/responsive_layout_widgets.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _visualIndex = 0;
  int _selectedSubIndex = -1;
  bool _isMenuOpen = false;
  Team? _selectedTeam;

  Widget _currentLifeWidget = const NotesScreen();
  String? _lifeTitle = 'Bütçe Takip';
  final FirebaseService _firebaseService = FirebaseService();
  final BudgetService _budgetService = BudgetService();

  late List<Widget> _widgetOptions;
  late AnimationController _menuAnimController;
  late Animation<double> _menuAnimation;

  @override
  void initState() {
    super.initState();
    ModuleSettingsService.instance.customNavButton
        .addListener(_onSettingsChanged);
    ModuleSettingsService.instance.disabledModules
        .addListener(_onSettingsChanged);
    _updateWidgetOptions();
    _menuAnimController = AnimationController(
      duration: PhobesTheme.animNormal,
      vsync: this,
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuAnimController,
      curve: PhobesTheme.curveDefault,
    );

    _updateHomeWidget();
  }

  Future<void> _updateHomeWidget() async {
    try {
      final now = DateTime.now();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final tasks =
          await _firebaseService.getTasksForDateRange(now, endOfDay).first;

      final pendingTasks = tasks.where((t) => t.status != 'completed').length;
      final message = pendingTasks > 0
          ? "Bugün için $pendingTasks görev kaldı!"
          : "Tüm görevler tamamlandı, harika!";

      await HomeWidget.saveWidgetData<String>('widget_message', message);
      await HomeWidget.updateWidget(
        name: 'HomeWidgetProvider',
        iOSName: 'PhobesWidget',
      );

      // --- Budget Update ---
      final budgetData = await _budgetService.getSankeyData();
      final income = budgetData['income'] as double? ?? 0.0;
      final expense = budgetData['expenseTotal'] as double? ?? 0.0;
      final balance = budgetData['savings'] as double? ?? 0.0;

      await WidgetService.updateBudgetWidget(
        income: income,
        expense: expense,
        balance: balance,
      );

      // --- Calendar/Tasks Update ---
      final calendarItems = <String>[];
      int remainingTasks = 0;
      for (final t in tasks) {
        if (t.status != 'completed') {
          if (calendarItems.length < 3) {
            calendarItems.add("• ${t.title}");
          }
          remainingTasks++;
        }
      }
      if (remainingTasks > 3) {
        calendarItems[2] = "... ve ${remainingTasks - 2} görev daha";
      }

      await WidgetService.updateCalendarWidget(calendarItems);

      // --- Medications Update ---
      final medsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('medications')
          .get();

      final medItems = <String>[];
      int remainingMeds = 0;

      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      for (var doc in medsSnapshot.docs) {
        final data = doc.data();
        final schedule = data['schedule'] as List<dynamic>? ?? [];

        bool hasToday = schedule
            .any((s) => s['date'] == todayStr && s['status'] != 'taken');

        if (hasToday) {
          if (medItems.length < 3) {
            medItems.add("• ${data['name']} (${data['dosage']})");
          }
          remainingMeds++;
        }
      }

      if (remainingMeds > 3) {
        medItems[2] = "... ve ${remainingMeds - 2} ilaç daha";
      }

      await WidgetService.updateMedicationWidget(medItems);
    } catch (e) {
      debugPrint("HomeWidget update error: $e");
    }
  }

  @override
  void dispose() {
    ModuleSettingsService.instance.customNavButton
        .removeListener(_onSettingsChanged);
    ModuleSettingsService.instance.disabledModules
        .removeListener(_onSettingsChanged);
    _menuAnimController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {
        _updateWidgetOptions();
      });
    }
  }

  void _updateWidgetOptions() {
    Widget customScreen;
    final customNavId = ModuleSettingsService.instance.customNavButton.value;

    switch (customNavId) {
      case 'budget':
        customScreen = BudgetScreen(onClose: () => _onItemTapped(0));
        break;
      case 'habit':
        customScreen = const HabitScreen();
        break;
      case 'notes':
        customScreen = const NotesScreen();
        break;
      case 'appointments':
        customScreen = AppointmentScreen(onClose: () => _onItemTapped(0));
        break;
      case 'medications':
        customScreen = MedicationsScreen(onClose: () => _onItemTapped(0));
        break;
      case 'focus':
        customScreen = const FocusScreen();
        break;
      case 'upcoming':
        customScreen = const UpcomingEventsScreen();
        break;
      case 'statistics':
        customScreen = const StatisticsScreen();
        break;
      case 'teams':
      default:
        customScreen = TeamScreen(
          onTeamSelected: (team) {
            setState(() {
              _selectedTeam = team;
              _selectedSubIndex = 0;
              _selectedIndex = 1;
              _visualIndex = 1;
            });
          },
        );
        break;
    }

    _widgetOptions = [
      const CalendarScreen(),
      customScreen,
      const NovaChatScreen(),
      _currentLifeWidget,
      const AccountScreen(),
      const NotificationsScreen(),
      TaskAddEditScreen(
        selectedDate: DateTime.now(),
        onClose: () => _onItemTapped(0),
      ),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      setState(() {
        if (_isMenuOpen) {
          _isMenuOpen = false;
          _menuAnimController.reverse();
          _selectedIndex = _visualIndex;
        } else {
          _isMenuOpen = true;
          _menuAnimController.forward();
          _selectedIndex = 3;
        }
      });
      return;
    }

    setState(() {
      _selectedIndex = index;
      _visualIndex = index;
      _isMenuOpen = false;
      _menuAnimController.reverse();
      if (index == 1) {
        _selectedSubIndex = -1;
      }
    });
  }

  void handleDeepLink(String action) {
    if (!mounted) return;

    switch (action) {
      case 'add_task':
        _onItemTapped(6); // Görev Ekle Ekranı indexi (_widgetOptions)
        break;
      case 'add_expense':
        _selectLifeOption(
            BudgetScreen(onClose: () => _onItemTapped(0)), 'Bütçe Takip');
        break;
      case 'add_medication':
        _selectLifeOption(
            MedicationsScreen(onClose: () => _onItemTapped(0)), 'İlaçlarım');
        break;
      case 'add_note':
        _selectLifeOption(const NotesScreen(), 'Notlarım');
        break;
    }
  }

  void _selectLifeOption(Widget widget, String title) {
    setState(() {
      _currentLifeWidget = widget;
      _lifeTitle = title;
      _updateWidgetOptions();
      _visualIndex = 3;
      _selectedIndex = 3;
      _isMenuOpen = false;
      _menuAnimController.reverse();
    });
  }

  void _onSidebarItemSelected(int index, int? subIndex, AppLocalizations l10n) {
    if (index == 0) {
      _onItemTapped(0);
    } else if (index == 1) {
      setState(() {
        _selectedIndex = 1;
        _visualIndex = 1;
        _isMenuOpen = false;
        if (subIndex != null) {
          _selectedSubIndex = subIndex;
          if (_selectedTeam == null) {
            _firebaseService.getUserTeamsStream().first.then((teams) {
              if (teams.isNotEmpty && mounted) {
                setState(() => _selectedTeam = teams.first);
              }
            });
          }
        } else {
          _selectedSubIndex = -1;
        }
      });
    } else if (index == 2) {
      _onItemTapped(2);
    } else if (index == 3) {
      _selectLifeOption(const HabitScreen(), l10n.navHabits);
    } else if (index == 4) {
      _selectLifeOption(const FocusScreen(), l10n.navFocus);
    } else if (index == 5) {
      _selectLifeOption(const BudgetScreen(), 'Bütçe Takip');
    } else if (index == 6) {
      _selectLifeOption(const AppointmentScreen(), l10n.navAppointments);
    } else if (index == 7) {
      _selectLifeOption(const NotesScreen(), 'Notlarım');
    } else if (index == 8) {
      _selectLifeOption(const MedicationsScreen(), 'İlaçlarım');
    } else if (index == 9) {
      _selectLifeOption(const UpcomingEventsScreen(), 'Yaklaşanlar');
    } else if (index == 10) {
      _selectLifeOption(const StatisticsScreen(), l10n.navStatistics);
    } else if (index == 11) {
      _onItemTapped(4);
    } else if (index == 12) {
      setState(() {
        _selectedIndex = 5;
        _visualIndex = 5;
        _isMenuOpen = false;
      });
    } else if (index == 13) {
      setState(() {
        _selectedIndex = 6;
        _visualIndex = 6;
        _isMenuOpen = false;
      });
    }

    if (index != 1) {
      setState(() => _selectedSubIndex = -1);
    }
  }

  int _getSidebarSelectedIndex() {
    if (_visualIndex == 0) return 0;
    if (_visualIndex == 1) return 1;
    if (_visualIndex == 2) return 2;
    if (_visualIndex == 4) return 11;
    if (_visualIndex == 5) return 12;
    if (_visualIndex == 6) return 13;

    if (_currentLifeWidget is HabitScreen) return 3;
    if (_currentLifeWidget is FocusScreen) return 4;
    if (_currentLifeWidget is BudgetScreen) return 5;
    if (_currentLifeWidget is AppointmentScreen) return 6;
    if (_currentLifeWidget is NotesScreen) return 7;
    if (_currentLifeWidget is MedicationsScreen) return 8;
    if (_currentLifeWidget is UpcomingEventsScreen) return 9;
    if (_currentLifeWidget is StatisticsScreen) return 10;

    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final displayLifeTitle = _selectedIndex == 3 && !_isMenuOpen
            ? (_lifeTitle ?? l10n.navLife)
            : l10n.navLife;

        return Scaffold(
          backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
          extendBody: true,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isWide)
                ValueListenableBuilder<List<String>>(
                  valueListenable:
                      ModuleSettingsService.instance.disabledModules,
                  builder: (context, disabledModules, child) {
                    bool isModuleEnabled(String id) => !disabledModules.contains(id);
                    final availableSidebarItems = <SidebarItemData>[
                      SidebarItemData(
                          icon: Icons.calendar_month_rounded,
                          label: l10n.navCalendar),
                      if (isModuleEnabled('teams'))
                        SidebarItemData(
                            icon: Icons.groups_2_rounded, label: l10n.navTeams),
                      SidebarItemData(
                          icon: Icons.auto_awesome, label: "Nova AI"),
                      if (isModuleEnabled('habit'))
                        SidebarItemData(
                            icon: Icons.spa_rounded, label: l10n.navHabits),
                      if (isModuleEnabled('focus'))
                        SidebarItemData(
                            icon: Icons.timelapse_rounded,
                            label: l10n.navFocus),
                      if (isModuleEnabled('budget'))
                        SidebarItemData(
                            icon: Icons.account_balance_wallet_rounded,
                            label: "Bütçe"),
                      if (isModuleEnabled('appointments'))
                        SidebarItemData(
                            icon: Icons.event_available_rounded,
                            label: l10n.navAppointments),
                      if (isModuleEnabled('notes'))
                        SidebarItemData(
                            icon: Icons.note_alt_rounded, label: "Notlarım"),
                      if (isModuleEnabled('medications'))
                        SidebarItemData(
                            icon: Icons.medication_rounded, label: "İlaçlarım"),
                      if (isModuleEnabled('upcoming'))
                        SidebarItemData(
                            icon: Icons.upcoming_rounded, label: "Yaklaşanlar"),
                      if (isModuleEnabled('statistics'))
                        SidebarItemData(
                            icon: Icons.insights_rounded,
                            label: l10n.navStatistics),
                      SidebarItemData(
                          icon: Icons.person_rounded, label: l10n.navAccount),
                      SidebarItemData(
                          icon: Icons.notifications_rounded,
                          label: 'Bildirimler'),
                      SidebarItemData(
                          icon: Icons.add_task_rounded, label: "Görev Ekle"),
                    ];

                    // Determine original index for callbacks based on labels to avoid complex index mapping
                    int mapSidebarIndex(int newIndex) {
                      final label = availableSidebarItems[newIndex].label;
                      if (label == l10n.navCalendar) return 0;
                      if (label == l10n.navTeams) return 1;
                      if (label == "Nova AI") return 2;
                      if (label == l10n.navHabits) return 3;
                      if (label == l10n.navFocus) return 4;
                      if (label == "Bütçe") return 5;
                      if (label == l10n.navAppointments) return 6;
                      if (label == "Notlarım") return 7;
                      if (label == "İlaçlarım") return 8;
                      if (label == "Yaklaşanlar") return 9;
                      if (label == l10n.navStatistics) return 10;
                      if (label == l10n.navAccount) return 11;
                      if (label == 'Bildirimler') return 12;
                      if (label == "Görev Ekle") return 13;
                      return 0;
                    }

                    int selectedMappedIndex = 0;
                    for (int i = 0; i < availableSidebarItems.length; i++) {
                      if (mapSidebarIndex(i) == _getSidebarSelectedIndex()) {
                        selectedMappedIndex = i;
                        break;
                      }
                    }

                    return NavigationSidebar(
                      selectedIndex: selectedMappedIndex,
                      selectedSubIndex: _selectedSubIndex,
                      onItemSelected: (idx, subIdx) => _onSidebarItemSelected(
                          mapSidebarIndex(idx), subIdx, l10n),
                      header: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: PhobesTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.blur_on_rounded,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Phobes",
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      items: availableSidebarItems,
                    );
                  },
                ),
              Expanded(
                child: Stack(
                  children: [
                    IndexedStack(
                      index: (_visualIndex == 1 &&
                              _selectedSubIndex != -1 &&
                              _selectedTeam != null)
                          ? 7
                          : _visualIndex,
                      children: [
                        ..._widgetOptions,
                        if (_selectedTeam != null)
                          TeamDetailScreen(
                            team: _selectedTeam!,
                            externalIndex: _selectedSubIndex,
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                    if (_isMenuOpen && !isWide)
                      FadeTransition(
                        opacity: _menuAnimation,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isMenuOpen = false;
                              _menuAnimController.reverse();
                              _selectedIndex = _visualIndex;
                            });
                          },
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              color: (isAmoled && isDark
                                      ? Colors.black
                                      : cs.surface)
                                  .withValues(alpha: 0.7),
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                      ),
                    if (_isMenuOpen && !isWide)
                      Positioned(
                        bottom: 100,
                        right: 20,
                        left: 20,
                        top: MediaQuery.of(context).padding.top + 80,
                        child: SingleChildScrollView(
                          reverse: true,
                          physics: const BouncingScrollPhysics(),
                          child: ValueListenableBuilder<List<String>>(
                            valueListenable:
                                ModuleSettingsService.instance.disabledModules,
                            builder: (context, disabledModules, child) {
                              bool isModuleEnabled(String id) => !disabledModules.contains(id);
                              return ValueListenableBuilder<String>(
                                valueListenable: ModuleSettingsService
                                    .instance.customNavButton,
                                builder: (context, customNavButton, child) {
                                  return Align(
                                    alignment: Alignment.bottomRight,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (customNavButton != 'statistics' &&
                                            isModuleEnabled('statistics'))
                                          _buildModernMenuButton(
                                            icon: Icons.insights_rounded,
                                            label: l10n.navStatistics,
                                            color: Colors.purple.shade300,
                                            desc: l10n.descStats,
                                            onTap: () => _selectLifeOption(
                                                const StatisticsScreen(),
                                                l10n.navStatistics),
                                            delay: 0,
                                            cs: cs,
                                          ),
                                        if (customNavButton != 'statistics' &&
                                            isModuleEnabled('statistics'))
                                          const SizedBox(height: 12),
                                        if (customNavButton != 'upcoming' &&
                                            isModuleEnabled('upcoming'))
                                          _buildModernMenuButton(
                                            icon: Icons.upcoming_rounded,
                                            label: 'Yaklaşanlar',
                                            color: Colors.pink.shade400,
                                            desc: 'Yaklaşan tüm olaylarınız',
                                            onTap: () => _selectLifeOption(
                                                const UpcomingEventsScreen(),
                                                'Yaklaşanlar'),
                                            delay: 50,
                                            cs: cs,
                                          ),
                                        if (customNavButton != 'upcoming' &&
                                            isModuleEnabled('upcoming'))
                                          const SizedBox(height: 12),
                                        if (customNavButton != 'focus' &&
                                            isModuleEnabled('focus'))
                                          _buildModernMenuButton(
                                            icon: Icons.timelapse_rounded,
                                            label: l10n.navFocus,
                                            color: Colors.deepOrange.shade400,
                                            desc: l10n.descFocus,
                                            onTap: () => _selectLifeOption(
                                                const FocusScreen(),
                                                l10n.navFocus),
                                            delay: 100,
                                            cs: cs,
                                          ),
                                        if (customNavButton != 'focus' &&
                                            isModuleEnabled('focus'))
                                          const SizedBox(height: 12),
                                        if (customNavButton != 'medications' &&
                                            isModuleEnabled('medications'))
                                          _buildModernMenuButton(
                                            icon: Icons.medication_rounded,
                                            label: 'İlaçlarım',
                                            color: Colors.teal.shade400,
                                            desc:
                                                'İlaç takibi ve hatırlatıcılar',
                                            onTap: () => _selectLifeOption(
                                                MedicationsScreen(
                                                    onClose: () =>
                                                        _onItemTapped(0)),
                                                'İlaçlarım'),
                                            delay: 150,
                                            cs: cs,
                                          ),
                                        if (customNavButton != 'medications' &&
                                            isModuleEnabled('medications'))
                                          const SizedBox(height: 12),
                                        if (customNavButton != 'appointments' &&
                                            isModuleEnabled('appointments'))
                                          _buildModernMenuButton(
                                            icon: Icons.event_available_rounded,
                                            label: l10n.navAppointments,
                                            color: Colors.cyan.shade400,
                                            desc: l10n.descAppointments,
                                            onTap: () => _selectLifeOption(
                                                AppointmentScreen(
                                                    onClose: () =>
                                                        _onItemTapped(0)),
                                                l10n.navAppointments),
                                            delay: 200,
                                            cs: cs,
                                          ),
                                        if (customNavButton != 'appointments' &&
                                            isModuleEnabled('appointments'))
                                          const SizedBox(height: 12),
                                        if (customNavButton != 'notes' &&
                                            isModuleEnabled('notes'))
                                          _buildModernMenuButton(
                                            icon: Icons.note_alt_rounded,
                                            label: 'Notlarım',
                                            color: Colors.indigo.shade400,
                                            desc: 'Düşüncelerinizi kaydedin',
                                            onTap: () => _selectLifeOption(
                                                const NotesScreen(),
                                                'Notlarım'),
                                            delay: 250,
                                            cs: cs,
                                          ),
                                        if (customNavButton != 'notes' &&
                                            isModuleEnabled('notes'))
                                          const SizedBox(height: 12),
                                        if (customNavButton != 'habit' &&
                                            isModuleEnabled('habit'))
                                          _buildModernMenuButton(
                                            icon: Icons.spa_rounded,
                                            label: l10n.navHabits,
                                            color: Colors.green.shade400,
                                            desc: l10n.descHabits,
                                            onTap: () => _selectLifeOption(
                                                const HabitScreen(),
                                                l10n.navHabits),
                                            delay: 300,
                                            cs: cs,
                                          ),
                                        if (customNavButton != 'habit' &&
                                            isModuleEnabled('habit'))
                                          const SizedBox(height: 12),
                                        if (customNavButton != 'budget' &&
                                            isModuleEnabled('budget'))
                                          _buildModernMenuButton(
                                            icon: Icons
                                                .account_balance_wallet_rounded,
                                            label: 'Bütçe Takip',
                                            color: Colors.amber.shade700,
                                            desc:
                                                'Gelir ve giderlerinizi yönetin',
                                            onTap: () => _selectLifeOption(
                                                BudgetScreen(
                                                    onClose: () =>
                                                        _onItemTapped(0)),
                                                'Bütçe Takip'),
                                            delay: 350,
                                            cs: cs,
                                          ),
                                        if (customNavButton != 'budget' &&
                                            isModuleEnabled('budget'))
                                          const SizedBox(height: 12),
                                        if (customNavButton != 'teams' &&
                                            isModuleEnabled('teams'))
                                          _buildModernMenuButton(
                                            icon: Icons.groups_2_rounded,
                                            label: l10n.navTeams,
                                            color: Colors.blue.shade600,
                                            desc:
                                                'Ekiplerinizle işbirliği yapın',
                                            onTap: () => _onItemTapped(1),
                                            delay: 400,
                                            cs: cs,
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isWide)
                DailyIntelligencePanel(
                  onNotificationTap: () =>
                      _onSidebarItemSelected(12, null, l10n),
                ),
            ],
          ),
          bottomNavigationBar:
              isWide ? null : _buildPremiumNavBar(l10n, displayLifeTitle, cs),
        );
      },
    );
  }

  Widget _buildPremiumNavBar(
      AppLocalizations l10n, String displayLifeTitle, ColorScheme cs) {
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
                  ? Colors.black.withValues(alpha: 0.8)
                  : cs.surfaceContainerHigh.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: cs.outline.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: ModuleSettingsService.instance.customNavButton,
              builder: (context, customNavButton, child) {
                // Determine icon and label based on selection
                IconData navIcon = Icons.groups_2_outlined;
                IconData activeNavIcon = Icons.groups_2_rounded;
                String navLabel = l10n.navTeams;

                switch (customNavButton) {
                  case 'budget':
                    navIcon = Icons.account_balance_wallet_outlined;
                    activeNavIcon = Icons.account_balance_wallet_rounded;
                    navLabel = "Bütçe";
                    break;
                  case 'habit':
                    navIcon = Icons.spa_outlined;
                    activeNavIcon = Icons.spa_rounded;
                    navLabel = l10n.navHabits;
                    break;
                  case 'notes':
                    navIcon = Icons.note_alt_outlined;
                    activeNavIcon = Icons.note_alt_rounded;
                    navLabel = "Notlarım";
                    break;
                  case 'appointments':
                    navIcon = Icons.event_available_outlined;
                    activeNavIcon = Icons.event_available_rounded;
                    navLabel = l10n.navAppointments;
                    break;
                  case 'medications':
                    navIcon = Icons
                        .medication_liquid_sharp; // Approximating medication icon
                    activeNavIcon = Icons.medication_rounded;
                    navLabel = "İlaçlarım";
                    break;
                  case 'focus':
                    navIcon = Icons.timelapse_outlined;
                    activeNavIcon = Icons.timelapse_rounded;
                    navLabel = l10n.navFocus;
                    break;
                  case 'upcoming':
                    navIcon = Icons.upcoming_outlined;
                    activeNavIcon = Icons.upcoming_rounded;
                    navLabel = "Yaklaşanlar";
                    break;
                  case 'statistics':
                    navIcon = Icons.insights_outlined;
                    activeNavIcon = Icons.insights_rounded;
                    navLabel = l10n.navStatistics;
                    break;
                  case 'teams':
                  default:
                    navIcon = Icons.groups_2_outlined;
                    activeNavIcon = Icons.groups_2_rounded;
                    navLabel = l10n.navTeams;
                    break;
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.calendar_today_rounded,
                      activeIcon: Icons.calendar_month_rounded,
                      label: l10n.navCalendar,
                      index: 0,
                      cs: cs,
                    ),
                    _buildNavItem(
                      icon: navIcon,
                      activeIcon: activeNavIcon,
                      label: navLabel,
                      index: 1,
                      cs: cs,
                    ),
                    _buildNovaButton(cs),
                    _buildNavItem(
                      icon: _isMenuOpen
                          ? Icons.close_rounded
                          : Icons.bento_rounded,
                      activeIcon: Icons.bento_rounded,
                      label: displayLifeTitle,
                      index: 3,
                      isLifeMenu: true,
                      cs: cs,
                    ),
                    _buildNavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: l10n.navAccount,
                      index: 4,
                      cs: cs,
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

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required ColorScheme cs,
    bool isLifeMenu = false,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
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
                    ? cs.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.5),
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNovaButton(ColorScheme cs) {
    final isSelected = _selectedIndex == 2;

    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: AnimatedContainer(
        duration: PhobesTheme.animFast,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? PhobesTheme.primaryGradient
                    : LinearGradient(
                        colors: [
                          cs.primary.withValues(alpha: 0.2),
                          cs.secondary.withValues(alpha: 0.2),
                        ],
                      ),
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.auto_awesome,
                color: isSelected
                    ? cs.onPrimary
                    : cs.onSurface.withValues(alpha: 0.7),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nova',
              style: GoogleFonts.outfit(
                color: isSelected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMenuButton({
    required IconData icon,
    required String label,
    required String desc,
    required Color color,
    required VoidCallback onTap,
    required int delay,
    required ColorScheme cs,
  }) {
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
                      colors: [color, color.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
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
                      Text(
                        label,
                        style: GoogleFonts.outfit(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: GoogleFonts.outfit(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color.withValues(alpha: 0.5),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
