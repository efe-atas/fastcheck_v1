import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_inline_cta.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/teacher_entities.dart';
import '../../domain/usecases/teacher_usecases.dart';

class TeacherExamsPage extends StatefulWidget {
  const TeacherExamsPage({super.key});

  @override
  State<TeacherExamsPage> createState() => _TeacherExamsPageState();
}

class _TeacherExamsPageState extends State<TeacherExamsPage> {
  bool _isLoading = true;
  String? _error;
  List<_ExamListItem> _allExams = const [];
  int _activeTab = 0;
  final _quickTitleController = TextEditingController();
  final _quickSubjectController = TextEditingController();
  final Map<String, int> _classNameToId = {};
  String? _quickClass;
  DateTime _quickPlannedDate = DateTime.now();
  bool _isQuickCreating = false;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  @override
  void dispose() {
    _quickTitleController.dispose();
    _quickSubjectController.dispose();
    super.dispose();
  }

  Future<void> _loadExams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final classesResult = await sl<GetClasses>()(const NoParams());
    final loaded = await classesResult.fold(
      (failure) async {
        _error = failure.message;
        return <_ExamListItem>[];
      },
      (classes) async {
        _classNameToId.clear();
        final getClassExams = sl<GetClassExams>();
        final list = <_ExamListItem>[];
        for (final classEntity in classes) {
          _classNameToId[classEntity.className] = classEntity.classId;
          final examsResult = await getClassExams(classEntity.classId);
          examsResult.fold(
            (_) => null,
            (exams) {
              list.addAll(
                exams.map((exam) => _ExamListItem(
                      exam: exam,
                      className: classEntity.className,
                    )),
              );
            },
          );
        }
        list.sort((a, b) => b.exam.createdAt.compareTo(a.exam.createdAt));
        return list;
      },
    );

