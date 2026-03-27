import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/di/injection_container.dart';
import '../../../teacher/domain/entities/teacher_entities.dart';
import '../../../teacher/domain/usecases/teacher_usecases.dart';
import '../cubit/ocr_cubit.dart';

/// OCR ekranı yalnızca hızlı sınav kağıdı tarama akışını sunar.
class OcrLabPage extends StatefulWidget {
  final bool requireExamSelection;

  const OcrLabPage({
    super.key,
    this.requireExamSelection = false,
  });

  @override
  State<OcrLabPage> createState() => _OcrLabPageState();
}

class _OcrLabPageState extends State<OcrLabPage> {
  bool _isLoadingExamOptions = false;
  String? _examLoadError;
  List<_ExamOption> _examOptions = const [];
  _ExamOption? _selectedExam;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OcrCubit>().refreshList();
      if (widget.requireExamSelection) {
        _loadExamOptions();
      }
    });
  }

  Future<void> _loadExamOptions() async {
    setState(() {
      _isLoadingExamOptions = true;
      _examLoadError = null;
    });

    final classesResult = await sl<GetClasses>()(const NoParams());
    await classesResult.fold(
      (failure) async {
        if (!mounted) return;
        setState(() {
          _isLoadingExamOptions = false;
          _examLoadError = failure.message;
          _examOptions = const [];
          _selectedExam = null;
        });
      },
      (classes) async {
        final getClassExams = sl<GetClassExams>();
        final List<_ExamOption> options = [];

        for (final classEntity in classes) {
          final examsResult = await getClassExams(classEntity.classId);
          examsResult.fold(
            (_) => null,
            (exams) {
              options.addAll(
                exams.map(
                  (exam) => _ExamOption(
                    exam: exam,
                    className: classEntity.className,
                  ),
                ),
              );
            },
          );
        }

        options.sort(
          (a, b) => b.exam.createdAt.compareTo(a.exam.createdAt),
        );

        if (!mounted) return;
        setState(() {
          _isLoadingExamOptions = false;
          _examOptions = options;
          if (_selectedExam != null) {
            _selectedExam = options.cast<_ExamOption?>().firstWhere(
                  (option) => option?.exam.examId == _selectedExam!.exam.examId,
                  orElse: () => null,
                );
          }
        });
      },
    );
  }

  Future<void> _openExamPicker() async {
    final selected = await showModalBottomSheet<_ExamOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Sınav seç',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    ShadButton.ghost(
                      onPressed: _isLoadingExamOptions ? null : _loadExamOptions,
                      leading: const Icon(Icons.refresh, size: 16),
                      child: const Text('Yenile'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isLoadingExamOptions)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_examLoadError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _examLoadError!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  )
                else if (_examOptions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Seçilebilir sınav bulunamadı. Önce sınav oluşturun.',
                      style: ShadTheme.of(context).textTheme.muted,
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _examOptions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = _examOptions[index];
                        final isSelected = _selectedExam?.exam.examId == option.exam.examId;
                        return ListTile(
                          onTap: () => Navigator.of(context).pop(option),
                          title: Text(
                            option.exam.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(option.className),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.success)
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    setState(() {
      _selectedExam = selected;
    });
  }

  void _onScanPressed() {
    if (widget.requireExamSelection && _selectedExam == null) {
      showAppToast(
        context,
        message: 'Lütfen önce bir sınav seçin.',
        destructive: true,
      );
      return;
    }

    context.read<OcrCubit>().scanAndExtract(
          sourceId: _selectedExam == null ? null : 'exam-${_selectedExam!.exam.examId}',
          examTitle: _selectedExam?.exam.title,
        );
  }

  @override
  Widget build(BuildContext context) {
    final selectedExam = _selectedExam;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: MultiBlocListener(
        listeners: [
          BlocListener<OcrCubit, OcrState>(
            listenWhen: (prev, curr) =>
                curr.errorMessage != prev.errorMessage &&
                curr.errorMessage != null,
            listener: (context, state) {
              showAppToast(
                context,
                message: state.errorMessage!,
                destructive: true,
              );
            },
          ),
          BlocListener<OcrCubit, OcrState>(
            listenWhen: (prev, curr) =>
                curr.lastMessage != null &&
                curr.lastMessage != prev.lastMessage &&
                (!curr.isLoading || curr.errorMessage != null),
            listener: (context, state) {
              final msg = state.lastMessage;
              if (msg == null || msg.isEmpty) return;
              showAppToast(context, message: msg);
            },
          ),
        ],
        child: BlocBuilder<OcrCubit, OcrState>(
          builder: (context, state) {
            return ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + 16,
                16,
                16,
              ),
              children: [
                Text(
                  'OCR Laboratuvarı',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sınav kağıtlarını hızlıca tarayın',
                  style: ShadTheme.of(context).textTheme.muted,
                ),
                const SizedBox(height: 8),
                Text(
                  kIsWeb
                      ? 'Belge tarama yalnızca mobil uygulamada (iOS/Android) kullanılabilir.'
                      : 'Tek dokunuşla tarayın. Çok sayfa varsa sistem hepsini sırayla işler.',
                  style: ShadTheme.of(context).textTheme.muted,
                ),
                if (widget.requireExamSelection) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.assignment_outlined, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Eşleştirilecek sınav',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            ShadButton.ghost(
                              onPressed:
                                  _isLoadingExamOptions ? null : _openExamPicker,
                              leading: const Icon(Icons.search, size: 16),
                              child: const Text('Sınav seç'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (_isLoadingExamOptions)
                          Text(
                            'Sınavlar yükleniyor...',
                            style: ShadTheme.of(context).textTheme.muted,
                          )
                        else if (_examLoadError != null)
                          Text(
                            _examLoadError!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          )
                        else if (selectedExam == null)
                          Text(
                            'Henüz seçim yapılmadı',
                            style: ShadTheme.of(context).textTheme.muted,
                          )
                        else
                          Text(
                            '${selectedExam.exam.title} • ${selectedExam.className}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ShadButton(
                  onPressed: kIsWeb ||
                          state.isLoading ||
                          (widget.requireExamSelection && selectedExam == null)
                      ? null
                      : _onScanPressed,
                  child: Text(
                      state.isLoading ? 'Taranıyor...' : 'Sınav kağıdını tara'),
                ),
                if (widget.requireExamSelection && selectedExam == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Tarama başlatmak için önce sınav seçin.',
                      style: ShadTheme.of(context).textTheme.muted,
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.lastMessage ?? 'Tarama bekleniyor',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'İlerleme: ${state.processedCount}/${state.totalCount}',
                        style: ShadTheme.of(context).textTheme.muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Sonuçlarım',
                      style: ShadTheme.of(context).textTheme.h4,
                    ),
                    const Spacer(),
                    ShadButton.ghost(
                      leading: const Icon(Icons.refresh, size: 18),
                      onPressed: state.isLoading
                          ? null
                          : () => context.read<OcrCubit>().refreshList(),
                      child: const Text('Yenile'),
                    ),
                  ],
                ),
                if (state.results == null || state.results!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Kayıt yok',
                      style: ShadTheme.of(context).textTheme.muted,
                    ),
                  )
                else
                  ...state.results!.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.imageUrl ?? e.jobId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ShadTheme.of(context).textTheme.muted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${e.createdAt.day.toString().padLeft(2, '0')}.${e.createdAt.month.toString().padLeft(2, '0')}',
                              style: ShadTheme.of(context).textTheme.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExamOption {
  final ExamEntity exam;
  final String className;

  const _ExamOption({
    required this.exam,
    required this.className,
  });
}
