import 'package:flutter/material.dart';

/// Taş (Stone) + Amber tabanlı tek sıcak nötr palet.
/// Semantik renkler aynı sıcaklıkta, Tailwind ölçeğiyle uyumludur.
class AppColors {
  AppColors._();

  // Primary — Stone
  static const Color primary = Color(0xFF1C1917); // 950
  static const Color primaryDark = Color(0xFF0C0A09);
  static const Color primaryLight = Color(0xFF44403C); // 700
  static const Color primarySurface = Color(0xFFF5F5F4); // 100

  // Accent — Amber
  static const Color accent = Color(0xFFD97706); // 600
  static const Color accentDark = Color(0xFFB45309); // 700
  static const Color accentLight = Color(0xFFFBBF24); // 400
  static const Color accentSurface = Color(0xFFFEF3C7); // 100

  // Semantic — emerald / amber / kırmızı aynı “sıcak” ailede
  static const Color success = Color(0xFF047857); // Emerald 700
  static const Color successLight = Color(0xFFECFDF5); // Emerald 50
  static const Color warning = accent;
  static const Color warningLight = accentSurface;
  static const Color error = Color(0xFFB91C1C); // Red 700
  static const Color errorLight = Color(0xFFFFF1F2); // Rose-50 benzeri sıcak zemin

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFFAFAF9); // Stone 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = primarySurface;
  static const Color surfaceWarm = Color(0xFFFAF8F5); // krem-taş, background ile aynı aile
  static const Color border = Color(0xFFE7E5E4); // Stone 200
  static const Color divider = primarySurface;

  // Text
  static const Color textPrimary = primary;
  static const Color textSecondary = Color(0xFF78716C); // Stone 500
  static const Color textTertiary = Color(0xFFA8A29E); // Stone 400
  static const Color textOnPrimary = background;
  static const Color textOnAccent = Color(0xFFFFFFFF);

  /// İkincil vurgu (ikonlar, bölüm başlıkları) — [textSecondary] ile aynı taş tonu.
  static const Color secondary = textSecondary;

  // Shimmer — border / arka plan ile aynı taş tonları
  static const Color shimmerBase = border;
  static const Color shimmerHighlight = background;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentDark, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Splash, Sliver başlık, sınıf kartı şeridi vb. üst yüzeyler.
  static const LinearGradient headerGradient = primaryGradient;
}
