import 'package:equatable/equatable.dart';

class LinkedStudentEntity extends Equatable {
  final int userId;
  final String fullName;
  final String email;
  final int? classId;

  const LinkedStudentEntity({
    required this.userId,
    required this.fullName,
    required this.email,
    this.classId,
  });

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.substring(0, fullName.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  List<Object?> get props => [userId, fullName, email, classId];
}

class ParentQuestionEntity extends Equatable {
  final int id;
  final int pageNumber;
  final int questionOrder;
  final String? sourceQuestionId;
  final String? questionText;
  final String? studentAnswer;
  final double confidence;

  const ParentQuestionEntity({
    required this.id,
    required this.pageNumber,
    required this.questionOrder,
    this.sourceQuestionId,
    this.questionText,
    this.studentAnswer,
    required this.confidence,
  });

  int get confidencePercent => (confidence * 100).round();

  @override
  List<Object?> get props => [
        id, pageNumber, questionOrder, sourceQuestionId,
        questionText, studentAnswer, confidence,
      ];
}

class ParentStudentSummaryEntity extends Equatable {
  final int studentId;
  final String fullName;
  final String email;
  final int? classId;
  final int totalExams;
  final int readyExams;
  final int? latestExamId;
  final String? latestExamTitle;
  final String? latestExamStatus;
  final DateTime? latestExamCreatedAt;

  const ParentStudentSummaryEntity({
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

  @override
  List<Object?> get props => [
        studentId,
        fullName,
        email,
        classId,
        totalExams,
        readyExams,
        latestExamId,
        latestExamTitle,
        latestExamStatus,
        latestExamCreatedAt,
      ];
}

class ParentStudentExamEntity extends Equatable {
  final int examId;
  final int classId;
  final String title;
  final String status;
  final DateTime createdAt;

  const ParentStudentExamEntity({
    required this.examId,
    required this.classId,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [examId, classId, title, status, createdAt];
}

class ParentDashboardSummaryEntity extends Equatable {
  final int linkedStudents;
  final List<ParentStudentSummaryEntity> students;

  const ParentDashboardSummaryEntity({
    required this.linkedStudents,
    required this.students,
  });

  bool get hasStudents => linkedStudents > 0;

  @override
  List<Object?> get props => [linkedStudents, students];
}
