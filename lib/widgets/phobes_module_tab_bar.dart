import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/module_ui_tokens.dart';
import 'phobes_module_header.dart';

/// Shared segmented tab bar used in module headers and team detail.
class PhobesModuleTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<PhobesModuleTab> tabs;

  const PhobesModuleTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Size get preferredSize => const Size.fromHeight(ModuleUiTokens.tabBarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PreferredSize(
      preferredSize: preferredSize,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          ModuleUiTokens.headerHorizontalPadding,
          0,
          ModuleUiTokens.headerHorizontalPadding,
          12,
        ),
        height: ModuleUiTokens.tabControlHeight,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(22),
        ),
        child: TabBar(
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: cs.primary,
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.62),
          labelStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: tabs
              .map(
                (t) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (t.icon != null) ...[
                        Icon(t.icon, size: 15),
                        const SizedBox(width: 5),
                      ],
                      Text(t.label),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
