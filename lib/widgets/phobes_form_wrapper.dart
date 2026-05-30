import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/module_ui_tokens.dart';
import 'phobes_widgets.dart';

/// Provides the correct [close] callback for forms shown inside [PhobesFormWrapper].
class PhobesFormScope extends InheritedWidget {
  final void Function([Object? result]) close;

  const PhobesFormScope({
    super.key,
    required this.close,
    required super.child,
  });

  static PhobesFormScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<PhobesFormScope>();
  }

  /// Closes the innermost form panel/sheet, or falls back to [Navigator.pop].
  static void closeForm(BuildContext context, [Object? result]) {
    final scope = maybeOf(context);
    if (scope != null) {
      scope.close(result);
    } else {
      Navigator.of(context).pop(result);
    }
  }

  @override
  bool updateShouldNotify(PhobesFormScope oldWidget) =>
      oldWidget.close != close;
}

/// Responsive form presenter.
///
/// - **Wide screen (≥ 900 px):** slides in as a full-height right-side panel.
/// - **Narrow screen (< 900 px):** draggable bottom sheet.
class PhobesFormWrapper {
  PhobesFormWrapper._();

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget form,
    bool forceSheet = false,
    double? panelWidth,
  }) {
    final isWide = ModuleUiTokens.isWideForm(context) && !forceSheet;

    if (isWide) {
      return _showPanel<T>(
        context,
        title: title,
        form: form,
        panelWidth: ModuleUiTokens.resolvePanelWidth(context, override: panelWidth),
      );
    }
    return _showSheet<T>(context, title: title, form: form);
  }

  static Future<T?> _showPanel<T>(
    BuildContext context, {
    required String title,
    required Widget form,
    required double panelWidth,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.38),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, animation, _) {
        final cs = Theme.of(ctx).colorScheme;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: Material(
              color: isDark ? const Color(0xFF121212) : cs.surface,
              elevation: 24,
              shadowColor: Colors.black.withOpacity(0.3),
              child: Container(
                width: panelWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: cs.outline.withOpacity(0.12)),
                  ),
                ),
                child: Column(
                  children: [
                    _PanelHeader(title: title, onClose: () => Navigator.pop(ctx)),
                    Expanded(
                      child: PhobesFormScope(
                        close: ([result]) => Navigator.pop(ctx, result),
                        child: form,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<T?> _showSheet<T>(
    BuildContext context, {
    required String title,
    required Widget form,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DraggableFormSheet(title: title, form: form),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _PanelHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 12, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outline.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
          PhobesIconButton(icon: Icons.close_rounded, onTap: onClose),
        ],
      ),
    );
  }
}

class _DraggableFormSheet extends StatelessWidget {
  final String title;
  final Widget form;

  const _DraggableFormSheet({required this.title, required this.form});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        PhobesIconButton(
                          icon: Icons.close_rounded,
                          onTap: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: cs.outline.withOpacity(0.1)),
              Expanded(
                child: PhobesFormScope(
                  close: ([result]) => Navigator.pop(ctx, result),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: form,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
