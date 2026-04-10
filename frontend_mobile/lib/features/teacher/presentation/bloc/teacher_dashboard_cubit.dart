import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../ocr/domain/entities/ocr_entities.dart';
import '../../../ocr/domain/usecases/ocr_usecases.dart';
import '../../domain/entities/teacher_entities.dart';
import '../../domain/usecases/teacher_usecases.dart';

abstract class TeacherDashboardState extends Equatable {
  const TeacherDashboardState();

  @override
  List<Object?> get props => [];
}

class TeacherDashboardInitial extends TeacherDashboardState {
  const TeacherDashboardInitial();
}

class TeacherDashboardLoading extends TeacherDashboardState {
  const TeacherDashboardLoading();
}

class TeacherDashboardLoaded extends TeacherDashboardState {
  final TeacherDashboardSummaryEntity summary;
  final List<OcrResultEntity> recentOcrResults;

  const TeacherDashboardLoaded(
    this.summary, {
    this.recentOcrResults = const [],
  });

  @override
  List<Object?> get props => [summary, recentOcrResults];
}

class TeacherDashboardError extends TeacherDashboardState {
  final String message;

  const TeacherDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

class TeacherDashboardCubit extends Cubit<TeacherDashboardState> {
  final GetTeacherDashboardSummary getTeacherDashboardSummary;
  final OcrListMine ocrListMine;

  TeacherDashboardCubit({
    required this.getTeacherDashboardSummary,
    required this.ocrListMine,
  })
      : super(const TeacherDashboardInitial());

  List<OcrResultEntity> _sortResults(List<OcrResultEntity> list) {
    final sorted = List<OcrResultEntity>.from(list);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  Future<void> _load({required bool showLoading}) async {
    if (showLoading) {
      emit(const TeacherDashboardLoading());
    }

    final summaryResult = await getTeacherDashboardSummary(const NoParams());
    final ocrResult = await ocrListMine(const NoParams());

    summaryResult.fold(
      (failure) => emit(TeacherDashboardError(failure.message)),
      (summary) {
        final recentOcrResults = ocrResult.fold<List<OcrResultEntity>>(
          (_) => const [],
          _sortResults,
        );
        emit(TeacherDashboardLoaded(
          summary,
          recentOcrResults: recentOcrResults,
        ));
      },
    );
  }

  Future<void> loadDashboard() async {
    await _load(showLoading: true);
  }

  Future<void> refreshDashboard() async {
    await _load(showLoading: false);
  }
}
