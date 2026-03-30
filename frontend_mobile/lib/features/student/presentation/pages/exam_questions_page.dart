import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/app_surface_card.dart';
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
          _buildAppBar(context),
          _buildBody(),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(56, 8, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Sınav Detayı',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    examTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
                _buildSummaryBar(questions.length),
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

  Widget _buildSummaryBar(int count) {
    return AppSurfaceCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: AppColors.primarySurface,
      child: Row(
        children: [
          const Icon(Icons.quiz_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            'Toplam $count soru',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
