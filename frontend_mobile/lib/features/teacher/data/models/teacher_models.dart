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
  final String? role;
  final String? initialPassword;

  const StudentModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.classId,
    this.role,
    this.initialPassword,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      userId: json['userId'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      classId: json['classId'] as int,
      role: json['role'] as String?,
      initialPassword: json['initialPassword'] as String?,
    );
  }

  StudentEntity toEntity() {
    return StudentEntity(
      userId: userId,
      fullName: fullName,
      email: email,
      classId: classId,
      initialPassword: initialPassword,
    );
  }
}

class ExamImageModel {
  final int imageId;
  final int? examId;
  final int pageOrder;
  final String imageUrl;
  final String status;
  final String? errorMessage;
  final DateTime? processingStartedAt;
  final DateTime? processingCompletedAt;
  final StudentMatchModel? studentMatch;

  const ExamImageModel({
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

  factory ExamImageModel.fromJson(
    Map<String, dynamic> json, {
    int? parentExamId,
  }) {
    return ExamImageModel(
      imageId: json['imageId'] as int? ?? json['id'] as int,
      examId: json['examId'] as int? ?? parentExamId,
      pageOrder: (json['pageOrder'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String? ??
          json['filePath'] as String? ??
          json['fileName'] as String? ??
          '',
      status: json['status'] as String? ?? 'PENDING',
      errorMessage: json['errorMessage'] as String?,
      processingStartedAt: json['processingStartedAt'] != null
          ? DateTime.tryParse(json['processingStartedAt'].toString())
          : null,
      processingCompletedAt: json['processingCompletedAt'] != null
          ? DateTime.tryParse(json['processingCompletedAt'].toString())
          : null,
      studentMatch: json['studentMatch'] is Map<String, dynamic>
          ? StudentMatchModel.fromJson(
              json['studentMatch'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  ExamImageEntity toEntity({int? parentExamId}) {
    return ExamImageEntity(
      imageId: imageId,
      examId: examId ?? parentExamId,
      pageOrder: pageOrder,
      imageUrl: imageUrl,
      status: status,
      errorMessage: errorMessage,
      processingStartedAt: processingStartedAt,
      processingCompletedAt: processingCompletedAt,
      studentMatch: studentMatch?.toEntity(),
    );
  }
}

class StudentMatchCandidateModel {
  final int userId;
  final String fullName;

  const StudentMatchCandidateModel({
    required this.userId,
    required this.fullName,
  });

  factory StudentMatchCandidateModel.fromJson(Map<String, dynamic> json) {
    return StudentMatchCandidateModel(
      userId: json['userId'] as int,
      fullName: json['fullName'] as String,
    );
  }

  StudentMatchCandidateEntity toEntity() {
    return StudentMatchCandidateEntity(
      userId: userId,
      fullName: fullName,
    );
  }
}

class StudentMatchModel {
  final String? detectedStudentName;
  final double? detectedNameConfidence;
  final int? matchedStudentId;
  final String? matchedStudentName;
  final double? matchingConfidence;
  final String? matchingStatus;
  final List<StudentMatchCandidateModel> candidateStudents;

  const StudentMatchModel({
    this.detectedStudentName,
    this.detectedNameConfidence,
    this.matchedStudentId,
    this.matchedStudentName,
    this.matchingConfidence,
    this.matchingStatus,
    this.candidateStudents = const [],
  });

  factory StudentMatchModel.fromJson(Map<String, dynamic> json) {
    return StudentMatchModel(
      detectedStudentName: json['detectedStudentName'] as String?,
      detectedNameConfidence:
          (json['detectedNameConfidence'] as num?)?.toDouble(),
      matchedStudentId: (json['matchedStudentId'] as num?)?.toInt(),
      matchedStudentName: json['matchedStudentName'] as String?,
      matchingConfidence: (json['matchingConfidence'] as num?)?.toDouble(),
      matchingStatus: json['matchingStatus'] as String?,
      candidateStudents: (json['candidateStudents'] as List<dynamic>?)
              ?.map(
                (e) => StudentMatchCandidateModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }

  StudentMatchEntity toEntity() {
    return StudentMatchEntity(
      detectedStudentName: detectedStudentName,
      detectedNameConfidence: detectedNameConfidence,
      matchedStudentId: matchedStudentId,
      matchedStudentName: matchedStudentName,
      matchingConfidence: matchingConfidence,
      matchingStatus: matchingStatus,
      candidateStudents: candidateStudents.map((e) => e.toEntity()).toList(),
    );
  }
}

class OcrJobModel {
  final String jobId;
  final String requestId;
  final String status;
  final int retryCount;
  final String? errorMessage;
  final DateTime? createdAt;

  const OcrJobModel({
    required this.jobId,
    required this.requestId,
    required this.status,
    this.retryCount = 0,
    this.errorMessage,
    this.createdAt,
  });

  factory OcrJobModel.fromJson(Map<String, dynamic> json) {
    final jobRaw = json['jobId'];
    final reqRaw = json['requestId'];
    return OcrJobModel(
      jobId: jobRaw?.toString() ?? '',
      requestId: reqRaw?.toString() ?? '',
      status: json['status'] as String,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  OcrJobEntity toEntity() {
    return OcrJobEntity(
      jobId: jobId,
      requestId: requestId,
      status: status,
      retryCount: retryCount,
      errorMessage: errorMessage,
      createdAt: createdAt,
    );
  }
}

class ExamStatusModel {
  final int examId;
  final int classId;
  final String title;
  final String examStatus;
  final String? gradingSystemSummary;
  final double? totalMaxPoints;
  final List<ExamImageModel> images;
  final List<StudentModel> students;
  final List<OcrJobModel> ocrJobs;
  final int questionCount;
  final List<TeacherQuestionModel> questions;
  final List<TeacherStudentClusterModel> studentClusters;
  final List<StudentExamResultModel> studentResults;

  const ExamStatusModel({
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

  factory ExamStatusModel.fromJson(Map<String, dynamic> json) {
    return ExamStatusModel(
      examId: json['examId'] as int,
      classId: json['classId'] as int,
      title: json['title'] as String,
      examStatus:
          json['examStatus'] as String? ?? json['status'] as String? ?? 'DRAFT',
      gradingSystemSummary: json['gradingSystemSummary'] as String?,
      totalMaxPoints: (json['totalMaxPoints'] as num?)?.toDouble(),
      images: (json['images'] as List<dynamic>?)
              ?.map(
                (e) => ExamImageModel.fromJson(
                  e as Map<String, dynamic>,
                  parentExamId: json['examId'] as int?,
                ),
              )
              .toList() ??
          [],
      students: (json['students'] as List<dynamic>?)
              ?.map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ocrJobs: (json['ocrJobs'] as List<dynamic>?)
              ?.map((e) => OcrJobModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) =>
                  TeacherQuestionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      studentClusters: (json['studentClusters'] as List<dynamic>?)
              ?.map(
                (e) => TeacherStudentClusterModel.fromJson(
                  e as Map<String, dynamic>,
                  parentExamId: json['examId'] as int?,
                ),
              )
              .toList() ??
          [],
      studentResults: (json['studentResults'] as List<dynamic>?)
              ?.map(
                (e) => StudentExamResultModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
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
      gradingSystemSummary: gradingSystemSummary,
      totalMaxPoints: totalMaxPoints,
      images: images.map((e) => e.toEntity(parentExamId: examId)).toList(),
      students: students.map((e) => e.toEntity()).toList(),
      ocrJobs: ocrJobs.map((e) => e.toEntity()).toList(),
      questionCount: questionCount,
      questions: questions.map((e) => e.toEntity()).toList(),
      studentClusters: studentClusters.map((e) => e.toEntity()).toList(),
      studentResults: studentResults.map((e) => e.toEntity()).toList(),
    );
  }
}

class TeacherStudentClusterModel {
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
  final List<ExamImageModel> images;
  final List<TeacherQuestionModel> questions;

  const TeacherStudentClusterModel({
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

  factory TeacherStudentClusterModel.fromJson(
    Map<String, dynamic> json, {
    int? parentExamId,
  }) {
    return TeacherStudentClusterModel(
      studentId: (json['studentId'] as num?)?.toInt(),
      studentName: json['studentName'] as String? ?? 'Bilinmeyen Öğrenci',
      studentEmail: json['studentEmail'] as String?,
      unmatched: json['unmatched'] as bool? ?? false,
      matchingStatus: json['matchingStatus'] as String?,
      pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      awardedPoints: (json['awardedPoints'] as num?)?.toDouble() ?? 0,
      maxPoints: (json['maxPoints'] as num?)?.toDouble() ?? 0,
      scorePercentage: (json['scorePercentage'] as num?)?.toDouble() ?? 0,
      gradingStatus: json['gradingStatus'] as String?,
      gradingSummary: json['gradingSummary'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map(
                (e) => ExamImageModel.fromJson(
                  e as Map<String, dynamic>,
                  parentExamId: parentExamId,
                ),
              )
              .toList() ??
          [],
      questions: (json['questions'] as List<dynamic>?)
              ?.map(
                (e) => TeacherQuestionModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  TeacherStudentClusterEntity toEntity() {
    return TeacherStudentClusterEntity(
      studentId: studentId,
      studentName: studentName,
      studentEmail: studentEmail,
      unmatched: unmatched,
      matchingStatus: matchingStatus,
      pageCount: pageCount,
      questionCount: questionCount,
      awardedPoints: awardedPoints,
      maxPoints: maxPoints,
      scorePercentage: scorePercentage,
      gradingStatus: gradingStatus,
      gradingSummary: gradingSummary,
      images: images.map((e) => e.toEntity()).toList(),
      questions: questions.map((e) => e.toEntity()).toList(),
    );
  }
}

class StudentExamResultModel {
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

  const StudentExamResultModel({
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

  factory StudentExamResultModel.fromJson(Map<String, dynamic> json) {
    return StudentExamResultModel(
      studentId: (json['studentId'] as num).toInt(),
      studentName: json['studentName'] as String,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      scoredQuestions: (json['scoredQuestions'] as num?)?.toInt() ?? 0,
      awardedPoints: (json['awardedPoints'] as num?)?.toDouble() ?? 0,
      maxPoints: (json['maxPoints'] as num?)?.toDouble() ?? 0,
      gradingConfidence: (json['gradingConfidence'] as num?)?.toDouble(),
      gradingStatus: json['gradingStatus'] as String?,
      gradingSummary: json['gradingSummary'] as String?,
      scorePercentage: (json['scorePercentage'] as num?)?.toDouble(),
    );
  }

  StudentExamResultEntity toEntity() {
    return StudentExamResultEntity(
      studentId: studentId,
      studentName: studentName,
      totalQuestions: totalQuestions,
      scoredQuestions: scoredQuestions,
      awardedPoints: awardedPoints,
      maxPoints: maxPoints,
      gradingConfidence: gradingConfidence,
      gradingStatus: gradingStatus,
      gradingSummary: gradingSummary,
      scorePercentage: scorePercentage,
    );
  }
}

class TeacherDashboardSummaryModel {
  final int totalClasses;
  final int totalExams;
  final int processingExams;
  final int readyExams;
  final List<ExamModel> latestExams;
  final List<OcrJobModel> recentOcrJobs;

  const TeacherDashboardSummaryModel({
    required this.totalClasses,
    required this.totalExams,
    required this.processingExams,
    required this.readyExams,
    required this.latestExams,
    required this.recentOcrJobs,
  });

  factory TeacherDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> readList(String key) {
      final raw = json[key];
      if (raw is List<dynamic>) return raw;
      return const [];
    }

    int readInt(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return TeacherDashboardSummaryModel(
      totalClasses: readInt('totalClasses'),
      totalExams: readInt('totalExams'),
      processingExams: readInt('processingExams'),
      readyExams: readInt('readyExams'),
      latestExams: readList('latestExams')
          .map((e) => ExamModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentOcrJobs: readList('recentOcrJobs')
          .map((e) => OcrJobModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  TeacherDashboardSummaryEntity toEntity() {
    return TeacherDashboardSummaryEntity(
      totalClasses: totalClasses,
      totalExams: totalExams,
      processingExams: processingExams,
      readyExams: readyExams,
      latestExams: latestExams.map((e) => e.toEntity()).toList(),
      recentOcrJobs: recentOcrJobs.map((e) => e.toEntity()).toList(),
    );
  }
}

class TeacherQuestionModel {
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

  const TeacherQuestionModel({
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

  factory TeacherQuestionModel.fromJson(Map<String, dynamic> json) {
    return TeacherQuestionModel(
      id: json['id'] as int,
      pageNumber: json['pageNumber'] as int,
      questionOrder: json['questionOrder'] as int,
      sourceQuestionId: json['sourceQuestionId']?.toString(),
      questionText: json['questionText'] as String?,
      studentAnswer: json['studentAnswer'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      questionType: json['questionType'] as String?,
      expectedAnswer: json['expectedAnswer'] as String?,
      gradingRubric: json['gradingRubric'] as String?,
      maxPoints: (json['maxPoints'] as num?)?.toDouble(),
      awardedPoints: (json['awardedPoints'] as num?)?.toDouble(),
      gradingConfidence: (json['gradingConfidence'] as num?)?.toDouble(),
      gradingStatus: json['gradingStatus'] as String?,
      evaluationSummary: json['evaluationSummary'] as String?,
      correct: json['correct'] as bool?,
      studentId: (json['studentId'] as num?)?.toInt(),
      studentName: json['studentName'] as String?,
      matchingStatus: json['matchingStatus'] as String?,
    );
  }

  TeacherQuestionEntity toEntity() {
    return TeacherQuestionEntity(
      id: id,
      pageNumber: pageNumber,
      questionOrder: questionOrder,
      sourceQuestionId: sourceQuestionId,
      questionText: questionText,
      studentAnswer: studentAnswer,
      confidence: confidence,
      questionType: questionType,
      expectedAnswer: expectedAnswer,
      gradingRubric: gradingRubric,
      maxPoints: maxPoints,
      awardedPoints: awardedPoints,
      gradingConfidence: gradingConfidence,
      gradingStatus: gradingStatus,
      evaluationSummary: evaluationSummary,
      correct: correct,
      studentId: studentId,
      studentName: studentName,
      matchingStatus: matchingStatus,
    );
  }
}
