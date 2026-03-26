import 'package:dartz/dartz.dart';
import '../../../../core/domain/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../entities/admin_entities.dart';

abstract class AdminRepository {
  Future<Either<Failure, SchoolEntity>> createSchool(String schoolName);

  Future<Either<Failure, AssignUserToSchoolEntity>> assignUserToSchool(
    int userId,
    int schoolId,
  );

  Future<Either<Failure, PagedResult<AdminUserSummaryEntity>>> searchUsers({
    String? role,
    String? query,
    required int page,
    required int size,
  });

  Future<Either<Failure, PagedResult<AdminSchoolSummaryEntity>>> searchSchools({
    String? query,
    required int page,
    required int size,
  });

  Future<Either<Failure, AdminBulkOperationEntity>> bulkAssignUsersToSchools({
    required List<int> fileBytes,
    required String fileName,
  });

  Future<Either<Failure, ParentStudentLinkEntity>> linkParentStudent({
    required int parentUserId,
    required int studentUserId,
  });

  Future<Either<Failure, AdminBulkOperationEntity>> bulkLinkParentStudents({
    required List<int> fileBytes,
    required String fileName,
  });

  Future<Either<Failure, List<AdminParentStudentViewEntity>>> listParentStudents(
    int parentUserId,
  );
}
