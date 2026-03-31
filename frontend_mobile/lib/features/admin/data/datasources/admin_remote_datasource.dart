import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/admin_models.dart';

abstract class AdminRemoteDataSource {
  Future<AdminProvisionedUserModel> createUser({
    required String fullName,
    required String email,
    required String role,
    String? password,
    int? schoolId,
    int? classId,
  });
  Future<SchoolModel> createSchool(String schoolName);
  Future<AssignUserToSchoolModel> assignUserToSchool(int userId, int schoolId);
  Future<AdminPagedResultModel<AdminUserSummaryModel>> searchUsers({
    String? role,
    String? query,
    required int page,
    required int size,
  });
  Future<AdminPagedResultModel<AdminSchoolSummaryModel>> searchSchools({
    String? query,
    required int page,
    required int size,
  });
  Future<AdminBulkOperationModel> bulkAssignUsersToSchools({
    required List<int> fileBytes,
    required String fileName,
  });
  Future<ParentStudentLinkModel> linkParentStudent({
    required int parentUserId,
    required int studentUserId,
  });
  Future<AdminBulkOperationModel> bulkLinkParentStudents({
    required List<int> fileBytes,
    required String fileName,
  });
  Future<List<AdminParentStudentViewModel>> listParentStudents(
      int parentUserId);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final Dio dio;

  AdminRemoteDataSourceImpl({required this.dio});

  @override
  Future<AdminProvisionedUserModel> createUser({
    required String fullName,
    required String email,
    required String role,
    String? password,
    int? schoolId,
    int? classId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'fullName': fullName,
        'email': email,
        'role': role,
        'password': password,
        'schoolId': schoolId,
        'classId': classId,
      }..removeWhere(
          (key, value) => value == null || (value is String && value.isEmpty));

      final response = await dio.post(
        ApiConstants.adminProvisionUsers,
        data: payload,
      );
      return AdminProvisionedUserModel.fromJson(
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
  Future<AdminPagedResultModel<AdminUserSummaryModel>> searchUsers({
    String? role,
    String? query,
    required int page,
    required int size,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.adminUsers,
        queryParameters: {
          'role': role,
          'q': query,
          'page': page,
          'size': size,
        }..removeWhere((key, value) => value == null),
      );
      return AdminPagedResultModel.fromJson(
        response.data as Map<String, dynamic>,
        AdminUserSummaryModel.fromJson,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _msg(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<AdminPagedResultModel<AdminSchoolSummaryModel>> searchSchools({
    String? query,
    required int page,
    required int size,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.adminSchools,
        queryParameters: {
          'q': query,
          'page': page,
          'size': size,
        }..removeWhere((key, value) => value == null),
      );
      return AdminPagedResultModel.fromJson(
        response.data as Map<String, dynamic>,
        AdminSchoolSummaryModel.fromJson,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _msg(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<AdminBulkOperationModel> bulkAssignUsersToSchools({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
      });
      final response = await dio.post(
        ApiConstants.adminBulkAssignUsersToSchools,
        data: formData,
      );
      return AdminBulkOperationModel.fromJson(
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
  Future<AdminBulkOperationModel> bulkLinkParentStudents({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
      });
      final response = await dio.post(
        ApiConstants.adminBulkParentStudentLinks,
        data: formData,
      );
      return AdminBulkOperationModel.fromJson(
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
