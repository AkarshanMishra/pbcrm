import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;
  final SecureStorageService _storage = SecureStorageService();

  static String get defaultBaseUrl {
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && !origin.startsWith('null') && !origin.startsWith('file://')) {
          return '$origin/api/v1';
        }
      } catch (_) {}
      return 'http://127.0.0.1:8000/api/v1';
    }
    return 'http://10.196.90.44:8000/api/v1';
  }

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: defaultBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _initCustomUrl();

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final accessToken = await _storage.getAccessToken();
        if (accessToken != null && !options.headers.containsKey('Authorization')) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401 && !error.requestOptions.path.contains('/auth/')) {
          // Attempt automatic Refresh Token rotation
          final refreshToken = await _storage.getRefreshToken();
          if (refreshToken != null) {
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
              final refreshResponse = await refreshDio.post('/auth/token/refresh/', data: {
                'refresh': refreshToken,
              });

              if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
                final newAccess = refreshResponse.data['access'];
                final newRefresh = refreshResponse.data['refresh'] ?? refreshToken;
                await _storage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);

                // Retry original request
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccess';
                final cloneReq = await dio.fetch(opts);
                return handler.resolve(cloneReq);
              }
            } catch (e) {
              await _storage.clearAll();
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> _initCustomUrl() async {
    final custom = await _storage.getServerBaseUrl();
    if (custom != null && custom.isNotEmpty) {
      dio.options.baseUrl = custom;
    }
  }

  Future<void> setBaseUrl(String url) async {
    String cleanUrl = url.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'http://$cleanUrl';
    }
    if (!cleanUrl.endsWith('/api/v1')) {
      if (cleanUrl.endsWith('/')) {
        cleanUrl = '${cleanUrl}api/v1';
      } else {
        cleanUrl = '$cleanUrl/api/v1';
      }
    }
    dio.options.baseUrl = cleanUrl;
    await _storage.saveServerBaseUrl(cleanUrl);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, [
    Object? data,
    Options? options,
  ]) {
    return dio.post<T>(
      path,
      data: data,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, [
    Object? data,
    Options? options,
  ]) {
    return dio.put<T>(
      path,
      data: data,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, [
    Object? data,
    Options? options,
  ]) {
    return dio.patch<T>(
      path,
      data: data,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, [
    Object? data,
    Options? options,
  ]) {
    return dio.delete<T>(
      path,
      data: data,
      options: options,
    );
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}

