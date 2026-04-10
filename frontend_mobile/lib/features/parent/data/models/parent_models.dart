import '../../domain/entities/parent_entities.dart';

class LinkedStudentModel {
  final int userId;
  final String fullName;
  final String email;
  final int? classId;

  const LinkedStudentModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.classId,
  });

  factory LinkedStudentModel.fromJson(Map<String, dynamic> json) {
    return LinkedStudentModel(
      userId: json['userId'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      classId: json['classId'] as int?,
    );
  }

  LinkedStudentEntity toEntity() {
    return LinkedStudentEntity(
      userId: userId,
      fullName: fullName,
      email: email,
      classId: classId,
    );
  }
}

class ParentQuestionModel {
  final int id;
  final int pageNumber;
  final int questionOrder;
  final String? sourceQuestionId;
  final String? questionText;
  final String? studentAnswer;
  final double confidence;
  final String? questionType;
  final String? expectedAnswer;
  final String? gradingRubric;
  final double? maxPoints;
  final double? awardedPoints;
  final double? gradingConfidence;
  final String? gradingStatus;
  final String? evaluationSummary;
  final bool? correct;

  const ParentQuestionModel({
    required this.id,
    required this.pageNumber,
    required this.questionOrder,
    this.sourceQuestionId,
    this.questionText,
    this.studentAnswer,
    required this.confidence,
    this.questionType,
    this.expectedAnswer,
    this.gradingRubric,
    this.maxPoints,
    this.awardedPoints,
    this.gradingConfidence,
    this.gradingStatus,
    this.evaluationSummary,
    this.correct,
  });

  factory ParentQuestionModel.fromJson(Map<String, dynamic> json) {
    return ParentQuestionModel(
      id: json['id'] as int,
      pageNumber: json['pageNumber'] as int,
      questionOrder: json['questionOrder'] as int,
      sourceQuestionId: json['sourceQuestionId'] as String?,
      questionText: json['questionText'] as String?,
      studentAnswer: json['studentAnswer'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
      questionType: json['questionType'] as String?,
      expectedAnswer: json['expectedAnswer'] as String?,
      gradingRubric: json['gradingRubric'] as String?,
      maxPoints: (json['maxPoints'] as num?)?.toDouble(),
      awardedPoints: (json['awardedPoints'] as num?)?.toDouble(),
      gradingConfidence: (json['gradingConfidence'] as num?)?.toDouble(),
      gradingStatus: json['gradingStatus'] as String?,
      evaluationSummary: json['evaluationSummary'] as String?,
      correct: json['correct'] as bool?,
    );
  }

  ParentQuestionEntity toEntity() {
    return ParentQuestionEntity(
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
    );
  }
}

class ParentStudentSummaryModel {
  final int studentId;
  final String fullName;
  final String email;
  final int? classId;
  final int totalExams;
  final int readyExams;
  final int? latestExamId;
  final String? latestExamTitle;
  final String? latestExamStatus;
  final String? latestExamCreatedAt;

  const ParentStudentSummaryModel({
    required this.studentId,
    required this.fullName,
    required this.email,
    this.classId,
    required this.totalExams,
    required this.readyExams,
    this.latestExamId,
    this.latestExamTitle,
    this.latestExamStatus,
    this.latestExamCreatedAt,
  });

  factory ParentStudentSummaryModel.fromJson(Map<String, dynamic> json) {
    return ParentStudentSummaryModel(
      studentId: json['studentId'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      classId: json['classId'] as int?,
      totalExams: (json['totalExams'] as num?)?.toInt() ?? 0,
      readyExams: (json['readyExams'] as num?)?.toInt() ?? 0,
      latestExamId: (json['latestExamId'] as num?)?.toInt(),
      latestExamTitle: json['latestExamTitle'] as String?,
      latestExamStatus: json['latestExamStatus'] as String?,
      latestExamCreatedAt: json['latestExamCreatedAt']?.toString(),
    );
  }

  ParentStudentSummaryEntity toEntity() {
    return ParentStudentSummaryEntity(
      studentId: studentId,
      fullName: fullName,
      email: email,
      classId: classId,
      totalExams: totalExams,
      readyExams: readyExams,
      latestExamId: latestExamId,
      latestExamTitle: latestExamTitle,
      latestExamStatus: latestExamStatus,
      latestExamCreatedAt: latestExamCreatedAt != null
          ? DateTime.tryParse(latestExamCreatedAt!)
          : null,
    );
  }
}

class ParentStudentExamModel {
  final int examId;
  final int classId;
  final String title;
  final String status;
  final String createdAt;
  final double? awardedPoints;
  final double? maxPoints;
  final double? scorePercentage;

  const ParentStudentExamModel({
    required this.examId,
    required this.classId,
    required this.title,
    required this.status,
    required this.createdAt,
    this.awardedPoints,
    this.maxPoints,
    this.scorePercentage,
  });

  factory ParentStudentExamModel.fromJson(Map<String, dynamic> json) {
    return ParentStudentExamModel(
      examId: json['examId'] as int,
      classId: json['classId'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
      awardedPoints: (json['awardedPoints'] as num?)?.toDouble(),
      maxPoints: (json['maxPoints'] as num?)?.toDouble(),
      scorePercentage: (json['scorePercentage'] as num?)?.toDouble(),
    );
  }

  ParentStudentExamEntity toEntity() {
    return ParentStudentExamEntity(
      examId: examId,
      classId: classId,
      title: title,
      status: status,
      createdAt: DateTime.parse(createdAt),
      awardedPoints: awardedPoints,
      maxPoints: maxPoints,
      scorePercentage: scorePercentage,
    );
  }
}

class ParentDashboardSummaryModel {
  final int linkedStudents;
  final List<ParentStudentSummaryModel> students;

  const ParentDashboardSummaryModel({
    required this.linkedStudents,
    required this.students,
  });

  factory ParentDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final list = json['students'] as List<dynamic>? ?? const [];
    return ParentDashboardSummaryModel(
      linkedStudents: (json['linkedStudents'] as num?)?.toInt() ?? list.length,
      students: list
          .map((e) => ParentStudentSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  ParentDashboardSummaryEntity toEntity() {
    return ParentDashboardSummaryEntity(
      linkedStudents: linkedStudents,
      students: students.map((e) => e.toEntity()).toList(),
    );
  }
}
