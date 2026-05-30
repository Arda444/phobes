import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

enum PhobesPlatform { mobile, tablet, desktop, web }

enum PhobesFormFactor { compact, medium, expanded }

class PhobesBreakpoints {
  PhobesBreakpoints._();

  static const double compact = 600;

  static const double medium = 840;

  static const double expanded = 1200;

  static const double large = 1600;
}

class PhobesResponsive {
  PhobesResponsive._();

  static PhobesPlatform get currentPlatform {
    if (kIsWeb) return PhobesPlatform.web;
    if (Platform.isAndroid || Platform.isIOS) return PhobesPlatform.mobile;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return PhobesPlatform.desktop;
    }
    return PhobesPlatform.mobile;
  }

  static bool get isDesktopPlatform {
    if (kIsWeb) return true;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static bool get isMobilePlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  static PhobesFormFactor getFormFactor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < PhobesBreakpoints.compact) return PhobesFormFactor.compact;
    if (width < PhobesBreakpoints.medium) return PhobesFormFactor.medium;
    return PhobesFormFactor.expanded;
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < PhobesBreakpoints.compact;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= PhobesBreakpoints.compact &&
        width < PhobesBreakpoints.medium;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= PhobesBreakpoints.medium;

  static bool isLarge(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= PhobesBreakpoints.expanded;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static int getGridColumns(BuildContext context, {int baseColumns = 1}) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= PhobesBreakpoints.large) return baseColumns * 4;
    if (width >= PhobesBreakpoints.expanded) return baseColumns * 3;
    if (width >= PhobesBreakpoints.compact) return baseColumns * 2;
    return baseColumns;
  }

  static double getContentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= PhobesBreakpoints.large) return 1200;
    if (width >= PhobesBreakpoints.expanded) return 960;
    if (width >= PhobesBreakpoints.medium) return 720;
    return width;
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= PhobesBreakpoints.large) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    }
    if (width >= PhobesBreakpoints.expanded) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    }
    if (width >= PhobesBreakpoints.compact) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }

  static bool shouldShowSidebar(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= PhobesBreakpoints.expanded;

  static bool shouldShowNavRail(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= PhobesBreakpoints.compact &&
        width < PhobesBreakpoints.medium;
  }

  static bool shouldShowBottomBar(BuildContext context) =>
      MediaQuery.sizeOf(context).width < PhobesBreakpoints.compact;
}

class PhobesResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) compact;
  final Widget Function(BuildContext context)? medium;
  final Widget Function(BuildContext context)? expanded;

  const PhobesResponsiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final formFactor = PhobesResponsive.getFormFactor(context);

    switch (formFactor) {
      case PhobesFormFactor.expanded:
        return (expanded ?? medium ?? compact)(context);
      case PhobesFormFactor.medium:
        return (medium ?? compact)(context);
      case PhobesFormFactor.compact:
        return compact(context);
    }
  }
}

class PhobesContentContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const PhobesContentContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? PhobesResponsive.getContentMaxWidth(context),
        ),
        child: Padding(
          padding: padding ?? PhobesResponsive.getScreenPadding(context),
          child: child,
        ),
      ),
    );
  }
}

T responsiveValue<T>(
  BuildContext context, {
  required T compact,
  T? medium,
  T? expanded,
}) {
  final formFactor = PhobesResponsive.getFormFactor(context);
  switch (formFactor) {
    case PhobesFormFactor.expanded:
      return expanded ?? medium ?? compact;
    case PhobesFormFactor.medium:
      return medium ?? compact;
    case PhobesFormFactor.compact:
      return compact;
  }
}
