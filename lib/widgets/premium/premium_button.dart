import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/phobes_theme.dart';

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isPrimary;
  final bool isLoading;

  const PremiumButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.isPrimary = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    final gradient = isPrimary
        ? PhobesTheme.primaryGradient
        : PhobesTheme.cardGradient(isDark);

    final textColor = isPrimary ? cs.onPrimary : cs.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isPrimary ? PhobesTheme.glowShadow(cs.primary) : [],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: textColor, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: GoogleFonts.outfit(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
