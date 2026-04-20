import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'production_config.dart';
import 'logger.dart';

/// Comprehensive exception handling with typed exceptions
class ExceptionHandler {
  ExceptionHandler._();

  /// Handle and categorize exceptions
  static Future<T?> handleException<T>(
    Object exception,
    StackTrace? stackTrace, {
    String? context,
    String? operation,
    Map<String, dynamic>? additionalInfo,
    bool rethrow = false,
  }) async {
    final categorizedException = _categorizeException(exception);
    
    // Log the exception
    await _logException(
      categorizedException,
      stackTrace,
      context: context,
      operation: operation,
      additionalInfo: additionalInfo,
    );
    
    // Report to crash reporting service
    await _reportToCrashReporting(
      categorizedException,
      stackTrace,
      context: context,
      operation: operation,
    );
    
    // Handle user notification
    await _notifyUser(categorizedException);
    
    // Perform cleanup if needed
    await _performCleanup(categorizedException);
    
    if (rethrow) {
      rethrow;
    }
    
    return null;
  }

  /// Categorize exception into specific types
  static CategorizedException _categorizeException(Object exception) {
    if (exception is NetworkException) {
      return CategorizedException(
        type: ExceptionType.network,
        originalException: exception,
        message: exception.message,
        isRecoverable: true,
        userMessage: 'Network connection issue. Please check your internet connection and try again.',
        technicalMessage: 'NetworkException: ${exception.message}',
      );
    }
    
    if (exception is SocketException) {
      return CategorizedException(
        type: ExceptionType.network,
        originalException: exception,
        message: exception.message,
        isRecoverable: true,
        userMessage: 'Unable to connect to server. Please check your internet connection.',
        technicalMessage: 'SocketException: ${exception.message}',
      );
    }
    
    if (exception is TimeoutException) {
      return CategorizedException(
        type: ExceptionType.network,
        originalException: exception,
        message: exception.message,
        isRecoverable: true,
        userMessage: 'Request timed out. Please try again.',
        technicalMessage: 'TimeoutException: ${exception.message}',
      );
    }
    
    if (exception is HttpException) {
      return CategorizedException(
        type: ExceptionType.http,
        originalException: exception,
        message: exception.message,
        isRecoverable: _isRecoverableHttpError(exception),
        userMessage: _getHttpUserMessage(exception),
        technicalMessage: 'HttpException: ${exception.message}',
      );
    }
    
    if (exception is FirebaseAuthException) {
      return CategorizedException(
        type: ExceptionType.authentication,
        originalException: exception,
        message: exception.message,
        code: exception.code,
        isRecoverable: _isRecoverableAuthError(exception.code),
        userMessage: _getAuthUserMessage(exception.code),
        technicalMessage: 'FirebaseAuthException: ${exception.code} - ${exception.message}',
      );
    }
    
    if (exception is FirebaseFirestoreException) {
      return CategorizedException(
        type: ExceptionType.database,
        originalException: exception,
        message: exception.message,
        code: exception.code,
        isRecoverable: _isRecoverableFirestoreError(exception.code),
        userMessage: _getFirestoreUserMessage(exception.code),
        technicalMessage: 'FirestoreException: ${exception.code} - ${exception.message}',
      );
    }
    
    if (exception is FirebaseStorageException) {
      return CategorizedException(
        type: ExceptionType.storage,
        originalException: exception,
        message: exception.message,
        code: exception.code,
        isRecoverable: _isRecoverableStorageError(exception.code),
        userMessage: _getStorageUserMessage(exception.code),
        technicalMessage: 'StorageException: ${exception.code} - ${exception.message}',
      );
    }
    
    if (exception is LocationServiceDisabledException) {
      return CategorizedException(
        type: ExceptionType.location,
        originalException: exception,
        message: exception.message,
        isRecoverable: true,
        userMessage: 'Location services are disabled. Please enable location services in your device settings.',
        technicalMessage: 'LocationServiceDisabledException: ${exception.message}',
      );
    }
    
    if (exception is LocationPermissionDeniedException) {
      return CategorizedException(
        type: ExceptionType.location,
        originalException: exception,
        message: exception.message,
        isRecoverable: true,
        userMessage: 'Location permission denied. Please grant location permission to use this feature.',
        technicalMessage: 'LocationPermissionDeniedException: ${exception.message}',
      );
    }
    
    if (exception is GoogleMapsException) {
      return CategorizedException(
        type: ExceptionType.maps,
        originalException: exception,
        message: exception.message,
        isRecoverable: _isRecoverableMapsError(exception),
        userMessage: _getMapsUserMessage(exception),
        technicalMessage: 'GoogleMapsException: ${exception.message}',
      );
    }
    
    if (exception is FormatException) {
      return CategorizedException(
        type: ExceptionType.validation,
        originalException: exception,
        message: exception.message,
        isRecoverable: true,
        userMessage: 'Invalid data format. Please check your input and try again.',
        technicalMessage: 'FormatException: ${exception.message}',
      );
    }
    
    if (exception is StateError) {
      return CategorizedException(
        type: ExceptionType.state,
        originalException: exception,
        message: exception.message,
        isRecoverable: false,
        userMessage: 'An unexpected error occurred. Please restart the app.',
        technicalMessage: 'StateError: ${exception.message}',
      );
    }
    
    if (exception is AssertionError) {
      return CategorizedException(
        type: ExceptionType.assertion,
        originalException: exception,
        message: exception.message,
        isRecoverable: false,
        userMessage: 'A system error occurred. Please restart the app.',
        technicalMessage: 'AssertionError: ${exception.message}',
      );
    }
    
    if (exception is RangeError) {
      return CategorizedException(
        type: ExceptionType.range,
        originalException: exception,
        message: exception.message,
        isRecoverable: true,
        userMessage: 'Invalid value provided. Please check your input and try again.',
        technicalMessage: 'RangeError: ${exception.message}',
      );
    }
    
    // Default case
    return CategorizedException(
      type: ExceptionType.unknown,
      originalException: exception,
      message: exception.toString(),
      isRecoverable: false,
      userMessage: 'An unexpected error occurred. Please try again.',
      technicalMessage: 'Unknown Exception: ${exception.toString()}',
    );
  }

