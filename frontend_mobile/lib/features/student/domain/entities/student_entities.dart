import 'package:equatable/equatable.dart';

class StudentExamEntity extends Equatable {
  final int examId;
  final int classId;
  final String title;
  final String status;
  final DateTime createdAt;
  final double? awardedPoints;
  final double? maxPoints;
  final double? scorePercentage;

  const StudentExamEntity({
    required this.examId,
    required this.classId,
    required this.title,
    required this.status,
    required this.createdAt,
    this.awardedPoints,
    this.maxPoints,
    this.scorePercentage,
  });

  @override
  List<Object?> get props => [
        examId,
        classId,
        title,
        status,
        createdAt,
        awardedPoints,
        maxPoints,
        scorePercentage,
      ];
}

class QuestionEntity extends Equatable {
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

  const QuestionEntity({
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

  double get scorePercent =>
      (maxPoints == null || maxPoints == 0)
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
      ];
}

class StudentDashboardSummaryEntity extends Equatable {
  final int totalExams;
  final int readyExams;
  final int processingExams;
  final int draftExams;
  final List<StudentExamEntity> latestExams;

  const StudentDashboardSummaryEntity({
    required this.totalExams,
    required this.readyExams,
    required this.processingExams,
    required this.draftExams,
    required this.latestExams,
  });

  @override
  List<Object?> get props =>
      [totalExams, readyExams, processingExams, draftExams, latestExams];
}
