import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/module_ui_tokens.dart';
import '../l10n/app_localizations.dart';

/// Rich module help content for the info button popup.
class PhobesModuleInfoContent {
  final String title;
  final String intro;
  final List<PhobesInfoSection> sections;
  final List<String> tips;

  const PhobesModuleInfoContent({
    required this.title,
    required this.intro,
    this.sections = const [],
    this.tips = const [],
  });

  /// Back-compat: single paragraph from legacy [infoText].
  factory PhobesModuleInfoContent.fromPlain(String title, String body) {
    return PhobesModuleInfoContent(title: title, intro: body);
  }
}

class PhobesInfoSection {
  final String title;
  final List<String> bullets;
  final IconData icon;

  const PhobesInfoSection({
    required this.title,
    required this.bullets,
    this.icon = Icons.check_circle_outline_rounded,
  });
}

/// Shows module help as a centered dialog (wide) or draggable sheet (compact).
class PhobesModuleInfo {
  PhobesModuleInfo._();

  static Future<void> show(
    BuildContext context, {
    required PhobesModuleInfoContent content,
  }) {
    final isCompact = !ModuleUiTokens.isWideForm(context);
    if (isCompact) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) => _InfoSheet(
            content: content,
            scrollController: scrollController,
          ),
        ),
      );
    }
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
          child: _InfoBody(content: content),
        ),
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  final PhobesModuleInfoContent content;
  final ScrollController scrollController;

  const _InfoSheet({
    required this.content,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: _InfoBody(content: content, embedded: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBody extends StatelessWidget {
  final PhobesModuleInfoContent content;
  final bool embedded;

  const _InfoBody({required this.content, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final surface = isDark ? const Color(0xFF1A1A1A) : cs.surface;

    return Material(
      color: embedded ? Colors.transparent : surface,
      borderRadius: embedded ? null : BorderRadius.circular(24),
      clipBehavior: embedded ? Clip.none : Clip.antiAlias,
      child: embedded
          ? _buildScrollContent(context, cs, l10n)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: _buildScrollContent(context, cs, l10n),
            ),
    );
  }

  Widget _buildScrollContent(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations? l10n,
  ) {
    final dismiss = l10n?.moduleInfoGotIt ?? 'OK';
    final tipsTitle = l10n?.moduleInfoTipsTitle ?? 'Tips';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.info_outline_rounded, color: cs.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                content.title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ),
            if (!embedded)
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
                color: cs.onSurface.withOpacity(0.5),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          content.intro,
          style: GoogleFonts.outfit(
            fontSize: 14,
            height: 1.55,
            color: cs.onSurface.withOpacity(0.75),
          ),
        ),
        for (final section in content.sections) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(section.icon, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                section.title,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final bullet in section.bullets)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: TextStyle(color: cs.primary, fontSize: 14)),
                  Expanded(
                    child: Text(
                      bullet,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        height: 1.45,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (content.tips.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      tipsTitle,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final tip in content.tips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      tip,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        height: 1.4,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              dismiss,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
