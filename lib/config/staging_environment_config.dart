import 'package:flutter/foundation.dart';
import '../utils/production_config.dart';

/// Staging environment configuration
class StagingEnvironmentConfig {
  StagingEnvironmentConfig._();

  // Staging API endpoints
  static const String _stagingApiBaseUrl = 'https://staging-api.optiflow.app/api/v1';
  static const String _stagingWebSocketUrl = 'wss://staging-api.optiflow.app/ws';
  static const String _stagingCdnUrl = 'https://staging-cdn.optiflow.app';
  static const String _stagingAnalyticsUrl = 'https://staging-analytics.optiflow.app';
  
  // Staging API keys
  static const String _stagingMapsApiKey = 'AIzaSyCFZJVmX7G2F8bdjf-cxEn6Eo-nSsHZ4Ow'; // Staging key
  static const String _stagingCrashlyticsKey = ''; // Staging crashlytics key
  static const String _stagingAnalyticsKey = ''; // Staging analytics key
  
  // Staging timeouts and limits
  static const Duration _stagingApiTimeout = Duration(seconds: 20);
  static const Duration _stagingConnectTimeout = Duration(seconds: 8);
  static const Duration _stagingReceiveTimeout = Duration(seconds: 15);
  static const int _stagingMaxRetries = 2;
  static const int _stagingRetryDelay = 500; // milliseconds
  static const int _stagingMaxConnections = 5;
  
  // Staging cache settings
  static const int _stagingCacheSize = 50 * 1024 * 1024; // 50MB
  static const Duration _stagingCacheExpiry = Duration(hours: 12);
  static const int _stagingMaxCacheEntries = 5000;
  
  // Staging database settings
  static const int _stagingDbConnectionPoolSize = 10;
  static const Duration _stagingDbTimeout = Duration(seconds: 10);
  static const int _stagingDbMaxConnections = 25;
  
  // Staging security settings
  static const bool _stagingRequireHttps = true;
  static const bool _stagingValidateCertificates = true;
  static const int _stagingSessionTimeout = 60; // minutes
  static const int _stagingMaxLoginAttempts = 10;
  static const Duration _stagingLockoutDuration = Duration(minutes: 5);
  
  // Staging feature flags
  static const bool _stagingEnableAnalytics = true;
  static const bool _stagingEnableCrashReporting = true;
  static const bool _stagingEnablePerformanceMonitoring = true;
  static const bool _stagingEnableRemoteConfig = true;
  static const bool _stagingEnableABTesting = true;
  
  // Staging logging settings
  static const bool _stagingEnableLogging = true;
  static const bool _stagingEnableErrorLogging = true;
  static const bool _stagingEnablePerformanceLogging = true;
  static const bool _stagingEnableNetworkLogging = true;
  static const bool _stagingEnableUserActionLogging = true;
  
  // Staging monitoring settings
  static const Duration _stagingHealthCheckInterval = Duration(minutes: 2);
  static const Duration _stagingMetricsCollectionInterval = Duration(seconds: 30);
  static const Duration _stagingPerformanceReportInterval = Duration(minutes: 30);
  static const int _stagingMaxErrorReportsPerHour = 200;
  
  // Staging notification settings
  static const bool _stagingEnablePushNotifications = true;
  static const bool _stagingEnableEmailNotifications = true;
  static const bool _stagingEnableSmsNotifications = true;
  static const int _stagingMaxNotificationsPerDay = 100;
  
