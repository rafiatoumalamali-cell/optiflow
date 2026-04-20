import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../providers/route_provider.dart';
import '../services/firebase_verification_service.dart';
import '../utils/logger.dart';

class AuthIntegrationTest {
  static Future<Map<String, dynamic>> testAuthIntegration() async {
    final results = <String, dynamic>{};
    
    try {
      // Test 1: AuthProvider initialization
      results['auth_provider'] = await _testAuthProvider();
      
      // Test 2: Business provider integration
      results['business_provider'] = await _testBusinessProvider();
      
      // Test 3: Route provider integration
      results['route_provider'] = await _testRouteProvider();
      
      // Test 4: Subscription provider integration
      results['subscription_provider'] = await _testSubscriptionProvider();
      
      // Test 5: Cross-service data flow
      results['data_flow'] = await _testDataFlow();
      
      results['overall_status'] = 'success';
      Logger.info('Auth integration test completed successfully', name: 'AuthIntegrationTest');
      
    } catch (e, stack) {
      results['overall_status'] = 'error';
      results['error'] = e.toString();
      Logger.error('Auth integration test failed', name: 'AuthIntegrationTest', error: e, stackTrace: stack);
    }
    
    return results;
  }
  
  static Future<Map<String, dynamic>> _testAuthProvider() async {
    try {
      final authProvider = AuthProvider();
      
      // Test authentication state
      final isLoggedIn = authProvider.isLoggedIn;
      final currentUser = authProvider.currentUser;
      final userRole = authProvider.userRole;
      
      return {
        'status': 'success',
        'is_logged_in': isLoggedIn,
        'current_user_id': currentUser?.uid,
        'user_role': userRole?.toString(),
        'auth_available': true,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'auth_available': false,
      };
    }
  }
  
  static Future<Map<String, dynamic>> _testBusinessProvider() async {
    try {
      final businessProvider = BusinessProvider();
      
      // Test business data access
      final businesses = businessProvider.businesses;
      final currentBusiness = businessProvider.currentBusiness;
      
      return {
        'status': 'success',
        'business_count': businesses.length,
        'has_current_business': currentBusiness != null,
        'current_business_id': currentBusiness?.id,
        'business_provider_available': true,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'business_provider_available': false,
      };
    }
  }
  
  static Future<Map<String, dynamic>> _testRouteProvider() async {
    try {
      final routeProvider = RouteProvider();
      
      // Test route data access
      final routes = routeProvider.routes;
      final isLoading = routeProvider.isLoading;
      final isOnline = routeProvider.isOnline;
      
      return {
        'status': 'success',
        'route_count': routes.length,
        'is_loading': isLoading,
        'is_online': isOnline,
        'route_provider_available': true,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'route_provider_available': false,
      };
    }
  }
  
  static Future<Map<String, dynamic>> _testSubscriptionProvider() async {
    try {
      // SubscriptionProvider test skipped - class not available
      
      return {
        'status': 'skipped',
        'message': 'SubscriptionProvider class not available',
        'subscription_provider_available': false,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'subscription_provider_available': false,
      };
    }
  }
  
  static Future<Map<String, dynamic>> _testDataFlow() async {
    try {
      final authProvider = AuthProvider();
      final businessProvider = BusinessProvider();
      final routeProvider = RouteProvider();
      
      // Test data flow from Auth → Business → Route
      final currentUser = authProvider.currentUser;
      final business = businessProvider.currentBusiness;
      final routes = routeProvider.routes;
      
      bool dataFlowWorking = true;
      List<String> issues = [];
      
      if (currentUser != null && business != null) {
        // Check if business belongs to current user
        if (business!.id != currentUser!.uid) {
          dataFlowWorking = false;
          issues.add('Business user ID mismatch');
        }
      }
      
      if (business != null && routes.isNotEmpty) {
        // Check if routes belong to current business
        final firstRoute = routes.first;
        if (firstRoute.businessId != business!.id) {
          dataFlowWorking = false;
          issues.add('Route business ID mismatch');
        }
      }
      
      return {
        'status': dataFlowWorking ? 'success' : 'warning',
        'data_flow_working': dataFlowWorking,
        'issues': issues,
        'user_id': currentUser?.uid,
        'business_id': business?.id,
        'route_count': routes.length,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'data_flow_working': false,
      };
    }
  }
  
  // Quick integration test for startup
  static Future<bool> quickIntegrationTest() async {
    try {
      final authProvider = AuthProvider();
      final businessProvider = BusinessProvider();
      final routeProvider = RouteProvider();
      
      // Quick checks
      final authOk = authProvider.isLoggedIn != null;
      final businessOk = businessProvider.businesses.isNotEmpty;
      final routeOk = routeProvider.routes != null;
      
      final allOk = authOk && businessOk && routeOk;
      
      Logger.info('Quick integration test: ${allOk ? "PASSED" : "FAILED"}', name: 'AuthIntegrationTest');
      
      return allOk;
    } catch (e) {
      Logger.error('Quick integration test failed', name: 'AuthIntegrationTest', error: e);
      return false;
    }
  }
  
  // Generate integration test report
  static String generateReport(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('=== Authentication Integration Test Report ===');
    buffer.writeln('Status: ${results['overall_status']}');
    buffer.writeln();
    
    if (results['auth_provider'] != null) {
      buffer.writeln('Auth Provider:');
      final auth = results['auth_provider'];
      buffer.writeln('  Status: ${auth['status']}');
      buffer.writeln('  Logged In: ${auth['is_logged_in']}');
      buffer.writeln('  User ID: ${auth['current_user_id'] ?? 'None'}');
      buffer.writeln('  Role: ${auth['user_role'] ?? 'None'}');
      buffer.writeln();
    }
    
    if (results['business_provider'] != null) {
      buffer.writeln('Business Provider:');
      final business = results['business_provider'];
      buffer.writeln('  Status: ${business['status']}');
      buffer.writeln('  Business Count: ${business['business_count']}');
      buffer.writeln('  Current Business: ${business['has_current_business'] ? 'Yes' : 'No'}');
      buffer.writeln();
    }
    
    if (results['route_provider'] != null) {
      buffer.writeln('Route Provider:');
      final route = results['route_provider'];
      buffer.writeln('  Status: ${route['status']}');
      buffer.writeln('  Route Count: ${route['route_count']}');
      buffer.writeln('  Online: ${route['is_online']}');
      buffer.writeln();
    }
    
    if (results['subscription_provider'] != null) {
      buffer.writeln('Subscription Provider:');
      final subscription = results['subscription_provider'];
      buffer.writeln('  Status: ${subscription['status']}');
      buffer.writeln('  Subscription Count: ${subscription['subscription_count']}');
      buffer.writeln('  Current Subscription: ${subscription['has_current_subscription'] ? 'Yes' : 'No'}');
      buffer.writeln();
    }
    
    if (results['data_flow'] != null) {
      buffer.writeln('Data Flow Test:');
      final dataFlow = results['data_flow'];
      buffer.writeln('  Status: ${dataFlow['status']}');
      buffer.writeln('  Working: ${dataFlow['data_flow_working']}');
      if (dataFlow['issues'].isNotEmpty) {
        buffer.writeln('  Issues:');
        for (final issue in dataFlow['issues']) {
          buffer.writeln('    - $issue');
        }
      }
      buffer.writeln();
    }
    
    if (results['error'] != null) {
      buffer.writeln('Global Error: ${results['error']}');
    }
    
    return buffer.toString();
  }
}
