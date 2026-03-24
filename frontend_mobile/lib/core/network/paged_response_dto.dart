import '../domain/paged_result.dart';

/// Backend [EducationDtos.PagedResponse] ile uyumlu sayfalı JSON.
class PagedResponseDto<T> {
  final List<T> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const PagedResponseDto({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory PagedResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return PagedResponseDto(
      items: rawItems
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }

  PagedResult<E> toPagedResult<E>(E Function(T item) map) {
    final next = page + 1 < totalPages;
    return PagedResult(
      content: items.map(map).toList(),
      totalElements: totalElements,
      totalPages: totalPages,
      currentPage: page,
      hasNext: next,
    );
  }
}
