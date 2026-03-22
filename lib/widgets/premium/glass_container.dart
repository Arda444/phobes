import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/phobes_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final bool withBorder;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
    this.margin,
    this.gradient,
    this.withBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? PhobesTheme.defaultRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient ?? PhobesTheme.glassGradient(isDark),
              border: withBorder
                  ? Border.all(
                      color: cs.outline.withValues(alpha: isDark ? 0.2 : 0.4),
                      width: 1,
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
