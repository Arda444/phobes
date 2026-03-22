import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/phobes_theme.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/smart_notification_service.dart';
import 'screens/home/main_navigation_screen.dart';
import 'screens/auth/landing_screen.dart';
import 'package:phobes/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app_links/app_links.dart';
import 'services/widget_service.dart';
import 'services/module_settings_service.dart';
import 'services/notification_settings_service.dart';
import 'dart:async';

final GlobalKey<MainNavigationScreenState> mainNavKey =
    GlobalKey<MainNavigationScreenState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initializationError;

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.web,
      );
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (!kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  } catch (e) {
    debugPrint("Firebase başlatılamadı veya ayarları güncellenemedi: $e");
    final errStr = e.toString().toLowerCase();
    // Yeniden başlatmalarda veya Web'de birden fazla sekme açıldığında persistence hatası verebilir, bunları göz ardı ediyoruz.
    if (!errStr.contains('duplicate-app') &&
        !errStr.contains('settings can no longer be changed') &&
        !errStr.contains('failed-precondition') &&
        !errStr.contains('persistence')) {
      initializationError = "Firebase Hatası: $e";
    }
  }

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint("Bildirim servisi başlatılamadı: $e");
  }

  try {
    await initializeDateFormatting();
  } catch (e) {
    debugPrint("Date formatting error: $e");
  }

  try {
    if (!kIsWeb) {
      await WidgetService.init();
    }
  } catch (e) {
    debugPrint("Widget service başlatılamadı: $e");
  }

  try {
    await ModuleSettingsService.instance.init();
    await NotificationSettingsService.instance.init();
    await PhobesTheme.loadAllPreferences();
  } catch (e) {
    debugPrint("Tema tercihleri yüklenemedi: $e");
  }

  if (initializationError != null) {
    runApp(ErrorApp(message: initializationError));
  } else {
    runApp(const MyApp());
  }
}

class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  "Uygulama Başlatılamadı",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
  Locale _locale = const Locale('tr', '');
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  Locale get locale => _locale;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _requestPermissions();
    _setupDailyNotifications();
    if (!kIsWeb) {
      _initAppLinks();
    }
  }

  Future<void> _initAppLinks() async {
    _appLinks = AppLinks();

    // Uygulama kapalıyken (cold start) widget'tan gelen intent'i kontrol et
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Initial AppLink Error: $e");
    }

    // Uygulama açıkken (background -> foreground or running) widget'tan gelen intent'i dinle
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("AppLink Stream Error: $err");
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint("Deep Link Received: $uri");
    if (uri.scheme == 'phobes') {
      final action = uri.host; // phobes:// URI yapısından dolayı
      _navigateToForm(action);
    }
  }

  void _navigateToForm(String action) {
    if (mainNavKey.currentState != null) {
      mainNavKey.currentState!.handleDeepLink(action);
    } else {
      debugPrint(
          "MainNavigationScreen is not mounted yet. Saving action to handle later.");
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    try {
      await NotificationService().requestPermissions();
    } catch (e) {
      debugPrint("Bildirim izni alınamadı: $e");
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
  }

  void _setupDailyNotifications() {
    try {
      SmartNotificationService().scheduleDailyNotifications();
    } catch (e) {
      debugPrint("Akıllı bildirim ayarlanamadı: $e");
    }
  }

  void setLocale(Locale newLocale) async {
    setState(() {
      _locale = newLocale;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: PhobesTheme.themeMode,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: PhobesTheme.amoledMode,
          builder: (context, _, __) {
            return ValueListenableBuilder<Color>(
              valueListenable: PhobesTheme.userAccentColor,
              builder: (context, _, __) {
                return MaterialApp(
                  title: 'Phobes',
                  debugShowCheckedModeBanner: false,
                  scrollBehavior: const MaterialScrollBehavior().copyWith(
                    scrollbars: false,
                  ),
                  locale: _locale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  themeMode: themeMode,
                  theme: PhobesTheme.lightTheme,
                  darkTheme: PhobesTheme.darkTheme,
                  home: StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(
                              color: PhobesTheme.userAccentColor.value,
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasData) {
                        return MainNavigationScreen(key: mainNavKey);
                      } else {
                        return const LandingScreen();
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
