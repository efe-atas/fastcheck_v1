import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart' show UseCase, NoParams;
import '../entities/ocr_entities.dart';
import '../repositories/ocr_repository.dart';

class OcrExtract extends UseCase<OcrResultEntity, OcrExtractParams> {
  final OcrRepository repository;

  OcrExtract(this.repository);

  @override
  Future<Either<Failure, OcrResultEntity>> call(OcrExtractParams params) {
    return repository.extract(
      imageUrl: params.imageUrl,
      sourceId: params.sourceId,
      languageHint: params.languageHint,
    );
  }
}

class OcrExtractParams extends Equatable {
  final String imageUrl;
  final String? sourceId;
  final String? languageHint;

  const OcrExtractParams({
    required this.imageUrl,
    this.sourceId,
    this.languageHint,
  });

  @override
  List<Object?> get props => [imageUrl, sourceId, languageHint];
}

class OcrListMine extends UseCase<List<OcrResultEntity>, NoParams> {
  final OcrRepository repository;

  OcrListMine(this.repository);

  @override
  Future<Either<Failure, List<OcrResultEntity>>> call(NoParams params) {
    return repository.listMine();
  }
}

class OcrGetMine extends UseCase<OcrResultEntity, String> {
  final OcrRepository repository;

  OcrGetMine(this.repository);

  @override
  Future<Either<Failure, OcrResultEntity>> call(String jobId) {
    return repository.getMine(jobId);
  }
}
