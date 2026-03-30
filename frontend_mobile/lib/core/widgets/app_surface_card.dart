import 'package:flutter/material.dart';
import '../theme/app_design_tokens.dart';
import '../theme/app_colors.dart';

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = AppDesignTokens.cardPadding,
    this.margin,
    this.radius = AppDesignTokens.radiusMd,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.borderWidth = 1,
    this.shadows = AppDesignTokens.softShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: AppDesignTokens.cardDecoration(
        radius: radius,
        color: backgroundColor,
        border: borderColor,
        shadows: shadows,
      ),
      child: child,
    );
  }
}
