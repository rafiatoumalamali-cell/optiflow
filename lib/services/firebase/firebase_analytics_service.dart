import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseAnalyticsService {
  FirebaseAnalyticsService._();

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {
      // Analytics should not break app flow.
    }
  }

  static Future<void> logOptimizationRequested(String optimizationType) async {
    await logEvent(
      name: 'optimization_requested',
      parameters: {'optimization_type': optimizationType},
    );
  }

  static Future<void> logOptimizationError(String optimizationType, String error) async {
    await logEvent(
      name: 'optimization_error',
      parameters: {
        'optimization_type': optimizationType,
        'error_message': error,
      },
    );
  }
}
