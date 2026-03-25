import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/ocr_entities.dart';
import '../../domain/usecases/ocr_usecases.dart';

class OcrState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<OcrResultEntity>? results;
  final OcrResultEntity? lastExtract;
  final int processedCount;
  final int totalCount;
  final int successCount;
  final int failedCount;
  final String? lastMessage;

  const OcrState({
    this.isLoading = false,
    this.errorMessage,
    this.results,
    this.lastExtract,
    this.processedCount = 0,
    this.totalCount = 0,
    this.successCount = 0,
    this.failedCount = 0,
    this.lastMessage,
  });

  OcrState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<OcrResultEntity>? results,
    OcrResultEntity? lastExtract,
    int? processedCount,
    int? totalCount,
    int? successCount,
    int? failedCount,
    String? lastMessage,
    bool clearError = false,
    bool clearLastMessage = false,
  }) {
    return OcrState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      results: results ?? this.results,
      lastExtract: lastExtract ?? this.lastExtract,
      processedCount: processedCount ?? this.processedCount,
      totalCount: totalCount ?? this.totalCount,
      successCount: successCount ?? this.successCount,
      failedCount: failedCount ?? this.failedCount,
      lastMessage: clearLastMessage ? null : (lastMessage ?? this.lastMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        results,
        lastExtract,
        processedCount,
        totalCount,
        successCount,
        failedCount,
        lastMessage,
      ];
}

class OcrCubit extends Cubit<OcrState> {
  final OcrUploadImage ocrUploadImage;
  final OcrExtract ocrExtract;
  final OcrListMine ocrListMine;
  final OcrGetMine ocrGetMine;

  OcrCubit({
    required this.ocrUploadImage,
    required this.ocrExtract,
    required this.ocrListMine,
    required this.ocrGetMine,
  }) : super(const OcrState());

  String _docScanErrorMessage(DocScanException e) {
    switch (e.code) {
      case DocScanException.codeNoActivity:
        return 'Tarama için uygulama ön planda olmalı.';
      case DocScanException.codeScanInProgress:
        return 'Zaten bir tarama sürüyor.';
      case DocScanException.codeScanFailed:
        return 'Belge taranamadı. Google Play Hizmetleri yüklü mü kontrol edin.';
      case DocScanException.codePdfCreationError:
        return 'Tarama çıktısı oluşturulamadı.';
      case DocScanException.codeCancelled:
        return 'Tarama iptal edildi.';
      case DocScanException.codeUnsupported:
        return 'Bu özellik bu cihazda desteklenmiyor.';
      case 'PERMISSION_DENIED':
        return 'Kamera izni gerekli. Ayarlardan izin verin.';
      default:
        return e.message.isNotEmpty
            ? e.message
            : 'Tarama başarısız (${e.code}).';
    }
  }

  Future<List<OcrResultEntity>?> _refreshResults() async {
    final result = await ocrListMine(const NoParams());
    return result.fold((_) => null, (list) => list);
  }

  /// Cihaz belge tarayıcısını açar ve sayfaları sırayla upload + extract yapar.
  Future<void> scanAndExtract({
    String? sourceId,
    String? languageHint,
    int maxPages = 4,
  }) async {
    if (kIsWeb) {
      emit(state.copyWith(
        errorMessage:
            'Belge tarama yalnızca iOS ve Android uygulamasında desteklenir.',
      ));
      return;
    }

    emit(state.copyWith(
      clearError: true,
      clearLastMessage: true,
      processedCount: 0,
      totalCount: 0,
      successCount: 0,
      failedCount: 0,
    ));

    ImageScanResult? scanResult;
    try {
      scanResult = await FlutterDocScanner().getScannedDocumentAsImages(
        page: maxPages,
        imageFormat: ImageFormat.jpeg,
      );
    } on DocScanException catch (e) {
      emit(state.copyWith(
        errorMessage: _docScanErrorMessage(e),
        lastMessage: 'Tarama başlatılamadı.',
      ));
      return;
    }

    if (scanResult == null || scanResult.images.isEmpty) {
      emit(state.copyWith(lastMessage: 'Tarama iptal edildi.'));
      return;
    }

    final images = scanResult.images;
    final total = images.length;
    var processed = 0;
    var success = 0;
    var failed = 0;
    OcrResultEntity? latestExtract;
    var latestError = state.errorMessage;

    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      totalCount: total,
      processedCount: 0,
      successCount: 0,
      failedCount: 0,
      lastMessage: '0/$total sayfa hazırlanıyor...',
    ));

    for (var i = 0; i < total; i++) {
      final pageNo = i + 1;
      final uploadResult = await ocrUploadImage(
        OcrUploadImageParams(localPath: images[i]),
      );

      await uploadResult.fold<Future<void>>(
        (failure) async {
          processed++;
          failed++;
          latestError = 'Sayfa $pageNo yükleme hatası: ${failure.message}';
          emit(state.copyWith(
            processedCount: processed,
            successCount: success,
            failedCount: failed,
            errorMessage: latestError,
            lastMessage: '$processed/$total tamamlandı',
          ));
        },
        (imageUrl) async {
          final extractResult = await ocrExtract(
            OcrExtractParams(
              imageUrl: imageUrl,
              sourceId: sourceId,
              languageHint: languageHint,
            ),
          );
          extractResult.fold(
            (failure) {
              processed++;
              failed++;
              latestError = 'Sayfa $pageNo OCR hatası: ${failure.message}';
              emit(state.copyWith(
                processedCount: processed,
                successCount: success,
                failedCount: failed,
                errorMessage: latestError,
                lastMessage: '$processed/$total tamamlandı',
              ));
            },
            (entity) {
              processed++;
              success++;
              latestExtract = entity;
              emit(state.copyWith(
                clearError: true,
                processedCount: processed,
                successCount: success,
                failedCount: failed,
                lastExtract: entity,
                lastMessage: '$processed/$total tamamlandı',
              ));
            },
          );
        },
      );
    }

    final refreshed = await _refreshResults();
    final summary =
        '$total sayfa işlendi, $success başarılı, $failed başarısız';
    emit(state.copyWith(
      isLoading: false,
      results: refreshed ?? state.results,
      lastExtract: latestExtract ?? state.lastExtract,
      successCount: success,
      failedCount: failed,
      processedCount: processed,
      totalCount: total,
      errorMessage: failed > 0 ? latestError : null,
      clearError: failed == 0,
      lastMessage: summary,
    ));
  }

  Future<void> extract({
    required String imageUrl,
    String? sourceId,
    String? languageHint,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await ocrExtract(
      OcrExtractParams(
        imageUrl: imageUrl.trim(),
        sourceId: sourceId,
        languageHint: languageHint,
      ),
    );
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (entity) => emit(state.copyWith(
        isLoading: false,
        lastExtract: entity,
        clearError: true,
      )),
    );
  }

  Future<void> refreshList() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await ocrListMine(const NoParams());
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (list) => emit(state.copyWith(
        isLoading: false,
        results: list,
        clearError: true,
      )),
    );
  }

  Future<void> loadByJobId(String jobId) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await ocrGetMine(jobId.trim());
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (entity) => emit(state.copyWith(
        isLoading: false,
        lastExtract: entity,
        clearError: true,
      )),
    );
  }
}