  /// Log exception with appropriate level
  static Future<void> _logException(
    CategorizedException exception,
    StackTrace? stackTrace, {
    String? context,
    String? operation,
    Map<String, dynamic>? additionalInfo,
  }) async {
    final logLevel = _getLogLevel(exception.type);
    
    final logMessage = _buildLogMessage(
      exception,
      stackTrace,
      context: context,
      operation: operation,
      additionalInfo: additionalInfo,
    );
    
    switch (logLevel) {
      case LogLevel.debug:
        Logger.debug(logMessage, name: 'ExceptionHandler');
        break;
      case LogLevel.info:
        Logger.info(logMessage, name: 'ExceptionHandler');
        break;
      case LogLevel.warning:
        Logger.warning(logMessage, name: 'ExceptionHandler');
        break;
      case LogLevel.error:
        Logger.error(logMessage, name: 'ExceptionHandler', error: exception.originalException, stackTrace: stackTrace);
        break;
    }
  }

  /// Report exception to crash reporting service
  static Future<void> _reportToCrashReporting(
    CategorizedException exception,
    StackTrace? stackTrace, {
    String? context,
    String? operation,
  }) async {
    // Only report in production or when crash reporting is enabled
    if (!ProductionConfig.enableCrashReporting) return;
    
    try {
      // This would integrate with the crash reporting service
      // For now, we'll just log it
      Logger.info('Exception reported to crash reporting service', name: 'ExceptionHandler');
    } catch (e) {
      Logger.error('Failed to report exception to crash reporting', error: e, name: 'ExceptionHandler');
    }
  }

