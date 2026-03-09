import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/parent_models.dart';

abstract class ParentRemoteDataSource {
  Future<List<LinkedStudentModel>> getLinkedStudents(int parentUserId);
  Future<List<ParentQuestionModel>> getStudentExamQuestions(
      int studentId, int examId);
}

class ParentRemoteDataSourceImpl implements ParentRemoteDataSource {
  final Dio dio;

  ParentRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<LinkedStudentModel>> getLinkedStudents(int parentUserId) async {
    try {
      final response =
          await dio.get(ApiConstants.adminParentStudents(parentUserId));
      final list = response.data as List;
      return list.map((e) => LinkedStudentModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ServerException(
        message: _extractError(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<ParentQuestionModel>> getStudentExamQuestions(
      int studentId, int examId) async {
    try {
      final response = await dio
          .get(ApiConstants.parentStudentExamQuestions(studentId, examId));
      final list = response.data as List;
      return list.map((e) => ParentQuestionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ServerException(
        message: _extractError(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  String _extractError(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      return data['message']?.toString() ?? 'Bir hata oluştu';
    }
    return 'Bir hata oluştu';
  }
}
