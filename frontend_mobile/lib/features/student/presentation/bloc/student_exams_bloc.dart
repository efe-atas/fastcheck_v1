import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/student_entities.dart';
import '../../domain/usecases/student_usecases.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class StudentExamsEvent extends Equatable {
  const StudentExamsEvent();

  @override
  List<Object?> get props => [];
}

class LoadStudentExams extends StudentExamsEvent {
  const LoadStudentExams();
}

class LoadMoreExams extends StudentExamsEvent {
  const LoadMoreExams();
}

class FilterExamsByStatus extends StudentExamsEvent {
  final String? status;

  const FilterExamsByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class RefreshStudentExams extends StudentExamsEvent {
  const RefreshStudentExams();
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class StudentExamsState extends Equatable {
  const StudentExamsState();

  @override
  List<Object?> get props => [];
}

class StudentExamsInitial extends StudentExamsState {
  const StudentExamsInitial();
}

class StudentExamsLoading extends StudentExamsState {
  const StudentExamsLoading();
}

class StudentExamsLoaded extends StudentExamsState {
  final List<StudentExamEntity> exams;
  final int currentPage;
  final int totalPages;
  final bool isLast;
  final String? activeFilter;
  final bool isLoadingMore;

  const StudentExamsLoaded({
    required this.exams,
    required this.currentPage,
    required this.totalPages,
    required this.isLast,
    this.activeFilter,
    this.isLoadingMore = false,
  });

  StudentExamsLoaded copyWith({
    List<StudentExamEntity>? exams,
    int? currentPage,
    int? totalPages,
    bool? isLast,
    String? activeFilter,
    bool? isLoadingMore,
    bool clearFilter = false,
  }) {
    return StudentExamsLoaded(
      exams: exams ?? this.exams,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLast: isLast ?? this.isLast,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props =>
      [exams, currentPage, totalPages, isLast, activeFilter, isLoadingMore];
}

class StudentExamsError extends StudentExamsState {
  final String message;

  const StudentExamsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

class StudentExamsBloc extends Bloc<StudentExamsEvent, StudentExamsState> {
  final GetStudentExams getStudentExams;

  static const int _pageSize = 20;

  StudentExamsBloc({required this.getStudentExams})
      : super(const StudentExamsInitial()) {
    on<LoadStudentExams>(_onLoad);
    on<LoadMoreExams>(_onLoadMore);
    on<FilterExamsByStatus>(_onFilter);
    on<RefreshStudentExams>(_onRefresh);
  }

  Future<void> _onLoad(
    LoadStudentExams event,
    Emitter<StudentExamsState> emit,
  ) async {
    emit(const StudentExamsLoading());
    await _fetchExams(emit, page: 0, status: null);
  }

  Future<void> _onLoadMore(
    LoadMoreExams event,
    Emitter<StudentExamsState> emit,
  ) async {
    final current = state;
    if (current is! StudentExamsLoaded || current.isLast || current.isLoadingMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));

    final nextPage = current.currentPage + 1;
    final result = await getStudentExams(
      GetStudentExamsParams(
        page: nextPage,
        size: _pageSize,
        examStatus: current.activeFilter,
      ),
    );

    result.fold(
      (failure) => emit(current.copyWith(isLoadingMore: false)),
      (paged) => emit(current.copyWith(
        exams: [...current.exams, ...paged.content],
        currentPage: paged.currentPage,
        totalPages: paged.totalPages,
        isLast: !paged.hasNext,
        isLoadingMore: false,
      )),
    );
  }

  Future<void> _onFilter(
    FilterExamsByStatus event,
    Emitter<StudentExamsState> emit,
  ) async {
    emit(const StudentExamsLoading());
    await _fetchExams(emit, page: 0, status: event.status);
  }

  Future<void> _onRefresh(
    RefreshStudentExams event,
    Emitter<StudentExamsState> emit,
  ) async {
    final currentFilter =
        state is StudentExamsLoaded ? (state as StudentExamsLoaded).activeFilter : null;
    emit(const StudentExamsLoading());
    await _fetchExams(emit, page: 0, status: currentFilter);
  }

  Future<void> _fetchExams(
    Emitter<StudentExamsState> emit, {
    required int page,
    required String? status,
  }) async {
    final result = await getStudentExams(
      GetStudentExamsParams(page: page, size: _pageSize, examStatus: status),
    );

    result.fold(
      (failure) => emit(StudentExamsError(failure.message)),
      (paged) => emit(StudentExamsLoaded(
        exams: paged.content,
        currentPage: paged.currentPage,
        totalPages: paged.totalPages,
        isLast: !paged.hasNext,
        activeFilter: status,
      )),
    );
  }
}
