import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/parent_entities.dart';
import '../../domain/usecases/parent_usecases.dart';

// Events
abstract class ParentEvent extends Equatable {
  const ParentEvent();
  @override
  List<Object?> get props => [];
}

class LoadLinkedStudents extends ParentEvent {
  final int parentUserId;
  const LoadLinkedStudents(this.parentUserId);
  @override
  List<Object?> get props => [parentUserId];
}

class LoadStudentExamQuestions extends ParentEvent {
  final int studentId;
  final int examId;
  const LoadStudentExamQuestions({
    required this.studentId,
    required this.examId,
  });
  @override
  List<Object?> get props => [studentId, examId];
}

// States
abstract class ParentState extends Equatable {
  const ParentState();
  @override
  List<Object?> get props => [];
}

class ParentInitial extends ParentState {
  const ParentInitial();
}

class ParentLoading extends ParentState {
  const ParentLoading();
}

class LinkedStudentsLoaded extends ParentState {
  final List<LinkedStudentEntity> students;
  const LinkedStudentsLoaded(this.students);
  @override
  List<Object?> get props => [students];
}

class StudentQuestionsLoaded extends ParentState {
  final List<ParentQuestionEntity> questions;
  const StudentQuestionsLoaded(this.questions);
  @override
  List<Object?> get props => [questions];
}

class ParentError extends ParentState {
  final String message;
  const ParentError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class ParentBloc extends Bloc<ParentEvent, ParentState> {
  final GetLinkedStudents getLinkedStudents;
  final GetStudentExamQuestions getStudentExamQuestions;

  ParentBloc({
    required this.getLinkedStudents,
    required this.getStudentExamQuestions,
  }) : super(const ParentInitial()) {
    on<LoadLinkedStudents>(_onLoadLinkedStudents);
    on<LoadStudentExamQuestions>(_onLoadStudentExamQuestions);
  }

  Future<void> _onLoadLinkedStudents(
    LoadLinkedStudents event,
    Emitter<ParentState> emit,
  ) async {
    emit(const ParentLoading());
    final result = await getLinkedStudents(event.parentUserId);
    result.fold(
      (failure) => emit(ParentError(failure.message)),
      (students) => emit(LinkedStudentsLoaded(students)),
    );
  }

  Future<void> _onLoadStudentExamQuestions(
    LoadStudentExamQuestions event,
    Emitter<ParentState> emit,
  ) async {
    emit(const ParentLoading());
    final result = await getStudentExamQuestions(
      StudentExamParams(studentId: event.studentId, examId: event.examId),
    );
    result.fold(
      (failure) => emit(ParentError(failure.message)),
      (questions) => emit(StudentQuestionsLoaded(questions)),
    );
  }
}
