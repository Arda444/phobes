import 'dart:math' as math;

import 'responsive.dart';

/// Layout metrics for the main app shell (sidebar + daily intelligence panel).
class PhobesShellMetrics {
  PhobesShellMetrics._({
    required this.viewportWidth,
    required this.sidebarWidth,
    required this.intelligencePanelWidth,
    required this.showSidebar,
    required this.showIntelligencePanel,
  });

  static const double minCenterWidth = 560;
  static const double minIntelligenceWidth = 220;
  static const double maxIntelligenceWidth = 300;
  static const double minSidebarWidth = 200;
  static const double maxSidebarWidth = 260;
  static const double collapsedSidebarWidth = 72;

  final double viewportWidth;
  final double sidebarWidth;
  final double intelligencePanelWidth;
  final bool showSidebar;
  final bool showIntelligencePanel;

  double get centerWidth {
    var w = viewportWidth;
    if (showSidebar) w -= sidebarWidth;
    if (showIntelligencePanel) w -= intelligencePanelWidth;
    return math.max(0, w);
  }

  bool get useCompactIntelligenceTypography =>
      intelligencePanelWidth > 0 && intelligencePanelWidth < 260;

  static PhobesShellMetrics fromWidth(
    double width, {
    bool sidebarCollapsed = false,
    bool intelligencePanelEnabled = true,
  }) {
    final showSidebar = width >= PhobesBreakpoints.medium;

    var sidebar = showSidebar
        ? (width * 0.14).clamp(minSidebarWidth, maxSidebarWidth)
        : 0.0;

    var remaining = width - sidebar;
    var intel = 0.0;

    if (intelligencePanelEnabled &&
        showSidebar &&
        remaining >= minCenterWidth + minIntelligenceWidth) {
      intel = (width * 0.16).clamp(minIntelligenceWidth, maxIntelligenceWidth);
      if (remaining - intel < minCenterWidth) {
        intel = math.max(
          0.0,
          remaining - minCenterWidth,
        );
        if (intel < minIntelligenceWidth) intel = 0.0;
      }
    }

    if (showSidebar && width - sidebar - intel < minCenterWidth) {
      intel = 0.0;
    }

    remaining = width - sidebar - intel;
    if (showSidebar && !sidebarCollapsed && remaining < minCenterWidth) {
      sidebar = math.max(
        minSidebarWidth,
        width - minCenterWidth,
      );
      if (width - sidebar < minCenterWidth) {
        sidebar = math.max(0, width - minCenterWidth);
      }
      intel = 0.0;
    }

    if (sidebarCollapsed && showSidebar) {
      sidebar = collapsedSidebarWidth;
    }

    return PhobesShellMetrics._(
      viewportWidth: width,
      sidebarWidth: sidebar,
      intelligencePanelWidth: intel,
      showSidebar: showSidebar && sidebar > 0,
      showIntelligencePanel: showSidebar && intel > 0,
    );
  }
}
