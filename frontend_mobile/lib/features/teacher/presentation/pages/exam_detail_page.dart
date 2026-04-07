import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/authenticated_image.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/teacher_entities.dart';
import '../bloc/exam_bloc.dart';

class ExamDetailPage extends StatefulWidget {
  final int examId;
  final String examTitle;

  const ExamDetailPage({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<ExamDetailPage> createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage> {
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling(BuildContext context) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      context.read<ExamBloc>().add(RefreshExamStatusEvent(widget.examId));
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.examTitle),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          BlocBuilder<ExamBloc, ExamState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => context
                    .read<ExamBloc>()
                    .add(LoadExamStatusEvent(widget.examId)),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ExamBloc, ExamState>(
        listener: (context, state) {
          if (state is ExamStatusLoaded) {
            final status = state.examStatus.examStatus.toUpperCase();
            if (status == 'PROCESSING') {
              _startPolling(context);
            } else {
              _stopPolling();
            }
          }
        },
        builder: (context, state) {
          if (state is ExamStatusLoading) {
            return const LoadingWidget(message: 'Sınav durumu yükleniyor...');
          }
          if (state is ExamError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context
                  .read<ExamBloc>()
                  .add(LoadExamStatusEvent(widget.examId)),
            );
          }
          if (state is ExamStatusLoaded) {
            return _buildContent(state.examStatus);
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildContent(ExamStatusEntity examStatus) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(examStatus),
          const SizedBox(height: 20),
          _buildNextStepCard(examStatus),
          const SizedBox(height: 20),
          if (examStatus.examStatus.toUpperCase() == 'PROCESSING')
            _buildProgressSection(examStatus),
          if (examStatus.examStatus.toUpperCase() == 'PROCESSING')
            const SizedBox(height: 20),
          _buildImagesSection(examStatus),
          if (examStatus.ocrJobs.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildAdvancedDetailsCard(examStatus),
          ],
          _buildActionButtons(context, examStatus),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ExamStatusEntity examStatus) {
    final status = examStatus.examStatus.toUpperCase();

    if (status == 'FAILED' || status == 'ERROR') {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<ExamBloc>().add(ReprocessExamEvent(examStatus.examId));
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: const Text(
              'Yeniden İşle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      );
    }

    if (status == 'READY' || status == 'COMPLETED' || status == 'DONE') {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              context.push(
                '/teacher/exams/${examStatus.examId}/questions?title=${Uri.encodeComponent(examStatus.title)}',
              );
            },
            icon: const Icon(Icons.quiz_rounded, color: Colors.white),
            label: Text(
              'Soruları Gör (${examStatus.questionCount} Soru)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildNextStepCard(ExamStatusEntity examStatus) {
    final status = examStatus.examStatus.toUpperCase();
    String message;

    switch (status) {
      case 'PROCESSING':
      case 'IN_PROGRESS':
        message =
            'Sınav kağıtları işleniyor. Birkaç dakika sonra tekrar kontrol edin.';
        break;
      case 'READY':
      case 'COMPLETED':
      case 'DONE':
        message = 'Sınav hazır. Öğrenciler soru detaylarını görüntüleyebilir.';
        break;
      case 'FAILED':
      case 'ERROR':
        message =
            'İşlemde hata oluştu. Gelişmiş detaylardan hatayı kontrol edin.';
        break;
      default:
        message =
            'Sınav taslak durumda. İsterseniz görsel yükleyerek devam edin.';
        break;
    }

    return AppSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(ExamStatusEntity examStatus) {
    final status = examStatus.examStatus.toUpperCase();
    return AppSurfaceCard(
      padding: const EdgeInsets.all(20),
      radius: 16,
      backgroundColor: _statusBgColor(status),
      borderColor: _statusColor(status).withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _statusIcon(status),
              color: _statusColor(status),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  examStatus.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(ExamStatusEntity examStatus) {
    final total = examStatus.images.length;
    final processed = examStatus.images
        .where((img) => img.status.toUpperCase() != 'PENDING')
        .length;
    final progress = total > 0 ? processed / total : 0.0;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(20),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              const Text(
                'İşlem Durumu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$processed / $total',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.warningLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.warning),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fotoğraflar işleniyor, lütfen bekleyin...',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection(ExamStatusEntity examStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library_rounded,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Fotoğraflar (${examStatus.images.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (examStatus.images.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                Icon(Icons.image_not_supported_rounded,
                    size: 40, color: AppColors.textTertiary),
                SizedBox(height: 8),
                Text(
                  'Henüz fotoğraf yüklenmedi',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: examStatus.images.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final image = examStatus.images[index];
              return _buildImageTile(image, index);
            },
          ),
      ],
    );
  }

  Widget _buildImageTile(ExamImageEntity image, int index) {
    final imageStatus = image.status.toUpperCase();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: image.imageUrl.isNotEmpty
                ? AuthenticatedImage(
                    url: image.imageUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _statusColor(imageStatus).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.image_rounded,
                      color: _statusColor(imageStatus),
                      size: 20,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sayfa ${index + 1}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusBgColor(imageStatus),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(imageStatus),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _statusColor(imageStatus),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrJobsSection(ExamStatusEntity examStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.text_snippet_rounded,
                size: 20, color: AppColors.secondary),
            SizedBox(width: 8),
            Text(
              'OCR İşleri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: examStatus.ocrJobs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final job = examStatus.ocrJobs[index];
            final jobStatus = job.status.toUpperCase();
            return AppSurfaceCard(
              padding: const EdgeInsets.all(14),
              radius: 12,
              child: Row(
                children: [
                  Icon(
                    _statusIcon(jobStatus),
                    color: _statusColor(jobStatus),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İş ${job.jobId.length > 8 ? job.jobId.substring(0, 8) : job.jobId}…',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (job.errorMessage != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            job.errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusBgColor(jobStatus),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(jobStatus),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(jobStatus),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedDetailsCard(ExamStatusEntity examStatus) {
    return AppSurfaceCard(
      radius: 12,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          title: const Text(
            'Gelişmiş teknik detaylar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: const Text(
            'OCR işleri ve hata kayıtları',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: _buildOcrJobsSection(examStatus),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'READY':
      case 'COMPLETED':
      case 'DONE':
        return AppColors.success;
      case 'PROCESSING':
      case 'PENDING':
      case 'IN_PROGRESS':
        return AppColors.warning;
      case 'FAILED':
      case 'ERROR':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'READY':
      case 'COMPLETED':
      case 'DONE':
        return AppColors.successLight;
      case 'PROCESSING':
      case 'PENDING':
      case 'IN_PROGRESS':
        return AppColors.warningLight;
      case 'FAILED':
      case 'ERROR':
        return AppColors.errorLight;
      default:
        return AppColors.surfaceVariant;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'READY':
      case 'COMPLETED':
      case 'DONE':
        return Icons.check_circle_rounded;
      case 'PROCESSING':
      case 'IN_PROGRESS':
        return Icons.hourglass_top_rounded;
      case 'PENDING':
        return Icons.schedule_rounded;
      case 'FAILED':
      case 'ERROR':
        return Icons.error_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'READY':
      case 'COMPLETED':
      case 'DONE':
        return 'Hazır';
      case 'PROCESSING':
      case 'IN_PROGRESS':
        return 'İşleniyor';
      case 'PENDING':
        return 'Bekliyor';
      case 'FAILED':
      case 'ERROR':
        return 'Hata';
      default:
        return 'Taslak';
    }
  }
}
