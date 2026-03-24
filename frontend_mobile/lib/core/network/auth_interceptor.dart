import 'dart:async';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

/// 401 sonrası access token yenileme. Sonsuz döngüyü önlemek için:
/// - Yenileme isteğinin kendisi 401 olursa tekrar refresh denenmez.
/// - Aynı istek access yenilendikten sonra en fazla bir kez tekrarlanır (`authRetried`).
/// - Paralel 401’ler tek bir refresh işlemini paylaşır.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorage storage,
    required Dio dio,
  })  : _storage = storage,
        _dio = dio;

  final SecureStorage _storage;
  final Dio _dio;

  static const String _kAuthRetried = 'authRetried';
  static Future<void>? _ongoingRefresh;

  bool _isAuthPath(String path) {
    return path.contains(ApiConstants.login) ||
        path.contains(ApiConstants.register) ||
        path.contains(ApiConstants.refreshToken);
  }

  bool _isRefreshRequest(RequestOptions o) {
    final p = o.path;
    final uriPath = o.uri.path;
    return p == ApiConstants.refreshToken ||
        uriPath == ApiConstants.refreshToken ||
        uriPath.endsWith('/auth/refresh');
  }

  Future<void> _refreshTokensLocked() async {
    if (_ongoingRefresh != null) {
      await _ongoingRefresh;
      return;
    }
    _ongoingRefresh = _executeRefresh();
    try {
      await _ongoingRefresh;
    } finally {
      _ongoingRefresh = null;
    }
  }

  Future<void> _executeRefresh() async {
    final refreshTokenValue = await _storage.refreshToken;
    if (refreshTokenValue == null || refreshTokenValue.isEmpty) {
      throw StateError('no refresh token');
    }
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.refreshToken,
      data: {'refreshToken': refreshTokenValue},
      options: Options(
        extra: {_kAuthRetried: true},
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('empty refresh response');
    }
    final newAccessToken = data['accessToken'] as String?;
    final newRefreshToken = data['refreshToken'] as String?;
    if (newAccessToken == null ||
        newAccessToken.isEmpty ||
        newRefreshToken == null ||
        newRefreshToken.isEmpty) {
      throw StateError('invalid refresh response');
    }
    await _storage.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    );
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuth = !_isAuthPath(options.path);

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
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Refresh endpoint’i başarısız: döngüye girme
    if (_isRefreshRequest(err.requestOptions)) {
      await _storage.clearAll();
      handler.next(err);
      return;
    }

    // Bu istek zaten bir kez yeni token ile denendi; tekrar refresh yok
    if (err.requestOptions.extra[_kAuthRetried] == true) {
      await _storage.clearAll();
      handler.next(err);
      return;
    }

    final refreshTokenValue = await _storage.refreshToken;
    if (refreshTokenValue == null || refreshTokenValue.isEmpty) {
      await _storage.clearAll();
      handler.next(err);
      return;
    }

    try {
      await _refreshTokensLocked();
      final newAccess = await _storage.accessToken;
      if (newAccess == null || newAccess.isEmpty) {
        await _storage.clearAll();
        handler.next(err);
        return;
      }

      final opts = err.requestOptions;
      opts.extra[_kAuthRetried] = true;
      opts.headers['Authorization'] = 'Bearer $newAccess';

      final retryResponse = await _dio.fetch(opts);
      handler.resolve(retryResponse);
    } catch (_) {
      await _storage.clearAll();
      handler.next(err);
    }
  }
}
