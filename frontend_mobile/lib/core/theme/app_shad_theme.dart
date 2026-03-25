import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'app_colors.dart';

/// Merkezi Shadcn UI teması; renk kaynağı [AppColors] ile hizalıdır.
abstract final class AppShadTheme {
  AppShadTheme._();

  static ShadColorScheme get _lightColorScheme => ShadVioletColorScheme.light(
        background: AppColors.background,
        foreground: AppColors.textPrimary,
        card: AppColors.surface,
        cardForeground: AppColors.textPrimary,
        popover: AppColors.surface,
        popoverForeground: AppColors.textPrimary,
        primary: AppColors.primary,
        primaryForeground: AppColors.textOnPrimary,
        secondary: AppColors.surfaceVariant,
        secondaryForeground: AppColors.textPrimary,
        muted: AppColors.surfaceVariant,
        mutedForeground: AppColors.textSecondary,
        accent: AppColors.primarySurface,
        accentForeground: AppColors.primaryDark,
        destructive: AppColors.error,
        destructiveForeground: AppColors.textOnPrimary,
        border: AppColors.border,
        input: AppColors.border,
        ring: AppColors.primary,
        custom: const {
          'success': AppColors.success,
          'warning': AppColors.warning,
          'textTertiary': AppColors.textTertiary,
        },
      );

  static ShadTextTheme get _textTheme => ShadTextTheme.fromGoogleFont(
        ({
          TextStyle? textStyle,
          Color? color,
          Color? backgroundColor,
          double? fontSize,
          FontWeight? fontWeight,
          FontStyle? fontStyle,
          double? letterSpacing,
          double? wordSpacing,
          TextBaseline? textBaseline,
          double? height,
          Locale? locale,
          Paint? foreground,
          Paint? background,
          List<Shadow>? shadows,
          List<FontFeature>? fontFeatures,
          TextDecoration? decoration,
          Color? decorationColor,
          TextDecorationStyle? decorationStyle,
          double? decorationThickness,
        }) {
          return GoogleFonts.inter(
            textStyle: textStyle,
            color: color,
            backgroundColor: backgroundColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
            letterSpacing: letterSpacing,
            wordSpacing: wordSpacing,
            textBaseline: textBaseline,
            height: height,
            locale: locale,
            foreground: foreground,
            background: background,
            shadows: shadows,
            fontFeatures: fontFeatures,
            decoration: decoration,
            decorationColor: decorationColor,
            decorationStyle: decorationStyle,
            decorationThickness: decorationThickness,
          );
        },
      );

  static ShadThemeData get light => ShadThemeData(
        brightness: Brightness.light,
        colorScheme: _lightColorScheme,
        radius: BorderRadius.circular(12),
        textTheme: _textTheme,
      );

  /// Sistem karanlık modu için; [AppColors] ile uyumlu violet tabanlı koyu şema.
  static ShadThemeData get dark => ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadVioletColorScheme.dark(),
        radius: BorderRadius.circular(12),
        textTheme: _textTheme,
      );
}

extension AppShadColorSchemeX on ShadColorScheme {
  Color get success => custom['success'] ?? const Color(0xFF22C55E);
  Color get warning => custom['warning'] ?? const Color(0xFFF59E0B);
  Color get textTertiary =>
      custom['textTertiary'] ?? const Color(0xFF94A3B8);
}
