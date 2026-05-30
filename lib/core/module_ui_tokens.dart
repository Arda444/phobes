import 'package:flutter/material.dart';

import 'responsive.dart';

/// Shared layout tokens for module headers, tabs, and form presenters.
class ModuleUiTokens {
  ModuleUiTokens._();

  /// Title row height (no custom content).
  static const double toolbarHeight = 88;

  /// Budget net-worth row and similar extended headers.
  static const double toolbarHeightExtended = 112;

  /// Tab strip outer height (`PreferredSize`).
  static const double tabBarHeight = 56;

  /// Inner segmented tab control height.
  static const double tabControlHeight = 44;

  static const double headerBottomRadius = 32;

  static const double actionSpacing = 6;

  static const double headerHorizontalPadding = 20;

  /// Module header action buttons (gradient bar).
  static const Color headerActionIconColor = Colors.white;
  static const double headerActionIconSize = 20;
  static const double headerActionButtonSize = 38;
  static const double headerActionBorderRadius = 12;

  static bool isCompactHeader(BuildContext context) =>
      PhobesResponsive.isCompact(context);

  static double headerActionButtonSizeOf(BuildContext context) =>
      responsiveValue(
        context,
        compact: 32,
        medium: 36,
        expanded: headerActionButtonSize,
      );

  static double headerActionIconSizeOf(BuildContext context) =>
      responsiveValue(
        context,
        compact: 17,
        medium: 18,
        expanded: headerActionIconSize,
      );

  static double headerActionPaddingOf(BuildContext context) =>
      responsiveValue(
        context,
        compact: 6,
        medium: 8,
        expanded: 9,
      );

  static double headerActionBorderRadiusOf(BuildContext context) =>
      responsiveValue(
        context,
        compact: 10,
        medium: 11,
        expanded: headerActionBorderRadius,
      );

  static double headerActionSpacingOf(BuildContext context) =>
      responsiveValue(
        context,
        compact: 4,
        medium: 5,
        expanded: actionSpacing,
      );

  static double headerHorizontalPaddingOf(BuildContext context) =>
      responsiveValue(
        context,
        compact: 14,
        medium: 17,
        expanded: headerHorizontalPadding,
      );

  static double headerTitleFontSizeOf(BuildContext context) =>
      responsiveValue(
        context,
        compact: 17,
        medium: 18,
        expanded: 20,
      );

  static double headerSubtitleFontSizeOf(BuildContext context) =>
      responsiveValue(
        context,
        compact: 10,
        medium: 10,
        expanded: 11,
      );

  static double headerEmojiSizeOf(BuildContext context) =>
      responsiveValue(
        context,
        compact: 22,
        medium: 24,
        expanded: 26,
      );

  static double headerLeadingIconTileSizeOf(BuildContext context) =>
      responsiveValue(
        context,
        compact: 32,
        medium: 35,
        expanded: 38,
      );

  static double headerLeadingIconSizeOf(BuildContext context) =>
      responsiveValue(
        context,
        compact: 17,
        medium: 18,
        expanded: 20,
      );

  static double toolbarHeightOf(
    BuildContext context, {
    bool extended = false,
  }) {
    if (extended) {
      return responsiveValue(
        context,
        compact: 100,
        medium: 106,
        expanded: toolbarHeightExtended,
      );
    }
    return responsiveValue(
      context,
      compact: 76,
      medium: 82,
      expanded: toolbarHeight,
    );
  }

  static Color headerActionBackground(BuildContext context, [double opacity = 0.3]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.black.withOpacity(opacity) : Colors.white.withOpacity(opacity);
  }

  /// Matches [PhobesFormWrapper] wide layout breakpoint.
  static const double formWideBreakpoint = 900;

  static const double defaultPanelWidth = 520;

  /// Bottom inset when floating nav bar is visible (mobile).
  static double bottomNavInset(BuildContext context) {
    final padding = MediaQuery.paddingOf(context).bottom;
    return padding + 80;
  }

  static double resolvePanelWidth(BuildContext context, {double? override}) {
    if (override != null) return override;
    final w = MediaQuery.sizeOf(context).width;
    return (w * 0.4).clamp(400.0, defaultPanelWidth);
  }

  static bool isWideForm(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= formWideBreakpoint;
}
