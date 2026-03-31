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

class ParentStudentSummaryModel {
  final int studentId;
  final String fullName;
  final String email;
  final int? classId;
  final int totalExams;
  final int readyExams;
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
      latestExamTitle: latestExamTitle,
      latestExamStatus: latestExamStatus,
      latestExamCreatedAt: latestExamCreatedAt != null
          ? DateTime.tryParse(latestExamCreatedAt!)
          : null,
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
