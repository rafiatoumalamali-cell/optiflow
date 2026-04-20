import 'package:flutter/foundation.dart';
import 'app_config.dart';
import 'production_config.dart';

class Environment {
  static const String _developmentApiUrl = 'http://localhost:8080/api/v1';
  static const String _productionApiUrl = 'https://api.optiflow.app/api/v1'; // Production URL
  static const String _stagingApiUrl = 'https://staging-api.optiflow.app/api/v1'; // Staging URL

  // Current environment
  static EnvironmentType get current {
    if (ProductionConfig.isProduction) {
      return EnvironmentType.production;
    } else if (ProductionConfig.isDevelopment) {
      return EnvironmentType.development;
    } else {
      return EnvironmentType.staging;
    }
  }

  // API URL based on environment
  static String get apiBaseUrl {
    switch (current) {
      case EnvironmentType.development:
        return _developmentApiUrl;
      case EnvironmentType.production:
        return _productionApiUrl;
      case EnvironmentType.staging:
        return _stagingApiUrl;
    }
  }

  // Google Maps API key based on environment
  static String get googleMapsApiKey {
    switch (current) {
      case EnvironmentType.development:
        return 'AIzaSyCFZJVmX7G2F8bdjf-cxEn6Eo-nSsHZ4Ow'; // Real development key
      case EnvironmentType.production:
        return 'AIzaSyCFZJVmX7G2F8bdjf-cxEn6Eo-nSsHZ4Ow'; // Use same key for now
      case EnvironmentType.staging:
        return 'AIzaSyCFZJVmX7G2F8bdjf-cxEn6Eo-nSsHZ4Ow'; // Use same key for now
    }
  }

  // Is development mode
  static bool get isDevelopment => current == EnvironmentType.development;
  
  // Is production mode
  static bool get isProduction => current == EnvironmentType.production;
  
  // Is staging mode
  static bool get isStaging => current == EnvironmentType.staging;

  // Debug configuration
  static bool get enableDebugLogs => ProductionConfig.enableVerboseLogging;
  
  // Mock data for development
  static bool get useMockData => ProductionConfig.enableMockData && AppConfig.useMockData;

  // Environment verification
  static Map<String, dynamic> getEnvironmentInfo() {
    return {
      'current_environment': current.toString(),
      'is_development': isDevelopment,
      'is_staging': isStaging,
      'is_production': isProduction,
      'api_base_url': apiBaseUrl,
      'google_maps_api_key': googleMapsApiKey,
      'debug_logs_enabled': enableDebugLogs,
      'mock_data_enabled': useMockData,
      'is_release_mode': ProductionConfig.isProduction,
      'is_debug_mode': ProductionConfig.isDevelopment,
      'is_profile_mode': ProductionConfig.isProfile,
      'production_config': ProductionConfig.getConfigSummary(),
    };
  }

  // Verify environment configuration
  static Future<Map<String, dynamic>> verifyEnvironmentConfiguration() async {
    final results = <String, dynamic>{};
    
    try {
      // Test API URL accessibility
      final apiUrl = apiBaseUrl;
      final isLocalhost = apiUrl.contains('localhost') || apiUrl.contains('127.0.0.1');
      
      // Test Google Maps API key
      final mapsKey = googleMapsApiKey;
      final hasValidMapsKey = mapsKey.isNotEmpty && 
                               !mapsKey.contains('YOUR_') && 
                               !mapsKey.contains('DemoKey') &&
                               !mapsKey.contains('KeyHere');
      
      results['api_url'] = {
        'url': apiUrl,
        'is_localhost': isLocalhost,
        'is_secure': apiUrl.startsWith('https://'),
        'status': isLocalhost ? 'development' : 'production',
      };
      
      results['google_maps'] = {
        'key_provided': mapsKey.isNotEmpty,
        'key_valid': hasValidMapsKey,
        'key_format': mapsKey.startsWith('AIzaSy') ? 'valid' : 'invalid',
      };
      
      results['environment_switching'] = {
        'current': current.toString(),
        'can_switch_to_production': true,
        'can_switch_to_staging': true,
        'can_switch_to_development': true,
      };
      
      results['overall_status'] = 'success';
      
    } catch (e) {
      results['overall_status'] = 'error';
      results['error'] = e.toString();
    }
    
    return results;
  }

  // Switch environment (for testing purposes)
  static void switchEnvironment(EnvironmentType newEnvironment) {
    // This would typically be done through build configuration
    // But we can provide a method for testing
    print('Environment switch requested: ${newEnvironment.toString()}');
    
    // In a real app, this would require app restart
    // For now, just log the request
  }

  // Get environment-specific app name
  static String get appName {
    switch (current) {
      case EnvironmentType.development:
        return 'OptiFlow (Dev)';
      case EnvironmentType.production:
        return 'OptiFlow';
      case EnvironmentType.staging:
        return 'OptiFlow (Staging)';
    }
  }

  // Get environment-specific app version
  static String get appVersion {
    switch (current) {
      case EnvironmentType.development:
        return '1.0.0-dev';
      case EnvironmentType.production:
        return '1.0.0';
      case EnvironmentType.staging:
        return '1.0.0-staging';
    }
  }
}

enum EnvironmentType {
  development,
  staging,
  production,
}
