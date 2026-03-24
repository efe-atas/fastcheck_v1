import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// İçerik + dikey padding (6+52+6); vurgulu daire 52px ile hizalı.
const double _kLiquidBarInnerHeight = 64;

/// Apple tarzı “liquid glass”: bulanık arka plan + ince cam kenarı + yumuşak gölgeler.
///
/// Scaffold [bottomNavigationBar] bazen çocuğa çok büyük [maxHeight] verir; [BackdropFilter]
/// ile [Row]/[Expanded] bu alanı doldurup tüm ekranı kaplayabiliyordu. Bu yüzden cam alanı
/// [SizedBox] ile sabit yükseklikte kilitlenir.
class LiquidGlassBottomBar extends StatelessWidget {
  const LiquidGlassBottomBar({
    super.key,
    required this.items,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 10),
    this.blurSigma = 28,
  });

  final List<LiquidGlassBarItem> items;
  final EdgeInsets margin;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: margin.copyWith(bottom: margin.bottom + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: SizedBox(
            height: _kLiquidBarInnerHeight,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.38),
                  width: 0.6,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.26),
                    Colors.white.withValues(alpha: 0.09),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                    spreadRadius: -8,
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (final item in items)
                        item.emphasized
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: _BarSlot(item: item),
                              )
                            : Expanded(
                                child: _BarSlot(item: item),
                              ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LiquidGlassBarItem {
  const LiquidGlassBarItem({
    required this.icon,
    this.label,
    required this.onTap,
    this.selected = false,
    this.emphasized = false,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool selected;
  final bool emphasized;
}

class _BarSlot extends StatelessWidget {
  const _BarSlot({required this.item});

  final LiquidGlassBarItem item;

  @override
  Widget build(BuildContext context) {
    if (item.emphasized) {
      return Align(
        alignment: Alignment.center,
        child: _EmphasizedButton(item: item),
      );
    }
    return _StandardButton(item: item);
  }
}

class _StandardButton extends StatelessWidget {
  const _StandardButton({required this.item});

  final LiquidGlassBarItem item;

  @override
  Widget build(BuildContext context) {
    final active = item.selected;
    final color = active ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(22),
      splashColor: AppColors.primary.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 24, color: color),
            if (item.label != null) ...[
              const SizedBox(height: 2),
              Text(
                item.label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmphasizedButton extends StatelessWidget {
  const _EmphasizedButton({required this.item});

  final LiquidGlassBarItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(item.icon, color: AppColors.textOnPrimary, size: 26),
        ),
      ),
    );
  }
}
