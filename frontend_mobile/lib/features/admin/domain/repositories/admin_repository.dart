import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/admin_entities.dart';

abstract class AdminRepository {
  Future<Either<Failure, SchoolEntity>> createSchool(String schoolName);

  Future<Either<Failure, AssignUserToSchoolEntity>> assignUserToSchool(
    int userId,
    int schoolId,
  );

  Future<Either<Failure, ParentStudentLinkEntity>> linkParentStudent({
    required int parentUserId,
    required int studentUserId,
  });

  Future<Either<Failure, List<AdminParentStudentViewEntity>>> listParentStudents(
    int parentUserId,
  );
}
