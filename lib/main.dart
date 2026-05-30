import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_links/app_links.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/app_bootstrapper.dart';
import 'core/navigation_keys.dart';
import 'core/material_icon_tree_shake_guard.dart';
import 'core/phobes_theme.dart';
import 'services/module_settings_service.dart';
import 'core/responsive.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/main_navigation_screen.dart';
import 'screens/auth/landing_screen.dart';
import 'l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/calendar/calendar_screen.dart';
import 'screens/chat/nova_chat_screen.dart';
import 'screens/habit/habit_screen.dart';
import 'screens/focus/focus_screen.dart';
import 'screens/budget/budget_screen.dart';
import 'screens/appointments/appointment_screen.dart';
import 'screens/notes/notes_screen.dart';
import 'screens/medication/medications_screen.dart';
import 'screens/calendar/upcoming_events_screen.dart';
import 'screens/home/statistics_screen.dart';
import 'screens/corkboard/corkboard_screen.dart';
import 'screens/books/books_screen.dart';
import 'screens/home/account_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'models/team_model.dart';
import 'screens/teams/team_detail_route_screen.dart';
import 'screens/teams/team_screen.dart';
import 'screens/common/maintenance_screen.dart';
import 'screens/common/survey_screen.dart';
import 'services/push_messaging_service.dart';

final GlobalKey<MainNavigationScreenState> mainNavKey =
    GlobalKey<MainNavigationScreenState>();

