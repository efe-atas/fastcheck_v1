import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/parent_entities.dart';

abstract class ParentRepository {
  Future<Either<Failure, ParentDashboardSummaryEntity>> getDashboardSummary();

  Future<Either<Failure, List<LinkedStudentEntity>>> getLinkedStudents(
      int parentUserId);
  Future<Either<Failure, List<ParentQuestionEntity>>>
      getStudentExamQuestions(int studentId, int examId);
}
