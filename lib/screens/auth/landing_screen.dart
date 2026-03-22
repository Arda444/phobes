import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/phobes_theme.dart';
import '../../widgets/phobes_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../settings/about_phobes_screen.dart';
import 'auth_screen.dart';
import 'landing_mockups.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _bgAnimController;
  double _scrollProgress = 0.0;
  bool _isScrolled = false;

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
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
              position: animation.drive(tween), child: child);
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
              // Dynamic Mesh Gradient Background
              AnimatedBuilder(
                animation: _bgAnimController,
                builder: (context, _) => CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _MeshGradientPainter(
                      _bgAnimController.value, _scrollProgress, cs, isDark),
                ),
              ),

              // Glass Overlay
              IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),

              CustomScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  // Navbar
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: _isScrolled
                        ? (isDark
                            ? Colors.black.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.85))
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

                  // Hero
                  SliverToBoxAdapter(
                    child: isWeb
                        ? _buildWebHero(cs, l10n, isDark)
                        : _buildMobileHero(cs, l10n, isDark),
                  ),

                  // Trust Bar
                  SliverToBoxAdapter(child: _buildTrustBar(cs)),

                  // ── Feature Sections ──
                  _buildSection(
                    isWeb: isWeb,
                    cs: cs,
                    title: "Zamanın Efendisi",
                    subtitle: "AKILLI TAKVİM",
                    desc:
                        "Haftalık, aylık ve günlük görünümlerle tüm planını tek bir yerde gör. Görevler, randevular ve notlar aynı takvimde birleşir.",
                    mockup: const CodeCalendarMockup(),
                    color: Colors.orange,
                    reversed: false,
                    icon: Icons.calendar_month_rounded,
                  ),

                  _buildSection(
                    isWeb: isWeb,
                    cs: cs,
                    title: "Ekip Gücü",
                    subtitle: "PROJE YÖNETİMİ",
                    desc:
                        "Kanban panosu, proje takibi ve liderlik tablosu ile takımını yönet. Görev ata, ilerleme izle, verimlilik artır.",
                    mockup: const CodeDashboardMockup(),
                    color: cs.primary,
                    reversed: true,
                    icon: Icons.people_alt_rounded,
                  ),

                  _buildSection(
                    isWeb: isWeb,
                    cs: cs,
                    title: "Yapay Zeka Asistanı",
                    subtitle: "PHOBES NOVA",
                    desc:
                        "AI asistanın verimlilik analizi yapar, görevlerini önceliklendirir, toplantı çakışmalarını tespit eder ve sana özel öneriler sunar.",
                    mockup: const CodeIntelligenceMockup(),
                    color: cs.secondary,
                    reversed: false,
                    icon: Icons.auto_awesome_rounded,
                  ),

                  _buildSection(
                    isWeb: isWeb,
                    cs: cs,
                    title: "Finansal Kontrol",
                    subtitle: "AKILLI BÜTÇE",
                    desc:
                        "Harcamalarını kategorize et, aylık limit belirle ve paranın nereye gittiğini detaylı grafiklerle gör.",
                    mockup: const CodeFinanceMockup(),
                    color: cs.tertiary,
                    reversed: true,
                    icon: Icons.account_balance_wallet_rounded,
                  ),

                  // ── All Features Grid ──
                  SliverToBoxAdapter(child: _buildAllFeatures(cs, isWeb, isDark)),

                  // ── Platform Section ──
                  SliverToBoxAdapter(child: _buildPlatformSection(cs, isWeb, isDark)),

                  // Final CTA
                  SliverToBoxAdapter(child: _buildFinalCTA(cs, l10n, isWeb)),

                  // Footer
                  SliverToBoxAdapter(child: _buildFooter(cs, isWeb)),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
                ],
              ),
            ],
          ),
        );
