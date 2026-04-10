import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/ocr_models.dart';

abstract class OcrRemoteDataSource {
  /// Tarayıcıdan gelen yerel dosya yolunu multipart ile yükler; sunucunun döndürdüğü http(s) URL.
  Future<String> uploadImage(String localPath);

  Future<OcrResultModel> extract({
    required String imageUrl,
    String? sourceId,
    String? languageHint,
  });

  Future<List<OcrResultModel>> listMine();

  Future<OcrResultModel> getMine(String jobId);
}

class OcrRemoteDataSourceImpl implements OcrRemoteDataSource {
  final Dio dio;

  OcrRemoteDataSourceImpl({required this.dio});

  /// iOS dosya yolu, Android `content://` URI veya `file://` URI.
  String _pathForXFile(String pathOrUri) {
    if (pathOrUri.startsWith('content://')) {
      return pathOrUri;
    }
    if (pathOrUri.startsWith('file://')) {
      return Uri.parse(pathOrUri).toFilePath();
    }
    return pathOrUri;
  }

  String _uploadFilename(String pathOrUri) {
    final normalized = pathOrUri.replaceAll(r'\', '/');
    final last = normalized.split('/').last;
    if (last.isEmpty || last.length > 128) {
      return 'scan.jpg';
    }
    if (!last.contains('.')) {
      return '$last.jpg';
    }
    return last;
  }

  String _mediaTypeForFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.heic')) {
      return 'image/heic';
    }
    if (lower.endsWith('.heif')) {
      return 'image/heif';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  @override
  Future<String> uploadImage(String localPath) async {
    try {
      final path = _pathForXFile(localPath);
      final bytes = await XFile(path).readAsBytes();
      if (bytes.isEmpty) {
        throw ServerException(message: 'Taranan dosya boş veya okunamadı');
      }
      final name = _uploadFilename(localPath);
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: name,
          contentType: MediaType.parse(_mediaTypeForFilename(name)),
        ),
      });
      final response = await dio.post<Map<String, dynamic>>(
        ApiConstants.ocrUploadImage,
        data: formData,
      );
      final data = response.data;
      final url = data?['imageUrl'] as String?;
      if (url == null || url.isEmpty) {
        throw ServerException(message: 'Yükleme yanıtı geçersiz');
      }
      return url;
    } on DioException catch (e) {
      throw ServerException(
        message: _msg(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<OcrResultModel> extract({
    required String imageUrl,
    String? sourceId,
    String? languageHint,
  }) async {
    try {
      final body = <String, dynamic>{'imageUrl': imageUrl};
      if (sourceId != null && sourceId.isNotEmpty) {
        body['sourceId'] = sourceId;
      }
      if (languageHint != null && languageHint.isNotEmpty) {
        body['languageHint'] = languageHint;
      }
      final response = await dio.post(
        ApiConstants.ocrExtract,
        data: body,
      );
      return OcrResultModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: _msg(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<OcrResultModel>> listMine() async {
    try {
      final response = await dio.get(ApiConstants.ocrResults);
      final list = response.data as List<dynamic>;
      return list
          .map((e) => OcrResultModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: _msg(e),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<OcrResultModel> getMine(String jobId) async {
    try {
      final response = await dio.get(ApiConstants.ocrResult(jobId));
      return OcrResultModel.fromJson(response.data as Map<String, dynamic>);
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
