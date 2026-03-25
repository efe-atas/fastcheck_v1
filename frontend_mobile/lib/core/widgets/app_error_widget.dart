import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../theme/app_colors.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: theme.colorScheme.destructive),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.p.copyWith(
                color: theme.colorScheme.mutedForeground,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ShadButton.outline(
                leading: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: onRetry,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
