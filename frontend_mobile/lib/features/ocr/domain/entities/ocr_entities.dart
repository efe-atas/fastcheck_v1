import 'package:equatable/equatable.dart';

class OcrResultEntity extends Equatable {
  final String jobId;
  final String requestId;
  final int? userId;
  final String? imageUrl;
  final String? sourceId;
  final String status;
  final DateTime createdAt;
  final dynamic result;

  const OcrResultEntity({
    required this.jobId,
    required this.requestId,
    this.userId,
    this.imageUrl,
    this.sourceId,
    this.status = 'PENDING',
    required this.createdAt,
    this.result,
  });

  @override
  List<Object?> get props =>
      [jobId, requestId, userId, imageUrl, sourceId, status, createdAt, result];
}
