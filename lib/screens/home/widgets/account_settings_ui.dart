import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/module_l10n.dart';
import '../../../core/phobes_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/module_settings_service.dart';
import '../../../widgets/phobes_widgets.dart';

/// Premium account screen visual system.
class AccountSettingsUi {
  AccountSettingsUi._();

  static Future<PackageInfo>? _packageInfoFuture;
  static Future<PackageInfo> _loadPackageInfo() =>
      _packageInfoFuture ??= PackageInfo.fromPlatform();

  static double xpProgress(int level, int xp) {
    final threshold = (level * 750).clamp(750, 999999);
    return ((xp % threshold) / threshold).clamp(0.0, 1.0);
  }

  static Widget pageBackground(ColorScheme cs, {required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: 0.14),
                  cs.surface,
                  cs.surfaceContainerLowest.withValues(alpha: 0.4),
                ],
                stops: const [0, 0.35, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -40,
          child: _glowOrb(220, cs.primary.withValues(alpha: 0.18)),
        ),
        Positioned(
          top: 120,
          left: -60,
          child: _glowOrb(160, cs.tertiary.withValues(alpha: 0.12)),
        ),
        Positioned.fill(child: child),
      ],
    );
  }

  static Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  static Widget topBar({
    required BuildContext context,
    required String title,
    required ColorScheme cs,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [cs.onSurface, cs.primary],
                  ).createShader(bounds),
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.05,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)!.accountHeaderSubtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  static Widget profileBanner({
    required BuildContext context,
    required ColorScheme cs,
    required String displayName,
    required String email,
    required String birthDate,
    required String? photoUrl,
    required int xp,
    required int level,
    required int enabledModules,
    required int totalModules,
    required VoidCallback onEditPhoto,
    required bool compact,
  }) {
    final progress = xpProgress(level, xp);
    final name = displayName.trim().isEmpty
        ? AppLocalizations.of(context)!.defaultUserName
        : displayName.trim();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, 18),
            spreadRadius: -8,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(cs.primary, Colors.black, 0.08)!,
                      cs.primary,
                      cs.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.85, -0.6),
                    radius: 1.1,
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -50,
              right: -30,
              child: _glowOrb(140, Colors.white.withValues(alpha: 0.1)),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: _glowOrb(100, Colors.white.withValues(alpha: 0.06)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 20 : 28,
                compact ? 24 : 30,
                compact ? 20 : 28,
                compact ? 24 : 28,
              ),
              child: compact
                  ? _profileColumn(
                      cs: cs,
                      name: name,
                      email: email,
                      birthDate: birthDate,
                      photoUrl: photoUrl,
                      xp: xp,
                      level: level,
                      progress: progress,
                      enabledModules: enabledModules,
                      totalModules: totalModules,
                      onEditPhoto: onEditPhoto,
                    )
                  : _profileRow(
                      cs: cs,
                      name: name,
                      email: email,
                      birthDate: birthDate,
                      photoUrl: photoUrl,
                      xp: xp,
                      level: level,
                      progress: progress,
                      enabledModules: enabledModules,
                      totalModules: totalModules,
                      onEditPhoto: onEditPhoto,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _profileRow({
    required ColorScheme cs,
    required String name,
    required String email,
    required String birthDate,
    required String? photoUrl,
    required int xp,
    required int level,
    required double progress,
    required int enabledModules,
    required int totalModules,
    required VoidCallback onEditPhoto,
  }) {
    return Row(
      children: [
        _avatarBlock(
          cs: cs,
          name: name,
          photoUrl: photoUrl,
          size: 100,
          level: level,
          onEditPhoto: onEditPhoto,
        ),
        const SizedBox(width: 28),
        Expanded(
          child: _profileMeta(
            cs: cs,
            name: name,
            email: email,
            birthDate: birthDate,
            xp: xp,
            level: level,
            progress: progress,
            enabledModules: enabledModules,
            totalModules: totalModules,
            lightText: true,
          ),
        ),
      ],
    );
  }

  static Widget _profileColumn({
    required ColorScheme cs,
    required String name,
    required String email,
    required String birthDate,
    required String? photoUrl,
    required int xp,
    required int level,
    required double progress,
    required int enabledModules,
    required int totalModules,
    required VoidCallback onEditPhoto,
  }) {
    return Column(
      children: [
        _avatarBlock(
          cs: cs,
          name: name,
          photoUrl: photoUrl,
          size: 92,
          level: level,
          onEditPhoto: onEditPhoto,
        ),
        const SizedBox(height: 20),
        _profileMeta(
          cs: cs,
          name: name,
          email: email,
          birthDate: birthDate,
          xp: xp,
          level: level,
          progress: progress,
          enabledModules: enabledModules,
          totalModules: totalModules,
          lightText: true,
          center: true,
        ),
      ],
    );
  }

  static Widget _avatarBlock({
    required ColorScheme cs,
    required String name,
    required String? photoUrl,
    required double size,
    required int level,
    required VoidCallback onEditPhoto,
  }) {
    return GestureDetector(
      onTap: onEditPhoto,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size + 16,
            height: size + 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            child: PhobesAvatar(imageUrl: photoUrl, name: name, size: size),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.camera_alt_rounded, size: 17, color: cs.primary),
            ),
          ),
          Positioned(
            top: -8,
            left: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF59D), Color(0xFFFFB300)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.military_tech_rounded,
                      size: 12, color: Color(0xFF5D4037),),
                  const SizedBox(width: 4),
                  Text(
                    'LV $level',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4E342E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _profileMeta({
    required ColorScheme cs,
    required String name,
    required String email,
    required String birthDate,
    required int xp,
    required int level,
    required double progress,
    required int enabledModules,
    required int totalModules,
    required bool lightText,
    bool center = false,
  }) {
    final titleColor = lightText ? Colors.white : cs.onSurface;
    final subColor = lightText
        ? Colors.white.withValues(alpha: 0.82)
        : cs.onSurface.withValues(alpha: 0.55);

    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          name,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.outfit(
            fontSize: center ? 24 : 28,
            fontWeight: FontWeight.w800,
            color: titleColor,
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          email,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.outfit(fontSize: 13.5, color: subColor),
        ),
        if (birthDate.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: center ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(Icons.cake_outlined,
                  size: 14, color: subColor.withValues(alpha: 0.9),),
              const SizedBox(width: 4),
              Text(
                birthDate,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: subColor.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: center ? WrapAlignment.center : WrapAlignment.start,
          children: [
            _glassStatChip(
              icon: Icons.bolt_rounded,
              label: '$xp XP',
              light: lightText,
            ),
            _glassStatChip(
              icon: Icons.apps_rounded,
              label: '$enabledModules / $totalModules',
              light: lightText,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _xpBar(level: level, progress: progress, lightText: lightText, cs: cs),
      ],
    );
  }

  static Widget _xpBar({
    required int level,
    required double progress,
    required bool lightText,
    required ColorScheme cs,
  }) {
    final subColor = lightText
        ? Colors.white.withValues(alpha: 0.75)
        : cs.onSurface.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Seviye $level',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: subColor,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: lightText ? Colors.white : cs.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Stack(
            children: [
              Container(
                height: 10,
                color: lightText
                    ? Colors.white.withValues(alpha: 0.18)
                    : cs.onSurface.withValues(alpha: 0.08),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: lightText
                          ? [Colors.white, Colors.white.withValues(alpha: 0.7)]
                          : [cs.primary, cs.primary.withValues(alpha: 0.65)],
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _glassStatChip({
    required IconData icon,
    required String label,
    required bool light,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: light
              ? Colors.white.withValues(alpha: 0.28)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: light ? Colors.white : null),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: light ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }

  static Widget section({
    required String title,
    required IconData icon,
    required ColorScheme cs,
    required Widget child,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.35)],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              _sectionHeaderIcon(icon: icon, color: cs.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.48),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: cs.surfaceContainerLow.withValues(alpha: 0.85),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  static Widget actionRow({
    required ColorScheme cs,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDanger = false,
    Widget? trailing,
  }) {
    final titleColor = isDanger ? cs.error : cs.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              _rowIconBox(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.48),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget switchRow({
    required ColorScheme cs,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required ValueListenable<bool> listenable,
    required void Function(bool) onChanged,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (context, value, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _rowIconBox(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.48),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: color,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _sectionHeaderIcon({
    required IconData icon,
    required Color color,
  }) {
    return _iconBadge(icon: icon, color: color, size: 42, iconSize: 22);
  }

  /// Sabit boyut — Row taşmasında küçülmez; dolu zemin + beyaz ikon.
  static Widget rowIcon({required IconData icon, required Color color}) =>
      _rowIconBox(icon: icon, color: color);

  static Widget _rowIconBox({
    required IconData icon,
    required Color color,
  }) {
    return _iconBadge(icon: icon, color: color, size: 40, iconSize: 20);
  }

  static Widget _iconBadge({
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: Colors.white,
            fill: 1,
            grade: 0,
            opticalSize: iconSize,
          ),
        ),
      ),
    );
  }

  static Widget rowDivider(ColorScheme cs) {
    return Divider(
      height: 1,
      indent: 64,
      endIndent: 12,
      color: cs.outlineVariant.withValues(alpha: 0.35),
    );
  }

  static Widget themePanel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: PhobesTheme.themeMode,
            builder: (context, mode, _) {
              return Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    _themeSegment(
                      context,
                      ThemeMode.light,
                      l10n.themeDay,
                      Icons.light_mode_rounded,
                      mode == ThemeMode.light,
                    ),
                    _themeSegment(
                      context,
                      ThemeMode.dark,
                      l10n.themeNight,
                      Icons.dark_mode_rounded,
                      mode == ThemeMode.dark,
                    ),
                    _themeSegment(
                      context,
                      ThemeMode.system,
                      l10n.themeSystem,
                      Icons.settings_suggest_rounded,
                      mode == ThemeMode.system,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          switchRow(
            cs: cs,
            icon: Icons.contrast_rounded,
            title: l10n.themeAmoledTitle,
            subtitle: l10n.themeAmoledSubtitle,
            color: Colors.blueGrey,
            listenable: PhobesTheme.amoledMode,
            onChanged: PhobesTheme.setAmoledMode,
          ),
          const SizedBox(height: 12),
          _uiScaleSelector(context, cs, l10n),
          const SizedBox(height: 8),
          Text(
            l10n.accentColorLabel,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<Color>(
            valueListenable: PhobesTheme.userAccentColor,
            builder: (context, accentColor, _) {
              return SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: PhobesTheme.accentColorOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final color = PhobesTheme.accentColorOptions[index];
                    final selected = color == accentColor;
                    return GestureDetector(
                      onTap: () => PhobesTheme.setAccentColor(color),
                      child: AnimatedContainer(
                        duration: PhobesTheme.animFast,
                        width: selected ? 48 : 42,
                        height: selected ? 48 : 42,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: cs.onSurface, width: 2.5)
                              : Border.all(
                                  color: cs.outline.withValues(alpha: 0.2),
                                ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.55),
                                    blurRadius: 14,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 22,)
                            : null,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget _uiScaleSelector(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    return ValueListenableBuilder<double>(
      valueListenable: PhobesTheme.uiScale,
      builder: (context, current, _) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.zoom_in_rounded,
                      color: Colors.indigo,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.uiScaleLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.uiScaleSubtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: PhobesTheme.uiScaleOptions.map((scale) {
                    final selected = (current - scale).abs() < 0.01;
                    return _uiScaleSegment(context, cs, scale, selected);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _uiScaleSegment(
    BuildContext context,
    ColorScheme cs,
    double scale,
    bool selected,
  ) {
    final percentLabel = '${(scale * 100).round()}%';
    return Expanded(
      child: GestureDetector(
        onTap: () => PhobesTheme.setUiScale(scale),
        child: AnimatedContainer(
          duration: PhobesTheme.animFast,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              percentLabel,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? cs.onPrimary
                    : cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _themeSegment(
    BuildContext context,
    ThemeMode mode,
    String label,
    IconData icon,
    bool selected,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: () => PhobesTheme.setThemeMode(mode),
        child: AnimatedContainer(
          duration: PhobesTheme.animFast,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected
                      ? cs.onPrimary
                      : cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget modulesPanel({
    required AppLocalizations l10n,
    required ColorScheme cs,
    required List<String> disabledModules,
    required String customNavButton,
    required bool expanded,
    required VoidCallback onToggleExpanded,
    /// [isCurrentlyEnabled] — kartın şu anki durumu; toggle sonrası devre dışı = bu değer.
    required void Function(String id, bool isCurrentlyEnabled) onModuleToggle,
    required void Function(String id) onNavButtonChanged,
  }) {
    final total = ModuleSettingsService.appModules.length;
    final enabled = total - disabledModules.length;

    final eligible = ModuleSettingsService.appModules
        .where((m) => m.navShortcutEligible && !disabledModules.contains(m.id))
        .toList();
    final effectiveNav = eligible.any((m) => m.id == customNavButton)
        ? customNavButton
        : (eligible.isNotEmpty ? eligible.first.id : 'teams');

    return section(
      title: l10n.modulesPanelTitle,
      subtitle: l10n.modulesPanelSubtitle(enabled),
      icon: Icons.grid_view_rounded,
      cs: cs,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.1),
                    cs.primary.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.touch_app_rounded, color: cs.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.modulesNavShortcutTitle,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            l10n.modulesNavShortcutSubtitle,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.48),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: effectiveNav,
                        borderRadius: BorderRadius.circular(12),
                        items: eligible
                            .map(
                              (m) => DropdownMenuItem(
                                value: m.id,
                                child: Text(
                                  moduleLocalizedName(l10n, m.id),
                                  style: GoogleFonts.outfit(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) onNavButtonChanged(v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  l10n.modulesVisibleTitle,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onToggleExpanded,
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                  ),
                  label: Text(
                      expanded ? l10n.modulesCollapse : l10n.modulesExpandAll),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final cols = w >= 1100
                        ? 6
                        : w >= 880
                            ? 5
                            : w >= 640
                                ? 4
                                : w >= 420
                                    ? 3
                                    : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.35,
                      ),
                      itemCount: ModuleSettingsService.appModules.length,
                      itemBuilder: (context, i) {
                        final m = ModuleSettingsService.appModules[i];
                        final on = !disabledModules.contains(m.id);
                        return _moduleCard(
                          module: m,
                          displayName: moduleLocalizedName(l10n, m.id),
                          enabled: on,
                          cs: cs,
                          activeLabel: l10n.modulesStatusActive,
                          hiddenLabel: l10n.modulesStatusHidden,
                          onTap: () => onModuleToggle(m.id, on),
                        );
                      },
                    );
                  },
                ),
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: PhobesTheme.animNormal,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _moduleCard({
    required AppModuleSetting module,
    required String displayName,
    required bool enabled,
    required ColorScheme cs,
    required String activeLabel,
    required String hiddenLabel,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
          duration: PhobesTheme.animFast,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      module.color.withValues(alpha: 0.2),
                      module.color.withValues(alpha: 0.06),
                    ],
                  )
                : null,
            color: enabled
                ? null
                : cs.surfaceContainerHighest.withValues(alpha: 0.45),
            border: Border.all(
              color: enabled
                  ? module.color.withValues(alpha: 0.35)
                  : cs.outlineVariant.withValues(alpha: 0.3),
              width: enabled ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _iconBadge(
                    icon: module.icon,
                    color: enabled
                        ? module.color
                        : cs.onSurface.withValues(alpha: 0.35),
                    size: 36,
                    iconSize: 18,
                  ),
                  const Spacer(),
                  Transform.scale(
                    scale: 0.72,
                    child: Switch(
                      value: enabled,
                      onChanged: (_) => onTap(),
                      activeThumbColor: module.color,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: enabled
                      ? cs.onSurface
                      : cs.onSurface.withValues(alpha: 0.38),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                enabled ? activeLabel : hiddenLabel,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? module.color
                      : cs.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget footer(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<PackageInfo>(
            future: _loadPackageInfo(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '';
              final build = snapshot.data?.buildNumber ?? '';
              final label = version.isEmpty
                  ? 'Phobes'
                  : (build.isEmpty || build == '0')
                      ? 'Phobes v$version'
                      : 'Phobes v$version ($build)';
              return Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  color: cs.onSurface.withValues(alpha: 0.28),
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.code_rounded, size: 15, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'Techluna Software',
                style: GoogleFonts.outfit(
                  color: cs.primary.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
