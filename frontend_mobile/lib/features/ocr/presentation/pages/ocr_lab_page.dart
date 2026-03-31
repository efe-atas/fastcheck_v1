import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../teacher/domain/entities/teacher_entities.dart';
import '../../../teacher/domain/usecases/teacher_usecases.dart';
import '../../domain/entities/ocr_entities.dart';
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
  final DateFormat _dateFormatter = DateFormat('d MMM y • HH:mm', 'tr_TR');
  final JsonEncoder _jsonEncoder = const JsonEncoder.withIndent('  ');

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
            final highlightedResult = _resolveReferenceResult(state);
            final resultStats = highlightedResult != null
                ? _resultStats(highlightedResult.result)
                : const _ResultStats();
            final bool showProcessingProgress =
                state.isLoading && state.totalCount > 0;
            final double progress = showProcessingProgress
                ? (state.totalCount == 0
                    ? 0
                    : state.processedCount / state.totalCount)
                : resultStats.accuracy;
            final double normalizedProgress =
                progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;
            final String trailingLabel = showProcessingProgress
                ? '${(normalizedProgress * 100).toStringAsFixed(0)}% tamamlandı'
                : resultStats.total > 0
                    ? '${(normalizedProgress * 100).toStringAsFixed(0)}% doğruluk'
                    : 'Sonuç bekleniyor';
            final String progressLabel = showProcessingProgress
                ? '${state.processedCount}/${state.totalCount} sayfa işlendi'
                : resultStats.total > 0
                    ? '${resultStats.correct}/${resultStats.total} doğru cevap'
                    : 'Henüz sonuç yok';
            final String titleText = highlightedResult != null
                ? _resultTitle(highlightedResult)
                : (selectedExam?.exam.title ?? 'Yeni OCR işlemi başlat');
            final String subtitleText = highlightedResult != null
                ? _resultSubtitle(highlightedResult)
                : (selectedExam != null
                    ? selectedExam.className
                    : 'Sınav kağıdı yükleyerek başlayın');
            final bool hasAnyResult = highlightedResult?.result != null;
            final bool hasValues = resultStats.total > 0;
            final bool isCompleted = hasValues && !state.isLoading;
            final bool hasUploaded =
                state.processedCount > 0 || hasAnyResult;
            final int successValue = showProcessingProgress
                ? state.successCount
                : resultStats.correct;
            final int failedValue = showProcessingProgress
                ? state.failedCount
                : (resultStats.total - resultStats.correct);
            final bool showStatusBadges =
                showProcessingProgress || resultStats.total > 0;

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
                        child: const Text('Yenile'),
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
                                highlightedResult?.imageUrl ??
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
                                  Text(
                                    titleText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF0F1729),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    subtitleText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7A99),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: normalizedProgress,
                                      minHeight: 6,
                                      backgroundColor: const Color(0xFFDCE2EE),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0BBFB0),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    progressLabel,
                                    style: const TextStyle(
                                      color: Color(0xFF3A4864),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (showStatusBadges) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        _MetricBadge(
                                          label: 'Başarılı',
                                          value: '$successValue',
                                          color: const Color(0xFF0BBFB0),
                                          background:
                                              const Color(0xFFDFF5F2),
                                        ),
                                        _MetricBadge(
                                          label: 'Hatalı',
                                          value: '$failedValue',
                                          color: const Color(0xFFDE3F4D),
                                          background:
                                              const Color(0xFFFCE8EA),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              trailingLabel,
                              style: TextStyle(
                                color: showProcessingProgress
                                    ? const Color(0xFF0BBFB0)
                                    : const Color(0xFF3B4FD8),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StepLabel(
                              label: 'Yüklendi',
                              active: hasUploaded,
                            ),
                            _StepLabel(
                              label: 'İşleniyor',
                              active: showProcessingProgress,
                            ),
                            _StepLabel(
                              label: 'Metin',
                              active: hasAnyResult,
                            ),
                            _StepLabel(
                              label: 'Değer',
                              active: hasValues,
                            ),
                            _StepLabel(
                              label: 'Tamam',
                              active: isCompleted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: highlightedResult != null
                                ? () => _showResultDetails(highlightedResult)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE4E9F4),
                              foregroundColor: const Color(0xFF6B7A99),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
                        if (previewRows.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 20),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Önizlenecek veri yok. Yeni bir tarama başlatın.',
                                style: TextStyle(
                                  color: Color(0xFF6B7A99),
                                ),
                              ),
                            ),
                          )
                        else
                          ...previewRows.map(
                            (row) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Color(0xFFE2E7F3)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${row.index}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F1729),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE9EEFF),
                                        borderRadius:
                                            BorderRadius.circular(16),
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
                  const Text(
                    'İşlem Geçmişi',
                    style: TextStyle(
                      color: Color(0xFF0F1729),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildHistorySection(state),
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

  Widget _buildHistorySection(OcrState state) {
    final results = state.results;
    if (results == null) {
      if (state.isLoading) {
        return Container(
          height: 120,
          alignment: Alignment.center,
          decoration: _historyCardDecoration(),
          child: const CircularProgressIndicator(),
        );
      }
      return _historyEmptyCard(
        'Sonuçlar henüz yüklenemedi.',
        action: TextButton(
          onPressed: () => context.read<OcrCubit>().refreshList(),
          child: const Text('Yeniden Dene'),
        ),
      );
    }
    if (results.isEmpty) {
      return _historyEmptyCard(
        'Henüz tamamlanan OCR işlemi yok.',
      );
    }
    final visible = results.take(10).toList();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => _buildHistoryCard(visible[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: visible.length,
    );
  }

  Widget _buildHistoryCard(OcrResultEntity result) {
    final stats = _resultStats(result.result);
    final accuracyLabel = stats.total > 0
        ? '${stats.correct}/${stats.total} doğru'
        : 'Veri bekleniyor';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _historyCardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              result.imageUrl ??
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
                Text(
                  _resultTitle(result),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F1729),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _resultSubtitle(result),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7A99),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.accuracy.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E7F3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF3B4FD8),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  accuracyLabel,
                  style: const TextStyle(
                    color: Color(0xFF3A4864),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetricBadge(
                      label: 'Doğru',
                      value: '${stats.correct}',
                      color: const Color(0xFF0BBFB0),
                      background: const Color(0xFFDFF5F2),
                    ),
                    _MetricBadge(
                      label: 'Yanlış',
                      value: '${stats.incorrect < 0 ? 0 : stats.incorrect}',
                      color: const Color(0xFFDE3F4D),
                      background: const Color(0xFFFCE8EA),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showResultDetails(result),
            icon: const Icon(Icons.open_in_new, size: 20),
            color: const Color(0xFF3B4FD8),
            tooltip: 'Sonucu Gör',
          ),
        ],
      ),
    );
  }

  Widget _historyEmptyCard(String message, {Widget? action}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _historyCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF6B7A99),
              fontSize: 14,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 8),
            action,
          ],
        ],
      ),
    );
  }

  BoxDecoration _historyCardDecoration() {
    return BoxDecoration(
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
    );
  }

  OcrResultEntity? _resolveReferenceResult(OcrState state) {
    if (state.lastExtract != null) {
      return state.lastExtract;
    }
    final list = state.results;
    if (list != null && list.isNotEmpty) {
      return list.first;
    }
    return null;
  }

  List<_PreviewRow> _buildPreviewRows(OcrState state) {
    final reference = _resolveReferenceResult(state);
    final answers = _extractAnswerList(reference?.result);
    if (answers == null || answers.isEmpty) {
      return const [];
    }
    final rows = <_PreviewRow>[];
    for (var i = 0; i < answers.length && i < 4; i++) {
      final row = answers[i];
      final mapped = _asStringKeyedMap(row);
      if (mapped == null) {
        rows.add(
          _PreviewRow(
            index: i + 1,
            detected: row.toString(),
            expected: row.toString(),
            correct: true,
          ),
        );
        continue;
      }
      final detected =
          _stringValue(mapped, const ['detected', 'answer', 'student']) ?? '—';
      final expected =
          _stringValue(mapped, const ['expected', 'correct']) ?? '—';
      final correct = expected == '—'
          ? true
          : detected.trim().toUpperCase() == expected.trim().toUpperCase();
      rows.add(
        _PreviewRow(
          index: i + 1,
          detected: detected,
          expected: expected,
          correct: correct,
        ),
      );
    }
    return rows;
  }

  List<dynamic>? _extractAnswerList(dynamic data) {
    if (data is List) return data;
    final map = _asStringKeyedMap(data);
    if (map == null) return null;
    for (final key in ['answers', 'items', 'questions', 'results', 'values']) {
      final value = map[key];
      if (value is List) return value;
    }
    return null;
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, dynamic v) => MapEntry(key.toString(), v),
      );
    }
    return null;
  }

  String? _stringValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final str = value.toString().trim();
      if (str.isEmpty) continue;
      return str;
    }
    return null;
  }

  _ResultStats _resultStats(dynamic data) {
    final map = _asStringKeyedMap(data);
    if (map != null) {
      final summary = _asStringKeyedMap(map['summary']);
      if (summary != null) {
        final total = _parseInt(summary['totalQuestions'] ??
            summary['total'] ??
            summary['questionCount']);
        final correct = _parseInt(
            summary['correct'] ?? summary['correctAnswers'] ?? summary['score']);
        if (total != null && total > 0) {
          final safeCorrect = correct ?? 0;
          final bounded =
              safeCorrect < 0 ? 0 : (safeCorrect > total ? total : safeCorrect);
          return _ResultStats(total: total, correct: bounded);
        }
      }
    }
    final answers = _extractAnswerList(data);
    if (answers == null || answers.isEmpty) {
      return const _ResultStats();
    }
    var correct = 0;
    for (final answer in answers) {
      final mapped = _asStringKeyedMap(answer);
      if (mapped == null) continue;
      final detected =
          _stringValue(mapped, const ['detected', 'answer', 'student']);
      final expected =
          _stringValue(mapped, const ['expected', 'correct', 'key']);
      if (detected == null || expected == null) continue;
      if (detected.trim().toUpperCase() == expected.trim().toUpperCase()) {
        correct++;
      }
    }
    return _ResultStats(total: answers.length, correct: correct);
  }

  String _resultTitle(OcrResultEntity? result) {
    if (result == null) return 'Sonuç bekleniyor';
    final student =
        _extractStudentName(_asStringKeyedMap(result.result));
    if (student != null) return student;
    final source = _sourceLabel(result.sourceId);
    if (source != null) return source;
    return 'İş ${_shortenId(result.jobId)}';
  }

  String _resultSubtitle(OcrResultEntity? result) {
    if (result == null) return 'Henüz sonuç yok';
    final parts = <String>[];
    final source = _sourceLabel(result.sourceId);
    if (source != null) {
      parts.add(source);
    }
    parts.add(_formatDate(result.createdAt));
    return parts.join(' • ');
  }

  String? _sourceLabel(String? sourceId) {
    if (sourceId == null || sourceId.isEmpty) return null;
    if (sourceId.startsWith('exam-')) {
      return 'Sınav #${sourceId.substring(5)}';
    }
    if (sourceId.startsWith('class-')) {
      return 'Sınıf #${sourceId.substring(6)}';
    }
    if (sourceId.startsWith('student-')) {
      return 'Öğrenci #${sourceId.substring(8)}';
    }
    return sourceId;
  }

  String? _extractStudentName(Map<String, dynamic>? data) {
    if (data == null) return null;
    for (final key in ['studentName', 'student', 'name', 'owner']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    final metadata = _asStringKeyedMap(data['metadata']);
    if (metadata != null) {
      for (final key in ['studentName', 'student', 'name']) {
        final value = metadata[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return _dateFormatter.format(date.toLocal());
  }

  Future<void> _showResultDetails(OcrResultEntity entity) async {
    if (!mounted) return;
    final stats = _resultStats(entity.result);
    final pretty = _prettifyResult(entity.result);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        final bottom = MediaQuery.paddingOf(context).bottom;
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1E6F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _resultTitle(entity),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F1729),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _resultSubtitle(entity),
                  style: const TextStyle(
                    color: Color(0xFF6B7A99),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricBadge(
                      label: 'İş ID',
                      value: _shortenId(entity.jobId),
                      color: const Color(0xFF3B4FD8),
                    ),
                    if (entity.requestId.isNotEmpty)
                      _MetricBadge(
                        label: 'İstek',
                        value: _shortenId(entity.requestId),
                        color: const Color(0xFF3B4FD8),
                      ),
                    _MetricBadge(
                      label: 'Oluşturma',
                      value: _formatDate(entity.createdAt),
                      color: const Color(0xFF6B7A99),
                      background: const Color(0xFFE9EDF8),
                    ),
                    if (stats.total > 0)
                      _MetricBadge(
                        label: 'Doğruluk',
                        value:
                            '${(stats.accuracy * 100).toStringAsFixed(0)}%',
                        color: const Color(0xFF0BBFB0),
                        background: const Color(0xFFDFF5F2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E6F2)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        pretty,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.25,
                          color: Color(0xFF0F1729),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _prettifyResult(dynamic result) {
    if (result == null) return '—';
    try {
      return _jsonEncoder.convert(result);
    } catch (_) {
      return result.toString();
    }
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.label,
    required this.value,
    required this.color,
    this.background = const Color(0xFFE9EEFF),
  });

  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultStats {
  final int total;
  final int correct;

  const _ResultStats({this.total = 0, this.correct = 0});

  int get incorrect => total - correct;

  double get accuracy {
    if (total <= 0) return 0;
    final safeCorrect = correct < 0
        ? 0
        : (correct > total ? total : correct);
    return safeCorrect / total;
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

String _shortenId(String value) {
  if (value.isEmpty) return '---';
  return value.length <= 8 ? value : value.substring(0, 8);
}
