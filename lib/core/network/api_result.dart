sealed class ApiResult<T> {
  const ApiResult();
}

class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);
  final T data;
}

class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.message, {this.statusCode, this.isOffline = false});
  final String message;
  final int? statusCode;
  final bool isOffline;
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.isUnauthorized = false});
  final String message;
  final int? statusCode;
  final bool isUnauthorized;

  @override
  String toString() => message;
}

class PaginatedData<T> {
  const PaginatedData({
    required this.items,
    required this.page,
    required this.lastPage,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int lastPage;
  final int total;

  bool get hasMore => page < lastPage;
}
