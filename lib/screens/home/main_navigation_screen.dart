import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../main.dart' show pendingDeepLinkActions;
import '../../admin/admin_scaffold.dart';
import '../../admin/admin_guard.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:phobes/l10n/app_localizations.dart';
import '../../core/phobes_theme.dart';
import '../../core/phobes_shell_metrics.dart';
import '../../core/page_transitions.dart';

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
import '../../widgets/phobes_form_wrapper.dart';
import '../chat/nova_chat_screen.dart';
import 'account_screen.dart';
import 'statistics_screen.dart';
import '../budget/budget_screen.dart';
import '../corkboard/corkboard_screen.dart';
import '../books/books_screen.dart';
import '../teams/team_detail_screen.dart';
import '../../models/team_model.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../services/module_settings_service.dart';
import '../../widgets/phobes_widgets.dart';
import '../../services/home_widget_updater.dart';
import '../../services/admin_access_service.dart';
import '../../widgets/home/premium_nav_bar.dart';
import '../../widgets/home/responsive_layout_widgets.dart';
import '../common/announcement_banner.dart';
import '../common/broadcast_popup.dart';
import '../../services/push_messaging_service.dart';

class MainNavigationScreen extends StatefulWidget {
  final Widget? navigationChild;
  const MainNavigationScreen({super.key, this.child, this.navigationChild});

  // Alias for GoRouter's shell child
  final Widget? child;

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
  bool _isAdmin = false;

  Widget _currentLifeWidget = const NotesScreen();
  String? _lifeTitle;
  final FirebaseService _firebaseService = FirebaseService();

  late List<Widget> _widgetOptions;
  late AnimationController _menuAnimController;
  late Animation<double> _menuAnimation;
  late final Stream<DocumentSnapshot> _userDataStream;
  final GlobalKey<ScaffoldState> _shellScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    ModuleSettingsService.instance.customNavButton
        .addListener(_onSettingsChanged);
    ModuleSettingsService.instance.disabledModules
        .addListener(_onSettingsChanged);
    _updateWidgetOptions();
    _userDataStream =
        _firebaseService.getUserDataStream().asBroadcastStream();
    _menuAnimController = AnimationController(
      duration: PhobesTheme.animNormal,
      vsync: this,
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuAnimController,
      curve: PhobesTheme.curveDefault,
    );

