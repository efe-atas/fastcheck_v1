import '../../domain/entities/ocr_entities.dart';

class OcrResultModel {
  final String jobId;
  final String requestId;
  final int? userId;
  final String? imageUrl;
  final String? sourceId;
  final String status;
  final String createdAt;
  final dynamic result;

  const OcrResultModel({
    required this.jobId,
    required this.requestId,
    this.userId,
    this.imageUrl,
    this.sourceId,
    required this.status,
    required this.createdAt,
    this.result,
  });

  factory OcrResultModel.fromJson(Map<String, dynamic> json) {
    return OcrResultModel(
      jobId: json['jobId']?.toString() ?? '',
      requestId: json['requestId']?.toString() ?? '',
      userId: (json['userId'] as num?)?.toInt(),
      imageUrl: json['imageUrl'] as String?,
      sourceId: json['sourceId'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'].toString(),
      result: json['result'],
    );
  }

  OcrResultEntity toEntity() {
    return OcrResultEntity(
      jobId: jobId,
      requestId: requestId,
      userId: userId,
      imageUrl: imageUrl,
      sourceId: sourceId,
      status: status,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0),
      result: result,
    );
  }
}
