import 'package:flutter/foundation.dart';
import '../utils/production_config.dart';

/// Development environment configuration
class DevelopmentEnvironmentConfig {
  DevelopmentEnvironmentConfig._();

  // Development API endpoints
  static const String _developmentApiBaseUrl = 'http://localhost:8080/api/v1';
  static const String _developmentWebSocketUrl = 'ws://localhost:8080/ws';
  static const String _developmentCdnUrl = 'http://localhost:8080/cdn';
  static const String _developmentAnalyticsUrl = 'http://localhost:8080/analytics';
  
  // Development API keys
  static const String _developmentMapsApiKey = 'AIzaSyCFZJVmX7G2F8bdjf-cxEn6Eo-nSsHZ4Ow'; // Development key
  static const String _developmentCrashlyticsKey = ''; // Development crashlytics key
  static const String _developmentAnalyticsKey = ''; // Development analytics key
  
  // Development timeouts and limits
  static const Duration _developmentApiTimeout = Duration(seconds: 10);
  static const Duration _developmentConnectTimeout = Duration(seconds: 5);
  static const Duration _developmentReceiveTimeout = Duration(seconds: 8);
  static const int _developmentMaxRetries = 1;
  static const int _developmentRetryDelay = 200; // milliseconds
  static const int _developmentMaxConnections = 3;
  
  // Development cache settings
  static const int _developmentCacheSize = 10 * 1024 * 1024; // 10MB
  static const Duration _developmentCacheExpiry = Duration(hours: 1);
  static const int _developmentMaxCacheEntries = 1000;
  
  // Development database settings
  static const int _developmentDbConnectionPoolSize = 5;
  static const Duration _developmentDbTimeout = Duration(seconds: 5);
  static const int _developmentDbMaxConnections = 10;
  
  // Development security settings
  static const bool _developmentRequireHttps = false; // Allow HTTP for local development
  static const bool _developmentValidateCertificates = false; // Allow self-signed certs
  static const int _developmentSessionTimeout = 120; // minutes (longer for development)
  static const int _developmentMaxLoginAttempts = 20; // More attempts for debugging
  static const Duration _developmentLockoutDuration = Duration(minutes: 1); // Short lockout
  
  // Development feature flags
  static const bool _developmentEnableAnalytics = false; // Disabled in development
  static const bool _developmentEnableCrashReporting = false; // Disabled in development
  static const bool _developmentEnablePerformanceMonitoring = true; // Enabled for debugging
  static const bool _developmentEnableRemoteConfig = true; // Enabled for testing
  static const bool _developmentEnableABTesting = true; // Enabled for testing
  
  // Development logging settings
  static const bool _developmentEnableLogging = true;
  static const bool _developmentEnableErrorLogging = true;
  static const bool _developmentEnablePerformanceLogging = true;
  static const bool _developmentEnableNetworkLogging = true; // All network requests logged
  static const bool _developmentEnableUserActionLogging = true;
  
  // Development monitoring settings
  static const Duration _developmentHealthCheckInterval = Duration(seconds: 30);
  static const Duration _developmentMetricsCollectionInterval = Duration(seconds: 10);
  static const Duration _developmentPerformanceReportInterval = Duration(minutes: 5);
  static const int _developmentMaxErrorReportsPerHour = 1000; // High limit for debugging
  
  // Development notification settings
  static const bool _developmentEnablePushNotifications = true;
  static const bool _developmentEnableEmailNotifications = false; // Disabled to avoid spam
  static const bool _developmentEnableSmsNotifications = false; // Disabled to avoid costs
  static const int _developmentMaxNotificationsPerDay = 1000; // High limit for testing
  
