import 'package:flutter/foundation.dart';
import '../utils/production_config.dart';
import 'production_environment_config.dart';
import 'staging_environment_config.dart';
import 'development_environment_config.dart';
import '../utils/logger.dart';

/// Unified environment manager that handles all environment-specific configurations
class EnvironmentManager {
  EnvironmentManager._();
  
  static EnvironmentType get currentEnvironment {
    if (ProductionConfig.isProduction) {
      return EnvironmentType.production;
    } else if (ProductionConfig.isProfile) {
      return EnvironmentType.staging;
    } else {
      return EnvironmentType.production; // Default to production for safety
    }
  }
  
  // API configuration
  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.apiBaseUrl;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.apiBaseUrl;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.apiBaseUrl;
    }
  }
  
  static String get webSocketUrl {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.webSocketUrl;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.webSocketUrl;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.webSocketUrl;
    }
  }
  
  static String get cdnUrl {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.cdnUrl;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.cdnUrl;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.cdnUrl;
    }
  }
  
  static String get analyticsUrl {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.analyticsUrl;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.analyticsUrl;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.analyticsUrl;
    }
  }
  
  // API keys
  static String get mapsApiKey {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.mapsApiKey;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.mapsApiKey;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.mapsApiKey;
    }
  }
  
  static String get crashlyticsKey {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.crashlyticsKey;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.crashlyticsKey;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.crashlyticsKey;
    }
  }
  
  static String get analyticsKey {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.analyticsKey;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.analyticsKey;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.analyticsKey;
    }
  }
  
  // Timeouts and limits
  static Duration get apiTimeout {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.apiTimeout;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.apiTimeout;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.apiTimeout;
    }
  }
  
  static Duration get connectTimeout {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.connectTimeout;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.connectTimeout;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.connectTimeout;
    }
  }
  
  static Duration get receiveTimeout {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.receiveTimeout;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.receiveTimeout;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.receiveTimeout;
    }
  }
  
  static int get maxRetries {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.maxRetries;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.maxRetries;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.maxRetries;
    }
  }
  
  static int get retryDelay {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.retryDelay;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.retryDelay;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.retryDelay;
    }
  }
  
  static int get maxConnections {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.maxConnections;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.maxConnections;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.maxConnections;
    }
  }
  
  // Cache settings
  static int get cacheSize {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.cacheSize;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.cacheSize;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.cacheSize;
    }
  }
  
  static Duration get cacheExpiry {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.cacheExpiry;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.cacheExpiry;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.cacheExpiry;
    }
  }
  
  static int get maxCacheEntries {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.maxCacheEntries;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.maxCacheEntries;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.maxCacheEntries;
    }
  }
  
  // Security settings
  static bool get requireHttps {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.requireHttps;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.requireHttps;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.requireHttps;
    }
  }
  
  static bool get validateCertificates {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.validateCertificates;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.validateCertificates;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.validateCertificates;
    }
  }
  
  static int get sessionTimeout {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.sessionTimeout;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.sessionTimeout;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.sessionTimeout;
    }
  }
  
  static int get maxLoginAttempts {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.maxLoginAttempts;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.maxLoginAttempts;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.maxLoginAttempts;
    }
  }
  
  static Duration get lockoutDuration {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.lockoutDuration;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.lockoutDuration;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.lockoutDuration;
    }
  }
  
  // Feature flags
  static bool get enableAnalytics {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enableAnalytics;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.enableAnalytics;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.enableAnalytics;
    }
  }
  
  static bool get enableCrashReporting {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enableCrashReporting;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.enableCrashReporting;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.enableCrashReporting;
    }
  }
  
  static bool get enablePerformanceMonitoring {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enablePerformanceMonitoring;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.enablePerformanceMonitoring;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.enablePerformanceMonitoring;
    }
  }
  
  static bool get enableRemoteConfig {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enableRemoteConfig;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.enableRemoteConfig;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.enableRemoteConfig;
    }
  }
  
  static bool get enableABTesting {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enableABTesting;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.enableABTesting;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.enableABTesting;
    }
  }
  
  // Logging settings
  static bool get enableLogging {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enableLogging;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.enableLogging;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.enableLogging;
    }
  }
  
  static bool get enableErrorLogging {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enableErrorLogging;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.enableErrorLogging;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.enableErrorLogging;
    }
  }
  
  static bool get enablePerformanceLogging {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enablePerformanceLogging;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.enablePerformanceLogging;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.enablePerformanceLogging;
    }
  }
  
  static bool get enableNetworkLogging {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enableNetworkLogging;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.enableNetworkLogging;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.enableNetworkLogging;
    }
  }
  
  static bool get enableUserActionLogging {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enableUserActionLogging;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.enableUserActionLogging;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.enableUserActionLogging;
    }
  }
  
  // Notification settings
  static bool get enablePushNotifications {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enablePushNotifications;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.enablePushNotifications;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.enablePushNotifications;
    }
  }
  
  static bool get enableEmailNotifications {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enableEmailNotifications;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.enableEmailNotifications;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.enableEmailNotifications;
    }
  }
  
  static bool get enableSmsNotifications {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enableSmsNotifications;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.enableSmsNotifications;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.enableSmsNotifications;
    }
  }
  
  static int get maxNotificationsPerDay {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.maxNotificationsPerDay;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.maxNotificationsPerDay;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.maxNotificationsPerDay;
    }
  }
  
  // File upload settings
  static int get maxFileSize {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.maxFileSize;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.maxFileSize;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.maxFileSize;
    }
  }
  
  static int get maxTotalUploadSize {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.maxTotalUploadSize;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.maxTotalUploadSize;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.maxTotalUploadSize;
    }
  }
  
  static List<String> get allowedFileTypes {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.allowedFileTypes;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.allowedFileTypes;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.allowedFileTypes;
    }
  }
  
  // Rate limiting
  static int get maxRequestsPerMinute {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.maxRequestsPerMinute;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.maxRequestsPerMinute;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.maxRequestsPerMinute;
    }
  }
  
  static int get maxRequestsPerHour {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.maxRequestsPerHour;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.maxRequestsPerHour;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.maxRequestsPerHour;
    }
  }
  
  static int get maxRequestsPerDay {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.maxRequestsPerDay;
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.maxRequestsPerDay;
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.maxRequestsPerDay;
    }
  }
  
  // Development-specific features
  static bool get enableMockData {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enableMockData;
      case EnvironmentType.staging:
        return false; // No mock data in staging
      case EnvironmentType.production:
        return false; // No mock data in production
    }
  }
  
  static bool get enableDebugMenu {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enableDebugMenu;
      case EnvironmentType.staging:
        return false; // No debug menu in staging
      case EnvironmentType.production:
        return false; // No debug menu in production
    }
  }
  
  static bool get enableDebugOverlay {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.enableDebugOverlay;
      case EnvironmentType.staging:
        return false; // No debug overlay in staging
      case EnvironmentType.production:
        return false; // No debug overlay in production
    }
  }
  
  // Environment validation
  static bool isCurrentEnvironmentValid() {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.isDevelopmentConfigValid();
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.isStagingConfigValid();
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.isProductionConfigValid();
    }
  }
  
  static List<String> getCurrentEnvironmentIssues() {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.getDevelopmentConfigIssues();
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.getStagingConfigIssues();
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.getProductionConfigIssues();
    }
  }
  
  // Configuration summary
  static Map<String, dynamic> getCurrentEnvironmentConfigSummary() {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return DevelopmentEnvironmentConfig.getDevelopmentConfigSummary();
      case EnvironmentType.staging:
        return StagingEnvironmentConfig.getStagingConfigSummary();
      case EnvironmentType.production:
        return ProductionEnvironmentConfig.getProductionConfigSummary();
    }
  }
  
  // Environment initialization
  static Future<void> initializeCurrentEnvironment() async {
    Logger.info('Initializing environment: ${currentEnvironment.toString()}', name: 'EnvironmentManager');
    
    try {
      switch (currentEnvironment) {
        case EnvironmentType.development:
          await DevelopmentEnvironmentConfig.initializeDevelopmentEnvironment();
          break;
        case EnvironmentType.staging:
          await StagingEnvironmentConfig.initializeStagingEnvironment();
          break;
        case EnvironmentType.production:
          await ProductionEnvironmentConfig.initializeProductionEnvironment();
          break;
      }
      
      Logger.info('Environment initialized successfully: ${currentEnvironment.toString()}', name: 'EnvironmentManager');
      
    } catch (e) {
      Logger.error('Failed to initialize environment: ${currentEnvironment.toString()}', 
                   error: e, name: 'EnvironmentManager');
      rethrow;
    }
  }
  
  // Environment health check
  static Future<Map<String, dynamic>> performEnvironmentHealthCheck() async {
    Logger.info('Performing environment health check: ${currentEnvironment.toString()}', name: 'EnvironmentManager');
    
    try {
      Map<String, dynamic> results;
      
      switch (currentEnvironment) {
        case EnvironmentType.development:
          results = await DevelopmentEnvironmentConfig.performDevelopmentHealthCheck();
          break;
        case EnvironmentType.staging:
          // Staging would use similar health check as production
          results = await ProductionEnvironmentConfig.performProductionHealthCheck();
          break;
        case EnvironmentType.production:
          results = await ProductionEnvironmentConfig.performProductionHealthCheck();
          break;
      }
      
      results['environment_type'] = currentEnvironment.toString();
      results['timestamp'] = DateTime.now().toIso8601String();
      
      Logger.info('Environment health check completed: ${currentEnvironment.toString()}', name: 'EnvironmentManager');
      
      return results;
      
    } catch (e) {
      Logger.error('Environment health check failed: ${currentEnvironment.toString()}', 
                   error: e, name: 'EnvironmentManager');
      
      return {
        'environment_type': currentEnvironment.toString(),
        'overall_health': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  // Environment switching (for testing only)
  static Future<void> switchEnvironmentForTesting(EnvironmentType newEnvironment) async {
    if (!ProductionConfig.isDevelopment) {
      throw Exception('Environment switching is only allowed in development mode');
    }
    
    Logger.warning('Switching environment for testing: ${newEnvironment.toString()}', name: 'EnvironmentManager');
    
    // This would typically require app restart
    // For now, just log the request
    // In a real implementation, you might:
    // 1. Save the new environment preference
    // 2. Clear caches
    // 3. Restart the app
    // 4. Reinitialize with new environment
  }
  
  // Environment-specific app configuration
  static String getAppTitle() {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return 'OptiFlow (Development)';
      case EnvironmentType.staging:
        return 'OptiFlow (Staging)';
      case EnvironmentType.production:
        return 'OptiFlow';
    }
  }
  
  static String getAppVersion(String baseVersion) {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return '$baseVersion-dev';
      case EnvironmentType.staging:
        return '$baseVersion-staging';
      case EnvironmentType.production:
        return baseVersion;
    }
  }
  
  static String getBuildFlavor() {
    switch (currentEnvironment) {
      case EnvironmentType.development:
        return 'development';
      case EnvironmentType.staging:
        return 'staging';
      case EnvironmentType.production:
        return 'production';
    }
  }
  
  // Environment comparison helpers
  static bool isDevelopment() => currentEnvironment == EnvironmentType.development;
  static bool isStaging() => currentEnvironment == EnvironmentType.staging;
  static bool isProduction() => currentEnvironment == EnvironmentType.production;
  static bool isDebug() => ProductionConfig.isDevelopment;
  static bool isRelease() => ProductionConfig.isProduction;
  static bool isProfile() => ProductionConfig.isProfile;
  
  // Environment-specific feature checks
  static bool shouldEnableFeature(Feature feature) {
    switch (feature) {
      case Feature.mockData:
        return enableMockData;
      case Feature.debugMenu:
        return enableDebugMenu;
      case Feature.debugOverlay:
        return enableDebugOverlay;
      case Feature.analytics:
        return enableAnalytics;
      case Feature.crashReporting:
        return enableCrashReporting;
      case Feature.performanceMonitoring:
        return enablePerformanceMonitoring;
      case Feature.networkLogging:
        return enableNetworkLogging;
      default:
        return true; // Default to enabled
    }
  }
  
  // Environment configuration validation
  static Map<String, bool> validateAllEnvironments() {
    return {
      'development_valid': DevelopmentEnvironmentConfig.isDevelopmentConfigValid(),
      'staging_valid': StagingEnvironmentConfig.isStagingConfigValid(),
      'production_valid': ProductionEnvironmentConfig.isProductionConfigValid(),
    };
  }
  
  // Environment configuration comparison
  static Map<String, dynamic> compareEnvironments() {
    return {
      'current_environment': currentEnvironment.toString(),
      'development_config': DevelopmentEnvironmentConfig.getDevelopmentConfigSummary(),
      'staging_config': StagingEnvironmentConfig.getStagingConfigSummary(),
      'production_config': ProductionEnvironmentConfig.getProductionConfigSummary(),
      'current_config': getCurrentEnvironmentConfigSummary(),
      'validation': validateAllEnvironments(),
    };
  }
}

/// Environment types
enum EnvironmentType {
  development,
  staging,
  production,
}

/// Features that can be environment-specific
enum Feature {
  mockData,
  debugMenu,
  debugOverlay,
  analytics,
  crashReporting,
  performanceMonitoring,
  networkLogging,
}
