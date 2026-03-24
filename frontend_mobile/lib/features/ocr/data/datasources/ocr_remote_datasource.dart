import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/ocr_models.dart';

abstract class OcrRemoteDataSource {
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
