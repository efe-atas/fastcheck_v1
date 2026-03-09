import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  final Dio _dio;

  AuthInterceptor({
    required SecureStorage storage,
    required Dio dio,
  })  : _storage = storage,
        _dio = dio;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final noAuthPaths = [
      ApiConstants.login,
      ApiConstants.register,
      ApiConstants.refreshToken,
    ];

    final requiresAuth =
        !noAuthPaths.any((path) => options.path.contains(path));

    if (requiresAuth) {
      final token = await _storage.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshTokenValue = await _storage.refreshToken;
      if (refreshTokenValue == null || refreshTokenValue.isEmpty) {
        await _storage.clearAll();
        handler.next(err);
        return;
      }

      try {
        final response = await _dio.post(
          ApiConstants.refreshToken,
          data: {'refreshToken': refreshTokenValue},
        );

        final newAccessToken = response.data['accessToken'] as String;
        final newRefreshToken = response.data['refreshToken'] as String;

        await _storage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResponse = await _dio.fetch(opts);
        handler.resolve(retryResponse);
      } catch (_) {
        await _storage.clearAll();
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}
