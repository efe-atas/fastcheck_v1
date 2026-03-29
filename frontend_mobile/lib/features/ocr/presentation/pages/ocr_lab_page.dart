import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../teacher/domain/entities/teacher_entities.dart';
import '../../../teacher/domain/usecases/teacher_usecases.dart';
import '../cubit/ocr_cubit.dart';

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
        final options = <_ExamOption>[];

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

        options.sort((a, b) => b.exam.createdAt.compareTo(a.exam.createdAt));

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
      backgroundColor: Colors.white,
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
                        color: Color(0xFF0F1729),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed:
                          _isLoadingExamOptions ? null : _loadExamOptions,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Yenile'),
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
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _examLoadError!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  )
                else if (_examOptions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Seçilebilir sınav bulunamadı. Önce sınav oluşturun.',
                      style: TextStyle(color: Color(0xFF6B7A99)),
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
                        final isSelected =
                            _selectedExam?.exam.examId == option.exam.examId;
                        return ListTile(
                          onTap: () => Navigator.of(context).pop(option),
                          title: Text(
                            option.exam.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(option.className),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.success)
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
          sourceId: _selectedExam == null
              ? null
              : 'exam-${_selectedExam!.exam.examId}',
          examTitle: _selectedExam?.exam.title,
        );
  }

  @override
  Widget build(BuildContext context) {
    final selectedExam = _selectedExam;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
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
            final previewRows = _buildPreviewRows(state);
            final progress = state.totalCount > 0
                ? state.processedCount / state.totalCount
                : 0.0;

            return RefreshIndicator(
              color: const Color(0xFF3B4FD8),
              onRefresh: () => context.read<OcrCubit>().refreshList(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + 8,
                  16,
                  56 + bottomInset,
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OCR İşlem Merkezi',
                              style: TextStyle(
                                color: Color(0xFF0F1729),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Yapay zeka ile sınav\ndeğerlendirme',
                              style: TextStyle(
                                color: Color(0xFF6B7A99),
                                fontSize: 14,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9EEFF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFDCE4FA)),
                        ),
                        child: Text(
                          '●  Devam Eden: ${state.isLoading ? 1 : 0}',
                          style: const TextStyle(
                            color: Color(0xFF3B4FD8),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
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
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8ECF8),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Icon(Icons.camera_alt_outlined,
                              color: Color(0xFF3B4FD8), size: 28),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Sınav kağıtlarını yükle',
                          style: TextStyle(
                            color: Color(0xFF0F1729),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sınav kağıdının fotoğrafını çekin veya galeriden\nbir dosya seçin',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Color(0xFF6B7A99), fontSize: 14),
                        ),
                        if (widget.requireExamSelection) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap:
                                _isLoadingExamOptions ? null : _openExamPicker,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F4FA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.assignment_outlined,
                                      color: Color(0xFF3B4FD8), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedExam == null
                                          ? (_isLoadingExamOptions
                                              ? 'Sınavlar yükleniyor...'
                                              : 'Sınav seç')
                                          : '${selectedExam.exam.title} • ${selectedExam.className}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Color(0xFF3A4864),
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const Icon(Icons.expand_more_rounded,
                                      color: Color(0xFF6B7A99)),
                                ],
                              ),
                            ),
                          ),
                          if (_examLoadError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _examLoadError!,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 12),
                              ),
                            ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.camera_alt_rounded,
                                label: 'Kamera',
                                primary: true,
                                onTap: kIsWeb ||
                                        state.isLoading ||
                                        (widget.requireExamSelection &&
                                            selectedExam == null)
                                    ? null
                                    : _onScanPressed,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.photo_library_outlined,
                                label: 'Galeri',
                                primary: false,
                                onTap: kIsWeb ||
                                        state.isLoading ||
                                        (widget.requireExamSelection &&
                                            selectedExam == null)
                                    ? null
                                    : _onScanPressed,
                              ),
                            ),
                          ],
                        ),
                        if (kIsWeb)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Belge tarama sadece iOS/Android uygulamasında desteklenir.',
                              style: TextStyle(
                                  color: Color(0xFF9AA5BE), fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text(
                        'Aktif İşlemler',
                        style: TextStyle(
                          color: Color(0xFF0F1729),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: state.isLoading
                            ? null
                            : () => context.read<OcrCubit>().refreshList(),
                        child: const Text('Tümünü Durdur'),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
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
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                (state.results != null &&
                                            state.results!.isNotEmpty
                                        ? state.results!.first.imageUrl
                                        : null) ??
                                    'https://www.figma.com/api/mcp/asset/f2d7b0e8-69e2-477c-bd80-836b5a7f0120',
                                width: 64,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 64,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9EEF8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Color(0xFF8A96B2),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ahmet Yılmaz',
                                    style: TextStyle(
                                      color: Color(0xFF0F1729),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    selectedExam == null
                                        ? 'Matematik 1. Yazılı - 9-A'
                                        : '${selectedExam.exam.title} - ${selectedExam.className}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Color(0xFF6B7A99), fontSize: 14),
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      backgroundColor: const Color(0xFFDCE2EE),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF0BBFB0)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(progress * 100).toStringAsFixed(1)}% güven',
                              style: const TextStyle(
                                color: Color(0xFF0BBFB0),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            _StepLabel(label: 'Yüklendi', active: true),
                            _StepLabel(label: 'İşleniyor', active: true),
                            _StepLabel(label: 'Metin', active: false),
                            _StepLabel(label: 'Değer', active: false),
                            _StepLabel(label: 'Tamam', active: false),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: state.results?.isNotEmpty == true
                                ? () {}
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE4E9F4),
                              foregroundColor: const Color(0xFF6B7A99),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Sonucu Gör'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sonuç Önizleme',
                    style: TextStyle(
                      color: Color(0xFF0F1729),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDDE3F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x100F1729),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0F3FA),
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(14)),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'SORU',
                                  style: TextStyle(
                                    color: Color(0xFF6D7A97),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'TESPİT',
                                  style: TextStyle(
                                    color: Color(0xFF6D7A97),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'DOĞRU',
                                  style: TextStyle(
                                    color: Color(0xFF6D7A97),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'DURUM',
                                  style: TextStyle(
                                    color: Color(0xFF6D7A97),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...previewRows.map(
                          (row) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(
                                  top: BorderSide(color: Color(0xFFE2E7F3))),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${row.index}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F1729)),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE9EEFF),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      row.detected,
                                      style: const TextStyle(
                                        color: Color(0xFF3B4FD8),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    row.expected,
                                    style: const TextStyle(
                                        color: Color(0xFF3A4864)),
                                  ),
                                ),
                                Expanded(
                                  child: Icon(
                                    row.correct
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: row.correct
                                        ? const Color(0xFF19A56E)
                                        : const Color(0xFFDE3F4D),
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 128,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.transparent,
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox.expand(
                              child: Image.network(
                                'https://www.figma.com/api/mcp/asset/f4150d04-f7cc-4f66-a477-9a2c375a80dd',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF3B4FD8),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xFF3046D8)
                                  .withValues(alpha: 0.78),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Toplu Yükleme',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          height: 1.05,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Tüm sınıfın kağıtlarını tek seferde\ntarayın ve işleyin',
                                        style: TextStyle(
                                            color: Color(0xBFFFFFFF),
                                            fontSize: 14,
                                            height: 1.12),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.17),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.35)),
                                  ),
                                  child: const Icon(Icons.upload_rounded,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<_PreviewRow> _buildPreviewRows(OcrState state) {
    final dynamic result = state.lastExtract?.result;
    if (result is List && result.isNotEmpty) {
      return result.take(4).toList().asMap().entries.map((entry) {
        final idx = entry.key + 1;
        final row = entry.value;
        if (row is Map<String, dynamic>) {
          final detected = (row['detected'] ?? row['answer'] ?? 'A').toString();
          final expected =
              (row['expected'] ?? row['correct'] ?? detected).toString();
          final correct = detected.toUpperCase() == expected.toUpperCase();
          return _PreviewRow(
              index: idx,
              detected: detected,
              expected: expected,
              correct: correct);
        }
        return _PreviewRow(
            index: idx, detected: 'A', expected: 'A', correct: true);
      }).toList();
    }
    if (result is Map<String, dynamic>) {
      final answers = result['answers'];
      if (answers is List && answers.isNotEmpty) {
        return answers.take(4).toList().asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final row = entry.value;
          if (row is Map<String, dynamic>) {
            final detected =
                (row['detected'] ?? row['student'] ?? 'A').toString();
            final expected =
                (row['expected'] ?? row['correct'] ?? detected).toString();
            final correct = detected.toUpperCase() == expected.toUpperCase();
            return _PreviewRow(
                index: idx,
                detected: detected,
                expected: expected,
                correct: correct);
          }
          return _PreviewRow(
              index: idx, detected: 'A', expected: 'A', correct: true);
        }).toList();
      }
    }
    return const [
      _PreviewRow(index: 1, detected: 'A', expected: 'A', correct: true),
      _PreviewRow(index: 2, detected: 'C', expected: 'B', correct: false),
      _PreviewRow(index: 3, detected: 'D', expected: 'D', correct: true),
      _PreviewRow(index: 4, detected: 'B', expected: 'B', correct: true),
    ];
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              primary ? const Color(0xFF3B4FD8) : const Color(0xFFE9EEFF),
          foregroundColor: primary ? Colors.white : const Color(0xFF3B4FD8),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.circle,
          size: 8,
          color: active ? const Color(0xFF0BBFB0) : const Color(0xFFD7DDEA),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF0BBFB0) : const Color(0xFF94A2BE),
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PreviewRow {
  const _PreviewRow({
    required this.index,
    required this.detected,
    required this.expected,
    required this.correct,
  });

  final int index;
  final String detected;
  final String expected;
  final bool correct;
}

class _ExamOption {
  final ExamEntity exam;
  final String className;

  const _ExamOption({
    required this.exam,
    required this.className,
  });
}
