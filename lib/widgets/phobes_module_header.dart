import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/module_ui_tokens.dart';
import '../core/phobes_theme.dart';
import 'phobes_module_info.dart';
import 'phobes_module_tab_bar.dart';
import 'phobes_widgets.dart';

/// Scaffold fill behind the branded module header sliver.
Color moduleHeaderBackgroundColor(BuildContext context) {
  return Theme.of(context).colorScheme.primary;
}

/// Standard icon action for [PhobesModuleHeader] / [PhobesModuleHeaderBar].
class PhobesModuleHeaderIconButton extends StatelessWidget {
  const PhobesModuleHeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.badgeCount,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return PhobesIconButton(
      icon: icon,
      onTap: onTap,
      color: iconColor ?? ModuleUiTokens.headerActionIconColor,
      backgroundColor: ModuleUiTokens.headerActionBackground(context),
      size: ModuleUiTokens.headerActionButtonSizeOf(context),
      iconSize: ModuleUiTokens.headerActionIconSizeOf(context),
      padding: ModuleUiTokens.headerActionPaddingOf(context),
      badgeCount: badgeCount,
      showBorder: false,
      borderRadius: ModuleUiTokens.headerActionBorderRadiusOf(context),
    );
  }
}

/// Tab definition for [PhobesModuleHeader].
class PhobesModuleTab {
  final String label;
  final IconData? icon;

  const PhobesModuleTab(this.label, [this.icon]);
}

/// Standard module header — returns a [SliverAppBar] with consistent
/// gradient background, title/subtitle, info button, optional add button
/// and optional TabBar.
class PhobesModuleHeader extends StatelessWidget {
  final String title;
  final String? emoji;
  final IconData? icon;
  final String? subtitle;
  final Widget? subtitleWidget;
  final VoidCallback? onClose;
  final VoidCallback? onAdd;
  final String? addTooltip;
  final List<Widget>? extraActions;
  final String? infoText;
  final PhobesModuleInfoContent? info;
  final TabController? tabController;
  final List<PhobesModuleTab>? tabs;
  final Widget? customContent;
  final Widget? filterChips;
  final double? toolbarHeight;
  final bool useExtendedHeight;

  const PhobesModuleHeader({
    super.key,
    required this.title,
    this.emoji,
    this.icon,
    this.subtitle,
    this.subtitleWidget,
    this.onClose,
    this.onAdd,
    this.addTooltip,
    this.extraActions,
    this.infoText,
    this.info,
    this.tabController,
    this.tabs,
    this.customContent,
    this.filterChips,
    this.toolbarHeight,
    this.useExtendedHeight = false,
  });

  double _toolbarHeight(BuildContext context) {
    if (toolbarHeight != null) return toolbarHeight!;
    return ModuleUiTokens.toolbarHeightOf(
      context,
      extended: useExtendedHeight || customContent != null,
    );
  }

  bool get _hasTabs =>
      tabs != null && tabs!.isNotEmpty && tabController != null;

