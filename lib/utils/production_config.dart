import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'logger.dart';

/// Production configuration utility to remove debug-only behavior
class ProductionConfig {
  ProductionConfig._();

  /// Check if the app is running in production mode
  static bool get isProduction => kReleaseMode;
  
  /// Check if the app is running in development mode
  static bool get isDevelopment => kDebugMode;
  
  /// Check if the app is running in profile mode
  static bool get isProfile => kProfileMode;

  /// Enable debug features only in non-production builds
  static bool get enableDebugFeatures => !isProduction;
  
  /// Enable verbose logging only in development
  static bool get enableVerboseLogging => isDevelopment;
  
  /// Enable performance monitoring in all non-release builds
  static bool get enablePerformanceMonitoring => !kReleaseMode;
  
  /// Enable crash reporting in production
  static bool get enableCrashReporting => isProduction;
  
  /// Enable analytics in production
  static bool get enableAnalytics => isProduction;
  
  /// Enable mock data only in development
  static bool get enableMockData => isDevelopment;
  
  /// Enable debug menus only in development
  static bool get enableDebugMenus => isDevelopment;
  
  /// Enable network logging only in development
  static bool get enableNetworkLogging => isDevelopment;
  
  /// Enable detailed error messages in development
  static bool get enableDetailedErrors => isDevelopment;
  
  /// Enable debug banners only in development
  static bool get enableDebugBanners => isDevelopment;

  /// Get appropriate log level based on build mode
  static LogLevel get logLevel {
    if (isProduction) return LogLevel.error;
    if (isProfile) return LogLevel.warning;
    return LogLevel.debug;
  }

  /// Get appropriate API timeout based on build mode
  static Duration get apiTimeout {
    if (isProduction) return const Duration(seconds: 30);
    if (isProfile) return const Duration(seconds: 20);
    return const Duration(seconds: 10);
  }

  /// Get appropriate retry count based on build mode
  static int get maxRetryCount {
    if (isProduction) return 3;
    if (isProfile) return 2;
    return 1;
  }

  /// Get appropriate cache size based on build mode
  static int get cacheSize {
    if (isProduction) return 100 * 1024 * 1024; // 100MB
    if (isProfile) return 50 * 1024 * 1024; // 50MB
    return 10 * 1024 * 1024; // 10MB
  }

  /// Check if a feature should be enabled based on build mode
  static bool shouldEnableFeature(Feature feature) {
    switch (feature) {
      case Feature.debugMenu:
        return enableDebugMenus;
      case Feature.mockData:
        return enableMockData;
      case Feature.verboseLogging:
        return enableVerboseLogging;
      case Feature.performanceMonitoring:
        return enablePerformanceMonitoring;
      case Feature.crashReporting:
        return enableCrashReporting;
      case Feature.analytics:
        return enableAnalytics;
      case Feature.networkLogging:
        return enableNetworkLogging;
      case Feature.detailedErrors:
        return enableDetailedErrors;
      case Feature.debugBanners:
        return enableDebugBanners;
    }
  }

  /// Get user-friendly error message based on build mode
  static String getErrorMessage(String technicalError) {
    if (isProduction) {
      return 'An error occurred. Please try again.';
    }
    return technicalError;
  }

  /// Get sanitized stack trace based on build mode
  static StackTrace? getStackTrace(StackTrace? stackTrace) {
    if (isProduction) return null;
    return stackTrace;
  }

  /// Log message based on build mode
  static void log(String message, {String? name, LogLevel? level, Object? error, StackTrace? stackTrace}) {
    final logLevel = level ?? LogLevel.info;
    
    if (!shouldLog(logLevel)) return;
    
    switch (logLevel) {
      case LogLevel.debug:
        Logger.debug(message, name: name, error: error, stackTrace: getStackTrace(stackTrace));
        break;
      case LogLevel.info:
        Logger.info(message, name: name, error: error, stackTrace: getStackTrace(stackTrace));
        break;
      case LogLevel.warning:
        Logger.warning(message, name: name, error: error, stackTrace: getStackTrace(stackTrace));
        break;
      case LogLevel.error:
        Logger.error(message, name: name, error: error, stackTrace: getStackTrace(stackTrace));
        break;
    }
  }