    _checkAdminStatus();
    HomeWidgetUpdater.instance.updateAll();
    _flushPendingDeepLinks();
    if (!kIsWeb) {
      PushMessagingService.instance.init();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybeShowBroadcastPopup(context);
    });
  }

  void _flushPendingDeepLinks() {
    if (pendingDeepLinkActions.isEmpty) return;
    final actions = List<String>.from(pendingDeepLinkActions);
    pendingDeepLinkActions.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final action in actions) {
        handleDeepLink(action);
      }
    });
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await AdminAccessService.instance.isCurrentUserAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  Future<void> _signOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final confirmed = await PhobesBottomSheet.confirm(
      context: context,
      title: l10n!.signOut,
      message: l10n.signOutConfirmation,
      confirmText: l10n.signOut,
      confirmColor: Colors.redAccent,
    );
    if (confirmed != true) return;
    await AuthService().signOut();
    router.go('/login');
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
      case 'books':
        customScreen = BooksScreen(onClose: () => _onItemTapped(0));
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
    ];
  }

  String _pathForCustomNavButton() {
    final key = ModuleSettingsService.instance.customNavButton.value;
    return switch (key) {
      'budget' => '/budget',
      'habit' => '/habit',
      'notes' => '/notes',
      'appointments' => '/appointments',
      'medications' => '/medications',
      'focus' => '/focus',
      'upcoming' => '/upcoming',
      'statistics' => '/statistics',
      'corkboard' => '/corkboard',
      'books' => '/books',
      _ => '/teams',
    };
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

    // Map index to GoRouter path
    String path = '/';
    switch (index) {
      case 0:
        path = '/';
        break;
      case 1:
        path = _pathForCustomNavButton();
        break;
      case 2:
        path = '/chat';
        break;
      case 4:
        path = '/account';
        break;
      case 5:
        path = '/notifications';
        break;
    }

    if (context.mounted) {
      context.go(path);
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
    final l10n = AppLocalizations.of(context)!;

    switch (action) {
      case 'add_task':
        PhobesFormWrapper.show(
          context,
          title: l10n.featAddTask,
          form: TaskAddEditScreen(selectedDate: DateTime.now()),
        );
        break;
      case 'add_expense':
        _selectLifeOption(
          '/budget',
          l10n.featBudgetManagement,
          BudgetScreen(onClose: () => _onItemTapped(0)),
        );
        break;
      case 'add_medication':
        _selectLifeOption(
          '/medications',
          l10n.navMedications,
          MedicationsScreen(onClose: () => _onItemTapped(0)),
        );
        break;
      case 'add_note':
        _selectLifeOption('/notes', l10n.noteMyNotes, const NotesScreen());
        break;
    }
  }

  void _selectLifeOption(String path, String title, [Widget? widget]) {
    if (context.mounted) {
      context.go(path);
    }
    setState(() {
      if (widget != null) {
        _currentLifeWidget = widget;
      }
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
      if (context.mounted && kIsWeb) {
        context.go('/teams');
        return;
      }
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
      _selectLifeOption('/habits', l10n.navHabits, const HabitScreen());
    } else if (index == 4) {
      _selectLifeOption('/focus', l10n.navFocus, const FocusScreen());
    } else if (index == 5) {
      _selectLifeOption('/budget', l10n.featBudgetManagement, const BudgetScreen());
    } else if (index == 6) {
      _selectLifeOption('/appointments', l10n.navAppointments, const AppointmentScreen());
    } else if (index == 7) {
      _selectLifeOption('/notes', l10n.noteMyNotes, const NotesScreen());
    } else if (index == 8) {
      _selectLifeOption('/medications', l10n.navMedications, const MedicationsScreen());
    } else if (index == 9) {
      _selectLifeOption(
          '/upcoming', l10n.navUpcomingEvents, const UpcomingEventsScreen(),);
    } else if (index == 10) {
      _selectLifeOption('/statistics', l10n.navStatistics, const StatisticsScreen());
    } else if (index == 14) {
      _selectLifeOption(
        '/corkboard',
        l10n.corkboardPersonalTitle,
        const CorkboardScreen(),
      );
    } else if (index == 15) {
      _selectLifeOption(
        '/books',
        l10n.moduleNameBooks,
        const BooksScreen(),
      );
    } else if (index == 11) {
      _onItemTapped(4);
    } else if (index == 12) {
      setState(() {
        _selectedIndex = 5;
        _visualIndex = 5;
        _isMenuOpen = false;
      });
    }

    if (index != 1) {
      setState(() => _selectedSubIndex = -1);
    }
  }

  int _getSidebarSelectedIndex() {
    // Route'u kontrol et — GoRouter kullanıldığında en güvenilir yöntem
    try {
      if (context.mounted) {
        final location = GoRouterState.of(context).uri.path;
        if (location == '/')                    return 0;
        if (location.startsWith('/teams'))      return 1;
        if (location == '/chat')                return 2;
        if (location == '/habits')              return 3;
        if (location == '/focus')               return 4;
        if (location == '/budget')              return 5;
        if (location == '/appointments')        return 6;
        if (location == '/notes')               return 7;
        if (location == '/medications')         return 8;
        if (location == '/upcoming')            return 9;
        if (location == '/statistics')          return 10;
        if (location == '/account')             return 11;
        if (location == '/notifications')       return 12;
        if (location == '/corkboard')           return 14;
        if (location == '/books')               return 15;
      }
    } catch (_) { /* GoRouterState mevcut değil */ }

    // Mobil: IndexedStack + life widget'a göre
    if (_visualIndex == 0) return 0;
    if (_visualIndex == 1) return 1;
    if (_visualIndex == 2) return 2;
    if (_visualIndex == 4) return 11;
    if (_visualIndex == 5) return 12;

    if (_currentLifeWidget is HabitScreen)         return 3;
    if (_currentLifeWidget is FocusScreen)         return 4;
    if (_currentLifeWidget is BudgetScreen)        return 5;
    if (_currentLifeWidget is AppointmentScreen)   return 6;
    if (_currentLifeWidget is NotesScreen)         return 7;
    if (_currentLifeWidget is MedicationsScreen)   return 8;
    if (_currentLifeWidget is UpcomingEventsScreen) return 9;
    if (_currentLifeWidget is StatisticsScreen)    return 10;
    if (_currentLifeWidget is CorkboardScreen)     return 14;
    if (_currentLifeWidget is BooksScreen)         return 15;

    return 0;
  }

  int _getBottomBarIndex() {
    if (_isMenuOpen) return 3;
    final sidebarIdx = _getSidebarSelectedIndex();
    if (sidebarIdx == 0) return 0; // Calendar
    if (sidebarIdx == 1) return 1; // Teams
    if (sidebarIdx == 2) return 2; // Nova
    if (sidebarIdx == 11) return 4; // Account
    // Diğer tüm modüller (3,4,5,6,7,8,9,10,14,15) 3. index (Bento/Life) altında toplanır
    if (sidebarIdx >= 3 && sidebarIdx <= 15) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;
    final displayLifeTitle = _selectedIndex == 3 && !_isMenuOpen
        ? (_lifeTitle ?? l10n.navLife)
        : l10n.navLife;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<bool>(
          valueListenable:
              ModuleSettingsService.instance.intelligencePanelEnabled,
          builder: (context, intelligenceEnabled, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: ModuleSettingsService.instance.sidebarCollapsed,
              builder: (context, sidebarCollapsedPref, _) {
                final sidebarIconOnly = kIsWeb && sidebarCollapsedPref;
                final shell = PhobesShellMetrics.fromWidth(
                  constraints.maxWidth,
                  sidebarCollapsed: sidebarIconOnly,
                  intelligencePanelEnabled: intelligenceEnabled,
                );
                final showSidebar = shell.showSidebar;
                return _buildShellScaffold(
                  context: context,
                  constraints: constraints,
                  shell: shell,
                  showSidebar: showSidebar,
                  sidebarIconOnly: sidebarIconOnly,
                  l10n: l10n,
                  cs: cs,
                  isDark: isDark,
                  isAmoled: isAmoled,
                  displayLifeTitle: displayLifeTitle,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildShellScaffold({
    required BuildContext context,
    required BoxConstraints constraints,
    required PhobesShellMetrics shell,
    required bool showSidebar,
    required bool sidebarIconOnly,
    required AppLocalizations l10n,
    required ColorScheme cs,
    required bool isDark,
    required bool isAmoled,
    required String displayLifeTitle,
  }) {
    Widget intelligencePanel({required double width}) =>
            DailyIntelligencePanel(
              width: width,
              compactTypography: shell.useCompactIntelligenceTypography,
              onNotificationTap: () => PhobesPageRoute.pushResponsive(
                context,
                const NotificationsScreen(),
              ),
            );

    return Scaffold(
          key: _shellScaffoldKey,
          backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
          extendBody: true,
          body: Column(
            children: [
              const AnnouncementBanner(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showSidebar)
                      ValueListenableBuilder<List<String>>(
                        valueListenable:
                            ModuleSettingsService.instance.disabledModules,
                        builder: (context, disabledModules, child) {
                          bool isModuleEnabled(String id) =>
                              !disabledModules.contains(id);
                          final availableSidebarItems = <SidebarItemData>[
                            if (isModuleEnabled('calendar'))
                              SidebarItemData(
                                icon: Icons.calendar_month_rounded,
                                label: l10n.navCalendar,
                              ),
                            if (isModuleEnabled('teams'))
                              SidebarItemData(
                                icon: Icons.groups_2_rounded,
                                label: l10n.navTeams,
                              ),
                            if (isModuleEnabled('chat'))
                              SidebarItemData(
                                icon: Icons.auto_awesome,
                                label: l10n.novaAssistant,
                              ),
                            if (isModuleEnabled('habit'))
                              SidebarItemData(
                                icon: Icons.spa_rounded,
                                label: l10n.navHabits,
                              ),
                            if (isModuleEnabled('focus'))
                              SidebarItemData(
                                icon: Icons.timelapse_rounded,
                                label: l10n.navFocus,
                              ),
                            if (isModuleEnabled('budget'))
                              SidebarItemData(
                                icon: Icons.account_balance_wallet_rounded,
                                label: l10n.featBudgetManagement,
                              ),
                            if (isModuleEnabled('appointments'))
                              SidebarItemData(
                                icon: Icons.event_available_rounded,
                                label: l10n.navAppointments,
                              ),
                            if (isModuleEnabled('notes'))
                              SidebarItemData(
                                icon: Icons.note_alt_rounded,
                                label: l10n.noteMyNotes,
                              ),
                            if (isModuleEnabled('medications'))
                              SidebarItemData(
                                icon: Icons.medication_rounded,
                                label: l10n.navMedications,
                              ),
                            if (isModuleEnabled('upcoming'))
                              SidebarItemData(
                                icon: Icons.upcoming_rounded,
                                label: l10n.navUpcomingEvents,
                              ),
                            if (isModuleEnabled('statistics'))
                              SidebarItemData(
                                icon: Icons.insights_rounded,
                                label: l10n.navStatistics,
                              ),
                            if (isModuleEnabled('corkboard'))
                              SidebarItemData(
                                icon: Icons.dashboard_customize_rounded,
                                label: l10n.corkboardPersonalTitle,
                              ),
                            if (isModuleEnabled('books'))
                              SidebarItemData(
                                icon: Icons.menu_book_rounded,
                                label: l10n.moduleNameBooks,
                              ),
                            if (!kIsWeb)
                              SidebarItemData(
                                icon: Icons.person_rounded,
                                label: l10n.navAccount,
                              ),

                            if (_isAdmin)
                              SidebarItemData(
                                icon: Icons.admin_panel_settings,
                                label: l10n.adminPanelTitle,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AdminGuard(
                                        child: AdminScaffold(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ];

                          int mapSidebarIndex(int newIndex) {
                            final label = availableSidebarItems[newIndex].label;
                            if (label == l10n.navCalendar) return 0;
                            if (label == l10n.navTeams) return 1;
                            if (label == l10n.novaAssistant) return 2;
                            if (label == l10n.navHabits) return 3;
                            if (label == l10n.navFocus) return 4;
                            if (label == l10n.featBudgetManagement) return 5;
                            if (label == l10n.navAppointments) return 6;
                            if (label == l10n.noteMyNotes) return 7;
                            if (label == l10n.navMedications) return 8;
                            if (label == l10n.navUpcomingEvents) return 9;
                            if (label == l10n.navStatistics) return 10;
                            if (label == l10n.corkboardPersonalTitle) return 14;
                            if (label == l10n.moduleNameBooks) return 15;
                            if (label == l10n.navAccount) return 11;

                            return 0;
                          }

                          // -1: hiçbir öğe seçili değil. Web'de "Account" sidebar
                          // listesinde yok (footer'da), bu yüzden /account
                          // rotasında eşleşme bulunmadığında varsayılan 0
                          // (Takvim) seçili görünmesini engelliyoruz.
                          int selectedMappedIndex = -1;
                          for (int i = 0;
                              i < availableSidebarItems.length;
                              i++) {
                            if (mapSidebarIndex(i) ==
                                _getSidebarSelectedIndex()) {
                              selectedMappedIndex = i;
                              break;
                            }
                          }

                          Widget sidebarLogo() => Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: PhobesTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'P',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              );

                          Widget collapseButton({bool compact = false}) {
                            void toggle() {
                              final svc = ModuleSettingsService.instance;
                              svc.setSidebarCollapsed(
                                !svc.sidebarCollapsed.value,
                              );
                            }

                            return Tooltip(
                              message: sidebarIconOnly
                                  ? l10n.sidebarExpand
                                  : l10n.sidebarCollapse,
                              child: IconButton(
                                onPressed: toggle,
                                icon: Icon(
                                  sidebarIconOnly
                                      ? Icons
                                          .keyboard_double_arrow_right_rounded
                                      : Icons
                                          .keyboard_double_arrow_left_rounded,
                                  size: compact ? 20 : 22,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      cs.onSurface.withOpacity(0.06),
                                  foregroundColor:
                                      cs.onSurface.withOpacity(0.65),
                                  minimumSize:
                                      Size(compact ? 32 : 36, compact ? 32 : 36),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            );
                          }

                          Widget? webFooter;
                          if (kIsWeb) {
                            webFooter = StreamBuilder<DocumentSnapshot>(
                              stream: _userDataStream,
                              builder: (context, snap) {
                                var name = '';
                                String? photoUrl;
                                var xp = 0;
                                if (snap.hasData && snap.data!.exists) {
                                  final data = snap.data!.data()
                                      as Map<String, dynamic>?;
                                  if (data != null) {
                                    name =
                                        '${data['name'] ?? ''} ${data['surname'] ?? ''}'
                                            .trim();
                                    photoUrl = data['photoUrl'] as String?;
                                    xp = (data['xp'] as num?)?.toInt() ?? 0;
                                  }
                                }
                                if (name.isEmpty) {
                                  name = FirebaseAuth
                                          .instance.currentUser?.displayName ??
                                      '';
                                }
                                photoUrl ??=
                                    FirebaseAuth.instance.currentUser?.photoURL;

                                return SidebarUserFooter(
                                  displayName: name,
                                  photoUrl: photoUrl,
                                  xp: xp,
                                  iconOnly: sidebarIconOnly,
                                  isAccountSelected:
                                      _getSidebarSelectedIndex() == 11,
                                  onAccountTap: () => context.go('/account'),
                                  onSignOut: () => _signOut(context),
                                  signOutTooltip: l10n.signOut,
                                );
                              },
                            );
                          }

                          return NavigationSidebar(
                            width: shell.sidebarWidth,
                            iconOnly: sidebarIconOnly,
                            footer: webFooter,
                            selectedIndex: selectedMappedIndex,
                            selectedSubIndex: _selectedSubIndex,
                            onItemSelected: (idx, subIdx) {
                              final mappedIndex = mapSidebarIndex(idx);
                              if (kIsWeb) {
                                switch (mappedIndex) {
                                  case 0:
                                    context.go('/');
                                    break;
                                  case 1:
                                    context.go('/teams');
                                    break;
                                  case 2:
                                    context.go('/chat');
                                    break;
                                  case 3:
                                    context.go('/habits');
                                    break;
                                  case 4:
                                    context.go('/focus');
                                    break;
                                  case 5:
                                    context.go('/budget');
                                    break;
                                  case 6:
                                    context.go('/appointments');
                                    break;
                                  case 7:
                                    context.go('/notes');
                                    break;
                                  case 8:
                                    context.go('/medications');
                                    break;
                                  case 9:
                                    context.go('/upcoming');
                                    break;
                                  case 10:
                                    context.go('/statistics');
                                    break;
                                  case 14:
                                    context.go('/corkboard');
                                    break;
                                  case 15:
                                    context.go('/books');
                                    break;
                                  case 11:
                                    context.go('/account');
                                    break;
                                }
                              } else {
                                _onSidebarItemSelected(
                                    mappedIndex, subIdx, l10n);
                              }
                            },
                            header: sidebarIconOnly
                                ? Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(8, 16, 8, 0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Center(child: sidebarLogo()),
                                        if (kIsWeb) ...[
                                          const SizedBox(height: 8),
                                          collapseButton(compact: true),
                                        ],
                                      ],
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 20, 12, 0,),
                                    child: Row(
                                      children: [
                                        sidebarLogo(),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Phobes',
                                            style: GoogleFonts.outfit(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                        ),
                                        if (kIsWeb) collapseButton(),
                                      ],
                                    ),
                                  ),
                            items: availableSidebarItems,
                            signOutLabel: kIsWeb ? null : l10n.signOut,
                            onSignOut:
                                kIsWeb ? null : () => _signOut(context),
                          );
                        },
                      ),
                    Expanded(
                      child: Stack(
                        children: [
                          (widget.navigationChild ?? widget.child) != null
                              ? (widget.navigationChild ?? widget.child)!
                              : IndexedStack(
                                  index: (_visualIndex == 1 &&
                                          _selectedTeam != null &&
                                          _selectedSubIndex != -1)
                                      ? 6
                                      : _visualIndex,
                                  children: [
                                    ..._widgetOptions,
                                    _selectedTeam != null
                                        ? TeamDetailScreen(
                                            key: ValueKey(_selectedTeam!.id),
                                            team: _selectedTeam!,
                                            externalIndex: _selectedSubIndex,
                                          )
                                        : const SizedBox.shrink(),
                                  ],
                                ),
                          if (_isMenuOpen && !showSidebar)
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
                                child: ClipRect(
                                  child: BackdropFilter(
                                    filter:
                                        ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: Container(
                                      color: (isAmoled && isDark
                                              ? Colors.black
                                              : cs.surface)
                                          .withOpacity(0.7),
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (_isMenuOpen && !showSidebar)
                            Positioned(
                              bottom: 100,
                              right: 20,
                              left: 20,
                              top: MediaQuery.of(context).padding.top + 80,
                              child: SingleChildScrollView(
                                reverse: true,
                                physics: const BouncingScrollPhysics(),
                                child: ValueListenableBuilder<List<String>>(
                                  valueListenable: ModuleSettingsService
                                      .instance.disabledModules,
                                  builder: (context, disabledModules, child) {
                                    bool isModuleEnabled(String id) =>
                                        !disabledModules.contains(id);
                                    return ValueListenableBuilder<String>(
                                      valueListenable: ModuleSettingsService
                                          .instance.customNavButton,
                                      builder:
                                          (context, customNavButton, child) {
                                        return Align(
                                          alignment: Alignment.bottomRight,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              if (customNavButton !=
                                                      'statistics' &&
                                                  isModuleEnabled('statistics'))
                                                NavMenuButton(
                                                  icon: Icons.insights_rounded,
                                                  label: l10n.navStatistics,
                                                  color: Colors.purple.shade300,
                                                  desc: l10n.descStats,
                                                  onTap: () =>
                                                      _selectLifeOption(
                                                    '/statistics',
                                                    l10n.navStatistics,
                                                    const StatisticsScreen(),
                                                  ),
                                                  delay: 0,
                                                ),
                                              if (isModuleEnabled('corkboard'))
                                                const SizedBox(height: 12),
                                              if (isModuleEnabled('corkboard'))
                                                NavMenuButton(
                                                  icon: Icons
                                                      .dashboard_customize_rounded,
                                                  label: l10n.corkboardPersonalTitle,
                                                  color: Colors.deepPurple.shade300,
                                                  desc: l10n.corkboardSubtitleDefault,
                                                  onTap: () =>
                                                      _selectLifeOption(
                                                    '/corkboard',
                                                    l10n.corkboardPersonalTitle,
                                                    const CorkboardScreen(),
                                                  ),
                                                  delay: 25,
                                                ),
                                              if (customNavButton != 'books' &&
                                                  isModuleEnabled('books'))
                                                const SizedBox(height: 12),
                                              if (customNavButton != 'books' &&
                                                  isModuleEnabled('books'))
                                                NavMenuButton(
                                                  icon: Icons
                                                      .menu_book_rounded,
                                                  label: l10n.moduleNameBooks,
                                                  color: Colors.brown.shade400,
                                                  desc: l10n.descBooks,
                                                  onTap: () =>
                                                      _selectLifeOption(
                                                    '/books',
                                                    l10n.moduleNameBooks,
                                                    BooksScreen(
                                                      onClose: () =>
                                                          _onItemTapped(0),
                                                    ),
                                                  ),
                                                  delay: 35,
                                                ),
                                              if (customNavButton !=
                                                      'statistics' &&
                                                  isModuleEnabled('statistics'))
                                                const SizedBox(height: 12),
                                              if (customNavButton !=
                                                      'upcoming' &&
                                                  isModuleEnabled('upcoming'))
                                                NavMenuButton(
                                                  icon: Icons.upcoming_rounded,
                                                  label: l10n.navUpcomingEvents,
                                                  color: Colors.pink.shade400,
                                                  desc: l10n.descUpcomingEvents,
                                                  onTap: () =>
                                                      _selectLifeOption(
                                                    '/upcoming',
                                                    l10n.navUpcomingEvents,
                                                    const UpcomingEventsScreen(),
                                                  ),
                                                  delay: 50,
                                                ),
                                              if (customNavButton !=
                                                      'upcoming' &&
                                                  isModuleEnabled('upcoming'))
                                                const SizedBox(height: 12),
                                              if (customNavButton != 'focus' &&
                                                  isModuleEnabled('focus'))
                                                NavMenuButton(
                                                  icon: Icons.timelapse_rounded,
                                                  label: l10n.navFocus,
                                                  color: Colors
                                                      .deepOrange.shade400,
                                                  desc: l10n.descFocus,
                                                  onTap: () =>
                                                      _selectLifeOption(
                                                    '/focus',
                                                    l10n.navFocus,
                                                    const FocusScreen(),
                                                  ),
                                                  delay: 100,
                                                ),
                                              if (customNavButton != 'focus' &&
                                                  isModuleEnabled('focus'))
                                                const SizedBox(height: 12),
                                              if (customNavButton !=
                                                      'medications' &&
                                                  isModuleEnabled(
                                                      'medications'))
                                                NavMenuButton(
                                                  icon:
                                                      Icons.medication_rounded,
                                                  label: l10n.navMedications,
                                                  color: Colors.teal.shade400,
                                                  desc: l10n.descMedications,
                                                  onTap: () =>
                                                      _selectLifeOption(
                                                    '/medications',
                                                    l10n.navMedications,
                                                    MedicationsScreen(
                                                      onClose: () =>
                                                          _onItemTapped(0),
                                                    ),
                                                  ),
                                                  delay: 150,
                                                ),
                                              if (customNavButton !=
                                                      'medications' &&
                                                  isModuleEnabled(
                                                      'medications'))
                                                const SizedBox(height: 12),
                                              if (customNavButton !=
                                                      'appointments' &&
                                                  isModuleEnabled(
                                                      'appointments'))
                                                NavMenuButton(
                                                  icon: Icons
                                                      .event_available_rounded,
                                                  label: l10n.navAppointments,
                                                  color: Colors.cyan.shade400,
                                                  desc: l10n.descAppointments,
                                                  onTap: () =>
                                                      _selectLifeOption(
                                                    '/appointments',
                                                    l10n.navAppointments,
                                                    AppointmentScreen(
                                                      onClose: () =>
                                                          _onItemTapped(0),
                                                    ),
                                                  ),
                                                  delay: 200,
                                                ),
                                              if (customNavButton !=
                                                      'appointments' &&
                                                  isModuleEnabled(
                                                      'appointments'))
                                                const SizedBox(height: 12),
                                              if (customNavButton != 'notes' &&
                                                  isModuleEnabled('notes'))
                                                NavMenuButton(
                                                  icon: Icons.note_alt_rounded,
                                                  label: l10n.noteMyNotes,
                                                  color: Colors.indigo.shade400,
                                                  desc: l10n.descNotes,
                                                  onTap: () =>
                                                      _selectLifeOption(
                                                    '/notes',
                                                    l10n.noteMyNotes,
                                                    const NotesScreen(),
                                                  ),
                                                  delay: 250,
                                                ),
                                              if (customNavButton != 'notes' &&
                                                  isModuleEnabled('notes'))
                                                const SizedBox(height: 12),
                                              if (customNavButton != 'habit' &&
                                                  isModuleEnabled('habit'))
                                                NavMenuButton(
                                                  icon: Icons.spa_rounded,
                                                  label: l10n.navHabits,
                                                  color: Colors.green.shade400,
                                                  desc: l10n.descHabits,
                                                  onTap: () =>
                                                      _selectLifeOption(
                                                    '/habits',
                                                    l10n.navHabits,
                                                    const HabitScreen(),
                                                  ),
                                                  delay: 300,
                                                ),
                                              if (customNavButton != 'habit' &&
                                                  isModuleEnabled('habit'))
                                                const SizedBox(height: 12),
                                              if (customNavButton != 'budget' &&
                                                  isModuleEnabled('budget'))
                                                NavMenuButton(
                                                  icon: Icons
                                                      .account_balance_wallet_rounded,
                                                  label: l10n.featBudgetManagement,
                                                  color: Colors.amber.shade700,
                                                  desc: l10n.featBudgetManagementDesc,
                                                  onTap: () =>
                                                      _selectLifeOption(
                                                    '/budget',
                                                    l10n.featBudgetManagement,
                                                    BudgetScreen(
                                                      onClose: () =>
                                                          _onItemTapped(0),
                                                    ),
                                                  ),
                                                  delay: 350,
                                                ),
                                              if (customNavButton != 'budget' &&
                                                  isModuleEnabled('budget'))
                                                const SizedBox(height: 12),
                                              if (customNavButton != 'teams' &&
                                                  isModuleEnabled('teams'))
                                                NavMenuButton(
                                                  icon: Icons.groups_2_rounded,
                                                  label: l10n.navTeams,
                                                  color: Colors.blue.shade600,
                                                  desc: l10n.descTeams,
                                                  onTap: () => _onItemTapped(1),
                                                  delay: 400,
                                                ),
                                              if (_isAdmin) ...[
                                                const SizedBox(height: 12),
                                                NavMenuButton(
                                                  icon: Icons
                                                      .admin_panel_settings_rounded,
                                                  label: l10n.adminPanelTitle,
                                                  color: Colors.red.shade600,
                                                  desc: l10n.adminPanelDesc,
                                                  onTap: () {
                                                    setState(
                                                      () => _isMenuOpen = false,
                                                    );
                                                    _menuAnimController
                                                        .reverse();
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const AdminGuard(
                                                          child:
                                                              AdminScaffold(),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  delay: 450,
                                                ),
                                              ],
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
                    if (shell.showIntelligencePanel)
                      intelligencePanel(width: shell.intelligencePanelWidth),
                  ],
                ),
              ), // Expanded
            ],
          ), // Column
          bottomNavigationBar: showSidebar
              ? null
              : PremiumNavBar(
                  selectedIndex: _getBottomBarIndex(),
                  isMenuOpen: _isMenuOpen,
                  displayLifeTitle: displayLifeTitle,
                  onItemTapped: _onItemTapped,
                ),
    );
  }
}
