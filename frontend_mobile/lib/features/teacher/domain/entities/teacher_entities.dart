import 'package:equatable/equatable.dart';

class ClassEntity extends Equatable {
  final int classId;
  final int schoolId;
  final String className;
  final int examCount;
  final DateTime createdAt;

  const ClassEntity({
    required this.classId,
    required this.schoolId,
    required this.className,
    required this.examCount,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [classId, schoolId, className, examCount, createdAt];
}

class ExamEntity extends Equatable {
  final int examId;
  final int classId;
  final String title;
  final String status;
  final DateTime createdAt;

  const ExamEntity({
    required this.examId,
    required this.classId,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [examId, classId, title, status, createdAt];
}

class StudentEntity extends Equatable {
  final int userId;
  final String fullName;
  final String email;
  final int classId;

  const StudentEntity({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.classId,
  });

  @override
  List<Object?> get props => [userId, fullName, email, classId];
}

class ExamImageEntity extends Equatable {
  final int imageId;
  final int? examId;
  final int pageOrder;
  final String imageUrl;
  final String status;
  final String? errorMessage;
  final DateTime? processingStartedAt;
  final DateTime? processingCompletedAt;

  const ExamImageEntity({
    required this.imageId,
    this.examId,
    this.pageOrder = 0,
    required this.imageUrl,
    required this.status,
    this.errorMessage,
    this.processingStartedAt,
    this.processingCompletedAt,
  });

  @override
  List<Object?> get props =>
      [
        imageId,
        examId,
        pageOrder,
        imageUrl,
        status,
        errorMessage,
        processingStartedAt,
        processingCompletedAt,
      ];
}

class OcrJobEntity extends Equatable {
  final String jobId;
  final String requestId;
  final String status;
  final int retryCount;
  final String? errorMessage;
  final DateTime? createdAt;

  const OcrJobEntity({
    required this.jobId,
    required this.requestId,
    required this.status,
    this.retryCount = 0,
    this.errorMessage,
    this.createdAt,
  });

  @override
  List<Object?> get props =>
      [jobId, requestId, status, retryCount, errorMessage, createdAt];
}

class ExamStatusEntity extends Equatable {
  final int examId;
  final int classId;
  final String title;
  final String examStatus;
  final List<ExamImageEntity> images;
  final List<OcrJobEntity> ocrJobs;

  const ExamStatusEntity({
    required this.examId,
    required this.classId,
    required this.title,
    required this.examStatus,
    required this.images,
    required this.ocrJobs,
  });

  @override
  List<Object?> get props => [examId, classId, title, examStatus, images, ocrJobs];
}

class TeacherDashboardSummaryEntity extends Equatable {
  final int totalClasses;
  final int totalExams;
  final int processingExams;
  final int readyExams;
  final List<ExamEntity> latestExams;
  final List<OcrJobEntity> recentOcrJobs;

  const TeacherDashboardSummaryEntity({
    required this.totalClasses,
    required this.totalExams,
    required this.processingExams,
    required this.readyExams,
    required this.latestExams,
    required this.recentOcrJobs,
  });

  @override
  List<Object?> get props => [
        totalClasses,
        totalExams,
        processingExams,
        readyExams,
        latestExams,
        recentOcrJobs,
      ];
}
