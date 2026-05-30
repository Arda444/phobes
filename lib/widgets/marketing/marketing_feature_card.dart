import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/marketing_module_catalog.dart';

/// Feature card for landing / about marketing grids.
class MarketingFeatureCard extends StatefulWidget {
  final MarketingModule module;
  final String title;
  final String subtitle;
  final bool isDark;
  final double? width;

  const MarketingFeatureCard({
    super.key,
    required this.module,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.width,
  });

  @override
  State<MarketingFeatureCard> createState() => _MarketingFeatureCardState();
}

class _MarketingFeatureCardState extends State<MarketingFeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardWidth = widget.width ?? 190;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: cardWidth,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withOpacity(_hovered ? 0.08 : 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.module.color.withOpacity(_hovered ? 0.35 : 0.12),
            ),
            boxShadow: widget.isDark
                ? null
                : [
                    BoxShadow(
                      color: widget.module.color.withOpacity(
                        _hovered ? 0.12 : 0.04,
                      ),
                      blurRadius: _hovered ? 18 : 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Pulse(
                infinite: true,
                duration: const Duration(seconds: 3),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.module.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.module.icon,
                    color: widget.module.color,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: cs.onSurface.withOpacity(0.45),
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
