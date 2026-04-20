class AppConfig {
  // API Configuration - Now handled by Environment class
  // static const String apiBaseUrl = 'http://localhost:8000/api/v1'; // DEPRECATED
  
  // Development vs Production - Now handled by Environment class
  // static const bool isDevelopment = true; // DEPRECATED
  
  // Map Configuration - Now handled by Environment class
  // static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // DEPRECATED
  
  // Mock data for development
  static const bool useMockData = false;
  
  // App Configuration
  static const String appName = 'OptiFlow';
  static const String appVersion = '1.0.0';
  
  // Firebase Configuration
  static const String projectId = 'optiflow-app';
  
  // Cache Configuration
  static const int cacheMaxAge = 7; // days
  static const int maxCachedRoutes = 50;
  
  // Route Configuration
  static const double defaultLatitude = 13.5127; // Niamey
  static const double defaultLongitude = 2.1128;
  static const double defaultZoom = 13.0;
  
  // Offline Configuration
  static const Duration offlineSyncInterval = Duration(minutes: 5);
  static const Duration locationUpdateInterval = Duration(seconds: 10);
}
