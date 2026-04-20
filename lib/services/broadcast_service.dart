import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import '../utils/environment.dart';

class BroadcastService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Create broadcast notification
  static Future<String> createBroadcast({
    required String title,
    required String message,
    required String audience,
    required String region,
    required DateTime scheduledTime,
    required Map<String, dynamic> content,
  }) async {
    try {
      final broadcastDoc = await _firestore.collection('broadcasts').add({
        'title': title,
        'message': message,
        'audience': audience,
        'region': region,
        'scheduledTime': scheduledTime,
        'content': content,
        'status': 'scheduled',
        'createdAt': Timestamp.now(),
        'sentAt': null,
        'deliveryCount': 0,
        'failedCount': 0,
      });

      Logger.info('Broadcast created: ${broadcastDoc.id}', name: 'BroadcastService');
      return broadcastDoc.id;
    } catch (e, stack) {
      Logger.error('Error creating broadcast', name: 'BroadcastService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // Send broadcast notification via FCM
  static Future<void> sendBroadcast(String broadcastId) async {
    try {
      final broadcastDoc = await _firestore.collection('broadcasts').doc(broadcastId).get();
      
      if (!broadcastDoc.exists) {
        throw Exception('Broadcast not found');
      }

      final broadcastData = broadcastDoc.data()!;
      final audience = broadcastData['audience'] as String;
      final region = broadcastData['region'] as String;
      final title = broadcastData['title'] as String;
      final message = broadcastData['message'] as String;
      final content = broadcastData['content'] as Map<String, dynamic>;

      // Get target users based on audience and region
      final targetTokens = await _getTargetTokens(audience, region);
      
      if (targetTokens.isEmpty) {
        Logger.warning('No target tokens found for broadcast', name: 'BroadcastService');
        await _updateBroadcastStatus(broadcastId, 'completed', 0, 0);
        return;
      }

      // Send FCM messages in batches
      final results = await _sendFCMBatch(targetTokens, title, message, content);
      
      // Update broadcast status
      await _updateBroadcastStatus(broadcastId, 'completed', results['success'] ?? 0, results['failed'] ?? 0);
      
      Logger.info('Broadcast sent: $broadcastId, Success: ${results['success']}, Failed: ${results['failed']}', 
                  name: 'BroadcastService');
      
    } catch (e, stack) {
      Logger.error('Error sending broadcast', name: 'BroadcastService', error: e, stackTrace: stack);
      await _updateBroadcastStatus(broadcastId, 'failed', 0, 0);
      rethrow;
    }
  }

  // Get target FCM tokens based on audience and region
  static Future<List<String>> _getTargetTokens(String audience, String region) async {
    try {
      QuerySnapshot usersSnapshot;
      
      switch (audience) {
        case 'All Users':
          if (region == 'All Regions') {
            usersSnapshot = await _firestore
                .collection('users')
                .where('fcmToken', isNotEqualTo: null)
                .get();
          } else {
            usersSnapshot = await _firestore
                .collection('users')
                .where('fcmToken', isNotEqualTo: null)
                .where('region', isEqualTo: region)
                .get();
          }
          break;
        case 'Business Owners':
          if (region == 'All Regions') {
            usersSnapshot = await _firestore
                .collection('users')
                .where('fcmToken', isNotEqualTo: null)
                .where('role', isEqualTo: 'business_owner')
                .get();
          } else {
            usersSnapshot = await _firestore
                .collection('users')
                .where('fcmToken', isNotEqualTo: null)
                .where('role', isEqualTo: 'business_owner')
                .where('region', isEqualTo: region)
                .get();
          }
          break;
        case 'Drivers':
          if (region == 'All Regions') {
            usersSnapshot = await _firestore
                .collection('users')
                .where('fcmToken', isNotEqualTo: null)
                .where('role', isEqualTo: 'driver')
                .get();
          } else {
            usersSnapshot = await _firestore
                .collection('users')
                .where('fcmToken', isNotEqualTo: null)
                .where('role', isEqualTo: 'driver')
                .where('region', isEqualTo: region)
                .get();
          }
          break;
        default:
          return [];
      }

      return usersSnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['fcmToken'] as String?)
          .where((token) => token != null && token!.isNotEmpty)
          .cast<String>()
          .toList();
      
    } catch (e, stack) {
      Logger.error('Error getting target tokens', name: 'BroadcastService', error: e, stackTrace: stack);
      return [];
    }
  }

  // Send FCM messages in batches
  static Future<Map<String, int>> _sendFCMBatch(
    List<String> tokens,
    String title,
    String message,
    Map<String, dynamic> content,
  ) async {
    int successCount = 0;
    int failedCount = 0;
    
    // FCM batch size limit
    const batchSize = 500;
    
    for (int i = 0; i < tokens.length; i += batchSize) {
      final batch = tokens.skip(i).take(batchSize).toList();
      
      try {
        final response = await _sendFCMRequest(batch, title, message, content);
        
        if (response['success'] == true) {
          successCount += batch.length;
        } else {
          failedCount += batch.length;
        }
        
      } catch (e) {
        Logger.error('Batch FCM send failed', name: 'BroadcastService', error: e);
        failedCount += batch.length;
      }
    }
    
    return {'success': successCount, 'failed': failedCount};
  }

  // Send FCM request
  static Future<Map<String, dynamic>> _sendFCMRequest(
    List<String> tokens,
    String title,
    String message,
    Map<String, dynamic> content,
  ) async {
    try {
      final serverKey = _getFCMServerKey();
      if (serverKey.isEmpty) {
        throw Exception('FCM server key not configured');
      }

      final payload = {
        'notification': {
          'title': title,
          'body': message,
          'sound': 'default',
        },
        'data': {
          'type': 'broadcast',
          'content': jsonEncode(content),
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'registration_ids': tokens,
      };

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(payload),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'response': responseData};
      } else {
        return {'success': false, 'error': responseData};
      }
      
    } catch (e, stack) {
      Logger.error('FCM request failed', name: 'BroadcastService', error: e, stackTrace: stack);
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get FCM server key from environment or secure storage
  static String _getFCMServerKey() {
    // In production, this should come from secure storage or environment variables
    // For now, return a placeholder - this needs to be configured properly
    return Environment.isDevelopment 
        ? 'YOUR_FCM_SERVER_KEY_HERE' 
        : 'YOUR_PRODUCTION_FCM_SERVER_KEY';
  }

  // Update broadcast status
  static Future<void> _updateBroadcastStatus(
    String broadcastId,
    String status,
    int successCount,
    int failedCount,
  ) async {
    try {
      await _firestore.collection('broadcasts').doc(broadcastId).update({
        'status': status,
        'sentAt': Timestamp.now(),
        'deliveryCount': successCount,
        'failedCount': failedCount,
      });
    } catch (e, stack) {
      Logger.error('Error updating broadcast status', name: 'BroadcastService', error: e, stackTrace: stack);
    }
  }

  // Get all broadcasts
  static Future<List<Map<String, dynamic>>> getBroadcasts() async {
    try {
      final snapshot = await _firestore
          .collection('broadcasts')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
    } catch (e, stack) {
      Logger.error('Error getting broadcasts', name: 'BroadcastService', error: e, stackTrace: stack);
      return [];
    }
  }

  // Get broadcast statistics
  static Future<Map<String, dynamic>> getBroadcastStats() async {
    try {
      final snapshot = await _firestore.collection('broadcasts').get();
      
      int totalBroadcasts = snapshot.docs.length;
      int scheduledCount = 0;
      int completedCount = 0;
      int failedCount = 0;
      int totalDelivered = 0;
      int totalFailed = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        
        switch (status) {
          case 'scheduled':
            scheduledCount++;
            break;
          case 'completed':
            completedCount++;
            totalDelivered += (data['deliveryCount'] as num?)?.toInt() ?? 0;
            totalFailed += (data['failedCount'] as num?)?.toInt() ?? 0;
            break;
          case 'failed':
            failedCount++;
            break;
        }
      }

      return {
        'totalBroadcasts': totalBroadcasts,
        'scheduledCount': scheduledCount,
        'completedCount': completedCount,
        'failedCount': failedCount,
        'totalDelivered': totalDelivered,
        'totalFailed': totalFailed,
        'successRate': totalDelivered > 0 ? (totalDelivered / (totalDelivered + totalFailed) * 100) : 0.0,
      };
      
    } catch (e, stack) {
      Logger.error('Error getting broadcast stats', name: 'BroadcastService', error: e, stackTrace: stack);
      return {};
    }
  }

  // Schedule broadcast for future delivery
  static Future<void> scheduleBroadcast(String broadcastId, DateTime scheduledTime) async {
    try {
      await _firestore.collection('broadcasts').doc(broadcastId).update({
        'scheduledTime': Timestamp.fromDate(scheduledTime),
        'status': 'scheduled',
      });
      
      Logger.info('Broadcast scheduled: $broadcastId at $scheduledTime', name: 'BroadcastService');
      
    } catch (e, stack) {
      Logger.error('Error scheduling broadcast', name: 'BroadcastService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // Cancel scheduled broadcast
  static Future<void> cancelBroadcast(String broadcastId) async {
    try {
      await _firestore.collection('broadcasts').doc(broadcastId).update({
        'status': 'cancelled',
      });
      
      Logger.info('Broadcast cancelled: $broadcastId', name: 'BroadcastService');
      
    } catch (e, stack) {
      Logger.error('Error cancelling broadcast', name: 'BroadcastService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // Get broadcast delivery details
  static Future<Map<String, dynamic>> getBroadcastDetails(String broadcastId) async {
    try {
      final doc = await _firestore.collection('broadcasts').doc(broadcastId).get();
      
      if (!doc.exists) {
        throw Exception('Broadcast not found');
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      
      return data;
      
    } catch (e, stack) {
      Logger.error('Error getting broadcast details', name: 'BroadcastService', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
