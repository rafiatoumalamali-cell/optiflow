import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? (loc?.translate('user') ?? 'User'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.role ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user?.phone ?? user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Items
          _buildMenuItem(
            context,
            Icons.dashboard_outlined,
            loc?.translate('dashboard') ?? 'Dashboard',
            user?.role == 'Driver' ? AppRoutes.driverHome : AppRoutes.homeDashboard,
          ),
          if (user?.role != 'Driver') ...[
            _buildMenuItem(
              context,
              Icons.inventory_2_outlined,
              loc?.translate('optimization') ?? 'Optimization',
              AppRoutes.productList,
            ),
            _buildMenuItem(
              context,
              Icons.saved_search_outlined,
              loc?.translate('saved_results') ?? 'Saved Results',
              AppRoutes.savedResults,
            ),
            _buildMenuItem(
              context,
              Icons.local_shipping_outlined,
              loc?.translate('transport') ?? 'Transport',
              AppRoutes.transportInput,
            ),
            _buildMenuItem(
              context,
              Icons.map_outlined,
              loc?.translate('routes') ?? 'Routes',
              AppRoutes.routePlanner,
            ),
            _buildMenuItem(
              context,
              Icons.account_balance_wallet_outlined,
              loc?.translate('budget') ?? 'Budget',
              AppRoutes.budgetInput,
            ),
            _buildMenuItem(
              context,
              Icons.people_outline,
              loc?.translate('manage_drivers') ?? 'Manage Drivers',
              AppRoutes.driverManagement,
            ),
          ] else ...[
             _buildMenuItem(
              context,
              Icons.route,
              loc?.translate('my_routes') ?? 'My Routes',
              AppRoutes.routeAssignment,
            ),
          ],
          
          const Divider(),
          
          // Settings Section
          _buildMenuItem(
            context,
            Icons.settings_outlined,
            loc?.translate('settings') ?? 'Settings',
            AppRoutes.settings,
          ),
          _buildMenuItem(
            context,
            Icons.help_outline,
            loc?.translate('help_support') ?? 'Help & Support',
            AppRoutes.help,
          ),
          
          const Divider(),
          
          // Sign Out
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.errorRed),
            title: Text(
              loc?.translate('sign_out') ?? 'Sign Out',
              style: const TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.w500),
            ),
            onTap: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.onboarding,
                  (route) => false,
                );
              }
            },
          ),
          
          const SizedBox(height: 20),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'OptiFlow v1.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '© 2024 OptiFlow Technologies',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textDark),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        Navigator.pushNamed(context, route);
      },
    );
  }
}
