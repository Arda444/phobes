import 'package:flutter/material.dart';
import '../../core/phobes_theme.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = color ?? cs.surfaceContainer;

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: PhobesTheme.defaultRadius,
        boxShadow: PhobesTheme.getCardShadow(isDark),
        border: Border.all(
          color: cs.outline.withValues(alpha: isDark ? 0.3 : 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: PhobesTheme.defaultRadius,
        child: InkWell(
          borderRadius: PhobesTheme.defaultRadius,
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
