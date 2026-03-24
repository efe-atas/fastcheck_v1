import '../constants/api_constants.dart';

/// Backend bazen tam URL, bazen `/files/...` yolu döner. [baseUrl] ile birleştirir.
String resolveApiUrl(String urlOrPath) {
  final t = urlOrPath.trim();
  if (t.isEmpty) return ApiConstants.baseUrl;
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  if (t.startsWith('/')) return '${ApiConstants.baseUrl}$t';
  return '${ApiConstants.baseUrl}/$t';
}
