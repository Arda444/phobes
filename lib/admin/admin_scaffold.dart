import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_drawer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_engagement_screen.dart';
import 'screens/admin_system_screen.dart';
import '../core/phobes_theme.dart';
import 'utils/admin_ui_system.dart';

class AdminScaffold extends StatefulWidget {
  const AdminScaffold({super.key});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  AnimationController? _bgAnimController;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _screens = [
      DashboardScreen(onNavigate: (i) => setState(() => _selectedIndex = i)),
      const AdminUsersScreen(),
      const AdminEngagementScreen(),
      const AdminSystemScreen(),
    ];
  }

  void _initAnimation() {
    _bgAnimController ??= AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _bgAnimController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bgAnimController == null) _initAnimation();

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;
    final isWide = MediaQuery.sizeOf(context).width >= 1100;
    final isMobile = AdminUISystem.isAdminMobile(context);
    final blurSigma = isMobile ? 18.0 : 90.0;

    final sidebar = AdminDrawer(
      selectedIndex: _selectedIndex,
      onItemSelected: (index) {
        setState(() => _selectedIndex = index);
        if (!isWide) Navigator.pop(context);
      },
      isSidebar: isWide,
    );

    final bodyContent = Row(
      children: [
        if (isWide) sidebar,
        Expanded(
          child: Column(
            children: [
              _buildTopBar(context, cs, isWide, isDark, isMobile),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Container(
                    key: ValueKey(_selectedIndex),
                    child: _screens[_selectedIndex],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      drawer: isWide ? null : sidebar,
      backgroundColor: isDark
          ? (isAmoled ? Colors.black : const Color(0xFF0F172A))
          : const Color(0xFFF8FAFC),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_rounded),
                  label: 'Panel',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_rounded),
                  label: 'Kullanıcı',
                ),
                NavigationDestination(
                  icon: Icon(Icons.campaign_rounded),
                  label: 'Etkileşim',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_rounded),
                  label: 'Sistem',
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          if (_bgAnimController != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgAnimController!,
                builder: (context, _) => CustomPaint(
                  painter: _AdminBgPainter(_bgAnimController!.value, cs),
                ),
              ),
            ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                color: isDark
                    ? (isAmoled
                        ? Colors.black.withOpacity(0.55)
                        : Colors.black.withOpacity(0.28))
                    : Colors.white.withOpacity(isMobile ? 0.55 : 0.4),
              ),
            ),
          ),
          SafeArea(child: bodyContent),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    ColorScheme cs,
    bool isWide,
    bool isDark,
    bool isMobile,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Admin';
    final initials = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'A';

    return Container(
      height: isMobile ? 56 : 75,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.white.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.04),
          ),
        ),
      ),
      child: Row(
        children: [
          if (!isWide)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          Expanded(
            child: Text(
              AdminUISystem.adminNavTitles[_selectedIndex],
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? Colors.white.withOpacity(0.9)
                    : Colors.black.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            _buildProfileAnchor(cs, displayName, initials),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileAnchor(ColorScheme cs, String name, String initials) {
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              name,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withOpacity(0.9),
              ),
            ),
            Text(
              'ADMIN',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: cs.primary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: PhobesTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminBgPainter extends CustomPainter {
  final double progress;
  final ColorScheme cs;
  _AdminBgPainter(this.progress, this.cs);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final primary = cs.primary;
    final secondary = cs.secondary;
    final tertiary = cs.tertiary;

    final c1x = size.width * (0.2 + 0.15 * math.sin(progress * 2 * math.pi));
    final c1y = size.height * (0.2 + 0.1 * math.cos(progress * 2 * math.pi));
    paint.shader = RadialGradient(
      colors: [primary.withOpacity(0.35), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(c1x, c1y), radius: 500));
    canvas.drawCircle(Offset(c1x, c1y), 500, paint);

    final c2x = size.width * (0.8 + 0.2 * math.cos(progress * 2 * math.pi + 1));
    final c2y = size.height * (0.7 + 0.15 * math.sin(progress * 2 * math.pi + 1));
    paint.shader = RadialGradient(
      colors: [secondary.withOpacity(0.3), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(c2x, c2y), radius: 450));
    canvas.drawCircle(Offset(c2x, c2y), 450, paint);

    final c3x = size.width * (0.5 + 0.25 * math.sin(progress * 2 * math.pi + 2));
    final c3y = size.height * (0.85 + 0.15 * math.cos(progress * 2 * math.pi + 2));
    paint.shader = RadialGradient(
      colors: [tertiary.withOpacity(0.2), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(c3x, c3y), radius: 400));
    canvas.drawCircle(Offset(c3x, c3y), 400, paint);
  }

  @override
  bool shouldRepaint(covariant _AdminBgPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.cs != cs;
}
