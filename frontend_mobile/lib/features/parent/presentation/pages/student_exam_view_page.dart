import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/parent_entities.dart';
import '../bloc/parent_bloc.dart';

class StudentExamViewPage extends StatelessWidget {
  final int studentId;
  final int examId;
  final String studentName;

  const StudentExamViewPage({
    super.key,
    required this.studentId,
    required this.examId,
    required this.studentName,
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
              child: BlocBuilder<ParentBloc, ParentState>(
                builder: (context, state) {
                  if (state is ParentLoading) {
                    return const ShimmerList(itemCount: 5, itemHeight: 120);
                  }
                  if (state is ParentError) {
                    return AppErrorWidget(
                      message: state.message,
                      onRetry: () => context.read<ParentBloc>().add(
                            LoadStudentExamQuestions(
                              studentId: studentId,
                              examId: examId,
                            ),
                          ),
                    );
                  }
                  if (state is StudentQuestionsLoaded) {
                    if (state.questions.isEmpty) {
                      return const EmptyStateWidget(
                        icon: Icons.quiz_outlined,
                        title: 'Soru Bulunamadı',
                        subtitle: 'Bu sınav için henüz soru işlenmemiş.',
                      );
                    }
                    return _buildQuestionList(state.questions);
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
          onPressed: () => Navigator.of(context).maybePop(),
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

  Widget _buildQuestionList(List<ParentQuestionEntity> questions) {
    return Column(
      children: [
        _buildSummaryBar(questions),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _QuestionCard(
                question: questions[index],
                index: index + 1,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBar(List<ParentQuestionEntity> questions) {
    final avgConfidence = questions.isEmpty
        ? 0.0
        : questions.map((q) => q.confidence).reduce((a, b) => a + b) /
            questions.length;
    final awardedPoints = questions.fold<double>(
      0,
      (sum, q) => sum + (q.awardedPoints ?? 0),
    );
    final maxPoints = questions.fold<double>(
      0,
      (sum, q) => sum + (q.maxPoints ?? 0),
    );

    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.all(16),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 20,
        runSpacing: 12,
        children: [
          _SummaryItem(
            label: 'Toplam Soru',
            value: '${questions.length}',
            icon: Icons.quiz_outlined,
            color: AppColors.primary,
          ),
          _SummaryItem(
            label: 'Ortalama Güven',
            value: '%${(avgConfidence * 100).round()}',
            icon: Icons.analytics_outlined,
            color: _getConfidenceColor(avgConfidence),
          ),
          if (maxPoints > 0) ...[
            _SummaryItem(
              label: 'Toplam Puan',
              value:
                  '${awardedPoints.toStringAsFixed(awardedPoints % 1 == 0 ? 0 : 1)} / ${maxPoints.toStringAsFixed(maxPoints % 1 == 0 ? 0 : 1)}',
              icon: Icons.workspace_premium_outlined,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppColors.success;
    if (confidence >= 0.5) return AppColors.warning;
    return AppColors.error;
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final ParentQuestionEntity question;
  final int index;

  const _QuestionCard({required this.question, required this.index});

  @override
  Widget build(BuildContext context) {
    final confidenceColor = _getColor(question.confidence);
    final confidencePercent = question.confidencePercent;
    final gradingConfidencePercent =
        ((question.gradingConfidence ?? 0) * 100).round();

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Soru $index',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: confidenceColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '%$confidencePercent',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: confidenceColor,
                  ),
                ),
              ),
            ],
          ),
          if (question.maxPoints != null && question.maxPoints! > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Puan: ${(question.awardedPoints ?? 0).toStringAsFixed((question.awardedPoints ?? 0) % 1 == 0 ? 0 : 1)} / ${question.maxPoints!.toStringAsFixed(question.maxPoints! % 1 == 0 ? 0 : 1)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
          if (question.questionText != null &&
              question.questionText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                question.questionText!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (question.studentAnswer != null &&
              question.studentAnswer!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.edit_note_rounded,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Öğrenci Cevabı',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.studentAnswer!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (question.expectedAnswer != null &&
              question.expectedAnswer!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoBlock(
              title: 'Beklenen Cevap',
              content: question.expectedAnswer!,
            ),
          ],
          if (question.evaluationSummary != null &&
              question.evaluationSummary!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoBlock(
              title: 'Değerlendirme Özeti',
              content: question.evaluationSummary!,
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: question.confidence,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(confidenceColor),
              minHeight: 6,
            ),
          ),
          if (question.gradingConfidence != null) ...[
            const SizedBox(height: 8),
            Text(
              'Puanlama güveni: %$gradingConfidencePercent',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColor(double confidence) {
    if (confidence >= 0.8) return AppColors.success;
    if (confidence >= 0.5) return AppColors.warning;
    return AppColors.error;
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final String content;

  const _InfoBlock({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
