import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:tool_bocs/core/api/api_constants.dart';
import 'package:tool_bocs/core/api/api_exception.dart';

/// Singleton HTTP client wrapper using Dio
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio _dio;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 75,
      colors: true,
      printEmojis: true,
    ),
  );

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_loggingInterceptor());
    _dio.interceptors.add(_errorInterceptor());
  }

  /// Get the Dio instance
  Dio get dio => _dio;

  /// Logging interceptor for debugging
  Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.i(
          '🚀 REQUEST[${options.method}] => ${options.uri}\n'
          'Headers: ${options.headers}\n'
          'Data: ${options.data}',
        );
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.i(
          '✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}\n'
          'Data: ${response.data}',
        );
        handler.next(response);
      },
      onError: (error, handler) {
        _logger.e(
          '❌ ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}\n'
          'Message: ${error.message}\n'
          'Data: ${error.response?.data}',
        );
        handler.next(error);
      },
    );
  }

  /// Error interceptor to handle common errors
  Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        final exception = _handleError(error);
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            error: exception,
            type: error.type,
          ),
        );
      },
    );
  }

  /// Handle different types of errors
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException();

      case DioExceptionType.connectionError:
        return NetworkException();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        // Try to extract error message from response
        String message = 'Server error occurred';
        if (data is Map<String, dynamic>) {
          message = data['error'] ??
              data['message'] ??
              data['data']?['message'] ??
              message;
        }

        if (statusCode == 401) {
          return UnauthorizedException(message);
        } else if (statusCode != null &&
            statusCode >= 400 &&
            statusCode < 500) {
          return ValidationException(message);
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(message, statusCode: statusCode);
        }
        return ServerException(message, statusCode: statusCode);

      case DioExceptionType.cancel:
        return ApiException('Request was cancelled');

      case DioExceptionType.badCertificate:
        return ApiException('SSL certificate verification failed');

      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return NetworkException();
        }
        return UnknownException(error.message ?? 'Unknown error occurred');
      default:
        return ApiException(error.message ?? 'An unexpected error occurred');
    }
  }

  /// Set authentication token in headers
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    _logger.i('🔐 Auth token set');
  }

  /// Remove authentication token from headers
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
    _logger.i('🔓 Auth token removed');
  }

  /// Generic GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw e.error ?? UnknownException();
    }
  }

  /// Generic POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw e.error ?? UnknownException();
    }
  }

  /// Generic PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw e.error ?? UnknownException();
    }
  }

  /// Generic PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw e.error ?? UnknownException();
    }
  }

  /// Generic DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw e.error ?? UnknownException();
    }
  }
}
