import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/domain/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/parent_entities.dart';
import '../repositories/parent_repository.dart';

class GetLinkedStudents extends UseCase<List<LinkedStudentEntity>, int> {
  final ParentRepository repository;

  GetLinkedStudents(this.repository);

  @override
  Future<Either<Failure, List<LinkedStudentEntity>>> call(int parentUserId) {
    return repository.getLinkedStudents(parentUserId);
  }
}

class GetParentDashboardSummary
    extends UseCase<ParentDashboardSummaryEntity, NoParams> {
  final ParentRepository repository;

  GetParentDashboardSummary(this.repository);

  @override
  Future<Either<Failure, ParentDashboardSummaryEntity>> call(
    NoParams params,
  ) {
    return repository.getDashboardSummary();
  }
}

class GetStudentExamQuestions
    extends UseCase<List<ParentQuestionEntity>, StudentExamParams> {
  final ParentRepository repository;

  GetStudentExamQuestions(this.repository);

  @override
  Future<Either<Failure, List<ParentQuestionEntity>>> call(
      StudentExamParams params) {
    return repository.getStudentExamQuestions(params.studentId, params.examId);
  }
}

class StudentExamParams extends Equatable {
  final int studentId;
  final int examId;

  const StudentExamParams({required this.studentId, required this.examId});

  @override
  List<Object?> get props => [studentId, examId];
}

class GetParentStudentExamsParams extends Equatable {
  final int studentId;
  final int page;
  final int size;
  final String? examStatus;

  const GetParentStudentExamsParams({
    required this.studentId,
    this.page = 0,
    this.size = 20,
    this.examStatus,
  });

  @override
  List<Object?> get props => [studentId, page, size, examStatus];
}

class GetParentStudentExams
    extends UseCase<PagedResult<ParentStudentExamEntity>,
        GetParentStudentExamsParams> {
  final ParentRepository repository;

  GetParentStudentExams(this.repository);

  @override
  Future<Either<Failure, PagedResult<ParentStudentExamEntity>>> call(
    GetParentStudentExamsParams params,
  ) {
    return repository.getStudentExams(
      params.studentId,
      page: params.page,
      size: params.size,
      examStatus: params.examStatus,
    );
  }
}
