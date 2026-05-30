import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/phobes_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/corkboard_item_model.dart';
import '../../../widgets/phobes_widgets.dart';
import '../corkboard_constants.dart';

/// Sticky-note color palette for the planning board.
class PaperTone {
  final int base;
  final Color accent;
  final String name;
  const PaperTone(this.base, this.accent, this.name);
}

const List<PaperTone> kPaperTones = [
  PaperTone(0xFFFFF9C4, Color(0xFFF9A825), ''),
  PaperTone(0xFFFFFFFF, Color(0xFF78909C), ''),
  PaperTone(0xFFE3F2FD, Color(0xFF42A5F5), ''),
  PaperTone(0xFFFCE4EC, Color(0xFFEC407A), ''),
  PaperTone(0xFFE8F5E9, Color(0xFF66BB6A), ''),
  PaperTone(0xFFEDE7F6, Color(0xFF7E57C2), ''),
];

String paperToneLabel(AppLocalizations l10n, PaperTone tone) {
  switch (tone.base) {
    case 0xFFFFF9C4:
      return l10n.corkboardPaperYellow;
    case 0xFFFFFFFF:
      return l10n.corkboardPaperWhite;
    case 0xFFE3F2FD:
      return l10n.corkboardPaperBlue;
    case 0xFFFCE4EC:
      return l10n.corkboardPaperPink;
    case 0xFFE8F5E9:
      return l10n.corkboardPaperGreen;
    default:
      return tone.name.isNotEmpty ? tone.name : l10n.corkboardPaperYellow;
  }
}

PaperTone toneOf(int color) => kPaperTones.firstWhere(
      (t) => t.base == color,
      orElse: () => kPaperTones.first,
    );

/// @deprecated Use [CorkboardItem.size] — kept for imports.
const double kCorkCardWidth = kCorkDefaultSize;

Color corkPaperTextColor(int paperColor, {bool muted = false}) {
  final lum = Color(paperColor).computeLuminance();
  final base =
      lum > 0.55 ? const Color(0xFF1A1A1E) : const Color(0xFFF8F8FA);
  return muted ? base.withOpacity(0.5) : base.withOpacity(0.92);
}

class CorkItemWidget extends StatefulWidget {
  final CorkboardItem item;
  final Function(double x, double y) onPositionChanged;
  final void Function(double x, double y)? onDragUpdate;
  final VoidCallback? onDragStart;
  final ValueChanged<double> onSizeChanged;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onConnect;
  final VoidCallback? onManageConnections;
  final bool isConnecting;
  final bool isSelectedForConnection;

  const CorkItemWidget({
    super.key,
    required this.item,
    required this.onPositionChanged,
    this.onDragUpdate,
    this.onDragStart,
    required this.onSizeChanged,
    required this.onDelete,
    required this.onEdit,
    required this.onConnect,
    this.onManageConnections,
    this.isConnecting = false,
    this.isSelectedForConnection = false,
  });

  @override
  State<CorkItemWidget> createState() => _CorkItemWidgetState();
}

