import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/legal_content.dart';
import '../../l10n/app_localizations.dart';

/// Full-screen legal document (privacy, terms, cookies).
class LegalDocumentScreen extends StatelessWidget {
  final LegalDocumentType type;
  final bool embedded;

  const LegalDocumentScreen({
    super.key,
    required this.type,
    this.embedded = false,
  });

  static void open(BuildContext context, LegalDocumentType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(type: type),
      ),
    );
  }

  String _title(AppLocalizations l10n) {
    switch (type) {
      case LegalDocumentType.privacy:
        return l10n.privacyPolicy;
      case LegalDocumentType.terms:
        return l10n.termsOfService;
      case LegalDocumentType.cookies:
        return l10n.cookiePolicy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final sections = legalSections(type, locale);

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          l10n.legalLastUpdated,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.45),
          ),
        ),
        const SizedBox(height: 20),
        for (final section in sections) ...[
          Text(
            section.title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          for (final p in section.paragraphs) ...[
            SelectableText(
              p,
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.55,
                color: cs.onSurface.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );

    if (embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title(l10n),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: body,
    );
  }
}
