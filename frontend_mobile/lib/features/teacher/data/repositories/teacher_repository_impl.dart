import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/domain/paged_result.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/teacher_entities.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../datasources/teacher_remote_datasource.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  final TeacherRemoteDataSource remoteDataSource;

  const TeacherRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, TeacherDashboardSummaryEntity>>
      getDashboardSummary() async {
    try {
      final model = await remoteDataSource.getDashboardSummary();
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ClassEntity>>> getClasses() async {
    try {
      final models = await remoteDataSource.getClasses();
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ExamEntity>>> getClassExams(int classId) async {
    try {
      final models = await remoteDataSource.getClassExams(classId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PagedResult<StudentEntity>>> getClassStudents(
    int classId, {
    int page = 0,
    int size = 20,
    String? name,
  }) async {
    try {
      final pagedModel = await remoteDataSource.getClassStudents(
        classId,
        page: page,
        size: size,
        name: name,
      );
      return Right(
        pagedModel.toPagedResult((m) => m.toEntity()),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ClassEntity>> createClass({
    required String className,
  }) async {
    try {
      final model = await remoteDataSource.createClass(
        className: className,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExamEntity>> createExam({
    required int classId,
    required String title,
  }) async {
    try {
      final model = await remoteDataSource.createExam(
        classId: classId,
        title: title,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ExamImageEntity>>> uploadExamImages({
    required int examId,
    required List<File> images,
  }) async {
    try {
      final models = await remoteDataSource.uploadExamImages(
        examId: examId,
        images: images,
      );
      return Right(
        models
            .map((m) => m.toEntity(parentExamId: m.examId ?? examId))
            .toList(),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExamStatusEntity>> getExamStatus(int examId) async {
    try {
      final model = await remoteDataSource.getExamStatus(examId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, StudentEntity>> addStudentToClass({
    required int classId,
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final model = await remoteDataSource.addStudentToClass(
        classId: classId,
        fullName: fullName,
        email: email,
        password: password,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
