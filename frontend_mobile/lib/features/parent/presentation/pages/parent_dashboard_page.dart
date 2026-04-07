import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_dashboard_header.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/parent_entities.dart';
import '../cubit/parent_dashboard_cubit.dart';

class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _handleRefresh(context),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: BlocBuilder<ParentDashboardCubit, ParentDashboardState>(
                buildWhen: (prev, curr) =>
                    prev.runtimeType != curr.runtimeType ||
                    curr is ParentDashboardLoaded,
                builder: (context, state) {
                  final linked = state is ParentDashboardLoaded
                      ? state.summary.linkedStudents
                      : null;
                  final subtitle = linked != null
                      ? '$linked bağlı öğrenci'
                      : 'Öğrencilerinizin durumunu takip edin';
                  return DashboardGradientBoxHeader(
                    headline: 'Veli Paneli',
                    subtitle: subtitle,
                  );
                },
              ),
            ),
            BlocBuilder<ParentDashboardCubit, ParentDashboardState>(
              builder: (context, state) {
                if (state is ParentDashboardInitial ||
                    state is ParentDashboardLoading) {
                  return const SliverFillRemaining(
                    child: ShimmerList(itemCount: 3, itemHeight: 140),
                  );
                }
                if (state is ParentDashboardError) {
                  return SliverFillRemaining(
                    child: AppErrorWidget(
                      message: state.message,
                      onRetry: () =>
                          context.read<ParentDashboardCubit>().loadDashboard(),
                    ),
                  );
                }
                if (state is ParentDashboardLoaded) {
                  final summary = state.summary;
                  if (!summary.hasStudents) {
                    return const SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: Icons.family_restroom_outlined,
                        title: 'Bağlı Öğrenci Yok',
                        subtitle:
                            'Admin tarafından bağlanan öğrenciler burada listelenir.',
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final student = summary.students[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  index == summary.students.length - 1 ? 0 : 12,
                            ),
                            child: _ParentStudentCard(student: student),
                          );
                        },
                        childCount: summary.students.length,
                      ),
                    ),
                  );
                }
                return const SliverFillRemaining(child: SizedBox());
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh(BuildContext context) async {
    await context.read<ParentDashboardCubit>().refreshDashboard();
  }
}

class _ParentStudentCard extends StatelessWidget {
  final ParentStudentSummaryEntity student;

  const _ParentStudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final hasLatest = student.latestExamTitle != null;
    final latestDate = student.latestExamCreatedAt != null
        ? DateFormat('d MMM y', 'tr_TR').format(student.latestExamCreatedAt!)
        : null;
    final statusUi = hasLatest
        ? _ParentStatusUi.fromStatus(student.latestExamStatus ?? '')
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(
          '/parent/students/${student.studentId}/exams'
          '?name=${Uri.encodeComponent(student.fullName)}',
        ),
        borderRadius: BorderRadius.circular(18),
        child: AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    student.fullName.isNotEmpty
                        ? student.fullName
                            .trim()
                            .split(' ')
                            .where((part) => part.isNotEmpty)
                            .take(2)
                            .map((e) => e[0].toUpperCase())
                            .join()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Toplam Sınav',
                  value: '${student.totalExams}',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'Hazır',
                  value: '${student.readyExams}',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasLatest)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: statusUi!.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(statusUi.icon, color: statusUi.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.latestExamTitle!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (latestDate != null)
                          Text(
                            latestDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
            )
          else
            const Text(
              'Bu öğrenci için henüz sınav yüklenmedi.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      ),
    );
  }
}

class _ParentStatusUi {
  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  const _ParentStatusUi({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });

  static _ParentStatusUi fromStatus(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'READY':
        return const _ParentStatusUi(
          label: 'Hazır',
          color: AppColors.success,
          background: AppColors.successLight,
          icon: Icons.verified_rounded,
        );
      case 'PROCESSING':
        return const _ParentStatusUi(
          label: 'İşleniyor',
          color: AppColors.warning,
          background: AppColors.warningLight,
          icon: Icons.timelapse_rounded,
        );
      case 'DRAFT':
        return const _ParentStatusUi(
          label: 'Taslak',
          color: AppColors.textSecondary,
          background: AppColors.surfaceVariant,
          icon: Icons.edit_note_rounded,
        );
      case 'FAILED':
        return const _ParentStatusUi(
          label: 'Hata',
          color: AppColors.error,
          background: AppColors.errorLight,
          icon: Icons.error_rounded,
        );
      default:
        return const _ParentStatusUi(
          label: 'Bekleniyor',
          color: AppColors.textSecondary,
          background: AppColors.surfaceVariant,
          icon: Icons.schedule_rounded,
        );
    }
  }
}
