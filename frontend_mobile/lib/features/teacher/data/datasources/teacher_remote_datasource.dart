import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/paged_response_dto.dart';
import '../../../../core/error/exceptions.dart';
import '../models/teacher_models.dart';

abstract class TeacherRemoteDataSource {
  Future<List<ClassModel>> getClasses();
  Future<TeacherDashboardSummaryModel> getDashboardSummary();
  Future<List<ExamModel>> getClassExams(int classId);
  Future<PagedResponseDto<StudentModel>> getClassStudents(
    int classId, {
    int page = 0,
    int size = 20,
    String? name,
  });
  Future<ClassModel> createClass({
    required String className,
  });
  Future<ExamModel> createExam({required int classId, required String title});
  Future<List<ExamImageModel>> uploadExamImages({
    required int examId,
    required List<File> images,
  });
  Future<ExamStatusModel> getExamStatus(int examId);
  Future<StudentModel> addStudentToClass({
    required int classId,
    required String fullName,
    required String email,
    required String password,
  });
}

class TeacherRemoteDataSourceImpl implements TeacherRemoteDataSource {
  final Dio dio;

  const TeacherRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ClassModel>> getClasses() async {
    try {
      final response = await dio.get(ApiConstants.teacherClasses);
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ClassModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message']?.toString() ?? 'Sunucu hatası',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<TeacherDashboardSummaryModel> getDashboardSummary() async {
    try {
      final response = await dio.get(ApiConstants.teacherDashboard);
      return TeacherDashboardSummaryModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message']?.toString() ?? 'Sunucu hatası',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<ExamModel>> getClassExams(int classId) async {
    try {
      final response = await dio.get(ApiConstants.teacherClassExams(classId));
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ExamModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message']?.toString() ?? 'Sunucu hatası',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<PagedResponseDto<StudentModel>> getClassStudents(
    int classId, {
    int page = 0,
    int size = 20,
    String? name,
  }) async {
    try {
      final query = <String, dynamic>{'page': page, 'size': size};
      if (name != null && name.trim().isNotEmpty) {
        query['name'] = name.trim();
      }
      final response = await dio.get(
        ApiConstants.teacherClassStudents(classId),
        queryParameters: query,
      );
      return PagedResponseDto.fromJson(
        response.data as Map<String, dynamic>,
        StudentModel.fromJson,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message']?.toString() ?? 'Sunucu hatası',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ClassModel> createClass({
    required String className,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.teacherClasses,
        data: {'className': className},
      );
      return ClassModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message']?.toString() ?? 'Sunucu hatası',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ExamModel> createExam({
    required int classId,
    required String title,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.teacherClassExams(classId),
        data: {'title': title},
      );
      return ExamModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message']?.toString() ?? 'Sunucu hatası',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<ExamImageModel>> uploadExamImages({
    required int examId,
    required List<File> images,
  }) async {
    try {
      final formData = FormData();
      for (final image in images) {
        formData.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(
            image.path,
            filename: image.path.split('/').last,
          ),
        ));
      }
      final response = await dio.post(
        ApiConstants.teacherExamImages(examId),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final resExamId = data['examId'] as int? ?? examId;
        final rawList = data['images'] as List<dynamic>? ?? [];
        return rawList
            .map(
              (e) => ExamImageModel.fromJson(
                e as Map<String, dynamic>,
                parentExamId: resExamId,
              ),
            )
            .toList();
      }
      if (data is List<dynamic>) {
        return data
            .map(
              (e) => ExamImageModel.fromJson(
                e as Map<String, dynamic>,
                parentExamId: examId,
              ),
            )
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message']?.toString() ?? 'Yükleme hatası',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ExamStatusModel> getExamStatus(int examId) async {
    try {
      final response = await dio.get(ApiConstants.teacherExamStatus(examId));
      return ExamStatusModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message']?.toString() ?? 'Sunucu hatası',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<StudentModel> addStudentToClass({
    required int classId,
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.teacherClassStudents(classId),
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
        },
      );
      return StudentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message']?.toString() ?? 'Sunucu hatası',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
