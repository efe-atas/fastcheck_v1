import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/student_entities.dart';
import '../repositories/student_repository.dart';

class GetStudentExams
    implements UseCase<PagedResult<StudentExamEntity>, GetStudentExamsParams> {
  final StudentRepository repository;

  GetStudentExams(this.repository);

  @override
  Future<Either<Failure, PagedResult<StudentExamEntity>>> call(
    GetStudentExamsParams params,
  ) {
    return repository.getStudentExams(
      page: params.page,
      size: params.size,
      examStatus: params.examStatus,
    );
  }
}

class GetStudentExamsParams extends Equatable {
  final int page;
  final int size;
  final String? examStatus;

  const GetStudentExamsParams({
    this.page = 0,
    this.size = 20,
    this.examStatus,
  });

  @override
  List<Object?> get props => [page, size, examStatus];
}

class GetExamQuestions
    implements UseCase<List<QuestionEntity>, GetExamQuestionsParams> {
  final StudentRepository repository;

  GetExamQuestions(this.repository);

  @override
  Future<Either<Failure, List<QuestionEntity>>> call(
    GetExamQuestionsParams params,
  ) {
    return repository.getExamQuestions(examId: params.examId);
  }
}

class GetExamQuestionsParams extends Equatable {
  final int examId;

  const GetExamQuestionsParams({required this.examId});

  @override
  List<Object?> get props => [examId];
}
