import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/student_entities.dart';

class ExamListTile extends StatelessWidget {
  final StudentExamEntity exam;
  final VoidCallback? onTap;

  const ExamListTile({
    super.key,
    required this.exam,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd MMM yyyy', 'tr').format(exam.createdAt);
    final scoreLabel = exam.scorePercentage == null
        ? null
        : '%${exam.scorePercentage!.round()} başarı';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AppSurfaceCard(
          padding: const EdgeInsets.all(16),
          radius: 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: _statusGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _statusIcon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.border,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Sınıf #${exam.classId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (scoreLabel != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        scoreLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(status: exam.status),
                  const SizedBox(height: 16),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient get _statusGradient {
    switch (exam.status) {
      case 'READY':
        return const LinearGradient(
          colors: [AppColors.success, Color(0xFF16A34A)],
        );
      case 'PROCESSING':
        return const LinearGradient(
          colors: [AppColors.warning, Color(0xFFD97706)],
        );
      case 'DRAFT':
        return const LinearGradient(
          colors: [AppColors.textTertiary, Color(0xFF64748B)],
        );
      case 'FAILED':
        return const LinearGradient(
          colors: [AppColors.error, Color(0xFFC62828)],
        );
      default:
        return AppColors.primaryGradient;
    }
  }

  IconData get _statusIcon {
    switch (exam.status) {
      case 'READY':
        return Icons.check_circle_outline_rounded;
      case 'PROCESSING':
        return Icons.hourglass_top_rounded;
      case 'DRAFT':
        return Icons.edit_note_rounded;
      case 'FAILED':
        return Icons.error_outline_rounded;
      default:
        return Icons.assignment_rounded;
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
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      ),
    );
  }

  String get _label {
    switch (status) {
      case 'READY':
        return 'Hazır';
      case 'PROCESSING':
        return 'İşleniyor';
      case 'DRAFT':
        return 'Taslak';
      case 'FAILED':
        return 'Hata';
      default:
        return status;
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case 'READY':
        return AppColors.successLight;
      case 'PROCESSING':
        return AppColors.warningLight;
      case 'DRAFT':
        return AppColors.surfaceVariant;
      case 'FAILED':
        return AppColors.errorLight;
      default:
        return AppColors.primarySurface;
    }
  }

  Color get _textColor {
    switch (status) {
      case 'READY':
        return AppColors.success;
      case 'PROCESSING':
        return AppColors.warning;
      case 'DRAFT':
        return AppColors.textSecondary;
      case 'FAILED':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}
