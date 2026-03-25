import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/ocr_entities.dart';

abstract class OcrRepository {
  Future<Either<Failure, String>> uploadImage(String localPath);

  Future<Either<Failure, OcrResultEntity>> extract({
    required String imageUrl,
    String? sourceId,
    String? languageHint,
  });

  Future<Either<Failure, List<OcrResultEntity>>> listMine();

  Future<Either<Failure, OcrResultEntity>> getMine(String jobId);
}
