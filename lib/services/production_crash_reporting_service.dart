import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/environment_manager.dart';
import '../utils/production_config.dart';
import '../utils/logger.dart';

/// Production crash reporting service without debug output
class ProductionCrashReportingService {
  ProductionCrashReportingService._();
  
  static ProductionCrashReportingService? _instance;
  static bool _isInitialized = false;
  static String? _crashlyticsKey;
  static String? _userId;
  static Map<String, dynamic> _userContext = {};
  static final List<CrashReport> _crashQueue = [];
  static Timer? _batchTimer;
  static final Duration _batchInterval = Duration(minutes: 5);
  static const int _maxBatchSize = 10;
  
  static ProductionCrashReportingService get instance {
    _instance ??= ProductionCrashReportingService._();
    return _instance!;
  }
  
  /// Initialize crash reporting service
  static Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;
    
    // Only initialize in production or when crash reporting is enabled
    if (!EnvironmentManager.enableCrashReporting) {
      Logger.info('Crash reporting disabled in current environment', name: 'CrashReporting');
      return;
    }
    
    try {
      _crashlyticsKey = EnvironmentManager.crashlyticsKey;
      if (_crashlyticsKey == null || _crashlyticsKey!.isEmpty) {
        Logger.warning('Crashlytics key not configured', name: 'CrashReporting');
        return;
      }
      
      _userId = userId;
      
      // Set up global error handlers
      _setupGlobalErrorHandlers();
      
      // Start batch timer
      _startBatchTimer();
      
      _isInitialized = true;
      
      // Log initialization event (only in non-production builds)
      if (!ProductionConfig.isProduction) {
        Logger.info('Crash reporting service initialized', name: 'CrashReporting');
      }
      
    } catch (e) {
      Logger.error('Failed to initialize crash reporting service', error: e, name: 'CrashReporting');
      // Don't rethrow in production to avoid app crashes
    }
  }
  
  /// Set user ID for crash reporting
  static Future<void> setUserId(String userId) async {
    if (!_isInitialized || !EnvironmentManager.enableCrashReporting) return;
    
    try {
      _userId = userId;
      
      // Send user identification event
      await _reportUserContext({
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      Logger.error('Failed to set crash reporting user ID', error: e, name: 'CrashReporting');
    }
  }
  
  /// Set user context for crash reporting
  static Future<void> setUserContext(Map<String, dynamic> context) async {
    if (!_isInitialized || !EnvironmentManager.enableCrashReporting) return;
    
    try {
      _userContext = {..._userContext, ...context};
      
      // Send user context update event
      await _reportUserContext({
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      Logger.error('Failed to set crash reporting user context', error: e, name: 'CrashReporting');
    }
  }
  
  /// Report a crash
  static Future<void> reportCrash(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    bool isFatal = true,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableCrashReporting) return;
    
    try {
      final crashReport = CrashReport(
        error: error.toString(),
        stackTrace: stackTrace?.toString(),
        context: context,
        isFatal: isFatal,
        timestamp: DateTime.now(),
        userId: _userId,
        userContext: Map.from(_userContext),
        additionalInfo: additionalInfo ?? {},
        appVersion: EnvironmentManager.getAppVersion('1.0.0'),
        platform: Platform.operatingSystem,
        environment: EnvironmentManager.getBuildFlavor(),
      );
      
      _addToBatch(crashReport);
      
      // If fatal, send immediately
      if (isFatal) {
        await _sendBatch();
      }
      
    } catch (e) {
      // Don't log error reporting errors to avoid infinite loops
      // In production, silently fail
    }
  }
  
  /// Report a non-fatal error
  static Future<void> reportError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalInfo,
  }) async {
    await reportCrash(
      error,
      stackTrace,
      context: context,
      isFatal: false,
      additionalInfo: additionalInfo,
    );
  }
  
  /// Report an exception
  static Future<void> reportException(
    Exception exception,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalInfo,
  }) async {
    await reportCrash(
      exception,
      stackTrace,
      context: context,
      isFatal: false,
      additionalInfo: additionalInfo,
    );
  }
  
  /// Report a custom message
  static Future<void> reportMessage(
    String message, {
    String? level,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableCrashReporting) return;
    
    try {
      final crashReport = CrashReport(
        error: message,
        stackTrace: null,
        context: 'custom_message',
        isFatal: false,
        timestamp: DateTime.now(),
        userId: _userId,
        userContext: Map.from(_userContext),
        additionalInfo: {
          'level': level ?? 'info',
          ...?additionalInfo,
        },
        appVersion: EnvironmentManager.getAppVersion('1.0.0'),
        platform: Platform.operatingSystem,
        environment: EnvironmentManager.getBuildFlavor(),
      );
      
      _addToBatch(crashReport);
      
    } catch (e) {
      // Don't log error reporting errors to avoid infinite loops
    }
  }
  
  /// Report ANR (Application Not Responding)
  static Future<void> reportANR({
    String? context,
    Duration? duration,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableCrashReporting) return;
    
    try {
      final crashReport = CrashReport(
        error: 'Application Not Responding',
        stackTrace: null,
        context: context ?? 'ANR',
        isFatal: true,
        timestamp: DateTime.now(),
        userId: _userId,
        userContext: Map.from(_userContext),
        additionalInfo: {
          'anr_duration_ms': duration?.inMilliseconds,
          ...?additionalInfo,
        },
        appVersion: EnvironmentManager.getAppVersion('1.0.0'),
        platform: Platform.operatingSystem,
        environment: EnvironmentManager.getBuildFlavor(),
      );
      
      _addToBatch(crashReport);
      await _sendBatch();
      
    } catch (e) {
      // Don't log error reporting errors to avoid infinite loops
    }
  }
  
  /// Report out of memory error
  static Future<void> reportOutOfMemory({
    String? context,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (!_isInitialized || !EnvironmentManager.enableCrashReporting) return;
    
    try {
      final crashReport = CrashReport(
        error: 'Out of Memory',
        stackTrace: null,
        context: context ?? 'OOM',
        isFatal: true,
        timestamp: DateTime.now(),
        userId: _userId,
        userContext: Map.from(_userContext),
        additionalInfo: additionalInfo ?? {},
        appVersion: EnvironmentManager.getAppVersion('1.0.0'),
        platform: Platform.operatingSystem,
        environment: EnvironmentManager.getBuildFlavor(),
      );
      
      _addToBatch(crashReport);
      await _sendBatch();
      
    } catch (e) {
      // Don't log error reporting errors to avoid infinite loops
    }
  }
  
  /// Set up global error handlers
  static void _setupGlobalErrorHandlers() {
    // Set up Flutter error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      reportCrash(
        details.exception,
        details.stack,
        context: 'flutter_error',
        isFatal: false,
        additionalInfo: {
          'library': details.library,
          'exception': details.exception.toString(),
        },
      );
    };
    
    // Set up platform error handler
    PlatformDispatcher.instance.onError = (error, stack) {
      reportCrash(
        error,
        stack,
        context: 'platform_error',
        isFatal: true,
      );
    };
  }
  
  /// Add crash report to batch queue
  static void _addToBatch(CrashReport crashReport) {
    _crashQueue.add(crashReport);
    
    // Send immediately if batch is full
    if (_crashQueue.length >= _maxBatchSize) {
      _sendBatch();
    }
  }
  
  /// Start batch timer
  static void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchInterval, (timer) {
      if (_crashQueue.isNotEmpty) {
        _sendBatch();
      }
    });
  }
  
  /// Send batch of crash reports
  static Future<void> _sendBatch() async {
    if (_crashQueue.isEmpty) return;
    
    final batch = List<CrashReport>.from(_crashQueue);
    _crashQueue.clear();
    
    try {
      await _sendCrashReportsToServer(batch);
    } catch (e) {
      Logger.error('Failed to send crash reports batch', error: e, name: 'CrashReporting');
      // Re-add reports to queue for retry
      _crashQueue.insertAll(0, batch);
    }
  }
  
  /// Send crash reports to crash reporting server
  static Future<void> _sendCrashReportsToServer(List<CrashReport> reports) async {
    if (_crashlyticsKey == null || _crashlyticsKey!.isEmpty) return;
    
    final url = 'https://api.crashlytics.com/v2/events';
    
    final payload = {
      'api_key': _crashlyticsKey,
      'reports': reports.map((report) => report.toJson()).toList(),
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
      throw Exception('Crashlytics server returned ${response.statusCode}');
    }
  }
  
  /// Report user context
  static Future<void> _reportUserContext(Map<String, dynamic> context) async {
    if (_crashlyticsKey == null || _crashlyticsKey!.isEmpty) return;
    
    final url = 'https://api.crashlytics.com/v2/user/context';
    
    final payload = {
      'api_key': _crashlyticsKey,
      'user_id': _userId,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'OptiFlow/1.0.0',
        },
        body: jsonEncode(payload),
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update user context: ${response.statusCode}');
      }
    } catch (e) {
      // Don't log user context errors to avoid noise
    }
  }
  
  /// Test crash reporting
  static Future<void> testCrashReporting() async {
    if (!_isInitialized || !EnvironmentManager.enableCrashReporting) return;
    
    try {
      final testError = Exception('Test crash reporting');
      final testStackTrace = StackTrace.current;
      
      await reportCrash(
        testError,
        testStackTrace,
        context: 'test',
        isFatal: false,
        additionalInfo: {
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
    } catch (e) {
      Logger.error('Failed to test crash reporting', error: e, name: 'CrashReporting');
    }
  }
  
  /// Get crash reporting status
  static bool get isInitialized => _isInitialized;
  static bool get isEnabled => _isInitialized && EnvironmentManager.enableCrashReporting;
  static int get pendingReportsCount => _crashQueue.length;
  
  /// Get crash reporting configuration
  static Map<String, dynamic> getCrashReportingConfiguration() {
    return {
      'is_initialized': _isInitialized,
      'is_enabled': isEnabled,
      'environment': EnvironmentManager.currentEnvironment.toString(),
      'crash_reporting_enabled': EnvironmentManager.enableCrashReporting,
      'pending_reports': _crashQueue.length,
      'batch_size': _maxBatchSize,
      'batch_interval_seconds': _batchInterval.inSeconds,
      'has_crashlytics_key': _crashlyticsKey != null && _crashlyticsKey!.isNotEmpty,
      'user_id_set': _userId != null,
      'user_context_count': _userContext.length,
    };
  }
  
  /// Disable crash reporting
  static Future<void> disable() async {
    _isInitialized = false;
    _batchTimer?.cancel();
    _batchTimer = null;
    await _sendBatch();
  }
  
  /// Enable crash reporting
  static Future<void> enable() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  /// Dispose crash reporting service
  static Future<void> dispose() async {
    _batchTimer?.cancel();
    _batchTimer = null;
    await _sendBatch();
    _isInitialized = false;
    _instance = null;
  }
}

/// Crash report model
class CrashReport {
  final String error;
  final String? stackTrace;
  final String? context;
  final bool isFatal;
  final DateTime timestamp;
  final String? userId;
  final Map<String, dynamic> userContext;
  final Map<String, dynamic> additionalInfo;
  final String appVersion;
  final String platform;
  final String environment;
  
  CrashReport({
    required this.error,
    this.stackTrace,
    this.context,
    required this.isFatal,
    required this.timestamp,
    this.userId,
    required this.userContext,
    required this.additionalInfo,
    required this.appVersion,
    required this.platform,
    required this.environment,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'stack_trace': stackTrace,
      'context': context,
      'is_fatal': isFatal,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'user_context': userContext,
      'additional_info': additionalInfo,
      'app_version': appVersion,
      'platform': platform,
      'environment': environment,
    };
  }
  
  @override
  String toString() {
    return 'CrashReport(error: $error, fatal: $isFatal, timestamp: $timestamp)';
  }
}
