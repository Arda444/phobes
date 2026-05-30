import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../core/app_bootstrapper.dart';
import '../../core/phobes_theme.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/admin_access_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PhobesSplashScreen extends StatefulWidget {
  const PhobesSplashScreen({super.key});

  @override
  State<PhobesSplashScreen> createState() => _PhobesSplashScreenState();
}

class _PhobesSplashScreenState extends State<PhobesSplashScreen> {
  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    String? initError;
    try {
      initError = await initializeApp().timeout(
        const Duration(seconds: 60),
        onTimeout: () => 'Timeout',
      );
    } catch (e) {
      initError = e.toString();
    }

    if (initError != null) debugPrint('Init Error: $initError');

    if (initError == 'Timeout') {
      await Future.wait([
        initializeDateFormatting('en'),
        initializeDateFormatting('tr'),
      ]).catchError((_) => <void>[]);
    }

    // Guard: if Firebase didn't initialize (e.g. timeout before init completed),
    // skip the auth check and send the user to the login screen.
    if (!AppBootstrapState.instance.firebaseReady) {
      if (!mounted) return;
      context.go('/login');
      return;
    }

    // Web'de Firebase Auth oturumu IndexedDB/localStorage'dan asenkron yüklenir.
    // authStateChanges().first → hydration sonrası ilk yayılan değeri bekler:
    //   - Oturum açıksa User, açık değilse null döner.
    // where() filtresi kullanmıyoruz; filtre null'ı atlayarak timeout'u tetikleyebilir.
    final authFuture = FirebaseAuth.instance.currentUser != null
        ? Future.value(FirebaseAuth.instance.currentUser)
        : FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(const Duration(milliseconds: 5000), onTimeout: () => null);

    // Splash animasyonu için minimum bekleme (authFuture ile paralel)
    await Future.delayed(const Duration(milliseconds: 2000));

    User? user;
    try {
      user = await authFuture;
    } catch (e) {
      debugPrint('Auth hydration error: $e');
    }
    // Son çare: hydration tamamlandıysa currentUser artık dolu olabilir
    user ??= FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    // Bakım modu ve ban kontrolü
    if (user != null) {
      try {
        // Bakım modu kontrolü (admin değilse göster)
        final configSnap = await FirebaseFirestore.instance
            .collection('appConfig')
            .doc('main')
            .get()
            .timeout(const Duration(seconds: 4),
                onTimeout: () => throw Exception('timeout'),);
        final config = configSnap.data() ?? {};
        final isMaintenance = config['maintenanceMode'] == true;

        // Admin claim kontrolü
        final isAdmin = await AdminAccessService.instance
            .isCurrentUserAdmin()
            .timeout(const Duration(seconds: 5), onTimeout: () => false);

        if (isMaintenance && !isAdmin) {
          if (!mounted) return;
          final msg = config['maintenanceMessage'] as String? ??
              'Uygulama şu anda bakımda.';
          context.go('/maintenance', extra: msg);
          return;
        }

        final accessAllowed = await AuthService()
            .recordSessionStart()
            .timeout(const Duration(seconds: 10), onTimeout: () => false);
        if (!accessAllowed) {
          if (!mounted) return;
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          context.go('/login');
          return;
        }

        final forceUpdate = config['forceUpdate'] == true;
        final requiredVersion = config['currentVersion'] as String?;
        if (forceUpdate && requiredVersion != null && requiredVersion.isNotEmpty) {
          try {
            final info = await PackageInfo.fromPlatform();
            if (info.version != requiredVersion) {
              if (!mounted) return;
              context.go('/login');
              return;
            }
          } catch (e) {
            debugPrint('Version check failed: $e');
          }
        }

        if (!mounted) return;
        context.go('/');
      } catch (e) {
        debugPrint('Splash user/config check failed: $e');
        if (!mounted) return;
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        context.go('/login');
      }
    } else {
      if (!mounted) return;
      context.go('/login');
    }

    if (!mounted) return;

    // Navigator logic removed for GoRouter
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69),
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.03),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElasticIn(
                  child: Pulse(
                    infinite: true,
                    duration: const Duration(seconds: 2),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: PhobesTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: PhobesTheme.kPrimaryColor.withOpacity(0.4),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'P',
                          style: GoogleFonts.outfit(
                            fontSize: 60,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                FadeIn(
                  duration: const Duration(milliseconds: 1000),
                  delay: const Duration(milliseconds: 1000),
                  child: const Text(
                    'Phobes',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeIn(
                  duration: const Duration(milliseconds: 1000),
                  delay: const Duration(milliseconds: 1200),
                  child: Text(
                    'ZAMANI YÖNET',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.3),
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: FadeIn(
              delay: const Duration(seconds: 2),
              child: const Center(
                child: SizedBox(
                  width: 40,
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
