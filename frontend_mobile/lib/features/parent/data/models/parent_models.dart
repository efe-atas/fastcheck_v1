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

  const ParentQuestionModel({
    required this.id,
    required this.pageNumber,
    required this.questionOrder,
    this.sourceQuestionId,
    this.questionText,
    this.studentAnswer,
    required this.confidence,
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
    );
  }
}
