import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';
import '../../services/offline_route_service.dart';
import '../../models/route_model.dart';

class OfflineRoutesScreen extends StatefulWidget {
  const OfflineRoutesScreen({super.key});

  @override
  State<OfflineRoutesScreen> createState() => _OfflineRoutesScreenState();
}

class _OfflineRoutesScreenState extends State<OfflineRoutesScreen> {
  List<RouteModel> _cachedRoutes = [];
  bool _isLoading = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadOfflineRoutes();
    _checkConnectivity();
  }

  Future<void> _loadOfflineRoutes() async {
    setState(() => _isLoading = true);
    
    try {
      final routes = await OfflineRouteService.getAllCachedRoutes();
      setState(() {
        _cachedRoutes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkConnectivity() async {
    final isOnline = await OfflineRouteService.isOnline();
    setState(() => _isOnline = isOnline);
  }

  Future<void> _deleteRoute(String routeId) async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    final success = await OfflineRouteService.deleteCachedRoute(routeId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route deleted successfully')),
      );
      _loadOfflineRoutes(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete route')),
      );
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: const Text('Are you sure you want to delete this cached route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _clearAllRoutes() async {
    final confirmed = await _showClearAllConfirmation();
    if (!confirmed) return;

    final success = await OfflineRouteService.clearAllCachedRoutes();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All cached routes cleared')),
      );
      _loadOfflineRoutes(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to clear routes')),
      );
    }
  }

  Future<bool> _showClearAllConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Routes'),
        content: const Text('Are you sure you want to delete all cached routes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Clear All'),
          ),
        ],
      ),
    ) ?? false;
  }

  String _formatDuration(String estimatedTime) {
    // Simple formatting for display
    if (estimatedTime.contains('h')) {
      return estimatedTime;
    }
    return '$estimatedTime min';
  }

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
        title: const Text('Offline Routes', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        actions: [
          if (_cachedRoutes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppColors.errorRed),
              onPressed: _clearAllRoutes,
            ),
        ],
      ),
      body: Column(
        children: [
          // Connectivity Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isOnline ? AppColors.successGreen : AppColors.primaryOrange,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isOnline ? 'Online - Routes will sync automatically' : 'Offline - Using cached routes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Routes List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cachedRoutes.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cachedRoutes.length,
                        itemBuilder: (context, index) {
                          final route = _cachedRoutes[index];
                          return _buildRouteCard(route, index);
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, AppRoutes.homeDashboard);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.savedResults);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.profile);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.offline_bolt,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Cached Routes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Routes will be cached here when you\nnavigate online',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore),
            label: const Text('Explore Routes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(RouteModel route, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Route Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.route,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name.isNotEmpty ? route.name : 'Route ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Created ${_formatDate(route.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteRoute(route.routeId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.errorRed, size: 18),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Route Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildDetailItem(
                  Icons.straighten,
                  '${route.distanceKm.toStringAsFixed(1)} km',
                ),
                const SizedBox(width: 24),
                _buildDetailItem(
                  Icons.access_time,
                  _formatDuration(route.estimatedTime),
                ),
                const SizedBox(width: 24),
                _buildDetailItem(
                  Icons.location_on,
                  '${route.waypoints.length} stops',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to route details or start navigation
                      Navigator.pushNamed(
                        context,
                        AppRoutes.driverNavigation,
                        arguments: route,
                      );
                    },
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Navigate'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Update last used timestamp
                      OfflineRouteService.updateRouteLastUsed(route.routeId);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.routeResults,
                        arguments: route,
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
