import 'package:flutter/material.dart';
import 'package:sajda/theme.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.emeraldAurora),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              else
                const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(children: actions ?? const [])
            ],
          ),
        ),
      ),
    );
  }
}

/// Sliver variant with the same gradient look and centered title.
class GradientSliverAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool pinned;
  final bool floating;
  final double expandedHeight;
  final bool showBack;
  final LinearGradient? gradient;

  const GradientSliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.pinned = true,
    this.floating = false,
    this.expandedHeight = 120,
    this.showBack = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theGradient = gradient ?? AppGradients.emeraldAurora;
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
        );

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      collapsedHeight: 64, // give a bit more room to avoid tight layouts
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: theGradient),
        child: FlexibleSpaceBar(
          centerTitle: true,
          // Reduce bottom padding to increase available vertical space for the title
          titlePadding: const EdgeInsetsDirectional.only(bottom: 8, start: 16, end: 16),
          // Use a collapse-aware title that hides the subtitle when collapsed
          title: _CollapseAwareTitle(
            title: title,
            subtitle: subtitle,
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
          ),
        ),
      ),
    );
  }
}

/// A title widget that adapts to SliverAppBar collapse state to avoid bottom overflow.
class _CollapseAwareTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const _CollapseAwareTitle({
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Read FlexibleSpaceBar settings to know the collapse ratio
    final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    double t = 1.0;
    if (settings != null) {
      final delta = settings.maxExtent - settings.minExtent;
      if (delta > 0) {
        t = (settings.currentExtent - settings.minExtent) / delta;
        t = t.clamp(0.0, 1.0);
      }
    }

    // Only show subtitle when sufficiently expanded AND when the available height can fit it
    final currentExtent = settings?.currentExtent ?? kToolbarHeight;
    // Heuristic: require at least toolbar height + 12px to fit two lines comfortably
    final canFitTwoLines = currentExtent >= (kToolbarHeight + 12);
    final showSubtitle = subtitle != null && t > 0.7 && canFitTwoLines;

    // Clamp text scale so very large accessibility sizes don't create overflow
    final mq = MediaQuery.of(context);
    final clampedTextScaler = mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.0);

    return MediaQuery(
      data: mq.copyWith(textScaler: clampedTextScaler),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: titleStyle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (showSubtitle)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle!,
                  style: subtitleStyle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
