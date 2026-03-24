import 'package:flutter/material.dart';

/// 8px grid — tutarlı boşluk ve köşe yarıçapları.
abstract final class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Yatay ekran kenarı (çoğu liste / grid).
  static const double screenHorizontal = lg;

  /// Kart / kutu içi padding.
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  static const double radiusSm = 12;
  static const double radiusMd = 14;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusSheet = 28;

  static const BorderRadius borderRadiusSm =
      BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd =
      BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg =
      BorderRadius.all(Radius.circular(radiusLg));
}
