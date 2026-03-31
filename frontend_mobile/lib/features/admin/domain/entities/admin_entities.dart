import 'package:equatable/equatable.dart';
import '../../../../core/domain/paged_result.dart';

class SchoolEntity extends Equatable {
  final int schoolId;
  final String schoolName;
  final DateTime createdAt;

  const SchoolEntity({
    required this.schoolId,
    required this.schoolName,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [schoolId, schoolName, createdAt];
}

class AssignUserToSchoolEntity extends Equatable {
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final int? classId;
  final String? initialPassword;

  const AssignUserToSchoolEntity({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.classId,
    this.initialPassword,
  });

  @override
  List<Object?> get props =>
      [userId, fullName, email, role, classId, initialPassword];
}

class AdminProvisionedUserEntity extends Equatable {
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final int? schoolId;
  final int? classId;
  final String? initialPassword;

  const AdminProvisionedUserEntity({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.schoolId,
    this.classId,
    this.initialPassword,
  });

  bool get hasInitialPassword =>
      initialPassword != null && initialPassword!.isNotEmpty;

  @override
  List<Object?> get props =>
      [userId, fullName, email, role, schoolId, classId, initialPassword];
}

class ParentStudentLinkEntity extends Equatable {
  final int linkId;
  final int parentUserId;
  final int studentUserId;
  final DateTime createdAt;

  const ParentStudentLinkEntity({
    required this.linkId,
    required this.parentUserId,
    required this.studentUserId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [linkId, parentUserId, studentUserId, createdAt];
}

class AdminParentStudentViewEntity extends Equatable {
  final int userId;
  final String fullName;
  final String email;
  final int? classId;

  const AdminParentStudentViewEntity({
    required this.userId,
    required this.fullName,
    required this.email,
    this.classId,
  });

  @override
  List<Object?> get props => [userId, fullName, email, classId];
}

class AdminUserSummaryEntity extends Equatable {
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final int? schoolId;
  final int? classId;

  const AdminUserSummaryEntity({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.schoolId,
    this.classId,
  });

  bool get isParent => role == 'ROLE_PARENT';
  bool get isStudent => role == 'ROLE_STUDENT';

  @override
  List<Object?> get props => [userId, fullName, email, role, schoolId, classId];
}

class AdminSchoolSummaryEntity extends Equatable {
  final int schoolId;
  final String schoolName;
  final DateTime createdAt;

  const AdminSchoolSummaryEntity({
    required this.schoolId,
    required this.schoolName,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [schoolId, schoolName, createdAt];
}

class AdminBulkRowErrorEntity extends Equatable {
  final int rowNumber;
  final String message;

  const AdminBulkRowErrorEntity({
    required this.rowNumber,
    required this.message,
  });

  @override
  List<Object?> get props => [rowNumber, message];
}

class AdminBulkOperationEntity extends Equatable {
  final int processed;
  final int success;
  final int failed;
  final List<AdminBulkRowErrorEntity> errors;

  const AdminBulkOperationEntity({
    required this.processed,
    required this.success,
    required this.failed,
    required this.errors,
  });

  @override
  List<Object?> get props => [processed, success, failed, errors];
}

typedef AdminUserSearchResult = PagedResult<AdminUserSummaryEntity>;
typedef AdminSchoolSearchResult = PagedResult<AdminSchoolSummaryEntity>;