  /// Notify user of exception
  static Future<void> _notifyUser(CategorizedException exception) async {
    // Only show user notifications for recoverable exceptions
    if (!exception.isRecoverable) return;
    
    // In a real app, this would show a snackbar, dialog, or notification
    // For now, we'll just log the user message
    Logger.info('User notification: ${exception.userMessage}', name: 'ExceptionHandler');
  }

  /// Perform cleanup after exception
  static Future<void> _performCleanup(CategorizedException exception) async {
    try {
      // Perform cleanup based on exception type
      switch (exception.type) {
        case ExceptionType.network:
          // Clean up network connections, cancel pending requests
          break;
        case ExceptionType.database:
          // Close database connections, clean up transactions
          break;
        case ExceptionType.storage:
          // Clean up file operations
          break;
        case ExceptionType.location:
          // Stop location updates
          break;
        default:
          // General cleanup
          break;
      }
    } catch (e) {
      Logger.error('Failed to perform cleanup after exception', error: e, name: 'ExceptionHandler');
    }
  }

  /// Get appropriate log level for exception type
  static LogLevel _getLogLevel(ExceptionType type) {
    switch (type) {
      case ExceptionType.debug:
        return LogLevel.debug;
      case ExceptionType.validation:
      case ExceptionType.network:
        return LogLevel.warning;
      case ExceptionType.authentication:
      case ExceptionType.database:
      case ExceptionType.storage:
      case ExceptionType.location:
      case ExceptionType.maps:
        return LogLevel.error;
      case ExceptionType.state:
      case ExceptionType.assertion:
      case ExceptionType.range:
      case ExceptionType.http:
      case ExceptionType.unknown:
        return LogLevel.error;
    }
  }

  /// Build comprehensive log message
  static String _buildLogMessage(
    CategorizedException exception,
    StackTrace? stackTrace, {
    String? context,
    String? operation,
    Map<String, dynamic>? additionalInfo,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== EXCEPTION HANDLED ===');
    buffer.writeln('Type: ${exception.type}');
    buffer.writeln('Message: ${exception.message}');
    buffer.writeln('User Message: ${exception.userMessage}');
    buffer.writeln('Technical Message: ${exception.technicalMessage}');
    buffer.writeln('Is Recoverable: ${exception.isRecoverable}');
    
    if (exception.code != null) {
      buffer.writeln('Code: ${exception.code}');
    }
    
    if (context != null) {
      buffer.writeln('Context: $context');
    }
    
    if (operation != null) {
      buffer.writeln('Operation: $operation');
    }
    
    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      buffer.writeln('Additional Info: $additionalInfo');
    }
    
    if (stackTrace != null && !ProductionConfig.isProduction) {
      buffer.writeln('Stack Trace:');
      buffer.writeln(stackTrace.toString());
    }
    
    buffer.writeln('========================');
    
    return buffer.toString();
  }

  /// Check if HTTP error is recoverable
  static bool _isRecoverableHttpError(HttpException exception) {
    // Client errors (4xx) are generally recoverable
    // Server errors (5xx) may be recoverable if temporary
    return true; // Simplified for now
  }

