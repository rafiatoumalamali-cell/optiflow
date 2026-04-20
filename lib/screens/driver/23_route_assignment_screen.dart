import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/driver/driver_bottom_nav_bar.dart';
import '../../routes/app_routes.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_provider.dart';
import '../../models/route_model.dart';

class RouteAssignmentScreen extends StatefulWidget {
  const RouteAssignmentScreen({super.key});

  @override
  State<RouteAssignmentScreen> createState() => _RouteAssignmentScreenState();
}

class _RouteAssignmentScreenState extends State<RouteAssignmentScreen> {
  String _selectedDate = 'Today';
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
    final routeProvider = Provider.of<RouteProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final routes = routeProvider.routes;

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
            child: Text(auth.currentUser?.fullName.substring(0,1).toUpperCase() ?? 'D', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ),
        title: const Text('OptiFlow', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: routeProvider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => routeProvider.fetchAssignedRoutes(auth.currentUser?.userId ?? ''),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Today\'s Routes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Assigned logistics for ${auth.currentUser?.fullName ?? 'Driver'}', style: const TextStyle(fontSize: 14, color: AppColors.textLight)),
                  const SizedBox(height: 24),

                  if (routes.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: const Column(
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No routes assigned for today.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    ...routes.map((route) => _buildRouteCard(
                      'ID: ${route.routeId.split('-').last}',
                      'Active Route',
                      '${route.distanceKm.toStringAsFixed(1)} km',
                      route.estimatedTime,
                      route: route,
                    )),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
      bottomNavigationBar: DriverBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, AppRoutes.driverHome);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.profile);
        },
      ),
    );
  }

  Widget _buildDateChip(String label) {
    bool isSelected = _selectedDate == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedDate = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard(String zone, String stops, String distance, String time, {required RouteModel route, bool isPriority = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPriority)
                    const Text('• PRIORITY ROUTE', style: TextStyle(color: AppColors.primaryOrange, fontSize: 8, fontWeight: FontWeight.bold)),
                  Text(zone, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(stops, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const Text('STOPS', style: TextStyle(fontSize: 8, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSmallIconText(Icons.location_on_outlined, distance),
              if (time.isNotEmpty) ...[
                const SizedBox(width: 16),
                _buildSmallIconText(Icons.access_time, time),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.driverNavigation, arguments: route),
            icon: const Icon(Icons.navigation, size: 18),
            label: const Text('Start Route', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIconText(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.backgroundGray, borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.textLight),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ],
      ),
    );
  }
}
