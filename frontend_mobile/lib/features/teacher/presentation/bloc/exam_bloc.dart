import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/teacher_entities.dart';
import '../../domain/usecases/teacher_usecases.dart';

// --- Events ---

abstract class ExamEvent extends Equatable {
  const ExamEvent();

  @override
  List<Object?> get props => [];
}

class CreateExamEvent extends ExamEvent {
  final int classId;
  final String title;

  const CreateExamEvent({required this.classId, required this.title});

  @override
  List<Object?> get props => [classId, title];
}

class UploadImagesEvent extends ExamEvent {
  final int examId;
  final List<File> images;

  const UploadImagesEvent({required this.examId, required this.images});

  @override
  List<Object?> get props => [examId, images];
}

class LoadExamStatusEvent extends ExamEvent {
  final int examId;

  const LoadExamStatusEvent(this.examId);

  @override
  List<Object?> get props => [examId];
}

class RefreshExamStatusEvent extends ExamEvent {
  final int examId;

  const RefreshExamStatusEvent(this.examId);

  @override
  List<Object?> get props => [examId];
}

class ReprocessExamEvent extends ExamEvent {
  final int examId;

  const ReprocessExamEvent(this.examId);

  @override
  List<Object?> get props => [examId];
}

class UpdateExamImageStudentMatchEvent extends ExamEvent {
  final int examId;
  final int imageId;
  final int studentId;

  const UpdateExamImageStudentMatchEvent({
    required this.examId,
    required this.imageId,
    required this.studentId,
  });

  @override
  List<Object?> get props => [examId, imageId, studentId];
}

class UpdateQuestionOverrideEvent extends ExamEvent {
  final int examId;
  final int questionId;
  final double awardedPoints;
  final double maxPoints;
  final String? expectedAnswer;
  final String? gradingRubric;
  final String? evaluationSummary;
  final bool? correct;

  const UpdateQuestionOverrideEvent({
    required this.examId,
    required this.questionId,
    required this.awardedPoints,
    required this.maxPoints,
    this.expectedAnswer,
    this.gradingRubric,
    this.evaluationSummary,
    this.correct,
  });

  @override
  List<Object?> get props => [
        examId,
        questionId,
        awardedPoints,
        maxPoints,
        expectedAnswer,
        gradingRubric,
        evaluationSummary,
        correct,
      ];
}

// --- States ---

abstract class ExamState extends Equatable {
  const ExamState();

  @override
  List<Object?> get props => [];
}

class ExamInitial extends ExamState {
  const ExamInitial();
}

class ExamCreating extends ExamState {
  const ExamCreating();
}

class ExamCreated extends ExamState {
  final ExamEntity exam;

  const ExamCreated(this.exam);

  @override
  List<Object?> get props => [exam];
}

class ImagesUploading extends ExamState {
  const ImagesUploading();
}

class ImagesUploaded extends ExamState {
  final List<ExamImageEntity> images;

  const ImagesUploaded(this.images);

  @override
  List<Object?> get props => [images];
}

class ExamStatusLoading extends ExamState {
  const ExamStatusLoading();
}

class ExamStatusLoaded extends ExamState {
  final ExamStatusEntity examStatus;

  const ExamStatusLoaded(this.examStatus);

  @override
  List<Object?> get props => [examStatus];
}

class ExamError extends ExamState {
  final String message;

  const ExamError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---

class ExamBloc extends Bloc<ExamEvent, ExamState> {
  final CreateExam createExam;
  final UploadExamImages uploadExamImages;
  final GetExamStatus getExamStatus;
  final ReprocessExam reprocessExam;
  final UpdateExamImageStudentMatch updateExamImageStudentMatch;
  final UpdateQuestionOverride updateQuestionOverride;