  // Staging file upload settings
  static const int _stagingMaxFileSize = 20 * 1024 * 1024; // 20MB
  static const int _stagingMaxTotalUploadSize = 200 * 1024 * 1024; // 200MB
  static const List<String> _stagingAllowedFileTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'application/pdf',
    'text/csv',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/json',
    'text/plain',
  ];
  
  // Staging rate limiting
  static const int _stagingMaxRequestsPerMinute = 500;
  static const int _stagingMaxRequestsPerHour = 5000;
  static const int _stagingMaxRequestsPerDay = 50000;
  static const Duration _stagingRateLimitWindow = Duration(minutes: 1);
  
  // Staging backup settings
  static const bool _stagingEnableAutoBackup = true;
  static const Duration _stagingBackupInterval = Duration(hours: 4);
  static const int _stagingMaxBackupRetainCount = 15;
  static const bool _stagingEnableIncrementalBackup = true;
  
  // Staging maintenance settings
  static const List<int> _stagingMaintenanceWindows = [3, 15]; // 3 AM and 3 PM UTC
  static const Duration _stagingMaintenanceDuration = Duration(minutes: 45);
  static const bool _stagingEnableMaintenanceMode = false;
  
  // Getters for staging configuration
  static String get apiBaseUrl => _stagingApiBaseUrl;
  static String get webSocketUrl => _stagingWebSocketUrl;
  static String get cdnUrl => _stagingCdnUrl;
  static String get analyticsUrl => _stagingAnalyticsUrl;
  
  static String get mapsApiKey => _stagingMapsApiKey;
  static String get crashlyticsKey => _stagingCrashlyticsKey;
  static String get analyticsKey => _stagingAnalyticsKey;
  
  static Duration get apiTimeout => _stagingApiTimeout;
  static Duration get connectTimeout => _stagingConnectTimeout;
  static Duration get receiveTimeout => _stagingReceiveTimeout;
  static int get maxRetries => _stagingMaxRetries;
  static int get retryDelay => _stagingRetryDelay;
  static int get maxConnections => _stagingMaxConnections;
  
  static int get cacheSize => _stagingCacheSize;
  static Duration get cacheExpiry => _stagingCacheExpiry;
  static int get maxCacheEntries => _stagingMaxCacheEntries;
  
  static int get dbConnectionPoolSize => _stagingDbConnectionPoolSize;
  static Duration get dbTimeout => _stagingDbTimeout;
  static int get dbMaxConnections => _stagingDbMaxConnections;
  
  static bool get requireHttps => _stagingRequireHttps;
  static bool get validateCertificates => _stagingValidateCertificates;
  static int get sessionTimeout => _stagingSessionTimeout;
  static int get maxLoginAttempts => _stagingMaxLoginAttempts;
  static Duration get lockoutDuration => _stagingLockoutDuration;
  
  static bool get enableAnalytics => _stagingEnableAnalytics;
  static bool get enableCrashReporting => _stagingEnableCrashReporting;
  static bool get enablePerformanceMonitoring => _stagingEnablePerformanceMonitoring;
  static bool get enableRemoteConfig => _stagingEnableRemoteConfig;
  static bool get enableABTesting => _stagingEnableABTesting;
  
  static bool get enableLogging => _stagingEnableLogging;
  static bool get enableErrorLogging => _stagingEnableErrorLogging;
  static bool get enablePerformanceLogging => _stagingEnablePerformanceLogging;
  static bool get enableNetworkLogging => _stagingEnableNetworkLogging;
  static bool get enableUserActionLogging => _stagingEnableUserActionLogging;
  
  static Duration get healthCheckInterval => _stagingHealthCheckInterval;
  static Duration get metricsCollectionInterval => _stagingMetricsCollectionInterval;
  static Duration get performanceReportInterval => _stagingPerformanceReportInterval;
  static int get maxErrorReportsPerHour => _stagingMaxErrorReportsPerHour;
  
  static bool get enablePushNotifications => _stagingEnablePushNotifications;
  static bool get enableEmailNotifications => _stagingEnableEmailNotifications;
  static bool get enableSmsNotifications => _stagingEnableSmsNotifications;
  static int get maxNotificationsPerDay => _stagingMaxNotificationsPerDay;
  
  static int get maxFileSize => _stagingMaxFileSize;
  static int get maxTotalUploadSize => _stagingMaxTotalUploadSize;
  static List<String> get allowedFileTypes => _stagingAllowedFileTypes;
  
  static int get maxRequestsPerMinute => _stagingMaxRequestsPerMinute;
  static int get maxRequestsPerHour => _stagingMaxRequestsPerHour;
  static int get maxRequestsPerDay => _stagingMaxRequestsPerDay;
  static Duration get rateLimitWindow => _stagingRateLimitWindow;
  
  static bool get enableAutoBackup => _stagingEnableAutoBackup;
  static Duration get backupInterval => _stagingBackupInterval;
  static int get maxBackupRetainCount => _stagingMaxBackupRetainCount;
  static bool get enableIncrementalBackup => _stagingEnableIncrementalBackup;
  
  static List<int> get maintenanceWindows => _stagingMaintenanceWindows;
  static Duration get maintenanceDuration => _stagingMaintenanceDuration;
  static bool get enableMaintenanceMode => _stagingEnableMaintenanceMode;
  
  // Validation methods
  static bool isStagingConfigValid() {
    final issues = <String>[];
    
    // Check required API keys
    if (_stagingMapsApiKey.isEmpty) {
      issues.add('Maps API key is required');
    }
    
    // Check URLs
    if (!_stagingApiBaseUrl.startsWith('https://')) {
      issues.add('API base URL must use HTTPS');
    }
    if (!_stagingWebSocketUrl.startsWith('wss://')) {
      issues.add('WebSocket URL must use WSS');
    }
    
    // Check timeouts
    if (_stagingApiTimeout.inSeconds < 5 || _stagingApiTimeout.inSeconds > 30) {
      issues.add('API timeout should be between 5 and 30 seconds');
    }
    
    return issues.isEmpty;
  }
  
  static List<String> getStagingConfigIssues() {
    final issues = <String>[];
    
    if (_stagingMapsApiKey.isEmpty) issues.add('Missing Maps API key');
    if (!_stagingApiBaseUrl.startsWith('https://')) issues.add('API URL not HTTPS');
    if (!_stagingWebSocketUrl.startsWith('wss://')) issues.add('WebSocket URL not WSS');
    if (_stagingApiTimeout.inSeconds < 5) issues.add('API timeout too short');
    
    return issues;
  }
  
  // Configuration summary
  static Map<String, dynamic> getStagingConfigSummary() {
    return {
      'environment': 'staging',
      'api': {
        'base_url': _stagingApiBaseUrl,
        'websocket_url': _stagingWebSocketUrl,
        'cdn_url': _stagingCdnUrl,
        'analytics_url': _stagingAnalyticsUrl,
        'timeout': _stagingApiTimeout.inSeconds,
        'max_retries': _stagingMaxRetries,
        'max_connections': _stagingMaxConnections,
      },
      'security': {
        'require_https': _stagingRequireHttps,
        'validate_certificates': _stagingValidateCertificates,
        'session_timeout': _stagingSessionTimeout,
        'max_login_attempts': _stagingMaxLoginAttempts,
        'lockout_duration': _stagingLockoutDuration.inMinutes,
      },
      'features': {
        'analytics': _stagingEnableAnalytics,
        'crash_reporting': _stagingEnableCrashReporting,
        'performance_monitoring': _stagingEnablePerformanceMonitoring,
        'remote_config': _stagingEnableRemoteConfig,
        'ab_testing': _stagingEnableABTesting,
      },
      'logging': {
        'enabled': _stagingEnableLogging,
        'error_logging': _stagingEnableErrorLogging,
        'performance_logging': _stagingEnablePerformanceLogging,
        'network_logging': _stagingEnableNetworkLogging,
        'user_action_logging': _stagingEnableUserActionLogging,
      },
      'cache': {
        'size_mb': _stagingCacheSize ~/ (1024 * 1024),
        'expiry_hours': _stagingCacheExpiry.inHours,
        'max_entries': _stagingMaxCacheEntries,
      },
      'rate_limiting': {
        'requests_per_minute': _stagingMaxRequestsPerMinute,
        'requests_per_hour': _stagingMaxRequestsPerHour,
        'requests_per_day': _stagingMaxRequestsPerDay,
        'window_minutes': _stagingRateLimitWindow.inMinutes,
      },
      'notifications': {
        'push_enabled': _stagingEnablePushNotifications,
        'email_enabled': _stagingEnableEmailNotifications,
        'sms_enabled': _stagingEnableSmsNotifications,
        'max_per_day': _stagingMaxNotificationsPerDay,
      },
      'file_uploads': {
        'max_file_size_mb': _stagingMaxFileSize ~/ (1024 * 1024),
        'max_total_size_mb': _stagingMaxTotalUploadSize ~/ (1024 * 1024),
        'allowed_types': _stagingAllowedFileTypes,
      },
      'backup': {
        'auto_enabled': _stagingEnableAutoBackup,
        'interval_hours': _stagingBackupInterval.inHours,
        'max_retain_count': _stagingMaxBackupRetainCount,
        'incremental': _stagingEnableIncrementalBackup,
      },
      'maintenance': {
        'windows': _stagingMaintenanceWindows,
        'duration_minutes': _stagingMaintenanceDuration.inMinutes,
        'maintenance_mode': _stagingEnableMaintenanceMode,
      },
      'validation': {
        'is_valid': isStagingConfigValid(),
        'issues': getStagingConfigIssues(),
      },
    };
  }
  
  // Staging environment initialization
  static Future<void> initializeStagingEnvironment() async {
    if (ProductionConfig.isProduction || ProductionConfig.isDevelopment) return;
    
    // Validate staging configuration
    if (!isStagingConfigValid()) {
      final issues = getStagingConfigIssues();
      throw Exception('Staging configuration is invalid: ${issues.join(', ')}');
    }
    
    // Initialize staging-specific services
    await _initializeStagingServices();
    
    // Configure staging logging
    _configureStagingLogging();
    
    // Set up staging monitoring
    _setupStagingMonitoring();
  }
  
  static Future<void> _initializeStagingServices() async {
    // Initialize staging services
    // This would include:
    // - Staging crash reporting service
    // - Staging analytics service
    // - Staging performance monitoring service
    // - Staging remote config service
    // - Staging A/B testing service
  }
  
  static void _configureStagingLogging() {
    // Configure staging logging
    // - Set appropriate log levels
    // - Configure log destinations
    // - Set up log rotation
    // - Configure error reporting
  }
  
  static void _setupStagingMonitoring() {
    // Set up staging monitoring
    // - Health checks
    // - Performance metrics
    // - Error tracking
    // - User analytics
    // - System metrics
  }
}