  PhobesModuleInfoContent? _resolvedInfo() {
    if (info != null) return info;
    if (infoText != null) {
      return PhobesModuleInfoContent.fromPlain(title, infoText!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SliverOverlapAbsorber(
      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
      sliver: SliverPersistentHeader(
        pinned: true,
        delegate: _PhobesModuleHeaderDelegate(
          toolbarHeight: _toolbarHeight(context),
          hasTabs: _hasTabs,
          content: PhobesModuleHeaderContent(
            title: title,
            emoji: emoji,
            icon: icon,
            subtitle: subtitle,
            subtitleWidget: subtitleWidget,
            onClose: onClose,
            onAdd: onAdd,
            addTooltip: addTooltip,
            extraActions: extraActions,
            info: _resolvedInfo(),
            customContent: customContent,
            filterChips: filterChips,
          ),
          tabController: tabController,
          tabs: tabs,
        ),
      ),
    );
  }
}

/// Helpers for [NestedScrollView] bodies so list content starts below the pinned header.
abstract final class ModuleNestedScroll {
  ModuleNestedScroll._();

  static List<Widget> slivers(BuildContext context, List<Widget> body) => [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        ...body,
      ];

  static Widget scrollView({
    required BuildContext context,
    required List<Widget> slivers,
    ScrollPhysics? physics,
  }) {
    return CustomScrollView(
      physics: physics,
      slivers: ModuleNestedScroll.slivers(context, slivers),
    );
  }

  static Widget centered({
    required BuildContext context,
    required Widget child,
  }) {
    return scrollView(
      context: context,
      slivers: [
        SliverFillRemaining(hasScrollBody: false, child: child),
      ],
    );
  }
}

class _PhobesModuleHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PhobesModuleHeaderDelegate({
    required this.toolbarHeight,
    required this.hasTabs,
    required this.content,
    this.tabController,
    this.tabs,
  });

  final double toolbarHeight;
  final bool hasTabs;
  final Widget content;
  final TabController? tabController;
  final List<PhobesModuleTab>? tabs;

  double get _tabStripHeight =>
      hasTabs ? ModuleUiTokens.tabBarHeight : 0;

  @override
  double get minExtent => toolbarHeight + _tabStripHeight;

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(ModuleUiTokens.headerBottomRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _ModuleHeaderBackground(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: toolbarHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ModuleUiTokens.headerHorizontalPaddingOf(
                        context,
                      ),
                    ),
                    child: content,
                  ),
                ),
                if (hasTabs)
                  PhobesModuleTabBar(
                    controller: tabController!,
                    tabs: tabs!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PhobesModuleHeaderDelegate oldDelegate) {
    return toolbarHeight != oldDelegate.toolbarHeight ||
        hasTabs != oldDelegate.hasTabs;
  }
}

/// Fixed-height header for screens that do not use [NestedScrollView].
class PhobesModuleHeaderBar extends StatelessWidget {
  final String title;
  final String? emoji;
  final IconData? icon;
  final String? subtitle;
  final Widget? subtitleWidget;
  final VoidCallback? onClose;
  final VoidCallback? onAdd;
  final String? addTooltip;
  final List<Widget>? extraActions;
  final String? infoText;
  final PhobesModuleInfoContent? info;
  final TabController? tabController;
  final List<PhobesModuleTab>? tabs;
  final Widget? customContent;
  final Widget? filterChips;
  final bool useExtendedHeight;
  final double? toolbarHeight;

  const PhobesModuleHeaderBar({
    super.key,
    required this.title,
    this.emoji,
    this.icon,
    this.subtitle,
    this.subtitleWidget,
    this.onClose,
    this.onAdd,
    this.addTooltip,
    this.extraActions,
    this.infoText,
    this.info,
    this.tabController,
    this.tabs,
    this.customContent,
    this.filterChips,
    this.useExtendedHeight = false,
    this.toolbarHeight,
  });

  bool get _hasTabs =>
      tabs != null && tabs!.isNotEmpty && tabController != null;

  double _toolbarHeight(BuildContext context) {
    if (toolbarHeight != null) return toolbarHeight!;
    return ModuleUiTokens.toolbarHeightOf(
      context,
      extended: useExtendedHeight || customContent != null,
    );
  }

  PhobesModuleInfoContent? _resolvedInfo() {
    if (info != null) return info;
    if (infoText != null) {
      return PhobesModuleInfoContent.fromPlain(title, infoText!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(ModuleUiTokens.headerBottomRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            const Positioned.fill(child: _ModuleHeaderBackground()),
            Padding(
              padding: EdgeInsets.only(top: top),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _toolbarHeight(context),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ModuleUiTokens.headerHorizontalPaddingOf(
                          context,
                        ),
                      ),
                      child: PhobesModuleHeaderContent(
                        title: title,
                        emoji: emoji,
                        icon: icon,
                        subtitle: subtitle,
                        subtitleWidget: subtitleWidget,
                        onClose: onClose,
                        onAdd: onAdd,
                        addTooltip: addTooltip,
                        extraActions: extraActions,
                        info: _resolvedInfo(),
                        customContent: customContent,
                        filterChips: filterChips,
                      ),
                    ),
                  ),
                  if (_hasTabs)
                    PhobesModuleTabBar(
                      controller: tabController!,
                      tabs: tabs!,
                    ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleHeaderBackground extends StatelessWidget {
  const _ModuleHeaderBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value && isDark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(ModuleUiTokens.headerBottomRadius),
        ),
        color: isAmoled ? null : primaryColor,
        gradient: isAmoled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.55),
                  Colors.black,
                ],
              )
            : null,
      ),
    );
  }
}

