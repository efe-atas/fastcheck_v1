import 'package:flutter/material.dart';
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

  // Deterministic accent color per class
  Color _accentColor() {
    final colors = [
      const Color(0xFF6366F1), // indigo
      const Color(0xFF0EA5E9), // sky
      const Color(0xFF10B981), // emerald
      const Color(0xFFF59E0B), // amber
      const Color(0xFFEC4899), // pink
      const Color(0xFF8B5CF6), // violet
    ];
    return colors[classEntity.classId % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = _accentColor();
    final hasExams = classEntity.examCount > 0;

    return Material(
      color: Colors.transparent,
      borderRadius: AppSpacing.borderRadiusLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusLg,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top accent strip
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
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
                      // Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Icon(
                          Icons.class_rounded,
                          color: accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Class name
                      Expanded(
                        child: Text(
                          classEntity.className,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Exam badge
                      _ExamBadge(
                          count: classEntity.examCount, hasExams: hasExams),
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

class _ExamBadge extends StatelessWidget {
  const _ExamBadge({required this.count, required this.hasExams});
  final int count;
  final bool hasExams;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: hasExams ? AppColors.successLight : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasExams
                ? Icons.assignment_turned_in_rounded
                : Icons.assignment_outlined,
            size: 13,
            color: hasExams ? AppColors.success : AppColors.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            hasExams ? '$count Sınav' : 'Sınav yok',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: hasExams ? AppColors.success : AppColors.textTertiary,
                  letterSpacing: 0.1,
                ),
          ),
        ],
      ),
    );
  }
}
