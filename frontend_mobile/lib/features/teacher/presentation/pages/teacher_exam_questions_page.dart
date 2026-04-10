import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/authenticated_image.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/teacher_entities.dart';
import '../bloc/exam_bloc.dart';

class TeacherExamQuestionsPage extends StatelessWidget {
  final int examId;
  final String title;
  final int? studentId;
  final String? studentName;
  final bool showUnmatchedOnly;

  const TeacherExamQuestionsPage({
    super.key,
    required this.examId,
    required this.title,
    this.studentId,
    this.studentName,
    this.showUnmatchedOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: BlocBuilder<ExamBloc, ExamState>(
                builder: (context, state) {
                  if (state is ExamStatusLoading) {
                    return const ShimmerList(itemCount: 5, itemHeight: 120);
                  }
                  if (state is ExamError) {
                    return AppErrorWidget(
                      message: state.message,
                      onRetry: () => context
                          .read<ExamBloc>()
                          .add(LoadExamStatusEvent(examId)),
                    );
                  }
                  if (state is ExamStatusLoaded) {
                    return _buildContent(context, state.examStatus);
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ExamStatusEntity examStatus) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final selectedCluster = _resolveSelectedCluster(examStatus);

    return SafeArea(
      bottom: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 104),
        child: (studentId != null || showUnmatchedOnly)
            ? _buildFocusedContent(context, examStatus, selectedCluster)
            : _buildOverviewContent(context, examStatus),
      ),
    );
  }

  Widget _buildOverviewContent(
    BuildContext context,
    ExamStatusEntity examStatus,
  ) {
    final questions = examStatus.questions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((examStatus.gradingSystemSummary?.isNotEmpty ?? false) ||
            examStatus.totalMaxPoints != null ||
            questions.isNotEmpty ||
            examStatus.images.isNotEmpty)
          _buildGradingOverview(examStatus),
        const SizedBox(height: 16),
        _buildClusterNavigatorSection(context, examStatus),
        if (examStatus.images.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildImagesSection(
            context,
            examStatus,
            images: examStatus.images,
            title: 'Kagit sayfalari',
          ),
        ],
      ],
    );
  }

  Widget _buildFocusedContent(
    BuildContext context,
    ExamStatusEntity examStatus,
    TeacherStudentClusterEntity? selectedCluster,
  ) {
    if (selectedCluster == null) {
      return AppSurfaceCard(
        padding: const EdgeInsets.all(18),
        child: const EmptyStateWidget(
          icon: Icons.person_search_outlined,
          title: 'Ogrenci grubu bulunamadi',
          subtitle:
              'Secilen ogrenci veya atanmamis kagit grubu bu sinavda bulunamadi.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStudentOverview(selectedCluster),
        const SizedBox(height: 16),
        if (selectedCluster.images.isNotEmpty)
          _buildImagesSection(
            context,
            examStatus,
            images: selectedCluster.images,
            title: selectedCluster.unmatched
                ? 'Atanmamis sayfalar'
                : 'Ogrenciye ait sayfalar',
          ),
        if (selectedCluster.images.isNotEmpty) const SizedBox(height: 20),
        _buildFocusedQuestionSection(
            context, examStatus.examId, selectedCluster),
      ],
    );
  }

  TeacherStudentClusterEntity? _resolveSelectedCluster(
    ExamStatusEntity examStatus,
  ) {
    if (showUnmatchedOnly) {
      for (final cluster in examStatus.studentClusters) {
        if (cluster.unmatched) {
          return cluster;
        }
      }
      return null;
    }
    if (studentId == null) {
      return null;
    }
    for (final cluster in examStatus.studentClusters) {
      if (cluster.studentId == studentId) {
        return cluster;
      }
    }
    return null;
  }

  Widget _buildStudentOverview(TeacherStudentClusterEntity cluster) {
    final accentColor = cluster.needsAttention
        ? AppColors.warning
        : cluster.unmatched
            ? AppColors.error
            : AppColors.success;
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: accentColor.withValues(alpha: 0.08),
      borderColor: accentColor.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cluster.studentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (cluster.studentEmail?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text(
                        cluster.studentEmail!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _formatMatchingStatus(
                      cluster.matchingStatus, cluster.unmatched),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                icon: Icons.photo_library_outlined,
                label: '${cluster.pageCount} sayfa',
              ),
              _MetricChip(
                icon: Icons.quiz_outlined,
                label: '${cluster.questionCount} soru',
              ),
              _MetricChip(
                icon: Icons.workspace_premium_outlined,
                label:
                    '${_formatPoints(cluster.awardedPoints)} / ${_formatPoints(cluster.maxPoints)} puan',
              ),
              _MetricChip(
                icon: Icons.percent_rounded,
                label:
                    '%${cluster.scorePercentage.toStringAsFixed(cluster.scorePercentage % 1 == 0 ? 0 : 1)}',
              ),
            ],
          ),
          if (cluster.gradingSummary?.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            Text(
              cluster.gradingSummary!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClusterNavigatorSection(
    BuildContext context,
    ExamStatusEntity examStatus,
  ) {
    final clusters = examStatus.studentClusters;
    if (clusters.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.groups_outlined,
        title: 'Ogrenci grubu bulunmadi',
        subtitle: 'Kagitlar eslestikce bu ekranda ogrenci kartlari gorunecek.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'Ogrenci gruplari',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: clusters.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final cluster = clusters[index];
            return AppSurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cluster.studentName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${cluster.pageCount} sayfa • ${cluster.questionCount} soru',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_formatPoints(cluster.awardedPoints)} / ${_formatPoints(cluster.maxPoints)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _openCluster(context, examStatus, cluster),
                      icon: Icon(
                        cluster.unmatched
                            ? Icons.person_search_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        cluster.unmatched ? 'Kagitlari Eslestir' : 'Detaya Git',
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

  Widget _buildGradingOverview(ExamStatusEntity examStatus) {
    final awardedPoints = _resolveAwardedPoints(examStatus);
    final totalMaxPoints = _resolveTotalMaxPoints(examStatus);
    final matchedCount = examStatus.images
        .where((image) => image.studentMatch?.hasMatchedStudent ?? false)
        .length;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Genel ozet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Toplam puan',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalMaxPoints > 0
                          ? '${_formatPoints(awardedPoints)} / ${_formatPoints(totalMaxPoints)}'
                          : _formatPoints(awardedPoints),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${examStatus.questions.length} soru',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${examStatus.images.length} sayfa • $matchedCount eslesen kagit',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (examStatus.gradingSystemSummary?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              examStatus.gradingSystemSummary!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagesSection(
    BuildContext context,
    ExamStatusEntity examStatus, {
    required List<ExamImageEntity> images,
    required String title,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 128,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final image = images[index];
              return _ExamPaperPreviewCard(
                image: image,
                index: image.pageOrder > 0 ? image.pageOrder : index + 1,
                onTap: image.imageUrl.isEmpty
                    ? null
                    : () => _showImagePreview(
                          context,
                          examStatus: examStatus,
                          image: image,
                          index: index + 1,
                        ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFocusedQuestionSection(
    BuildContext context,
    int examId,
    TeacherStudentClusterEntity cluster,
  ) {
    final questions = [...cluster.questions]..sort((a, b) {
        final pageCompare = a.pageNumber.compareTo(b.pageNumber);
        if (pageCompare != 0) return pageCompare;
        return a.questionOrder.compareTo(b.questionOrder);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            cluster.unmatched ? 'Atanmamis sorular' : 'Soru listesi',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (questions.isEmpty)
          EmptyStateWidget(
            icon: cluster.unmatched
                ? Icons.person_search_outlined
                : Icons.quiz_outlined,
            title: cluster.unmatched
                ? 'Sorular ogrenciye baglanmayi bekliyor'
                : 'Bu ogrenci icin soru bulunmuyor',
            subtitle: cluster.unmatched
                ? 'Yukaridaki sayfalari acip manuel eslestirme yapabilirsiniz.'
                : 'OCR sonrasi soru kaydi henuz olusmamis olabilir.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final question = questions[index];
              return _QuestionCard(
                question: question,
                index: question.questionOrder > 0
                    ? question.questionOrder
                    : index + 1,
                onOverride: () => _showQuestionOverrideSheet(
                  context,
                  examId: examId,
                  question: question,
                ),
              );
            },
          ),
      ],
    );
  }

  void _openCluster(
    BuildContext context,
    ExamStatusEntity examStatus,
    TeacherStudentClusterEntity cluster,
  ) {
    final params = <String, String>{
      'title': examStatus.title,
    };
    if (cluster.unmatched) {
      params['unmatched'] = 'true';
    } else if (cluster.studentId != null) {
      params['studentId'] = cluster.studentId.toString();
      params['studentName'] = cluster.studentName;
    }
    final uri = Uri(
      path: '/teacher/exams/${examStatus.examId}/questions',
      queryParameters: params,
    );
    context.push(uri.toString());
  }

  void _showImagePreview(
    BuildContext context, {
    required ExamStatusEntity examStatus,
    required ExamImageEntity image,
    required int index,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    color: Colors.black,
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: AspectRatio(
                        aspectRatio: 0.72,
                        child: AuthenticatedImage(
                          url: image.imageUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sayfa $index',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _imageStatusLabel(image.status),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                image.studentMatch?.matchedStudentName ??
                    image.studentMatch?.detectedStudentName ??
                    'Öğrenci eşleştirmesi bekleniyor',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (examStatus.students.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await _promptStudentSelection(
                        context,
                        examStatus: examStatus,
                        image: image,
                      );
                    },
                    icon: const Icon(Icons.person_search_rounded),
                    label: Text(
                      image.studentMatch?.hasMatchedStudent ?? false
                          ? 'Öğrenciyi Değiştir'
                          : 'Öğrenci Seç',
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _promptStudentSelection(
    BuildContext context, {
    required ExamStatusEntity examStatus,
    required ExamImageEntity image,
  }) async {
    final selectedStudentId = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: examStatus.students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final student = examStatus.students[index];
              final isSelected =
                  student.userId == image.studentMatch?.matchedStudentId;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: isSelected
                    ? AppColors.primarySurface
                    : AppColors.surfaceVariant,
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(
                    isSelected
                        ? Icons.check_rounded
                        : Icons.person_outline_rounded,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
                title: Text(student.fullName),
                subtitle: Text(student.email),
                onTap: () => Navigator.of(sheetContext).pop(student.userId),
              );
            },
          ),
        );
      },
    );

    if (!context.mounted || selectedStudentId == null) {
      return;
    }

    context.read<ExamBloc>().add(
          UpdateExamImageStudentMatchEvent(
            examId: examStatus.examId,
            imageId: image.imageId,
            studentId: selectedStudentId,
          ),
        );
  }

  Future<void> _showQuestionOverrideSheet(
    BuildContext context, {
    required int examId,
    required TeacherQuestionEntity question,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _QuestionOverrideSheet(
          question: question,
          onSubmit: ({
            required double awardedPoints,
            required double maxPoints,
            String? expectedAnswer,
            String? gradingRubric,
            String? evaluationSummary,
            bool? correct,
          }) {
            context.read<ExamBloc>().add(
                  UpdateQuestionOverrideEvent(
                    examId: examId,
                    questionId: question.id,
                    awardedPoints: awardedPoints,
                    maxPoints: maxPoints,
                    expectedAnswer: expectedAnswer,
                    gradingRubric: gradingRubric,
                    evaluationSummary: evaluationSummary,
                    correct: correct,
                  ),
                );
          },
        );
      },
    );
  }

  String _imageStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return 'OCR tamamlandı';
      case 'PROCESSING':
        return 'İşleniyor';
      case 'FAILED':
        return 'İşleme hatası';
      default:
        return 'Yüklendi';
    }
  }

  double _resolveAwardedPoints(ExamStatusEntity examStatus) {
    return examStatus.questions.fold<double>(
      0,
      (sum, question) => sum + (question.awardedPoints ?? 0),
    );
  }

  double _resolveTotalMaxPoints(ExamStatusEntity examStatus) {
    final computed = examStatus.questions.fold<double>(
      0,
      (sum, question) => sum + (question.maxPoints ?? 0),
    );
    if (computed > 0) {
      return computed;
    }
    return examStatus.totalMaxPoints ?? 0;
  }

  String _formatPoints(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    if ((value * 10) == (value * 10).roundToDouble()) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(2);
  }

  String _formatMatchingStatus(String? value, bool unmatched) {
    if (unmatched) {
      return 'Atama Bekliyor';
    }
    switch (value?.toUpperCase()) {
      case 'MANUAL':
        return 'Manuel Eslesti';
      case 'AMBIGUOUS':
        return 'Kontrol Gerekli';
      case 'UNMATCHED':
        return 'Eslestirilemedi';
      case 'MATCHED':
        return 'Eslesti';
      default:
        return 'Hazir';
    }
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamPaperPreviewCard extends StatelessWidget {
  final ExamImageEntity image;
  final int index;
  final VoidCallback? onTap;

  const _ExamPaperPreviewCard({
    required this.image,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = image.imageUrl.isNotEmpty;

    return SizedBox(
      width: 112,
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    color: AppColors.surfaceVariant,
                    child: hasImage
                        ? AuthenticatedImage(
                            url: image.imageUrl,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textTertiary,
                            size: 28,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sayfa $index',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _statusLabel(image.status),
                style: TextStyle(
                  fontSize: 11,
                  color: _statusColor(image.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return 'Hazır';
      case 'PROCESSING':
        return 'İşleniyor';
      case 'FAILED':
        return 'Hata';
      default:
        return 'Yüklendi';
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
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

class _QuestionCard extends StatefulWidget {
  final TeacherQuestionEntity question;
  final int index;
  final VoidCallback onOverride;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.onOverride,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  TeacherQuestionEntity get question => widget.question;

  @override
  Widget build(BuildContext context) {
    final confidence = widget.question.confidence ?? 0;
    final awardedPoints = widget.question.awardedPoints ?? 0;
    final maxPoints = widget.question.maxPoints ?? 0;
    final gradingConfidencePercent =
        (widget.question.gradingConfidencePercent).round();
    final scoreLabel = maxPoints > 0
        ? '${awardedPoints.toStringAsFixed(awardedPoints % 1 == 0 ? 0 : 1)} / ${maxPoints.toStringAsFixed(maxPoints % 1 == 0 ? 0 : 1)} puan'
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(18),
        child: AppSurfaceCard(
          padding: const EdgeInsets.all(14),
          radius: 18,
          borderColor: _expanded
              ? AppColors.primary.withValues(alpha: 0.26)
              : AppColors.border,
          borderWidth: _expanded ? 1.4 : 1,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.index}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Soru ${widget.index}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Sayfa ${widget.question.pageNumber}${widget.question.questionType?.isNotEmpty == true ? ' • ${_formatQuestionType(widget.question.questionType!)}' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (scoreLabel != null)
                      Text(
                        scoreLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    if (scoreLabel != null &&
                        (widget.question.gradingStatus?.isNotEmpty ?? false))
                      const Text(
                        '  •  ',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    if (widget.question.gradingStatus?.isNotEmpty ?? false)
                      Expanded(
                        child: Text(
                          _formatGradingStatus(widget.question.gradingStatus!),
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
                if (widget.question.questionText?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 10),
                  _PreviewBlock(
                    title: 'Soru Metni',
                    icon: Icons.help_outline_rounded,
                    content: widget.question.questionText!,
                  ),
                ],
                if (widget.question.studentAnswer?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 10),
                  _PreviewBlock(
                    title: 'Ogrenci Cevabi',
                    icon: Icons.edit_note_rounded,
                    content: widget.question.studentAnswer!,
                  ),
                ],
                if (_expanded) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 14),
                  if (widget.question.expectedAnswer?.isNotEmpty ?? false) ...[
                    _InfoBlock(
                      title: 'Beklenen Cevap',
                      icon: Icons.fact_check_outlined,
                      content: widget.question.expectedAnswer!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (widget.question.gradingRubric?.isNotEmpty ?? false) ...[
                    _InfoBlock(
                      title: 'Rubrik',
                      icon: Icons.menu_book_outlined,
                      content: widget.question.gradingRubric!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (widget.question.evaluationSummary?.isNotEmpty ??
                      false) ...[
                    _InfoBlock(
                      title: 'Degerlendirme Ozeti',
                      icon: Icons.auto_awesome_outlined,
                      content: widget.question.evaluationSummary!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarm,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Guven Skorlari',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ProgressInfoRow(
                          label: 'OCR guveni',
                          percentLabel: '%${(confidence * 100).round()}',
                          value: confidence,
                          color: _getColor(confidence),
                        ),
                        if (widget.question.gradingConfidence != null) ...[
                          const SizedBox(height: 12),
                          _ProgressInfoRow(
                            label: 'Puanlama guveni',
                            percentLabel: '%$gradingConfidencePercent',
                            value: widget.question.gradingConfidence!,
                            color:
                                _getColor(widget.question.gradingConfidence!),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onOverride,
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Ogretmen Override'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        backgroundColor: AppColors.surfaceWarm,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColor(double confidence) {
    if (confidence >= 0.8) return AppColors.success;
    if (confidence >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  String _formatQuestionType(String value) {
    switch (value.toUpperCase()) {
      case 'MULTIPLE_CHOICE':
        return 'Coktan secmeli';
      case 'SHORT_TEXT':
        return 'Kisa cevap';
      case 'NUMERIC':
        return 'Sayisal';
      case 'OPEN_ENDED':
        return 'Acik uclu';
      default:
        return value;
    }
  }

  String _formatGradingStatus(String value) {
    switch (value.toUpperCase()) {
      case 'GRADED':
        return 'Puanlandi';
      case 'PARTIALLY_GRADED':
        return 'Kismi puan';
      case 'OVERRIDDEN':
        return 'Ogretmen override';
      case 'NEEDS_REVIEW':
        return 'Kontrol onerilir';
      case 'FAILED':
        return 'Puanlama hatasi';
      default:
        return value;
    }
  }
}

class _QuestionOverrideSheet extends StatefulWidget {
  final TeacherQuestionEntity question;
  final void Function({
    required double awardedPoints,
    required double maxPoints,
    String? expectedAnswer,
    String? gradingRubric,
    String? evaluationSummary,
    bool? correct,
  }) onSubmit;

  const _QuestionOverrideSheet({
    required this.question,
    required this.onSubmit,
  });

  @override
  State<_QuestionOverrideSheet> createState() => _QuestionOverrideSheetState();
}

class _QuestionOverrideSheetState extends State<_QuestionOverrideSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _awardedPointsController;
  late final TextEditingController _maxPointsController;
  late final TextEditingController _expectedAnswerController;
  late final TextEditingController _gradingRubricController;
  late final TextEditingController _evaluationSummaryController;
  bool? _correct;

  @override
  void initState() {
    super.initState();
    _awardedPointsController = TextEditingController(
      text: (widget.question.awardedPoints ?? 0).toString(),
    );
    _maxPointsController = TextEditingController(
      text: (widget.question.maxPoints ?? 1).toString(),
    );
    _expectedAnswerController = TextEditingController(
      text: widget.question.expectedAnswer ?? '',
    );
    _gradingRubricController = TextEditingController(
      text: widget.question.gradingRubric ?? '',
    );
    _evaluationSummaryController = TextEditingController(
      text: widget.question.evaluationSummary ?? '',
    );
    _correct = widget.question.correct;
  }

  @override
  void dispose() {
    _awardedPointsController.dispose();
    _maxPointsController.dispose();
    _expectedAnswerController.dispose();
    _gradingRubricController.dispose();
    _evaluationSummaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ogretmen Override',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.question.questionText?.isNotEmpty == true
                        ? widget.question.questionText!
                        : 'Soru ${widget.question.questionOrder}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppSurfaceCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildNumberField(
                                controller: _awardedPointsController,
                                label: 'Verilen Puan',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildNumberField(
                                controller: _maxPointsController,
                                label: 'Maksimum Puan',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildCorrectnessSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _expectedAnswerController,
                    label: 'Beklenen Cevap',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _gradingRubricController,
                    label: 'Rubrik',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _evaluationSummaryController,
                    label: 'Ogretmen Notu',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Vazgec'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Kaydet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
      ],
      decoration: _inputDecoration(label),
      validator: (value) {
        final parsed = _parseDouble(value);
        if (parsed == null) {
          return 'Gecerli sayi girin';
        }
        if (parsed < 0) {
          return 'Negatif olamaz';
        }
        return null;
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(label),
    );
  }

  Widget _buildCorrectnessSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Sonuc',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CorrectnessChip(
              label: 'Dogru',
              selected: _correct == true,
              onTap: () => setState(() => _correct = true),
            ),
            _CorrectnessChip(
              label: 'Yanlis',
              selected: _correct == false,
              onTap: () => setState(() => _correct = false),
            ),
            _CorrectnessChip(
              label: 'Kismi / Belirsiz',
              selected: _correct == null,
              onTap: () => setState(() => _correct = null),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final awarded = _parseDouble(_awardedPointsController.text) ?? 0;
    final maxPoints = _parseDouble(_maxPointsController.text) ?? 0;
    if (awarded > maxPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verilen puan maksimum puandan buyuk olamaz.'),
        ),
      );
      return;
    }

    widget.onSubmit(
      awardedPoints: awarded,
      maxPoints: maxPoints,
      expectedAnswer: _emptyToNull(_expectedAnswerController.text),
      gradingRubric: _emptyToNull(_gradingRubricController.text),
      evaluationSummary: _emptyToNull(_evaluationSummaryController.text),
      correct: _correct,
    );
    Navigator.of(context).pop();
  }

  double? _parseDouble(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return double.tryParse(value.replaceAll(',', '.'));
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _CorrectnessChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CorrectnessChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}

class _PreviewBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;

  const _PreviewBlock({
    required this.title,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;

  const _InfoBlock({
    required this.title,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressInfoRow extends StatelessWidget {
  final String label;
  final String percentLabel;
  final double value;
  final Color color;

  const _ProgressInfoRow({
    required this.label,
    required this.percentLabel,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              percentLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
