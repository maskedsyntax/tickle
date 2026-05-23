import 'dart:ui';

import 'package:flutter/material.dart';

/// iOS-style large-title sliver app bar.
///
/// Behaviour:
/// - Pinned: the toolbar row stays anchored at the top while scrolling.
/// - Expanded: a large title sits bottom-left (Apple HIG standard for
///   navigation bars with `prefersLargeTitles`).
/// - Collapsed: a small title fades in at top-centre.
/// - Background uses a translucent frosted-glass blur so content scrolling
///   underneath is dimmed rather than visible.
class IOSSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const IOSSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final translucentBg = theme.scaffoldBackgroundColor.withValues(alpha: 0.74);
    final smallTitleStyle = theme.appBarTheme.titleTextStyle ??
        const TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
    final largeTitleStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: smallTitleStyle.color,
    );

    return SliverAppBar.medium(
      pinned: true,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      actions: actions,
      backgroundColor: translucentBg,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // SliverAppBar.medium's defaults: 64pt collapsed, 112pt expanded
              // (both exclusive of the status bar). The 48pt difference is the
              // range over which the cross-fade happens.
              const collapsedBarHeight = 64.0;
              const expandableRange = 48.0;
              final topPadding = MediaQuery.paddingOf(context).top;
              final fullyCollapsedHeight = topPadding + collapsedBarHeight;
              final expandedExtra =
                  (constraints.maxHeight - fullyCollapsedHeight)
                      .clamp(0.0, expandableRange);
              final expandedProgress = expandedExtra / expandableRange;
              final collapsedOpacity = 1.0 - expandedProgress;

              return Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: translucentBg,
                      border: Border(
                        bottom: BorderSide(
                          color: theme.dividerColor.withValues(
                            alpha: 0.65 * collapsedOpacity,
                          ),
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 56,
                    right: 56,
                    top: topPadding,
                    height: kToolbarHeight,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: collapsedOpacity,
                        child: Center(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: smallTitleStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 12,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: expandedProgress,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: largeTitleStyle,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
