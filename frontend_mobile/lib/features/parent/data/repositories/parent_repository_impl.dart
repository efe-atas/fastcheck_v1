import 'package:dartz/dartz.dart';
import '../../../../core/domain/paged_result.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/parent_entities.dart';
import '../../domain/repositories/parent_repository.dart';
import '../datasources/parent_remote_datasource.dart';

class ParentRepositoryImpl implements ParentRepository {
  final ParentRemoteDataSource remoteDataSource;

  ParentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ParentDashboardSummaryEntity>> getDashboardSummary() async {
    try {
      final model = await remoteDataSource.getDashboardSummary();
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return const Left(ServerFailure('Panel verileri alınamadı'));
    }
  }

  @override
  Future<Either<Failure, List<LinkedStudentEntity>>> getLinkedStudents(
      int parentUserId) async {
    try {
      final models = await remoteDataSource.getLinkedStudents(parentUserId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return const Left(ServerFailure('Öğrenci listesi alınamadı'));
    }
  }

  @override
  Future<Either<Failure, List<ParentQuestionEntity>>>
      getStudentExamQuestions(int studentId, int examId) async {
    try {
      final models =
          await remoteDataSource.getStudentExamQuestions(studentId, examId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return const Left(ServerFailure('Soru listesi alınamadı'));
    }
  }

  @override
  Future<Either<Failure, PagedResult<ParentStudentExamEntity>>> getStudentExams(
    int studentId, {
    int page = 0,
    int size = 20,
    String? examStatus,
  }) async {
    try {
      final paged = await remoteDataSource.getStudentExams(
        studentId,
        page: page,
        size: size,
        examStatus: examStatus,
      );
      return Right(paged.toPagedResult((m) => m.toEntity()));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return const Left(ServerFailure('Sınav listesi alınamadı'));
    }
  }
}

