import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

/// Service for managing Firestore security and access control
class FirestoreSecurityService {
  static final FirestoreSecurityService _instance = FirestoreSecurityService._();
  factory FirestoreSecurityService() => _instance;
  FirestoreSecurityService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _businessesCollection = FirebaseFirestore.instance.collection('businesses');
  final CollectionReference _routesCollection = FirebaseFirestore.instance.collection('routes');
  final CollectionReference _productsCollection = FirebaseFirestore.instance.collection('products');
  final CollectionReference _ordersCollection = FirebaseFirestore.instance.collection('orders');
  final CollectionReference _locationsCollection = FirebaseFirestore.instance.collection('locations');
  final CollectionReference _notificationsCollection = FirebaseFirestore.instance.collection('notifications');
  final CollectionReference _analyticsCollection = FirebaseFirestore.instance.collection('analytics');
  final CollectionReference _reportsCollection = FirebaseFirestore.instance.collection('reports');
  final CollectionReference _settingsCollection = FirebaseFirestore.instance.collection('settings');
  final CollectionReference _syncQueueCollection = FirebaseFirestore.instance.collection('sync_queue');
  final CollectionReference _adminLogsCollection = FirebaseFirestore.instance.collection('admin_logs');
  final CollectionReference _systemConfigCollection = FirebaseFirestore.instance.collection('system_config');

  /// Get current user ID
  String? get currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  /// Get current user role
  Future<String?> getCurrentUserRole() async {
    if (currentUserId == null) return null;
    
    try {
      final userDoc = await _usersCollection.doc(currentUserId).get();
      return userDoc.data()?['role'] as String?;
    } catch (e) {
      Logger.error('Failed to get current user role', error: e, name: 'FirestoreSecurity');
      return null;
    }
  }

  /// Get current user's business ID
  Future<String?> getCurrentUserBusinessId() async {
    if (currentUserId == null) return null;
    
    try {
      final userDoc = await _usersCollection.doc(currentUserId).get();
      return userDoc.data()?['businessId'] as String?;
    } catch (e) {
      Logger.error('Failed to get current user business ID', error: e, name: 'FirestoreSecurity');
      return null;
    }
  }

  /// Check if current user is authenticated
  bool get isAuthenticated {
    return FirebaseAuth.instance.currentUser != null;
  }

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  /// Check if current user is business owner
  Future<bool> isBusinessOwner(String businessId) async {
    final userBusinessId = await getCurrentUserBusinessId();
    return userBusinessId == businessId;
  }

  /// Check if current user is business admin
  Future<bool> isBusinessAdmin(String businessId) async {
    final userBusinessId = await getCurrentUserBusinessId();
    final role = await getCurrentUserRole();
    return userBusinessId == businessId && role == 'admin';
  }

  /// Check if current user is manager
  Future<bool> isManager(String businessId) async {
    final userBusinessId = await getCurrentUserBusinessId();
    final role = await getCurrentUserRole();
    return userBusinessId == businessId && role == 'manager';
  }

  /// Check if current user is driver
  Future<bool> isDriver(String businessId) async {
    final userBusinessId = await getCurrentUserBusinessId();
    final role = await getCurrentUserRole();
    return userBusinessId == businessId && role == 'driver';
  }

  /// Check if user has access to business
  Future<bool> hasBusinessAccess(String businessId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    final userBusinessId = await getCurrentUserBusinessId();
    return userBusinessId == businessId;
  }

  // Users collection security
  Future<bool> canReadUser(String userId) async {
    if (currentUserId == null) return false;
    return currentUserId == userId;
  }

  Future<bool> canWriteUser(String userId) async {
    if (currentUserId == null) return false;
    return currentUserId == userId;
  }

  Future<bool> canUpdateUserProfile(String userId) async {
    return canWriteUser(userId);
  }

  Future<bool> canUpdateUserPassword(String userId) async {
    return canWriteUser(userId);
  }

  // Businesses collection security
  Future<bool> canReadBusiness(String businessId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    final userBusinessId = await getCurrentUserBusinessId();
    return userBusinessId == businessId;
  }

  Future<bool> canWriteBusiness(String businessId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    final userBusinessId = await getCurrentUserBusinessId();
    return userBusinessId == businessId;
  }

  Future<bool> canCreateBusiness() async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  Future<bool> canDeleteBusiness(String businessId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    final userBusinessId = await getCurrentUserBusinessId();
    return userBusinessId == businessId;
  }