// Removed Builder and Theme wrappers
  }

  // ─── NAVBAR ───

  Widget _buildNavbar(ColorScheme cs, AppLocalizations l10n, bool isWeb, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 48 : 16),
      child: Row(
        children: [
          // Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: PhobesTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('P',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(width: 10),
          Text('Phobes',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -0.5)),

          const Spacer(),
          if (isWeb) ...[
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutPhobesScreen()),
              ),
              child: Text("Hakkında",
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withValues(alpha: 0.6))),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PhobesFeatureTreeScreen()),
              ),
              child: Text("Özellikler",
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withValues(alpha: 0.6))),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PhobesContactScreen()),
              ),
              child: Text("İletişim",
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withValues(alpha: 0.6))),
            ),
            const SizedBox(width: 8),
          ],

          // Theme toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: cs.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
            onPressed: () => PhobesTheme.toggleTheme(),
            tooltip: isDark ? "Açık Tema" : "Koyu Tema",
          ),

          const SizedBox(width: 4),

          // Auth buttons
          TextButton(
            onPressed: () => _navigateToAuth(true),
            child: Text(l10n.login,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.7))),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: PhobesButton(
              text: l10n.register,
              width: 100,
              onPressed: () => _navigateToAuth(false),
            ),
          ),
        ],
      ),
    );
  }

  // ─── WEB HERO ───

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
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SpinPerfect(
                            infinite: true,
                            duration: const Duration(seconds: 4),
                            child: Icon(Icons.auto_awesome,
                                size: 14, color: cs.primary),
                          ),
                          const SizedBox(width: 6),
                          Text("AI DESTEKLİ VERİMLİLİK",
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: cs.primary,
                                  letterSpacing: 2)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInLeft(
                  delay: const Duration(milliseconds: 200),
                  child: Text("Sadece Yaşama,\nZamanı Yönet.",
                      style: GoogleFonts.outfit(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          color: cs.onSurface)),
                ),
                const SizedBox(height: 20),
                FadeInLeft(
                  delay: const Duration(milliseconds: 400),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Text(
                        "Takvim, görev yönetimi, bütçe, randevular, istatistikler, ilaç takibi, alışkanlıklar, odak modu ve AI asistanı — hepsi tek uygulamada.",
                        style: GoogleFonts.outfit(
                            fontSize: 17,
                            color: cs.onSurface.withValues(alpha: 0.5),
                            height: 1.6)),
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
                          name: "App Store",
                          icon: Icons.apple_rounded,
                          isDark: isDark),
                    ),
                    ElasticIn(
                      delay: const Duration(milliseconds: 750),
                      child: _DownloadBtn(
                          name: "Play Store",
                          icon: Icons.android_rounded,
                          isDark: isDark),
                    ),
                    ElasticIn(
                      delay: const Duration(milliseconds: 900),
                      child: _DownloadBtn(
                          name: "Windows",
                          icon: Icons.window_rounded,
                          isDark: isDark),
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
                          color: cs.primary.withValues(alpha: 0.15),
                          blurRadius: 60,
                          offset: const Offset(0, 20)),
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

  // ─── MOBILE HERO ───

  Widget _buildMobileHero(ColorScheme cs, AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          FadeInDown(
            child: Text("Zamanı Yönet.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: cs.onSurface)),
          ),
          const SizedBox(height: 12),
          FadeInDown(
            delay: const Duration(milliseconds: 200),
            child: Text(
                "Takvim, bütçe, ekip, istatistik ve AI — tek uygulamada.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 15, color: cs.onSurface.withValues(alpha: 0.5))),
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
                text: "HEMEN BAŞLA",
                width: double.infinity,
                onPressed: () => _navigateToAuth(false)),
          ),
        ],
      ),
    );
  }

  // ─── TRUST BAR ───

  Widget _buildTrustBar(ColorScheme cs) {
    return FadeInUp(
      delay: const Duration(milliseconds: 800),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        color: cs.onSurface.withValues(alpha: 0.02),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 32,
          runSpacing: 16,
          children: [
            BounceInDown(
              delay: const Duration(milliseconds: 800),
              child: const _TrustLogo(
                  icon: Icons.flash_on_rounded, label: "Hızlı"),
            ),
            BounceInDown(
              delay: const Duration(milliseconds: 950),
              child: const _TrustLogo(
                  icon: Icons.security_rounded, label: "Güvenli"),
            ),
            BounceInDown(
              delay: const Duration(milliseconds: 1100),
              child: const _TrustLogo(
                  icon: Icons.cloud_done_rounded, label: "Senkronize"),
            ),
            BounceInDown(
              delay: const Duration(milliseconds: 1250),
              child: const _TrustLogo(
                  icon: Icons.verified_user_rounded, label: "Premium"),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BENEFIT SECTION ───

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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 16),
        Text(subtitle,
            style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: color)),
        const SizedBox(height: 10),
        Text(title,
            textAlign: isWeb ? TextAlign.start : TextAlign.center,
            style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: cs.onSurface)),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(desc,
              textAlign: isWeb ? TextAlign.start : TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.5),
                  height: 1.6)),
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
          child: Column(children: [
            FadeInLeft(child: textW),
            const SizedBox(height: 32),
            FadeInUp(delay: const Duration(milliseconds: 200), child: mockupW),
          ]),
        ),
      );
    }

    final children = reversed
        ? [
            Expanded(
                child: FadeInUp(
                    delay: const Duration(milliseconds: 200), child: mockupW)),
            const SizedBox(width: 60),
            Expanded(child: FadeInLeft(child: textW)),
          ]
        : [
            Expanded(child: FadeInLeft(child: textW)),
            const SizedBox(width: 60),
            Expanded(
                child: FadeInUp(
                    delay: const Duration(milliseconds: 200), child: mockupW)),
          ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 80),
      sliver: SliverToBoxAdapter(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }

  // ─── ALL FEATURES GRID ───

  Widget _buildAllFeatures(ColorScheme cs, bool isWeb, bool isDark) {
    const features = [
      _Feat(Icons.calendar_month_rounded, "Akıllı Takvim",
          "Haftalık, aylık, günlük görünüm", Color(0xFFE65100)),
      _Feat(Icons.task_alt_rounded, "Görev Yönetimi",
          "Priorite, tekrar, sesli ekleme", Color(0xFF4285F4)),
      _Feat(Icons.event_available_rounded, "Randevular",
          "Müşteri yönetimi ve grup randevuları", Color(0xFF10B981)),
      _Feat(Icons.bar_chart_rounded, "İstatistikler",
          "Verimlilik analizi ve grafikler", Color(0xFFF59E0B)),
      _Feat(Icons.account_balance_wallet_rounded, "Bütçe Takibi",
          "Gelir, gider, kategori limitleri", Color(0xFF06B6D4)),
      _Feat(Icons.auto_awesome_rounded, "Phobes Nova AI",
          "Akıllı öneri ve analiz asistanı", Color(0xFF8B5CF6)),
      _Feat(Icons.note_alt_rounded, "Zengin Notlar",
          "Kategorili, etiketli not sistemi", Color(0xFF3B82F6)),
      _Feat(Icons.view_kanban_rounded, "Kanban Panosu",
          "Proje takibi ve ekip yönetimi", Color(0xFFF472B6)),
      _Feat(Icons.group_rounded, "Ekip Yönetimi",
          "Liderlik tablosu ve aktivite", Color(0xFFEF4444)),
      _Feat(Icons.timer_rounded, "Odak Modu",
          "Pomodoro ve konsantrasyon takibi", Color(0xFF059669)),
      _Feat(Icons.loop_rounded, "Alışkanlık Takibi",
          "Günlük rutinlerini oluştur", Color(0xFF7C3AED)),
      _Feat(Icons.medication_rounded, "İlaç Hatırlatıcı",
          "Doz takibi ve bildirimler", Color(0xFFDB2777)),
      _Feat(Icons.notifications_active_rounded, "Akıllı Bildirimler",
          "Özelleştirilebilir hatırlatıcılar", Color(0xFFF97316)),
      _Feat(Icons.palette_rounded, "Kişiselleştirme",
          "8 renk, dark/light/AMOLED tema", Color(0xFF8B5CF6)),
      _Feat(Icons.mic_rounded, "Sesli Görev Ekleme",
          "Konuşarak hızlı görev kaydet", Color(0xFF0EA5E9)),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 80, horizontal: isWeb ? 80 : 24),
      child: Column(
        children: [
          FadeInDown(
            child: Text("TÜM ÖZELLİKLER",
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: cs.primary)),
          ),
          const SizedBox(height: 12),
          FadeInDown(
            delay: const Duration(milliseconds: 100),
            child: Text("Her İhtiyacın İçin\nTek Uygulama",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: cs.onSurface)),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: features.asMap().entries.map((e) {
              return FadeInUp(
                delay: Duration(milliseconds: 100 + e.key * 60),
                child: _buildFeatCard(cs, e.value, isDark),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatCard(ColorScheme cs, _Feat f, bool isDark) {
    return ZoomIn(
      duration: const Duration(milliseconds: 600),
      child: _HoverMockup(
        color: f.color,
        child: Container(
          width: 190,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: cs.onSurface.withValues(alpha: isDark ? 0.08 : 0.06)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Pulse(
                infinite: true,
                duration: const Duration(seconds: 3),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: f.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(f.icon, color: f.color, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              Text(f.title,
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
              const SizedBox(height: 4),
              Text(f.sub,
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.4),
                      height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PLATFORM SECTION ───

  Widget _buildPlatformSection(ColorScheme cs, bool isWeb, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 80, horizontal: isWeb ? 80 : 24),
      child: Column(
        children: [
          FadeInDown(
            child: Text("HER YERDE PHOBES",
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: cs.primary)),
          ),
          const SizedBox(height: 12),
          FadeInDown(
            delay: const Duration(milliseconds: 100),
            child: Text("Tüm Platformlarda",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface)),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _platformCard(cs, Icons.phone_iphone_rounded, "iOS",
                    "iPhone & iPad", const Color(0xFF007AFF), isDark),
              ),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: _platformCard(cs, Icons.android_rounded, "Android",
                    "Tüm Cihazlar", const Color(0xFF3DDC84), isDark),
              ),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: _platformCard(cs, Icons.window_rounded, "Windows",
                    "Masaüstü", const Color(0xFF00BCF2), isDark),
              ),
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: _platformCard(
                    cs, Icons.language_rounded, "Web", "Tarayıcı", cs.primary, isDark),
              ),
            ],
          ),
          const SizedBox(height: 40),
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  Icon(Icons.dark_mode_rounded,
                      size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
                  Text("Dark & Light Mod",
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                  Text("+ AMOLED",
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.primary)),
                  Icon(Icons.light_mode_rounded,
                      size: 18, color: Colors.orange.withValues(alpha: 0.6)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _platformCard(
      ColorScheme cs, IconData icon, String name, String sub, Color c, bool isDark) {
    return ElasticIn(
      duration: const Duration(milliseconds: 800),
      child: _HoverMockup(
        color: c,
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.withValues(alpha: 0.12)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                        color: c.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6)),
                  ],
          ),
          child: Column(
            children: [
              SpinPerfect(
                duration: const Duration(milliseconds: 1500),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: c, size: 28),
                ),
              ),
              const SizedBox(height: 14),
              Text(name,
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(sub,
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.4))),
            ],
          ),
        ),
      ),
    );
  }

  // ─── FINAL CTA ───

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
                cs.primary.withValues(alpha: 0.06),
                cs.secondary.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              BounceInUp(
                child: SpinPerfect(
                  infinite: true,
                  duration: const Duration(seconds: 5),
                  child: Icon(Icons.rocket_launch_rounded,
                      size: 40, color: cs.primary),
                ),
              ),
              const SizedBox(height: 20),
              Text("Hemen Başla",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: isWeb ? 44 : 32,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      color: cs.onSurface)),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                    "Binlerce üretken insan arasına katıl ve Phobes premium deneyimini bugün yaşa.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: cs.onSurface.withValues(alpha: 0.5),
                        height: 1.5)),
              ),
              const SizedBox(height: 28),
              PhobesButton(
                  text: "ÜCRETSİZ BAŞLA",
                  width: isWeb ? 280 : double.infinity,
                  onPressed: () => _navigateToAuth(false)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── FOOTER ───

  Widget _buildFooter(ColorScheme cs, bool isWeb) {
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
                        Text("Phobes",
                            style: GoogleFonts.outfit(
                                fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text("Zamanın, senin kontrolünde.",
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: cs.onSurface.withValues(alpha: 0.4))),
                      ],
                    ),
                    Row(
                      children: [
                        _FooterLinkCol(
                            title: "Ürün",
                            items: const [
                              "Akıllı Takvim",
                              "Bütçe Takibi",
                              "Phobes Nova AI"
                            ],
                            onTap: (_) => _navigateToAuth(false)),
                        const SizedBox(width: 48),
                        _FooterLinkCol(
                            title: "Şirket",
                            items: const [
                              "Hakkımızda",
                              "Özellik Ağacı",
                              "İletişim"
                            ],
                            onTap: (item) {
                              if (item == "Hakkımızda") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AboutPhobesScreen()),
                                );
                              } else if (item == "Özellik Ağacı") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const PhobesFeatureTreeScreen()),
                                );
                              } else if (item == "İletişim") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const PhobesContactScreen()),
                                );
                              }
                            }),
                        const SizedBox(width: 48),
                        _FooterLinkCol(
                            title: "Yasal",
                            items: const [
                              "Gizlilik Politikası",
                              "Kullanım Şartları",
                              "Çerez Politikası"
                            ],
                            onTap: (item) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text(item)));
                            }),
                      ],
                    ),
                  ],
                )
              : Column(
                  children: [
                    Text("Phobes",
                        style: GoogleFonts.outfit(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text("Zamanın, senin kontrolünde.",
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.4))),
                  ],
                ),
          const SizedBox(height: 20),
          Text("© 2026 Techluna Software. Tüm hakları saklıdır.",
              style: GoogleFonts.outfit(
                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.2))),
        ],
      ),
    );
  }
}

