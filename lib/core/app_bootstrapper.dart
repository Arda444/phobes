import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, kDebugMode, debugPrint, FlutterError;
import 'package:flutter/material.dart' show ChangeNotifier;

import 'package:intl/date_symbol_data_local.dart';

import '../firebase_options.dart';
import '../services/notification_service.dart';
import '../services/push_messaging_service.dart';
import '../services/smart_notification_service.dart';
import '../services/widget_service.dart';
import '../services/module_settings_service.dart';
import '../services/notification_settings_service.dart';
import 'phobes_theme.dart';
import 'safe_date_format.dart';

/// Tracks Firebase readiness without calling [Firebase.apps] before the web
/// JS SDK is injected (mobile Safari throws "Null check operator" otherwise).
class AppBootstrapState extends ChangeNotifier {
  AppBootstrapState._();
  static final AppBootstrapState instance = AppBootstrapState._();

  bool _firebaseReady = false;
  bool get firebaseReady => _firebaseReady;

  static void markFirebaseReady() {
    if (instance._firebaseReady) return;
    instance._firebaseReady = true;
    instance.notifyListeners();
  }
}

/// Result of the bootstrap process.
class BootstrapResult {
  final bool success;
  final String? errorMessage;
  final List<String> warnings;

  const BootstrapResult({
    required this.success,
    this.errorMessage,
    this.warnings = const [],
  });

  bool get hasWarnings => warnings.isNotEmpty;
}

/// Handles app startup in two parallel layers:
///
/// Layer 1 — runs immediately (no Firebase dependency):
///   • Date formatting locales
///   • Module/notification/theme preferences (SharedPreferences)
///   • Notification service setup
///   • Widget service (mobile only)
///
/// Layer 2 — runs concurrently with Layer 1:
///   • Firebase.initializeApp()
///   • Firestore persistence settings
///   • App Check activation (fire-and-forget)
///
/// Both layers run in parallel. The bootstrapper waits for both to complete
/// before returning, ensuring Firebase is ready before any screen uses it.
class AppBootstrapper {
  const AppBootstrapper._();

  static Future<BootstrapResult> run() async {
    final warnings = <String>[];

    // ── Layer 1: local / SharedPreferences tasks (no Firebase dependency) ──
    final localFuture = Future.wait([
      _initDateFormatting(),
      ModuleSettingsService.instance.init(),
      NotificationSettingsService.instance.init(),
      PhobesTheme.loadAllPreferences(),
      if (!kIsWeb) NotificationService().init(),
      if (!kIsWeb) WidgetService.init(),
    ],).catchError((e) {
      debugPrint('[Bootstrap] Local services error: $e');
      warnings.add('Yerel servisler başlatılamadı: $e');
      return <void>[];
    });

    // ── Layer 2: Firebase (must complete before any Firestore/Auth call) ───
    String? firebaseError;
    final firebaseFuture = _initFirebase().then((_) {
      _configureFirestore();
      _activateAppCheck(); // fire-and-forget
    }).catchError((e) {
      final msg = e.toString();
      if (!msg.toLowerCase().contains('duplicate-app')) {
        firebaseError = 'Firebase Hatası: $e';
      } else {
        AppBootstrapState.markFirebaseReady();
      }
      debugPrint('[Bootstrap] Firebase error: $e');
    });

    // Wait for both layers to finish
    await Future.wait([localFuture, firebaseFuture]);

    // Fire-and-forget post-init tasks (do not block splash).
    // flutter_local_notifications is unsupported on web (including mobile Safari).
    if (!kIsWeb) {
      NotificationService()
          .requestPermissions()
          .catchError((e) => debugPrint('[Bootstrap] Permission error: $e'));
      SmartNotificationService().scheduleDailyNotifications();
    }

    if (firebaseError != null) {
      return BootstrapResult(
        success: false,
        errorMessage: firebaseError,
        warnings: warnings,
      );
    }
    if (!kIsWeb && Firebase.apps.isNotEmpty) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      if (FirebaseAuth.instance.currentUser != null) {
        PushMessagingService.instance.init().catchError(
          (e) => debugPrint('[Bootstrap] FCM init: $e'),
        );
      }
    }
    return BootstrapResult(success: true, warnings: warnings);
  }

  /// Web-only: call from [main] before [runApp] so GoRouter never touches
  /// [Firebase.apps] while `firebase_core` JS is still undefined.
  static Future<void> ensureFirebaseForWeb() async {
    if (!kIsWeb || AppBootstrapState.instance.firebaseReady) return;
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    AppBootstrapState.markFirebaseReady();
  }

  static Future<void> _initFirebase() async {
    if (AppBootstrapState.instance.firebaseReady) return;
    if (kIsWeb) {
      await ensureFirebaseForWeb();
      return;
    }
    if (Firebase.apps.isNotEmpty) {
      AppBootstrapState.markFirebaseReady();
      return;
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppBootstrapState.markFirebaseReady();
  }

  static void _configureFirestore() {
    if (kIsWeb) {
      FirebaseFirestore.instance.settings =
          const Settings(persistenceEnabled: false);
    } else {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        // 50 MB — balanced between offline capability and low-storage devices.
        cacheSizeBytes: 52428800,
      );
    }
  }

  static void _activateAppCheck() {
    // Also enable "Enforce" for Firestore, Functions, and Storage in Firebase Console.
    const webKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');
    // Sideloaded iOS builds (free Apple ID) cannot use DeviceCheck/Play Integrity.
    const sideloadBuild = bool.fromEnvironment('SIDELOAD_BUILD');
    const useDebugAttestation = kDebugMode || sideloadBuild;
    if (kIsWeb) {
      if (webKey.isEmpty && !kDebugMode) {
        debugPrint(
          '[AppBootstrapper] RECAPTCHA_SITE_KEY missing — enable App Check in Firebase Console after setting --dart-define.',
        );
      }
      if (webKey.isNotEmpty) {
        FirebaseAppCheck.instance
            .activate(webProvider: ReCaptchaV3Provider(webKey))
            .catchError((e) => debugPrint('[Bootstrap] AppCheck Web: $e'));
      } else {
        debugPrint(
          '[Bootstrap] RECAPTCHA_SITE_KEY missing — web App Check disabled.',
        );
      }
    } else {
      FirebaseAppCheck.instance
          .activate(
            androidProvider: useDebugAttestation
                ? AndroidProvider.debug
                : AndroidProvider.playIntegrity,
            appleProvider: useDebugAttestation
                ? AppleProvider.debug
                : AppleProvider.deviceCheck,
          )
          .catchError((e) => debugPrint('[Bootstrap] AppCheck mobile: $e'));
    }
  }

  static Future<void> _initDateFormatting() async {
    // Every supported UI locale must be initialized. Partial init (tr/en only) caused
    // "Null check operator used on a null value" in intl DateFormat on mobile web
    // when the device language was de/fr/es/etc.
    await Future.wait(
      kAppDateLocaleCodes.map(
        (code) => initializeDateFormatting(code).catchError(
          (e) => debugPrint('[Bootstrap] DateFormat locale $code: $e'),
        ),
      ),
    );
  }
}
