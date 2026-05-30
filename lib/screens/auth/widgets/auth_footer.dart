import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/about_phobes_screen.dart';
import '../../common/phobes_feature_tree_screen.dart';
import '../../common/phobes_contact_screen.dart';
import '../../common/legal_document_screen.dart';
import '../../../core/legal_content.dart';

class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FooterTextLink(
          text: l10n.about,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutPhobesScreen()),
          ),
        ),
        _FooterSeparator(cs: cs),
        _FooterTextLink(
          text: l10n.features,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PhobesFeatureTreeScreen()),
          ),
        ),
        _FooterSeparator(cs: cs),
        _FooterTextLink(
          text: l10n.support,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PhobesContactScreen()),
          ),
        ),
        _FooterSeparator(cs: cs),
        _FooterTextLink(
          text: l10n.privacyPolicy,
          onTap: () => LegalDocumentScreen.open(
            context,
            LegalDocumentType.privacy,
          ),
        ),
      ],
    );
  }
}

class _FooterTextLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FooterTextLink({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
    );
  }
}

class _FooterSeparator extends StatelessWidget {
  final ColorScheme cs;

  const _FooterSeparator({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '|',
        style: GoogleFonts.outfit(
          color: cs.onSurface.withOpacity(0.1),
          fontSize: 10,
        ),
      ),
    );
  }
}
