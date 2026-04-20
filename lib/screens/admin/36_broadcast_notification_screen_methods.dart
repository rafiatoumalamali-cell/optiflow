import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import '../services/broadcast_service.dart';
import '../utils/logger.dart';

// Define AppColors if not imported
class AppColors {
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color textLight = Color(0xFF757575);
  static const Color textDark = Color(0xFF212529);
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color backgroundGray = Color(0xFFF5F5F5);
}

// Additional methods for BroadcastNotificationScreen

class BroadcastNotificationMethods extends StatefulWidget {
  const BroadcastNotificationMethods({Key? key}) : super(key: key);

  @override
  State<BroadcastNotificationMethods> createState() => _BroadcastNotificationMethodsState();
}

class _BroadcastNotificationMethodsState extends State<BroadcastNotificationMethods> {
  String _selectedRegion = 'All Regions';
  bool _isSending = false;
  bool _isImmediate = true;
  Map<String, dynamic>? _broadcastStats;
  List<Map<String, dynamic>> _recentBroadcasts = [];

  Widget _buildRegionOption(String label) {
    bool isSelected = _selectedRegion == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedRegion = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.successGreen.withOpacity(0.05) : AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.successGreen : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: isSelected ? AppColors.successGreen : AppColors.textLight,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendBroadcast() async {
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      // This would integrate with the actual broadcast service
      await BroadcastService.sendBroadcast(
        title: 'Test Broadcast',
        message: 'This is a test broadcast',
        audience: 'All Users',
        region: _selectedRegion,
        isImmediate: _isImmediate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Broadcast sent successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      Logger.error('Failed to send broadcast', error: e, name: 'BroadcastNotificationMethods');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send broadcast: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Widget _buildSmallButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label feature coming soon'),
            backgroundColor: AppColors.warningOrange,
          ),
        );
      },
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: Colors.grey.shade300),
        foregroundColor: AppColors.textDark,
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSending ? null : _sendBroadcast,
        icon: _isSending 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.send, size: 16),
        label: Text(_isSending ? 'Sending...' : (_isImmediate ? 'Send Broadcast' : 'Schedule Broadcast')),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildStatsBadge() {
    if (_broadcastStats == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.analytics, size: 16, color: AppColors.successGreen),
          const SizedBox(width: 8),
          Text(
            '${_broadcastStats!['totalBroadcasts'] ?? 0} sent',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.successGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBroadcasts() {
    if (_recentBroadcasts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Broadcasts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No recent broadcasts',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Broadcasts',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._recentBroadcasts.map((broadcast) => _buildBroadcastItem(broadcast)),
        ],
      ),
    );
  }

  Widget _buildBroadcastItem(Map<String, dynamic> broadcast) {
    final title = broadcast['title'] as String? ?? 'Unknown';
    final message = broadcast['message'] as String? ?? '';
    final status = broadcast['status'] as String? ?? 'unknown';
    final createdAt = broadcast['createdAt'] as Timestamp?;
    final deliveryCount = broadcast['deliveryCount'] as int? ?? 0;
    final failedCount = broadcast['failedCount'] as int? ?? 0;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'completed':
        statusColor = AppColors.successGreen;
        statusIcon = Icons.check_circle;
        statusText = 'Delivered';
        break;
      case 'scheduled':
        statusColor = AppColors.warningOrange;
        statusIcon = Icons.schedule;
        statusText = 'Scheduled';
        break;
      case 'failed':
        statusColor = AppColors.errorRed;
        statusIcon = Icons.error;
        statusText = 'Failed';
        break;
      default:
        statusColor = AppColors.textLight;
        statusIcon = Icons.help;
        statusText = 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message.length > 50 ? '${message.substring(0, 50)}...' : message,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                createdAt != null 
                    ? '${createdAt!.toDate().day}/${createdAt!.toDate().month}/${createdAt!.toDate().year}'
                    : 'Unknown date',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textLight,
                ),
              ),
              const Spacer(),
              if (deliveryCount > 0) ...[
                Text(
                  '$deliveryCount delivered',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.successGreen,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (failedCount > 0) ...[
                Text(
                  '$failedCount failed',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.errorRed,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
