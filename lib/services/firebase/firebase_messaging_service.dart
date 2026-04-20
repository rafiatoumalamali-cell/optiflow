import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../providers/notification_provider.dart';
import '../../utils/logger.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Define the Android channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  /// Initializes FCM and sets up message handlers.
  Future<void> initialize(NotificationProvider notificationProvider) async {
    // 1. Request permissions (especially for iOS and Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      Logger.info('FCM: User granted permission', name: 'FirebaseMessagingService');
    } else {
      Logger.warning('FCM: User declined or has not accepted permission', name: 'FirebaseMessagingService');
    }

    // 2. Initialize Local Notifications for Android Foreground
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        Logger.info('Local Notification Clicked: ${response.payload}', name: 'FirebaseMessagingService');
        // Handle local notification click if needed
      },
    );

    // Create the high importance channel
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Handle background message redirection (when app is opened via notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Logger.info('FCM: App opened via notification: ${message.data}', name: 'FirebaseMessagingService');
      notificationProvider.handleRemoteMessage(message);
    });

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger.info('FCM: Message received in foreground: ${message.notification?.title}', name: 'FirebaseMessagingService');
      
      // Update UI state
      notificationProvider.handleRemoteMessage(message);

      // Show local notification for Android
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // 5. Handle initial message (when app is opened from a terminated state)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
       Logger.info('FCM: Terminated app opened via notification', name: 'FirebaseMessagingService');
       notificationProvider.handleRemoteMessage(initialMessage);
    }
  }

  /// Shows a local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android.smallIcon,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Fetches the unique FCM token for this device.
  Future<String?> getToken() async {
    try {
      String? token = await _fcm.getToken();
      Logger.info('FCM: Token: $token', name: 'FirebaseMessagingService');
      return token;
    } catch (e, stack) {
      Logger.error('FCM: Failed to get token', name: 'FirebaseMessagingService', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Updates the FCM token in the user's Firestore document.
  Future<void> updateTokenInFirestore(String userId) async {
    String? token = await getToken();
    if (token != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'fcm_token': token,
          'last_token_update': FieldValue.serverTimestamp(),
        });
        Logger.info('FCM: Token updated for user $userId', name: 'FirebaseMessagingService');
      } catch (e, stack) {
        Logger.error('FCM: Failed to update token in Firestore', name: 'FirebaseMessagingService', error: e, stackTrace: stack);
      }
    }
  }
}
