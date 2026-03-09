import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../bloc/class_detail_bloc.dart';
import '../widgets/exam_card.dart';
import '../widgets/student_tile.dart';

class ClassDetailPage extends StatefulWidget {
  final int classId;
  final String className;

  const ClassDetailPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.className),
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.assignment_rounded, size: 20),
                text: 'Sınavlar',
              ),
              Tab(
                icon: Icon(Icons.people_rounded, size: 20),
                text: 'Öğrenciler',
              ),
            ],
          ),
        ),
        body: BlocBuilder<ClassDetailBloc, ClassDetailState>(
          builder: (context, state) {
            if (state is ClassDetailLoading) {
              return const LoadingWidget(message: 'Yükleniyor...');
            }
            if (state is ClassDetailError) {
              return AppErrorWidget(
                message: state.message,
                onRetry: () => context
                    .read<ClassDetailBloc>()
                    .add(LoadClassDetail(widget.classId)),
              );
            }
            if (state is ClassDetailLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildExamsTab(context, state),
                  _buildStudentsTab(context, state),
                ],
              );
            }
            return const SizedBox();
          },
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton.extended(
              onPressed: () => _currentTab == 0
                  ? _navigateToCreateExam(context)
                  : _navigateToAddStudent(context),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              icon: Icon(
                _currentTab == 0
                    ? Icons.note_add_rounded
                    : Icons.person_add_rounded,
              ),
              label: Text(
                _currentTab == 0 ? 'Sınav Ekle' : 'Öğrenci Ekle',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          },
        ),
      );
  }

  Widget _buildExamsTab(BuildContext context, ClassDetailLoaded state) {
    if (state.exams.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.assignment_rounded,
        title: 'Henüz sınav yok',
        subtitle: 'Bu sınıf için ilk sınavınızı oluşturun.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<ClassDetailBloc>()
            .add(RefreshExams(widget.classId));
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: state.exams.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final exam = state.exams[index];
          return ExamCard(
            exam: exam,
            onTap: () => _navigateToExamDetail(context, exam.examId, exam.title),
          );
        },
      ),
    );
  }

  Widget _buildStudentsTab(BuildContext context, ClassDetailLoaded state) {
    if (state.students.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.people_rounded,
        title: 'Henüz öğrenci yok',
        subtitle: 'Bu sınıfa öğrenci ekleyerek başlayın.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<ClassDetailBloc>()
            .add(RefreshStudents(widget.classId));
      },
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surfaceVariant,
            child: Text(
              'Toplam ${state.totalStudents} öğrenci',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: state.students.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 72,
                color: AppColors.border,
              ),
              itemBuilder: (context, index) {
                return StudentTile(student: state.students[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateExam(BuildContext context) {
    context.push('/teacher/classes/${widget.classId}/exams/create');
  }

  void _navigateToAddStudent(BuildContext context) {
    context.push('/teacher/classes/${widget.classId}/students/add');
  }

  void _navigateToExamDetail(
    BuildContext context,
    int examId,
    String title,
  ) {
    context.push('/teacher/exams/$examId?title=${Uri.encodeComponent(title)}');
  }
}
