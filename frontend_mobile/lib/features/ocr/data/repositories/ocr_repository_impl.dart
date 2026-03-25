import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/ocr_entities.dart';
import '../../domain/repositories/ocr_repository.dart';
import '../datasources/ocr_remote_datasource.dart';

class OcrRepositoryImpl implements OcrRepository {
  final OcrRemoteDataSource remoteDataSource;

  OcrRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> uploadImage(String localPath) async {
    try {
      final url = await remoteDataSource.uploadImage(localPath);
      return Right(url);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OcrResultEntity>> extract({
    required String imageUrl,
    String? sourceId,
    String? languageHint,
  }) async {
    try {
      final m = await remoteDataSource.extract(
        imageUrl: imageUrl,
        sourceId: sourceId,
        languageHint: languageHint,
      );
      return Right(m.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OcrResultEntity>>> listMine() async {
    try {
      final list = await remoteDataSource.listMine();
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OcrResultEntity>> getMine(String jobId) async {
    try {
      final m = await remoteDataSource.getMine(jobId);
      return Right(m.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