  /// Check if auth error is recoverable
  static bool _isRecoverableAuthError(String? code) {
    if (code == null) return false;
    
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-email':
      case 'weak-password':
        return true;
      case 'too-many-requests':
        return true;
      case 'user-disabled':
      case 'operation-not-allowed':
        return false;
      default:
        return true;
    }
  }

  /// Check if Firestore error is recoverable
  static bool _isRecoverableFirestoreError(String? code) {
    if (code == null) return false;
    
    switch (code) {
      case 'permission-denied':
      case 'not-found':
      case 'already-exists':
        return true;
      case 'unavailable':
      case 'deadline-exceeded':
        return true;
      case 'resource-exhausted':
        return false;
      default:
        return true;
    }
  }

  /// Check if storage error is recoverable
  static bool _isRecoverableStorageError(String? code) {
    if (code == null) return false;
    
    switch (code) {
      case 'object-not-found':
      case 'unauthorized':
      case 'retry-limit-exceeded':
        return true;
      case 'quota-exceeded':
      case 'download-size-exceeded':
        return false;
      default:
        return true;
    }
  }

  /// Check if Maps error is recoverable
  static bool _isRecoverableMapsError(GoogleMapsException exception) {
    // Most Maps errors are recoverable by retrying or showing alternative
    return true;
  }

  /// Get user-friendly HTTP error message
  static String _getHttpUserMessage(HttpException exception) {
    // Return user-friendly message based on HTTP status
    return 'Network error occurred. Please try again.';
  }

  /// Get user-friendly auth error message
  static String _getAuthUserMessage(String? code) {
    if (code == null) return 'Authentication error occurred.';
    
    switch (code) {
      case 'user-not-found':
        return 'User not found. Please check your credentials.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address. Please check your email.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'Email is already in use. Please use a different email.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'user-disabled':
        return 'Account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'Authentication error. Please try again.';
    }
  }

  /// Get user-friendly Firestore error message
  static String _getFirestoreUserMessage(String? code) {
    if (code == null) return 'Database error occurred.';
    
    switch (code) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action.';
      case 'not-found':
        return 'The requested data was not found.';
      case 'already-exists':
        return 'This data already exists.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again.';
      case 'deadline-exceeded':
        return 'Request took too long. Please try again.';
      case 'resource-exhausted':
        return 'Service quota exceeded. Please try again later.';
      default:
        return 'Database error occurred. Please try again.';
    }
  }

  /// Get user-friendly storage error message
  static String _getStorageUserMessage(String? code) {
    if (code == null) return 'Storage error occurred.';
    
    switch (code) {
      case 'object-not-found':
        return 'File not found.';
      case 'unauthorized':
        return 'You don\'t have permission to access this file.';
      case 'retry-limit-exceeded':
        return 'Too many requests. Please try again later.';
      case 'quota-exceeded':
        return 'Storage quota exceeded. Please free up space.';
      case 'download-size-exceeded':
        return 'File is too large to download.';
      default:
        return 'Storage error occurred. Please try again.';
    }
  }

  /// Get user-friendly Maps error message
  static String _getMapsUserMessage(GoogleMapsException exception) {
    return 'Map service error occurred. Please try again.';
  }

  /// Handle specific operation with typed exception handling
  static Future<T?> handleOperation<T>(
    Future<T> Function() operation, {
    String? context,
    String? operationName,
    Map<String, dynamic>? additionalInfo,
    T? defaultValue,
    bool rethrow = false,
  }) async {
    try {
      return await operation();
    } catch (exception, stackTrace) {
      await handleException(
        exception,
        stackTrace,
        context: context,
        operation: operationName,
        additionalInfo: additionalInfo,
        rethrow: rethrow,
      );
      
      return defaultValue;
    }
  }

  /// Handle network operations specifically
  static Future<T?> handleNetworkOperation<T>(
    Future<T> Function() operation, {
    String? context,
    String? operationName,
    Map<String, dynamic>? additionalInfo,
    T? defaultValue,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (exception, stackTrace) {
        attempts++;
        
        if (attempts >= maxRetries) {
          // Final attempt failed, handle the exception
          await handleException(
            exception,
            stackTrace,
            context: context,
            operation: operationName,
            additionalInfo: {
              ...additionalInfo ?? {},
              'attempts': attempts,
              'maxRetries': maxRetries,
            },
          );
          
          return defaultValue;
        } else {
          // Retry after delay
          await Future.delayed(retryDelay);
        }
      }
    }
    
    return defaultValue;
  }

  /// Handle authentication operations specifically
  static Future<T?> handleAuthOperation<T>(
    Future<T> Function() operation, {
    String? context,
    String? operationName,
    Map<String, dynamic>? additionalInfo,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (exception, stackTrace) {
      await handleException(
        exception,
        stackTrace,
        context: context,
        operation: operationName,
        additionalInfo: additionalInfo,
      );
      
      return defaultValue;
    }
  }

  /// Handle database operations specifically
  static Future<T?> handleDatabaseOperation<T>(
    Future<T> Function() operation, {
    String? context,
    String? operationName,
    Map<String, dynamic>? additionalInfo,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (exception, stackTrace) {
      await handleException(
        exception,
        stackTrace,
        context: context,
        operation: operationName,
        additionalInfo: additionalInfo,
      );
      
      return defaultValue;
    }
  }

  /// Handle storage operations specifically
  static Future<T?> handleStorageOperation<T>(
    Future<T> Function() operation, {
    String? context,
    String? operationName,
    Map<String, dynamic>? additionalInfo,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (exception, stackTrace) {
      await handleException(
        exception,
        stackTrace,
        context: context,
        operation: operationName,
        additionalInfo: additionalInfo,
      );
      
      return defaultValue;
    }
  }

  /// Handle location operations specifically
  static Future<T?> handleLocationOperation<T>(
    Future<T> Function() operation, {
    String? context,
    String? operationName,
    Map<String, dynamic>? additionalInfo,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (exception, stackTrace) {
      await handleException(
        exception,
        stackTrace,
        context: context,
        operation: operationName,
        additionalInfo: additionalInfo,
      );
      
      return defaultValue;
    }
  }

  /// Handle maps operations specifically
  static Future<T?> handleMapsOperation<T>(
    Future<T> Function() operation, {
    String? context,
    String? operationName,
    Map<String, dynamic>? additionalInfo,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (exception, stackTrace) {
      await handleException(
        exception,
        stackTrace,
        context: context,
        operation: operationName,
        additionalInfo: additionalInfo,
      );
      
      return defaultValue;
    }
  }
}

/// Categorized exception with detailed information
class CategorizedException {
  final ExceptionType type;
  final Object originalException;
  final String message;
  final String? code;
  final bool isRecoverable;
  final String userMessage;
  final String technicalMessage;
  final DateTime timestamp;

  CategorizedException({
    required this.type,
    required this.originalException,
    required this.message,
    this.code,
    required this.isRecoverable,
    required this.userMessage,
    required this.technicalMessage,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'CategorizedException(type: $type, message: $message, recoverable: $isRecoverable)';
  }
}

/// Exception types for categorization
enum ExceptionType {
  debug,
  validation,
  network,
  http,
  authentication,
  database,
  storage,
  location,
  maps,
  state,
  assertion,
  range,
  unknown,
}

/// Typed exception classes for specific scenarios
class NetworkException implements Exception {
  final String message;
  final String? url;
  final int? statusCode;

  NetworkException(this.message, {this.url, this.statusCode});

  @override
  String toString() => 'NetworkException: $message';
}

class ValidationException implements Exception {
  final String message;
  final String? field;
  final String? value;

  ValidationException(this.message, {this.field, this.value});

  @override
  String toString() => 'ValidationException: $message';
}

class AuthenticationException implements Exception {
  final String message;
  final String? code;
  final String? userId;

  AuthenticationException(this.message, {this.code, this.userId});

  @override
  String toString() => 'AuthenticationException: $message';
}

class DatabaseException implements Exception {
  final String message;
  final String? operation;
  final String? collection;

  DatabaseException(this.message, {this.operation, this.collection});

  @override
  String toString() => 'DatabaseException: $message';
}

class StorageException implements Exception {
  final String message;
  final String? operation;
  final String? path;

  StorageException(this.message, {this.operation, this.path});

  @override
  String toString() => 'StorageException: $message';
}

class LocationException implements Exception {
  final String message;
  final String? operation;
  final double? latitude;
  final double? longitude;

  LocationException(this.message, {this.operation, this.latitude, this.longitude});

  @override
  String toString() => 'LocationException: $message';
}

class MapsException implements Exception {
  final String message;
  final String? operation;
  final String? placeId;

  MapsException(this.message, {this.operation, this.placeId});

  @override
  String toString() => 'MapsException: $message';
}

class ConfigurationException implements Exception {
  final String message;
  final String? configKey;
  final dynamic configValue;

  ConfigurationException(this.message, {this.configKey, this.configValue});

  @override
  String toString() => 'ConfigurationException: $message';
}
