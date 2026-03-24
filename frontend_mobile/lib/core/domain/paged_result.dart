import 'package:equatable/equatable.dart';

/// Domain katmanı sayfalı liste (API'den gelen [PagedResponseDto] eşlemesi).
class PagedResult<T> extends Equatable {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final bool hasNext;

  const PagedResult({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.hasNext,
  });

  @override
  List<Object?> get props =>
      [content, totalElements, totalPages, currentPage, hasNext];
}
