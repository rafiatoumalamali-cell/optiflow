import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // User Header
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/images/user_avatar.png'),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryOrange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final user = authProvider.currentUser;
                      if (user == null) {
                        return const Column(
                          children: [
                            Text(
                              'Guest User',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            Text(
                              'Please sign in',
                              style: TextStyle(fontSize: 14, color: AppColors.textLight),
                            ),
                          ],
                        );
                      }
                      
                      return Column(
                        children: [
                          Text(
                            user.fullName ?? 'User',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          Text(
                            user.role ?? 'User',
                            style: const TextStyle(fontSize: 14, color: AppColors.successGreen, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'ID: ${user.sequentialId ?? user.userId}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_done_outlined, size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      const Text('Offline Sync: 2m ago', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Activity Stats
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                if (user == null) {
                  return const SizedBox.shrink();
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Activity Stats', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem('OPTIMIZATIONS', '0'), // TODO: Connect to real stats
                          _buildStatItem('FUEL SAVED', '0L'), // TODO: Connect to real stats
                          _buildStatItem('COST SAVED', 'CFA 0'), // TODO: Connect to real stats
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Contact Information
            _buildSectionHeader('Contact Information'),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                if (user == null) {
                  return Column(
                    children: [
                      _buildInfoTile(Icons.email_outlined, 'EMAIL ADDRESS', 'Not available'),
                      _buildInfoTile(Icons.phone_outlined, 'PHONE NUMBER', 'Not available'),
                      _buildInfoTile(Icons.location_on_outlined, 'LOCATION', 'Not available'),
                    ],
                  );
                }
                
                return Column(
                  children: [
                    _buildInfoTile(Icons.email_outlined, 'EMAIL ADDRESS', user.email ?? 'Not provided'),
                    _buildInfoTile(Icons.phone_outlined, 'PHONE NUMBER', user.phone),
                    _buildInfoTile(Icons.location_on_outlined, 'LOCATION', 'Niamey, Niger 🇳🇪'),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 24),
            // Business Details
            _buildSectionHeader('Business Details'),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                if (user == null) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(child: _buildInfoSubTile('BUSINESS ID', 'Not available')),
                            Expanded(child: _buildInfoSubTile('ROLE', 'Not available')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(child: _buildInfoSubTile('JOINED DATE', 'Not available')),
                            Expanded(child: _buildInfoSubTile('STATUS', 'NOT SIGNED IN', color: Colors.orange)),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                
                final joinedDate = user.createdAt != null 
                    ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                    : 'Not available';
                final isActive = user.isActive ?? false;
                
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: _buildInfoSubTile('BUSINESS ID', user.sequentialId ?? user.userId)),
                          Expanded(child: _buildInfoSubTile('ROLE', user.role ?? 'User')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: _buildInfoSubTile('JOINED DATE', joinedDate)),
                          Expanded(child: _buildInfoSubTile('STATUS', isActive ? 'ACTIVE' : 'INACTIVE', 
                              color: isActive ? AppColors.successGreen : AppColors.primaryOrange)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            // Account Settings
            _buildSectionHeader('Account Settings'),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final isDriver = auth.currentUser?.role == 'Driver';
                return Column(
                  children: [
                    if (!isDriver)
                      _buildSettingsTile(Icons.people_outline, 'Manage Drivers', onTap: () => Navigator.pushNamed(context, AppRoutes.driverManagement)),
                    _buildSettingsTile(Icons.edit_outlined, 'Edit Profile', onTap: () => _showEditProfileDialog()),
                    _buildSettingsTile(Icons.lock_outline, 'Security & Password', onTap: () => _showSecurityDialog()),
                    _buildSettingsTile(Icons.notifications_none, 'Notification Preferences', onTap: () => _showNotificationPreferencesDialog()),
                    _buildSettingsTile(Icons.language, 'Regional Preferences', onTap: () => _showRegionalPreferencesDialog()),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
            // Sign Out
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirmed = await _showSignOutConfirmation();
                      if (confirmed) {
                        await authProvider.signOut();
                        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.onboarding, (route) => false);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: AppColors.errorRed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Sign Out', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Consumer<AuthProvider>(
        builder: (context, auth, _) => CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            final isDriver = auth.currentUser?.role == 'Driver';
            if (index == 0) {
              Navigator.pushNamed(context, isDriver ? AppRoutes.driverHome : AppRoutes.homeDashboard);
            }
            if (index == 1) {
              if (isDriver) {
                Navigator.pushNamed(context, AppRoutes.routeAssignment);
              } else {
                Navigator.pushNamed(context, AppRoutes.savedResults);
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const Icon(Icons.info_outline, size: 16, color: AppColors.textLight),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textLight, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.successGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.successGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textLight, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSubTile(String label, String value, {Color? color}) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textLight, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color ?? AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textLight, size: 20),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
          ],
        ),
      ),
    );
  }

  Future<bool> _showSignOutConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showEditProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user == null) return;

    final nameController = TextEditingController(text: user.fullName ?? '');
    final phoneController = TextEditingController(text: user.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Update user profile
              await authProvider.updateUserProfile(
                fullName: nameController.text.trim(),
                email: user.email ?? '',
                role: user.role ?? 'User',
                businessId: user.businessId ?? '',
              );
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security & Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              onTap: () {
                Navigator.pop(context);
                _showChangePasswordDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Two-Factor Authentication'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('2FA feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy settings coming soon')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              try {
                await authProvider.changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password changed successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showNotificationPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Preferences'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Optimization Results'),
              subtitle: const Text('Get notified when optimization completes'),
              value: true, // TODO: Connect to real preferences
              onChanged: (value) {
                // TODO: Save preference
              },
            ),
            SwitchListTile(
              title: const Text('Route Updates'),
              subtitle: const Text('Receive route status updates'),
              value: true, // TODO: Connect to real preferences
              onChanged: (value) {
                // TODO: Save preference
              },
            ),
            SwitchListTile(
              title: const Text('System Notifications'),
              subtitle: const Text('Important system updates'),
              value: false, // TODO: Connect to real preferences
              onChanged: (value) {
                // TODO: Save preference
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preferences saved')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRegionalPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regional Preferences'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: const Text('English'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language selection coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Time Zone'),
              subtitle: const Text('UTC+1 (West Africa)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Time zone selection coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Currency'),
              subtitle: const Text('CFA Franc'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Currency selection coming soon')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
