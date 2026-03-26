import 'package:dartz/dartz.dart';
import '../../../../core/domain/paged_result.dart';
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
  Future<Either<Failure, PagedResult<AdminUserSummaryEntity>>> searchUsers({
    String? role,
    String? query,
    required int page,
    required int size,
  }) async {
    try {
      final result = await remoteDataSource.searchUsers(
        role: role,
        query: query,
        page: page,
        size: size,
      );
      return Right(result.toEntity((m) => m.toEntity()));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PagedResult<AdminSchoolSummaryEntity>>> searchSchools({
    String? query,
    required int page,
    required int size,
  }) async {
    try {
      final result = await remoteDataSource.searchSchools(
        query: query,
        page: page,
        size: size,
      );
      return Right(result.toEntity((m) => m.toEntity()));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminBulkOperationEntity>> bulkAssignUsersToSchools({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final result = await remoteDataSource.bulkAssignUsersToSchools(
        fileBytes: fileBytes,
        fileName: fileName,
      );
      return Right(result.toEntity());
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
  Future<Either<Failure, AdminBulkOperationEntity>> bulkLinkParentStudents({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final result = await remoteDataSource.bulkLinkParentStudents(
        fileBytes: fileBytes,
        fileName: fileName,
      );
      return Right(result.toEntity());
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
