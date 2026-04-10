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
  List<Object?> get props =>
      [classId, schoolId, className, examCount, createdAt];
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
  final String? initialPassword;

  const StudentEntity({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.classId,
    this.initialPassword,
  });

  @override
  List<Object?> get props =>
      [userId, fullName, email, classId, initialPassword];
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
  final StudentMatchEntity? studentMatch;

  const ExamImageEntity({
    required this.imageId,
    this.examId,
    this.pageOrder = 0,
    required this.imageUrl,
    required this.status,
    this.errorMessage,
    this.processingStartedAt,
    this.processingCompletedAt,
    this.studentMatch,
  });

  @override
  List<Object?> get props => [
        imageId,
        examId,
        pageOrder,
        imageUrl,
        status,
        errorMessage,
        processingStartedAt,
        processingCompletedAt,
        studentMatch,
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
  final String? gradingSystemSummary;
  final double? totalMaxPoints;
  final List<ExamImageEntity> images;
  final List<StudentEntity> students;
  final List<OcrJobEntity> ocrJobs;
  final int questionCount;
  final List<TeacherQuestionEntity> questions;
  final List<TeacherStudentClusterEntity> studentClusters;
  final List<StudentExamResultEntity> studentResults;

  const ExamStatusEntity({
    required this.examId,
    required this.classId,
    required this.title,
    required this.examStatus,
    this.gradingSystemSummary,
    this.totalMaxPoints,
    required this.images,
    this.students = const [],
    required this.ocrJobs,
    this.questionCount = 0,
    this.questions = const [],
    this.studentClusters = const [],
    this.studentResults = const [],
  });

  @override
  List<Object?> get props => [
        examId,
        classId,
        title,
        examStatus,
        gradingSystemSummary,
        totalMaxPoints,
        images,
        students,
        ocrJobs,
        questionCount,
        questions,
        studentClusters,
        studentResults,
      ];
}

class TeacherStudentClusterEntity extends Equatable {
  final int? studentId;
  final String studentName;
  final String? studentEmail;
  final bool unmatched;
  final String? matchingStatus;
  final int pageCount;
  final int questionCount;
  final double awardedPoints;
  final double maxPoints;
  final double scorePercentage;
  final String? gradingStatus;
  final String? gradingSummary;
  final List<ExamImageEntity> images;
  final List<TeacherQuestionEntity> questions;

  const TeacherStudentClusterEntity({
    this.studentId,
    required this.studentName,
    this.studentEmail,
    this.unmatched = false,
    this.matchingStatus,
    this.pageCount = 0,
    this.questionCount = 0,
    this.awardedPoints = 0,
    this.maxPoints = 0,
    this.scorePercentage = 0,
    this.gradingStatus,
    this.gradingSummary,
    this.images = const [],
    this.questions = const [],
  });

  bool get hasQuestions => questions.isNotEmpty;
  bool get hasImages => images.isNotEmpty;

  bool get needsAttention {
    final normalized = matchingStatus?.toUpperCase();
    return unmatched || normalized == 'UNMATCHED' || normalized == 'AMBIGUOUS';
  }

  @override
  List<Object?> get props => [
        studentId,
        studentName,
        studentEmail,
        unmatched,
        matchingStatus,
        pageCount,
        questionCount,
        awardedPoints,
        maxPoints,
        scorePercentage,
        gradingStatus,
        gradingSummary,
        images,
        questions,
      ];
}

class StudentExamResultEntity extends Equatable {
  final int studentId;
  final String studentName;
  final int totalQuestions;
  final int scoredQuestions;
  final double awardedPoints;
  final double maxPoints;
  final double? gradingConfidence;
  final String? gradingStatus;
  final String? gradingSummary;
  final double? scorePercentage;

  const StudentExamResultEntity({
    required this.studentId,
    required this.studentName,
    required this.totalQuestions,
    required this.scoredQuestions,
    required this.awardedPoints,
    required this.maxPoints,
    this.gradingConfidence,
    this.gradingStatus,
    this.gradingSummary,
    this.scorePercentage,
  });

  @override
  List<Object?> get props => [
        studentId,
        studentName,
        totalQuestions,
        scoredQuestions,
        awardedPoints,
        maxPoints,
        gradingConfidence,
        gradingStatus,
        gradingSummary,
        scorePercentage,
      ];
}

class StudentMatchCandidateEntity extends Equatable {
  final int userId;
  final String fullName;

  const StudentMatchCandidateEntity({
    required this.userId,
    required this.fullName,
  });

  @override
  List<Object?> get props => [userId, fullName];
}

class StudentMatchEntity extends Equatable {
  final String? detectedStudentName;
  final double? detectedNameConfidence;
  final int? matchedStudentId;
  final String? matchedStudentName;
  final double? matchingConfidence;
  final String? matchingStatus;
  final List<StudentMatchCandidateEntity> candidateStudents;

  const StudentMatchEntity({
    this.detectedStudentName,
    this.detectedNameConfidence,
    this.matchedStudentId,
    this.matchedStudentName,
    this.matchingConfidence,
    this.matchingStatus,
    this.candidateStudents = const [],
  });

  bool get hasMatchedStudent =>
      matchedStudentId != null &&
      matchedStudentName != null &&
      matchedStudentName!.isNotEmpty;

  @override
  List<Object?> get props => [
        detectedStudentName,
        detectedNameConfidence,
        matchedStudentId,
        matchedStudentName,
        matchingConfidence,
        matchingStatus,
        candidateStudents,
      ];
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

class TeacherQuestionEntity extends Equatable {
  final int id;
  final int pageNumber;
  final int questionOrder;
  final String? sourceQuestionId;
  final String? questionText;
  final String? studentAnswer;
  final double? confidence;
  final String? questionType;
  final String? expectedAnswer;
  final String? gradingRubric;
  final double? maxPoints;
  final double? awardedPoints;
  final double? gradingConfidence;
  final String? gradingStatus;
  final String? evaluationSummary;
  final bool? correct;
  final int? studentId;
  final String? studentName;
  final String? matchingStatus;

  const TeacherQuestionEntity({
    required this.id,
    required this.pageNumber,
    required this.questionOrder,
    this.sourceQuestionId,
    this.questionText,
    this.studentAnswer,
    this.confidence,
    this.questionType,
    this.expectedAnswer,
    this.gradingRubric,
    this.maxPoints,
    this.awardedPoints,
    this.gradingConfidence,
    this.gradingStatus,
    this.evaluationSummary,
    this.correct,
    this.studentId,
    this.studentName,
    this.matchingStatus,
  });

  double get confidencePercent => (confidence ?? 0) * 100;
  double get gradingConfidencePercent => (gradingConfidence ?? 0) * 100;
  double get scorePercent => (maxPoints == null || maxPoints == 0)
      ? 0
      : ((awardedPoints ?? 0) / maxPoints!) * 100;

  @override
  List<Object?> get props => [
        id,
        pageNumber,
        questionOrder,
        sourceQuestionId,
        questionText,
        studentAnswer,
        confidence,
        questionType,
        expectedAnswer,
        gradingRubric,
        maxPoints,
        awardedPoints,
        gradingConfidence,
        gradingStatus,
        evaluationSummary,
        correct,
        studentId,
        studentName,
        matchingStatus,
      ];
}
