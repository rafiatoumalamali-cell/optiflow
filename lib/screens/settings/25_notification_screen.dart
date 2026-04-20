import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    final notiProv = Provider.of<NotificationProvider>(context);
    final notifications = notiProv.notifications;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.eco, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            const Text('OptiFlow', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No notifications yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  const Text('We\'ll alert you of route updates here.', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notifications', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const Text('Stay updated on your fleet and routes.', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                final n = notifications[index - 1];
                return GestureDetector(
                  onTap: () => notiProv.markAsRead(n.notificationId),
                  child: _buildNotificationTile(
                    _getIconForTitle(n.title),
                    n.title,
                    n.body,
                    DateFormat('HH:mm').format(n.createdAt),
                    n.isRead ? Colors.grey[100]! : _getBgColorForTitle(n.title),
                    n.isRead ? AppColors.textLight : _getIconColorForTitle(n.title),
                    isRead: n.isRead,
                  ),
                );
              },
            ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, AppRoutes.homeDashboard);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.savedResults);
        },
      ),
    );
  }

  Widget _buildNotificationTile(IconData icon, String title, String body, String time, Color bgColor, Color iconColor, {required bool isRead}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                    Text(time, style: const TextStyle(fontSize: 8, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    if (title.contains('Route')) return Icons.route_outlined;
    if (title.contains('Delivery')) return Icons.local_shipping_outlined;
    return Icons.notifications_active_outlined;
  }

  Color _getBgColorForTitle(String title) {
    if (title.contains('Route')) return Colors.blue.shade50;
    if (title.contains('Delivery')) return Colors.green.shade50;
    return AppColors.primaryOrange.withOpacity(0.1);
  }

  Color _getIconColorForTitle(String title) {
    if (title.contains('Route')) return Colors.blue;
    if (title.contains('Delivery')) return AppColors.primaryGreen;
    return AppColors.primaryOrange;
  }
}
