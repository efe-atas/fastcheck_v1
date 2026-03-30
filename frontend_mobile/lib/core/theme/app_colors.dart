import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Figma referans palette (dashboard/exams/ocr lab)
  static const Color primary = Color(0xFF3B4FD8);
  static const Color primaryDark = Color(0xFF1A2A9E);
  static const Color primaryLight = Color(0xFF5168F5);
  static const Color primarySurface = Color(0xFFE9EEFF);

  static const Color accent = Color(0xFF0BBFB0);
  static const Color accentDark = Color(0xFF099A8F);
  static const Color accentLight = Color(0xFF14C6B7);
  static const Color accentSurface = Color(0xFFE3F8F5);

  static const Color success = Color(0xFF19A56E);
  static const Color successLight = Color(0xFFE7F7EF);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDE3F4D);
  static const Color errorLight = Color(0xFFFFF1F2);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF3F5FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F3FA);
  static const Color surfaceWarm = Color(0xFFF9FAFF);
  static const Color border = Color(0xFFDDE3F0);
  static const Color divider = Color(0xFFE2E7F3);

  // Text
  static const Color textPrimary = Color(0xFF0F1729);
  static const Color textSecondary = Color(0xFF6B7A99);
  static const Color textTertiary = Color(0xFF8A96B2);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnAccent = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF3A4864);

  // Shimmer
  static const Color shimmerBase = border;
  static const Color shimmerHighlight = surfaceWarm;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B4FD8), Color(0xFF2D3DB8), Color(0xFF1A2A9E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentDark, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = primaryGradient;
}