  // Development file upload settings
  static const int _developmentMaxFileSize = 50 * 1024 * 1024; // 50MB
  static const int _developmentMaxTotalUploadSize = 500 * 1024 * 1024; // 500MB
  static const List<String> _developmentAllowedFileTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'application/pdf',
    'text/csv',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/json',
    'text/plain',
    'application/zip',
    'application/x-zip-compressed',
    'image/svg+xml',
    'text/html',
    'application/xml',
  ];
  
  // Development rate limiting
  static const int _developmentMaxRequestsPerMinute = 10000; // Very high limit
  static const int _developmentMaxRequestsPerHour = 100000; // Very high limit
  static const int _developmentMaxRequestsPerDay = 1000000; // Very high limit
  static const Duration _developmentRateLimitWindow = Duration(minutes: 1);
  
  // Development backup settings
  static const bool _developmentEnableAutoBackup = false; // Disabled in development
  static const Duration _developmentBackupInterval = Duration(hours: 24); // If enabled
  static const int _developmentMaxBackupRetainCount = 3; // Few backups
  static const bool _developmentEnableIncrementalBackup = false; // Full backups only
  
  // Development maintenance settings
  static const List<int> _developmentMaintenanceWindows = []; // No maintenance windows
  static const Duration _developmentMaintenanceDuration = Duration(minutes: 15); // Short maintenance
  static const bool _developmentEnableMaintenanceMode = false; // Never enabled in development
  
  // Development mock data settings
  static const bool _developmentEnableMockData = true; // Mock data enabled
  static const bool _developmentMockApiResponses = true; // Mock API responses
  static const bool _developmentMockAuthentication = true; // Mock authentication
  static const bool _developmentMockNotifications = true; // Mock notifications
  
  // Development debug settings
  static const bool _developmentEnableDebugMenu = true; // Debug menu enabled
  static const bool _developmentEnableDebugOverlay = true; // Debug overlay enabled
  static const bool _developmentEnableDebugLogs = true; // Debug logs enabled
  static const bool _developmentEnableDebugNetworkInspector = true; // Network inspector enabled
  static const bool _developmentEnableDebugPerformanceOverlay = true; // Performance overlay enabled
  
  // Getters for development configuration
  static String get apiBaseUrl => _developmentApiBaseUrl;
  static String get webSocketUrl => _developmentWebSocketUrl;
  static String get cdnUrl => _developmentCdnUrl;
  static String get analyticsUrl => _developmentAnalyticsUrl;
  
  static String get mapsApiKey => _developmentMapsApiKey;
  static String get crashlyticsKey => _developmentCrashlyticsKey;
  static String get analyticsKey => _developmentAnalyticsKey;
  
  static Duration get apiTimeout => _developmentApiTimeout;
  static Duration get connectTimeout => _developmentConnectTimeout;
  static Duration get receiveTimeout => _developmentReceiveTimeout;
  static int get maxRetries => _developmentMaxRetries;
  static int get retryDelay => _developmentRetryDelay;
  static int get maxConnections => _developmentMaxConnections;
  
  static int get cacheSize => _developmentCacheSize;
  static Duration get cacheExpiry => _developmentCacheExpiry;
  static int get maxCacheEntries => _developmentMaxCacheEntries;
  
  static int get dbConnectionPoolSize => _developmentDbConnectionPoolSize;
  static Duration get dbTimeout => _developmentDbTimeout;
  static int get dbMaxConnections => _developmentDbMaxConnections;
  
  static bool get requireHttps => _developmentRequireHttps;
  static bool get validateCertificates => _developmentValidateCertificates;
  static int get sessionTimeout => _developmentSessionTimeout;
  static int get maxLoginAttempts => _developmentMaxLoginAttempts;
  static Duration get lockoutDuration => _developmentLockoutDuration;
  
  static bool get enableAnalytics => _developmentEnableAnalytics;
  static bool get enableCrashReporting => _developmentEnableCrashReporting;
  static bool get enablePerformanceMonitoring => _developmentEnablePerformanceMonitoring;
  static bool get enableRemoteConfig => _developmentEnableRemoteConfig;
  static bool get enableABTesting => _developmentEnableABTesting;
  
  static bool get enableLogging => _developmentEnableLogging;
  static bool get enableErrorLogging => _developmentEnableErrorLogging;
  static bool get enablePerformanceLogging => _developmentEnablePerformanceLogging;
  static bool get enableNetworkLogging => _developmentEnableNetworkLogging;
  static bool get enableUserActionLogging => _developmentEnableUserActionLogging;
  
  static Duration get healthCheckInterval => _developmentHealthCheckInterval;
  static Duration get metricsCollectionInterval => _developmentMetricsCollectionInterval;
  static Duration get performanceReportInterval => _developmentPerformanceReportInterval;
  static int get maxErrorReportsPerHour => _developmentMaxErrorReportsPerHour;
  
  static bool get enablePushNotifications => _developmentEnablePushNotifications;
  static bool get enableEmailNotifications => _developmentEnableEmailNotifications;
  static bool get enableSmsNotifications => _developmentEnableSmsNotifications;
  static int get maxNotificationsPerDay => _developmentMaxNotificationsPerDay;
  
  static int get maxFileSize => _developmentMaxFileSize;
  static int get maxTotalUploadSize => _developmentMaxTotalUploadSize;
  static List<String> get allowedFileTypes => _developmentAllowedFileTypes;
  
  static int get maxRequestsPerMinute => _developmentMaxRequestsPerMinute;
  static int get maxRequestsPerHour => _developmentMaxRequestsPerHour;
  static int get maxRequestsPerDay => _developmentMaxRequestsPerDay;
  static Duration get rateLimitWindow => _developmentRateLimitWindow;
  
  static bool get enableAutoBackup => _developmentEnableAutoBackup;
  static Duration get backupInterval => _developmentBackupInterval;
  static int get maxBackupRetainCount => _developmentMaxBackupRetainCount;
  static bool get enableIncrementalBackup => _developmentEnableIncrementalBackup;
  
  static List<int> get maintenanceWindows => _developmentMaintenanceWindows;
  static Duration get maintenanceDuration => _developmentMaintenanceDuration;
  static bool get enableMaintenanceMode => _developmentEnableMaintenanceMode;
  
  // Mock data getters
  static bool get enableMockData => _developmentEnableMockData;
  static bool get mockApiResponses => _developmentMockApiResponses;
  static bool get mockAuthentication => _developmentMockAuthentication;
  static bool get mockNotifications => _developmentMockNotifications;
  
  // Debug settings getters
  static bool get enableDebugMenu => _developmentEnableDebugMenu;
  static bool get enableDebugOverlay => _developmentEnableDebugOverlay;
  static bool get enableDebugLogs => _developmentEnableDebugLogs;
  static bool get enableDebugNetworkInspector => _developmentEnableDebugNetworkInspector;
  static bool get enableDebugPerformanceOverlay => _developmentEnableDebugPerformanceOverlay;
  
  // Validation methods
  static bool isDevelopmentConfigValid() {
    final issues = <String>[];
    
    // Check required API keys
    if (_developmentMapsApiKey.isEmpty) {
      issues.add('Maps API key is required');
    }
    
    // Check URLs
    // Allow HTTP for development
    if (!_developmentApiBaseUrl.startsWith('http://') && !_developmentApiBaseUrl.startsWith('https://')) {
      issues.add('API base URL must use HTTP or HTTPS');
    }
    
    // Check timeouts
    if (_developmentApiTimeout.inSeconds < 5 || _developmentApiTimeout.inSeconds > 30) {
      issues.add('API timeout should be between 5 and 30 seconds');
    }
    
    // Check cache settings
    if (_developmentCacheSize < 5 * 1024 * 1024) { // Less than 5MB
      issues.add('Cache size should be at least 5MB');
    }
    
    return issues.isEmpty;
  }
  
  static List<String> getDevelopmentConfigIssues() {
    final issues = <String>[];
    
    if (_developmentMapsApiKey.isEmpty) issues.add('Missing Maps API key');
    if (!_developmentApiBaseUrl.startsWith('http://') && !_developmentApiBaseUrl.startsWith('https://')) issues.add('Invalid API URL protocol');
    if (_developmentApiTimeout.inSeconds < 5) issues.add('API timeout too short');
    if (_developmentCacheSize < 5 * 1024 * 1024) issues.add('Cache size too small');
    
    return issues;
  }
  
  // Configuration summary
  static Map<String, dynamic> getDevelopmentConfigSummary() {
    return {
      'environment': 'development',
      'api': {
        'base_url': _developmentApiBaseUrl,
        'websocket_url': _developmentWebSocketUrl,
        'cdn_url': _developmentCdnUrl,
        'analytics_url': _developmentAnalyticsUrl,
        'timeout': _developmentApiTimeout.inSeconds,
        'max_retries': _developmentMaxRetries,
        'max_connections': _developmentMaxConnections,
      },
      'security': {
        'require_https': _developmentRequireHttps,
        'validate_certificates': _developmentValidateCertificates,
        'session_timeout': _developmentSessionTimeout,
        'max_login_attempts': _developmentMaxLoginAttempts,
        'lockout_duration': _developmentLockoutDuration.inMinutes,
      },
      'features': {
        'analytics': _developmentEnableAnalytics,
        'crash_reporting': _developmentEnableCrashReporting,
        'performance_monitoring': _developmentEnablePerformanceMonitoring,
        'remote_config': _developmentEnableRemoteConfig,
        'ab_testing': _developmentEnableABTesting,
      },
      'logging': {
        'enabled': _developmentEnableLogging,
        'error_logging': _developmentEnableErrorLogging,
        'performance_logging': _developmentEnablePerformanceLogging,
        'network_logging': _developmentEnableNetworkLogging,
        'user_action_logging': _developmentEnableUserActionLogging,
      },
      'cache': {
        'size_mb': _developmentCacheSize ~/ (1024 * 1024),
        'expiry_hours': _developmentCacheExpiry.inHours,
        'max_entries': _developmentMaxCacheEntries,
      },
      'rate_limiting': {
        'requests_per_minute': _developmentMaxRequestsPerMinute,
        'requests_per_hour': _developmentMaxRequestsPerHour,
        'requests_per_day': _developmentMaxRequestsPerDay,
        'window_minutes': _developmentRateLimitWindow.inMinutes,
      },
      'notifications': {
        'push_enabled': _developmentEnablePushNotifications,
        'email_enabled': _developmentEnableEmailNotifications,
        'sms_enabled': _developmentEnableSmsNotifications,
        'max_per_day': _developmentMaxNotificationsPerDay,
      },
      'file_uploads': {
        'max_file_size_mb': _developmentMaxFileSize ~/ (1024 * 1024),
        'max_total_size_mb': _developmentMaxTotalUploadSize ~/ (1024 * 1024),
        'allowed_types': _developmentAllowedFileTypes,
      },
      'backup': {
        'auto_enabled': _developmentEnableAutoBackup,
        'interval_hours': _developmentBackupInterval.inHours,
        'max_retain_count': _developmentMaxBackupRetainCount,
        'incremental': _developmentEnableIncrementalBackup,
      },
      'maintenance': {
        'windows': _developmentMaintenanceWindows,
        'duration_minutes': _developmentMaintenanceDuration.inMinutes,
        'maintenance_mode': _developmentEnableMaintenanceMode,
      },
      'mock_data': {
        'enabled': _developmentEnableMockData,
        'api_responses': _developmentMockApiResponses,
        'authentication': _developmentMockAuthentication,
        'notifications': _developmentMockNotifications,
      },
      'debug': {
        'menu_enabled': _developmentEnableDebugMenu,
        'overlay_enabled': _developmentEnableDebugOverlay,
        'logs_enabled': _developmentEnableDebugLogs,
        'network_inspector_enabled': _developmentEnableDebugNetworkInspector,
        'performance_overlay_enabled': _developmentEnableDebugPerformanceOverlay,
      },
      'validation': {
        'is_valid': isDevelopmentConfigValid(),
        'issues': getDevelopmentConfigIssues(),
      },
    };
  }
  
  // Development environment initialization
  static Future<void> initializeDevelopmentEnvironment() async {
    if (!ProductionConfig.isDevelopment) return;
    
    // Validate development configuration
    if (!isDevelopmentConfigValid()) {
      final issues = getDevelopmentConfigIssues();
      throw Exception('Development configuration is invalid: ${issues.join(', ')}');
    }
    
    // Initialize development-specific services
    await _initializeDevelopmentServices();
    
    // Configure development logging
    _configureDevelopmentLogging();
    
    // Set up development monitoring
    _setupDevelopmentMonitoring();
    
    // Configure debug features
    _configureDebugFeatures();
  }
  
  static Future<void> _initializeDevelopmentServices() async {
    // Initialize development services
    // This would include:
    // - Mock data service
    // - Mock authentication service
    // - Mock notification service
    // - Debug service
    // - Development API service
  }
  
  static void _configureDevelopmentLogging() {
    // Configure development logging
    // - Set verbose log levels
    // - Configure console logging
    // - Set up file logging
    // - Configure debug logging
  }
  
  static void _setupDevelopmentMonitoring() {
    // Set up development monitoring
    // - Health checks
    // - Performance metrics
    // - Debug metrics
    // - Development analytics
  }
  
  static void _configureDebugFeatures() {
    // Configure debug features
    // - Debug menu
    // - Debug overlay
    // - Network inspector
    // - Performance overlay
    // - Debug logs
  }
  
  // Development environment health check
  static Future<Map<String, dynamic>> performDevelopmentHealthCheck() async {
    final results = <String, dynamic>{};
    
    try {
      // Check API connectivity
      final apiHealthy = await _checkApiHealth();
      results['api_health'] = apiHealthy;
      
      // Check WebSocket connectivity
      final wsHealthy = await _checkWebSocketHealth();
      results['websocket_health'] = wsHealthy;
      
      // Check configuration validity
      results['config_valid'] = isDevelopmentConfigValid();
      results['config_issues'] = getDevelopmentConfigIssues();
      
      // Check mock data status
      results['mock_data_enabled'] = _developmentEnableMockData;
      results['debug_features_enabled'] = _developmentEnableDebugMenu;
      
      // Overall health
      results['overall_health'] = apiHealthy && wsHealthy && isDevelopmentConfigValid();
      results['timestamp'] = DateTime.now().toIso8601String();
      
    } catch (e) {
      results['error'] = e.toString();
      results['overall_health'] = false;
    }
    
    return results;
  }
  
  static Future<bool> _checkApiHealth() async {
    try {
      // Implementation would check local API health endpoint
      return true; // Placeholder
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> _checkWebSocketHealth() async {
    try {
      // Implementation would check local WebSocket connectivity
      return true; // Placeholder
    } catch (e) {
      return false;
    }
  }
}
