class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({this.message = 'Sunucu hatası', this.statusCode});

  @override
  String toString() => 'ServerException(message: $message, statusCode: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'İnternet bağlantısı yok'});

  @override
  String toString() => 'NetworkException(message: $message)';
}

class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Önbellek hatası'});

  @override
  String toString() => 'CacheException(message: $message)';
}

class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException({this.message = 'Yetkisiz erişim'});

  @override
  String toString() => 'UnauthorizedException(message: $message)';
}
