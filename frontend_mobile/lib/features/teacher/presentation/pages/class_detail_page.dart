import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/app_inline_cta.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/app_text_field.dart';
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
  final TextEditingController _studentSearchController =
      TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabController.dispose();
    _studentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Container(
              color: AppColors.surface,
              child: TabBar(
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
            Expanded(
              child: BlocBuilder<ClassDetailBloc, ClassDetailState>(
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

  Widget _buildExamsTab(BuildContext context, ClassDetailLoaded state) {
    if (state.exams.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.assignment_rounded,
        title: 'Henüz sınav yok',
        subtitle: 'Bu sınıf için ilk sınavınızı oluşturun.',
        actionLabel: 'Sınav Oluştur',
        onAction: () => _navigateToCreateExam(context),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ClassDetailBloc>().add(RefreshExams(widget.classId));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          AppInlineCta(
            title: 'Yeni Sınav Ekle',
            subtitle: 'Bu sınıfa yeni bir sınav oluşturun',
            icon: Icons.note_add_rounded,
            onTap: () => _navigateToCreateExam(context),
          ),
          const SizedBox(height: 12),
          ...state.exams.map(
            (exam) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExamCard(
                exam: exam,
                onTap: () =>
                    _navigateToExamDetail(context, exam.examId, exam.title),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab(BuildContext context, ClassDetailLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ClassDetailBloc>().add(
              RefreshStudents(
                widget.classId,
                name: state.studentNameFilter,
              ),
            );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppTextField(
              controller: _studentSearchController,
              hint: 'Ad / soyad ile ara',
              prefixIcon: Icons.search_rounded,
              onChanged: _onStudentSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: AppInlineCta(
              title: 'Yeni Öğrenci Ekle',
              subtitle: 'Sınıfa öğrenci davet edin',
              icon: Icons.person_add_rounded,
              onTap: () => _navigateToAddStudent(context),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: state.students.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.people_rounded,
                    title: 'Öğrenci bulunamadı',
                    subtitle: state.studentNameFilter != null &&
                            state.studentNameFilter!.isNotEmpty
                        ? 'Aramayı değiştirmeyi deneyin.'
                        : 'Bu sınıfa öğrenci ekleyerek başlayın.',
                  )
                : ListView.separated(
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

  void _onStudentSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final query = value.trim();
      context.read<ClassDetailBloc>().add(
            RefreshStudents(
              widget.classId,
              name: query.isEmpty ? null : query,
            ),
          );
    });
  }
}
