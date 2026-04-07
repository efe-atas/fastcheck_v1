import 'package:dartz/dartz.dart';
import '../../../../core/domain/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../entities/parent_entities.dart';

abstract class ParentRepository {
  Future<Either<Failure, ParentDashboardSummaryEntity>> getDashboardSummary();

  Future<Either<Failure, List<LinkedStudentEntity>>> getLinkedStudents(
      int parentUserId);
  Future<Either<Failure, List<ParentQuestionEntity>>>
      getStudentExamQuestions(int studentId, int examId);
  Future<Either<Failure, PagedResult<ParentStudentExamEntity>>> getStudentExams(
    int studentId, {
    int page = 0,
    int size = 20,
    String? examStatus,
  });
}
