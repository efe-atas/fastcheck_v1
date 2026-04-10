import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../domain/entities/parent_entities.dart';
import '../../domain/usecases/parent_usecases.dart';

class ParentStudentExamsPage extends StatefulWidget {
  final int studentId;
  final String studentName;

  const ParentStudentExamsPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ParentStudentExamsPage> createState() => _ParentStudentExamsPageState();
}

class _ParentStudentExamsPageState extends State<ParentStudentExamsPage> {
  final List<ParentStudentExamEntity> _exams = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  String? _activeFilter;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 0;
        _exams.clear();
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    final usecase = GetIt.I<GetParentStudentExams>();
    final result = await usecase(GetParentStudentExamsParams(
      studentId: widget.studentId,
      page: _currentPage,
      size: 20,
      examStatus: _activeFilter,
    ));

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = failure.message;
      }),
      (paged) => setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _exams.addAll(paged.content);
        _totalPages = paged.totalPages;
      }),
    );
  }

  void _onFilterChanged(String? filter) {
    setState(() => _activeFilter = filter);
    _loadExams();
  }

  void _loadMore() {
    if (_isLoadingMore || _currentPage + 1 >= _totalPages) return;
    _currentPage++;
    _loadExams(reset: false);
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
            _buildFilterChips(),
            const SizedBox(height: 4),
            Expanded(child: _buildBody()),
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

  Widget _buildFilterChips() {
    const filters = <String?, String>{
      null: 'Tümü',
      'READY': 'Hazır',
      'PROCESSING': 'İşleniyor',
      'DRAFT': 'Taslak',
      'FAILED': 'Hata',
    };

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final entry = filters.entries.elementAt(index);
            final isActive = _activeFilter == entry.key;

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
              onSelected: (_) => _onFilterChanged(entry.key),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ShimmerList(itemCount: 6, itemHeight: 88);
    }
    if (_error != null) {
      return AppErrorWidget(
        message: _error!,
        onRetry: () => _loadExams(),
      );
    }
    if (_exams.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.assignment_outlined,
        title: 'Sınav bulunmuyor',
        subtitle: _activeFilter != null
            ? 'Bu filtreye uygun sınav yok.'
            : 'Öğrencinin sınıfında henüz sınav oluşturulmamış.',
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          _loadMore();
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        itemCount: _exams.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _exams.length) {
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
          final exam = _exams[index];
          return _ParentExamTile(
            exam: exam,
            onTap: () {
              if (exam.status.toUpperCase() != 'READY') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Bu sınav henüz hazır değil. Hazır olduğunda sorular görüntülenebilir.',
                    ),
                  ),
                );
                return;
              }
              context.push(
                '/parent/students/${widget.studentId}/exams/${exam.examId}/questions'
                '?title=${Uri.encodeComponent(exam.title)}',
              );
            },
          );
        },
      ),
    );
  }
}

class _ParentExamTile extends StatelessWidget {
  final ParentStudentExamEntity exam;
  final VoidCallback? onTap;

  const _ParentExamTile({required this.exam, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusUi = _ExamStatusUi.fromStatus(exam.status);
    final dateLabel = DateFormat('d MMM y', 'tr_TR').format(exam.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AppSurfaceCard(
          padding: const EdgeInsets.all(16),
          radius: 16,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: statusUi.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusUi.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusUi.bgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusUi.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusUi.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamStatusUi {
  final String label;
  final Color color;
  final Color bgColor;
  final LinearGradient gradient;
  final IconData icon;

  const _ExamStatusUi({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.gradient,
    required this.icon,
  });

  static _ExamStatusUi fromStatus(String status) {
    switch (status.toUpperCase()) {
      case 'READY':
        return const _ExamStatusUi(
          label: 'Hazır',
          color: AppColors.success,
          bgColor: AppColors.successLight,
          gradient: LinearGradient(
            colors: [AppColors.success, Color(0xFF16A34A)],
          ),
          icon: Icons.check_circle_outline_rounded,
        );
      case 'PROCESSING':
        return const _ExamStatusUi(
          label: 'İşleniyor',
          color: AppColors.warning,
          bgColor: AppColors.warningLight,
          gradient: LinearGradient(
            colors: [AppColors.warning, Color(0xFFD97706)],
          ),
          icon: Icons.hourglass_top_rounded,
        );
      case 'DRAFT':
        return const _ExamStatusUi(
          label: 'Taslak',
          color: AppColors.textSecondary,
          bgColor: AppColors.surfaceVariant,
          gradient: LinearGradient(
            colors: [AppColors.textTertiary, Color(0xFF64748B)],
          ),
          icon: Icons.edit_note_rounded,
        );
      case 'FAILED':
        return const _ExamStatusUi(
          label: 'Hata',
          color: AppColors.error,
          bgColor: AppColors.errorLight,
          gradient: LinearGradient(
            colors: [AppColors.error, Color(0xFFC62828)],
          ),
          icon: Icons.error_outline_rounded,
        );
      default:
        return _ExamStatusUi(
          label: status,
          color: AppColors.textSecondary,
          bgColor: AppColors.surfaceVariant,
          gradient: AppColors.primaryGradient,
          icon: Icons.assignment_rounded,
        );
    }
  }
}
