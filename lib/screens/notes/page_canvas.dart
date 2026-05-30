import 'package:flutter/material.dart';
import '../../core/page_sizes.dart';
import '../../models/note_model.dart';

/// Seçilen sayfa boyutuna ve kenar boşluklarına göre içeriği kağıt görünümünde
/// çerçeveleyen widget. pageSize == 'free' ise responsive tam genişlik düzeni kullanılır.
class PageCanvas extends StatelessWidget {
  final String pageSize;
  final String pageOrientation;
  final PageMargins margins;
  final Widget child;
  final bool isEditMode;

  const PageCanvas({
    super.key,
    required this.pageSize,
    required this.pageOrientation,
    required this.margins,
    required this.child,
    this.isEditMode = false,
  });

  static const double _mmToPx = 3.7795;

  double _marginPx(double mm) => mm * _mmToPx;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (pageSize == 'free') {
      return child;
    }

    final page = NotePageSize.byKey(pageSize);
    final isLandscape = pageOrientation == 'landscape';
    final canvasWidth = isLandscape ? page.heightPx : page.widthPx;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Guard against infinity or NaN (Flutter Web unbounded Column / first frame)
        final rawWidth = constraints.maxWidth;
        final availableWidth =
            (rawWidth.isFinite && rawWidth > 0) ? rawWidth : canvasWidth;

        final effectiveWidth =
            (canvasWidth > availableWidth ? availableWidth : canvasWidth)
                .clamp(100.0, double.infinity);

        final scaleRatio = canvasWidth > availableWidth
            ? (availableWidth / canvasWidth).clamp(0.1, 1.0)
            : 1.0;

        double safePad(double mm) {
          final v = _marginPx(mm) * scaleRatio;
          return (v.isFinite && v >= 8.0) ? v : 8.0;
        }

        final canvasHeight = isLandscape ? page.widthPx : page.heightPx;
        final minHeight =
            (canvasHeight * scaleRatio).clamp(0.0, double.infinity);

        return Center(
          child: Container(
            width: effectiveWidth,
            constraints: BoxConstraints(minHeight: minHeight),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.40 : 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.20 : 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                safePad(margins.left),
                safePad(margins.top),
                safePad(margins.right),
                safePad(margins.bottom),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Sayfa canvas'ını dış arka planla (kağıt masası görünümü) saran scaffold.
/// Editor ve detail view'un üst scroll container'ında kullanılır.
class PageCanvasScaffold extends StatelessWidget {
  final String pageSize;
  final String pageOrientation;
  final PageMargins margins;
  final Widget child;
  final bool isEditMode;

  const PageCanvasScaffold({
    super.key,
    required this.pageSize,
    required this.pageOrientation,
    required this.margins,
    required this.child,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isFree = pageSize == 'free';

    if (isFree) {
      return child;
    }

    return Container(
      color: const Color(0xFF262626),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: PageCanvas(
          pageSize: pageSize,
          pageOrientation: pageOrientation,
          margins: margins,
          isEditMode: isEditMode,
          child: child,
        ),
      ),
    );
  }
}
