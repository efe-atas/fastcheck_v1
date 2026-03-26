import '../../domain/entities/admin_entities.dart';
import '../../../../core/domain/paged_result.dart';

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

class AdminUserSummaryModel {
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final int? schoolId;
  final int? classId;

  const AdminUserSummaryModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.schoolId,
    this.classId,
  });

  factory AdminUserSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminUserSummaryModel(
      userId: json['userId'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      schoolId: json['schoolId'] as int?,
      classId: json['classId'] as int?,
    );
  }

  AdminUserSummaryEntity toEntity() {
    return AdminUserSummaryEntity(
      userId: userId,
      fullName: fullName,
      email: email,
      role: role,
      schoolId: schoolId,
      classId: classId,
    );
  }
}

class AdminSchoolSummaryModel {
  final int schoolId;
  final String schoolName;
  final String createdAt;

  const AdminSchoolSummaryModel({
    required this.schoolId,
    required this.schoolName,
    required this.createdAt,
  });

  factory AdminSchoolSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminSchoolSummaryModel(
      schoolId: json['schoolId'] as int,
      schoolName: json['schoolName'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  AdminSchoolSummaryEntity toEntity() {
    return AdminSchoolSummaryEntity(
      schoolId: schoolId,
      schoolName: schoolName,
      createdAt: DateTime.parse(createdAt),
    );
  }
}

class AdminBulkRowErrorModel {
  final int rowNumber;
  final String message;

  const AdminBulkRowErrorModel({
    required this.rowNumber,
    required this.message,
  });

  factory AdminBulkRowErrorModel.fromJson(Map<String, dynamic> json) {
    return AdminBulkRowErrorModel(
      rowNumber: json['rowNumber'] as int,
      message: json['message'] as String,
    );
  }

  AdminBulkRowErrorEntity toEntity() {
    return AdminBulkRowErrorEntity(
      rowNumber: rowNumber,
      message: message,
    );
  }
}

class AdminBulkOperationModel {
  final int processed;
  final int success;
  final int failed;
  final List<AdminBulkRowErrorModel> errors;

  const AdminBulkOperationModel({
    required this.processed,
    required this.success,
    required this.failed,
    required this.errors,
  });

  factory AdminBulkOperationModel.fromJson(Map<String, dynamic> json) {
    final rawErrors = (json['errors'] as List<dynamic>? ?? const []);
    return AdminBulkOperationModel(
      processed: json['processed'] as int,
      success: json['success'] as int,
      failed: json['failed'] as int,
      errors: rawErrors
          .map((e) => AdminBulkRowErrorModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  AdminBulkOperationEntity toEntity() {
    return AdminBulkOperationEntity(
      processed: processed,
      success: success,
      failed: failed,
      errors: errors.map((e) => e.toEntity()).toList(),
    );
  }
}

class AdminPagedResultModel<T> {
  final List<T> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const AdminPagedResultModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory AdminPagedResultModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final rawItems = (json['items'] as List<dynamic>? ?? const []);
    return AdminPagedResultModel(
      items: rawItems.map((e) => itemFromJson(e as Map<String, dynamic>)).toList(),
      page: json['page'] as int,
      size: json['size'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  PagedResult<R> toEntity<R>(R Function(T) mapper) {
    return PagedResult<R>(
      content: items.map(mapper).toList(),
      totalElements: totalElements,
      totalPages: totalPages,
      currentPage: page,
      hasNext: page + 1 < totalPages,
    );
  }
}
