import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/teacher_entities.dart';

class ExamCard extends StatelessWidget {
  final ExamEntity exam;
  final VoidCallback? onTap;

  const ExamCard({
    super.key,
    required this.exam,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMd,
        child: AppSurfaceCard(
          padding: AppSpacing.cardPadding,
          radius: AppSpacing.radiusMd,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _statusColor(exam.status).withValues(alpha: 0.12),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  _statusIcon(exam.status),
                  color: _statusColor(exam.status),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm', 'tr_TR')
                          .format(exam.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: exam.status),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'READY':
        return AppColors.success;
      case 'PROCESSING':
        return AppColors.warning;
      case 'FAILED':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'READY':
        return Icons.check_circle_outline_rounded;
      case 'PROCESSING':
        return Icons.hourglass_top_rounded;
      case 'FAILED':
        return Icons.error_outline_rounded;
      default:
        return Icons.description_rounded;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
      ),
    );
  }

  String get _label {
    switch (status.toUpperCase()) {
      case 'READY':
        return 'Hazır';
      case 'PROCESSING':
        return 'İşleniyor';
      case 'FAILED':
        return 'Hata';
      default:
        return 'Taslak';
    }
  }

  Color get _bgColor {
    switch (status.toUpperCase()) {
      case 'READY':
        return AppColors.successLight;
      case 'PROCESSING':
        return AppColors.warningLight;
      case 'FAILED':
        return AppColors.errorLight;
      default:
        return AppColors.surfaceVariant;
    }
  }

  Color get _textColor {
    switch (status.toUpperCase()) {
      case 'READY':
        return AppColors.success;
      case 'PROCESSING':
        return AppColors.warning;
      case 'FAILED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
