import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  // ignore: use_super_parameters — statusCode ayrı iletiliyor
  const ServerFailure([String message = 'Sunucu hatası oluştu', int? statusCode])
      : super(message, statusCode: statusCode);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'İnternet bağlantısı bulunamadı']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Önbellek hatası oluştu']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Kimlik doğrulama hatası']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Doğrulama hatası']);
}

class UnauthorizedFailure extends Failure {
  // ignore: use_super_parameters — statusCode: 401 sabit
  const UnauthorizedFailure([String message = 'Oturum süresi doldu'])
      : super(message, statusCode: 401);
}
