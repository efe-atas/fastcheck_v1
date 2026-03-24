import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

/// `flutter run --dart-define=VERBOSE_DIO=true` ile hata ayıklama logları (gövde yok: token sızıntısı riski).
const bool _verboseDioLogs =
    bool.fromEnvironment('VERBOSE_DIO', defaultValue: false);

class ApiClient {
  late final Dio dio;

  ApiClient({required SecureStorage storage}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor(storage: storage, dio: dio));

    if (kDebugMode && _verboseDioLogs) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          logPrint: (obj) => debugPrint('[DIO] $obj'),
        ),
      );
    }
  }
}
