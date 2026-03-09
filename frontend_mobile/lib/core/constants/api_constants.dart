import 'dart:io' show Platform;

class ApiConstants {
  ApiConstants._();

  static const String _devMachineIp =
      String.fromEnvironment('DEV_MACHINE_IP', defaultValue: '192.168.1.104');

  static String get baseUrl {
    if (Platform.isAndroid) {
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
}