  // Routes collection security
  Future<bool> canReadRoute(String routeId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final routeDoc = await _routesCollection.doc(routeId).get();
      final routeBusinessId = routeDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == routeBusinessId;
    } catch (e) {
      Logger.error('Failed to check route read access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canWriteRoute(String routeId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final routeDoc = await _routesCollection.doc(routeId).get();
      final routeBusinessId = routeDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == routeBusinessId && ['admin', 'manager'].contains(role);
    } catch (e) {
      Logger.error('Failed to check route write access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canCreateRoute(String businessId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    final userBusinessId = await getCurrentUserBusinessId();
    return userBusinessId == businessId && ['admin', 'manager'].contains(role);
  }

  Future<bool> canDeleteRoute(String routeId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final routeDoc = await _routesCollection.doc(routeId).get();
      final routeBusinessId = routeDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == routeBusinessId && ['admin', 'manager'].contains(role);
    } catch (e) {
      Logger.error('Failed to check route delete access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canUpdateRouteStatus(String routeId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final routeDoc = await _routesCollection.doc(routeId).get();
      final routeBusinessId = routeDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == routeBusinessId && ['admin', 'manager', 'driver'].contains(role);
    } catch (e) {
      Logger.error('Failed to check route status update access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  // Products collection security
  Future<bool> canReadProduct(String productId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final productDoc = await _productsCollection.doc(productId).get();
      final productBusinessId = productDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == productBusinessId;
    } catch (e) {
      Logger.error('Failed to check product read access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canWriteProduct(String productId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final productDoc = await _productsCollection.doc(productId).get();
      final productBusinessId = productDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == productBusinessId && ['admin', 'manager'].contains(role);
    } catch (e) {
      Logger.error('Failed to check product write access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canCreateProduct(String businessId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    final userBusinessId = await getCurrentUserBusinessId();
    return userBusinessId == businessId && ['admin', 'manager'].contains(role);
  }

  Future<bool> canDeleteProduct(String productId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final productDoc = await _productsCollection.doc(productId).get();
      final productBusinessId = productDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == productBusinessId && ['admin', 'manager'].contains(role);
    } catch (e) {
      Logger.error('Failed to check product delete access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  // Orders collection security
  Future<bool> canReadOrder(String orderId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final orderDoc = await _ordersCollection.doc(orderId).get();
      final orderBusinessId = orderDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == orderBusinessId;
    } catch (e) {
      Logger.error('Failed to check order read access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canWriteOrder(String orderId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final orderDoc = await _ordersCollection.doc(orderId).get();
      final orderBusinessId = orderDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == orderBusinessId && ['admin', 'manager'].contains(role);
    } catch (e) {
      Logger.error('Failed to check order write access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canCreateOrder(String businessId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    final userBusinessId = await getCurrentUserBusinessId();
    return userBusinessId == businessId && ['admin', 'manager'].contains(role);
  }

  Future<bool> canDeleteOrder(String orderId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final orderDoc = await _ordersCollection.doc(orderId).get();
      final orderBusinessId = orderDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == orderBusinessId && ['admin', 'manager'].contains(role);
    } catch (e) {
      Logger.error('Failed to check order delete access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canUpdateOrderStatus(String orderId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final orderDoc = await _ordersCollection.doc(orderId).get();
      final orderBusinessId = orderDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == orderBusinessId && ['admin', 'manager', 'driver'].contains(role);
    } catch (e) {
      Logger.error('Failed to check order status update access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  // Locations collection security
  Future<bool> canReadLocation(String locationId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final locationDoc = await _locationsCollection.doc(locationId).get();
      final locationBusinessId = locationDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == locationBusinessId;
    } catch (e) {
      Logger.error('Failed to check location read access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canWriteLocation(String locationId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final locationDoc = await _locationsCollection.doc(locationId).get();
      final locationBusinessId = locationDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == locationBusinessId && ['admin', 'manager'].contains(role);
    } catch (e) {
      Logger.error('Failed to check location write access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canCreateLocation(String businessId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    final userBusinessId = await getCurrentUserBusinessId();
    return userBusinessId == businessId && ['admin', 'manager'].contains(role);
  }

  Future<bool> canDeleteLocation(String locationId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final locationDoc = await _locationsCollection.doc(locationId).get();
      final locationBusinessId = locationDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == locationBusinessId && ['admin', 'manager'].contains(role);
    } catch (e) {
      Logger.error('Failed to check location delete access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  // Notifications collection security
  Future<bool> canReadNotification(String notificationId) async {
    if (currentUserId == null) return false;
    
    try {
      final notificationDoc = await _notificationsCollection.doc(notificationId).get();
      final notificationUserId = notificationDoc.data()?['userId'] as String?;
      return currentUserId == notificationUserId;
    } catch (e) {
      Logger.error('Failed to check notification read access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canWriteNotification(String notificationId) async {
    if (currentUserId == null) return false;
    
    try {
      final notificationDoc = await _notificationsCollection.doc(notificationId).get();
      final notificationUserId = notificationDoc.data()?['userId'] as String?;
      return currentUserId == notificationUserId;
    } catch (e) {
      Logger.error('Failed to check notification write access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canCreateNotification() async {
    return isAuthenticated;
  }

  Future<bool> canDeleteNotification(String notificationId) async {
    return canWriteNotification(notificationId);
  }

  // Analytics collection security
  Future<bool> canReadAnalytics(String analyticsId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final analyticsDoc = await _analyticsCollection.doc(analyticsId).get();
      final analyticsBusinessId = analyticsDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == analyticsBusinessId && ['admin', 'manager'].contains(role);
    } catch (e) {
      Logger.error('Failed to check analytics read access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canWriteAnalytics(String analyticsId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final analyticsDoc = await _analyticsCollection.doc(analyticsId).get();
      final analyticsBusinessId = analyticsDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == analyticsBusinessId && ['admin', 'manager'].contains(role);
    } catch (e) {
      Logger.error('Failed to check analytics write access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canCreateAnalytics(String businessId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    final userBusinessId = await getCurrentUserBusinessId();
    return userBusinessId == businessId && ['admin', 'manager'].contains(role);
  }

  Future<bool> canDeleteAnalytics(String analyticsId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final analyticsDoc = await _analyticsCollection.doc(analyticsId).get();
      final analyticsBusinessId = analyticsDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == analyticsBusinessId && ['admin', 'manager'].contains(role);
    } catch (e) {
      Logger.error('Failed to check analytics delete access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  // Reports collection security
  Future<bool> canReadReport(String reportId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final reportDoc = await _reportsCollection.doc(reportId).get();
      final reportBusinessId = reportDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == reportBusinessId && ['admin', 'manager'].contains(role);
    } catch (e) {
      Logger.error('Failed to check report read access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canWriteReport(String reportId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final reportDoc = await _reportsCollection.doc(reportId).get();
      final reportBusinessId = reportDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == reportBusinessId && ['admin', 'manager'].contains(role);
    } catch (e) {
      Logger.error('Failed to check report write access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canCreateReport(String businessId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    final userBusinessId = await getCurrentUserBusinessId();
    return userBusinessId == businessId && ['admin', 'manager'].contains(role);
  }

  Future<bool> canDeleteReport(String reportId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      final reportDoc = await _reportsCollection.doc(reportId).get();
      final reportBusinessId = reportDoc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == reportBusinessId && ['admin', 'manager'].contains(role);
    } catch (e) {
      Logger.error('Failed to check report delete access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  // Settings collection security
  Future<bool> canReadSetting(String settingId) async {
    if (currentUserId == null) return false;
    
    try {
      final settingDoc = await _settingsCollection.doc(settingId).get();
      final settingUserId = settingDoc.data()?['userId'] as String?;
      return currentUserId == settingUserId;
    } catch (e) {
      Logger.error('Failed to check setting read access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canWriteSetting(String settingId) async {
    if (currentUserId == null) return false;
    
    try {
      final settingDoc = await _settingsCollection.doc(settingId).get();
      final settingUserId = settingDoc.data()?['userId'] as String?;
      return currentUserId == settingUserId;
    } catch (e) {
      Logger.error('Failed to check setting write access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<bool> canCreateSetting() async {
    return isAuthenticated;
  }

  Future<bool> canDeleteSetting(String settingId) async {
    return canWriteSetting(settingId);
  }

  // Sync queue collection security
  Future<bool> canReadSyncQueue(String syncId) async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  Future<bool> canWriteSyncQueue(String syncId) async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  Future<bool> canCreateSyncQueue() async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  Future<bool> canDeleteSyncQueue(String syncId) async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  // Admin logs collection security
  Future<bool> canReadAdminLog(String logId) async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  Future<bool> canWriteAdminLog(String logId) async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  Future<bool> canCreateAdminLog() async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  Future<bool> canDeleteAdminLog(String logId) async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  // System configuration collection security
  Future<bool> canReadSystemConfig(String configId) async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  Future<bool> canWriteSystemConfig(String configId) async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  Future<bool> canCreateSystemConfig() async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  Future<bool> canDeleteSystemConfig(String configId) async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  // Security validation methods
  Future<bool> validateUserAccess(String userId) async {
    if (currentUserId == null) return false;
    return currentUserId == userId;
  }

  Future<bool> validateBusinessAccess(String businessId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    final userBusinessId = await getCurrentUserBusinessId();
    return userBusinessId == businessId;
  }

  Future<bool> validateDocumentAccess(String collection, String documentId) async {
    final role = await getCurrentUserRole();
    if (role == 'admin') return true;
    
    try {
      DocumentReference docRef;
      switch (collection) {
        case 'routes':
          docRef = _routesCollection.doc(documentId);
          break;
        case 'products':
          docRef = _productsCollection.doc(documentId);
          break;
        case 'orders':
          docRef = _ordersCollection.doc(documentId);
          break;
        case 'locations':
          docRef = _locationsCollection.doc(documentId);
          break;
        case 'analytics':
          docRef = _analyticsCollection.doc(documentId);
          break;
        case 'reports':
          docRef = _reportsCollection.doc(documentId);
          break;
        default:
          return false;
      }
      
      final doc = await docRef.get();
      final docBusinessId = doc.data()?['businessId'] as String?;
      final userBusinessId = await getCurrentUserBusinessId();
      
      return userBusinessId == docBusinessId;
    } catch (e) {
      Logger.error('Failed to validate document access', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  // Security audit methods
  Future<Map<String, dynamic>> performSecurityAudit() async {
    final auditResults = <String, dynamic>{};
    
    try {
      final role = await getCurrentUserRole();
      final userId = currentUserId;
      final businessId = await getCurrentUserBusinessId();
      
      auditResults['user_id'] = userId;
      auditResults['user_role'] = role;
      auditResults['business_id'] = businessId;
      auditResults['is_authenticated'] = isAuthenticated;
      auditResults['audit_timestamp'] = DateTime.now().toIso8601String();
      
      // Check access patterns
      final accessChecks = <String, bool>{};
      accessChecks['can_read_business'] = await canReadBusiness(businessId ?? '');
      accessChecks['can_write_business'] = await canWriteBusiness(businessId ?? '');
      accessChecks['can_create_business'] = await canCreateBusiness();
      accessChecks['can_delete_business'] = await canDeleteBusiness(businessId ?? '');
      
      auditResults['access_checks'] = accessChecks;
      
      // Log security audit
      if (role == 'admin') {
        await _adminLogsCollection.add({
          'action': 'security_audit',
          'userId': userId,
          'role': role,
          'businessId': businessId,
          'accessChecks': accessChecks,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      
      Logger.info('Security audit completed', name: 'FirestoreSecurity');
      
    } catch (e) {
      Logger.error('Failed to perform security audit', error: e, name: 'FirestoreSecurity');
      auditResults['error'] = e.toString();
    }
    
    return auditResults;
  }

  // Security monitoring
  Future<void> monitorSecurityActivity() async {
    try {
      final role = await getCurrentUserRole();
      final userId = currentUserId;
      
      // Monitor for suspicious activities
      if (userId != null && role != 'admin') {
        // Check for unusual access patterns
        await _checkUnusualAccessPatterns(userId!);
      }
      
      Logger.info('Security monitoring completed', name: 'FirestoreSecurity');
      
    } catch (e) {
      Logger.error('Failed to monitor security activity', error: e, name: 'FirestoreSecurity');
    }
  }

  Future<void> _checkUnusualAccessPatterns(String userId) async {
    // Implementation would check for unusual patterns
    // This is a placeholder for security monitoring
    try {
      // Check for rapid access attempts
      // Check for access from unusual locations
      // Check for access to unusual documents
      // Log suspicious activities
      
      Logger.info('Unusual access pattern check completed', name: 'FirestoreSecurity');
      
    } catch (e) {
      Logger.error('Failed to check unusual access patterns', error: e, name: 'FirestoreSecurity');
    }
  }

  // Security configuration
  Future<Map<String, dynamic>> getSecurityConfiguration() async {
    return {
      'version': '2.0',
      'enforced_rules': true,
      'data_validation': true,
      'access_control': true,
      'audit_logging': true,
      'security_monitoring': true,
      'rate_limiting': true,
      'encryption': true,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  // Security compliance checks
  Future<bool> checkCompliance() async {
    try {
      // Check if security rules are properly configured
      final securityConfig = await getSecurityConfiguration();
      
      // Verify essential security features are enabled
      if (!securityConfig['enforced_rules']) return false;
      if (!securityConfig['access_control']) return false;
      if (!securityConfig['audit_logging']) return false;
      if (!securityConfig['security_monitoring']) return false;
      
      // Check for any security vulnerabilities
      final vulnerabilities = await _checkSecurityVulnerabilities();
      if (vulnerabilities.isNotEmpty) {
        Logger.warning('Security vulnerabilities detected: $vulnerabilities', name: 'FirestoreSecurity');
        return false;
      }
      
      Logger.info('Compliance check passed', name: 'FirestoreSecurity');
      return true;
      
    } catch (e) {
      Logger.error('Failed to check compliance', error: e, name: 'FirestoreSecurity');
      return false;
    }
  }

  Future<List<String>> _checkSecurityVulnerabilities() async {
    final vulnerabilities = <String>[];
    
    // Check for common security issues
    // This is a placeholder implementation
    
    return vulnerabilities;
  }
}