// Cold-start deep link kuyruğu: MainNavigationScreen hazır olmadan gelen
// linkleri depolar; ekran initState'te bu kuyruğu boşaltır.
final List<String> pendingDeepLinkActions = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web: Firebase JS must load before GoRouter redirect reads Firebase.apps.
  if (kIsWeb) {
    try {
      await AppBootstrapper.ensureFirebaseForWeb();
    } catch (e) {
      debugPrint('[main] Firebase web pre-init: $e');
    }
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      final stack = details.stack?.toString() ?? '';
      return Material(
        child: Container(
          color: Colors.red.shade900,
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: SingleChildScrollView(
              child: SelectableText(
                '${details.exceptionAsString()}\n\n$stack',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Material(
      child: Container(
        color: const Color(0xFF2D1B69),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Text(
          'Bir şeyler ters gitti. Lütfen uygulamayı yeniden başlatın.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  };

  GoogleFonts.config.allowRuntimeFetching = false;
  tz.initializeTimeZones();

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Tercihleri runApp'tan ÖNCE yükle ki ilk frame saved değerlerle render edilsin.
  // SharedPreferences web'de localStorage kullanır → senkron + hızlıdır.
  // Splash başlamadan tema/scale/sidebar/intelligence değerleri yerinde olur.
  try {
    await Future.wait([
      PhobesTheme.loadAllPreferences(),
      ModuleSettingsService.instance.init(),
    ]);
  } catch (e) {
    debugPrint('[main] Preference preload failed: $e');
  }

  runApp(const MyApp());
}

/// Called by PhobesSplashScreen. Delegates to AppBootstrapper.
Future<String?> initializeApp() async {
  final result = await AppBootstrapper.run();
  return result.errorMessage;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<MyAppState>();
  }

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Locale? _locale; // Null means follow system language
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  Locale? get locale => _locale;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    if (!kIsWeb) {
      _initAppLinks();
    }
    PushMessagingService.onNotificationTap = _handlePushTap;
  }

  void _handlePushTap(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final surveyId = data['surveyId']?.toString();
    if (type == 'survey' && surveyId != null && surveyId.isNotEmpty) {
      _router.push('/survey/$surveyId');
    }
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      setState(() {
        _locale = Locale(languageCode, '');
      });
    }
    // If null, MaterialApp will use the system locale by default
  }

  Future<void> setLocale(Locale newLocale) async {
    setState(() {
      _locale = newLocale;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
  }

  Future<void> _initAppLinks() async {
    _appLinks = AppLinks();
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleDeepLink(initialUri);
    } catch (e) {
      debugPrint('DeepLink Error: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'phobes') {
      final action = uri.host;
      if (mainNavKey.currentState != null) {
        mainNavKey.currentState!.handleDeepLink(action);
      } else {
        // Nav henüz hazır değil (splash ekranı sürerken cold-start).
        // Kuyruğa al; MainNavigationScreen.initState kuyruğu boşaltır.
        pendingDeepLinkActions.add(action);
      }
    }
  }

  late final GoRouter _router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: AppBootstrapState.instance,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const PhobesSplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => MaintenanceScreen(
          message: state.extra as String? ??
              'Uygulama şu anda bakımda. Lütfen daha sonra tekrar deneyin.',
        ),
      ),
      GoRoute(
        path: '/survey/:surveyId',
        builder: (context, state) => SurveyScreen(
          surveyId: state.pathParameters['surveyId']!,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationScreen(navigationChild: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/teams/:teamId',
            builder: (context, state) {
              final team = state.extra as Team?;
              final teamId = state.pathParameters['teamId']!;
              return TeamDetailRouteScreen(teamId: teamId, team: team);
            },
          ),
          GoRoute(
            path: '/teams',
            builder: (context, state) => const TeamScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const NovaChatScreen(),
          ),
          GoRoute(
            path: '/habits',
            builder: (context, state) => const HabitScreen(),
          ),
          GoRoute(
            path: '/focus',
            builder: (context, state) => const FocusScreen(),
          ),
          GoRoute(
            path: '/budget',
            builder: (context, state) => BudgetScreen(onClose: () => context.go('/')),
          ),
          GoRoute(
            path: '/appointments',
            builder: (context, state) => AppointmentScreen(onClose: () => context.go('/')),
          ),
          GoRoute(
            path: '/notes',
            builder: (context, state) => const NotesScreen(),
          ),
          GoRoute(
            path: '/medications',
            builder: (context, state) => MedicationsScreen(onClose: () => context.go('/')),
          ),
          GoRoute(
            path: '/upcoming',
            builder: (context, state) => const UpcomingEventsScreen(),
          ),
          GoRoute(
            path: '/statistics',
            builder: (context, state) => const StatisticsScreen(),
          ),
          GoRoute(
            path: '/corkboard',
            builder: (context, state) => const CorkboardScreen(),
          ),
          GoRoute(
            path: '/books',
            builder: (context, state) => BooksScreen(onClose: () => context.go('/')),
          ),
          GoRoute(
            path: '/teams/:teamId/corkboard',
            builder: (context, state) {
              final teamId = state.pathParameters['teamId'];
              return CorkboardScreen(teamId: teamId);
            },
          ),
          GoRoute(
            path: '/account',
            builder: (context, state) => const AccountScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      // Do not call Firebase.apps on web before the JS SDK is ready — mobile
      // Safari throws "Null check operator used on a null value" (gaHg/getApps).
      if (!AppBootstrapState.instance.firebaseReady) {
        return state.uri.path == '/splash' ? null : '/splash';
      }

      final bool loggedIn = FirebaseAuth.instance.currentUser != null;
      final bool loggingIn = state.uri.path == '/login';
      final bool splashing = state.uri.path == '/splash';

      final maintenance = state.uri.path == '/maintenance';
      final survey = state.uri.path.startsWith('/survey');
      if (maintenance) return null;
      if (survey && !loggedIn) return '/login';
      if (!loggedIn && !loggingIn && !splashing) return '/login';
      if (loggedIn && loggingIn) return '/';
      return null;
    },
  );

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        PhobesTheme.themeMode,
        PhobesTheme.amoledMode,
        PhobesTheme.userAccentColor,
        PhobesTheme.uiScale,
      ]),
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Phobes',
          debugShowCheckedModeBanner: false,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            scrollbars: false,
          ),
          locale: _locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (locale, supported) {
            if (locale == null) {
              return supported.firstWhere(
                (l) => l.languageCode == 'en',
                orElse: () => supported.first,
              );
            }
            for (final supportedLocale in supported) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
            return supported.firstWhere(
              (l) => l.languageCode == 'en',
              orElse: () => supported.first,
            );
          },
          themeMode: PhobesTheme.themeMode.value,
          theme: PhobesTheme.lightTheme,
          darkTheme: PhobesTheme.darkTheme,
          routerConfig: _router,
          builder: (context, child) {
            Widget wrapped = MaterialIconTreeShakeGuard(
              child: child ?? const SizedBox.shrink(),
            );
            if (kIsWeb || PhobesResponsive.isDesktopPlatform) {
              final mq = MediaQuery.of(context);
              wrapped = MediaQuery(
                data: mq.copyWith(
                  textScaler: mq.textScaler.clamp(
                    minScaleFactor: 1.0,
                    maxScaleFactor: 1.15,
                  ),
                ),
                child: wrapped,
              );
            }
            // Chrome benzeri zoom: layout + metin birlikte ölçeklenir.
            // FittedBox(BoxFit.fill) hem layout boyutunu hem de paint'i
            // ölçeklediği için scale > 1'de etrafa siyah kenar bırakmaz.
            final scale = PhobesTheme.uiScale.value;
            if (scale != 1.0) {
              final inner = wrapped;
              wrapped = LayoutBuilder(
                builder: (context, constraints) {
                  final actualW = constraints.maxWidth;
                  final actualH = constraints.maxHeight;
                  final logicalW = actualW / scale;
                  final logicalH = actualH / scale;
                  final mq = MediaQuery.of(context);
                  return ClipRect(
                    child: FittedBox(
                      fit: BoxFit.fill,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: logicalW,
                        height: logicalH,
                        child: MediaQuery(
                          data: mq.copyWith(
                            size: Size(logicalW, logicalH),
                            devicePixelRatio: mq.devicePixelRatio * scale,
                          ),
                          child: inner,
                        ),
                      ),
                    ),
                  );
                },
              );
            }
            return wrapped;
          },
        );
      },
    );
  }
}
