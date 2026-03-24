import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/ocr_entities.dart';
import '../../domain/usecases/ocr_usecases.dart';

class OcrState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<OcrResultEntity>? results;
  final OcrResultEntity? lastExtract;

  const OcrState({
    this.isLoading = false,
    this.errorMessage,
    this.results,
    this.lastExtract,
  });

  OcrState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<OcrResultEntity>? results,
    OcrResultEntity? lastExtract,
    bool clearError = false,
  }) {
    return OcrState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      results: results ?? this.results,
      lastExtract: lastExtract ?? this.lastExtract,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, errorMessage, results, lastExtract];
}

class OcrCubit extends Cubit<OcrState> {
  final OcrExtract ocrExtract;
  final OcrListMine ocrListMine;
  final OcrGetMine ocrGetMine;

  OcrCubit({
    required this.ocrExtract,
    required this.ocrListMine,
    required this.ocrGetMine,
  }) : super(const OcrState());

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
      )),
    );
  }

  Future<void> refreshList() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await ocrListMine(const NoParams());
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (list) => emit(state.copyWith(isLoading: false, results: list)),
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
      )),
    );
  }
}
