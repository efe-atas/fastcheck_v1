import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/gradient_dashboard_header.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entities/student_entities.dart';
import '../bloc/student_exams_bloc.dart';
import '../cubit/student_dashboard_cubit.dart';
import '../widgets/exam_list_tile.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _handleRefresh(context),
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxScrolled) => [
            _buildHeader(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _StudentSummarySection(
                  onRetry: () =>
                      context.read<StudentDashboardCubit>().loadDashboard(),
                ),
              ),
            ),
          ],
          body: Column(
            children: [
              _FilterChips(),
              const SizedBox(height: 4),
              const Expanded(child: _ExamList()),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh(BuildContext context) async {
    final dashboardCubit = context.read<StudentDashboardCubit>();
    final examsBloc = context.read<StudentExamsBloc>();
    examsBloc.add(const RefreshStudentExams());
    final examsFuture = examsBloc.stream.firstWhere(
      (state) => state is StudentExamsLoaded || state is StudentExamsError,
    );
    await Future.wait([
      dashboardCubit.refreshDashboard(),
      examsFuture,
    ]);
  }

  Widget _buildHeader(BuildContext context) {
    return DashboardGradientSliverAppBar(
      expandedHeight: 160,
      pinned: true,
      expandedContentAlignment: Alignment.bottomLeft,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onSelected: (value) {
            if (value == 'logout') {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: 'logout',
              child: Text('Çıkış yap'),
            ),
          ],
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
        final active = state is StudentExamsLoaded ? state.activeFilter : null;

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

          return ListView.separated(
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
                  if (exam.status.toUpperCase() != 'READY') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Bu sınav henüz hazır değil. Hazır olduğunda sorular açılacaktır.',
                        ),
                      ),
                    );
                    return;
                  }
                  context.push(
                    '/student/exams/${exam.examId}/questions?title=${Uri.encodeComponent(exam.title)}',
                  );
                },
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _StudentSummarySection extends StatelessWidget {
  final VoidCallback onRetry;

  const _StudentSummarySection({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentDashboardCubit, StudentDashboardState>(
      builder: (context, state) {
        if (state is StudentDashboardInitial ||
            state is StudentDashboardLoading) {
          return const _StudentSummarySkeleton();
        }
        if (state is StudentDashboardError) {
          return _SummaryErrorCard(message: state.message, onRetry: onRetry);
        }
        if (state is StudentDashboardLoaded) {
          final summary = state.summary;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryMetricGrid(summary: summary),
              const SizedBox(height: 16),
              _LatestExamsSection(exams: summary.latestExams),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _SummaryMetricGrid extends StatelessWidget {
  final StudentDashboardSummaryEntity summary;

  const _SummaryMetricGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryMetricCard(
                label: 'Toplam Sınav',
                value: '${summary.totalExams}',
                icon: Icons.quiz_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryMetricCard(
                label: 'Hazır',
                value: '${summary.readyExams}',
                icon: Icons.verified_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryMetricCard(
                label: 'İşleniyor',
                value: '${summary.processingExams}',
                icon: Icons.sync_rounded,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryMetricCard(
                label: 'Taslak',
                value: '${summary.draftExams}',
                icon: Icons.edit_note_rounded,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      borderColor: Colors.transparent,
      backgroundColor: color.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestExamsSection extends StatelessWidget {
  final List<StudentExamEntity> exams;

  const _LatestExamsSection({required this.exams});

  @override
  Widget build(BuildContext context) {
    final visible = exams.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Son sınavlar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          AppSurfaceCard(
            padding: const EdgeInsets.all(20),
            borderColor: Colors.transparent,
            child: const Text(
              'Henüz herhangi bir sınav oluşturulmadı.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          Column(
            children: visible
                .map(
                  (exam) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LatestExamTile(exam: exam),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _LatestExamTile extends StatelessWidget {
  final StudentExamEntity exam;

  const _LatestExamTile({required this.exam});

  @override
  Widget build(BuildContext context) {
    final statusUi = _StatusUi.fromStatus(exam.status);
    final dateLabel = DateFormat('d MMM y', 'tr_TR').format(exam.createdAt);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.border,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: statusUi.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(statusUi.icon, color: statusUi.color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateLabel · Sınıf #${exam.classId}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusUi.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              statusUi.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusUi.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SummaryErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      backgroundColor: AppColors.errorLight,
      borderColor: Colors.transparent,
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar Dene'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentSummarySkeleton extends StatelessWidget {
  const _StudentSummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: _SkeletonCard()),
            SizedBox(width: 12),
            Expanded(child: _SkeletonCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(child: _SkeletonCard()),
            SizedBox(width: 12),
            Expanded(child: _SkeletonCard()),
          ],
        ),
        const SizedBox(height: 16),
        const _SkeletonCard(height: 92),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;

  const _SkeletonCard({this.height = 116});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _StatusUi {
  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  const _StatusUi({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });

  static _StatusUi fromStatus(String status) {
    switch (status.toUpperCase()) {
      case 'READY':
        return const _StatusUi(
          label: 'Hazır',
          color: AppColors.success,
          background: AppColors.successLight,
          icon: Icons.check_circle_rounded,
        );
      case 'PROCESSING':
        return const _StatusUi(
          label: 'İşleniyor',
          color: AppColors.warning,
          background: AppColors.warningLight,
          icon: Icons.autorenew_rounded,
        );
      case 'DRAFT':
        return const _StatusUi(
          label: 'Taslak',
          color: AppColors.textSecondary,
          background: AppColors.surfaceVariant,
          icon: Icons.edit_note_rounded,
        );
      default:
        return const _StatusUi(
          label: 'Bilinmiyor',
          color: AppColors.textSecondary,
          background: AppColors.surfaceVariant,
          icon: Icons.help_outline_rounded,
        );
    }
  }
}
