import 'package:dio/dio.dart';

import '../core/config/app_config.dart';
import '../core/network/api_result.dart';
import '../core/network/dio_client.dart';

class ApiService {
  ApiService(this._client);

  final DioClient _client;

  Dio get dio => _client.client;

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic data) parser,
  }) {
    return _client.request(
      () => dio.get(path, queryParameters: query),
      parser,
    );
  }

  Future<ApiResult<T>> post<T>(
    String path, {
    Object? data,
    required T Function(dynamic data) parser,
  }) {
    return _client.request(() => dio.post(path, data: data), parser);
  }

  Future<ApiResult<T>> put<T>(
    String path, {
    Object? data,
    required T Function(dynamic data) parser,
  }) {
    return _client.request(() => dio.put(path, data: data), parser);
  }

  Future<ApiResult<T>> delete<T>(
    String path, {
    required T Function(dynamic data) parser,
  }) {
    return _client.request(() => dio.delete(path), parser);
  }

  bool get isMock => AppConfig.useMockData;
}
