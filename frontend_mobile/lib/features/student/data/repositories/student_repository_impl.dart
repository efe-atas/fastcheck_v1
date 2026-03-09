import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/student_entities.dart';
import '../../domain/repositories/student_repository.dart';
import '../datasources/student_remote_datasource.dart';

class StudentRepositoryImpl implements StudentRepository {
  final StudentRemoteDataSource remoteDataSource;

  StudentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PagedResult<StudentExamEntity>>> getStudentExams({
    required int page,
    required int size,
    String? examStatus,
  }) async {
    try {
      final response = await remoteDataSource.getStudentExams(
        page: page,
        size: size,
        examStatus: examStatus,
      );
      final pagedResult = response.toEntity((model) => model.toEntity());
      return Right(pagedResult);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return const Left(ServerFailure('Sınavlar yüklenirken bir hata oluştu'));
    }
  }

  @override
  Future<Either<Failure, List<QuestionEntity>>> getExamQuestions({
    required int examId,
  }) async {
    try {
      final models = await remoteDataSource.getExamQuestions(examId: examId);
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return const Left(ServerFailure('Sorular yüklenirken bir hata oluştu'));
    }
  }
}
