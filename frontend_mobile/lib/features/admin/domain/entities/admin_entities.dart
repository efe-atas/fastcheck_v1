import 'package:equatable/equatable.dart';

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
  List<Object?> get props =>
      [linkId, parentUserId, studentUserId, createdAt];
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
