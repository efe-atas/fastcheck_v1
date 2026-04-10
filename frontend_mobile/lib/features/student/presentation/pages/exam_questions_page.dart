import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/student_entities.dart';
import '../bloc/exam_questions_bloc.dart';
import '../widgets/question_card.dart';

class ExamQuestionsPage extends StatelessWidget {
  final int examId;
  final String examTitle;

  const ExamQuestionsPage({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildTopBar(context)),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
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
      ),
    );
  }

  SliverToBoxAdapter _buildBody() {
    return SliverToBoxAdapter(
      child: BlocBuilder<ExamQuestionsBloc, ExamQuestionsState>(
        builder: (context, state) {
          if (state is ExamQuestionsLoading) {
            return const Padding(
              padding: EdgeInsets.only(top: 48),
              child: ShimmerList(itemCount: 5, itemHeight: 96),
            );
          }

          if (state is ExamQuestionsError) {
            return Padding(
              padding: const EdgeInsets.only(top: 48),
              child: AppErrorWidget(
                message: state.message,
                onRetry: () => context
                    .read<ExamQuestionsBloc>()
                    .add(LoadExamQuestions(examId: examId)),
              ),
            );
          }

          if (state is ExamQuestionsLoaded) {
            if (state.questions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 48),
                child: EmptyStateWidget(
                  icon: Icons.quiz_outlined,
                  title: 'Henüz soru bulunmuyor',
                  subtitle: 'Bu sınava ait sorular henüz işlenmemiş olabilir.',
                ),
              );
            }

            final questions = state.questions;
            return Column(
              children: [
                _buildSummaryBar(questions),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      return QuestionCard(
                        question: questions[index],
                        displayIndex: index + 1,
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummaryBar(List<QuestionEntity> questions) {
    final count = questions.length;
    final awarded = questions.fold<double>(
      0,
      (sum, q) => sum + (q.awardedPoints ?? 0),
    );
    final maxPoints = questions.fold<double>(
      0,
      (sum, q) => sum + (q.maxPoints ?? 0),
    );
    return AppSurfaceCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: AppColors.primarySurface,
      child: Row(
        children: [
          const Icon(Icons.quiz_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              maxPoints > 0
                  ? 'Toplam $count soru, ${awarded.toStringAsFixed(awarded % 1 == 0 ? 0 : 1)} / ${maxPoints.toStringAsFixed(maxPoints % 1 == 0 ? 0 : 1)} puan'
                  : 'Toplam $count soru',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
