import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
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
        child: const _StudentDashboardScrollView(),
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
}

class _StudentDashboardScrollView extends StatefulWidget {
  const _StudentDashboardScrollView();

  @override
  State<_StudentDashboardScrollView> createState() =>
      _StudentDashboardScrollViewState();
}

class _StudentDashboardScrollViewState
    extends State<_StudentDashboardScrollView> {
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
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= maxScroll - 200) {
      context.read<StudentExamsBloc>().add(const LoadMoreExams());
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: const [
        _DashboardHeroSliver(),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _ExamWorkspaceHeader(),
          ),
        ),
        _ExamListSliver(),
      ],
    );
  }
}

class _DashboardHeroSliver extends StatelessWidget {
  const _DashboardHeroSliver();

  @override
  Widget build(BuildContext context) {
    final formatted =
        DateFormat('EEEE, d MMMM y', 'tr_TR').format(DateTime.now());
    final top = MediaQuery.paddingOf(context).top;
    const metricCardHeight = 126.0;
    const overlapAmount = 62.0;

    return SliverToBoxAdapter(
      child: BlocBuilder<StudentDashboardCubit, StudentDashboardState>(
        builder: (context, state) {
          final summary = state is StudentDashboardLoaded
              ? state.summary
              : const StudentDashboardSummaryEntity(
                  totalExams: 0,
                  readyExams: 0,
                  processingExams: 0,
                  draftExams: 0,
                  latestExams: [],
                );
          final isLoading = state is StudentDashboardInitial ||
              state is StudentDashboardLoading;

          return Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.headerGradient,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        top + 12,
                        16,
                        overlapAmount + 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 80.5,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 5.5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Merhaba, Öğrenci',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          height: 1.02,
                                        ),
                                      ),
                                      const Text(
                                        'Panelin hazır 👋',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          height: 1.02,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _capitalizeFirst(formatted),
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.65),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Column(
                                    children: [
                                      InkWell(
                                        onTap: () => context
                                            .read<AuthBloc>()
                                            .add(const AuthLogoutRequested()),
                                        borderRadius: BorderRadius.circular(18),
                                        child: Ink(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.16),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.more_horiz_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 30,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0x400BBFB0),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'OGRENCI',
                                          style: TextStyle(
                                            color: Color(0xFF0BBFB0),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            height: 112,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF5C72F6),
                                          Color(0xFF3346C7),
                                          Color(0xFF1C2D9D),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.black.withValues(alpha: 0.10),
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  bottom: 28,
                                  child: Text(
                                    isLoading
                                        ? 'Sınav verileri yükleniyor'
                                        : '${summary.readyExams} sınav hazır bekliyor',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  bottom: 12,
                                  child: Text(
                                    _heroSubtitle(summary, isLoading),
                                    style: const TextStyle(
                                      color: Color(0xC9FFFFFF),
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: -overlapAmount,
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: metricCardHeight,
                            child: _HeroMetric(
                              icon: Icons.assignment_rounded,
                              value: isLoading ? '—' : '${summary.totalExams}',
                              label: 'Toplam Sınav',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: metricCardHeight,
                            child: _HeroMetric(
                              icon: Icons.timelapse_rounded,
                              value: isLoading
                                  ? '—'
                                  : '${summary.processingExams}',
                              label: 'İşlenenler',
                              badgeDot: summary.processingExams > 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: metricCardHeight,
                            child: _HeroMetric(
                              icon: Icons.check_circle_rounded,
                              value: isLoading ? '—' : '${summary.readyExams}',
                              label: 'Hazır Sınav',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: overlapAmount + 6),
            ],
          );
        },
      ),
    );
  }

  String _heroSubtitle(StudentDashboardSummaryEntity summary, bool isLoading) {
    if (isLoading) {
      return 'Özet ve son sınavlar birkaç saniye içinde güncellenecek';
    }
    if (summary.totalExams == 0) {
      return 'Öğretmenin ilk sınavı eklediğinde burası otomatik dolacak';
    }
    if (summary.processingExams > 0) {
      return 'İşlenen sınavlar tamamlandıkça aşağıdaki liste güncellenecek';
    }
    return 'Hazır olan sınavları aşağıdaki listeden hemen açabilirsin';
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.badgeDot = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool badgeDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9DFF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F1729),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF5068F3), size: 18),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0F1729),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 0.95,
                ),
              ),
              if (badgeDot) ...[
                const SizedBox(width: 2),
                const Icon(Icons.circle, size: 8, color: Color(0xFF0BBFB0)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7A99),
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamWorkspaceHeader extends StatelessWidget {
  const _ExamWorkspaceHeader();

  static const _filters = <String?, String>{
    null: 'Tümü',
    'READY': 'Hazır',
    'PROCESSING': 'İşleniyor',
    'DRAFT': 'Taslak',
    'FAILED': 'Hata',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Sınav Listesi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              Text(
                'Duruma göre filtrele',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BlocBuilder<StudentExamsBloc, StudentExamsState>(
            buildWhen: (prev, curr) {
              final prevFilter =
                  prev is StudentExamsLoaded ? prev.activeFilter : null;
              final currFilter =
                  curr is StudentExamsLoaded ? curr.activeFilter : null;
              return prevFilter != currFilter ||
                  prev.runtimeType != curr.runtimeType;
            },
            builder: (context, state) {
              final active =
                  state is StudentExamsLoaded ? state.activeFilter : null;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.entries.map((entry) {
                    final isActive = active == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          context
                              .read<StudentExamsBloc>()
                              .add(FilterExamsByStatus(entry.key));
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ExamListSliver extends StatelessWidget {
  const _ExamListSliver();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentExamsBloc, StudentExamsState>(
      builder: (context, state) {
        if (state is StudentExamsLoading) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 110),
              child: ShimmerList(itemCount: 6, itemHeight: 96),
            ),
          );
        }

        if (state is StudentExamsError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              child: AppErrorWidget(
                message: state.message,
                onRetry: () => context
                    .read<StudentExamsBloc>()
                    .add(const RefreshStudentExams()),
              ),
            ),
          );
        }

        if (state is! StudentExamsLoaded || state.exams.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              child: EmptyStateWidget(
                icon: Icons.assignment_outlined,
                title: 'Henüz sınav bulunmuyor',
                subtitle: state is StudentExamsLoaded &&
                        state.activeFilter != null
                    ? 'Bu filtrede kayıt görünmüyor. Başka bir durum seçerek tekrar kontrol edin.'
                    : 'Öğretmeniniz sınav eklediğinde bu alan otomatik olarak dolacak.',
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
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
                return Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        index == state.exams.length - 1 && !state.isLoadingMore
                            ? 0
                            : 12,
                  ),
                  child: ExamListTile(
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
                  ),
                );
              },
              childCount: state.exams.length + (state.isLoadingMore ? 1 : 0),
            ),
          ),
        );
      },
    );
  }
}

String _capitalizeFirst(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}
