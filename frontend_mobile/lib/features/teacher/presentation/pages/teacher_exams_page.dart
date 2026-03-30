import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/app_inline_cta.dart';
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

  @override
  void initState() {
    super.initState();
    _loadExams();
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
        final getClassExams = sl<GetClassExams>();
        final list = <_ExamListItem>[];
        for (final classEntity in classes) {
          final examsResult = await getClassExams(classEntity.classId);
          examsResult.fold(
            (_) => null,
            (exams) {
              list.addAll(
                exams.map((exam) => _ExamListItem(
                    exam: exam, className: classEntity.className)),
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
              onTap: () => context.go('/teacher'),
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
    final count = (item.exam.examId % 30) + 2;
    final total = count + 10;
    final date = DateFormat('d MMM', 'tr_TR').format(item.exam.createdAt);

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
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9EDF6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${item.exam.classId}-${String.fromCharCode(64 + ((item.exam.examId % 4) + 1))}',
                          style: const TextStyle(
                              color: Color(0xFF8A96B2),
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
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
                      const Icon(Icons.groups_rounded,
                          size: 14, color: Color(0xFF8A96B2)),
                      const SizedBox(width: 4),
                      Text('${total - 2} öğrenci',
                          style: const TextStyle(
                              color: Color(0xFF6B7A99), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: total == 0 ? 0 : count / total,
                        strokeWidth: 4,
                        backgroundColor: const Color(0xFFDDE3F0),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                      Center(
                        child: Text(
                          '$count/$total',
                          style: const TextStyle(
                            color: Color(0xFF3B4FD8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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
  });

  final ExamEntity exam;
  final String className;
}
