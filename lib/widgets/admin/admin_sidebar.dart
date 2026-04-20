import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../routes/app_routes.dart';

class AdminSidebar extends StatelessWidget {
  final String selectedRoute;

  const AdminSidebar({super.key, required this.selectedRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo / brand header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  const Icon(Icons.eco, color: AppColors.primaryGreen, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OptiFlow',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      Text(
                        'PLATFORM ADMIN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 24),

            // Navigation items — scrollable so they never overflow
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSidebarItem(context, Icons.dashboard_outlined, 'Dashboard', AppRoutes.adminDashboard),
                  _buildSidebarItem(context, Icons.people_outline, 'Users', AppRoutes.adminUsers),
                  _buildSidebarItem(context, Icons.business_outlined, 'Businesses', AppRoutes.adminBusinesses),
                  _buildSidebarItem(context, Icons.subscriptions_outlined, 'Subscriptions', AppRoutes.adminSubscriptions),
                  _buildSidebarItem(context, Icons.analytics_outlined, 'Analytics', AppRoutes.adminAnalytics),
                  _buildSidebarItem(context, Icons.description_outlined, 'Reports', AppRoutes.adminReports),
                  _buildSidebarItem(context, Icons.settings_outlined, 'Settings', AppRoutes.adminSettings),
                  _buildSidebarItem(context, Icons.campaign_outlined, 'Broadcast', AppRoutes.adminBroadcast),
                ],
              ),
            ),

            const Divider(height: 1),

            // Admin profile footer — fixed at bottom, no Spacer needed
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.15),
                    child: const Icon(Icons.person, color: AppColors.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Super Admin', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                      ],
                    ),
                  ),
                  const Icon(Icons.logout, size: 16, color: AppColors.textLight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, IconData icon, String title, String route) {
    final bool isSelected = selectedRoute == route;
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close drawer first
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppColors.primaryGreen.withOpacity(0.2)) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primaryGreen : AppColors.textLight,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primaryGreen : AppColors.textDark,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
