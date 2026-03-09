import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Sunucu hatası oluştu', int? statusCode])
      : super(message, statusCode: statusCode);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'İnternet bağlantısı bulunamadı'])
      : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Önbellek hatası oluştu'])
      : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Kimlik doğrulama hatası'])
      : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Doğrulama hatası'])
      : super(message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = 'Oturum süresi doldu'])
      : super(message, statusCode: 401);
}
