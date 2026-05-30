import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/phobes_theme.dart';
import '../../../l10n/app_localizations.dart';

class AuthHeader extends StatelessWidget {
  final bool isLogin;
  
  const AuthHeader({super.key, required this.isLogin});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        FadeInDown(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: PhobesTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text('P',
                  style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: cs.onPrimary,
                  ),),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FadeInDown(
          delay: const Duration(milliseconds: 100),
          child: Text(
            l10n.appTitle,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FadeInDown(
          delay: const Duration(milliseconds: 150),
          child: Text(
            isLogin ? l10n.welcomeBack : l10n.createAccount,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: cs.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }
}
