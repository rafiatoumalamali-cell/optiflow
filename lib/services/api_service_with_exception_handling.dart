import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/exception_handler.dart';
import '../utils/production_config.dart';
import '../utils/logger.dart';

/// API service with comprehensive typed exception handling
class ApiServiceWithExceptionHandling {
  final String _baseUrl;
  final Duration _timeout;
  final int _maxRetries;
  final Map<String, String> _defaultHeaders;

  ApiServiceWithExceptionHandling({
    required String baseUrl,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
    Map<String, String>? defaultHeaders,
  }) : _baseUrl = baseUrl,
       _timeout = timeout,
       _maxRetries = maxRetries,
       _defaultHeaders = {
         'Content-Type': 'application/json',
         'Accept': 'application/json',
         ...?defaultHeaders,
       };

  /// Make GET request with typed exception handling
  Future<T> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? decoder,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return ExceptionHandler.handleNetworkOperation<T>(
      () async {
        final response = await _executeRequest(
          'GET',
          endpoint,
          headers: headers,
          timeout: timeout,
          maxRetries: maxRetries,
        );
        
        return _parseResponse<T>(response, decoder);
      },
      context: 'GET request to $endpoint',
      operationName: 'GET $endpoint',
      additionalInfo: {
        'endpoint': endpoint,
        'method': 'GET',
        'timeout': timeout?.inSeconds ?? _timeout.inSeconds,
        'maxRetries': maxRetries ?? _maxRetries,
      },
    );
  }

  /// Make POST request with typed exception handling
  Future<T> post<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    T Function(dynamic)? decoder,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return ExceptionHandler.handleNetworkOperation<T>(
      () async {
        final response = await _executeRequest(
          'POST',
          endpoint,
          headers: headers,
          body: body,
          timeout: timeout,
          maxRetries: maxRetries,
        );
        
        return _parseResponse<T>(response, decoder);
      },
      context: 'POST request to $endpoint',
      operationName: 'POST $endpoint',
      additionalInfo: {
        'endpoint': endpoint,
        'method': 'POST',
        'hasBody': body != null,
        'timeout': timeout?.inSeconds ?? _timeout.inSeconds,
        'maxRetries': maxRetries ?? _maxRetries,
      },
    );
  }

  /// Make PUT request with typed exception handling
  Future<T> put<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    T Function(dynamic)? decoder,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return ExceptionHandler.handleNetworkOperation<T>(
      () async {
        final response = await _executeRequest(
          'PUT',
          endpoint,
          headers: headers,
          body: body,
          timeout: timeout,
          maxRetries: maxRetries,
        );
        
        return _parseResponse<T>(response, decoder);
      },
      context: 'PUT request to $endpoint',
      operationName: 'PUT $endpoint',
      additionalInfo: {
        'endpoint': endpoint,
        'method': 'PUT',
        'hasBody': body != null,
        'timeout': timeout?.inSeconds ?? _timeout.inSeconds,
        'maxRetries': maxRetries ?? _maxRetries,
      },
    );
  }

  /// Make DELETE request with typed exception handling
  Future<T> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? decoder,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return ExceptionHandler.handleNetworkOperation<T>(
      () async {
        final response = await _executeRequest(
          'DELETE',
          endpoint,
          headers: headers,
          timeout: timeout,
          maxRetries: maxRetries,
        );
        
        return _parseResponse<T>(response, decoder);
      },
      context: 'DELETE request to $endpoint',
      operationName: 'DELETE $endpoint',
      additionalInfo: {
        'endpoint': endpoint,
        'method': 'DELETE',
        'timeout': timeout?.inSeconds ?? _timeout.inSeconds,
        'maxRetries': maxRetries ?? _maxRetries,
      },
    );
  }

  /// Make PATCH request with typed exception handling
  Future<T> patch<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    T Function(dynamic)? decoder,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return ExceptionHandler.handleNetworkOperation<T>(
      () async {
        final response = await _executeRequest(
          'PATCH',
          endpoint,
          headers: headers,
          body: body,
          timeout: timeout,
          maxRetries: maxRetries,
        );
        
        return _parseResponse<T>(response, decoder);
      },
      context: 'PATCH request to $endpoint',
      operationName: 'PATCH $endpoint',
      additionalInfo: {
        'endpoint': endpoint,
        'method': 'PATCH',
        'hasBody': body != null,
        'timeout': timeout?.inSeconds ?? _timeout.inSeconds,
        'maxRetries': maxRetries ?? _maxRetries,
      },
    );
  }

  /// Upload file with typed exception handling
  Future<T> uploadFile<T>(
    String endpoint,
    String filePath, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    T Function(dynamic)? decoder,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return ExceptionHandler.handleNetworkOperation<T>(
      () async {
        final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$endpoint'));
        
        // Add headers
        request.headers.addAll({..._defaultHeaders, ...?headers});
        
        // Add file
        final file = await http.MultipartFile.fromPath('file', filePath);
        request.files.add(file);
        
        // Add fields
        if (fields != null) {
          request.fields.addAll(fields!);
        }
        
        final response = await request.send().timeout(
          timeout ?? _timeout,
        );
        
        final responseBody = await http.Response.fromStream(response).timeout(
          timeout ?? _timeout,
        );
        
        return _parseResponse<T>(responseBody, decoder);
      },
      context: 'File upload to $endpoint',
      operationName: 'UPLOAD $endpoint',
      additionalInfo: {
        'endpoint': endpoint,
        'method': 'UPLOAD',
        'filePath': filePath,
        'hasFields': fields != null,
        'timeout': timeout?.inSeconds ?? _timeout.inSeconds,
        'maxRetries': maxRetries ?? _maxRetries,
      },
    );
  }

  /// Execute HTTP request with retry logic
  Future<http.Response> _executeRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
    int? maxRetries,
  }) async {
    final requestHeaders = {..._defaultHeaders, ...?headers};
    final requestTimeout = timeout ?? _timeout;
    final retryCount = maxRetries ?? _maxRetries;
    
    final uri = Uri.parse('$_baseUrl$endpoint');
    
    for (int attempt = 0; attempt < retryCount; attempt++) {
      try {
        Logger.network('Attempting $method $endpoint (attempt ${attempt + 1}/$retryCount)', name: 'ApiService');
        
        http.Response response;
        
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(uri, headers: requestHeaders).timeout(requestTimeout);
            break;
          case 'POST':
            final requestBody = _encodeBody(body);
            response = await http.post(uri, headers: requestHeaders, body: requestBody).timeout(requestTimeout);
            break;
          case 'PUT':
            final requestBody = _encodeBody(body);
            response = await http.put(uri, headers: requestHeaders, body: requestBody).timeout(requestTimeout);
            break;
          case 'DELETE':
            response = await http.delete(uri, headers: requestHeaders).timeout(requestTimeout);
            break;
          case 'PATCH':
            final requestBody = _encodeBody(body);
            response = await http.patch(uri, headers: requestHeaders, body: requestBody).timeout(requestTimeout);
            break;
          default:
            throw HttpException('Unsupported HTTP method: $method');
        }
        
        Logger.network('Successfully completed $method $endpoint (attempt ${attempt + 1})', name: 'ApiService');
        
        return response;
        
      } on SocketException catch (e) {
        Logger.network('SocketException on $method $endpoint (attempt ${attempt + 1}): ${e.message}', name: 'ApiService');
        
        if (attempt == retryCount - 1) {
          // Last attempt, rethrow
          rethrow;
        }
        
        // Wait before retry
        await Future.delayed(Duration(milliseconds: 1000 * (attempt + 1)));
        
      } on TimeoutException catch (e) {
        Logger.network('TimeoutException on $method $endpoint (attempt ${attempt + 1}): ${e.message}', name: 'ApiService');
        
        if (attempt == retryCount - 1) {
          // Last attempt, rethrow
          rethrow;
        }
        
        // Wait before retry
        await Future.delayed(Duration(milliseconds: 1000 * (attempt + 1)));
        
      } on HttpException catch (e) {
        Logger.network('HttpException on $method $endpoint (attempt ${attempt + 1}): ${e.message}', name: 'ApiService');
        
        // Don't retry HTTP errors (4xx)
        if (e.code != null && e.code!.startsWith('4')) {
          rethrow;
        }
        
        if (attempt == retryCount - 1) {
          // Last attempt, rethrow
          rethrow;
        }
        
        // Wait before retry
        await Future.delayed(Duration(milliseconds: 1000 * (attempt + 1)));
        
      } catch (e) {
        Logger.network('Unexpected exception on $method $endpoint (attempt ${attempt + 1}): $e', name: 'ApiService');
        
        if (attempt == retryCount - 1) {
          // Last attempt, rethrow
          rethrow;
        }
        
        // Wait before retry
        await Future.delayed(Duration(milliseconds: 1000 * (attempt + 1)));
      }
    }
    
    // This should never be reached
    throw HttpException('Request failed after $retryCount attempts');
  }

  /// Encode request body
  String? _encodeBody(dynamic body) {
    if (body == null) return null;
    
    if (body is String) {
      return body;
    }
    
    if (body is Map<String, dynamic>) {
      return jsonEncode(body);
    }
    
    return body.toString();
  }

  /// Parse HTTP response with typed exception handling
  T _parseResponse<T>(
    http.Response response,
    T Function(dynamic)? decoder,
  ) {
    final statusCode = response.statusCode;
    final responseBody = response.body;
    
    Logger.network('Response received: $statusCode for ${response.request?.url}', name: 'ApiService');
    
    // Check for success status codes
    if (statusCode >= 200 && statusCode < 300) {
      try {
        if (responseBody.isEmpty) {
          return null as T;
        }
        
        dynamic parsedBody;
        
        try {
          parsedBody = jsonDecode(responseBody);
        } catch (e) {
          // If JSON parsing fails, return raw body
          parsedBody = responseBody;
        }
        
        // Decode to specific type if decoder provided
        if (decoder != null && parsedBody != null) {
          try {
            return decoder!(parsedBody);
          } catch (e) {
            throw ValidationException('Failed to decode response: $e', field: 'response');
          }
        } else {
          return parsedBody as T;
        }
        
      } catch (e) {
        throw ValidationException('Failed to parse success response: $e', field: 'response');
      }
    } else {
      // Handle error responses
      String errorMessage = 'Request failed with status $statusCode';
      dynamic errorBody;
      
      if (responseBody.isNotEmpty) {
        try {
          errorBody = jsonDecode(responseBody);
          errorMessage = errorBody['message'] ?? errorBody['error'] ?? errorMessage;
        } catch (e) {
          // If JSON parsing fails, use raw body
          errorMessage = responseBody;
        }
      }
      
      throw HttpException(errorMessage);
    }
  }

  /// Check connectivity before making request
  Future<bool> _checkConnectivity() async {
    try {
      // This would integrate with connectivity provider
      // For now, we'll just return true
      return true;
    } catch (e) {
      Logger.error('Failed to check connectivity', error: e, name: 'ApiService');
      return false;
    }
  }

  /// Get service status
  Future<Map<String, dynamic>> getServiceStatus() async {
    try {
      final connectivityStatus = await _checkConnectivity();
      
      return {
        'base_url': _baseUrl,
        'timeout': _timeout.inSeconds,
        'max_retries': _maxRetries,
        'default_headers': _defaultHeaders,
        'connectivity_status': connectivityStatus,
        'service_status': 'operational',
      };
    } catch (e) {
      return {
        'base_url': _baseUrl,
        'timeout': _timeout.inSeconds,
        'max_retries': _maxRetries,
        'default_headers': _defaultHeaders,
        'connectivity_status': 'unknown',
        'service_status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Dispose service resources
  void dispose() {
    // Clean up any resources if needed
    Logger.info('ApiService disposed', name: 'ApiService');
  }
}

/// Typed API response wrapper
class ApiResponse<T> {
  final T? data;
  final int statusCode;
  final Map<String, String> headers;
  final String? message;
  final bool success;
  final DateTime timestamp;

  ApiResponse({
    this.data,
    required this.statusCode,
    required this.headers,
    this.message,
    required this.success,
    required this.timestamp,
  });

  factory ApiResponse.success({
    T? data,
    required int statusCode,
    required Map<String, String> headers,
    String? message,
  }) {
    return ApiResponse<T>(
      data: data,
      statusCode: statusCode,
      headers: headers,
      message: message,
      success: true,
      timestamp: DateTime.now(),
    );
  }

  factory ApiResponse.error({
    required int statusCode,
    required Map<String, String> headers,
    required String message,
  }) {
    return ApiResponse<T>(
      statusCode: statusCode,
      headers: headers,
      message: message,
      success: false,
      timestamp: DateTime.now(),
    );
  }

  bool get isSuccess => success;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;

  @override
  String toString() {
    return 'ApiResponse(statusCode: $statusCode, success: $success, message: $message)';
  }
}

/// API configuration class
class ApiConfiguration {
  final String baseUrl;
  final Duration timeout;
  final int maxRetries;
  final Map<String, String> defaultHeaders;
  final bool enableRetry;
  final bool enableLogging;
  final bool enableMetrics;

  const ApiConfiguration({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    this.enableRetry = true,
    this.enableLogging = true,
    this.enableMetrics = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'timeout': timeout.inSeconds,
      'maxRetries': maxRetries,
      'defaultHeaders': defaultHeaders,
      'enableRetry': enableRetry,
      'enableLogging': enableLogging,
      'enableMetrics': enableMetrics,
    };
  }
}