    if (!mounted) return;
    setState(() {
      _allExams = loaded;
      _isLoading = false;
      _quickClass ??=
          (_classNameToId.isNotEmpty ? _classNameToId.keys.first : null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredExams();
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: RefreshIndicator(
        color: const Color(0xFF3B4FD8),
        onRefresh: _loadExams,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top + 18,
            16,
            72,
          ),
          children: [
            const Text(
              'Sınavlar',
              style: TextStyle(
                color: Color(0xFF0F1729),
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(height: 16),
            _StatusTabs(
              activeIndex: _activeTab,
              onChanged: (index) => setState(() => _activeTab = index),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EDF6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EDF6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.filter_alt_outlined,
                      color: Color(0xFF3A4864)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppInlineCta(
              title: 'Yeni Sınav Oluştur',
              subtitle: 'Sınıf seçip hızlıca sınav ekleyin',
              icon: Icons.add_rounded,
              onTap: _openQuickCreateSheet,
            ),
            const SizedBox(height: 12),
            if (_error != null)
              _ErrorCard(
                message: _error!,
                onRetry: _loadExams,
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              const _ExamEmptyState()
            else
              ...filtered.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ExamOverviewCard(
                    item: item,
                    onTap: () => context.push(
                      '/teacher/exams/${item.exam.examId}?title=${Uri.encodeComponent(item.exam.title)}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_ExamListItem> _filteredExams() {
    if (_activeTab == 0) {
      return _allExams
          .where((item) => !_isCompleted(item.exam.status))
          .toList();
    }
    if (_activeTab == 1) {
      return _allExams.where((item) => _isCompleted(item.exam.status)).toList();
    }
    return _allExams.where((item) => _isDraft(item.exam.status)).toList();
  }

  bool _isCompleted(String status) {
    final normalized = status.toUpperCase();
    return normalized == 'READY' ||
        normalized == 'DONE' ||
        normalized == 'COMPLETED';
  }

  bool _isDraft(String status) {
    final normalized = status.toUpperCase();
    return normalized == 'DRAFT' || normalized == 'PENDING';
  }

  List<String> _classOptions() {
    if (_classNameToId.isNotEmpty) {
      final list = _classNameToId.keys.toList()..sort();
      return list;
    }
    return const [];
  }

  void _openQuickCreateSheet() {
    if (_classNameToId.isEmpty) {
      showAppToast(
        context,
        message: 'Önce bir sınıf oluşturmalısınız.',
        destructive: true,
      );
      return;
    }
    final classes = _classOptions();
    _quickClass ??= classes.first;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, modalSetState) {
            final plannedDateLabel =
                DateFormat('d MMM yyyy', 'tr_TR').format(_quickPlannedDate);
            final keyboardInset = MediaQuery.viewInsetsOf(ctx).bottom;
            final safeBottom = MediaQuery.viewPaddingOf(ctx).bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 12),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5EAFE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.flash_on_rounded,
                              color: Color(0xFF3B4FD8),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hızlı sınav oluştur',
                                  style: TextStyle(
                                    color: Color(0xFF0F1729),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Başlığı yazın, sınıfı seçin; sınav taslak olarak listeye insin.',
                                  style: TextStyle(
                                    color: Color(0xFF6B7A99),
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      AppTextField(
                        controller: _quickTitleController,
                        label: 'Sınav başlığı',
                        hint: 'Örn. Matematik quiz',
                        prefixIcon: Icons.title_rounded,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _quickSubjectController,
                        label: 'Ders türü',
                        hint: 'Örn. Fizik',
                        prefixIcon: Icons.menu_book_outlined,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Sınıf',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4E5E7C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _quickClass,
                            borderRadius: BorderRadius.circular(16),
                            icon: const Icon(Icons.expand_more_rounded),
                            items: classes
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _quickClass = value);
                              modalSetState(() {});
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Planlanan tarih',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4E5E7C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _selectPlannedDate(ctx, modalSetState),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_available_outlined,
                                  color: Color(0xFF6B7A99)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  plannedDateLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF0F1729),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(Icons.edit_calendar_rounded,
                                  color: Color(0xFF6B7A99)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AppGradientButton(
                        text: 'Oluştur',
                        isLoading: _isQuickCreating,
                        onPressed: _isQuickCreating
                            ? null
                            : () async {
                                final title = _quickTitleController.text.trim();
                                if (title.isEmpty) {
                                  showAppToast(
                                    context,
                                    message: 'Başlık gerekli',
                                    destructive: true,
                                  );
                                  return;
                                }
                                final navigator = Navigator.of(ctx);
                                final success = await _createQuickExam(
                                  title,
                                  _quickClass ?? classes.first,
                                  _quickSubjectController.text.trim(),
                                  _quickPlannedDate,
                                  modalSetState,
                                );
                                if (!mounted || !success) return;
                                if (navigator.canPop()) {
                                  navigator.pop();
                                }
                              },
                      ),
                      SizedBox(height: safeBottom + 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectPlannedDate(
    BuildContext context, [
    void Function(void Function())? onSheetState,
  ]) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _quickPlannedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      helpText: 'Planlanan tarih',
      locale: const Locale('tr', 'TR'),
    );
    if (selected != null) {
      if (!mounted) return;
      setState(() => _quickPlannedDate = selected);
      onSheetState?.call(() {});
    }
  }

  Future<bool> _createQuickExam(
    String title,
    String className,
    String subject,
    DateTime plannedDate,
    void Function(void Function())? onSheetState,
  ) async {
    final classId = _classNameToId[className];
    if (classId == null) {
      showAppToast(
        context,
        message:
            'Sınıf bulunamadı. Lütfen sınıf listesi yüklendikten sonra deneyin.',
        destructive: true,
      );
      return false;
    }

    if (!mounted) return false;
    setState(() => _isQuickCreating = true);
    onSheetState?.call(() {});

    final result = await sl<CreateExam>()(
      CreateExamParams(classId: classId, title: title),
    );

    bool success = false;
    result.fold(
      (failure) {
        showAppToast(
          context,
          message: failure.message,
          destructive: true,
        );
      },
      (exam) {
        if (!mounted) return;
        setState(() {
          _allExams = [
            _ExamListItem(
              exam: exam,
              className: className,
              subject: subject.isEmpty ? null : subject,
              plannedDate: plannedDate,
            ),
            ..._allExams,
          ];
          _quickTitleController.clear();
          _quickSubjectController.clear();
          _quickPlannedDate = DateTime.now();
        });
        success = true;
        showAppToast(
          context,
          message: 'Sınav oluşturuldu',
        );
      },
    );

    if (!mounted) return success;
    setState(() => _isQuickCreating = false);
    onSheetState?.call(() {});
    return success;
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.activeIndex,
    required this.onChanged,
  });

  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Aktif', 'Tamamlandı', 'Taslak'];
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E8F3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = activeIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF3B4FD8)
                        : const Color(0xFF6B7A99),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ExamOverviewCard extends StatelessWidget {
  const _ExamOverviewCard({
    required this.item,
    required this.onTap,
  });

  final _ExamListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = item.exam.status.toUpperCase();
    final isDone =
        status == 'READY' || status == 'COMPLETED' || status == 'DONE';
    final color = isDone ? const Color(0xFF0BBFB0) : const Color(0xFF3B4FD8);
    final date = DateFormat('d MMM', 'tr_TR').format(item.exam.createdAt);
    final plannedFor = item.plannedDate != null
        ? DateFormat('d MMM', 'tr_TR').format(item.plannedDate!)
        : null;
    final statusLabel = _statusLabel(status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE3F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F1729),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(width: 3, height: 86, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.className.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (item.subject != null && item.subject!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF3FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              item.subject!,
                              style: const TextStyle(
                                color: Color(0xFF3B4FD8),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.exam.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F1729),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: Color(0xFF8A96B2)),
                      const SizedBox(width: 6),
                      Text(date,
                          style: const TextStyle(
                              color: Color(0xFF6B7A99), fontSize: 11)),
                      const SizedBox(width: 12),
                      if (plannedFor != null) ...[
                        const Icon(Icons.event_available_outlined,
                            size: 12, color: Color(0xFF8A96B2)),
                        const SizedBox(width: 6),
                        Text(
                          plannedFor,
                          style: const TextStyle(
                            color: Color(0xFF6B7A99),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isDone
                        ? Icons.check_circle_outline_rounded
                        : Icons.pending_actions_rounded,
                    color: color,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Detaylar',
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: color, size: 18),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'READY':
      case 'COMPLETED':
      case 'DONE':
        return 'Tamamlandı';
      case 'PROCESSING':
        return 'İşleniyor';
      case 'FAILED':
        return 'Hata';
      case 'DRAFT':
      case 'PENDING':
      default:
        return 'Taslak';
    }
  }
}

class _ExamEmptyState extends StatelessWidget {
  const _ExamEmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Opacity(
          opacity: 0.3,
          child: Image.network(
            'https://www.figma.com/api/mcp/asset/c75a49d1-fdd2-458e-a8bb-dc9cc2554263',
            width: 170,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 170,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEF8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Color(0xFF9AA5BE),
                size: 36,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Henüz taslak sınav yok',
          style: TextStyle(
            color: Color(0xFF9AA5BE),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Yeni bir sınav hazırlayarak burada taslak\nolarak kaydedebilirsiniz.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFB5BED3), fontSize: 12),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFB91C1C)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Yenile')),
        ],
      ),
    );
  }
}

class _ExamListItem {
  const _ExamListItem({
    required this.exam,
    required this.className,
    this.subject,
    this.plannedDate,
  });

  final ExamEntity exam;
  final String className;
  final String? subject;
  final DateTime? plannedDate;
}
