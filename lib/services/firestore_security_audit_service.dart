import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

/// Service for auditing Firestore security and access patterns
class FirestoreSecurityAuditService {
  static final FirestoreSecurityAuditService _instance = FirestoreSecurityAuditService._();
  factory FirestoreSecurityAuditService() => _instance;
  FirestoreSecurityAuditService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _auditCollection = FirebaseFirestore.instance.collection('security_audit');
  final CollectionReference _accessLogCollection = FirebaseFirestore.instance.collection('access_log');
  final CollectionReference _suspiciousActivityCollection = FirebaseFirestore.instance.collection('suspicious_activity');

  /// Log security audit event
  Future<void> logSecurityAudit({
    required String eventType,
    required String userId,
    String? role,
    String? businessId,
    String? resourceType,
    String? resourceId,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? metadata,
    bool? success,
    String? errorMessage,
  }) async {
    try {
      final auditEntry = {
        'event_type': eventType,
        'user_id': userId,
        'role': role,
        'business_id': businessId,
        'resource_type': resourceType,
        'resource_id': resourceId,
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'metadata': metadata ?? {},
        'success': success,
        'error_message': errorMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String(),
      };

      await _auditCollection.add(auditEntry);
      
      Logger.info('Security audit logged: $eventType', name: 'SecurityAudit');
      
    } catch (e) {
      Logger.error('Failed to log security audit', error: e, name: 'SecurityAudit');
    }
  }

  /// Log access attempt
  Future<void> logAccessAttempt({
    required String userId,
    required String resourceType,
    required String resourceId,
    required String action,
    required bool success,
    String? businessId,
    String? ipAddress,
    String? userAgent,
    String? errorMessage,
  }) async {
    try {
      final accessEntry = {
        'user_id': userId,
        'resource_type': resourceType,
        'resource_id': resourceId,
        'action': action,
        'success': success,
        'business_id': businessId,
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'error_message': errorMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String(),
      };

      await _accessLogCollection.add(accessEntry);
      
      Logger.info('Access attempt logged: $action on $resourceType/$resourceId', name: 'SecurityAudit');
      
    } catch (e) {
      Logger.error('Failed to log access attempt', error: e, name: 'SecurityAudit');
    }
  }

  /// Log suspicious activity
  Future<void> logSuspiciousActivity({
    required String userId,
    required String activityType,
    required String description,
    String? businessId,
    String? resourceType,
    String? resourceId,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? evidence,
  }) async {
    try {
      final suspiciousEntry = {
        'user_id': userId,
        'activity_type': activityType,
        'description': description,
        'business_id': businessId,
        'resource_type': resourceType,
        'resource_id': resourceId,
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'evidence': evidence ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String(),
        'severity': _calculateSeverity(activityType),
        'status': 'investigating',
      };

      await _suspiciousActivityCollection.add(suspiciousEntry);
      
      Logger.warning('Suspicious activity logged: $activityType', name: 'SecurityAudit');
      
    } catch (e) {
      Logger.error('Failed to log suspicious activity', error: e, name: 'SecurityAudit');
    }
  }

  /// Calculate severity level for suspicious activity
  String _calculateSeverity(String activityType) {
    switch (activityType) {
      case 'multiple_failed_logins':
      case 'unusual_access_pattern':
      case 'privilege_escalation_attempt':
        return 'high';
      case 'data_access_anomaly':
      case 'unusual_time_access':
      case 'bulk_data_access':
        return 'medium';
      case 'suspicious_query':
      case 'unusual_location_access':
        return 'low';
      default:
        return 'medium';
    }
  }

  /// Check for suspicious login patterns
  Future<void> checkSuspiciousLoginPatterns(String userId) async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(Duration(hours: 1));
      
      final failedLoginsQuery = await _accessLogCollection
          .where('user_id', isEqualTo: userId)
          .where('action', isEqualTo: 'login')
          .where('success', isEqualTo: false)
          .where('timestamp', isGreaterThanOrEqualTo: oneHourAgo)
          .get();

      final failedLoginCount = failedLoginsQuery.docs.length;

