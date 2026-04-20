import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/environment_manager.dart';
import '../utils/production_config.dart';
import '../utils/logger.dart';

/// Production analytics service without debug output
class ProductionAnalyticsService {
  ProductionAnalyticsService._();
  
  static ProductionAnalyticsService? _instance;
  static bool _isInitialized = false;
  static String? _analyticsKey;
  static String? _userId;
  static Map<String, dynamic> _userProperties = {};
  static final List<AnalyticsEvent> _eventQueue = [];
  static Timer? _batchTimer;
  static final Duration _batchInterval = Duration(minutes: 1);
  static const int _maxBatchSize = 50;
  
  static ProductionAnalyticsService get instance {
    _instance ??= ProductionAnalyticsService._();
    return _instance!;
  }
  
  /// Initialize analytics service
  static Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;
    
    // Only initialize in production or when analytics is enabled
    if (!EnvironmentManager.enableAnalytics) {
      Logger.info('Analytics disabled in current environment', name: 'Analytics');
      return;
    }
    
    try {
      _analyticsKey = EnvironmentManager.analyticsKey;
      if (_analyticsKey == null || _analyticsKey!.isEmpty) {
        Logger.warning('Analytics key not configured', name: 'Analytics');
        return;
      }
      
      _userId = userId;
      
      // Start batch timer
      _startBatchTimer();
      
      _isInitialized = true;
      
      // Log initialization event (only in non-production builds)
      if (!ProductionConfig.isProduction) {
        Logger.info('Analytics service initialized', name: 'Analytics');
      }
      
    } catch (e) {
      Logger.error('Failed to initialize analytics service', error: e, name: 'Analytics');
      // Don't rethrow in production to avoid app crashes
    }
  }
  
  /// Set user ID for analytics
  static Future<void> setUserId(String userId) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      _userId = userId;
      
      // Send user identification event
      await trackEvent('user_identified', properties: {
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      Logger.error('Failed to set analytics user ID', error: e, name: 'Analytics');
    }
  }
  
  /// Set user properties
  static Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      _userProperties = {..._userProperties, ...properties};
      
      // Send user properties update event
      await trackEvent('user_properties_updated', properties: {
        'properties': properties,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      Logger.error('Failed to set analytics user properties', error: e, name: 'Analytics');
    }
  }
  
  /// Track custom event
  static Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
    double? value,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      final event = AnalyticsEvent(
        name: eventName,
        parameters: parameters ?? {},
        value: value,
        timestamp: DateTime.now(),
        userId: _userId,
        userProperties: Map.from(_userProperties),
      );
      
      _addToBatch(event);
      
    } catch (e) {
      Logger.error('Failed to track analytics event: $eventName', error: e, name: 'Analytics');
    }
  }
  
  /// Track screen view
  static Future<void> trackScreenView(
    String screenName, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      await trackEvent('screen_view', parameters: {
        'screen_name': screenName,
        ...?parameters,
      });
      
    } catch (e) {
      Logger.error('Failed to track screen view: $screenName', error: e, name: 'Analytics');
    }
  }
  
  /// Track user action
  static Future<void> trackUserAction(
    String action, {
    String? category,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      await trackEvent('user_action', parameters: {
        'action': action,
        'category': category ?? 'general',
        ...?parameters,
      });
      
    } catch (e) {
      Logger.error('Failed to track user action: $action', error: e, name: 'Analytics');
    }
  }
  
  /// Track app performance
  static Future<void> trackPerformance(
    String operation, {
    Duration? duration,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      await trackEvent('performance', parameters: {
        'operation': operation,
        'duration_ms': duration?.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
      
    } catch (e) {
      Logger.error('Failed to track performance: $operation', error: e, name: 'Analytics');
    }
  }
  
  /// Track error event
  static Future<void> trackError(
    String error, {
    String? stackTrace,
    String? context,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      await trackEvent('error', parameters: {
        'error_message': error,
        'stack_trace': stackTrace,
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
      
    } catch (e) {
      // Don't log error tracking errors to avoid infinite loops
      // In production, silently fail
    }
  }
  
  /// Track API call
  static Future<void> trackApiCall(
    String endpoint,
    String method, {
    int? statusCode,
    Duration? duration,
    Object? error,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      await trackEvent('api_call', parameters: {
        'endpoint': endpoint,
        'method': method,
        'status_code': statusCode,
        'duration_ms': duration?.inMilliseconds,
        'error': error?.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      Logger.error('Failed to track API call: $method $endpoint', error: e, name: 'Analytics');
    }
  }
  
  /// Track user session
  static Future<void> trackSessionStart({
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      await trackEvent('session_start', parameters: {
        'session_id': _generateSessionId(),
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
      
    } catch (e) {
      Logger.error('Failed to track session start', error: e, name: 'Analytics');
    }
  }
  
  static Future<void> trackSessionEnd({
    Duration? duration,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      await trackEvent('session_end', parameters: {
        'session_id': _generateSessionId(),
        'duration_ms': duration?.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
      
    } catch (e) {
      Logger.error('Failed to track session end', error: e, name: 'Analytics');
    }
  }
  
  /// Track app lifecycle events
  static Future<void> trackAppOpen({
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      await trackEvent('app_open', parameters: {
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
      
    } catch (e) {
      Logger.error('Failed to track app open', error: e, name: 'Analytics');
    }
  }
  
  static Future<void> trackAppClose({
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      await trackEvent('app_close', parameters: {
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
      
    } catch (e) {
      Logger.error('Failed to track app close', error: e, name: 'Analytics');
    }
  }
  
  /// Track app background/foreground
  static Future<void> trackAppBackground({
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      await trackEvent('app_background', parameters: {
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
      
    } catch (e) {
      Logger.error('Failed to track app background', error: e, name: 'Analytics');
    }
  }
  
  static Future<void> trackAppForeground({
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      await trackEvent('app_foreground', parameters: {
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
      
    } catch (e) {
      Logger.error('Failed to track app foreground', error: e, name: 'Analytics');
    }
  }
  
  /// Track business metrics
  static Future<void> trackBusinessMetric(
    String metricName,
    dynamic value, {
    String? unit,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      await trackEvent('business_metric', parameters: {
        'metric_name': metricName,
        'value': value,
        'unit': unit,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
      
    } catch (e) {
      Logger.error('Failed to track business metric: $metricName', error: e, name: 'Analytics');
    }
  }
  
  /// Track user engagement
  static Future<void> trackUserEngagement({
    int? sessionDuration,
    int? screenViews,
    int? actions,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableAnalytics) return;
    
    try {
      await trackEvent('user_engagement', parameters: {
        'session_duration_seconds': sessionDuration,
        'screen_views': screenViews,
        'actions': actions,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
      
    } catch (e) {
      Logger.error('Failed to track user engagement', error: e, name: 'Analytics');
    }
  }
  
  /// Add event to batch queue
  static void _addToBatch(AnalyticsEvent event) {
    _eventQueue.add(event);
    
    // Send immediately if batch is full
    if (_eventQueue.length >= _maxBatchSize) {
      _sendBatch();
    }
  }
  
  /// Start batch timer
  static void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchInterval, (timer) {
      if (_eventQueue.isNotEmpty) {
        _sendBatch();
      }
    });
  }
  
  /// Send batch of events
  static Future<void> _sendBatch() async {
    if (_eventQueue.isEmpty) return;
    
    final batch = List<AnalyticsEvent>.from(_eventQueue);
    _eventQueue.clear();
    
    try {
      await _sendEventsToServer(batch);
    } catch (e) {
      Logger.error('Failed to send analytics batch', error: e, name: 'Analytics');
      // Re-add events to queue for retry
      _eventQueue.insertAll(0, batch);
    }
  }
  
  /// Send events to analytics server
  static Future<void> _sendEventsToServer(List<AnalyticsEvent> events) async {
    if (_analyticsKey == null || _analyticsKey!.isEmpty) return;
    
    final url = '${EnvironmentManager.analyticsUrl}/events';
    
    final payload = {
      'api_key': _analyticsKey,
      'events': events.map((e) => e.toJson()).toList(),
      'app_version': EnvironmentManager.getAppVersion('1.0.0'),
      'platform': Platform.operatingSystem,
      'environment': EnvironmentManager.getBuildFlavor(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'OptiFlow/1.0.0',
      },
      body: jsonEncode(payload),
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode != 200) {
      throw Exception('Analytics server returned ${response.statusCode}');
    }
  }
  
  /// Generate session ID
  static String _generateSessionId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_userId ?? 'anonymous'}';
  }
  
  /// Flush pending events
  static Future<void> flush() async {
    if (_eventQueue.isNotEmpty) {
      await _sendBatch();
    }
  }
  
  /// Disable analytics
  static Future<void> disable() async {
    _isInitialized = false;
    _batchTimer?.cancel();
    _batchTimer = null;
    await flush();
  }
  
  /// Enable analytics
  static Future<void> enable() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  /// Get analytics status
  static bool get isInitialized => _isInitialized;
  static bool get isEnabled => _isInitialized && EnvironmentManager.enableAnalytics;
  static int get pendingEventsCount => _eventQueue.length;
  
  /// Get analytics configuration
  static Map<String, dynamic> getAnalyticsConfiguration() {
    return {
      'is_initialized': _isInitialized,
      'is_enabled': isEnabled,
      'environment': EnvironmentManager.currentEnvironment.toString(),
      'analytics_enabled': EnvironmentManager.enableAnalytics,
      'pending_events': _eventQueue.length,
      'batch_size': _maxBatchSize,
      'batch_interval_seconds': _batchInterval.inSeconds,
      'has_analytics_key': _analyticsKey != null && _analyticsKey!.isNotEmpty,
      'user_id_set': _userId != null,
      'user_properties_count': _userProperties.length,
    };
  }
  
  /// Dispose analytics service
  static Future<void> dispose() async {
    _batchTimer?.cancel();
    _batchTimer = null;
    await flush();
    _isInitialized = false;
    _instance = null;
  }
}

/// Analytics event model
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final double? value;
  final DateTime timestamp;
  final String? userId;
  final Map<String, dynamic> userProperties;
  
  AnalyticsEvent({
    required this.name,
    required this.parameters,
    this.value,
    required this.timestamp,
    this.userId,
    required this.userProperties,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameters': parameters,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'user_properties': userProperties,
    };
  }
  
  @override
  String toString() {
    return 'AnalyticsEvent(name: $name, timestamp: $timestamp)';
  }
}
