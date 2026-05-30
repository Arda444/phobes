import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/phobes_widgets.dart';
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

class PhobesContactScreen extends StatelessWidget {
  final bool embedded;
  const PhobesContactScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 900;
    final horizontalPadding = isWeb ? 80.0 : 24.0;
    final l10n = AppLocalizations.of(context)!;

    if (embedded) {
      return SingleChildScrollView(
        child: _buildContent(context, cs, isDark, isWeb, l10n, horizontalPadding),
      );
    }

    return Scaffold(
      backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, cs, isAmoled && isDark, l10n.contact),
          SliverToBoxAdapter(child: _buildContent(context, cs, isDark, isWeb, l10n, horizontalPadding)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme cs, bool isDark,
      bool isWeb, AppLocalizations l10n, double horizontalPadding,) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, l10n.contactChannels),
              PhobesGlassCard(
                padding: const EdgeInsets.all(24),
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildContactTile(
                      Icons.alternate_email_rounded,
                      l10n.generalContact,
                      'hello@phobes.app',
                      () => _launchEmail('hello@phobes.app', l10n.aboutPhobes),
                    ),
                    const Divider(height: 32),
                    _buildContactTile(
                      Icons.support_agent_rounded,
                      l10n.supportHotline,
                      'support@phobes.app',
                      () => _launchEmail('support@phobes.app', l10n.support),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              _buildSectionTitle(context, l10n.corpInfo),
              PhobesGlassCard(
                padding: const EdgeInsets.all(24),
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Techluna Software and Design',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),),
                    const SizedBox(height: 8),
                    Text(l10n.techlunaDesc,
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: cs.onSurface.withOpacity(isDark ? 0.6 : 0.8),),),
                  ],
                ),
              ),
              const SizedBox(height: 64),
              Center(
                child: Text(
                  l10n.allRightsReserved,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 11, color: cs.onSurface.withOpacity(0.3),),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, ColorScheme cs, bool amoled, String title,) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: amoled ? Colors.black : cs.surface,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(title.toUpperCase(),
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900, letterSpacing: 2,),),
      ),
      leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),),
    );
  }

  Widget _buildContactTile(
      IconData icon, String title, String subtitle, VoidCallback onTap,) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),),
        child: Icon(icon, color: Colors.blueAccent),
      ),
      title:
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _launchEmail(String email, String subject) async {
    final Uri uri =
        Uri(scheme: 'mailto', path: email, query: 'subject=$subject');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