      if (failedLoginCount >= 5) {
        await logSuspiciousActivity(
          userId: userId,
          activityType: 'multiple_failed_logins',
          description: 'Multiple failed login attempts detected',
          evidence: {
            'failed_attempts': failedLoginCount,
            'time_window': '1 hour',
          },
        );
      }

    } catch (e) {
      Logger.error('Failed to check suspicious login patterns', error: e, name: 'SecurityAudit');
    }
  }

  /// Check for unusual access patterns
  Future<void> checkUnusualAccessPatterns(String userId) async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(Duration(days: 1));
      
      final accessQuery = await _accessLogCollection
          .where('user_id', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: oneDayAgo)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final accessEvents = accessQuery.docs;
      
      // Check for unusual time patterns
      final unusualTimeAccess = _checkUnusualTimePatterns(accessEvents);
      if (unusualTimeAccess) {
        await logSuspiciousActivity(
          userId: userId,
          activityType: 'unusual_time_access',
          description: 'Unusual access time pattern detected',
          evidence: {
            'access_times': accessEvents.map((doc) => doc.data()['date']).toList(),
          },
        );
      }

      // Check for unusual access frequency
      final unusualFrequency = _checkUnusualAccessFrequency(accessEvents);
      if (unusualFrequency) {
        await logSuspiciousActivity(
          userId: userId,
          activityType: 'unusual_access_pattern',
          description: 'Unusual access frequency pattern detected',
          evidence: {
            'access_frequency': accessEvents.length,
            'time_window': '24 hours',
          },
        );
      }

    } catch (e) {
      Logger.error('Failed to check unusual access patterns', error: e, name: 'SecurityAudit');
    }
  }

  /// Check for unusual time patterns
  bool _checkUnusualTimePatterns(List<QueryDocumentSnapshot> accessEvents) {
    if (accessEvents.isEmpty) return false;

    // Group access events by hour
    final Map<int, int> hourlyAccess = {};
    for (final event in accessEvents) {
      final timestamp = DateTime.parse(event.data()['date']);
      final hour = timestamp.hour;
      hourlyAccess[hour] = (hourlyAccess[hour] ?? 0) + 1;
    }

    // Check if most access is between 2 AM and 4 AM (unusual for business app)
    final unusualHours = hourlyAccess.entries.where((entry) => 
        entry.key >= 2 && entry.key <= 4 && entry.value >= 3);

    return unusualHours.isNotEmpty;
  }

  /// Check for unusual access frequency
  bool _checkUnusualAccessFrequency(List<QueryDocumentSnapshot> accessEvents) {
    if (accessEvents.length < 10) return false;

    // Calculate access rate
    final timeSpan = DateTime.parse(accessEvents.first.data()['date'])
        .difference(DateTime.parse(accessEvents.last.data()['date']));
    
    final accessRate = accessEvents.length / timeSpan.inHours;

    // If access rate is more than 100 per hour, it's suspicious
    return accessRate > 100;
  }

  /// Check for data access anomalies
  Future<void> checkDataAccessAnomalies(String userId) async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(Duration(hours: 1));
      
      final dataAccessQuery = await _accessLogCollection
          .where('user_id', isEqualTo: userId)
          .where('resource_type', whereIn: ['routes', 'products', 'orders', 'analytics'])
          .where('action', isEqualTo: 'read')
          .where('timestamp', isGreaterThanOrEqualTo: oneHourAgo)
          .get();

      final dataAccessEvents = dataAccessQuery.docs;
      
      // Check for bulk data access
      if (dataAccessEvents.length > 1000) {
        await logSuspiciousActivity(
          userId: userId,
          activityType: 'bulk_data_access',
          description: 'Bulk data access detected',
          evidence: {
            'access_count': dataAccessEvents.length,
            'time_window': '1 hour',
          },
        );
      }

    } catch (e) {
      Logger.error('Failed to check data access anomalies', error: e, name: 'SecurityAudit');
    }
  }

  /// Check for privilege escalation attempts
  Future<void> checkPrivilegeEscalationAttempts(String userId) async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(Duration(hours: 1));
      
      final privilegeQuery = await _accessLogCollection
          .where('user_id', isEqualTo: userId)
          .where('action', whereIn: ['create_business', 'delete_business', 'create_user', 'delete_user'])
          .where('timestamp', isGreaterThanOrEqualTo: oneHourAgo)
          .get();

      final privilegeEvents = privilegeQuery.docs;

      if (privilegeEvents.isNotEmpty) {
        await logSuspiciousActivity(
          userId: userId,
          activityType: 'privilege_escalation_attempt',
          description: 'Privilege escalation attempt detected',
          evidence: {
            'privilege_operations': privilegeEvents.map((doc) => doc.data()['action']).toList(),
          },
        );
      }

    } catch (e) {
      Logger.error('Failed to check privilege escalation attempts', error: e, name: 'SecurityAudit');
    }
  }

  /// Generate security report
  Future<Map<String, dynamic>> generateSecurityReport({
    String? userId,
    String? businessId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query auditQuery = _auditCollection;
      
      if (userId != null) {
        auditQuery = auditQuery.where('user_id', isEqualTo: userId);
      }
      
      if (businessId != null) {
        auditQuery = auditQuery.where('business_id', isEqualTo: businessId);
      }
      
      if (startDate != null) {
        auditQuery = auditQuery.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      
      if (endDate != null) {
        auditQuery = auditQuery.where('timestamp', isLessThanOrEqualTo: endDate);
      }
      
      final auditDocs = await auditQuery.orderBy('timestamp', descending: true).get();
      
      // Analyze security events
      final securityEvents = auditDocs.map((doc) => doc.data()).toList();
      
      final totalEvents = securityEvents.length;
      final failedLogins = securityEvents.where((event) => 
          event['event_type'] == 'login_failed').length;
      final suspiciousActivities = securityEvents.where((event) => 
          event['event_type'] == 'suspicious_activity').length;
      
      final report = {
        'total_events': totalEvents,
        'failed_logins': failedLogins,
        'suspicious_activities': suspiciousActivities,
        'security_score': _calculateSecurityScore(totalEvents, failedLogins, suspiciousActivities),
        'risk_level': _calculateRiskLevel(totalEvents, failedLogins, suspiciousActivities),
        'recommendations': _generateSecurityRecommendations(totalEvents, failedLogins, suspiciousActivities),
        'generated_at': DateTime.now().toIso8601String(),
        'events': securityEvents,
      };
      
      Logger.info('Security report generated', name: 'SecurityAudit');
      
      return report;
      
    } catch (e) {
      Logger.error('Failed to generate security report', error: e, name: 'SecurityAudit');
      return {
        'error': e.toString(),
        'generated_at': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Calculate security score
  double _calculateSecurityScore(int totalEvents, int failedLogins, int suspiciousActivities) {
    double score = 100.0; // Start with perfect score
    
    // Deduct points for failed logins
    score -= (failedLogins * 2);
    
    // Deduct points for suspicious activities
    score -= (suspiciousActivities * 5);
    
    // Deduct points for high volume of events
    if (totalEvents > 1000) {
      score -= 10;
    }
    
    return score.clamp(0.0, 100.0);
  }

  /// Calculate risk level
  String _calculateRiskLevel(int totalEvents, int failedLogins, int suspiciousActivities) {
    final score = _calculateSecurityScore(totalEvents, failedLogins, suspiciousActivities);
    
    if (score >= 80) {
      return 'low';
    } else if (score >= 60) {
      return 'medium';
    } else if (score >= 40) {
      return 'high';
    } else {
      return 'critical';
    }
  }

  /// Generate security recommendations
  List<String> _generateSecurityRecommendations(int totalEvents, int failedLogins, int suspiciousActivities) {
    final recommendations = <String>[];
    
    if (failedLogins > 5) {
      recommendations.add('Consider implementing account lockout after multiple failed login attempts');
    }
    
    if (suspiciousActivities > 2) {
      recommendations.add('Review user access patterns and consider additional authentication measures');
    }
    
    if (totalEvents > 1000) {
      recommendations.add('Monitor for potential automated attacks or bot activity');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Security posture appears normal');
    }
    
    return recommendations;
  }

  /// Clean up old audit logs
  Future<void> cleanupOldAuditLogs() async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: 90));
      
      final oldLogsQuery = _auditCollection
          .where('timestamp', isLessThan: cutoffDate)
          .limit(1000);
      
      final oldLogs = await oldLogsQuery.get();
      
      for (final doc in oldLogs.docs) {
        await doc.reference.delete();
      }
      
      Logger.info('Cleaned up ${oldLogs.length} old audit logs', name: 'SecurityAudit');
      
    } catch (e) {
      Logger.error('Failed to cleanup old audit logs', error: e, name: 'SecurityAudit');
    }
  }

  /// Get security statistics
  Future<Map<String, dynamic>> getSecurityStatistics() async {
    try {
      final now = DateTime.now();
      final last24Hours = now.subtract(Duration(hours: 24));
      final last7Days = now.subtract(Duration(days: 7));
      final last30Days = now.subtract(Duration(days: 30));
      
      // Get statistics for different time periods
      final last24HoursQuery = await _auditCollection
          .where('timestamp', isGreaterThanOrEqualTo: last24Hours)
          .get();
      
      final last7DaysQuery = await _auditCollection
          .where('timestamp', isGreaterThanOrEqualTo: last7Days)
          .get();
      
      final last30DaysQuery = await _auditCollection
          .where('timestamp', isGreaterThanOrEqualTo: last30Days)
          .get();
      
      final suspiciousQuery = await _suspiciousActivityCollection
          .where('timestamp', isGreaterThanOrEqualTo: last7Days)
          .get();
      
      return {
        'last_24_hours': {
          'total_events': last24HoursQuery.docs.length,
          'failed_logins': last24HoursQuery.docs.where((doc) => doc.data()['event_type'] == 'login_failed').length,
          'suspicious_activities': last24HoursQuery.docs.where((doc) => doc.data()['event_type'] == 'suspicious_activity').length,
        },
        'last_7_days': {
          'total_events': last7DaysQuery.docs.length,
          'failed_logins': last7DaysQuery.docs.where((doc) => doc.data()['event_type'] == 'login_failed').length,
          'suspicious_activities': last7DaysQuery.docs.where((doc) => doc.data()['event_type'] == 'suspicious_activity').length,
        },
        'last_30_days': {
          'total_events': last30DaysQuery.docs.length,
          'failed_logins': last30DaysQuery.docs.where((doc) => doc.data()['event_type'] == 'login_failed').length,
          'suspicious_activities': last30DaysQuery.docs.where((doc) => doc.data()['event_type'] == 'suspicious_activity').length,
        },
        'suspicious_activities': {
          'total': suspiciousQuery.docs.length,
          'by_severity': _groupSuspiciousActivitiesBySeverity(suspiciousQuery.docs),
          'by_type': _groupSuspiciousActivitiesByType(suspiciousQuery.docs),
        },
        'generated_at': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      Logger.error('Failed to get security statistics', error: e, name: 'SecurityAudit');
      return {
        'error': e.toString(),
        'generated_at': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Group suspicious activities by severity
  Map<String, int> _groupSuspiciousActivitiesBySeverity(List<QueryDocumentSnapshot> activities) {
    final Map<String, int> severityCount = {};
    
    for (final activity in activities) {
      final severity = activity.data()['severity'] as String? ?? 'medium';
      severityCount[severity] = (severityCount[severity] ?? 0) + 1;
    }
    
    return severityCount;
  }

  /// Group suspicious activities by type
  Map<String, int> _groupSuspiciousActivitiesByType(List<QueryDocumentSnapshot> activities) {
    final Map<String, int> typeCount = {};
    
    for (final activity in activities) {
      final type = activity.data()['activity_type'] as String? ?? 'unknown';
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }
    
    return typeCount;
  }

  /// Schedule regular security audit
  Future<void> scheduleRegularSecurityAudit() async {
    try {
      // This would be called by a background job
      await cleanupOldAuditLogs();
      
      // Check for suspicious patterns across all users
      await _performGlobalSecurityCheck();
      
      Logger.info('Regular security audit completed', name: 'SecurityAudit');
      
    } catch (e) {
      Logger.error('Failed to perform regular security audit', error: e, name: 'SecurityAudit');
    }
  }

  /// Perform global security check
  Future<void> _performGlobalSecurityCheck() async {
    try {
      // Check for multiple failed logins across all users
      final now = DateTime.now();
      final oneHourAgo = now.subtract(Duration(hours: 1));
      
      final failedLoginsQuery = await _accessLogCollection
          .where('action', isEqualTo: 'login')
          .where('success', isEqualTo: false)
          .where('timestamp', isGreaterThanOrEqualTo: oneHourAgo)
          .get();

      // Group by user and check for patterns
      final Map<String, int> userFailedLogins = {};
      for (final doc in failedLoginsQuery.docs) {
        final userId = doc.data()['user_id'] as String;
        userFailedLogins[userId] = (userFailedLogins[userId] ?? 0) + 1;
      }
      
      // Flag users with multiple failed logins
      for (final entry in userFailedLogins.entries) {
        if (entry.value >= 5) {
          await logSuspiciousActivity(
            userId: entry.key,
            activityType: 'multiple_failed_logins',
            description: 'Multiple failed login attempts detected',
            evidence: {
              'failed_attempts': entry.value,
              'time_window': '1 hour',
            },
          );
        }
      }
      
    } catch (e) {
      Logger.error('Failed to perform global security check', error: e, name: 'SecurityAudit');
    }
  }
}
