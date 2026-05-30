import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'module_ui_tokens.dart';
import 'page_transitions.dart';
import 'phobes_shell_metrics.dart';
import '../services/module_settings_service.dart';

/// How a detail screen is presented on wide layouts.
enum DetailPresentation {
  /// Right-side slide panel (tasks, books, etc.).
  panel,

  /// Full-height center column between sidebar and intelligence panel.
  shellCentered,
}

/// Opens a detail view: right-side panel or shell-centered on wide screens,
/// full screen on mobile.
class PhobesDetailPanel {
  PhobesDetailPanel._();

  static Future<T?> open<T>(
    BuildContext context,
    Widget page, {
    double? panelWidth,
    DetailPresentation presentation = DetailPresentation.panel,
  }) {
    switch (presentation) {
      case DetailPresentation.shellCentered:
        return _pushShellCentered<T>(context, page);
      case DetailPresentation.panel:
        return PhobesPageRoute.pushResponsive<T>(
          context,
          page,
          panelWidth: panelWidth,
        );
    }
  }

  /// Fills the shell center column on wide layouts; sidebar and intelligence
  /// panel stay visible and interactive.
  static Future<T?> _pushShellCentered<T>(
    BuildContext context,
    Widget page,
  ) {
    if (!ModuleUiTokens.isWideForm(context)) {
      return Navigator.push<T>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => page,
        ),
      );
    }

    final settings = ModuleSettingsService.instance;
    final shell = PhobesShellMetrics.fromWidth(
      MediaQuery.sizeOf(context).width,
      sidebarCollapsed: kIsWeb && settings.sidebarCollapsed.value,
      intelligencePanelEnabled: settings.intelligencePanelEnabled.value,
    );

    return Navigator.push<T>(
      context,
      PageRouteBuilder<T>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          final cs = Theme.of(dialogContext).colorScheme;
          final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
          final left = shell.showSidebar ? shell.sidebarWidth : 0.0;
          final right =
              shell.showIntelligencePanel ? shell.intelligencePanelWidth : 0.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: left,
                right: right,
                top: 0,
                bottom: 0,
                child: Material(
                  color: isDark ? const Color(0xFF121212) : cs.surface,
                  child: page,
                ),
              ),
            ],
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
