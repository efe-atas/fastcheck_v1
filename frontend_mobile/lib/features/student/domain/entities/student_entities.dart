import 'package:equatable/equatable.dart';

class StudentExamEntity extends Equatable {
  final int examId;
  final int classId;
  final String title;
  final String status;
  final DateTime createdAt;

  const StudentExamEntity({
    required this.examId,
    required this.classId,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [examId, classId, title, status, createdAt];
}

class QuestionEntity extends Equatable {
  final int id;
  final int pageNumber;
  final int questionOrder;
  final String? sourceQuestionId;
  final String? questionText;
  final String? studentAnswer;
  final double? confidence;

  const QuestionEntity({
    required this.id,
    required this.pageNumber,
    required this.questionOrder,
    this.sourceQuestionId,
    this.questionText,
    this.studentAnswer,
    this.confidence,
  });

  @override
  List<Object?> get props => [
        id,
        pageNumber,
        questionOrder,
        sourceQuestionId,
        questionText,
        studentAnswer,
        confidence,
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
