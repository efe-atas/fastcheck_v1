import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/teacher_entities.dart';

class ClassCard extends StatelessWidget {
  final ClassEntity classEntity;
  final VoidCallback? onTap;

  const ClassCard({
    super.key,
    required this.classEntity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusLg,
        child: ShadCard(
          padding: EdgeInsets.zero,
          radius: AppSpacing.borderRadiusLg,
          border: ShadBorder.all(color: AppColors.border, width: 1),
          shadows: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusLg),
                    topRight: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: const Icon(
                          Icons.class_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        classEntity.className,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: classEntity.examCount > 0
                              ? AppColors.successLight
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.assignment_rounded,
                              size: 14,
                              color: classEntity.examCount > 0
                                  ? AppColors.success
                                  : AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${classEntity.examCount} Sınav',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: classEntity.examCount > 0
                                        ? AppColors.success
                                        : AppColors.textTertiary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
