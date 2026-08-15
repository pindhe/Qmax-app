import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../constants/app_constants.dart';
import 'api_result.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: ApiException(
            'Unauthorized',
            statusCode: 401,
            isUnauthorized: true,
          ),
        ),
      );
      return;
    }
    handler.next(err);
  }
}

class DioClient {
  DioClient({
    required FlutterSecureStorage secureStorage,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: AppConfig.connectTimeout,
                receiveTimeout: AppConfig.receiveTimeout,
              ),
            ) {
    _dio.interceptors.add(AuthInterceptor(secureStorage));
  }

  final Dio _dio;
  Dio get client => _dio;

  Future<ApiResult<T>> request<T>(
    Future<Response<dynamic>> Function() call,
    T Function(dynamic data) parser,
  ) async {
    try {
      final response = await call();
      return ApiSuccess(parser(response.data));
    } on DioException catch (e) {
      final offline = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout;
      final message = e.response?.data is Map
          ? (e.response?.data['message'] as String? ?? e.message ?? 'Request failed')
          : (e.message ?? 'Request failed');
      return ApiFailure(
        message,
        statusCode: e.response?.statusCode,
        isOffline: offline,
      );
    } catch (e) {
      return ApiFailure(e.toString());
    }
  }
}
