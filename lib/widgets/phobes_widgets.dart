import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/navigation_keys.dart';
import '../core/phobes_theme.dart';
import '../l10n/app_localizations.dart';

class PhobesCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableGlow;
  final Color? glowColor;
  final Gradient? gradient;

  const PhobesCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.onLongPress,
    this.enableGlow = false,
    this.glowColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.only(bottom: PhobesTheme.spacingM),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? cs.surfaceVariant : null,
        borderRadius: BorderRadius.circular(PhobesTheme.borderRadiusL),
        border: Border.all(
          color: cs.outline.withOpacity(isDark ? 0.3 : 0.15),
        ),
        boxShadow: enableGlow
            ? [
                BoxShadow(
                  color: (glowColor ?? cs.primary).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ]
            : PhobesTheme.getCardShadow(isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PhobesTheme.borderRadiusL),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(PhobesTheme.borderRadiusL),
            splashColor: cs.primary.withOpacity(0.08),
            highlightColor: cs.primary.withOpacity(0.04),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(PhobesTheme.spacingL),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class PhobesGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double blur;
  final double? borderRadius;
  final VoidCallback? onTap;

  const PhobesGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.blur = 10,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: PhobesTheme.spacingM),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(borderRadius ?? PhobesTheme.borderRadiusL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              gradient: PhobesTheme.glassGradient(isDark),
              borderRadius: BorderRadius.circular(PhobesTheme.borderRadiusL),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.6),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(PhobesTheme.borderRadiusL),
                splashColor: cs.primary.withOpacity(0.08),
                child: Padding(
                  padding:
                      padding ?? const EdgeInsets.all(PhobesTheme.spacingL),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PhobesButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final Gradient? gradient;
  final double? width;
  final Color? backgroundColor;

  const PhobesButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.gradient,
    this.width,
    this.backgroundColor,
  });

  @override
  State<PhobesButton> createState() => _PhobesButtonState();
}

class _PhobesButtonState extends State<PhobesButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultGradient = LinearGradient(
      colors: [cs.primary, cs.primary.withOpacity(0.8)],
    );

    final textColor = widget.isOutlined ? cs.primary : cs.onPrimary;

    final outlinedBg = isDark ? cs.surfaceVariant : cs.surfaceVariant;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.isOutlined
                ? null
                : (widget.backgroundColor != null
                    ? null
                    : (widget.gradient ?? defaultGradient)),
            color: widget.isOutlined ? outlinedBg : widget.backgroundColor,
            borderRadius: BorderRadius.circular(PhobesTheme.borderRadiusM),
            border: widget.isOutlined
                ? Border.all(color: cs.primary, width: 1.5)
                : null,
            boxShadow: widget.isOutlined
                ? null
                : [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(PhobesTheme.borderRadiusM),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: textColor,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: textColor, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: GoogleFonts.outfit(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PhobesIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? backgroundColor;
  final double iconSize;
  final double padding;
  final double? size;
  final int? badgeCount;
  final bool enableGlow;
  final bool showBorder;
  final double borderRadius;

  const PhobesIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.backgroundColor,
    this.iconSize = 20,
    this.padding = 4,
    this.size,
    this.badgeCount,
    this.enableGlow = false,
    this.showBorder = true,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = color ?? cs.onSurface.withOpacity(0.8);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          border: showBorder
              ? Border.all(
                  color: cs.outline.withOpacity(isDark ? 0.08 : 0.05),
                )
              : null,
          boxShadow: enableGlow
              ? [
                  BoxShadow(
                    color: (color ?? cs.primary).withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: baseColor, size: iconSize),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: cs.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.black : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      badgeCount! > 9 ? '9+' : '$badgeCount',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PhobesTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final int? maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  /// Pass [] to disable browser autofill on this field.
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const PhobesTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.autofocus = false,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      autofocus: autofocus,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 15),
      cursorColor: cs.primary,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: cs.onSurface.withOpacity(0.4), size: 22)
            : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(
                  suffixIcon,
                  color: cs.onSurface.withOpacity(0.4),
                  size: 22,
                ),
                onPressed: onSuffixTap,
              )
            : null,
      ),
    );
  }
}

class PhobesTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final int? maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool autofocus;
  final bool isLarge;

  /// Pass [] to disable browser autofill on this field.
  final Iterable<String>? autofillHints;

  const PhobesTextFormField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.autofocus = false,
    this.isLarge = false,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      autofocus: autofocus,
      autofillHints: autofillHints,
      style: GoogleFonts.outfit(
        color: cs.onSurface,
        fontSize: isLarge ? 24 : 15,
        fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
      ),
      cursorColor: cs.primary,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        hintStyle: GoogleFonts.outfit(
          color: cs.onSurface.withOpacity(0.2),
          fontSize: isLarge ? 24 : 15,
          fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: cs.onSurface.withOpacity(0.4), size: 22)
            : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(
                  suffixIcon,
                  color: cs.onSurface.withOpacity(0.4),
                  size: 22,
                ),
                onPressed: onSuffixTap,
              )
            : null,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(
          vertical: isLarge ? 4 : 12,
          horizontal: prefixIcon == null ? 0 : 12,
        ),
      ),
    );
  }
}

class PhobesChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;

  const PhobesChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.color,
    this.icon,
  });

  @override
  State<PhobesChip> createState() => _PhobesChipState();
}

class _PhobesChipState extends State<PhobesChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = widget.color ?? cs.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSelected ? 20 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: widget.isSelected
                ? chipColor.withOpacity(isDark ? 0.15 : 0.1)
                : Colors.transparent,
            border: Border.all(
              color: widget.isSelected
                  ? chipColor.withOpacity(0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: chipColor.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: Icon(
                    widget.icon,
                    key: ValueKey(widget.isSelected),
                    size: widget.isSelected ? 18 : 16,
                    color: widget.isSelected
                        ? chipColor
                        : cs.onSurface.withOpacity(0.5),
                  ),
                ),
                SizedBox(width: widget.isSelected ? 8 : 6),
              ],
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                style: GoogleFonts.outfit(
                  color: widget.isSelected
                      ? (isDark
                          ? Colors.white
                          : chipColor.withRed(
                              ((chipColor.r * 255.0).round() - 50)
                                  .clamp(0, 255),
                            ))
                      : cs.onSurface.withOpacity(0.6),
                  fontSize: widget.isSelected ? 15 : 14,
                  fontWeight:
                      widget.isSelected ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: widget.isSelected ? 0.5 : 0.2,
                ),
                child: Text(widget.label),
              ),
              if (widget.isSelected && widget.icon == null) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: chipColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: chipColor.withOpacity(0.8),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PhobesAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showGlow;
  final Color? glowColor;
  final VoidCallback? onTap;

  const PhobesAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 48,
    this.showGlow = false,
    this.glowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: PhobesTheme.primaryGradient,
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: (glowColor ?? cs.primary).withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: imageUrl != null
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _buildInitial(cs),
                  placeholder: (_, __) => _buildInitial(cs),
                ),
              )
            : _buildInitial(cs),
      ),
    );
  }

  Widget _buildInitial(ColorScheme cs) {
    return Center(
      child: Text(
        (name?.isNotEmpty == true) ? name![0].toUpperCase() : '?',
        style: GoogleFonts.outfit(
          color: cs.onPrimary,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class PhobesLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const PhobesLoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  State<PhobesLoadingIndicator> createState() => _PhobesLoadingIndicatorState();
}

class _PhobesLoadingIndicatorState extends State<PhobesLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return RotationTransition(
      turns: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              widget.color ?? cs.primary,
              Colors.transparent,
            ],
          ),
        ),
        child: Center(
          child: Container(
            width: widget.size - 8,
            height: widget.size - 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
        ),
      ),
    );
  }
}

class PhobesSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  const PhobesSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        top: PhobesTheme.spacingXL,
        bottom: PhobesTheme.spacingM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: cs.onSurface.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.outfit(
                    color: cs.onSurface.withOpacity(0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class PhobesStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const PhobesStatCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PhobesCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: cs.onSurface.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                color: cs.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (unit != null)
            Text(
              unit!,
              style: GoogleFonts.outfit(
                color: cs.onSurface.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

class PhobesEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  // subtitle and description are interchangeable aliases.
  final String? subtitle;
  final String? description;
  final String? buttonText;
  // onButtonPressed and onButtonTap are interchangeable aliases.
  final VoidCallback? onButtonPressed;
  final VoidCallback? onButtonTap;
  final IconData? buttonIcon;

  const PhobesEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.description,
    this.buttonText,
    this.onButtonPressed,
    this.onButtonTap,
    this.buttonIcon,
  });

  String? get _body => subtitle ?? description;
  VoidCallback? get _action => onButtonPressed ?? onButtonTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 52, color: cs.primary.withOpacity(0.6)),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: cs.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              if (_body != null) ...[
                const SizedBox(height: 8),
                Text(
                  _body!,
                  style: GoogleFonts.outfit(
                    color: cs.onSurface.withOpacity(0.45),
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (buttonText != null && _action != null) ...[
                const SizedBox(height: 28),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: PhobesButton(
                    text: buttonText!,
                    icon: buttonIcon,
                    onPressed: _action,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PhobesSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const PhobesSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  static Widget card({double height = 80}) {
    return Builder(
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(bottom: PhobesTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhobesSkeleton(width: double.infinity, height: height),
            ],
          ),
        );
      },
    );
  }

  static Widget listTile() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          PhobesSkeleton(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhobesSkeleton(width: 160, height: 14),
                SizedBox(height: 8),
                PhobesSkeleton(width: 100, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<PhobesSkeleton> createState() => _PhobesSkeletonState();
}

class _PhobesSkeletonState extends State<PhobesSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: cs.onSurface.withOpacity(_animation.value * 0.15),
            borderRadius: widget.borderRadius ??
                BorderRadius.circular(PhobesTheme.borderRadiusS),
          ),
        );
      },
    );
  }
}

class PhobesSwipeableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Color? leftColor;
  final Color? rightColor;
  final IconData? leftIcon;
  final IconData? rightIcon;
  final String? leftLabel;
  final String? rightLabel;

  const PhobesSwipeableCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftColor,
    this.rightColor,
    this.leftIcon,
    this.rightIcon,
    this.leftLabel,
    this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key ?? UniqueKey(),
      background: _buildBackground(
        color: rightColor ?? PhobesTheme.kSuccessColor,
        icon: rightIcon ?? Icons.check_rounded,
        label: rightLabel,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildBackground(
        color: leftColor ?? PhobesTheme.kErrorColor,
        icon: leftIcon ?? Icons.delete_rounded,
        label: leftLabel,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd && onSwipeRight != null) {
          onSwipeRight!();
          return false;
        }
        if (direction == DismissDirection.endToStart && onSwipeLeft != null) {
          onSwipeLeft!();
          return false;
        }
        return false;
      },
      child: child,
    );
  }

  Widget _buildBackground({
    required Color color,
    required IconData icon,
    String? label,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: PhobesTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(PhobesTheme.borderRadiusL),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PhobesBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool showCloseButton;
  final double? padding;

  const PhobesBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.showCloseButton = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: 12,
        left: padding ?? 24,
        right: padding ?? 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + (padding ?? 24),
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: cs.outline.withOpacity(isDark ? 0.1 : 0.05),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
              if (showCloseButton)
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool isScrollControlled = true,
    bool showDragHandle = true,
    double? maxHeight,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      constraints:
          maxHeight != null ? BoxConstraints(maxHeight: maxHeight) : null,
      builder: builder,
    );
  }

  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    String? message,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final resolvedConfirm = confirmText ?? l10n.confirm;
    final resolvedCancel = cancelText ?? l10n.cancel;
    return show<bool>(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: title,
        child: Column(
          children: [
            if (message != null) ...[
              Text(
                message,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
            ],
            Row(
              children: [
                Expanded(
                  child: PhobesButton(
                    text: resolvedCancel,
                    isOutlined: true,
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PhobesButton(
                    text: resolvedConfirm,
                    gradient: confirmColor != null
                        ? LinearGradient(
                            colors: [
                              confirmColor,
                              confirmColor.withOpacity(0.8),
                            ],
                          )
                        : null,
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (color ?? cs.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color ?? cs.primary),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PhobesSnackbar {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    PhobesSnackbarType type = PhobesSnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final rootNav = rootNavigatorKey.currentState;
    final overlay = rootNav?.overlay ??
        Navigator.maybeOf(context, rootNavigator: true)?.overlay ??
        Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _timer?.cancel();
    _entry?.remove();

    final themeContext = rootNav?.context ??
        Navigator.maybeOf(context, rootNavigator: true)?.context ??
        context;
    final cs = Theme.of(themeContext).colorScheme;
    final isDark = Theme.of(themeContext).brightness == Brightness.dark;
    final top = MediaQuery.viewPaddingOf(themeContext).top + 12;
    final screenW = MediaQuery.sizeOf(themeContext).width;
    final toastW = (screenW * 0.42).clamp(280.0, 400.0);

    final (Color accent, IconData icon) = switch (type) {
      PhobesSnackbarType.success => (
          PhobesTheme.kSuccessColor,
          Icons.check_circle_rounded,
        ),
      PhobesSnackbarType.error => (
          PhobesTheme.kErrorColor,
          Icons.error_rounded,
        ),
      PhobesSnackbarType.warning => (
          PhobesTheme.kWarningColor,
          Icons.warning_rounded,
        ),
      PhobesSnackbarType.info => (PhobesTheme.kInfoColor, Icons.info_rounded),
    };

    _entry = OverlayEntry(
      builder: (ctx) => IgnorePointer(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(top: top, right: 16),
            child: IgnorePointer(
              ignoring: false,
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Transform.translate(
                    offset: Offset((1 - value) * 24, 0),
                    child: Opacity(opacity: value, child: child),
                  ),
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accent.withOpacity(0.35)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(isDark ? 0.45 : 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: SizedBox(
                          width: toastW,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(icon, color: accent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  message,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              if (actionLabel != null) ...[
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    onAction?.call();
                                    _dismiss();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    actionLabel,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_entry!);
    _timer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

enum PhobesSnackbarType { success, error, warning, info }

class PhobesPremiumAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final double height;
  final PreferredSizeWidget? bottom;

  const PhobesPremiumAppBar({
    super.key,
    required this.title,
    this.trailing,
    this.onBackPressed,
    this.showBackButton = true,
    this.height = 110.0,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            topPadding + 12,
            20,
            bottom == null ? 20 : 10,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary.withOpacity(0.15),
                cs.surface,
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: cs.primary.withOpacity(0.1),
                width: 1.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showBackButton) ...[
                    PhobesIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      backgroundColor: cs.surface.withOpacity(0.5),
                      onTap: onBackPressed ?? () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 16),
                    trailing!,
                  ],
                ],
              ),
              if (bottom != null) ...[
                const SizedBox(height: 12),
                bottom!,
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));
}
