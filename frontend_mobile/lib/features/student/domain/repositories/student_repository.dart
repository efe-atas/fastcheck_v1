import 'package:dartz/dartz.dart';
import '../../../../core/domain/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../entities/student_entities.dart';

abstract class StudentRepository {
  Future<Either<Failure, StudentDashboardSummaryEntity>> getDashboardSummary();

  Future<Either<Failure, PagedResult<StudentExamEntity>>> getStudentExams({
    required int page,
    required int size,
    String? examStatus,
  });

  Future<Either<Failure, List<QuestionEntity>>> getExamQuestions({
    required int examId,
  });
}
