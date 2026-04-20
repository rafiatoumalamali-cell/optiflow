import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/driver/driver_bottom_nav_bar.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_provider.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final TextEditingController _fleetCodeController = TextEditingController();

  @override
  void dispose() {
    _fleetCodeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser != null) {
        Provider.of<RouteProvider>(context, listen: false).fetchAssignedRoutes(auth.currentUser!.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final routeProvider = Provider.of<RouteProvider>(context);
    final currentUser = authProvider.currentUser;

    // Logic for Summary metrics
    final todayRoutes = routeProvider.routes;
    final totalDistance = todayRoutes.fold(0.0, (sum, r) => sum + r.distanceKm);
    final totalDeliveries = todayRoutes.length;
    final activeRoute = todayRoutes.firstWhere((r) => r.status == 'assigned' || r.status == 'in_progress', orElse: () => todayRoutes.isNotEmpty ? todayRoutes.first : todayRoutes.first); // Mocking active for now if none assigned

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
            child: Text(
              currentUser?.fullName != null && currentUser!.fullName.isNotEmpty 
                  ? currentUser.fullName.substring(0, 1).toUpperCase() 
                  : 'D',
              style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc?.translate('home_title') ?? 'OptiFlow', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('LOGISTICS HUB', style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.textDark),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
        ],
      ),
      body: routeProvider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => routeProvider.fetchAssignedRoutes(currentUser?.userId ?? ''),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${loc?.translate('good_morning') ?? 'Good morning,'} ${currentUser?.fullName.split(' ')[0] ?? 'Driver'}', 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(loc?.translate('ready_today_routes') ?? 'Ready for today\'s routes?', style: const TextStyle(fontSize: 14, color: AppColors.textLight)),
                  const SizedBox(height: 20),
                  
                  // Real Summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem(loc?.translate('deliveries') ?? 'Routes', totalDeliveries.toString()),
                        _buildSummaryItem(loc?.translate('drive_time') ?? 'Time', todayRoutes.isEmpty ? '0h' : todayRoutes.first.estimatedTime),
                        _buildSummaryItem(loc?.translate('distance_label') ?? 'Distance', '${totalDistance.toStringAsFixed(1)} km'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Real Active Route Card
                  if (todayRoutes.isNotEmpty) ...[
                    Text(loc?.translate('active_route') ?? 'ACTIVE ROUTE', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFF212121), borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(todayRoutes.first.routeId.split('-').last, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Column(
                                  children: [
                                    Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text('STATUS', style: TextStyle(color: Colors.white, fontSize: 8)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: AppColors.primaryGreen),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(loc?.translate('destination') ?? 'Destination', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                      Text(todayRoutes.first.destinationId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.driverNavigation, arguments: todayRoutes.first),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(loc?.translate('start_delivery') ?? 'Open Route', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Real Pending Routes (Other assigned routes)
                  Text('MY ASSIGNMENTS', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (todayRoutes.isEmpty) 
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: const Column(
                          children: [
                            Icon(Icons.assignment_late_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No routes assigned yet.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                  else
                    ...todayRoutes.map((route) => _buildPendingRoute(
                      context,
                      'ID: ${route.routeId.split('-').last}',
                      '${route.distanceKm.toStringAsFixed(1)} km • ${route.estimatedTime}',
                      Icons.local_shipping,
                      route,
                    )),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
      bottomNavigationBar: DriverBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, AppRoutes.routeAssignment);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.profile);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.support);
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPendingRoute(BuildContext context, String title, String subtitle, IconData icon, dynamic route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.backgroundGray, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.textLight, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.driverNavigation, arguments: route),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.backgroundGray, foregroundColor: AppColors.textDark, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: const Size(0, 0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Open', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
