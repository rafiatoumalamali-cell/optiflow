import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  void handleRemoteMessage(RemoteMessage message) {
    // If there's a notification object, use it. Otherwise, look for data.
    String title = message.notification?.title ?? message.data['title'] ?? 'New Update';
    String body = message.notification?.body ?? message.data['body'] ?? '';

    final newNotification = NotificationModel(
      notificationId: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user', // Fixed for demo, should be dynamic in production
      title: title,
      body: body,
      isRead: false,
      createdAt: DateTime.now(),
    );
    
    _notifications.insert(0, newNotification);
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.notificationId == id);
    if (index != -1) {
      final old = _notifications[index];
      _notifications[index] = NotificationModel(
        notificationId: old.notificationId,
        userId: old.userId,
        title: old.title,
        body: old.body,
        isRead: true,
        createdAt: old.createdAt,
      );
      notifyListeners();
    }
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
