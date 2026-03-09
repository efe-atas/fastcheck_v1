import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
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
      appBar: AppBar(
        title: Text('$studentName - Sınav'),
      ),
      body: BlocBuilder<ParentBloc, ParentState>(
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            label: 'Toplam Soru',
            value: '${questions.length}',
            icon: Icons.quiz_outlined,
            color: AppColors.primary,
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          _SummaryItem(
            label: 'Ortalama Güven',
            value: '%${(avgConfidence * 100).round()}',
            icon: Icons.analytics_outlined,
            color: _getConfidenceColor(avgConfidence),
          ),
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

    return Card(
      child: Padding(
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
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
          ],
        ),
      ),
    );
  }

  Color _getColor(double confidence) {
    if (confidence >= 0.8) return AppColors.success;
    if (confidence >= 0.5) return AppColors.warning;
    return AppColors.error;
  }
}