// ─── DATA ───

class _Feat {
  final IconData icon;
  final String title;
  final String sub;
  final Color color;
  const _Feat(this.icon, this.title, this.sub, this.color);
}

// ─── WIDGETS ───

class _DownloadBtn extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool isDark;
  const _DownloadBtn(
      {required this.name, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  name == "App Store"
                      ? "Download on the"
                      : (name == "Windows" ? "Download for" : "GET IT ON"),
                  style:
                      GoogleFonts.outfit(fontSize: 9, color: Colors.white70)),
              Text(name,
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ],
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
        Icon(icon, color: cs.onSurface.withValues(alpha: 0.2), size: 20),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.2))),
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
                  color: widget.color.withValues(alpha: _hovered ? 0.18 : 0.08),
                  blurRadius: _hovered ? 50 : 30,
                  offset: const Offset(0, 12)),
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
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
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

class _FooterLinkCol extends StatelessWidget {
  final String title;
  final List<String> items;
  final void Function(String) onTap;
  const _FooterLinkCol(
      {required this.title, required this.items, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        ...items.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => onTap(i),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(i,
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.4))),
                ),
              ),
            )),
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
      this.progress, this.scrollProgress, this.cs, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = isDark ? Colors.black : Colors.white);

    void drawOrb(Offset center, double radius, Color color) {
      paint.shader = RadialGradient(
        colors: [
          color.withValues(alpha: isDark ? 0.12 : 0.06),
          Colors.transparent
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    final t = progress * 2 * math.pi;
    drawOrb(
        Offset(size.width * (0.2 + 0.1 * math.sin(t)),
            size.height * (0.2 + (0.4 * scrollProgress))),
        size.width * 1.2,
        cs.primary);
    drawOrb(
        Offset(size.width * (0.8 - (0.3 * scrollProgress)),
            size.height * (0.6 + 0.1 * math.sin(t * 0.7))),
        size.width * 1.0,
        cs.secondary);
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) => true;
}
