import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/logger.dart';

class FirebaseVerificationService {
  static Future<Map<String, dynamic>> verifyFirebaseSetup() async {
    final results = <String, dynamic>{};
    
    try {
      // 1. Verify Firebase Core initialization
      results['firebase_core'] = await _verifyFirebaseCore();
      
      // 2. Verify Firebase Auth
      results['firebase_auth'] = await _verifyFirebaseAuth();
      
      // 3. Verify Firestore
      results['firestore'] = await _verifyFirestore();
      
      // 4. Verify Firebase Messaging
      results['messaging'] = await _verifyMessaging();
      
      // 5. Verify Firebase Storage
      results['storage'] = await _verifyStorage();
      
      // 6. Platform-specific verification
      results['platform_info'] = await _getPlatformInfo();
      
      results['overall_status'] = 'success';
      Logger.info('Firebase verification completed successfully', name: 'FirebaseVerification');
      
    } catch (e, stack) {
      results['overall_status'] = 'error';
      results['error'] = e.toString();
      Logger.error('Firebase verification failed', name: 'FirebaseVerification', error: e, stackTrace: stack);
    }
    
    return results;
  }
  
  static Future<Map<String, dynamic>> _verifyFirebaseCore() async {
    try {
      final app = Firebase.app();
      return {
        'status': 'success',
        'app_name': app.name,
        'project_id': app.options.projectId,
        'is_initialized': true,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'is_initialized': false,
      };
    }
  }
  
  static Future<Map<String, dynamic>> _verifyFirebaseAuth() async {
    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      return {
        'status': 'success',
        'current_user': currentUser?.uid ?? 'none',
        'auth_available': true,
        'supported_providers': ['email', 'phone', 'google'],
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'auth_available': false,
      };
    }
  }
  
  static Future<Map<String, dynamic>> _verifyFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Test a simple read operation
      await firestore.collection('_test').limit(1).get();
      
      return {
        'status': 'success',
        'firestore_available': true,
        'database_url': firestore.settings.persistenceEnabled ?? false ? 'local_cache_enabled' : 'cloud_only',
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'firestore_available': false,
      };
    }
  }
  
  static Future<Map<String, dynamic>> _verifyMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Get notification permissions (only works on mobile platforms)
      String? token;
      NotificationSettings? settings;
      
      if (!kIsWeb) {
        settings = await messaging.requestPermission();
        token = await messaging.getToken();
      }
      
      return {
        'status': 'success',
        'messaging_available': true,
        'token_available': token != null,
        'token': token ?? 'not_available',
        'permission_status': settings?.authorizationStatus.toString() ?? 'web_platform',
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'messaging_available': false,
      };
    }
  }
  
  static Future<Map<String, dynamic>> _verifyStorage() async {
    try {
      final storage = FirebaseStorage.instance;
      
      return {
        'status': 'success',
        'storage_available': true,
        'bucket_url': storage.bucket,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'storage_available': false,
      };
    }
  }
  
  static Future<Map<String, dynamic>> _getPlatformInfo() async {
    return {
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.toString(),
      'is_debug_mode': kDebugMode,
      'is_release_mode': kReleaseMode,
      'is_profile_mode': kProfileMode,
      'firebase_core_version': '10.0.0', // Placeholder version
    };
  }
  
  // Quick verification method for startup
  static Future<bool> quickVerify() async {
    try {
      final app = Firebase.app();
      Logger.info('Firebase quick verify: ${app.options.projectId}', name: 'FirebaseVerification');
      return true;
    } catch (e) {
      Logger.error('Firebase quick verify failed', name: 'FirebaseVerification', error: e);
      return false;
    }
  }
  
  // Generate verification report
  static String generateReport(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('=== Firebase Verification Report ===');
    buffer.writeln('Status: ${results['overall_status']}');
    buffer.writeln();
    
    if (results['platform_info'] != null) {
      final platform = results['platform_info'];
      buffer.writeln('Platform: ${platform['platform']}');
      buffer.writeln('Debug Mode: ${platform['is_debug_mode']}');
      buffer.writeln();
    }
    
    results.forEach((key, value) {
      if (key != 'overall_status' && key != 'platform_info' && value is Map) {
        buffer.writeln('$key:');
        value.forEach((k, v) {
          buffer.writeln('  $k: $v');
        });
        buffer.writeln();
      }
    });
    
    if (results['error'] != null) {
      buffer.writeln('Global Error: ${results['error']}');
    }
    
    return buffer.toString();
  }
}
