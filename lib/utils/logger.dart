import 'dart:developer' as developer;
import 'production_config.dart';

class Logger {
  Logger._();

  static void info(String message, {String? name, Object? error, StackTrace? stackTrace}) {
    if (!ProductionConfig.shouldLog(LogLevel.info)) return;
    
    final sanitizedStackTrace = ProductionConfig.getStackTrace(stackTrace);
    developer.log(message, level: 800, name: name ?? 'Logger', error: error, stackTrace: sanitizedStackTrace);
  }

  static void warning(String message, {String? name, Object? error, StackTrace? stackTrace}) {
    if (!ProductionConfig.shouldLog(LogLevel.warning)) return;
    
    final sanitizedStackTrace = ProductionConfig.getStackTrace(stackTrace);
    developer.log(message, level: 900, name: name ?? 'Logger', error: error, stackTrace: sanitizedStackTrace);
  }

  static void error(String message, {String? name, Object? error, StackTrace? stackTrace}) {
    if (!ProductionConfig.shouldLog(LogLevel.error)) return;
    
    final sanitizedStackTrace = ProductionConfig.getStackTrace(stackTrace);
    developer.log(message, level: 1000, name: name ?? 'Logger', error: error, stackTrace: sanitizedStackTrace);
    
    // In production, also send to crash reporting
    if (ProductionConfig.enableCrashReporting) {
      ProductionErrorHandler.handleError(error ?? Exception(message), stackTrace, context: name);
    }
  }

  static void debug(String message, {String? name, Object? error, StackTrace? stackTrace}) {
    if (!ProductionConfig.shouldLog(LogLevel.debug)) return;
    
    final sanitizedStackTrace = ProductionConfig.getStackTrace(stackTrace);
    developer.log(message, level: 700, name: name ?? 'Logger', error: error, stackTrace: sanitizedStackTrace);
  }

  /// Performance logging
  static void performance(String message, {String? name, Duration? duration}) {
    if (!ProductionConfig.enablePerformanceMonitoring) return;
    
    final fullMessage = duration != null 
        ? 'Performance: $message (${duration.inMilliseconds}ms)'
        : 'Performance: $message';
    
    LogLevel level = LogLevel.info;
    if (duration != null && duration.inMilliseconds > 1000) {
      level = LogLevel.warning;
    }
    if (duration != null && duration.inMilliseconds > 5000) {
      level = LogLevel.error;
    }
    
    if (ProductionConfig.shouldLog(level)) {
      developer.log(fullMessage, level: 800, name: name ?? 'Performance');
    }
  }

  /// Network logging
  static void network(String message, {String? name, LogLevel level = LogLevel.debug}) {
    if (!ProductionConfig.enableNetworkLogging) return;
    
    if (ProductionConfig.shouldLog(level)) {
      developer.log('Network: $message', level: 800, name: name ?? 'Network');
    }
  }

  /// User action logging
  static void userAction(String action, {Map<String, dynamic>? parameters}) {
    if (!ProductionConfig.enableAnalytics) return;
    
    final message = parameters != null 
        ? 'User Action: $action - $parameters'
        : 'User Action: $action';
    
    if (ProductionConfig.shouldLog(LogLevel.info)) {
      developer.log(message, level: 800, name: 'UserAction');
    }
  }

  /// Security event logging
  static void security(String event, {String? severity, Map<String, dynamic>? context}) {
    // Always log security events regardless of build mode
    final message = context != null 
        ? 'Security: $event - $context'
        : 'Security: $event';
    
    LogLevel level = LogLevel.warning;
    if (severity == 'high' || severity == 'critical') {
      level = LogLevel.error;
    }
    
    developer.log(message, level: level == LogLevel.error ? 1000 : 900, name: 'Security');
  }

  /// API logging
  static void api(String endpoint, String method, {int? statusCode, Duration? duration, Object? error}) {
    if (!ProductionConfig.enableNetworkLogging) return;
    
    final message = statusCode != null 
        ? 'API: $method $endpoint - $statusCode (${duration?.inMilliseconds ?? 0}ms)'
        : 'API: $method $endpoint - Error: $error';
    
    LogLevel level = LogLevel.info;
    if (statusCode != null && statusCode >= 400) {
      level = LogLevel.error;
    } else if (error != null) {
      level = LogLevel.error;
    } else if (duration != null && duration.inMilliseconds > 5000) {
      level = LogLevel.warning;
    }
    
    if (ProductionConfig.shouldLog(level)) {
      developer.log(message, level: level == LogLevel.error ? 1000 : 800, name: 'API');
    }
  }

  /// Database operation logging
  static void database(String operation, {String? table, Duration? duration, Object? error}) {
    if (!ProductionConfig.shouldLog(LogLevel.debug)) return;
    
    final message = error != null 
        ? 'Database: $operation - Error: $error'
        : 'Database: $operation${table != null ? ' on $table' : ''} (${duration?.inMilliseconds ?? 0}ms)';
    
    LogLevel level = LogLevel.debug;
    if (error != null) {
      level = LogLevel.error;
    } else if (duration != null && duration.inMilliseconds > 1000) {
      level = LogLevel.warning;
    }
    
    if (ProductionConfig.shouldLog(level)) {
      developer.log(message, level: level == LogLevel.error ? 1000 : 700, name: 'Database');
    }
  }

  /// Cache operation logging
  static void cache(String operation, {String? key, bool? hit, Duration? duration}) {
    if (!ProductionConfig.shouldLog(LogLevel.debug)) return;
    
    final message = hit != null 
        ? 'Cache: $operation${key != null ? ' for $key' : ''} - ${hit ? "HIT" : "MISS"} (${duration?.inMilliseconds ?? 0}ms)'
        : 'Cache: $operation${key != null ? ' for $key' : ''} (${duration?.inMilliseconds ?? 0}ms)';
    
    if (ProductionConfig.shouldLog(LogLevel.debug)) {
      developer.log(message, level: 700, name: 'Cache');
    }
  }

  /// Background task logging
  static void backgroundTask(String task, {String? status, Duration? duration, Object? error}) {
    final message = error != null 
        ? 'Background: $task - Error: $error'
        : 'Background: $task${status != null ? ' - $status' : ''} (${duration?.inMilliseconds ?? 0}ms)';
    
    LogLevel level = LogLevel.info;
    if (error != null) {
      level = LogLevel.error;
    } else if (duration != null && duration.inMilliseconds > 30000) {
      level = LogLevel.warning;
    }
    
    if (ProductionConfig.shouldLog(level)) {
      developer.log(message, level: level == LogLevel.error ? 1000 : 800, name: 'Background');
    }
  }

  /// UI event logging
  static void ui(String event, {String? screen, Map<String, dynamic>? parameters}) {
    if (!ProductionConfig.shouldLog(LogLevel.debug)) return;
    
    final message = parameters != null 
        ? 'UI: $event${screen != null ? ' on $screen' : ''} - $parameters'
        : 'UI: $event${screen != null ? ' on $screen' : ''}';
    
    if (ProductionConfig.shouldLog(LogLevel.debug)) {
      developer.log(message, level: 700, name: 'UI');
    }
  }
}
