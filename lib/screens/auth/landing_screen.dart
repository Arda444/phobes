import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/phobes_theme.dart';
import '../../core/app_locales.dart';
import '../../core/marketing_module_catalog.dart';
import '../../main.dart';
import '../../widgets/marketing/marketing_feature_card.dart';
import '../../widgets/phobes_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../settings/about_phobes_screen.dart';
import '../common/phobes_feature_tree_screen.dart';
import '../common/phobes_contact_screen.dart';
import '../common/legal_document_screen.dart';
import '../../core/legal_content.dart';
import 'auth_screen.dart';
import 'landing_mockups.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

enum _SubPage { home, about, features, contact }

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _bgAnimController;
  double _scrollProgress = 0.0;
  bool _isScrolled = false;
  _SubPage _subPage = _SubPage.home;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _bgAnimController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      setState(() {
        _scrollProgress = (_scrollController.offset /
                _scrollController.position.maxScrollExtent)
            .clamp(0.0, 1.0);
        _isScrolled = _scrollController.offset > 50;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bgAnimController.dispose();
    super.dispose();
  }

  void _navigateToAuth(bool isLogin) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AuthScreen(
          initialIsLogin: isLogin,
          showLandingHeader: true,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;
          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;
    final isWeb = width > 900;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : cs.surface,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _MeshGradientPainter(
                _bgAnimController.value,
                _scrollProgress,
                cs,
                isDark,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          CustomScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: _isScrolled
                    ? (isDark
                        ? Colors.black.withOpacity(0.85)
                        : Colors.white.withOpacity(0.85))
                    : Colors.transparent,
                elevation: _isScrolled ? 1 : 0,
                toolbarHeight: 70,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                titleSpacing: 0,
                title: _buildNavbar(cs, l10n, isWeb, isDark),
              ),
              if (_subPage == _SubPage.home) ...[
                SliverToBoxAdapter(
                  child: isWeb
                      ? _buildWebHero(cs, l10n, isDark)
                      : _buildMobileHero(cs, l10n, isDark),
                ),
                SliverToBoxAdapter(child: _buildTrustBar(cs)),
                _buildSection(
                  isWeb: isWeb,
                  cs: cs,
                  title: l10n.landingFeatCalendarTitle,
                  subtitle: l10n.landingFeatCalendarBadge,
                  desc: l10n.landingFeatCalendarDesc,
                  mockup: const CodeCalendarMockup(),
                  color: Colors.orange,
                  reversed: false,
                  icon: Icons.calendar_month_rounded,
                ),
                _buildSection(
                  isWeb: isWeb,
                  cs: cs,
                  title: l10n.landingFeatTeamsTitle,
                  subtitle: l10n.landingFeatTeamsBadge,
                  desc: l10n.landingFeatTeamsDesc,
                  mockup: const CodeDashboardMockup(),
                  color: cs.primary,
                  reversed: true,
                  icon: Icons.people_alt_rounded,
                ),
                _buildSection(
                  isWeb: isWeb,
                  cs: cs,
                  title: l10n.landingFeatNovaTitle,
                  subtitle: l10n.landingFeatNovaBadge,
                  desc: l10n.landingFeatNovaDesc,
                  mockup: const CodeIntelligenceMockup(),
                  color: cs.secondary,
                  reversed: false,
                  icon: Icons.auto_awesome_rounded,
                ),
                _buildSection(
                  isWeb: isWeb,
                  cs: cs,
                  title: l10n.landingFeatBudgetTitle,
                  subtitle: l10n.landingFeatBudgetBadge,
                  desc: l10n.landingFeatBudgetDesc,
                  mockup: const CodeFinanceMockup(),
                  color: cs.tertiary,
                  reversed: true,
                  icon: Icons.account_balance_wallet_rounded,
                ),
                SliverToBoxAdapter(
                  child: _buildAllFeatures(context, cs, isWeb, isDark),
                ),
                SliverToBoxAdapter(
                    child: _buildPlatformSection(cs, isWeb, isDark)),
                SliverToBoxAdapter(child: _buildFinalCTA(cs, l10n, isWeb)),
                SliverToBoxAdapter(child: _buildFooter(context, cs, isWeb)),
                const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
              ] else
                SliverFillRemaining(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _subPage == _SubPage.about
                        ? const AboutPhobesScreen(embedded: true)
                        : _subPage == _SubPage.features
                            ? const PhobesFeatureTreeScreen(embedded: true)
                            : const PhobesContactScreen(embedded: true),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navBtn(String label, _SubPage page, ColorScheme cs) {
    final active = _subPage == page;
    return TextButton(
      onPressed: () {
        setState(() => _subPage = page);
        _scrollController.jumpTo(0);
      },
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? cs.primary : cs.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildLanguageSwitcher(ColorScheme cs, AppLocalizations l10n) {
    final currentCode = MyApp.of(context)?.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final currentOption =
        localeOptionForCode(currentCode) ?? kAppLocaleOptions.first;

    return PopupMenuButton<Locale>(
      tooltip: l10n.language,
      position: PopupMenuPosition.under,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outline.withOpacity(0.12)),
      ),
      elevation: 8,
      onSelected: (locale) => MyApp.of(context)?.setLocale(locale),
      itemBuilder: (context) => [
        for (final option in kAppLocaleOptions)
          PopupMenuItem<Locale>(
            value: option.locale,
            height: 40,
            child: Row(
              children: [
                if (option.locale.languageCode == currentCode)
                  Icon(Icons.check_rounded,
                      size: 16, color: cs.primary)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 10),
                Text(
                  option.nativeLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight:
                        option.locale.languageCode == currentCode
                            ? FontWeight.w700
                            : FontWeight.w500,
                    color: option.locale.languageCode == currentCode
                        ? cs.primary
                        : cs.onSurface.withOpacity(0.85),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  option.locale.languageCode.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 16,
              color: cs.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Text(
              currentOption.locale.languageCode.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more_rounded,
              size: 14,
              color: cs.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbar(
      ColorScheme cs, AppLocalizations l10n, bool isWeb, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 48 : 12),
      child: Row(
        children: [
          Container(
            width: isWeb ? 32 : 28,
            height: isWeb ? 32 : 28,
            decoration: BoxDecoration(
              gradient: PhobesTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'P',
                style: GoogleFonts.outfit(
                  fontSize: isWeb ? 18 : 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (isWeb) ...[
            const SizedBox(width: 10),
            Text(
              'Phobes',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ],
          const Spacer(),
          if (isWeb) ...[
            if (_subPage != _SubPage.home)
              TextButton.icon(
                onPressed: () {
                  setState(() => _subPage = _SubPage.home);
                  _scrollController.jumpTo(0);
                },
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: cs.onSurface.withOpacity(0.6),
                ),
                label: Text(
                  l10n.landingHome,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            _navBtn(l10n.landingAbout, _SubPage.about, cs),
            _navBtn(l10n.landingFeatures, _SubPage.features, cs),
            _navBtn(l10n.landingContact, _SubPage.contact, cs),
            const SizedBox(width: 8),
          ],
          _buildLanguageSwitcher(cs, l10n),
          const SizedBox(width: 2),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: cs.onSurface.withOpacity(0.6),
              size: 20,
            ),
            onPressed: () => PhobesTheme.toggleTheme(),
            tooltip: isDark ? l10n.landingThemeLight : l10n.landingThemeDark,
          ),
          if (isWeb) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => _navigateToAuth(true),
              child: Text(
                l10n.login,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
          SizedBox(width: isWeb ? 8 : 4),
          SizedBox(
            height: isWeb ? 38 : 34,
            child: PhobesButton(
              text: isWeb ? l10n.register : l10n.login,
              width: isWeb ? 100 : 78,
              onPressed: () => _navigateToAuth(!isWeb),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebHero(ColorScheme cs, AppLocalizations l10n, bool isDark) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInLeft(
                  child: Pulse(
                    infinite: true,
                    duration: const Duration(seconds: 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SpinPerfect(
                            infinite: true,
                            duration: const Duration(seconds: 4),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.landingAiProductivity,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInLeft(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    l10n.landingHeroHeadline,
                    style: GoogleFonts.outfit(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeInLeft(
                  delay: const Duration(milliseconds: 400),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Text(
                      l10n.landingHeroSub,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        color: cs.onSurface.withOpacity(0.5),
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElasticIn(
                      delay: const Duration(milliseconds: 600),
                      child: _DownloadBtn(
                        name: 'App Store',
                        icon: Icons.apple_rounded,
                        isDark: isDark,
                      ),
                    ),
                    ElasticIn(
                      delay: const Duration(milliseconds: 750),
                      child: _DownloadBtn(
                        name: 'Android APK',
                        icon: Icons.android_rounded,
                        isDark: isDark,
                        topLabel: 'Direct Download',
                        url: '/phobes.apk',
                      ),
                    ),
                    ElasticIn(
                      delay: const Duration(milliseconds: 900),
                      child: _DownloadBtn(
                        name: 'Windows',
                        icon: Icons.window_rounded,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 5,
            child: FadeInRight(
              delay: const Duration(milliseconds: 300),
              child: _FloatingWidget(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.15),
                        blurRadius: 60,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: const CodeCalendarMockup(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHero(ColorScheme cs, AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          FadeInDown(
            child: Text(
              l10n.landingHeroHeadline,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1.1,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeInDown(
            delay: const Duration(milliseconds: 200),
            child: Text(
              l10n.landingHeroSub,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: cs.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 28),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: const CodeCalendarMockup(),
          ),
          const SizedBox(height: 28),
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: PhobesButton(
              text: l10n.landingCtaStart,
              width: double.infinity,
              onPressed: () => _navigateToAuth(false),
            ),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 750),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _DownloadBtn(
                  name: 'App Store',
                  icon: Icons.apple_rounded,
                  isDark: isDark,
                ),
                _DownloadBtn(
                  name: 'Android APK',
                  icon: Icons.android_rounded,
                  isDark: isDark,
                  topLabel: 'Direct Download',
                  url: '/phobes.apk',
                ),
                _DownloadBtn(
                  name: 'Windows',
                  icon: Icons.window_rounded,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBar(ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return FadeInUp(
      delay: const Duration(milliseconds: 800),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        color: cs.onSurface.withOpacity(0.02),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 32,
          runSpacing: 16,
          children: [
            BounceInDown(
              delay: const Duration(milliseconds: 800),
              child: _TrustLogo(
                icon: Icons.flash_on_rounded,
                label: l10n.landingTrustFast,
              ),
            ),
            BounceInDown(
              delay: const Duration(milliseconds: 950),
              child: _TrustLogo(
                icon: Icons.security_rounded,
                label: l10n.landingTrustSecure,
              ),
            ),
            BounceInDown(
              delay: const Duration(milliseconds: 1100),
              child: _TrustLogo(
                icon: Icons.cloud_done_rounded,
                label: l10n.landingTrustSync,
              ),
            ),
            BounceInDown(
              delay: const Duration(milliseconds: 1250),
              child: _TrustLogo(
                icon: Icons.verified_user_rounded,
                label: l10n.landingTrustPremium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required bool isWeb,
    required ColorScheme cs,
    required String title,
    required String subtitle,
    required String desc,
    required Widget mockup,
    required Color color,
    required bool reversed,
    required IconData icon,
  }) {
    final textW = Column(
      crossAxisAlignment:
          isWeb ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SpinPerfect(
          duration: const Duration(milliseconds: 1200),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: color,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: isWeb ? TextAlign.start : TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            desc,
            textAlign: isWeb ? TextAlign.start : TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: cs.onSurface.withOpacity(0.5),
              height: 1.6,
            ),
          ),
        ),
      ],
    );

    final mockupW = _HoverMockup(
      color: color,
      child: mockup,
    );

    if (!isWeb) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              FadeInLeft(child: textW),
              const SizedBox(height: 32),
              FadeInUp(
                  delay: const Duration(milliseconds: 200), child: mockupW),
            ],
          ),
        ),
      );
    }

    final children = reversed
        ? [
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: mockupW,
              ),
            ),
            const SizedBox(width: 60),
            Expanded(child: FadeInLeft(child: textW)),
          ]
        : [
            Expanded(child: FadeInLeft(child: textW)),
            const SizedBox(width: 60),
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: mockupW,
              ),
            ),
          ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 80),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: children,
        ),
      ),
    );
  }

  Widget _buildAllFeatures(
    BuildContext context,
    ColorScheme cs,
    bool isWeb,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);
    final features = l10n != null
        ? MarketingModuleCatalog.landingFeatures(l10n)
        : <MarketingModule>[];

    double cardWidthFor(double maxWidth) {
      if (maxWidth >= 1200) return 220;
      if (maxWidth >= 900) return 200;
      if (maxWidth >= 600) return (maxWidth - 32) / 2 - 8;
      return maxWidth - 32;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 80, horizontal: isWeb ? 80 : 24),
      child: Column(
        children: [
          FadeInDown(
            child: Text(
              l10n?.landingAllFeatures ?? 'ALL FEATURES',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeInDown(
            delay: const Duration(milliseconds: 100),
            child: Text(
              l10n?.landingAllFeaturesTitle ?? 'One app for\nevery need',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.1,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardW = cardWidthFor(constraints.maxWidth);
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: features.asMap().entries.map((e) {
                  final m = e.value;
                  return FadeInUp(
                    delay: Duration(milliseconds: 100 + e.key * 40),
                    child: MarketingFeatureCard(
                      module: m,
                      title: l10n != null ? m.title(l10n) : m.id,
                      subtitle: l10n != null ? m.subtitle(l10n) : '',
                      isDark: isDark,
                      width: cardW,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSection(ColorScheme cs, bool isWeb, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 80, horizontal: isWeb ? 80 : 24),
      child: Column(
        children: [
          FadeInDown(
            child: Text(
              'HER YERDE PHOBES',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeInDown(
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Tüm Platformlarda',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _platformCard(
                  cs,
                  Icons.phone_iphone_rounded,
                  'iOS',
                  'iPhone & iPad',
                  const Color(0xFF007AFF),
                  isDark,
                ),
              ),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: _platformCard(
                  cs,
                  Icons.android_rounded,
                  'Android',
                  'Tüm Cihazlar',
                  const Color(0xFF3DDC84),
                  isDark,
                ),
              ),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: _platformCard(
                  cs,
                  Icons.window_rounded,
                  'Windows',
                  'Masaüstü',
                  const Color(0xFF00BCF2),
                  isDark,
                ),
              ),
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: _platformCard(
                  cs,
                  Icons.language_rounded,
                  'Web',
                  'Tarayıcı',
                  cs.primary,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.primary.withOpacity(0.1)),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  Icon(
                    Icons.dark_mode_rounded,
                    size: 18,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                  Text(
                    'Dark & Light Mod',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    '+ AMOLED',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  Icon(
                    Icons.light_mode_rounded,
                    size: 18,
                    color: Colors.orange.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _platformCard(
    ColorScheme cs,
    IconData icon,
    String name,
    String sub,
    Color c,
    bool isDark,
  ) {
    return ElasticIn(
      duration: const Duration(milliseconds: 800),
      child: _HoverMockup(
        color: c,
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.withOpacity(0.12)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: c.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            children: [
              SpinPerfect(
                duration: const Duration(milliseconds: 1500),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: c, size: 28),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: cs.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalCTA(ColorScheme cs, AppLocalizations l10n, bool isWeb) {
    return FadeInUp(
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: isWeb ? 80 : 24, vertical: 40),
        child: Container(
          padding: EdgeInsets.all(isWeb ? 56 : 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withOpacity(0.06),
                cs.secondary.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: cs.primary.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              BounceInUp(
                child: SpinPerfect(
                  infinite: true,
                  duration: const Duration(seconds: 5),
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    size: 40,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.landingCtaStart,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: isWeb ? 44 : 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  'Binlerce üretken insan arasına katıl ve Phobes premium deneyimini bugün yaşa.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: cs.onSurface.withOpacity(0.5),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              PhobesButton(
                text: l10n.landingCtaFree,
                width: isWeb ? 280 : double.infinity,
                onPressed: () => _navigateToAuth(false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme cs, bool isWeb) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 24),
          isWeb
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phobes',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n?.landingTagline ?? 'Your time, under your control.',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: cs.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _FooterLinkCol(
                          title: l10n?.footerProduct ?? 'Product',
                          items: l10n != null
                              ? [
                                  MarketingModuleCatalog.all
                                      .firstWhere((m) => m.id == 'calendar')
                                      .title(l10n),
                                  MarketingModuleCatalog.all
                                      .firstWhere((m) => m.id == 'budget')
                                      .title(l10n),
                                  MarketingModuleCatalog.all
                                      .firstWhere((m) => m.id == 'nova')
                                      .title(l10n),
                                ]
                              : const [
                                  'Calendar',
                                  'Budget',
                                  'Nova',
                                ],
                          onTap: (_) => _navigateToAuth(false),
                        ),
                        const SizedBox(width: 48),
                        _FooterLinkCol(
                          title: l10n?.footerCompany ?? 'Company',
                          items: [
                            l10n?.landingAbout ?? 'About',
                            l10n?.landingFeatures ?? 'Features',
                            l10n?.landingContact ?? 'Contact',
                          ],
                          onTap: (item) {
                            final about = l10n?.landingAbout ?? 'About';
                            final features =
                                l10n?.landingFeatures ?? 'Features';
                            final contact = l10n?.landingContact ?? 'Contact';
                            if (item == about) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AboutPhobesScreen(),
                                ),
                              );
                            } else if (item == features) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PhobesFeatureTreeScreen(),
                                ),
                              );
                            } else if (item == contact) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PhobesContactScreen(),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 48),
                        _FooterLinkCol(
                          title: l10n?.footerLegal ?? 'Legal',
                          items: [
                            l10n?.privacyPolicy ?? 'Privacy Policy',
                            l10n?.termsOfService ?? 'Terms of Service',
                            l10n?.cookiePolicy ?? 'Cookie Policy',
                          ],
                          onTap: (item) {
                            final privacy = l10n?.privacyPolicy ?? 'Privacy Policy';
                            final terms = l10n?.termsOfService ?? 'Terms of Service';
                            final LegalDocumentType type;
                            if (item == privacy) {
                              type = LegalDocumentType.privacy;
                            } else if (item == terms) {
                              type = LegalDocumentType.terms;
                            } else {
                              type = LegalDocumentType.cookies;
                            }
                            LegalDocumentScreen.open(context, type);
                          },
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  children: [
                    Text(
                      'Phobes',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.landingTagline ?? 'Your time, under your control.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      children: [
                        _FooterLegalLink(
                          label: l10n?.privacyPolicy ?? 'Privacy',
                          onTap: () => LegalDocumentScreen.open(
                            context,
                            LegalDocumentType.privacy,
                          ),
                        ),
                        _FooterLegalLink(
                          label: l10n?.termsOfService ?? 'Terms',
                          onTap: () => LegalDocumentScreen.open(
                            context,
                            LegalDocumentType.terms,
                          ),
                        ),
                        _FooterLegalLink(
                          label: l10n?.cookiePolicy ?? 'Cookies',
                          onTap: () => LegalDocumentScreen.open(
                            context,
                            LegalDocumentType.cookies,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          const SizedBox(height: 20),
          Text(
            '© 2026 Techluna Software. Tüm hakları saklıdır.',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: cs.onSurface.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadBtn extends StatefulWidget {
  final String name;
  final IconData icon;
  final bool isDark;
  final String? topLabel;
  final String? url;
  const _DownloadBtn({
    required this.name,
    required this.icon,
    required this.isDark,
    this.topLabel,
    this.url,
  });

  @override
  State<_DownloadBtn> createState() => _DownloadBtnState();
}

class _DownloadBtnState extends State<_DownloadBtn> {
  bool _hovered = false;

  String get _topLabel {
    if (widget.topLabel != null) return widget.topLabel!;
    if (widget.name == 'App Store') return 'Download on the';
    if (widget.name == 'Windows') return 'Download for';
    return 'GET IT ON';
  }

  Future<void> _onTap() async {
    final url = widget.url;
    if (url == null) return;
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.url != null;
    return MouseRegion(
      cursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = enabled),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: enabled ? _onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withOpacity(_hovered ? 0.16 : 0.1)
                : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
            border: enabled
                ? Border.all(
                    color: Colors.white.withOpacity(_hovered ? 0.25 : 0),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _topLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    widget.name,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (enabled) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.download_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustLogo extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustLogo({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: cs.onSurface.withOpacity(0.2), size: 20),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}

class _HoverMockup extends StatefulWidget {
  final Color color;
  final Widget child;
  const _HoverMockup({required this.color, required this.child});

  @override
  State<_HoverMockup> createState() => _HoverMockupState();
}

class _HoverMockupState extends State<_HoverMockup> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_hovered ? 0.18 : 0.08),
                blurRadius: _hovered ? 50 : 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _FloatingWidget extends StatefulWidget {
  final Widget child;
  const _FloatingWidget({required this.child});

  @override
  State<_FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<_FloatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _anim = Tween<Offset>(
      begin: const Offset(0, 0.01),
      end: const Offset(0, -0.01),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _anim, child: widget.child);
  }
}

class _FooterLegalLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLegalLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          color: cs.onSurface.withOpacity(0.35),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _FooterLinkCol extends StatelessWidget {
  final String title;
  final List<String> items;
  final void Function(String) onTap;
  const _FooterLinkCol({
    required this.title,
    required this.items,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: () => onTap(i),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  i,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  final double progress;
  final double scrollProgress;
  final ColorScheme cs;
  final bool isDark;

  _MeshGradientPainter(
    this.progress,
    this.scrollProgress,
    this.cs,
    this.isDark,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = isDark ? Colors.black : Colors.white,
    );

    void drawOrb(Offset center, double radius, Color color) {
      paint.shader = RadialGradient(
        colors: [
          color.withOpacity(isDark ? 0.12 : 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    final t = progress * 2 * math.pi;
    drawOrb(
      Offset(
        size.width * (0.2 + 0.1 * math.sin(t)),
        size.height * (0.2 + (0.4 * scrollProgress)),
      ),
      size.width * 1.2,
      cs.primary,
    );
    drawOrb(
      Offset(
        size.width * (0.8 - (0.3 * scrollProgress)),
        size.height * (0.6 + 0.1 * math.sin(t * 0.7)),
      ),
      size.width * 1.0,
      cs.secondary,
    );
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) => true;
}
