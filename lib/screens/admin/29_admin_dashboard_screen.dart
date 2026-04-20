import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../routes/app_routes.dart';
import '../../providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<AdminProvider>();
      prov.fetchGlobalStats();
      prov.fetchRecentActivity();
      prov.fetchSubscriptions();
    });
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
              'Admin Dashboard',
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
      drawer: const AdminSidebar(selectedRoute: '/admin/dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer<AdminProvider>(
          builder: (context, adminProv, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildStatsGrid(adminProv),
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildRecentActivity(adminProv),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OPERATIONAL INSIGHT',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
        ),
        const Text(
          'Platform Overview',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 16),
        _buildQuickActionButtons(context),
      ],
    );
  }

  Widget _buildQuickActionButtons(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildHeaderButton(Icons.add, 'Add Admin', Colors.white, AppColors.textDark),
        _buildHeaderButton(Icons.description_outlined, 'Review Reports', AppColors.primaryOrange, Colors.white,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.adminReports)),
        _buildHeaderButton(Icons.send_outlined, 'Send Broadcast', AppColors.primaryGreen, Colors.white,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.adminBroadcast)),
      ],
    );
  }

  Widget _buildStatsGrid(AdminProvider adminProv) {
    // Format currency with CFA notation
    String _fmtRevenue(double revenue) {
      if (revenue >= 1000000) return 'CFA ${(revenue / 1000000).toStringAsFixed(1)}M';
      if (revenue >= 1000) return 'CFA ${(revenue / 1000).toStringAsFixed(0)}k';
      return 'CFA ${revenue.toInt()}';
    }

    return Column(
      children: [
        // Row 1: Users + Businesses (from fetchGlobalStats)
        Row(
          children: [
            Expanded(
              child: adminProv.isLoading
                  ? _loadingCard()
                  : _buildStatCard('Total Users', adminProv.totalUsers.toString(), AppColors.primaryGreen, Icons.people),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: adminProv.isLoading
                  ? _loadingCard()
                  : _buildStatCard('Businesses', adminProv.totalBusinesses.toString(), AppColors.primaryGreen, Icons.business),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Optimizations (from fetchGlobalStats) + Revenue (from fetchSubscriptions)
        Row(
          children: [
            Expanded(
              child: adminProv.isLoading
                  ? _loadingCard()
                  : _buildStatCard('Optimizations', adminProv.totalOptimizations.toString(), AppColors.primaryOrange, Icons.bolt),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: adminProv.isSubscriptionsLoading
                  ? _loadingCard()
                  : _buildStatCard(
                      'Total Revenue',
                      _fmtRevenue(adminProv.totalRevenue),
                      AppColors.successGreen,
                      Icons.payments,
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _loadingCard() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
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
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
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
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          _buildActionItem(Icons.people, 'User Management', AppRoutes.adminUsers, context),
          _buildActionItem(Icons.business, 'Business Management', AppRoutes.adminBusinesses, context),
          _buildActionItem(Icons.analytics, 'Analytics', AppRoutes.adminAnalytics, context),
          _buildActionItem(Icons.settings, 'Settings', AppRoutes.adminSettings, context),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, String route, BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textLight, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(AdminProvider adminProv) {
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
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          if (adminProv.isActivityLoading)
            const Center(child: CircularProgressIndicator())
          else if (adminProv.recentActivity.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No recent activity yet.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            )
          else
            ...adminProv.recentActivity.map((event) => _buildActivityItem(event)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> event) {
    final time = event['time'] as DateTime;
    final now = DateTime.now();
    final diff = now.difference(time);
    String timeStr;
    if (diff.inMinutes < 60) {
      timeStr = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timeStr = '${diff.inHours}h ago';
    } else {
      timeStr = '${diff.inDays}d ago';
    }

    final iconMap = {
      'person': Icons.person_outline,
      'business': Icons.business_outlined,
      'bolt': Icons.bolt,
    };
    final icon = iconMap[event['icon']] ?? Icons.circle;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event['text'] as String,
              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, String label, Color bgColor, Color textColor, {VoidCallback? onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 16, color: textColor),
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: bgColor == Colors.white ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
