import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppGoogleNavItem {
  const AppGoogleNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.persistSelection = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool persistSelection;
}

/// Uygulama temasına tam uyumlu, sade ve erişilebilir alt gezinme çubuğu.
/// selectedIndex ve onSelected ile tamamen dışarıdan kontrol edilir (controlled widget).
class AppGoogleBottomNav extends StatelessWidget {
  const AppGoogleBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.margin = const EdgeInsets.fromLTRB(12, 0, 12, 8),
  });

  final List<AppGoogleNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: margin.copyWith(bottom: margin.bottom + bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItemButton(
                    item: items[i],
                    selected: selectedIndex == i,
                    labelStyle: textTheme.labelLarge,
                    onTap: () {
                      final tappedItem = items[i];
                      if (tappedItem.persistSelection) {
                        onSelected(i);
                      }
                      tappedItem.onTap();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemButton extends StatelessWidget {
  const _NavItemButton({
    required this.item,
    required this.selected,
    required this.onTap,
    this.labelStyle,
  });

  final AppGoogleNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final fgColor = selected ? AppColors.primary : AppColors.textSecondary;
    final bgColor = selected ? AppColors.primarySurface : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 20, color: fgColor),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (labelStyle ?? const TextStyle()).copyWith(
                    color: fgColor,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
