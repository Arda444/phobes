import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'embed_utils.dart';

// ─────────────────────────────── Enum ────────────────────────────────────────

enum DividerStyle {
  line,      // ─────────────────────
  thick,     // ══════════════════════
  dots,      // • • • • • • • • • • •
  ornament,  // ────── ✦ ──────
  section,   // ── BÖLÜM SONU ──
  wave,      // ∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿
  double,    // ══════ ══════
}

extension DividerStyleX on DividerStyle {
  String get label {
    switch (this) {
      case DividerStyle.line:     return 'İnce Çizgi';
      case DividerStyle.thick:    return 'Kalın Çizgi';
      case DividerStyle.dots:     return 'Noktalı';
      case DividerStyle.ornament: return 'Süslü';
      case DividerStyle.section:  return 'Bölüm';
      case DividerStyle.wave:     return 'Dalgalı';
      case DividerStyle.double:   return 'Çift Çizgi';
    }
  }

  String get preview {
    switch (this) {
      case DividerStyle.line:     return '─────────';
      case DividerStyle.thick:    return '━━━━━━━━━';
      case DividerStyle.dots:     return '· · · · · · ·';
      case DividerStyle.ornament: return '── ✦ ──';
      case DividerStyle.section:  return '── BÖLÜM ──';
      case DividerStyle.wave:     return '〰〰〰〰〰';
      case DividerStyle.double:   return '════════';
    }
  }
}

// ─────────────────────────────── Embed ───────────────────────────────────────

class DividerBlockEmbed extends CustomBlockEmbed {
  const DividerBlockEmbed([String value = 'divider'])
      : super(dividerType, value);
  static const String dividerType = 'divider';

  DividerStyle get style {
    try {
      if (data == 'divider') return DividerStyle.line;
      final json = jsonDecode(data) as Map<String, dynamic>;
      return DividerStyle.values.firstWhere(
        (s) => s.name == json['style'],
        orElse: () => DividerStyle.line,
      );
    } catch (_) {
      return DividerStyle.line;
    }
  }

  static DividerBlockEmbed withStyle(DividerStyle style) {
    if (style == DividerStyle.line) return const DividerBlockEmbed();
    return DividerBlockEmbed(jsonEncode({'style': style.name}));
  }
}

class DividerEmbedBuilder extends EmbedBuilder {
  @override
  String get key => DividerBlockEmbed.dividerType;

  @override
  bool get expanded => true;

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    DividerStyle style;
    try {
      style = DividerBlockEmbed(node.value.data).style;
    } catch (_) {
      style = DividerStyle.line;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: _DividerWidget(
        style: style,
        readOnly: readOnly,
        onStyleChange: readOnly
            ? null
            : (newStyle) {
                final result = getCustomEmbedNode(
                    controller, controller.selection.start);
                if (result != null) {
                  controller.replaceText(
                    result.offset,
                    1,
                    DividerBlockEmbed.withStyle(newStyle),
                    null,
                  );
                }
              },
      ),
    );
  }
}

// ─────────────────────────────── Widget ──────────────────────────────────────

class _DividerWidget extends StatelessWidget {
  final DividerStyle style;
  final bool readOnly;
  final ValueChanged<DividerStyle>? onStyleChange;

  const _DividerWidget({
    required this.style,
    required this.readOnly,
    this.onStyleChange,
  });

  @override
  Widget build(BuildContext context) {
    final child = _buildVisual(context);

    if (readOnly || onStyleChange == null) return child;

    return GestureDetector(
      onTap: () => _showStylePicker(context),
      child: Tooltip(
        message: 'Stili değiştir',
        child: child,
      ),
    );
  }

  Widget _buildVisual(BuildContext context) {
    const lineColor = Color(0xFFCDD2DA);
    const textColor = Color(0xFF9BA3AF);

    switch (style) {
      // ─────────────────────────────────────────────────────
      case DividerStyle.line:
        return Container(
          height: 1,
          color: lineColor,
        );

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      case DividerStyle.thick:
        return Container(
          height: 2.5,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.transparent,
                Color(0xFFB0B8C4),
                Color(0xFFB0B8C4),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        );

      // · · · · · · · · · · · · · · · · ·
      case DividerStyle.dots:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            11,
            (i) => Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: const BoxDecoration(
                color: lineColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );

      // ─────── ✦ ───────
      case DividerStyle.ornament:
        return Row(
          children: [
            Expanded(
              child: Container(height: 1, color: lineColor),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '✦',
                style: TextStyle(
                  fontSize: 13,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ),
            Expanded(
              child: Container(height: 1, color: lineColor),
            ),
          ],
        );

      // ── BÖLÜM SONU ──
      case DividerStyle.section:
        return Row(
          children: [
            Expanded(
              child: Container(height: 1, color: lineColor),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: lineColor),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'BÖLÜM SONU',
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Expanded(
              child: Container(height: 1, color: lineColor),
            ),
          ],
        );

      // 〰〰〰〰〰〰〰〰〰〰〰〰
      case DividerStyle.wave:
        return Center(
          child: Text(
            '〰 〰 〰 〰 〰 〰 〰 〰',
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.55),
              letterSpacing: 2,
            ),
          ),
        );

      // ══════════════════════════════
      case DividerStyle.double:
        return Column(
          children: [
            Container(height: 1, color: lineColor),
            const SizedBox(height: 3),
            Container(height: 1, color: lineColor.withOpacity(0.5)),
          ],
        );
    }
  }

  void _showStylePicker(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Ayraç Stili',
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // Style grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: DividerStyle.values.length,
              itemBuilder: (_, i) {
                final s = DividerStyle.values[i];
                final sel = s == style;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    onStyleChange?.call(s);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? cs.primary.withOpacity(0.08)
                          : cs.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: sel
                            ? cs.primary.withOpacity(0.4)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.label,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: sel
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: sel
                                ? cs.primary
                                : cs.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.preview,
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withOpacity(0.35),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
