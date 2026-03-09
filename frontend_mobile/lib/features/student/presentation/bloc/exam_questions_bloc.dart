import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/student_entities.dart';
import '../../domain/usecases/student_usecases.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class ExamQuestionsEvent extends Equatable {
  const ExamQuestionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadExamQuestions extends ExamQuestionsEvent {
  final int examId;

  const LoadExamQuestions({required this.examId});

  @override
  List<Object?> get props => [examId];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class ExamQuestionsState extends Equatable {
  const ExamQuestionsState();

  @override
  List<Object?> get props => [];
}

class ExamQuestionsInitial extends ExamQuestionsState {
  const ExamQuestionsInitial();
}

class ExamQuestionsLoading extends ExamQuestionsState {
  const ExamQuestionsLoading();
}

class ExamQuestionsLoaded extends ExamQuestionsState {
  final List<QuestionEntity> questions;

  const ExamQuestionsLoaded({required this.questions});

  @override
  List<Object?> get props => [questions];
}

class ExamQuestionsError extends ExamQuestionsState {
  final String message;

  const ExamQuestionsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

class ExamQuestionsBloc extends Bloc<ExamQuestionsEvent, ExamQuestionsState> {
  final GetExamQuestions getExamQuestions;

  ExamQuestionsBloc({required this.getExamQuestions})
      : super(const ExamQuestionsInitial()) {
    on<LoadExamQuestions>(_onLoad);
  }

  Future<void> _onLoad(
    LoadExamQuestions event,
    Emitter<ExamQuestionsState> emit,
  ) async {
    emit(const ExamQuestionsLoading());

    final result = await getExamQuestions(
      GetExamQuestionsParams(examId: event.examId),
    );

    result.fold(
      (failure) => emit(ExamQuestionsError(failure.message)),
      (questions) => emit(ExamQuestionsLoaded(questions: questions)),
    );
  }
}
