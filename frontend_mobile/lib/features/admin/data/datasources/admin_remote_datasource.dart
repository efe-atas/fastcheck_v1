import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/admin_models.dart';

abstract class AdminRemoteDataSource {
  Future<SchoolModel> createSchool(String schoolName);
  Future<AssignUserToSchoolModel> assignUserToSchool(int userId, int schoolId);
  Future<ParentStudentLinkModel> linkParentStudent({
    required int parentUserId,
    required int studentUserId,
  });
  Future<List<AdminParentStudentViewModel>> listParentStudents(int parentUserId);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final Dio dio;

  AdminRemoteDataSourceImpl({required this.dio});

  @override
  Future<SchoolModel> createSchool(String schoolName) async {
    try {
      final response = await dio.post(
        ApiConstants.adminSchools,
        data: {'schoolName': schoolName},
      );
      return SchoolModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: _msg(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<AssignUserToSchoolModel> assignUserToSchool(
    int userId,
    int schoolId,
  ) async {
    try {
      final response = await dio.post(
        ApiConstants.adminAssignUser(userId, schoolId),
      );
      return AssignUserToSchoolModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _msg(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ParentStudentLinkModel> linkParentStudent({
    required int parentUserId,
    required int studentUserId,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.adminParentStudentLinks,
        data: {
          'parentUserId': parentUserId,
          'studentUserId': studentUserId,
        },
      );
      return ParentStudentLinkModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _msg(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<AdminParentStudentViewModel>> listParentStudents(
    int parentUserId,
  ) async {
    try {
      final response =
          await dio.get(ApiConstants.adminParentStudents(parentUserId));
      final list = response.data as List<dynamic>;
      return list
          .map((e) => AdminParentStudentViewModel.fromJson(
                e as Map<String, dynamic>,
              ))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: _msg(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  String _msg(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      return data['message']?.toString() ?? 'Sunucu hatası';
    }
    return 'Sunucu hatası';
  }
}