/// Title row + actions — shared by sliver and bar variants.
class PhobesModuleHeaderContent extends StatelessWidget {
  final String title;
  final String? emoji;
  final IconData? icon;
  final String? subtitle;
  final Widget? subtitleWidget;
  final VoidCallback? onClose;
  final VoidCallback? onAdd;
  final String? addTooltip;
  final List<Widget>? extraActions;
  final PhobesModuleInfoContent? info;
  final Widget? customContent;
  final Widget? filterChips;

  const PhobesModuleHeaderContent({
    super.key,
    required this.title,
    this.emoji,
    this.icon,
    this.subtitle,
    this.subtitleWidget,
    this.onClose,
    this.onAdd,
    this.addTooltip,
    this.extraActions,
    this.info,
    this.customContent,
    this.filterChips,
  });

  @override
  Widget build(BuildContext context) {
    const titleColor = Colors.white;
    final mutedOnHeader = Colors.white.withOpacity(0.72);
    final iconTileBg = ModuleUiTokens.headerActionBackground(context);
    final actionGap = ModuleUiTokens.headerActionSpacingOf(context);
    final titleSize = ModuleUiTokens.headerTitleFontSizeOf(context);
    final subtitleSize = ModuleUiTokens.headerSubtitleFontSizeOf(context);
    final leadingTile = ModuleUiTokens.headerLeadingIconTileSizeOf(context);
    final leadingIcon = ModuleUiTokens.headerLeadingIconSizeOf(context);
    final leadingGap = ModuleUiTokens.isCompactHeader(context) ? 8.0 : 10.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onClose != null || Navigator.canPop(context)) ...[
              PhobesModuleHeaderIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onClose ?? () => Navigator.maybePop(context),
              ),
              SizedBox(width: leadingGap),
            ],
            if (emoji != null) ...[
              Text(
                emoji!,
                style: TextStyle(
                  fontSize: ModuleUiTokens.headerEmojiSizeOf(context),
                ),
              ),
              SizedBox(width: leadingGap),
            ] else if (icon != null) ...[
              Container(
                width: leadingTile,
                height: leadingTile,
                decoration: BoxDecoration(
                  color: iconTileBg,
                  borderRadius: BorderRadius.circular(
                    ModuleUiTokens.headerActionBorderRadiusOf(context),
                  ),
                ),
                child: Icon(icon!, color: titleColor, size: leadingIcon),
              ),
              SizedBox(width: leadingGap),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitleWidget != null)
                    subtitleWidget!
                  else if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.outfit(
                        fontSize: subtitleSize,
                        color: mutedOnHeader,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (extraActions != null)
              for (var i = 0; i < extraActions!.length; i++) ...[
                extraActions![i],
                if (i < extraActions!.length - 1) SizedBox(width: actionGap),
              ],
            if (info != null) ...[
              if (extraActions != null && extraActions!.isNotEmpty)
                SizedBox(width: actionGap),
              PhobesModuleHeaderIconButton(
                icon: Icons.info_outline_rounded,
                onTap: () => PhobesModuleInfo.show(context, content: info!),
              ),
            ],
            if (onAdd != null) ...[
              SizedBox(width: actionGap),
              Tooltip(
                message: addTooltip ?? '',
                child: PhobesModuleHeaderIconButton(
                  icon: Icons.add_rounded,
                  onTap: onAdd!,
                ),
              ),
            ],
          ],
        ),
        if (customContent != null) ...[
          const SizedBox(height: 8),
          customContent!,
        ],
        if (filterChips != null) ...[
          const SizedBox(height: 10),
          filterChips!,
        ],
      ],
    );
  }
}
