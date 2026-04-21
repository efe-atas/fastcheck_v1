import '../constants/api_constants.dart';

/// Backend bazen tam URL, bazen `/files/...` yolu döner. [baseUrl] ile birleştirir.
String resolveApiUrl(String urlOrPath) {
  final t = urlOrPath.trim();
  if (t.isEmpty) return ApiConstants.baseUrl;
  if (t.startsWith('http://') || t.startsWith('https://')) {
    return _remapLoopbackUrlIfNeeded(t);
  }
  if (t.startsWith('/')) return '${ApiConstants.baseUrl}$t';
  return '${ApiConstants.baseUrl}/$t';
}

String _remapLoopbackUrlIfNeeded(String absoluteUrl) {
  final incoming = Uri.tryParse(absoluteUrl);
  final base = Uri.tryParse(ApiConstants.baseUrl);
  if (incoming == null || base == null) {
    return absoluteUrl;
  }

  if (!_isLoopbackHost(incoming.host) || _isLoopbackHost(base.host)) {
    return absoluteUrl;
  }

  return incoming
      .replace(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: _resolveRemappedPath(incoming.path, base.path),
      )
      .toString();
}

String _resolveRemappedPath(String incomingPath, String basePath) {
  if (basePath.isEmpty || basePath == '/') {
    return incomingPath;
  }
  if (incomingPath == basePath || incomingPath.startsWith('$basePath/')) {
    return incomingPath;
  }
  final normalizedBasePath = basePath.endsWith('/')
      ? basePath.substring(0, basePath.length - 1)
      : basePath;
  final normalizedIncomingPath = incomingPath.startsWith('/')
      ? incomingPath
      : '/$incomingPath';
  return '$normalizedBasePath$normalizedIncomingPath';
}

bool _isLoopbackHost(String host) {
  final normalized = host.trim().toLowerCase();
  return normalized == 'localhost' ||
      normalized == '127.0.0.1' ||
      normalized == '0.0.0.0' ||
      normalized == '::1';
}
