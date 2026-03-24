import '../../domain/entities/admin_entities.dart';

class SchoolModel {
  final int schoolId;
  final String schoolName;
  final String createdAt;

  const SchoolModel({
    required this.schoolId,
    required this.schoolName,
    required this.createdAt,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      schoolId: json['schoolId'] as int,
      schoolName: json['schoolName'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  SchoolEntity toEntity() {
    return SchoolEntity(
      schoolId: schoolId,
      schoolName: schoolName,
      createdAt: DateTime.parse(createdAt),
    );
  }
}

class AssignUserToSchoolModel {
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final int? classId;
  final String? initialPassword;

  const AssignUserToSchoolModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.classId,
    this.initialPassword,
  });

  factory AssignUserToSchoolModel.fromJson(Map<String, dynamic> json) {
    return AssignUserToSchoolModel(
      userId: json['userId'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      classId: json['classId'] as int?,
      initialPassword: json['initialPassword'] as String?,
    );
  }

  AssignUserToSchoolEntity toEntity() {
    return AssignUserToSchoolEntity(
      userId: userId,
      fullName: fullName,
      email: email,
      role: role,
      classId: classId,
      initialPassword: initialPassword,
    );
  }
}

class ParentStudentLinkModel {
  final int linkId;
  final int parentUserId;
  final int studentUserId;
  final String createdAt;

  const ParentStudentLinkModel({
    required this.linkId,
    required this.parentUserId,
    required this.studentUserId,
    required this.createdAt,
  });

  factory ParentStudentLinkModel.fromJson(Map<String, dynamic> json) {
    return ParentStudentLinkModel(
      linkId: json['linkId'] as int,
      parentUserId: json['parentUserId'] as int,
      studentUserId: json['studentUserId'] as int,
      createdAt: json['createdAt'] as String,
    );
  }

  ParentStudentLinkEntity toEntity() {
    return ParentStudentLinkEntity(
      linkId: linkId,
      parentUserId: parentUserId,
      studentUserId: studentUserId,
      createdAt: DateTime.parse(createdAt),
    );
  }
}

class AdminParentStudentViewModel {
  final int userId;
  final String fullName;
  final String email;
  final int? classId;

  const AdminParentStudentViewModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.classId,
  });

  factory AdminParentStudentViewModel.fromJson(Map<String, dynamic> json) {
    return AdminParentStudentViewModel(
      userId: json['userId'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      classId: json['classId'] as int?,
    );
  }

  AdminParentStudentViewEntity toEntity() {
    return AdminParentStudentViewEntity(
      userId: userId,
      fullName: fullName,
      email: email,
      classId: classId,
    );
  }
}
