import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../widgets/phobes_widgets.dart';
import '../common/legal_document_screen.dart';
import '../common/phobes_feature_tree_screen.dart';
import '../../core/legal_content.dart';
import '../../core/marketing_module_catalog.dart';
import '../../core/phobes_theme.dart';
import '../../l10n/app_localizations.dart';

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

class AboutPhobesScreen extends StatelessWidget {
  final bool embedded;
  const AboutPhobesScreen({super.key, this.embedded = false});

  Widget _buildContent(BuildContext context, ColorScheme cs, bool isDark,
      bool isWeb, AppLocalizations l10n,) {
    final horizontalPadding = isWeb ? 80.0 : 24.0;
    return Center(
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
              _buildSectionTitle(context, l10n.aboutModulesTitle),
              _buildModulesGrid(context, cs, isDark, l10n),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 900;
    final l10n = AppLocalizations.of(context)!;

    if (embedded) {
      return SingleChildScrollView(
        child: _buildContent(context, cs, isDark, isWeb, l10n),
      );
    }

    return Scaffold(
      backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, cs, isAmoled && isDark, l10n.aboutPhobes),
          SliverToBoxAdapter(
            child: _buildContent(context, cs, isDark, isWeb, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, ColorScheme cs, bool amoled, String title,) {
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
                cs.primary.withOpacity(0.1),
                cs.surface,
              ],
            ),
          ),
          child: Center(
            child: Icon(Icons.auto_awesome,
                size: 40,
                color: cs.primary
                    .withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.2),),
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
              color: cs.onSurface.withOpacity(isDark ? 0.7 : 0.85),
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
                        color: cs.primary,),),
                Text(m['en']!,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,),),
                Text(m['tr']!,
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(isDark ? 0.5 : 0.7),),),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.aboutPhobesLongDesc,
            style: GoogleFonts.outfit(
              fontSize: 15,
              height: 1.6,
              color: cs.onSurface.withOpacity(isDark ? 0.7 : 0.85),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.aboutModulesDesc,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.55,
              color: cs.onSurface.withOpacity(isDark ? 0.55 : 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesGrid(
    BuildContext context,
    ColorScheme cs,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final modules = MarketingModuleCatalog.aboutModules(l10n);
    return PhobesGlassCard(
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: modules.map((m) {
              return ActionChip(
                avatar: Icon(m.icon, size: 18, color: m.color),
                label: Text(
                  m.title(l10n),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PhobesFeatureTreeScreen(),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PhobesFeatureTreeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.account_tree_rounded, size: 18),
              label: Text(l10n.features),
            ),
          ),
        ],
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
                  color: cs.primary,),),
          const SizedBox(height: 16),
          _buildFounderTile('Arda Kocaoğlu', l10n.coFounder, cs, isDark),
          const Divider(height: 32),
          _buildFounderTile('Sude Gül Çinay', l10n.coFounder, cs, isDark),

        ],
      ),
    );
  }

  Widget _buildFounderTile(
      String name, String role, ColorScheme cs, bool isDark,) {
    return Row(
      children: [
        CircleAvatar(
            backgroundColor: cs.primary.withOpacity(0.1),
            child: Text(name[0],
                style: GoogleFonts.outfit(
                    color: cs.primary, fontWeight: FontWeight.bold,),),),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: cs.onSurface,),),
          Text(role,
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(isDark ? 0.5 : 0.7),),),
        ],),
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
              l10n.yourDataYourFortress, l10n.dataNeverSold,),
          const SizedBox(height: 16),
          _buildInfoRow(context, Icons.visibility_off_rounded,
              l10n.endToEndTransparency, l10n.dataProcessingTransparency,),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => LegalDocumentScreen.open(
                context,
                LegalDocumentType.privacy,
              ),
              icon: const Icon(Icons.article_outlined, size: 18),
              label: Text(l10n.privacyPolicy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String title, String desc,) {
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
                  color: cs.onSurface,),),
          Text(desc,
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(isDark ? 0.6 : 0.8),),),
        ],),),
      ],
    );
  }
}
