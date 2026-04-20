import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/environment_manager.dart';
import '../utils/production_config.dart';
import '../utils/logger.dart';

/// Production performance monitoring service without debug output
class ProductionPerformanceMonitoringService {
  ProductionPerformanceMonitoringService._();
  
  static ProductionPerformanceMonitoringService? _instance;
  static bool _isInitialized = false;
  static final List<PerformanceMetric> _metricsQueue = [];
  static Timer? _batchTimer;
  static final Duration _batchInterval = Duration(minutes: 1);
  static const int _maxBatchSize = 100;
  static final Map<String, DateTime> _screenStartTime = {};
  static final List<FrameTimeMetric> _frameMetrics = [];
  static int _frameCount = 0;
  static DateTime? _lastFrameTime;
  
  static ProductionPerformanceMonitoringService get instance {
    _instance ??= ProductionPerformanceMonitoringService._();
    return _instance!;
  }
  
  /// Initialize performance monitoring service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Only initialize in production or when performance monitoring is enabled
    if (!EnvironmentManager.enablePerformanceMonitoring) {
      Logger.info('Performance monitoring disabled in current environment', name: 'Performance');
      return;
    }
    
    try {
      // Set up performance observers
      _setupPerformanceObservers();
      
      // Start batch timer
      _startBatchTimer();
      
      _isInitialized = true;
      
      // Log initialization event (only in non-production builds)
      if (!ProductionConfig.isProduction) {
        Logger.info('Performance monitoring service initialized', name: 'Performance');
      }
      
    } catch (e) {
      Logger.error('Failed to initialize performance monitoring service', error: e, name: 'Performance');
      // Don't rethrow in production to avoid app crashes
    }
  }
  
  /// Track screen load time
  static Future<void> trackScreenLoad(
    String screenName, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enablePerformanceMonitoring) return;
    
    try {
      final startTime = _screenStartTime[screenName];
      if (startTime != null) {
        final loadTime = DateTime.now().difference(startTime!);
        
        await trackMetric('screen_load_time', {
          'screen_name': screenName,
          'load_time_ms': loadTime.inMilliseconds,
          'timestamp': DateTime.now().toIso8601String(),
          ...?parameters,
        });
        
        _screenStartTime.remove(screenName);
      }
    } catch (e) {
      Logger.error('Failed to track screen load time: $screenName', error: e, name: 'Performance');
    }
  }
  
  /// Start tracking screen load
  static void startScreenLoad(String screenName) {
    if (!_isInitialized || !EnvironmentManager.enablePerformanceMonitoring) return;
    
    _screenStartTime[screenName] = DateTime.now();
  }
  
  /// Track API response time
  static Future<void> trackApiResponse(
    String endpoint,
    String method, {
    int? statusCode,
    Duration? duration,
    int? responseSize,
    Object? error,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enablePerformanceMonitoring) return;
    
    try {
      await trackMetric('api_response_time', {
        'endpoint': endpoint,
        'method': method,
        'status_code': statusCode,
        'duration_ms': duration?.inMilliseconds,
        'response_size_bytes': responseSize,
        'error': error?.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
    } catch (e) {
      Logger.error('Failed to track API response time: $method $endpoint', error: e, name: 'Performance');
    }
  }
  
  /// Track database operation time
  static Future<void> trackDatabaseOperation(
    String operation,
    String table, {
    Duration? duration,
    int? recordCount,
    Object? error,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enablePerformanceMonitoring) return;
    
    try {
      await trackMetric('database_operation_time', {
        'operation': operation,
        'table': table,
        'duration_ms': duration?.inMilliseconds,
        'record_count': recordCount,
        'error': error?.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
    } catch (e) {
      Logger.error('Failed to track database operation: $operation $table', error: e, name: 'Performance');
    }
  }
  
  /// Track memory usage
  static Future<void> trackMemoryUsage({
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enablePerformanceMonitoring) return;
    
    try {
      // Get memory usage (platform-specific implementation would go here)
      final memoryUsage = await _getMemoryUsage();
      
      await trackMetric('memory_usage', {
        'heap_size_mb': memoryUsage['heapSizeMB'],
        'total_memory_mb': memoryUsage['totalMemoryMB'],
        'used_memory_mb': memoryUsage['usedMemoryMB'],
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
    } catch (e) {
      Logger.error('Failed to track memory usage', error: e, name: 'Performance');
    }
  }
  
  /// Track CPU usage
  static Future<void> trackCpuUsage({
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enablePerformanceMonitoring) return;
    
    try {
      // Get CPU usage (platform-specific implementation would go here)
      final cpuUsage = await _getCpuUsage();
      
      await trackMetric('cpu_usage', {
        'cpu_percentage': cpuUsage['percentage'],
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
    } catch (e) {
      Logger.error('Failed to track CPU usage', error: e, name: 'Performance');
    }
  }
  
  /// Track network performance
  static Future<void> trackNetworkPerformance({
    int? downloadSpeed,
    int? uploadSpeed,
    int? latency,
    int? packetLoss,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enablePerformanceMonitoring) return;
    
    try {
      await trackMetric('network_performance', {
        'download_speed_kbps': downloadSpeed,
        'upload_speed_kbps': uploadSpeed,
        'latency_ms': latency,
        'packet_loss_percentage': packetLoss,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
    } catch (e) {
      Logger.error('Failed to track network performance', error: e, name: 'Performance');
    }
  }
  
  /// Track app startup time
  static Future<void> trackAppStartup({
    Duration? coldStartTime,
    Duration? warmStartTime,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enablePerformanceMonitoring) return;
    
    try {
      await trackMetric('app_startup_time', {
        'cold_start_ms': coldStartTime?.inMilliseconds,
        'warm_start_ms': warmStartTime?.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      });
    } catch (e) {
      Logger.error('Failed to track app startup time', error: e, name: 'Performance');
    }
  }
  
  /// Track custom performance metric
  static Future<void> trackMetric(
    String metricName,
    Map<String, dynamic> parameters,
  ) async {
    if (!_isInitialized || !EnvironmentManager.enablePerformanceMonitoring) return;
    
    try {
      final metric = PerformanceMetric(
        name: metricName,
        parameters: parameters,
        timestamp: DateTime.now(),
        appVersion: EnvironmentManager.getAppVersion('1.0.0'),
        platform: Platform.operatingSystem,
        environment: EnvironmentManager.getBuildFlavor(),
      );
      
      _addToBatch(metric);
      
    } catch (e) {
      Logger.error('Failed to track performance metric: $metricName', error: e, name: 'Performance');
    }
  }
  
  /// Track frame rendering performance
  static void trackFrameTime(Duration frameTime) {
    if (!_isInitialized || !EnvironmentManager.enablePerformanceMonitoring) return;
    
    _frameCount++;
    _lastFrameTime = DateTime.now();
    
    final frameMetric = FrameTimeMetric(
      frameTime: frameTime.inMicroseconds.toDouble(),
      timestamp: DateTime.now(),
    );
    
    _frameMetrics.add(frameMetric);
    
    // Keep only last 1000 frames
    if (_frameMetrics.length > 1000) {
      _frameMetrics.removeRange(0, _frameMetrics.length - 1000);
    }
    
    // Report frame performance every 100 frames
    if (_frameCount % 100 == 0) {
      _reportFramePerformance();
    }
  }
  
  /// Report frame performance metrics
  static Future<void> _reportFramePerformance() async {
    if (_frameMetrics.isEmpty) return;
    
    try {
      final frameTimes = _frameMetrics.map((m) => m.frameTime).toList();
      final avgFrameTime = frameTimes.reduce((a, b) => a + b) / frameTimes.length;
      final maxFrameTime = frameTimes.reduce((a, b) => a > b ? a : b);
      final minFrameTime = frameTimes.reduce((a, b) => a < b ? a : b);
      
      // Calculate FPS
      final avgFps = 1000000 / avgFrameTime; // Convert microseconds to FPS
      
      await trackMetric('frame_performance', {
        'avg_frame_time_us': avgFrameTime,
        'max_frame_time_us': maxFrameTime,
        'min_frame_time_us': minFrameTime,
        'avg_fps': avgFps,
        'frame_count': _frameCount,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      Logger.error('Failed to report frame performance', error: e, name: 'Performance');
    }
  }
  
  /// Set up performance observers
  static void _setupPerformanceObservers() {
    // Set up frame rate monitoring
    if (!ProductionConfig.isProduction) {
      WidgetsBinding.instance.addPostFrameCallback(_onPostFrameCallback);
    }
    
    // Set up memory pressure monitoring
    _setupMemoryPressureMonitoring();
    
    // Set up app lifecycle monitoring
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
  }
  
  /// Handle post frame callback
  static void _onPostFrameCallback(Duration timestamp) {
    if (_lastFrameTime != null) {
      final frameTime = timestamp.difference(_lastFrameTime!);
      trackFrameTime(frameTime);
    }
  }
  
  /// Set up memory pressure monitoring
  static void _setupMemoryPressureMonitoring() {
    // Implementation would depend on platform
    // This is a placeholder for memory pressure monitoring
  }
  
  /// Add metric to batch queue
  static void _addToBatch(PerformanceMetric metric) {
    _metricsQueue.add(metric);
    
    // Send immediately if batch is full
    if (_metricsQueue.length >= _maxBatchSize) {
      _sendBatch();
    }
  }
  
  /// Start batch timer
  static void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchInterval, (timer) {
      if (_metricsQueue.isNotEmpty) {
        _sendBatch();
      }
    });
  }
  
  /// Send batch of metrics
  static Future<void> _sendBatch() async {
    if (_metricsQueue.isEmpty) return;
    
    final batch = List<PerformanceMetric>.from(_metricsQueue);
    _metricsQueue.clear();
    
    try {
      await _sendMetricsToServer(batch);
    } catch (e) {
      Logger.error('Failed to send performance metrics batch', error: e, name: 'Performance');
      // Re-add metrics to queue for retry
      _metricsQueue.insertAll(0, batch);
    }
  }
  
  /// Send metrics to performance monitoring server
  static Future<void> _sendMetricsToServer(List<PerformanceMetric> metrics) async {
    final url = '${EnvironmentManager.analyticsUrl}/performance';
    
    final payload = {
      'metrics': metrics.map((m) => m.toJson()).toList(),
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
      throw Exception('Performance monitoring server returned ${response.statusCode}');
    }
  }
  
  /// Get memory usage (platform-specific)
  static Future<Map<String, int>> _getMemoryUsage() async {
    // This would be implemented differently for each platform
    // Placeholder implementation
    return {
      'heapSizeMB': 50, // Placeholder
      'totalMemoryMB': 1024, // Placeholder
      'usedMemoryMB': 200, // Placeholder
    };
  }
  
  /// Get CPU usage (platform-specific)
  static Future<Map<String, double>> _getCpuUsage() async {
    // This would be implemented differently for each platform
    // Placeholder implementation
    return {
      'percentage': 25.0, // Placeholder
    };
  }
  
  /// Get performance monitoring status
  static bool get isInitialized => _isInitialized;
  static bool get isEnabled => _isInitialized && EnvironmentManager.enablePerformanceMonitoring;
  static int get pendingMetricsCount => _metricsQueue.length;
  
  /// Get performance monitoring configuration
  static Map<String, dynamic> getPerformanceMonitoringConfiguration() {
    return {
      'is_initialized': _isInitialized,
      'is_enabled': isEnabled,
      'environment': EnvironmentManager.currentEnvironment.toString(),
      'performance_monitoring_enabled': EnvironmentManager.enablePerformanceMonitoring,
      'pending_metrics': _metricsQueue.length,
      'batch_size': _maxBatchSize,
      'batch_interval_seconds': _batchInterval.inSeconds,
      'screen_tracking_count': _screenStartTime.length,
      'frame_metrics_count': _frameMetrics.length,
      'total_frames_tracked': _frameCount,
    };
  }
  
  /// Flush pending metrics
  static Future<void> flush() async {
    if (_metricsQueue.isNotEmpty) {
      await _sendBatch();
    }
  }
  
  /// Disable performance monitoring
  static Future<void> disable() async {
    _isInitialized = false;
    _batchTimer?.cancel();
    _batchTimer = null;
    await flush();
  }
  
  /// Enable performance monitoring
  static Future<void> enable() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  /// Dispose performance monitoring service
  static Future<void> dispose() async {
    _batchTimer?.cancel();
    _batchTimer = null;
    await flush();
    _isInitialized = false;
    _instance = null;
  }
}

/// Performance metric model
class PerformanceMetric {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String appVersion;
  final String platform;
  final String environment;
  
  PerformanceMetric({
    required this.name,
    required this.parameters,
    required this.timestamp,
    required this.appVersion,
    required this.platform,
    required this.environment,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
      'app_version': appVersion,
      'platform': platform,
      'environment': environment,
    };
  }
  
  @override
  String toString() {
    return 'PerformanceMetric(name: $name, timestamp: $timestamp)';
  }
}

/// Frame time metric model
class FrameTimeMetric {
  final double frameTime; // in microseconds
  final DateTime timestamp;
  
  FrameTimeMetric({
    required this.frameTime,
    required this.timestamp,
  });
  
  @override
  String toString() {
    return 'FrameTimeMetric(frameTime: $frameTimeμs, timestamp: $timestamp)';
  }
}

/// App lifecycle observer for performance monitoring
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        ProductionPerformanceMonitoringService.trackMetric('app_lifecycle', {
          'state': 'resumed',
          'timestamp': DateTime.now().toIso8601String(),
        });
        break;
      case AppLifecycleState.inactive:
        ProductionPerformanceMonitoringService.trackMetric('app_lifecycle', {
          'state': 'inactive',
          'timestamp': DateTime.now().toIso8601String(),
        });
        break;
      case AppLifecycleState.paused:
        ProductionPerformanceMonitoringService.trackMetric('app_lifecycle', {
          'state': 'paused',
          'timestamp': DateTime.now().toIso8601String(),
        });
        break;
      case AppLifecycleState.detached:
        ProductionPerformanceMonitoringService.trackMetric('app_lifecycle', {
          'state': 'detached',
          'timestamp': DateTime.now().toIso8601String(),
        });
        break;
      case AppLifecycleState.hidden:
        ProductionPerformanceMonitoringService.trackMetric('app_lifecycle', {
          'state': 'hidden',
          'timestamp': DateTime.now().toIso8601String(),
        });
        break;
    }
  }
}
