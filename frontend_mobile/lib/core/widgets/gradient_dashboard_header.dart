import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Gradient arka planlı, [SliverAppBar] ile kullanılan ortak üst başlık.
class DashboardGradientSliverAppBar extends StatelessWidget {
  const DashboardGradientSliverAppBar({
    super.key,
    required this.expandedHeight,
    required this.expandedChild,
    this.pinned = true,
    this.stretch = false,
    this.floating = false,
    this.title,
    this.titlePadding,
    this.actions,
    this.expandedContentAlignment = Alignment.topLeft,
  });

  final double expandedHeight;
  final Widget expandedChild;
  final bool pinned;
  final bool stretch;
  final bool floating;
  final String? title;
  final EdgeInsetsGeometry? titlePadding;
  final List<Widget>? actions;
  final AlignmentGeometry expandedContentAlignment;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: pinned,
      stretch: stretch,
      floating: floating,
      elevation: 0,
      backgroundColor: AppColors.primary,
      actions: actions,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        title: title != null
            ? Text(
                title!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              )
            : null,
        titlePadding: titlePadding,
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: expandedContentAlignment,
              child: expandedChild,
            ),
          ),
        ),
      ),
    );
  }
}

/// Yuvarlatılmış alt köşeli gradient blok (veli paneli vb.).
class DashboardGradientBoxHeader extends StatelessWidget {
  const DashboardGradientBoxHeader({
    super.key,
    this.headline,
    this.subtitle,
    this.trailing,
  });

  final String? headline;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.only(
        top: top + AppSpacing.xl,
        left: AppSpacing.xxl,
        right: AppSpacing.xxl,
        bottom: AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusSheet),
          bottomRight: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (headline != null && headline!.isNotEmpty)
                  Text(
                    headline!,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                if (subtitle != null) ...[
                  if (headline != null && headline!.isNotEmpty)
                    const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Gradient üst bölümde ikon rozeti.
class DashboardGradientIconBadge extends StatelessWidget {
  const DashboardGradientIconBadge({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize = 24,
    this.borderRadius = AppSpacing.radiusSm,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}