  ExamBloc({
    required this.createExam,
    required this.uploadExamImages,
    required this.getExamStatus,
    required this.reprocessExam,
    required this.updateExamImageStudentMatch,
    required this.updateQuestionOverride,
  }) : super(const ExamInitial()) {
    on<CreateExamEvent>(_onCreateExam);
    on<UploadImagesEvent>(_onUploadImages);
    on<LoadExamStatusEvent>(_onLoadExamStatus);
    on<RefreshExamStatusEvent>(_onRefreshExamStatus);
    on<ReprocessExamEvent>(_onReprocessExam);
    on<UpdateExamImageStudentMatchEvent>(_onUpdateExamImageStudentMatch);
    on<UpdateQuestionOverrideEvent>(_onUpdateQuestionOverride);
  }

  Future<void> _onCreateExam(
    CreateExamEvent event,
    Emitter<ExamState> emit,
  ) async {
    emit(const ExamCreating());
    final result = await createExam(
      CreateExamParams(classId: event.classId, title: event.title),
    );
    result.fold(
      (failure) => emit(ExamError(failure.message)),
      (exam) => emit(ExamCreated(exam)),
    );
  }

  Future<void> _onUploadImages(
    UploadImagesEvent event,
    Emitter<ExamState> emit,
  ) async {
    emit(const ImagesUploading());
    final result = await uploadExamImages(
      UploadExamImagesParams(examId: event.examId, images: event.images),
    );
    await result.fold(
      (failure) async => emit(ExamError(failure.message)),
      (images) async {
        final statusResult = await getExamStatus(event.examId);
        statusResult.fold(
          (_) => emit(ImagesUploaded(images)),
          (status) => emit(ExamStatusLoaded(status)),
        );
      },
    );
  }

  Future<void> _onLoadExamStatus(
    LoadExamStatusEvent event,
    Emitter<ExamState> emit,
  ) async {
    emit(const ExamStatusLoading());
    final result = await getExamStatus(event.examId);
    result.fold(
      (failure) => emit(ExamError(failure.message)),
      (status) => emit(ExamStatusLoaded(status)),
    );
  }

  Future<void> _onRefreshExamStatus(
    RefreshExamStatusEvent event,
    Emitter<ExamState> emit,
  ) async {
    final result = await getExamStatus(event.examId);
    result.fold(
      (failure) => emit(ExamError(failure.message)),
      (status) => emit(ExamStatusLoaded(status)),
    );
  }

  Future<void> _onReprocessExam(
    ReprocessExamEvent event,
    Emitter<ExamState> emit,
  ) async {
    emit(const ExamStatusLoading());
    final result = await reprocessExam(event.examId);
    result.fold(
      (failure) => emit(ExamError(failure.message)),
      (status) => emit(ExamStatusLoaded(status)),
    );
  }

  Future<void> _onUpdateExamImageStudentMatch(
    UpdateExamImageStudentMatchEvent event,
    Emitter<ExamState> emit,
  ) async {
    emit(const ExamStatusLoading());
    final result = await updateExamImageStudentMatch(
      UpdateExamImageStudentMatchParams(
        examId: event.examId,
        imageId: event.imageId,
        studentId: event.studentId,
      ),
    );
    result.fold(
      (failure) => emit(ExamError(failure.message)),
      (status) => emit(ExamStatusLoaded(status)),
    );
  }

  Future<void> _onUpdateQuestionOverride(
    UpdateQuestionOverrideEvent event,
    Emitter<ExamState> emit,
  ) async {
    emit(const ExamStatusLoading());
    final result = await updateQuestionOverride(
      UpdateQuestionOverrideParams(
        examId: event.examId,
        questionId: event.questionId,
        awardedPoints: event.awardedPoints,
        maxPoints: event.maxPoints,
        expectedAnswer: event.expectedAnswer,
        gradingRubric: event.gradingRubric,
        evaluationSummary: event.evaluationSummary,
        correct: event.correct,
      ),
    );
    result.fold(
      (failure) => emit(ExamError(failure.message)),
      (status) => emit(ExamStatusLoaded(status)),
    );
  }
}
