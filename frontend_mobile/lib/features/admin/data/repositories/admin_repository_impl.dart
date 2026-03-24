import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, SchoolEntity>> createSchool(String schoolName) async {
    try {
      final m = await remoteDataSource.createSchool(schoolName);
      return Right(m.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AssignUserToSchoolEntity>> assignUserToSchool(
    int userId,
    int schoolId,
  ) async {
    try {
      final m = await remoteDataSource.assignUserToSchool(userId, schoolId);
      return Right(m.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ParentStudentLinkEntity>> linkParentStudent({
    required int parentUserId,
    required int studentUserId,
  }) async {
    try {
      final m = await remoteDataSource.linkParentStudent(
        parentUserId: parentUserId,
        studentUserId: studentUserId,
      );
      return Right(m.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AdminParentStudentViewEntity>>> listParentStudents(
    int parentUserId,
  ) async {
    try {
      final list = await remoteDataSource.listParentStudents(parentUserId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
