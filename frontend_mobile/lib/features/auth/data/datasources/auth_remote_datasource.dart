import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/auth_models.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  });

  Future<AuthResponseModel> refreshToken(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.register,
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<AuthResponseModel> refreshToken(String refreshToken) async {
    try {
      final response = await dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      return AuthResponseModel.fromJson(response.data);
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
