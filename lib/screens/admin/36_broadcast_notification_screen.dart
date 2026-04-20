import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/logger.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../services/broadcast_service.dart';

class BroadcastNotificationScreen extends StatefulWidget {
  const BroadcastNotificationScreen({super.key});

  @override
  State<BroadcastNotificationScreen> createState() => _BroadcastNotificationScreenState();
}

class _BroadcastNotificationScreenState extends State<BroadcastNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  String _selectedAudience = 'All Users';
  String _selectedRegion = 'All Regions';
  DateTime? _scheduledTime;
  bool _isImmediate = true;
  bool _isSending = false;
  bool _isPreviewMode = false;
  
  List<Map<String, dynamic>> _recentBroadcasts = [];
  Map<String, dynamic>? _broadcastStats;

  @override
  void initState() {
    super.initState();
    _loadBroadcastData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadBroadcastData() async {
    try {
      final broadcasts = await BroadcastService.getBroadcasts();
      final stats = await BroadcastService.getBroadcastStats();
      
      if (mounted) {
        setState(() {
          _recentBroadcasts = broadcasts.take(5).toList();
          _broadcastStats = stats;
        });
      }
    } catch (e, stack) {
      Logger.error('Error loading broadcast data', name: 'BroadcastScreen', error: e, stackTrace: stack);
    }
  }

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final broadcastId = await BroadcastService.createBroadcast(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        audience: _selectedAudience,
        region: _selectedRegion,
        scheduledTime: _isImmediate ? DateTime.now() : (_scheduledTime ?? DateTime.now()),
        content: {
          'type': 'broadcast',
          'audience': _selectedAudience,
          'region': _selectedRegion,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      if (_isImmediate) {
        await BroadcastService.sendBroadcast(broadcastId);
      }

      // Clear form
      _formKey.currentState!.reset();
      _titleController.clear();
      _messageController.clear();
      _scheduledTime = null;
      _isImmediate = true;
      _selectedAudience = 'All Users';
      _selectedRegion = 'All Regions';

      // Reload data
      await _loadBroadcastData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isImmediate ? 'Broadcast sent successfully!' : 'Broadcast scheduled successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }

    } catch (e, stack) {
      Logger.error('Error sending broadcast', name: 'BroadcastScreen', error: e, stackTrace: stack);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending broadcast: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.eco, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            const Text(
              'Broadcast',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textDark),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AdminSidebar(selectedRoute: '/admin/broadcast'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BROADCAST NOTIFICATION',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 8),
              const Text(
                'Send notifications to users across the platform',
                style: TextStyle(fontSize: 14, color: AppColors.textLight),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text('Send Broadcast', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (_broadcastStats != null) _buildStatsBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Text('Reach your logistics partners and users instantly with regional or global announcements.',
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              const SizedBox(height: 24),
              _buildSection('Target Audience', Icons.groups_outlined, _buildAudienceGrid()),
              const SizedBox(height: 24),
              _buildSection('Notification Content', Icons.edit_note_outlined, _buildContentForm()),
              const SizedBox(height: 24),
              _buildSection('Delivery Schedule', Icons.calendar_today_outlined, _buildScheduleActions()),
              const SizedBox(height: 24),
              _buildSendButton(),
              const SizedBox(height: 24),
              _buildDevicePreview(),
              const SizedBox(height: 24),
              _buildRecentBroadcasts(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70, color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(child: Container(height: 40, constraints: const BoxConstraints(maxWidth: 400), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)), child: const Row(children: [SizedBox(width: 16), Icon(Icons.search, size: 18, color: Colors.grey), SizedBox(width: 12), Text('Search resources...', style: TextStyle(color: Colors.grey, fontSize: 13))]))),
          const Icon(Icons.notifications_none, color: Colors.grey),
          const SizedBox(width: 20),
          const Icon(Icons.help_outline, color: Colors.grey),
          const SizedBox(width: 20),
          const CircleAvatar(radius: 16, backgroundImage: AssetImage('assets/images/user_avatar.png')),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 18, color: Colors.green), const SizedBox(width: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildAudienceGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Audience Type', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            SizedBox(height: 44, width: 160, child: _buildAudienceOption('All Users')),
            SizedBox(height: 44, width: 160, child: _buildAudienceOption('Business Owners')),
            SizedBox(height: 44, width: 160, child: _buildAudienceOption('Drivers')),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Region', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            SizedBox(height: 44, width: 120, child: _buildRegionOption('All Regions')),
            SizedBox(height: 44, width: 120, child: _buildRegionOption('Nigeria')),
            SizedBox(height: 44, width: 120, child: _buildRegionOption('Ghana')),
            SizedBox(height: 44, width: 120, child: _buildRegionOption('Niger')),
          ],
        ),
      ],
    );
  }

  Widget _buildAudienceOption(String label) {
    bool isSelected = _selectedAudience == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedAudience = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: isSelected ? AppColors.successGreen.withOpacity(0.05) : AppColors.backgroundGray, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? AppColors.successGreen : Colors.transparent)),
        child: Row(children: [Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, size: 16, color: isSelected ? AppColors.successGreen : AppColors.textLight), const SizedBox(width: 12), Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))]),
      ),
    );
  }

  Widget _buildRegionOption(String label) {
    bool isSelected = _selectedRegion == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedRegion = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: isSelected ? Colors.green : Colors.grey.shade600,
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

  Widget _buildContentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notification Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'e.g. Scheduled System Maintenance',
            filled: true,
            fillColor: AppColors.backgroundGray,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.errorRed)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a notification title';
            }
            if (value.trim().length > 50) {
              return 'Title must be less than 50 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        const Text('Message Body', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Type your broadcast message here...',
            filled: true,
            fillColor: AppColors.backgroundGray,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.errorRed)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a message';
            }
            if (value.trim().length > 500) {
              return 'Message must be less than 500 characters';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {}); // Update character count
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_messageController.text.length} / 500 characters',
            style: TextStyle(
              fontSize: 10,
              color: _messageController.text.length > 450 ? AppColors.errorRed : AppColors.textLight,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildSmallButton(Icons.image_outlined, 'Attach Image'),
            const SizedBox(width: 12),
            _buildSmallButton(Icons.link, 'Add Deep Link'),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Send Immediately'),
                value: true,
                groupValue: _isImmediate,
                onChanged: (value) {
                  setState(() {
                    _isImmediate = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Schedule for Later'),
                value: false,
                groupValue: _isImmediate,
                onChanged: (value) {
                  setState(() {
                    _isImmediate = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
        if (!_isImmediate) ...[
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: AppColors.primaryGreen),
            title: Text(
              _scheduledTime != null 
                  ? 'Scheduled: ${_scheduledTime!.toString().substring(0, 16)}'
                  : 'Select date and time',
            ),
            subtitle: const Text('Tap to select schedule time'),
            onTap: _selectScheduleTime,
            tileColor: AppColors.backgroundGray,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ],
      ],
    );
  }

  Future<void> _selectScheduleTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))),
      );

      if (time != null) {
        setState(() {
          _scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Widget _buildDevicePreview() {
    return Column(
      children: [
        Container(
          width: 280, height: 560,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.grey.shade800, width: 8)),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('09:41', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]),
              const SizedBox(height: 40),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.eco, color: AppColors.primaryGreen, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('OPTIFLOW', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          Text('Holiday Operational Updates', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Dear Partners, please be advised that our regional hub...', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                        ],
                      ),
                    ),
                    Text('NOW', style: TextStyle(fontSize: 8, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildAudienceReach(),
      ],
    );
  }

  Widget _buildAudienceReach() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Row(children: [Icon(Icons.person_outline, size: 16, color: AppColors.successGreen), SizedBox(width: 8), Text('Audience Reach Estimate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.successGreen))]),
          const SizedBox(height: 12),
          const Text('Your message will be broadcasted to approximately 12,450 users across West Africa.', style: TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.4)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(4, (index) => const Align(widthFactor: 0.6, child: CircleAvatar(radius: 12, backgroundColor: Colors.white, child: CircleAvatar(radius: 10, backgroundImage: AssetImage('assets/images/user_avatar.png'))))),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [Icon(icon, size: 16, color: Colors.grey), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildStatsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics, size: 16, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            '${_broadcastStats!['total_sent'] ?? 0} sent',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSending ? null : _sendBroadcast,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSending
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Sending...'),
                ],
              )
            : const Text('Send Broadcast'),
      ),
    );
  }

  Widget _buildRecentBroadcasts() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Broadcasts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to broadcast history
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentBroadcasts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent broadcasts',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your broadcast history will appear here',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._recentBroadcasts.map((broadcast) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            broadcast['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatDate(broadcast['created_at']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      broadcast['message'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${broadcast['sent_count'] ?? 0} recipients',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(broadcast['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            broadcast['status'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStatusColor(broadcast['status']),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = timestamp is DateTime 
          ? timestamp 
          : DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'sent':
        return Colors.green;
      case 'scheduled':
        return Colors.blue;
      case 'failed':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
