import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../error/exceptions.dart';

/// API client wrapper around Dio for making HTTP requests
class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    return dio;
  }

  /// Performs a GET request to the specified [path]
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Performs a POST request to the specified [path]
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Converts DioException to app-specific exceptions
  AppException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'انتهت مهلة الاتصال. يرجى المحاولة مجدداً.',
        );
      case DioExceptionType.connectionError:
        if (e.error is SocketException) {
          return const NetworkException(
            message: 'لا يوجد اتصال بالإنترنت.',
          );
        }
        return const NetworkException();
      case DioExceptionType.badResponse:
        return _handleBadResponse(e.response);
      case DioExceptionType.cancel:
        return const AppException(message: 'تم إلغاء الطلب.');
      default:
        return const ServerException(
          message: 'حدث خطأ غير متوقع.',
        );
    }
  }

  /// Handles HTTP error responses
  AppException _handleBadResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode ?? 500;
    final data = response?.data;

    String message = 'حدث خطأ في الخادم.';
    if (data is Map<String, dynamic>) {
      message = data['message'] as String? ?? message;
    }

    switch (statusCode) {
      case 401:
        return AuthenticationException(message: message);
      case 422:
        final errors = data is Map<String, dynamic>
            ? (data['errors'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(
                  key,
                  (value as List).map((e) => e.toString()).toList(),
                ),
              )
            : null;
        return ValidationException(message: message, errors: errors);
      case 404:
        return ServerException(
          message: 'البيانات المطلوبة غير موجودة.',
          statusCode: statusCode,
        );
      case 500:
      case 502:
      case 503:
        return ServerException(
          message: 'الخادم غير متاح حالياً. يرجى المحاولة لاحقاً.',
          statusCode: statusCode,
        );
      default:
        return ServerException(message: message, statusCode: statusCode);
    }
  }

  /// Sets authorization token for authenticated requests
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Removes authorization token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
