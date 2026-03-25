import 'dart:io' show Platform;

class ApiConstants {
  ApiConstants._();

  /// Geliştirme makinesinin API adresi.
  /// - iOS **simülatör**: varsayılan `127.0.0.1` (Mac’teki backend’e doğrudan gider).
  /// - Fiziksel cihaz: `flutter run --dart-define=DEV_MACHINE_IP=192.168.x.x`
  static const String _devMachineIp = String.fromEnvironment(
    'DEV_MACHINE_IP',
    defaultValue: '127.0.0.1',
  );

  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android emülatör → host makinesi
      return 'http://10.0.2.2:8080';
    }
    return 'http://$_devMachineIp:8080';
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
  static String teacherExamStatus(int examId) =>
      '/v1/teacher/exams/$examId';

  // Student
  static const String studentExams = '/v1/student/exams';
  static String studentExamQuestions(int examId) =>
      '/v1/student/exams/$examId/questions';

  // Parent
  static String parentStudentExamQuestions(int studentId, int examId) =>
      '/v1/parent/students/$studentId/exams/$examId/questions';

  // Admin
  static const String adminSchools = '/v1/admin/schools';
  static String adminAssignUser(int userId, int schoolId) =>
      '/v1/admin/users/$userId/schools/$schoolId';
  static const String adminParentStudentLinks =
      '/v1/admin/parent-student-links';
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
