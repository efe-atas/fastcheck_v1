import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppDesignTokens {
  AppDesignTokens._();

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(14);

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x120F1729),
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];

  static const List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Color(0x100F1729),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static BoxDecoration cardDecoration({
    double radius = radiusMd,
    Color color = AppColors.surface,
    Color border = AppColors.border,
    List<BoxShadow> shadows = softShadow,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
      boxShadow: shadows,
    );
  }
}