  /// Check if we should log at the given level
  static bool shouldLog(LogLevel level) {
    if (isProduction) {
      return level == LogLevel.error;
    }
    return true; // Log everything in non-production
  }

  /// Get appropriate app title based on build mode
  static String getAppTitle() {
    if (isProduction) return 'OptiFlow';
    if (isProfile) return 'OptiFlow (Profile)';
    return 'OptiFlow (Debug)';
  }

  /// Get appropriate app version based on build mode
  static String getAppVersion(String baseVersion) {
    if (isProduction) return baseVersion;
    if (isProfile) return '$baseVersion-profile';
    return '$baseVersion-debug';
  }

  /// Validate configuration for production
  static Map<String, bool> validateProductionConfig() {
    final issues = <String, bool>{};
    
    // Check for debug features in production
    issues['debug_features_disabled'] = !enableDebugFeatures;
    issues['verbose_logging_disabled'] = !enableVerboseLogging;
    issues['debug_banners_disabled'] = !enableDebugBanners;
    issues['mock_data_disabled'] = !enableMockData;
    issues['crash_reporting_enabled'] = enableCrashReporting;
    issues['analytics_enabled'] = enableAnalytics;
    
    // Check for appropriate error handling
    issues['detailed_errors_disabled'] = !enableDetailedErrors;
    issues['network_logging_disabled'] = !enableNetworkLogging;
    
    return issues;
  }

  /// Get configuration summary
  static Map<String, dynamic> getConfigSummary() {
    return {
      'is_production': isProduction,
      'is_development': isDevelopment,
      'is_profile': isProfile,
      'enable_debug_features': enableDebugFeatures,
      'enable_verbose_logging': enableVerboseLogging,
      'enable_performance_monitoring': enablePerformanceMonitoring,
      'enable_crash_reporting': enableCrashReporting,
      'enable_analytics': enableAnalytics,
      'enable_mock_data': enableMockData,
      'enable_debug_menus': enableDebugMenus,
      'enable_network_logging': enableNetworkLogging,
      'enable_detailed_errors': enableDetailedErrors,
      'enable_debug_banners': enableDebugBanners,
      'log_level': logLevel.toString(),
      'api_timeout': apiTimeout.inSeconds,
      'max_retry_count': maxRetryCount,
      'cache_size_mb': cacheSize ~/ (1024 * 1024),
      'app_title': getAppTitle(),
    };
  }

  /// Initialize production configuration
  static void initialize() {
    if (isProduction) {
      // Production-specific initialization
      _initializeProduction();
    } else if (isProfile) {
      // Profile-specific initialization
      _initializeProfile();
    } else {
      // Development-specific initialization
      _initializeDevelopment();
    }
  }

  static void _initializeProduction() {
    log('Initializing production configuration', level: LogLevel.info);
    
    // Ensure debug features are disabled
    assert(!enableDebugFeatures, 'Debug features should be disabled in production');
    assert(!enableVerboseLogging, 'Verbose logging should be disabled in production');
    assert(!enableDebugBanners, 'Debug banners should be disabled in production');
    assert(!enableMockData, 'Mock data should be disabled in production');
    
    // Ensure production features are enabled
    assert(enableCrashReporting, 'Crash reporting should be enabled in production');
    assert(enableAnalytics, 'Analytics should be enabled in production');
    
    log('Production configuration initialized successfully', level: LogLevel.info);
  }

  static void _initializeProfile() {
    log('Initializing profile configuration', level: LogLevel.info);
    
    // Profile mode is for performance testing
    log('Profile configuration initialized successfully', level: LogLevel.info);
  }

  static void _initializeDevelopment() {
    log('Initializing development configuration', level: LogLevel.info);
    
    // Development mode has all features enabled
    log('Development configuration initialized successfully', level: LogLevel.info);
  }

  /// Clean up debug-specific resources
  static void cleanup() {
    if (isProduction) {
      // Clean up any debug-specific resources
      log('Cleaning up debug resources', level: LogLevel.debug);
    }
  }
}

