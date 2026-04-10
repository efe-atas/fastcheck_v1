import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/authenticated_image.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoadingExamOptions = false;
  bool _isUploadingSelectedExam = false;
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

  Future<void> _onCameraPressed() async {
    if (widget.requireExamSelection && _selectedExam == null) {
      showAppToast(
        context,
        message: 'Lütfen önce bir sınav seçin.',
        destructive: true,
      );
      return;
    }

    if (widget.requireExamSelection && _selectedExam != null) {
      await _scanForSelectedExam();
      return;
    }

    context.read<OcrCubit>().scanAndExtract(
          sourceId: _selectedExam == null
              ? null
              : 'exam-${_selectedExam!.exam.examId}',
          examTitle: _selectedExam?.exam.title,
        );
  }

  Future<void> _onGalleryPressed() async {
    if (widget.requireExamSelection && _selectedExam == null) {
      showAppToast(
        context,
        message: 'Lütfen önce bir sınav seçin.',
        destructive: true,
      );
      return;
    }

    final files = await _pickGalleryFiles();
    if (!mounted || files == null || files.isEmpty) {
      return;
    }

    if (widget.requireExamSelection && _selectedExam != null) {
      await _uploadSelectedExamFiles(_selectedExam!, files);
      return;
    }

    await context.read<OcrCubit>().extractFromLocalPaths(
          localPaths: files.map((file) => file.path).toList(),
          sourceId: _selectedExam == null
              ? null
              : 'exam-${_selectedExam!.exam.examId}',
          examTitle: _selectedExam?.exam.title,
        );
  }

  Future<List<File>?> _pickGalleryFiles() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isEmpty) {
        if (mounted) {
          showAppToast(context, message: 'Galeri seçimi iptal edildi.');
        }
        return null;
      }
      return pickedFiles.map((file) => File(file.path)).toList();
    } catch (_) {
      if (mounted) {
        showAppToast(
          context,
          message: 'Galeri açılamadı.',
          destructive: true,
        );
      }
      return null;
    }
  }

  Future<void> _scanForSelectedExam() async {
    final selectedExam = _selectedExam;
    if (selectedExam == null || _isUploadingSelectedExam) {
      return;
    }

    setState(() {
      _isUploadingSelectedExam = true;
    });

    ImageScanResult? scanResult;
    try {
      scanResult = await FlutterDocScanner().getScannedDocumentAsImages(
        page: 4,
        imageFormat: ImageFormat.jpeg,
      );
    } on DocScanException catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingSelectedExam = false;
      });
      showAppToast(
        context,
        message: e.message.isNotEmpty ? e.message : 'Tarama başarısız.',
        destructive: true,
      );
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUploadingSelectedExam = false;
      });
      showAppToast(
        context,
        message: 'Tarama başlatılamadı.',
        destructive: true,
      );
      return;
    }

    if (scanResult == null || scanResult.images.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isUploadingSelectedExam = false;
      });
      showAppToast(context, message: 'Tarama iptal edildi.');
      return;
    }

    await _uploadSelectedExamFiles(
      selectedExam,
      scanResult.images.map(File.new).toList(),
    );
  }

  Future<void> _uploadSelectedExamFiles(
    _ExamOption selectedExam,
    List<File> files,
  ) async {
    if (files.isEmpty) {
      return;
    }

    setState(() {
      _isUploadingSelectedExam = true;
    });

    final result = await sl<UploadExamImages>()(
      UploadExamImagesParams(
        examId: selectedExam.exam.examId,
        images: files,
      ),
    );

    if (!mounted) return;
    setState(() {
      _isUploadingSelectedExam = false;
    });

    result.fold(
      (failure) {
        showAppToast(
          context,
          message: failure.message,
          destructive: true,
        );
      },
      (_) {
        context.read<OcrCubit>().refreshList();
        showAppToast(
          context,
          message: 'Kağıt yüklendi, OCR başlatıldı.',
        );
        context.push(
          '/teacher/exams/${selectedExam.exam.examId}?title=${Uri.encodeComponent(selectedExam.exam.title)}',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedExam = _selectedExam;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isBusy = _isUploadingSelectedExam;
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
            final orderedResults = _orderedResults(state);
            final activeResult = _resolveActiveResult(state);
            final activeStats = _resultStats(activeResult?.result);
            final showLiveProgress = state.isLoading && state.totalCount > 0;
            final processingCount =
                orderedResults.where(_isInFlightResult).length;
            final completedCount =
                orderedResults.where(_isCompletedResult).length;
            final failedCount = orderedResults.where(_isFailedResult).length;
            final visibleProcessingCount =
                showLiveProgress && processingCount == 0 ? 1 : processingCount;
            final activeProgress = showLiveProgress
                ? (state.totalCount == 0
                    ? 0.0
                    : state.processedCount / state.totalCount)
                : (activeResult == null
                    ? 0.0
                    : (_isCompletedResult(activeResult)
                        ? activeStats.accuracy
                        : _statusProgress(activeResult.status)));
            final normalizedProgress =
                activeProgress.isFinite ? activeProgress.clamp(0.0, 1.0) : 0.0;
            final activeTitle = showLiveProgress
                ? (selectedExam?.exam.title ?? 'OCR işlemi hazırlanıyor')
                : activeResult != null
                    ? _resultTitle(activeResult)
                    : 'Aktif OCR işlemi yok';
            final activeSubtitle = showLiveProgress
                ? (selectedExam != null
                    ? '${selectedExam.className} • Taranan sayfalar işleniyor'
                    : 'Taranan sayfalar OCR kuyruğuna alındı')
                : activeResult != null
                    ? _resultSubtitle(activeResult)
                    : 'Yeni bir sınav seçip tarama başlatabilirsiniz';
            final activeStatusLabel = showLiveProgress
                ? 'İşleniyor'
                : activeResult != null
                    ? _statusLabel(activeResult.status)
                    : 'Beklemede';
            final activeStatusColor = showLiveProgress
                ? const Color(0xFF0BBFB0)
                : activeResult != null
                    ? _statusColor(activeResult.status)
                    : const Color(0xFF6B7A99);
            final activeStatusBackground = showLiveProgress
                ? const Color(0xFFDFF5F2)
                : activeResult != null
                    ? _statusBackground(activeResult.status)
                    : const Color(0xFFE9EDF6);
            final activeProgressLabel = showLiveProgress
                ? '${state.processedCount}/${state.totalCount} sayfa işlendi'
                : activeResult == null
                    ? 'Henüz iş kuyruğu oluşmadı'
                    : _activeProgressLabel(activeResult, activeStats);
            final activeSupportText = showLiveProgress
                ? 'Taradığınız sayfalar sırayla OCR servisine gönderiliyor.'
                : activeResult == null
                    ? 'Sınav kağıdı yükleyerek ilk OCR işinizi başlatın.'
                    : _activeSupportText(activeResult, activeStats);

            return RefreshIndicator(
              color: const Color(0xFF3B4FD8),
              onRefresh: () => context.read<OcrCubit>().refreshList(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + 4,
                  16,
                  16 + bottomInset,
                ),
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Toplam İş',
                          value: '${orderedResults.length}',
                          icon: Icons.receipt_long_rounded,
                          accent: const Color(0xFF3B4FD8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Devam Eden',
                          value: '$visibleProcessingCount',
                          icon: Icons.timelapse_rounded,
                          accent: const Color(0xFF0BBFB0),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Tamamlanan',
                          value: '$completedCount',
                          icon: Icons.check_circle_rounded,
                          accent: const Color(0xFF19A56E),
                        ),
                      ),
                    ],
                  ),
                  if (failedCount > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        '$failedCount OCR işlemi hata durumunda. Geçmiş listesinden kontrol edebilirsiniz.',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: _historyCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F3FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Color(0xFF3B4FD8),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Yeni tarama başlat',
                                    style: TextStyle(
                                      color: Color(0xFF0F1729),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Kamera veya galeriden kağıt ekleyin. Tamamlanan kayıtlar otomatik olarak geçmişe düşer.',
                                    style: TextStyle(
                                      color: Color(0xFF6B7A99),
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (widget.requireExamSelection) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap:
                                _isLoadingExamOptions ? null : _openExamPicker,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F7FB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E7F2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.assignment_outlined,
                                    color: Color(0xFF3B4FD8),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedExam == null
                                          ? (_isLoadingExamOptions
                                              ? 'Sınavlar yükleniyor...'
                                              : 'Önce sınav seçin')
                                          : '${selectedExam.exam.title} • ${selectedExam.className}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF3A4864),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.expand_more_rounded,
                                    color: Color(0xFF6B7A99),
                                  ),
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
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
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
                                        isBusy ||
                                        (widget.requireExamSelection &&
                                            selectedExam == null)
                                    ? null
                                    : _onCameraPressed,
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
                                        isBusy ||
                                        (widget.requireExamSelection &&
                                            selectedExam == null)
                                    ? null
                                    : _onGalleryPressed,
                              ),
                            ),
                          ],
                        ),
                        if (kIsWeb)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'Belge tarama sadece iOS/Android uygulamasında desteklenir.',
                              style: TextStyle(
                                color: Color(0xFF9AA5BE),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionHeader(
                    title: 'Aktif İşlem',
                    actionLabel: 'Yenile',
                    onAction: state.isLoading && !showLiveProgress
                        ? null
                        : () => context.read<OcrCubit>().refreshList(),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: _historyCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _ResultPreviewImage(
                                imageUrl: activeResult?.imageUrl,
                                compact: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          activeTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF0F1729),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _StatusBadge(
                                        label: activeStatusLabel,
                                        color: activeStatusColor,
                                        background: activeStatusBackground,
                                        compact: true,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    activeSubtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7A99),
                                      fontSize: 11,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: normalizedProgress,
                                      minHeight: 4,
                                      backgroundColor: const Color(0xFFDCE2EE),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        activeStatusColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    activeProgressLabel,
                                    style: const TextStyle(
                                      color: Color(0xFF3A4864),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeSupportText,
                          style: const TextStyle(
                            color: Color(0xFF6B7A99),
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                        if (showLiveProgress) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _MetricBadge(
                                label: 'Başarılı',
                                value: '${state.successCount}',
                                color: const Color(0xFF0BBFB0),
                                background: const Color(0xFFDFF5F2),
                                compact: true,
                              ),
                              _MetricBadge(
                                label: 'Hatalı',
                                value: '${state.failedCount}',
                                color: const Color(0xFFDE3F4D),
                                background: const Color(0xFFFCE8EA),
                                compact: true,
                              ),
                            ],
                          ),
                        ] else if (activeResult != null &&
                            activeStats.total > 0) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _MetricBadge(
                                label: 'Doğru',
                                value: '${activeStats.correct}',
                                color: const Color(0xFF0BBFB0),
                                background: const Color(0xFFDFF5F2),
                                compact: true,
                              ),
                              _MetricBadge(
                                label: 'Yanlış',
                                value:
                                    '${activeStats.incorrect < 0 ? 0 : activeStats.incorrect}',
                                color: const Color(0xFFDE3F4D),
                                background: const Color(0xFFFCE8EA),
                                compact: true,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _SectionHeader(title: 'İşlem Geçmişi'),
                  const SizedBox(height: 6),
                  _buildHistorySection(state),
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
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: visible.length,
    );
  }

  Widget _buildHistoryCard(OcrResultEntity result) {
    final stats = _resultStats(result.result);
    final accuracyLabel = stats.total > 0
        ? '${stats.correct}/${stats.total} doğru'
        : _statusDescription(result.status);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _historyCardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _ResultPreviewImage(
              imageUrl: result.imageUrl,
              compact: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _resultTitle(result),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F1729),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _StatusBadge(
                      label: _statusLabel(result.status),
                      color: _statusColor(result.status),
                      background: _statusBackground(result.status),
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _resultSubtitle(result),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7A99),
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (stats.total > 0
                            ? stats.accuracy
                            : _statusProgress(result.status))
                        .clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE2E7F3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _statusColor(result.status),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  accuracyLabel,
                  style: const TextStyle(
                    color: Color(0xFF3A4864),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (stats.total > 0) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [
                      _MetricBadge(
                        label: 'Doğru',
                        value: '${stats.correct}',
                        color: const Color(0xFF0BBFB0),
                        background: const Color(0xFFDFF5F2),
                        compact: true,
                      ),
                      _MetricBadge(
                        label: 'Yanlış',
                        value: '${stats.incorrect < 0 ? 0 : stats.incorrect}',
                        color: const Color(0xFFDE3F4D),
                        background: const Color(0xFFFCE8EA),
                        compact: true,
                      ),
                    ],
                  ),
                ],
              ],
            ),
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
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE1E6F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x100F1729),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ],
    );
  }

  List<OcrResultEntity> _orderedResults(OcrState state) {
    final base = state.results ?? const <OcrResultEntity>[];
    if (base.isNotEmpty) {
      final sorted = List<OcrResultEntity>.from(base)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted;
    }
    if (state.lastExtract != null) {
      return [state.lastExtract!];
    }
    return const [];
  }

  OcrResultEntity? _resolveActiveResult(OcrState state) {
    final ordered = _orderedResults(state);
    for (final result in ordered) {
      if (_isInFlightResult(result)) {
        return result;
      }
    }
    if (ordered.isNotEmpty) {
      return ordered.first;
    }
    return state.lastExtract;
  }

  bool _isCompletedResult(OcrResultEntity result) {
    return _isCompletedStatus(result.status);
  }

  bool _isInFlightResult(OcrResultEntity result) {
    return _isInFlightStatus(result.status);
  }

  bool _isFailedResult(OcrResultEntity result) {
    return _isFailedStatus(result.status);
  }

  bool _isCompletedStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
      case 'READY':
      case 'DONE':
        return true;
      default:
        return false;
    }
  }

  bool _isInFlightStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
      case 'PROCESSING':
      case 'IN_PROGRESS':
      case 'QUEUED':
        return true;
      default:
        return false;
    }
  }

  bool _isFailedStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'FAILED':
      case 'ERROR':
        return true;
      default:
        return false;
    }
  }

  String _statusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
      case 'READY':
      case 'DONE':
        return 'Tamamlandı';
      case 'PROCESSING':
      case 'IN_PROGRESS':
        return 'İşleniyor';
      case 'FAILED':
      case 'ERROR':
        return 'Hata';
      case 'PENDING':
      case 'QUEUED':
      default:
        return 'Kuyrukta';
    }
  }

  String _statusDescription(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
      case 'READY':
      case 'DONE':
        return 'İşlem tamamlandı';
      case 'PROCESSING':
      case 'IN_PROGRESS':
        return 'OCR işleniyor';
      case 'FAILED':
      case 'ERROR':
        return 'İşlem hatası oluştu';
      case 'PENDING':
      case 'QUEUED':
      default:
        return 'Sırada bekliyor';
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
      case 'READY':
      case 'DONE':
        return const Color(0xFF19A56E);
      case 'PROCESSING':
      case 'IN_PROGRESS':
        return const Color(0xFF0BBFB0);
      case 'FAILED':
      case 'ERROR':
        return const Color(0xFFDE3F4D);
      case 'PENDING':
      case 'QUEUED':
      default:
        return const Color(0xFF3B4FD8);
    }
  }

  Color _statusBackground(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
      case 'READY':
      case 'DONE':
        return const Color(0xFFE7F7EF);
      case 'PROCESSING':
      case 'IN_PROGRESS':
        return const Color(0xFFDFF5F2);
      case 'FAILED':
      case 'ERROR':
        return const Color(0xFFFCE8EA);
      case 'PENDING':
      case 'QUEUED':
      default:
        return const Color(0xFFE9EEFF);
    }
  }

  double _statusProgress(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
      case 'READY':
      case 'DONE':
        return 1.0;
      case 'PROCESSING':
      case 'IN_PROGRESS':
        return 0.65;
      case 'FAILED':
      case 'ERROR':
        return 1.0;
      case 'PENDING':
      case 'QUEUED':
      default:
        return 0.18;
    }
  }

  String _activeProgressLabel(OcrResultEntity result, _ResultStats stats) {
    if (stats.total > 0) {
      return '${stats.correct}/${stats.total} doğru cevap';
    }
    return _statusDescription(result.status);
  }

  String _activeSupportText(OcrResultEntity result, _ResultStats stats) {
    if (stats.total > 0) {
      return 'Son işlenen kağıdın özet sonucu burada gösteriliyor.';
    }
    if (_isFailedResult(result)) {
      return 'Bu iş başarısız oldu. Aynı sınav için yeni yükleme yaparak tekrar deneyebilirsiniz.';
    }
    if (_isInFlightResult(result)) {
      return 'Bu kayıt halen işleniyor. Sonuç oluştuğunda geçmiş kartı otomatik güncellenecek.';
    }
    return 'Kayıt tamamlandı ancak ayrıntılı sonuç verisi henüz gelmedi.';
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
        final correct = _parseInt(summary['correct'] ??
            summary['correctAnswers'] ??
            summary['score']);
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
    final student = _extractStudentName(_asStringKeyedMap(result.result));
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
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              primary ? const Color(0xFF3B4FD8) : const Color(0xFFE9EEFF),
          foregroundColor: primary ? Colors.white : const Color(0xFF3B4FD8),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ResultPreviewImage extends StatelessWidget {
  const _ResultPreviewImage({
    required this.imageUrl,
    this.compact = false,
  });

  final String? imageUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _placeholder();
    }

    return SizedBox(
      width: compact ? 48 : 56,
      height: compact ? 62 : 72,
      child: AuthenticatedImage(
        url: imageUrl!.trim(),
        width: compact ? 48 : 56,
        height: compact ? 62 : 72,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: compact ? 48 : 56,
      height: compact ? 62 : 72,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xFF8A96B2),
        size: 20,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E6F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F1729),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F1729),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7A99),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.background,
    this.compact = false,
  });

  final String label;
  final Color color;
  final Color background;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F1729),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.label,
    required this.value,
    required this.color,
    this.background = const Color(0xFFE9EEFF),
    this.compact = false,
  });

  final String label;
  final String value;
  final Color color;
  final Color background;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: TextStyle(
            fontSize: compact ? 10 : 11,
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
    final safeCorrect = correct < 0 ? 0 : (correct > total ? total : correct);
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
