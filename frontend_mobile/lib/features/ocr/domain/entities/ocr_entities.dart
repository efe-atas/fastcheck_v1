import 'package:equatable/equatable.dart';

class OcrResultEntity extends Equatable {
  final String jobId;
  final String requestId;
  final int? userId;
  final String? imageUrl;
  final String? sourceId;
  final DateTime createdAt;
  final dynamic result;

  const OcrResultEntity({
    required this.jobId,
    required this.requestId,
    this.userId,
    this.imageUrl,
    this.sourceId,
    required this.createdAt,
    this.result,
  });

  @override
  List<Object?> get props =>
      [jobId, requestId, userId, imageUrl, sourceId, createdAt, result];
}
