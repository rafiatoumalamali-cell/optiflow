import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/production_config.dart';
import '../utils/logger.dart';

/// Production-safe API service that removes debug-only behavior
class ProductionApiService {
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  
  final String _baseUrl;
  final String? _apiKey;
  final Map<String, String> _defaultHeaders;
  
  ProductionApiService({
    required String baseUrl,
    String? apiKey,
    Map<String, String>? defaultHeaders,
  }) : _baseUrl = baseUrl,
       _apiKey = apiKey,
       _defaultHeaders = {
         'Content-Type': 'application/json',
         'Accept': 'application/json',
         if (apiKey != null) 'Authorization': 'Bearer $apiKey',
         ...?defaultHeaders,
       };

  /// Make a GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
    int? maxRetries,
    T Function(dynamic)? decoder,
  }) async {
    return _makeRequest<T>(
      'GET',
      endpoint,
      headers: headers,
      timeout: timeout,
      maxRetries: maxRetries,
      decoder: decoder,
    );
  }

  /// Make a POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
    int? maxRetries,
    T Function(dynamic)? decoder,
  }) async {
    return _makeRequest<T>(
      'POST',
      endpoint,
      headers: headers,
      body: body,
      timeout: timeout,
      maxRetries: maxRetries,
      decoder: decoder,
    );
  }

  /// Make a PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
    int? maxRetries,
    T Function(dynamic)? decoder,
  }) async {
    return _makeRequest<T>(
      'PUT',
      endpoint,
      headers: headers,
      body: body,
      timeout: timeout,
      maxRetries: maxRetries,
      decoder: decoder,
    );
  }

  /// Make a DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
    int? maxRetries,
    T Function(dynamic)? decoder,
  }) async {
    return _makeRequest<T>(
      'DELETE',
      endpoint,
      headers: headers,
      timeout: timeout,
      maxRetries: maxRetries,
      decoder: decoder,
    );
  }

  /// Make a PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
    int? maxRetries,
    T Function(dynamic)? decoder,
  }) async {
    return _makeRequest<T>(
      'PATCH',
      endpoint,
      headers: headers,
      body: body,
      timeout: timeout,
      maxRetries: maxRetries,
      decoder: decoder,
    );
  }

  /// Internal method to make HTTP requests
  Future<ApiResponse<T>> _makeRequest<T>(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
    int? maxRetries,
    T Function(dynamic)? decoder,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final requestHeaders = {..._defaultHeaders, ...?headers};
    final requestTimeout = timeout ?? ProductionConfig.apiTimeout;
    final retryCount = maxRetries ?? ProductionConfig.maxRetryCount;
    
    // Log request start
    Logger.api(endpoint, method, duration: requestTimeout);
    
    // Prepare request body
    String? requestBody;
    if (body != null) {
      if (body is String) {
        requestBody = body;
      } else if (body is Map<String, dynamic>) {
        requestBody = jsonEncode(body);
      } else {
        requestBody = jsonEncode(body);
      }
    }
    
    // Make request with retries
    ApiResponse<T>? lastResponse;
    Exception? lastException;
    
    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
        final stopwatch = Stopwatch()..start();
        
        final response = await _executeRequest(
          method,
          uri,
          requestHeaders,
          requestBody,
          requestTimeout,
        );
        
        stopwatch.stop();
        
        // Log successful response
        Logger.api(endpoint, method, statusCode: response.statusCode, duration: stopwatch.elapsed);
        
        // Parse response
        final apiResponse = await _parseResponse<T>(
          response,
          endpoint,
          method,
          stopwatch.elapsed,
          decoder,
        );
        
        return apiResponse;
        
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        // Log error
        Logger.api(endpoint, method, error: lastException);
        
        // Don't retry on client errors (4xx)
        if (e is ApiException && e.isClientError) {
          break;
        }
        
        // Wait before retry (exponential backoff)
        if (attempt < retryCount) {
          final delay = Duration(milliseconds: 100 * (1 << attempt));
          await Future.delayed(delay);
        }
      }
    }
    
    // All retries failed
    throw lastException ?? ApiException('Request failed after $retryCount retries');
  }

  /// Execute the HTTP request
  Future<http.Response> _executeRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
    Duration timeout,
  ) async {
    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers).timeout(timeout);
      case 'POST':
        return await http.post(uri, headers: headers, body: body).timeout(timeout);
      case 'PUT':
        return await http.put(uri, headers: headers, body: body).timeout(timeout);
      case 'DELETE':
        return await http.delete(uri, headers: headers).timeout(timeout);
      case 'PATCH':
        return await http.patch(uri, headers: headers, body: body).timeout(timeout);
      default:
        throw ApiException('Unsupported HTTP method: $method');
    }
  }

  /// Parse HTTP response
  Future<ApiResponse<T>> _parseResponse<T>(
    http.Response response,
    String endpoint,
    String method,
    Duration duration,
    T Function(dynamic)? decoder,
  ) async {
    final statusCode = response.statusCode;
    final responseBody = response.body;
    
    // Check for success status codes
    if (statusCode >= 200 && statusCode < 300) {
      dynamic parsedBody;
      
      if (responseBody.isNotEmpty) {
        try {
          parsedBody = jsonDecode(responseBody);
        } catch (e) {
          // If JSON parsing fails, return raw body
          parsedBody = responseBody;
        }
      }
      
      // Decode to specific type if decoder provided
      T? decodedData;
      if (decoder != null && parsedBody != null) {
        try {
          decodedData = decoder(parsedBody);
        } catch (e) {
          throw ApiException('Failed to decode response: $e');
        }
      } else {
        decodedData = parsedBody as T?;
      }
      
      return ApiResponse<T>(
        data: decodedData,
        statusCode: statusCode,
        headers: response.headers,
        duration: duration,
        success: true,
      );
    } else {
      // Handle error responses
      String errorMessage = 'Request failed with status $statusCode';
      dynamic errorBody;
      
      if (responseBody.isNotEmpty) {
        try {
          errorBody = jsonDecode(responseBody);
          errorMessage = errorBody['message'] ?? errorBody['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = responseBody;
        }
      }
      
      throw ApiException(
        errorMessage,
        statusCode: statusCode,
        headers: response.headers,
        body: errorBody,
      );
    }
  }

  /// Upload a file
  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    String filePath,
    String fieldName, {
    Map<String, String>? fields,
    Map<String, String>? headers,
    Duration? timeout,
    T Function(dynamic)? decoder,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$endpoint'));
    
    // Add headers
    request.headers.addAll(_defaultHeaders);
    if (headers != null) {
      request.headers.addAll(headers);
    }
    
    // Add file
    final file = await http.MultipartFile.fromPath(fieldName, filePath);
    request.files.add(file);
    
    // Add fields
    if (fields != null) {
      request.fields.addAll(fields);
    }
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final streamedResponse = await request.send().timeout(
        timeout ?? ProductionConfig.apiTimeout,
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();
      
      Logger.api(endpoint, 'POST', statusCode: response.statusCode, duration: stopwatch.elapsed);
      
      return await _parseResponse<T>(
        response,
        endpoint,
        'POST',
        stopwatch.elapsed,
        decoder,
      );
      
    } catch (e) {
      stopwatch.stop();
      Logger.api(endpoint, 'POST', error: e);
      throw ApiException('File upload failed: $e');
    }
  }

  /// Download a file
  Future<void> downloadFile(
    String endpoint,
    String savePath, {
    Map<String, String>? headers,
    Duration? timeout,
    ProgressCallback? onProgress,
  }) async {
    final requestHeaders = {..._defaultHeaders, ...?headers};
    final requestTimeout = timeout ?? ProductionConfig.apiTimeout;
    
    try {
      final request = http.Request('GET', Uri.parse('$_baseUrl$endpoint'));
      request.headers.addAll(requestHeaders);
      
      final streamedResponse = await request.send().timeout(requestTimeout);
      
      if (streamedResponse.statusCode != 200) {
        throw ApiException(
          'Download failed with status ${streamedResponse.statusCode}',
          statusCode: streamedResponse.statusCode,
        );
      }
      
      final contentLength = streamedResponse.contentLength ?? 0;
      final bytes = <int>[];
      int downloadedBytes = 0;
      
      await for (final chunk in streamedResponse.stream) {
        bytes.addAll(chunk);
        downloadedBytes += chunk.length;
        
        if (onProgress != null && contentLength > 0) {
          onProgress(downloadedBytes, contentLength);
        }
      }
      
      // Save file (implementation would depend on file system package)
      // This is a placeholder - you'd use path_provider and dart:io
      Logger.api(endpoint, 'GET', statusCode: 200);
      
    } catch (e) {
      Logger.api(endpoint, 'GET', error: e);
      throw ApiException('Download failed: $e');
    }
  }

  /// Health check
  Future<bool> healthCheck({Duration? timeout}) async {
    try {
      final response = await _executeRequest(
        'GET',
        Uri.parse('$_baseUrl/health'),
        _defaultHeaders,
        null,
        timeout ?? const Duration(seconds: 10),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      Logger.error('Health check failed', error: e);
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
    ProductionConfig.cleanup();
  }
}

/// API response wrapper
class ApiResponse<T> {
  final T? data;
  final int statusCode;
  final Map<String, String> headers;
  final Duration duration;
  final bool success;
  
  ApiResponse({
    this.data,
    required this.statusCode,
    required this.headers,
    required this.duration,
    required this.success,
  });
  
  bool get isSuccess => success;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;
  
  @override
  String toString() {
    return 'ApiResponse(statusCode: $statusCode, success: $success, duration: ${duration.inMilliseconds}ms)';
  }
}

/// API exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, String>? headers;
  final dynamic body;
  
  ApiException(
    this.message, {
    this.statusCode,
    this.headers,
    this.body,
  });
  
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  
  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (statusCode != null) {
      buffer.write(' (status: $statusCode)');
    }
    return buffer.toString();
  }
}

/// Progress callback for file operations
typedef ProgressCallback = void Function(int bytesDownloaded, int totalBytes);
