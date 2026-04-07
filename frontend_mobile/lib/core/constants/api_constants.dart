import 'dart:io' show Platform;

import 'dev_server_override.dart';

class ApiConstants {
  ApiConstants._();

  /// Base API URL. Android emülatörleri host makinesine farklı IP ile gider.
  /// Diğer platformlarda `DevServerOverride` yerel ağ IP’sini çözer.
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android emülatör → host makinesi
      return 'http://10.0.2.2:8080';
    }
    final host = DevServerOverride.baseUrlHost;
    return 'http://$host:8080';
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';

  // Teacher
  static const String teacherClasses = '/v1/teacher/classes';
  static String teacherClassStudents(int classId) =>
      '/v1/teacher/classes/$classId/students';
  static String teacherClassExams(int classId) =>
      '/v1/teacher/classes/$classId/exams';
  static String teacherExamImages(int examId) =>
      '/v1/teacher/exams/$examId/images';
  static String teacherExamStatus(int examId) => '/v1/teacher/exams/$examId';
  static String teacherExamReprocess(int examId) => '/v1/teacher/exams/$examId/reprocess';
  static const String teacherDashboard = '/v1/teacher/dashboard';

  // Student
  static const String studentExams = '/v1/student/exams';
  static String studentExamQuestions(int examId) =>
      '/v1/student/exams/$examId/questions';
  static const String studentDashboard = '/v1/student/dashboard';

  // Parent
  static String parentStudentExamQuestions(int studentId, int examId) =>
      '/v1/parent/students/$studentId/exams/$examId/questions';
  static String parentStudentExams(int studentId) =>
      '/v1/parent/students/$studentId/exams';
  static const String parentDashboard = '/v1/parent/dashboard';

  // Admin
  static const String adminSchools = '/v1/admin/schools';
  static const String adminUsers = '/v1/admin/users';
  static const String adminProvisionUsers = '/auth/admin/users';
  static String adminAssignUser(int userId, int schoolId) =>
      '/v1/admin/users/$userId/schools/$schoolId';
  static const String adminBulkAssignUsersToSchools =
      '/v1/admin/users/schools/bulk';
  static const String adminParentStudentLinks =
      '/v1/admin/parent-student-links';
  static const String adminBulkParentStudentLinks =
      '/v1/admin/parent-student-links/bulk';
  static String adminParentStudents(int parentUserId) =>
      '/v1/admin/parents/$parentUserId/students';

  // Files
  static String fileUrl(String fileName) => '/files/$fileName';

  // OCR (extract için herkese açık http/https imageUrl; yükleme sonrası sunucu URL döner)
  static const String ocrUploadImage = '/v1/ocr/upload-image';
  static const String ocrExtract = '/v1/ocr/extract';
  static const String ocrResults = '/v1/ocr/results';
  static String ocrResult(String jobId) => '/v1/ocr/results/$jobId';
}
