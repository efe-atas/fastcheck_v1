import '../../domain/entities/student_entities.dart';

class StudentExamModel {
  final int examId;
  final int classId;
  final String title;
  final String status;
  final String createdAt;

  const StudentExamModel({
    required this.examId,
    required this.classId,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  factory StudentExamModel.fromJson(Map<String, dynamic> json) {
    return StudentExamModel(
      examId: json['examId'] as int,
      classId: json['classId'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  StudentExamEntity toEntity() {
    return StudentExamEntity(
      examId: examId,
      classId: classId,
      title: title,
      status: status,
      createdAt: DateTime.parse(createdAt),
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

  const QuestionModel({
    required this.id,
    required this.pageNumber,
    required this.questionOrder,
    this.sourceQuestionId,
    this.questionText,
    this.studentAnswer,
    this.confidence,
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
    );
  }
}