/// Log levels for production configuration
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Features that can be enabled/disabled based on build mode
enum Feature {
  debugMenu,
  mockData,
  verboseLogging,
  performanceMonitoring,
  crashReporting,
  analytics,
  networkLogging,
  detailedErrors,
  debugBanners,
}

/// Production-safe error handler
class ProductionErrorHandler {
  static void handleError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    LogLevel logLevel = LogLevel.error,
  }) {
    // Log the error
    final message = context != null ? 'Error in $context: ${error.toString()}' : error.toString();
    ProductionConfig.log(message, level: logLevel, error: error, stackTrace: stackTrace);
    
    // In production, you might want to send this to a crash reporting service
    if (ProductionConfig.isProduction && ProductionConfig.enableCrashReporting) {
      _sendToCrashReporting(error, stackTrace, context);
    }
  }

  static void _sendToCrashReporting(Object error, StackTrace? stackTrace, String? context) {
    // Implementation would depend on your crash reporting service
    // e.g., Firebase Crashlytics, Sentry, etc.
    ProductionConfig.log('Sending error to crash reporting service', level: LogLevel.debug);
  }
}

/// Production-safe network logging
class ProductionNetworkLogger {
  static void logRequest(
    String url,
    String method, {
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!ProductionConfig.enableNetworkLogging) return;
    
    final message = 'Network Request: $method $url';
    ProductionConfig.log(message, level: LogLevel.debug);
    
    if (headers != null) {
      ProductionConfig.log('Headers: $headers', level: LogLevel.debug);
    }
    
    if (body != null) {
      ProductionConfig.log('Body: $body', level: LogLevel.debug);
    }
  }

  static void logResponse(
    String url,
    int statusCode, {
    Map<String, String>? headers,
    dynamic body,
    Duration? duration,
  }) {
    if (!ProductionConfig.enableNetworkLogging) return;
    
    final message = 'Network Response: $statusCode $url';
    ProductionConfig.log(message, level: LogLevel.debug);
    
    if (duration != null) {
      ProductionConfig.log('Duration: ${duration.inMilliseconds}ms', level: LogLevel.debug);
    }
    
    if (headers != null) {
      ProductionConfig.log('Response Headers: $headers', level: LogLevel.debug);
    }
    
    if (body != null) {
      ProductionConfig.log('Response Body: $body', level: LogLevel.debug);
    }
  }

  static void logError(
    String url,
    Object error, {
    StackTrace? stackTrace,
    Duration? duration,
  }) {
    final message = 'Network Error: $url - $error';
    ProductionConfig.log(message, level: LogLevel.error, error: error, stackTrace: stackTrace);
    
    if (duration != null) {
      ProductionConfig.log('Duration: ${duration.inMilliseconds}ms', level: LogLevel.error);
    }
  }
}

/// Production-safe performance monitoring
class ProductionPerformanceMonitor {
  static void startTimer(String operation) {
    if (!ProductionConfig.enablePerformanceMonitoring) return;
    
    ProductionConfig.log('Performance: Starting timer for $operation', level: LogLevel.debug);
  }

  static void endTimer(String operation, Duration duration) {
    if (!ProductionConfig.enablePerformanceMonitoring) return;
    
    final message = 'Performance: $operation completed in ${duration.inMilliseconds}ms';
    
    LogLevel level = LogLevel.info;
    if (duration.inMilliseconds > 1000) {
      level = LogLevel.warning;
    }
    if (duration.inMilliseconds > 5000) {
      level = LogLevel.error;
    }
    
    ProductionConfig.log(message, level: level);
  }

  static void trackMemoryUsage() {
    if (!ProductionConfig.enablePerformanceMonitoring) return;
    
    // Implementation would depend on platform-specific APIs
    ProductionConfig.log('Performance: Tracking memory usage', level: LogLevel.debug);
  }

  static void trackFrameTime(Duration frameTime) {
    if (!ProductionConfig.enablePerformanceMonitoring) return;
    
    if (frameTime.inMilliseconds > 16) { // 60 FPS = 16.67ms per frame
      ProductionConfig.log(
        'Performance: Slow frame detected: ${frameTime.inMilliseconds}ms',
        level: LogLevel.warning,
      );
    }
  }
}
