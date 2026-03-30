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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AppSurfaceCard(
          padding: const EdgeInsets.all(16),
          radius: 16,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _statusGradient,
                  borderRadius: BorderRadius.circular(12),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatusChip(status: exam.status),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy', 'tr')
                              .format(exam.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
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
      default:
        return AppColors.primary;
    }
  }
}