class _CorkItemWidgetState extends State<CorkItemWidget>
    with SingleTickerProviderStateMixin {
  late double _x, _y, _size;
  bool _dragging = false;
  bool _resizing = false;
  bool _hovered = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _x = widget.item.posX;
    _y = widget.item.posY;
    _size = widget.item.size.clamp(kCorkMinSize, kCorkMaxSize);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(CorkItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.item.posX != widget.item.posX) {
      _x = widget.item.posX;
    }
    if (!_dragging && oldWidget.item.posY != widget.item.posY) {
      _y = widget.item.posY;
    }
    if (!_resizing && oldWidget.item.size != widget.item.size) {
      _size = widget.item.size.clamp(kCorkMinSize, kCorkMaxSize);
    }
    if (widget.isSelectedForConnection && !oldWidget.isSelectedForConnection) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isSelectedForConnection &&
        oldWidget.isSelectedForConnection) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 1;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _clampPosition() {
    final max = kCorkBoardSize - _size;
    _x = _x.clamp(0.0, max);
    _y = _y.clamp(0.0, max);
  }

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;
    final tone = toneOf(widget.item.color);

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => PhobesBottomSheet(
        title: l10n.edit,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MenuTile(
              icon: Icons.edit_outlined,
              label: l10n.edit,
              color: tone.accent,
              onTap: () {
                Navigator.pop(ctx);
                widget.onEdit();
              },
            ),
            _MenuTile(
              icon: Icons.hub_outlined,
              label: l10n.corkboardConnectLink,
              color: Theme.of(ctx).colorScheme.primary,
              onTap: () {
                Navigator.pop(ctx);
                widget.onConnect();
              },
            ),
            if (widget.onManageConnections != null)
              _MenuTile(
                icon: Icons.link_off_outlined,
                label: l10n.corkboardManageConnections,
                color: Theme.of(ctx).colorScheme.tertiary,
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onManageConnections!();
                },
              ),
            _MenuTile(
              icon: Icons.delete_outline_rounded,
              label: l10n.delete,
              color: Theme.of(ctx).colorScheme.error,
              onTap: () {
                Navigator.pop(ctx);
                widget.onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = toneOf(widget.item.color);
    final bg = Color(widget.item.color);
    final textColor = corkPaperTextColor(widget.item.color);
    final mutedText = corkPaperTextColor(widget.item.color, muted: true);
    final isSelected = widget.isSelectedForConnection;
    final hasText = widget.item.content.trim().isNotEmpty;
    final fontSize = (_size / kCorkDefaultSize * 13.5).clamp(11.0, 17.0);
    final connecting = widget.isConnecting;
    final showResizeHandle = !connecting &&
        (_hovered || _resizing || MediaQuery.sizeOf(context).shortestSide < 720);

    final cardBody = Transform.rotate(
          angle: widget.item.rotation,
          child: AnimatedScale(
            scale: connecting
                ? 1.0
                : (_dragging ? 1.03 : (_hovered ? 1.015 : 1.0)),
            duration: PhobesTheme.animFast,
            curve: PhobesTheme.curveDefault,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final scale = isSelected ? _pulse.value : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: SizedBox(
                width: _size,
                height: _size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: _size,
                      height: _size,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? cs.primary
                              : (widget.isConnecting
                                  ? cs.primary.withOpacity(0.55)
                                  : tone.accent.withOpacity(isDark ? 0.45 : 0.4)),
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(_dragging ? 0.28 : 0.14),
                            blurRadius: _dragging ? 24 : 12,
                            offset: Offset(0, _dragging ? 12 : 5),
                          ),
                          if (isSelected)
                            BoxShadow(
                              color: cs.primary.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: tone.accent,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -5,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF3A3F4B)
                                        : const Color(0xFFECEFF1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: tone.accent,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                8,
                                12,
                                12,
                              ),
                              child: hasText
                                  ? Text(
                                      widget.item.content,
                                      maxLines: 12,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                        height: 1.4,
                                      ),
                                    )
                                  : Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .corkboardNotePlaceholder,
                                        style: GoogleFonts.outfit(
                                          fontSize: fontSize - 1,
                                          fontStyle: FontStyle.italic,
                                          color: mutedText,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showResizeHandle)
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: GestureDetector(
                          onPanStart: (_) =>
                              setState(() => _resizing = true),
                          onPanUpdate: (d) {
                            setState(() {
                              final delta =
                                  (d.delta.dx + d.delta.dy) / 2;
                              _size = (_size + delta)
                                  .clamp(kCorkMinSize, kCorkMaxSize);
                            });
                          },
                          onPanEnd: (_) {
                            setState(() => _resizing = false);
                            widget.onSizeChanged(_size);
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withOpacity(0.45),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.open_in_full_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
    );

    // Bağlantı modunda onTap yerine ham pointer kullan (InteractiveViewer ile çakışmaz).
    final Widget card = connecting
        ? Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => widget.onConnect(),
            child: cardBody,
          )
        : MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onPanStart: (_) {
                if (_resizing) return;
                widget.onDragStart?.call();
                setState(() => _dragging = true);
              },
              onPanUpdate: (d) {
                if (_resizing) return;
                setState(() {
                  _x += d.delta.dx;
                  _y += d.delta.dy;
                  _clampPosition();
                });
                widget.onDragUpdate?.call(_x, _y);
              },
              onPanEnd: (_) {
                if (_resizing) return;
                setState(() => _dragging = false);
                widget.onPositionChanged(_x, _y);
              },
              onTap: widget.onEdit,
              onLongPress: _onLongPress,
              child: cardBody,
            ),
          );

    return Positioned(left: _x, top: _y, child: card);
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
