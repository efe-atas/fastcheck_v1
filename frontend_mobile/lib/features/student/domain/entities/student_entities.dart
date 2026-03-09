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
  final int? sourceQuestionId;
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

class PagedResult<T> extends Equatable {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final bool isLast;

  const PagedResult({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.isLast,
  });

  @override
  List<Object?> get props =>
      [content, totalElements, totalPages, currentPage, isLast];
}
