import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../theme/app_colors.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && onPressed != null;
    final child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Text(text);

    if (isOutlined) {
      return ShadButton.outline(
        leading: icon != null && !isLoading
            ? Icon(icon, size: 20)
            : null,
        onPressed: enabled ? onPressed : null,
        enabled: enabled,
        child: child,
      );
    }

    return ShadButton(
      leading: icon != null && !isLoading ? Icon(icon, size: 20) : null,
      onPressed: enabled ? onPressed : null,
      enabled: enabled,
      child: child,
    );
  }
}

class AppGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppGradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final enabled = !isLoading && onPressed != null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ShadButton(
        onPressed: enabled ? onPressed : null,
        enabled: enabled,
        expands: true,
        gradient: enabled ? AppColors.primaryGradient : null,
        backgroundColor: enabled ? null : AppColors.textTertiary,
        foregroundColor: AppColors.textOnPrimary,
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.textOnPrimary,
                ),
              )
            : Text(
                text,
                style: theme.textTheme.large.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
