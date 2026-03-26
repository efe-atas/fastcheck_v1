import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/gradient_dashboard_header.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../bloc/student_exams_bloc.dart';
import '../widgets/exam_list_tile.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          _buildHeader(context),
        ],
        body: Column(
          children: [
            _FilterChips(),
            const SizedBox(height: 4),
            const Expanded(child: _ExamList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return DashboardGradientSliverAppBar(
      expandedHeight: 160,
      pinned: true,
      expandedContentAlignment: Alignment.bottomLeft,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: () {
            context
                .read<StudentExamsBloc>()
                .add(const RefreshStudentExams());
          },
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
      expandedChild: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: Row(
          children: [
            const DashboardGradientIconBadge(
              icon: Icons.school_rounded,
              size: 48,
              iconSize: 26,
              borderRadius: AppSpacing.radiusMd,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Merhaba! 👋',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sınavlarım',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  static const _filters = <String?, String>{
    null: 'Tümü',
    'READY': 'Hazır',
    'PROCESSING': 'İşleniyor',
    'DRAFT': 'Taslak',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentExamsBloc, StudentExamsState>(
      buildWhen: (prev, curr) {
        final prevFilter =
            prev is StudentExamsLoaded ? prev.activeFilter : null;
        final currFilter =
            curr is StudentExamsLoaded ? curr.activeFilter : null;
        return prevFilter != currFilter || prev.runtimeType != curr.runtimeType;
      },
      builder: (context, state) {
        final active =
            state is StudentExamsLoaded ? state.activeFilter : null;

        return Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final entry = _filters.entries.elementAt(index);
                final isActive = active == entry.key;

                return FilterChip(
                  selected: isActive,
                  label: Text(entry.value),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                  backgroundColor: AppColors.surfaceVariant,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isActive ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onSelected: (_) {
                    context
                        .read<StudentExamsBloc>()
                        .add(FilterExamsByStatus(entry.key));
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ExamList extends StatefulWidget {
  const _ExamList();

  @override
  State<_ExamList> createState() => _ExamListState();
}

class _ExamListState extends State<_ExamList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<StudentExamsBloc>().add(const LoadMoreExams());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= maxScroll - 200;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentExamsBloc, StudentExamsState>(
      builder: (context, state) {
        if (state is StudentExamsLoading) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 100),
            child: ShimmerList(itemCount: 6, itemHeight: 88),
          );
        }

        if (state is StudentExamsError) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: AppErrorWidget(
              message: state.message,
              onRetry: () => context
                  .read<StudentExamsBloc>()
                  .add(const RefreshStudentExams()),
            ),
          );
        }

        if (state is StudentExamsLoaded) {
          if (state.exams.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: EmptyStateWidget(
                icon: Icons.assignment_outlined,
                title: 'Henüz sınav bulunmuyor',
                subtitle: state.activeFilter != null
                    ? 'Bu filtreye uygun sınav yok. Filtreyi değiştirmeyi deneyin.'
                    : 'Öğretmeniniz sınav eklediğinde burada görünecektir.',
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              context
                  .read<StudentExamsBloc>()
                  .add(const RefreshStudentExams());
            },
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              itemCount: state.exams.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= state.exams.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }

                final exam = state.exams[index];
                return ExamListTile(
                  exam: exam,
                  onTap: () {
                    context.push(
                      '/student/exams/${exam.examId}/questions?title=${Uri.encodeComponent(exam.title)}',
                    );
                  },
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
