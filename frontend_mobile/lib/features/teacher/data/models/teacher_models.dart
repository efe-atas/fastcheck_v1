import '../../domain/entities/teacher_entities.dart';

class ClassModel {
  final int classId;
  final int schoolId;
  final String className;
  final int examCount;
  final String createdAt;

  const ClassModel({
    required this.classId,
    required this.schoolId,
    required this.className,
    required this.examCount,
    required this.createdAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      classId: json['classId'] as int,
      schoolId: json['schoolId'] as int,
      className: json['className'] as String,
      examCount: json['examCount'] as int? ?? 0,
      createdAt: json['createdAt'] as String,
    );
  }

  ClassEntity toEntity() {
    return ClassEntity(
      classId: classId,
      schoolId: schoolId,
      className: className,
      examCount: examCount,
      createdAt: DateTime.parse(createdAt),
    );
  }
}

class ExamModel {
  final int examId;
  final int classId;
  final String title;
  final String status;
  final String createdAt;

  const ExamModel({
    required this.examId,
    required this.classId,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      examId: json['examId'] as int,
      classId: json['classId'] as int,
      title: json['title'] as String,
      status: json['status'] as String? ?? 'DRAFT',
      createdAt: json['createdAt'] as String,
    );
  }

  ExamEntity toEntity() {
    return ExamEntity(
      examId: examId,
      classId: classId,
      title: title,
      status: status,
      createdAt: DateTime.parse(createdAt),
    );
  }
}

class StudentModel {
  final int userId;
  final String fullName;
  final String email;
  final int classId;

  const StudentModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.classId,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      userId: json['userId'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      classId: json['classId'] as int,
    );
  }

  StudentEntity toEntity() {
    return StudentEntity(
      userId: userId,
      fullName: fullName,
      email: email,
      classId: classId,
    );
  }
}

class ExamImageModel {
  final int imageId;
  final int examId;
  final String filePath;
  final String status;

  const ExamImageModel({
    required this.imageId,
    required this.examId,
    required this.filePath,
    required this.status,
  });

  factory ExamImageModel.fromJson(Map<String, dynamic> json) {
    return ExamImageModel(
      imageId: json['imageId'] as int? ?? json['id'] as int,
      examId: json['examId'] as int,
      filePath: json['filePath'] as String? ?? json['fileName'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
    );
  }

  ExamImageEntity toEntity() {
    return ExamImageEntity(
      imageId: imageId,
      examId: examId,
      filePath: filePath,
      status: status,
    );
  }
}

class OcrJobModel {
  final int jobId;
  final int imageId;
  final String status;
  final String? errorMessage;

  const OcrJobModel({
    required this.jobId,
    required this.imageId,
    required this.status,
    this.errorMessage,
  });

  factory OcrJobModel.fromJson(Map<String, dynamic> json) {
    return OcrJobModel(
      jobId: json['jobId'] as int? ?? json['id'] as int,
      imageId: json['imageId'] as int,
      status: json['status'] as String,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  OcrJobEntity toEntity() {
    return OcrJobEntity(
      jobId: jobId,
      imageId: imageId,
      status: status,
      errorMessage: errorMessage,
    );
  }
}

class ExamStatusModel {
  final int examId;
  final int classId;
  final String title;
  final String examStatus;
  final List<ExamImageModel> images;
  final List<OcrJobModel> ocrJobs;

  const ExamStatusModel({
    required this.examId,
    required this.classId,
    required this.title,
    required this.examStatus,
    required this.images,
    required this.ocrJobs,
  });

  factory ExamStatusModel.fromJson(Map<String, dynamic> json) {
    return ExamStatusModel(
      examId: json['examId'] as int,
      classId: json['classId'] as int,
      title: json['title'] as String,
      examStatus: json['examStatus'] as String? ?? json['status'] as String? ?? 'DRAFT',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => ExamImageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ocrJobs: (json['ocrJobs'] as List<dynamic>?)
              ?.map((e) => OcrJobModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  ExamStatusEntity toEntity() {
    return ExamStatusEntity(
      examId: examId,
      classId: classId,
      title: title,
      examStatus: examStatus,
      images: images.map((e) => e.toEntity()).toList(),
      ocrJobs: ocrJobs.map((e) => e.toEntity()).toList(),
    );
  }
}

class PagedResponseModel<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final bool last;

  const PagedResponseModel({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.last,
  });

  factory PagedResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResponseModel(
      content: (json['content'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      last: json['last'] as bool? ?? true,
    );
  }
}
