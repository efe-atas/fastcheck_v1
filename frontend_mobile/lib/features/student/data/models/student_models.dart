import '../../domain/entities/student_entities.dart';

class StudentExamModel {
  final int examId;
  final int classId;
  final String title;
  final String status;
  final String createdAt;
  final double? awardedPoints;
  final double? maxPoints;
  final double? scorePercentage;

  const StudentExamModel({
    required this.examId,
    required this.classId,
    required this.title,
    required this.status,
    required this.createdAt,
    this.awardedPoints,
    this.maxPoints,
    this.scorePercentage,
  });

  factory StudentExamModel.fromJson(Map<String, dynamic> json) {
    return StudentExamModel(
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

  StudentExamEntity toEntity() {
    return StudentExamEntity(
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

class QuestionModel {
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

  const QuestionModel({
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
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
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
    );
  }

  QuestionEntity toEntity() {
    return QuestionEntity(
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

class StudentDashboardSummaryModel {
  final int totalExams;
  final int readyExams;
  final int processingExams;
  final int draftExams;
  final List<StudentExamModel> latestExams;

  const StudentDashboardSummaryModel({
    required this.totalExams,
    required this.readyExams,
    required this.processingExams,
    required this.draftExams,
    required this.latestExams,
  });

  factory StudentDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> latest = json['latestExams'] as List<dynamic>? ?? const [];
    return StudentDashboardSummaryModel(
      totalExams: (json['totalExams'] as num?)?.toInt() ?? 0,
      readyExams: (json['readyExams'] as num?)?.toInt() ?? 0,
      processingExams: (json['processingExams'] as num?)?.toInt() ?? 0,
      draftExams: (json['draftExams'] as num?)?.toInt() ?? 0,
      latestExams: latest
          .map((e) => StudentExamModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  StudentDashboardSummaryEntity toEntity() {
    return StudentDashboardSummaryEntity(
      totalExams: totalExams,
      readyExams: readyExams,
      processingExams: processingExams,
      draftExams: draftExams,
      latestExams: latestExams.map((e) => e.toEntity()).toList(),
    );
  }
}
