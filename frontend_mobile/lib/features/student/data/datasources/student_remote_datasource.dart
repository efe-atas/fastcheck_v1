import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/paged_response_dto.dart';
import '../../../../core/error/exceptions.dart';
import '../models/student_models.dart';

abstract class StudentRemoteDataSource {
  Future<PagedResponseDto<StudentExamModel>> getStudentExams({
    required int page,
    required int size,
    String? examStatus,
  });

  Future<List<QuestionModel>> getExamQuestions({required int examId});

  Future<StudentDashboardSummaryModel> getDashboardSummary();
}

class StudentRemoteDataSourceImpl implements StudentRemoteDataSource {
  final Dio dio;

  StudentRemoteDataSourceImpl({required this.dio});

  @override
  Future<PagedResponseDto<StudentExamModel>> getStudentExams({
    required int page,
    required int size,
    String? examStatus,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (examStatus != null) {
        queryParams['examStatus'] = examStatus;
      }

      final response = await dio.get(
        ApiConstants.studentExams,
        queryParameters: queryParams,
      );

      return PagedResponseDto.fromJson(
        response.data as Map<String, dynamic>,
        StudentExamModel.fromJson,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<QuestionModel>> getExamQuestions({required int examId}) async {
    try {
      final response = await dio.get(
        ApiConstants.studentExamQuestions(examId),
      );

      final list = response.data as List<dynamic>;
      return list
          .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<StudentDashboardSummaryModel> getDashboardSummary() async {
    try {
      final response = await dio.get(ApiConstants.studentDashboard);
      return StudentDashboardSummaryModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      return data['message']?.toString() ??
          data['error']?.toString() ??
          'Bir hata oluştu';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Bağlantı zaman aşımına uğradı';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Sunucuya bağlanılamadı';
    }
    return 'Bir hata oluştu';
  }
}
