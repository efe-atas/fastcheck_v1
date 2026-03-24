import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/admin_entities.dart';
import '../repositories/admin_repository.dart';

class CreateSchool extends UseCase<SchoolEntity, CreateSchoolParams> {
  final AdminRepository repository;

  CreateSchool(this.repository);

  @override
  Future<Either<Failure, SchoolEntity>> call(CreateSchoolParams params) {
    return repository.createSchool(params.schoolName);
  }
}

class CreateSchoolParams extends Equatable {
  final String schoolName;

  const CreateSchoolParams({required this.schoolName});

  @override
  List<Object?> get props => [schoolName];
}

class AssignUserToSchoolUc
    extends UseCase<AssignUserToSchoolEntity, AssignUserToSchoolParams> {
  final AdminRepository repository;

  AssignUserToSchoolUc(this.repository);

  @override
  Future<Either<Failure, AssignUserToSchoolEntity>> call(
    AssignUserToSchoolParams params,
  ) {
    return repository.assignUserToSchool(params.userId, params.schoolId);
  }
}

class AssignUserToSchoolParams extends Equatable {
  final int userId;
  final int schoolId;

  const AssignUserToSchoolParams({
    required this.userId,
    required this.schoolId,
  });

  @override
  List<Object?> get props => [userId, schoolId];
}

class LinkParentStudentUc
    extends UseCase<ParentStudentLinkEntity, LinkParentStudentParams> {
  final AdminRepository repository;

  LinkParentStudentUc(this.repository);

  @override
  Future<Either<Failure, ParentStudentLinkEntity>> call(
    LinkParentStudentParams params,
  ) {
    return repository.linkParentStudent(
      parentUserId: params.parentUserId,
      studentUserId: params.studentUserId,
    );
  }
}

class LinkParentStudentParams extends Equatable {
  final int parentUserId;
  final int studentUserId;

  const LinkParentStudentParams({
    required this.parentUserId,
    required this.studentUserId,
  });

  @override
  List<Object?> get props => [parentUserId, studentUserId];
}

class ListParentStudentsAdmin
    extends UseCase<List<AdminParentStudentViewEntity>, int> {
  final AdminRepository repository;

  ListParentStudentsAdmin(this.repository);

  @override
  Future<Either<Failure, List<AdminParentStudentViewEntity>>> call(
    int parentUserId,
  ) {
    return repository.listParentStudents(parentUserId);
  }
}
